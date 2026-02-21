#!/usr/bin/env bash
set -euo pipefail

install_dir=$1
test_dir=$2

echo "--- Container: Fetching latest stable Gradle version ---"

json_response=$(curl -s https://services.gradle.org/versions/current)
gradle_version=$(echo "$json_response" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*' | cut -d'"' -f4)

if [ -z "$gradle_version" ]; then
    echo "Error: Could not determine Gradle version."
    exit 1
fi

echo "--- Container: Testing with Gradle $gradle_version ---"

mkdir -p "$install_dir"
curl -sSL "https://services.gradle.org/distributions/gradle-${gradle_version}-bin.zip" -o "$install_dir/gradle.zip"
unzip -q "$install_dir/gradle.zip" -d "$install_dir"

gradle_bin="../$install_dir/gradle-${gradle_version}/bin/gradle"

mkdir -p "$test_dir" && cd "$test_dir"

echo "--- Container: Initializing project via $gradle_bin ---"
LD_PRELOAD="" "$gradle_bin" init \
    --type java-application \
    --dsl kotlin \
    --package com.example \
    --project-name smoke-test-app \
    --no-daemon

echo "--- Container: Verifying via generated ./gradlew help ---"
./gradlew help --no-daemon
