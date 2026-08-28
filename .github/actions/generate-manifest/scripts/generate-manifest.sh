#!/usr/bin/env bash
set -euo pipefail

image=$1
image_tag=$2
report_file=$3

get_android_cli() {
    local cliVersion
    cliVersion=$(docker run --rm "$image" android --version 2>/dev/null)

    if [ -z "$cliVersion" ]; then
        echo "Error: 'android version' returns no output." >&2
        return 1
    fi

    printf "| android | %s | Android CLI |\n" "$cliVersion"
}

get_sdk_components() {
    local output
    output=$(docker run --rm "$image" android sdk list 2>/dev/null |
        awk '
        /^Installed packages:/ {
            in_packages = 1
            next
        }
        in_packages && /[a-zA-Z0-9]/ {
            line = $0
            sub(/^[ \t]+/, "", line)
            sub(/[ \t]+$/, "", line)
            split(line, arr, /[ \t][ \t]+/)
            printf "| %s | %s | %s |\n", arr[1], arr[2], arr[3]
        }' | sort)

    if [ -z "$output" ]; then
        echo "Error: No installed SDK components found or unable to parse 'android sdk list' output." >&2
        return 1
    fi

    echo "$output"
}

get_apk_packages() {
    local output
    output=$(docker run --rm "$image" apk info -v 2>/dev/null |
        awk '
        /^WARNING:/ { next }
        /^[a-zA-Z0-9]/ {
            full=$0; pkg=$0;
            sub(/-[0-9].*$/, "", pkg);
            ver=substr(full, length(pkg) + 2);
            printf "| %s | %s |\n", pkg, ver
        }' | sort)

    if [ -z "$output" ]; then
        echo "Error: No installed apk packages found or unable to parse apk output." >&2
        return 1
    fi

    echo "$output"
}

generate_markdown_body() {
    local cli_row
    local sdk_rows
    local apk_rows

    cli_row=$(get_android_cli)
    sdk_rows=$(get_sdk_components)
    apk_rows=$(get_apk_packages)

    cat <<EOF
<details><summary><b>🐋 Docker Image Content: <code>${image_tag}</code></b></summary>

#### 🤖 Android SDK Components
| Component | Version | Description |
| :--- | :--- | :--- |
${cli_row}
${sdk_rows}

#### 📦 Installed OS Packages (apk)
<details><summary>Click to view APK list</summary>

| Package | Version |
| :--- | :--- |
${apk_rows}

</details>
</details>

EOF
}

generate_markdown_body >>"$report_file"
