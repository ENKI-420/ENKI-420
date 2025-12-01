#!/usr/bin/env bash
#
# ╔══════════════════════════════════════════════════════════════════════════════════╗
# ║  TORSION RAIN - Polarized ASCII Rain at 51.843° Angular Torsion                  ║
# ║  Agile Defense Systems, LLC | CAGE: 9HUP5 | dna::}{::lang™                       ║
# ╚══════════════════════════════════════════════════════════════════════════════════╝
#
# Creates a Matrix-style falling character effect with DNA codons,
# quantum state indicators, and ΛΦ symbols at 51.843° angular torsion.
#
# Usage: ./torsion-rain.sh [options]
#   -d, --duration    Duration in seconds (default: infinite)
#   -s, --speed       Drop speed 1-10 (default: 5)
#   -c, --color       Color mode: green, purple, gold, rainbow (default: green)
#   -h, --help        Show this help message
#
# © 2025 Agile Defense Systems, LLC. All Rights Reserved.

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# Angular torsion: 51.843° (tan ≈ 1.27)
readonly TORSION_ANGLE=51.843
readonly TORSION_TAN=1.27

# Default settings
DURATION=0  # 0 = infinite
SPEED=5
COLOR_MODE="green"

# DNA Codons (subset of genetic code)
readonly -a DNA_CODONS=(
    "ATG" "TAC" "GCA" "CGT" "AAA" "TTT" "GGG" "CCC"
    "AGT" "TCA" "GAT" "CTA" "AGA" "TCT" "GAG" "CTC"
    "AUG" "UAC" "GCU" "CGU" "AAA" "UUU" "GGG" "CCC"
)

# Quantum state indicators
readonly -a QUANTUM_STATES=(
    "|0⟩" "|1⟩" "|+⟩" "|−⟩" 
    "|Ψ⟩" "|Φ⟩" "⟨0|" "⟨1|"
)

# Special symbols
readonly -a SPECIAL_SYMBOLS=(
    "ΛΦ" "Φ" "Ψ" "Ω" "Ξ" "Γ" "Λ" "Σ"
    "∿" "≈" "∞" "√" "∂" "∫" "∇" "π"
    "═" "║" "╔" "╗" "╚" "╝" "╠" "╣"
)

# Single characters for standard rain
readonly -a RAIN_CHARS=(
    "0" "1" "A" "T" "G" "C" "U"
    "α" "β" "γ" "δ" "ε" "θ" "λ" "μ" "σ" "φ" "ψ" "ω"
    "│" "┃" "║" "┊" "┆" "┇" "┋"
)

# ═══════════════════════════════════════════════════════════════════════════════
# ANSI COLOR CODES
# ═══════════════════════════════════════════════════════════════════════════════

