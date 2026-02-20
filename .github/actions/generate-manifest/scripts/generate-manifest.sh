#!/usr/bin/env bash
set -euo pipefail

image=$1
jdk_version=$2
android_api=$3
report_file="build_report.md"

: >"$report_file"

{
    # Main collapsible section for this specific image
    echo "<details><summary><b>📦 Build Configuration: JDK $jdk_version | Android API $android_api</b></summary>"
    echo ""
    echo "#### 🤖 Android SDK Components"
    echo "| Component | Version | Description |"
    echo "| :--- | :--- | :--- |"

    # Parse sdkmanager output
    docker run --rm "$image" sdkmanager --list_installed --verbose 2>/dev/null |
        awk '
    /^[a-zA-Z0-9.;_-]+$/ && !/^-+$/ { path=$1 }
    /[Dd]escription:/ { sub(/^[ \t]*[Dd]escription:[ \t]*/, ""); desc=$0 }
    /[Vv]ersion:/ {
        sub(/^[ \t]*[Vv]ersion:[ \t]*/, ""); ver=$0;
        if (path != "") {
            print "| " path " | " ver " | " desc " |";
            path=""; desc=""; ver="";
        }
    }' | sort

    echo ""
    echo "#### 📦 Installed OS Packages (apk)"
    echo "<details><summary>Click to view APK list</summary>"
    echo ""
    echo "| Package | Version |"
    echo "| :--- | :--- |"

    # Parse apk info and suppress warnings
    docker run --rm "$image" apk info -v 2>/dev/null | sort |
        awk '/^[a-zA-Z0-9]/ && !/[Ww]arning/ {
      full=$0; pkg=$0;
      sub(/-[0-9].*$/, "", pkg);
      ver=substr(full, length(pkg) + 2);
      print "| " pkg " | " ver " |"
    }'
    echo ""
    echo "</details>" # End APK details
    echo "</details>" # End Matrix-Slot details
    echo ""
} >>"$report_file"

# Add to GitHub Summary if running in CI
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    cat "$report_file" >>"$GITHUB_STEP_SUMMARY"
fi
