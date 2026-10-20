#!/usr/bin/env bash
set -euo pipefail

image=$1
image_tag=$2
report_file=$3

get_android_package_info() {
    local package_dir=$1
    local package_xml
    local parsed
    local package_path
    local display_name
    local version

    package_xml="$(docker run --rm --entrypoint sh "${image}" -c \
        "find \"\${ANDROID_HOME}/${package_dir}\" -name package.xml -exec cat {} +")"

    parsed="$(
        awk '
        function tag_value(line, tag) {
            sub(".*<" tag ">", "", line)
            sub("</" tag ">.*", "", line)
            return line
        }
        /<localPackage / {
            match($0, /path="[^"]*"/)
            package_path = substr($0, RSTART + 6, RLENGTH - 7)
            gsub(/;/, "/", package_path)
        }
        /<display-name>/ { display_name = tag_value($0, "display-name") }
        /<revision>/     { in_revision = 1 }
        /<\/revision>/   { in_revision = 0 }
        in_revision && /<major>/ && major == "" { major = tag_value($0, "major") }
        in_revision && /<minor>/ && minor == "" { minor = tag_value($0, "minor") }
        in_revision && /<micro>/ && micro == "" { micro = tag_value($0, "micro") }
        END {
            if (package_path == "" || display_name == "" || major == "") {
                print "Missing required field in package.xml" > "/dev/stderr"
                exit 1
            }
            printf "%s|%s|%s.%s.%s\n", package_path, display_name, \
                major, (minor == "" ? 0 : minor), (micro == "" ? 0 : micro)
        }
        ' <<<"${package_xml}"
    )"

    IFS='|' read -r package_path display_name version <<<"${parsed}"

    printf '| %s | %s | %s |\n' "${package_path}" "${version}" "${display_name}"
}

get_apk_packages() {
    local output
    output=$(docker run --rm --entrypoint apk "$image" info -v 2>/dev/null |
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
    local platform_tools_row
    local emulator_row
    local system_image_row
    local apk_rows

    platform_tools_row=$(get_android_package_info "platform-tools")
    emulator_row=$(get_android_package_info "emulator")
    system_image_row=$(get_android_package_info "system-images")
    apk_rows=$(get_apk_packages)

    cat <<EOF
<details><summary><b>🐋 Docker Image Content: <code>${image_tag}</code></b></summary>

#### 🤖 Android SDK Components
| Component | Version | Description |
| :--- | :--- | :--- |
${platform_tools_row}
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
