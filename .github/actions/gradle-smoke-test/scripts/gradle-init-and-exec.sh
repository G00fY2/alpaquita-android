#!/usr/bin/env bash
set -euo pipefail

test_dir="integration-test-project"
install_dir="gradle-dist"

echo "--- Container: Fetching latest stable Gradle version ---"
gradle_version=$(curl -s https://services.gradle.org/versions/current | jq -r '.version')
echo "--- Container: Testing with Gradle $gradle_version ---"

mkdir -p "$install_dir"
curl -sSL "https://services.gradle.org/distributions/gradle-${gradle_version}-bin.zip" -o "$install_dir/gradle.zip"
unzip -q "$install_dir/gradle.zip" -d "$install_dir"

gradle_bin="../$install_dir/gradle-${gradle_version}/bin/gradle"

mkdir -p "$test_dir" && cd "$test_dir"

echo "--- Container: Initializing project via $gradle_bin ---"
"$gradle_bin" init \
    --type java-application \
    --dsl kotlin \
    --package com.example \
    --project-name smoke-test-app \
    --no-daemon

echo "--- Container: Verifying via generated ./gradlew help ---"
./gradlew help --no-daemon
