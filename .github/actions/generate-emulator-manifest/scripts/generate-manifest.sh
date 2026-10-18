#!/usr/bin/env bash
set -euo pipefail

image=$1
image_tag=$2
report_file=$3

get_adb() {
    local adb_version
    adb_version=$(
        docker run --rm "$image" adb -version 2>/dev/null | grep -oP 'Android Debug Bridge version \K[0-9.]+'
    )

    if [ -z "$adb_version" ]; then
        echo "Error: 'adb version' returns no output." >&2
        return 1
    fi

    printf "| adb | %s | Android Debug Bridge |\n" "$adb_version"
}

get_emulator() {
    local emulator_version
    emulator_version=$(
        docker run --rm "${image}" emulator -version 2>&1 | grep -oP 'Android emulator version \K[0-9.]+'
    )

    if [ -z "$emulator_version" ]; then
        echo "Error: 'emulator version' returns no output." >&2
        return 1
    fi

    printf "| emulator | %s | Android Emulator |\n" "$emulator_version"
}

get_system_image() {
    local package_xml
    local parsed
    local display_name
    local api_level
    local revision

    package_xml="$(docker run --rm "${image}" sh -c \
        'find "${ANDROID_HOME}/system-images" -name package.xml -exec cat {} +')"

    parsed="$(
        awk '
        function tag_value(line, tag) {
            sub(".*<" tag ">", "", line)
            sub("</" tag ">.*", "", line)
            return line
        }
        /<api-level>/        { api_level = tag_value($0, "api-level") }
        /<display-name>/ { display_name = tag_value($0, "display-name") }
        /<revision>/         { in_revision = 1 }
        /<\/revision>/     { in_revision = 0 }
        in_revision && /<major>/ && major == "" { major = tag_value($0, "major") }
        in_revision && /<minor>/ && minor == "" { minor = tag_value($0, "minor") }
        in_revision && /<micro>/ && micro == "" { micro = tag_value($0, "micro") }
        END {
            if (display_name == "" || api_level == "" || major == "") {
                print "Missing required field in package.xml" > "/dev/stderr"
                exit 1
            }
            printf "%s|%s|%s.%s.%s\n", display_name, api_level, \
                major, (minor == "" ? 0 : minor), (micro == "" ? 0 : micro)
        }
        ' <<<"${package_xml}"
    )"

    IFS='|' read -r display_name api_level revision <<<"${parsed}"

    printf '| system-image | %s (API %s) | %s |\n' \
        "${revision}" "${api_level}" "${display_name}"
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
    local adb_row
    local emulator_row
    local system_image_row
    local apk_rows

    adb_row=$(get_adb)
    emulator_row=$(get_emulator)
    system_image_row=$(get_system_image)
    apk_rows=$(get_apk_packages)

    cat <<EOF
<details><summary><b>🐋 Docker Image Content: <code>${image_tag}</code></b></summary>

#### 🤖 Android SDK Components
| Component | Version | Description |
| :--- | :--- | :--- |
${adb_row}
${emulator_row}
${system_image_row}

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
