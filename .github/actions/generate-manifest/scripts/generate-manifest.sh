#!/usr/bin/env bash
set -euo pipefail

image=$1
jdk_version=$2
android_api=$3
report_file=$4

get_sdk_components() {
    docker run --rm "$image" sdkmanager --list_installed 2>/dev/null |
        awk -F '|' '
        /^[[:space:]]*Path/ {
            gsub(/Version/, "Version / Revision", $0);
            print $0; next
        }
        /^[[:space:]]*---/ { print $0; next }
        /^[[:space:]]+[a-zA-Z0-9.;_-]+[[:space:]]+\|/ {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1);
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2);
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3);
            printf "| %s | %s | %s |\n", $1, $2, $3
        }'
}

get_apk_packages() {
    docker run --rm "$image" apk info -v 2>/dev/null |
        awk '
        /^WARNING:/ { next }
        /^[a-zA-Z0-9]/ {
            full=$0; pkg=$0;
            sub(/-[0-9].*$/, "", pkg);
            ver=substr(full, length(pkg) + 2);
            printf "| %s | %s |\n", pkg, ver
        }' | sort
}

generate_markdown_body() {
    echo "<details><summary><b>🐳 Docker Image Content: JDK ${jdk_version#jdk} | Android API $android_api</b></summary>"
    echo ""
    echo "#### 🤖 Android SDK Components"
    echo "| Component | Version | Description |"
    echo "| :--- | :--- | :--- |"
    get_sdk_components

    echo ""
    echo "#### 📦 Installed OS Packages (apk)"
    echo "<details><summary>Click to view APK list</summary>"
    echo ""
    echo "| Package | Version |"
    echo "| :--- | :--- |"
    get_apk_packages

    echo ""
    echo "</details>"
    echo "</details>"
    echo ""
}

generate_markdown_body >>"$report_file"
