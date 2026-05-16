#!/usr/bin/env bash
set -euo pipefail

image=$1
report_file=$2
image_tag="${image#*:}"

get_sdk_components() {
    docker run --rm "$image" sdkmanager --list_installed 2>/dev/null |
        awk -F '|' '
        /^[[:space:]]*(Path|---)/ { next }
        /^[[:space:]]+[a-zA-Z0-9.;_-]+[[:space:]]+\|/ {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1);
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2);
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3);
            printf "| %s | %s | %s |\n", $1, $2, $3
        }' | sort
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
    cat <<EOF
<details><summary><b>🐳 Docker Image Content: <code>${image_tag}</code></b></summary>

#### 🤖 Android SDK Components
| Component | Version | Description |
| :--- | :--- | :--- |
$(get_sdk_components)

#### 📦 Installed OS Packages (apk)
<details><summary>Click to view APK list</summary>

| Package | Version |
| :--- | :--- |
$(get_apk_packages)

</details>
</details>

EOF
}

generate_markdown_body >>"$report_file"
