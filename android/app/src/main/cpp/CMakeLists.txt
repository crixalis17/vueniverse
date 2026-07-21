cmake_minimum_required(VERSION 3.22.1)

project(vueniverse_medgemma LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(DEFINED ENV{LLAMA_CPP_DIR} AND NOT "$ENV{LLAMA_CPP_DIR}" STREQUAL "")
    set(LLAMA_CPP_DIR "$ENV{LLAMA_CPP_DIR}")
else()
    get_filename_component(
        LLAMA_CPP_DIR
        "${CMAKE_CURRENT_LIST_DIR}/../../../../../tooling/medgemma/.cache/llama.cpp"
        ABSOLUTE
    )
endif()

add_library(medgemma_jni SHARED medgemma_jni.cpp)
target_link_libraries(medgemma_jni PRIVATE android log)

if(EXISTS "${LLAMA_CPP_DIR}/CMakeLists.txt")
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
    set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
    set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
    set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
    set(GGML_CPU_KLEIDIAI OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_COMMON OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
    set(LLAMA_BUILD_APP OFF CACHE BOOL "" FORCE)
    set(LLAMA_CURL OFF CACHE BOOL "" FORCE)
    add_subdirectory("${LLAMA_CPP_DIR}" llama-build EXCLUDE_FROM_ALL)
    target_compile_definitions(medgemma_jni PRIVATE VUENIVERSE_LLAMA_AVAILABLE=1)
    target_include_directories(medgemma_jni PRIVATE
        "${LLAMA_CPP_DIR}/include"
        "${LLAMA_CPP_DIR}/ggml/include"
    )
    target_link_libraries(medgemma_jni PRIVATE llama)
else()
    message(WARNING "llama.cpp checkout not found; building unavailable-runtime JNI stub")
    target_compile_definitions(medgemma_jni PRIVATE VUENIVERSE_LLAMA_AVAILABLE=0)
endif()
