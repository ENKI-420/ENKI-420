#!/usr/bin/env bash
#
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  IP-PROTECT-CONVERT - Document Conversion & IP Protection Script                 ║
# ║  Agile Defense Systems, LLC | CAGE: 9HUP5 | dna::}{::lang™                       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# Adds ASCII art header/footer watermarks to documents with IP protection notices,
# generates SHA-256 hash for integrity verification, and creates timestamped copies.
#
# Supported formats: .md, .txt, .py, .ts, .sh, .json
#
# Usage:
#   ./ip-protect-convert.sh document.md
#   ./ip-protect-convert.sh --batch ./documents/
#   ./ip-protect-convert.sh --output ./protected/ document.md
#   ./ip-protect-convert.sh --manifest ./protected/
#
# © 2025 Agile Defense Systems, LLC. All Rights Reserved.

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly VERSION="1.0.0"

# Company Information
readonly COMPANY_NAME="Agile Defense Systems, LLC"
readonly CAGE_CODE="9HUP5"
readonly DUNS_NUMBER="117678011"
readonly TRADEMARK="dna::}{::lang™"
readonly COPYRIGHT_YEAR="2025"
readonly WEBSITE="https://www.dnalang.dev"
readonly EMAIL="research@dnalang.dev"

# Output settings
OUTPUT_DIR=""
BATCH_MODE=false
MANIFEST_ONLY=false
VERBOSE=false

# Supported file extensions
readonly -a SUPPORTED_EXTENSIONS=(".md" ".txt" ".py" ".ts" ".sh" ".json")

# ═══════════════════════════════════════════════════════════════════════════════
# ASCII ART TEMPLATES
# ═══════════════════════════════════════════════════════════════════════════════

get_header_template() {
    local hash="$1"
    local timestamp="$2"
    local filename="$3"
    
    cat << EOF
╔══════════════════════════════════════════════════════════════════════════════════╗
║  AGILE DEFENSE SYSTEMS, LLC — PROPRIETARY & CONFIDENTIAL                         ║
║  CAGE: ${CAGE_CODE} | DUNS: ${DUNS_NUMBER} | ${TRADEMARK}                                     ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  Document: ${filename}
║  Document Hash: ${hash}
║  Generated: ${timestamp}
╠══════════════════════════════════════════════════════════════════════════════════╣

EOF
}

get_footer_template() {
    cat << EOF

╠══════════════════════════════════════════════════════════════════════════════════╣
║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.                         ║
║  This document contains trade secrets and proprietary information protected      ║
║  under 18 U.S.C. § 1836 (Defend Trade Secrets Act of 2016).                      ║
║  Unauthorized reproduction or distribution is prohibited.                        ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  ${TRADEMARK} is a registered trademark of ${COMPANY_NAME}             ║
║  Website: ${WEBSITE} | Email: ${EMAIL}                    ║
╚══════════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Language-specific comment wrappers
get_comment_header() {
    local ext="$1"
    local hash="$2"
    local timestamp="$3"
    local filename="$4"
    
    case "$ext" in
        .py)
            cat << EOF
"""
╔══════════════════════════════════════════════════════════════════════════════════╗
║  AGILE DEFENSE SYSTEMS, LLC — PROPRIETARY & CONFIDENTIAL                         ║
║  CAGE: ${CAGE_CODE} | DUNS: ${DUNS_NUMBER} | ${TRADEMARK}                                     ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  Document: ${filename}
║  Document Hash: ${hash}
║  Generated: ${timestamp}
╠══════════════════════════════════════════════════════════════════════════════════╣
║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.                         ║
║  Protected under 18 U.S.C. § 1836. Unauthorized reproduction prohibited.         ║
╚══════════════════════════════════════════════════════════════════════════════════╝
"""

EOF
            ;;
        .ts|.json)
            cat << EOF
