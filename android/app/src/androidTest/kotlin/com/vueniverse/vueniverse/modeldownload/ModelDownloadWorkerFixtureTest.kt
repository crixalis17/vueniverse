package com.vueniverse.vueniverse.modeldownload

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.work.ListenableWorker
import androidx.work.testing.TestListenableWorkerBuilder
import com.vueniverse.vueniverse.medgemma.ArtifactValidationResult
import com.vueniverse.vueniverse.medgemma.ExpectedModelArtifact
import com.vueniverse.vueniverse.medgemma.ModelArtifactLocator
import com.vueniverse.vueniverse.medgemma.ModelArtifactManager
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.Closeable
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.util.Collections
import kotlin.concurrent.thread

@RunWith(AndroidJUnit4::class)
class ModelDownloadWorkerFixtureTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val body = "fixture-medgemma-gguf-payload".toByteArray()
    private val artifact = ExpectedModelArtifact(
        modelId = "fixture/medgemma",
        modelRevision = "fixture-revision-v1",
        quantization = "Q4_TEST",
        fileName = "fixture-medgemma-Q4_TEST.gguf",
        sizeBytes = body.size.toLong(),
        sha256 = sha256(body),
    )
    private lateinit var files: ModelDownloadFiles

    @Before
    fun setUp() {
        files = ModelDownloadFiles(context, artifact)
        files.partialFile.delete()
        files.metadataFile.delete()
        files.finalFile.delete()
        ModelDownloadWorker.testEnvironmentFactory = null
    }

    @After
    fun tearDown() {
        ModelDownloadWorker.testEnvironmentFactory = null
        files.partialFile.delete()
        files.metadataFile.delete()
        files.finalFile.delete()
    }

    @Test
    fun interruptedFixtureResumesAndOnlyPromotesVerifiedFinalPath() {
        val interruptedAt = 8
        files.directory.mkdirs()
        files.partialFile.writeBytes(body.copyOfRange(0, interruptedAt))
        PartialMetadata(
            etag = ETAG,
            revision = artifact.modelRevision,
            downloadedBytes = interruptedAt.toLong(),
        ).write(files.metadataFile)
        val manager = ModelArtifactManager(ModelArtifactLocator(context.filesDir))
        assertTrue(manager.validate(artifact) is ArtifactValidationResult.Missing)

        FixtureHttpServer(body).use { server ->
            val url = "http://127.0.0.1:${server.port}/${artifact.fileName}"
            ModelDownloadWorker.testEnvironmentFactory = {
                ModelDownloadWorkerEnvironment(
                    artifact = artifact,
                    config = ModelDownloadConfig(
                        url = url,
                        reserveBytes = 0,
                        allowHttpForTests = true,
                    ),
                )
            }

            val worker = TestListenableWorkerBuilder
                .from(context, ModelDownloadWorker::class.java)
                .build()
            val result = runBlocking { worker.doWork() }

            assertTrue(result is ListenableWorker.Result.Success)
            assertEquals("bytes=$interruptedAt-", server.headers.single()["range"])
            assertEquals(ETAG, server.headers.single()["if-range"])
        }

        assertFalse(files.partialFile.exists())
        assertFalse(files.metadataFile.exists())
        assertTrue(files.finalFile.exists())
        assertTrue(manager.validate(artifact) is ArtifactValidationResult.Valid)
    }

    private class FixtureHttpServer(private val body: ByteArray) : Closeable {
        private val socket = ServerSocket(0, 8, InetAddress.getByName("127.0.0.1"))
        private val requests = Collections.synchronizedList(mutableListOf<Map<String, String>>())
        private val serverThread = thread(name = "model-fixture-http", isDaemon = true) {
            while (!socket.isClosed) {
                try {
                    socket.accept().use(::respond)
                } catch (error: Exception) {
                    if (!socket.isClosed) throw error
                }
            }
        }

        val port: Int get() = socket.localPort
        val headers: List<Map<String, String>> get() = requests.toList()

        private fun respond(client: Socket) {
            val reader = client.getInputStream().bufferedReader(StandardCharsets.US_ASCII)
            reader.readLine()
            val requestHeaders = mutableMapOf<String, String>()
            while (true) {
                val line = reader.readLine() ?: break
                if (line.isEmpty()) break
                val separator = line.indexOf(':')
                if (separator > 0) {
                    requestHeaders[line.substring(0, separator).lowercase()] =
                        line.substring(separator + 1).trim()
                }
            }
            requests += requestHeaders
            val start = requestHeaders["range"]
                ?.removePrefix("bytes=")
                ?.substringBefore('-')
                ?.toIntOrNull()
                ?: 0
            val payload = body.copyOfRange(start, body.size)
            val status = if (start > 0) "206 Partial Content" else "200 OK"
            val response = buildString {
                append("HTTP/1.1 $status\r\n")
                append("Content-Length: ${payload.size}\r\n")
                append("ETag: $ETAG\r\n")
                append("Accept-Ranges: bytes\r\n")
                if (start > 0) {
                    append("Content-Range: bytes $start-${body.lastIndex}/${body.size}\r\n")
                }
                append("Connection: close\r\n\r\n")
            }
            client.getOutputStream().use { output ->
                output.write(response.toByteArray(StandardCharsets.US_ASCII))
                output.write(payload)
                output.flush()
            }
        }

        override fun close() {
            socket.close()
            serverThread.join(2_000)
        }
    }

    companion object {
        private const val ETAG = "\"fixture-v1\""

        private fun sha256(bytes: ByteArray): String = MessageDigest
            .getInstance("SHA-256")
            .digest(bytes)
            .joinToString("") { "%02x".format(it) }
    }
}