declare -A COLORS
COLORS=(
    [RESET]="\033[0m"
    [BOLD]="\033[1m"
    [DIM]="\033[2m"
    
    # Green theme (Matrix)
    [GREEN_BRIGHT]="\033[1;92m"
    [GREEN]="\033[0;32m"
    [GREEN_DIM]="\033[2;32m"
    
    # Purple theme (Quantum)
    [PURPLE_BRIGHT]="\033[1;95m"
    [PURPLE]="\033[0;35m"
    [PURPLE_DIM]="\033[2;35m"
    
    # Gold theme (dna::}{::lang)
    [GOLD_BRIGHT]="\033[1;93m"
    [GOLD]="\033[0;33m"
    [GOLD_DIM]="\033[2;33m"
    
    # Blue theme
    [BLUE_BRIGHT]="\033[1;94m"
    [BLUE]="\033[0;34m"
    [BLUE_DIM]="\033[2;34m"
    
    # Cyan theme
    [CYAN_BRIGHT]="\033[1;96m"
    [CYAN]="\033[0;36m"
    [CYAN_DIM]="\033[2;36m"
    
    # White
    [WHITE_BRIGHT]="\033[1;97m"
    [WHITE]="\033[0;37m"
    [WHITE_DIM]="\033[2;37m"
)

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════╗
║  TORSION RAIN - Polarized ASCII Rain at 51.843° Angular Torsion                  ║
║  Agile Defense Systems, LLC | CAGE: 9HUP5 | dna::}{::lang™                       ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                  ║
║  Usage: ./torsion-rain.sh [options]                                              ║
║                                                                                  ║
║  Options:                                                                        ║
║    -d, --duration <seconds>   Duration in seconds (default: infinite)            ║
║    -s, --speed <1-10>         Drop speed 1=slow, 10=fast (default: 5)            ║
║    -c, --color <mode>         Color mode (default: green)                        ║
║                               Options: green, purple, gold, rainbow              ║
║    -h, --help                 Show this help message                             ║
║                                                                                  ║
║  Examples:                                                                       ║
║    ./torsion-rain.sh                          # Default green, infinite          ║
║    ./torsion-rain.sh -d 30 -c purple          # Purple for 30 seconds            ║
║    ./torsion-rain.sh --speed 8 --color gold   # Fast gold rain                   ║
║                                                                                  ║
║  Technical Notes:                                                                ║
║    • Angular torsion: 51.843° (tan ≈ 1.27)                                       ║
║    • Characters shift right by ~1.27 positions per row descent                   ║
║    • Creates helical/spiral appearance matching DNA torsion                      ║
║    • Press Ctrl+C to exit                                                        ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--duration)
                DURATION="$2"
                shift 2
                ;;
            -s|--speed)
                SPEED="$2"
                if [[ $SPEED -lt 1 ]] || [[ $SPEED -gt 10 ]]; then
                    echo "Error: Speed must be between 1 and 10"
                    exit 1
                fi
                shift 2
                ;;
            -c|--color)
                COLOR_MODE="$2"
                if [[ ! "$COLOR_MODE" =~ ^(green|purple|gold|rainbow)$ ]]; then
                    echo "Error: Color mode must be: green, purple, gold, or rainbow"
                    exit 1
                fi
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

# Get terminal dimensions
get_terminal_size() {
    TERM_COLS=$(tput cols)
    TERM_ROWS=$(tput lines)
}

# Get a random character/symbol for the rain
get_rain_char() {
    local type=$((RANDOM % 100))
    
    if [[ $type -lt 50 ]]; then
        # 50% - Single rain character
        echo "${RAIN_CHARS[$((RANDOM % ${#RAIN_CHARS[@]}))]}"
    elif [[ $type -lt 75 ]]; then
        # 25% - DNA codon
        echo "${DNA_CODONS[$((RANDOM % ${#DNA_CODONS[@]}))]}"
    elif [[ $type -lt 90 ]]; then
        # 15% - Quantum state
        echo "${QUANTUM_STATES[$((RANDOM % ${#QUANTUM_STATES[@]}))]}"
    else
        # 10% - Special symbol
        echo "${SPECIAL_SYMBOLS[$((RANDOM % ${#SPECIAL_SYMBOLS[@]}))]}"
    fi
}

# Get color based on intensity (0-2: dim, mid, bright)
get_color() {
    local intensity=$1
    local colors_bright colors_mid colors_dim
    
    case $COLOR_MODE in
        green)
            colors_bright="${COLORS[GREEN_BRIGHT]}"
            colors_mid="${COLORS[GREEN]}"
            colors_dim="${COLORS[GREEN_DIM]}"
            ;;
        purple)
            colors_bright="${COLORS[PURPLE_BRIGHT]}"
            colors_mid="${COLORS[PURPLE]}"
            colors_dim="${COLORS[PURPLE_DIM]}"
            ;;
        gold)
            colors_bright="${COLORS[GOLD_BRIGHT]}"
            colors_mid="${COLORS[GOLD]}"
            colors_dim="${COLORS[GOLD_DIM]}"
            ;;
        rainbow)
            local rainbow_colors=("GREEN_BRIGHT" "PURPLE_BRIGHT" "GOLD_BRIGHT" "BLUE_BRIGHT" "CYAN_BRIGHT")
            local color_key="${rainbow_colors[$((RANDOM % ${#rainbow_colors[@]}))]}"
            colors_bright="${COLORS[$color_key]}"
            colors_mid="${COLORS[${color_key/BRIGHT/}]:-${COLORS[$color_key]}}"
            colors_dim="${COLORS[${color_key/BRIGHT/DIM}]:-${COLORS[$color_key]}}"
            ;;
    esac
    
    case $intensity in
        0) echo "$colors_dim" ;;
        1) echo "$colors_mid" ;;
        *) echo "$colors_bright" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# RAIN DROP CLASS (simulated with arrays)