/**
 * ╔══════════════════════════════════════════════════════════════════════════════════╗
 * ║  AGILE DEFENSE SYSTEMS, LLC — PROPRIETARY & CONFIDENTIAL                         ║
 * ║  CAGE: ${CAGE_CODE} | DUNS: ${DUNS_NUMBER} | ${TRADEMARK}                                     ║
 * ╠══════════════════════════════════════════════════════════════════════════════════╣
 * ║  Document: ${filename}
 * ║  Document Hash: ${hash}
 * ║  Generated: ${timestamp}
 * ╠══════════════════════════════════════════════════════════════════════════════════╣
 * ║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.                         ║
 * ║  Protected under 18 U.S.C. § 1836. Unauthorized reproduction prohibited.         ║
 * ╚══════════════════════════════════════════════════════════════════════════════════╝
 */

EOF
            ;;
        .sh)
            cat << EOF
#!/usr/bin/env bash
#
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  AGILE DEFENSE SYSTEMS, LLC — PROPRIETARY & CONFIDENTIAL                         ║
# ║  CAGE: ${CAGE_CODE} | DUNS: ${DUNS_NUMBER} | ${TRADEMARK}                                     ║
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  Document: ${filename}
# ║  Document Hash: ${hash}
# ║  Generated: ${timestamp}
# ╠══════════════════════════════════════════════════════════════════════════════════╣
# ║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.                         ║
# ║  Protected under 18 U.S.C. § 1836. Unauthorized reproduction prohibited.         ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#

EOF
            ;;
        *)
            get_header_template "$hash" "$timestamp" "$filename"
            ;;
    esac
}

get_comment_footer() {
    local ext="$1"
    
    case "$ext" in
        .py)
            cat << EOF

"""
╔══════════════════════════════════════════════════════════════════════════════════╗
║  END OF PROTECTED DOCUMENT                                                       ║
║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.                         ║
║  ${TRADEMARK} — CAGE: ${CAGE_CODE}                                               ║
╚══════════════════════════════════════════════════════════════════════════════════╝
"""
EOF
            ;;
        .ts|.json)
            cat << EOF

/**
 * ╔══════════════════════════════════════════════════════════════════════════════════╗
 * ║  END OF PROTECTED DOCUMENT                                                       ║
 * ║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.                         ║
 * ║  ${TRADEMARK} — CAGE: ${CAGE_CODE}                                               ║
 * ╚══════════════════════════════════════════════════════════════════════════════════╝
 */
EOF
            ;;
        .sh)
            cat << EOF

#
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  END OF PROTECTED DOCUMENT                                                       ║
# ║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.                         ║
# ║  ${TRADEMARK} — CAGE: ${CAGE_CODE}                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
EOF
            ;;
        *)
            get_footer_template
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║     ██╗██████╗       ██████╗ ██████╗  ██████╗ ████████╗███████╗ ██████╗████████╗ ║
║     ██║██╔══██╗      ██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝ ║
║     ██║██████╔╝█████╗██████╔╝██████╔╝██║   ██║   ██║   █████╗  ██║        ██║    ║
║     ██║██╔═══╝ ╚════╝██╔═══╝ ██╔══██╗██║   ██║   ██║   ██╔══╝  ██║        ██║    ║
║     ██║██║           ██║     ██║  ██║╚██████╔╝   ██║   ███████╗╚██████╗   ██║    ║
║     ╚═╝╚═╝           ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝ ╚═════╝   ╚═╝    ║
║                                                                                  ║
║                    DOCUMENT CONVERSION & IP PROTECTION SYSTEM                    ║
║                                                                                  ║
║                    Agile Defense Systems, LLC | CAGE: 9HUP5                      ║
║                              dna::}{::lang™                                      ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
EOF
}

show_help() {
    show_banner
    cat << EOF

Usage: ${SCRIPT_NAME} [OPTIONS] <file|directory>

Options:
  -o, --output <dir>    Output directory for protected files
  -b, --batch           Process all supported files in directory
  -m, --manifest        Generate/update manifest only
  -v, --verbose         Enable verbose output
  -h, --help            Show this help message
  --version             Show version information

Supported file types: ${SUPPORTED_EXTENSIONS[*]}

Examples:
  ${SCRIPT_NAME} document.md
  ${SCRIPT_NAME} --batch ./documents/
  ${SCRIPT_NAME} --output ./protected/ document.md
  ${SCRIPT_NAME} --manifest ./protected/

Features:
  • Adds ASCII art header/footer watermarks
  • Inserts IP protection notices
  • Generates SHA-256 hash for integrity verification
  • Creates timestamped copies with embedded metadata
  • Adds dna::}{::lang™ trademark notice
  • Embeds CAGE Code and copyright

© ${COPYRIGHT_YEAR} ${COMPANY_NAME}. All Rights Reserved.
EOF
    exit 0
}

