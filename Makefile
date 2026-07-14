.PHONY: setup check android-bootstrap android-34 android-36 android-smoke android-smoke-36

setup:
	flutter pub get

check:
	dart format --output=none --set-exit-if-changed lib test integration_test
	flutter analyze
	flutter test

android-bootstrap:
	tooling/android/bootstrap.sh

android-34:
	tooling/android/launch.sh 34

android-36:
	tooling/android/launch.sh 36

android-smoke:
	tooling/android/smoke.sh 34

android-smoke-36:
	tooling/android/smoke.sh 36