# ═══════════════════════════════════════════════════════════════════════════════

# Arrays to track drops
declare -a DROP_COL        # Current column position
declare -a DROP_ROW        # Current row position
declare -a DROP_LENGTH     # Trail length
declare -a DROP_SPEED      # Individual speed
declare -a DROP_START_COL  # Starting column (for torsion calc)
declare -a DROP_CHARS      # Character trail

MAX_DROPS=0
ACTIVE_DROPS=0

init_drops() {
    MAX_DROPS=$((TERM_COLS / 3))
    
    for ((i = 0; i < MAX_DROPS; i++)); do
        DROP_COL[$i]=-1
        DROP_ROW[$i]=-1
        DROP_LENGTH[$i]=0
        DROP_SPEED[$i]=1
        DROP_START_COL[$i]=0
        DROP_CHARS[$i]=""
    done
    
    ACTIVE_DROPS=0
}

spawn_drop() {
    local slot=-1
    
    # Find empty slot
    for ((i = 0; i < MAX_DROPS; i++)); do
        if [[ ${DROP_COL[$i]} -eq -1 ]]; then
            slot=$i
            break
        fi
    done
    
    if [[ $slot -eq -1 ]]; then
        return
    fi
    
    local start_col=$((RANDOM % TERM_COLS))
    DROP_COL[$slot]=$start_col
    DROP_START_COL[$slot]=$start_col
    DROP_ROW[$slot]=0
    DROP_LENGTH[$slot]=$((RANDOM % 10 + 5))
    DROP_SPEED[$slot]=$((RANDOM % 3 + 1))
    DROP_CHARS[$slot]=""
    
    # Pre-generate character trail
    local chars=""
    for ((j = 0; j < ${DROP_LENGTH[$slot]}; j++)); do
        chars+="$(get_rain_char)|"
    done
    DROP_CHARS[$slot]="$chars"
    
    ((ACTIVE_DROPS++))
}

update_drop() {
    local slot=$1
    
    if [[ ${DROP_COL[$slot]} -eq -1 ]]; then
        return
    fi
    
    local row=${DROP_ROW[$slot]}
    local start_col=${DROP_START_COL[$slot]}
    local length=${DROP_LENGTH[$slot]}
    local speed=${DROP_SPEED[$slot]}
    
    # Calculate torsion offset: column shifts right by tan(51.843°) ≈ 1.27 per row
    # Using integer approximation: shift by 1 every row, plus extra shift every ~4 rows
    local torsion_offset=$(( (row * 127) / 100 ))
    local col=$(( (start_col + torsion_offset) % TERM_COLS ))
    
    DROP_COL[$slot]=$col
    
    # Move drop down
    ((DROP_ROW[$slot] += speed))
    
    # Check if drop is off screen
    if [[ ${DROP_ROW[$slot]} -gt $((TERM_ROWS + length)) ]]; then
        DROP_COL[$slot]=-1
        ((ACTIVE_DROPS--))
    fi
}