show_version() {
    echo "${SCRIPT_NAME} version ${VERSION}"
    echo "© ${COPYRIGHT_YEAR} ${COMPANY_NAME}"
    echo "CAGE: ${CAGE_CODE} | ${TRADEMARK}"
    exit 0
}

log_info() {
    echo "[INFO] $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*" >&2
}

# Check if file extension is supported
is_supported_extension() {
    local file="$1"
    local ext="${file##*.}"
    ext=".$ext"
    
    for supported in "${SUPPORTED_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$supported" ]]; then
            return 0
        fi
    done
    return 1
}

# Get file extension
get_extension() {
    local file="$1"
    local ext="${file##*.}"
    echo ".$ext"
}

# Generate SHA-256 hash of file content
generate_hash() {
    local file="$1"
    sha256sum "$file" | cut -d' ' -f1
}

# Generate ISO-8601 timestamp
generate_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CORE PROCESSING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

process_file() {
    local input_file="$1"
    local output_dir="${2:-$(dirname "$input_file")}"
    
    if [[ ! -f "$input_file" ]]; then
        log_error "File not found: $input_file"
        return 1
    fi
    
    if ! is_supported_extension "$input_file"; then
        log_error "Unsupported file type: $input_file"
        return 1
    fi
    
    local filename
    filename=$(basename "$input_file")
    local ext
    ext=$(get_extension "$input_file")
    local basename_no_ext="${filename%$ext}"
    local timestamp
    timestamp=$(generate_timestamp)
    local timestamp_safe="${timestamp//:/-}"
    
    # Generate hash of original content
    local original_hash
    original_hash=$(generate_hash "$input_file")
    
    # Create output filename with timestamp
    local output_file="${output_dir}/${basename_no_ext}_protected_${timestamp_safe}${ext}"
    
    log_info "Processing: $input_file"
    log_verbose "  Original hash: $original_hash"
    log_verbose "  Timestamp: $timestamp"
    log_verbose "  Output: $output_file"
    
    # Ensure output directory exists
    mkdir -p "$output_dir"
    
    # Read original content
    local original_content
    original_content=$(cat "$input_file")
    
    # Handle shebang for shell scripts
    local has_shebang=false
    local shebang_line=""
    if [[ "$ext" == ".sh" ]] && [[ "$original_content" == "#!"* ]]; then
        has_shebang=true
        shebang_line=$(echo "$original_content" | head -n1)
        original_content=$(echo "$original_content" | tail -n +2)
    fi
    
    # Build protected document
    {
        # For shell scripts, we already include shebang in the header template
        # For others, add header
        get_comment_header "$ext" "$original_hash" "$timestamp" "$filename"
        
        # Original content
        echo "$original_content"
        
        # Footer
        get_comment_footer "$ext"
        
    } > "$output_file"
    
    # Preserve file permissions
    chmod --reference="$input_file" "$output_file" 2>/dev/null || true
    
    # Generate hash of protected file
    local protected_hash
    protected_hash=$(generate_hash "$output_file")
    
    log_success "Protected file created: $output_file"
    log_verbose "  Protected hash: $protected_hash"
    
    # Return manifest entry
    echo "{\"original_file\":\"$input_file\",\"protected_file\":\"$output_file\",\"original_hash\":\"$original_hash\",\"protected_hash\":\"$protected_hash\",\"timestamp\":\"$timestamp\"}"
}

process_batch() {
    local input_dir="$1"
    local output_dir="${2:-$input_dir/protected}"
    
    if [[ ! -d "$input_dir" ]]; then
        log_error "Directory not found: $input_dir"
        return 1
    fi
    
    log_info "Batch processing directory: $input_dir"
    log_info "Output directory: $output_dir"
    
    mkdir -p "$output_dir"
    
    local manifest_entries=()
    local processed=0
    local skipped=0
    
    for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
        while IFS= read -r -d '' file; do
            local entry
            if entry=$(process_file "$file" "$output_dir"); then
                manifest_entries+=("$entry")
                ((processed++))
            else
                ((skipped++))
            fi
        done < <(find "$input_dir" -maxdepth 1 -type f -name "*$ext" -print0 2>/dev/null)
    done
    
    log_info "Processed: $processed files"
    log_info "Skipped: $skipped files"
    
    # Generate manifest
    generate_manifest "$output_dir" "${manifest_entries[@]}"
}

generate_manifest() {
    local output_dir="$1"
    shift
    local entries=("$@")
    
    local manifest_file="${output_dir}/manifest.json"
    local timestamp
    timestamp=$(generate_timestamp)
    
    log_info "Generating manifest: $manifest_file"
    
    {
        echo "{"
        echo "  \"manifest_version\": \"1.0.0\","
        echo "  \"generator\": \"${SCRIPT_NAME}\","
        echo "  \"generator_version\": \"${VERSION}\","
        echo "  \"company\": \"${COMPANY_NAME}\","
        echo "  \"cage_code\": \"${CAGE_CODE}\","
        echo "  \"duns_number\": \"${DUNS_NUMBER}\","
        echo "  \"trademark\": \"${TRADEMARK}\","
        echo "  \"generated_at\": \"${timestamp}\","
        echo "  \"documents\": ["
        
        local first=true
        for entry in "${entries[@]}"; do
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ","
            fi
            echo -n "    $entry"
        done
        
        echo ""
        echo "  ]"
        echo "}"
    } > "$manifest_file"
    
    log_success "Manifest generated: $manifest_file"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ARGUMENT PARSING
# ═══════════════════════════════════════════════════════════════════════════════

parse_args() {
    local positional_args=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -b|--batch)
                BATCH_MODE=true
                shift
                ;;
            -m|--manifest)
                MANIFEST_ONLY=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            --version)
                show_version
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                ;;
            *)
                positional_args+=("$1")
                shift
                ;;
        esac
    done
    
    set -- "${positional_args[@]}"
    
    if [[ ${#positional_args[@]} -eq 0 ]]; then
        log_error "No input file or directory specified"
        show_help
    fi
    
    INPUT_PATH="${positional_args[0]}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    parse_args "$@"
    
    show_banner
    echo ""
    
    if [[ "$MANIFEST_ONLY" == "true" ]]; then
        # Just regenerate manifest from existing protected files
        if [[ -d "$INPUT_PATH" ]]; then
            log_info "Regenerating manifest for: $INPUT_PATH"
            local entries=()
            for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
                while IFS= read -r -d '' file; do
                    local hash
                    hash=$(generate_hash "$file")
                    local ts
                    ts=$(generate_timestamp)
                    entries+=("{\"protected_file\":\"$file\",\"protected_hash\":\"$hash\",\"timestamp\":\"$ts\"}")
                done < <(find "$INPUT_PATH" -maxdepth 1 -type f -name "*$ext" -print0 2>/dev/null)
            done
            generate_manifest "$INPUT_PATH" "${entries[@]}"
        else
            log_error "Manifest mode requires a directory"
            exit 1
        fi
    elif [[ "$BATCH_MODE" == "true" ]]; then
        # Batch process directory
        process_batch "$INPUT_PATH" "${OUTPUT_DIR:-$INPUT_PATH/protected}"
    else
        # Single file processing
        if [[ -f "$INPUT_PATH" ]]; then
            local entry
            entry=$(process_file "$INPUT_PATH" "${OUTPUT_DIR:-$(dirname "$INPUT_PATH")}")
            if [[ -n "$OUTPUT_DIR" ]]; then
                generate_manifest "$OUTPUT_DIR" "$entry"
            fi
        elif [[ -d "$INPUT_PATH" ]]; then
            log_error "For directories, use --batch flag"
            exit 1
        else
            log_error "File or directory not found: $INPUT_PATH"
            exit 1
        fi
    fi
    
    echo ""
    log_info "IP protection complete"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  © ${COPYRIGHT_YEAR} ${COMPANY_NAME}                       ║"
    echo "║  CAGE: ${CAGE_CODE} | ${TRADEMARK}                                   ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
}

main "$@"