render_drop() {
    local slot=$1
    
    if [[ ${DROP_COL[$slot]} -eq -1 ]]; then
        return
    fi
    
    local col=${DROP_COL[$slot]}
    local row=${DROP_ROW[$slot]}
    local length=${DROP_LENGTH[$slot]}
    local start_col=${DROP_START_COL[$slot]}
    local chars="${DROP_CHARS[$slot]}"
    
    IFS='|' read -ra char_array <<< "$chars"
    
    for ((i = 0; i < length && i < ${#char_array[@]}; i++)); do
        local draw_row=$((row - i))
        
        if [[ $draw_row -lt 0 ]] || [[ $draw_row -ge $TERM_ROWS ]]; then
            continue
        fi
        
        # Calculate column with torsion for this specific row
        local torsion_offset=$(( (draw_row * 127) / 100 ))
        local draw_col=$(( (start_col + torsion_offset) % TERM_COLS ))
        
        # Intensity: brightest at head (i=0), dimmer toward tail
        local intensity
        if [[ $i -eq 0 ]]; then
            intensity=2
        elif [[ $i -lt $((length / 2)) ]]; then
            intensity=1
        else
            intensity=0
        fi
        
        local color
        color=$(get_color $intensity)
        local char="${char_array[$i]:-│}"
        
        # Move cursor and print
        printf "\033[%d;%dH%b%s%b" "$((draw_row + 1))" "$((draw_col + 1))" "$color" "$char" "${COLORS[RESET]}"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN ANIMATION LOOP
# ═══════════════════════════════════════════════════════════════════════════════

cleanup() {
    # Show cursor
    tput cnorm
    # Reset terminal
    printf "%b" "${COLORS[RESET]}"
    clear
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  TORSION RAIN terminated                                         ║"
    echo "║  © 2025 Agile Defense Systems, LLC | CAGE: 9HUP5                 ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    exit 0
}

show_header() {
    printf "%b" "${COLORS[GOLD_BRIGHT]}"
    cat << 'HEADER'
╔══════════════════════════════════════════════════════════════════════════════════╗
║  TORSION RAIN - 51.843° Angular Polarization                                     ║
║  Agile Defense Systems, LLC | CAGE: 9HUP5 | dna::}{::lang™                       ║
║  Press Ctrl+C to exit                                                            ║
╚══════════════════════════════════════════════════════════════════════════════════╝
HEADER
    printf "%b" "${COLORS[RESET]}"
    sleep 2
}

main_loop() {
    local start_time
    start_time=$(date +%s)
    local frame=0
    
    # Calculate delay based on speed (1-10)
    # Speed 1 = 0.2s delay, Speed 10 = 0.02s delay
    local delay
    delay=$(awk "BEGIN {printf \"%.3f\", 0.22 - ($SPEED * 0.02)}")
    
    while true; do
        # Check duration
        if [[ $DURATION -gt 0 ]]; then
            local current_time
            current_time=$(date +%s)
            if [[ $((current_time - start_time)) -ge $DURATION ]]; then
                break
            fi
        fi
        
        # Update terminal size
        get_terminal_size
        
        # Spawn new drops randomly
        local spawn_chance=$((SPEED * 10))
        if [[ $((RANDOM % 100)) -lt $spawn_chance ]] && [[ $ACTIVE_DROPS -lt $MAX_DROPS ]]; then
            spawn_drop
        fi
        
        # Update and render all drops
        for ((i = 0; i < MAX_DROPS; i++)); do
            update_drop $i
            render_drop $i
        done
        
        # Occasional special effect: Print ΛΦ coupling indicator
        if [[ $((frame % 50)) -eq 0 ]]; then
            local fx_row=$((RANDOM % (TERM_ROWS - 1) + 1))
            local fx_col=$((RANDOM % (TERM_COLS - 20) + 1))
            printf "\033[%d;%dH%b ΛΦ=2.176435×10⁻⁸ %b" "$fx_row" "$fx_col" "${COLORS[WHITE_BRIGHT]}" "${COLORS[RESET]}"
        fi
        
        # Quantum state overlay
        if [[ $((frame % 30)) -eq 0 ]]; then
            local q_row=$((RANDOM % (TERM_ROWS - 1) + 1))
            local q_col=$((RANDOM % (TERM_COLS - 10) + 1))
            local q_state="${QUANTUM_STATES[$((RANDOM % ${#QUANTUM_STATES[@]}))]}"
            printf "\033[%d;%dH%b%s%b" "$q_row" "$q_col" "${COLORS[CYAN_BRIGHT]}" "$q_state" "${COLORS[RESET]}"
        fi
        
        ((frame++))
        sleep "$delay"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    parse_args "$@"
    
    # Setup
    trap cleanup EXIT INT TERM
    
    # Hide cursor
    tput civis
    
    # Clear screen
    clear
    
    # Show header briefly
    show_header
    
    # Clear again for animation
    clear
    
    # Get initial terminal size
    get_terminal_size
    
    # Initialize drops
    init_drops
    
    # Run animation
    main_loop
}

main "$@"
