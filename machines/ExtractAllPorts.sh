#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  ExtractAllPorts — Nmap Port Extraction Utility             ║
# ║  Extracts open ports & IPs from scan results                ║
# ╚══════════════════════════════════════════════════════════════╝

# ─── Colors & Styles ───────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
RESET='\033[0m'

RED='\033[38;5;196m'
GREEN='\033[38;5;82m'
CYAN='\033[38;5;87m'
YELLOW='\033[38;5;220m'
MAGENTA='\033[38;5;213m'
BLUE='\033[38;5;75m'
ORANGE='\033[38;5;208m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;245m'

# ─── Symbols ──────────────────────────────────────────────────
CHECK="${GREEN}✔${RESET}"
CROSS="${RED}✘${RESET}"
ARROW="${CYAN}➜${RESET}"
BOLT="${YELLOW}⚡${RESET}"
CLIP="${MAGENTA}📋${RESET}"
SEARCH="${BLUE}🔍${RESET}"
INFO="${CYAN}ℹ${RESET}"

# ─── Banner ───────────────────────────────────────────────────
show_banner() {
    echo -e ""
    echo -e "${BOLD}${CYAN}  ╔═══════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  ${BOLD}${MAGENTA}⚡ ${WHITE}E x t r a c t ${MAGENTA}A l l ${WHITE}P o r t s ${MAGENTA}⚡${RESET}  ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ╠═══════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  ${DIM}${GRAY}Nmap Open Port Extraction Utility${RESET}              ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚═══════════════════════════════════════════════════╝${RESET}"
    echo -e ""
}

# ─── Separator ────────────────────────────────────────────────
separator() {
    echo -e "  ${DIM}${GRAY}─────────────────────────────────────────────────────${RESET}"
}

# ─── Extract Ports Function ───────────────────────────────────
extractPorts() {
    local file="$1"
    local ports ip_address port_count

    # Validate file
    if [[ ! -f "$file" ]]; then
        echo -e "  ${CROSS} ${RED}File not found:${RESET} ${ITALIC}${file}${RESET}"
        return 1
    fi

    echo -e "  ${SEARCH} ${BOLD}${WHITE}Scanning:${RESET} ${ITALIC}${BLUE}${file}${RESET}"
    separator

    # Extract data
    ports="$(grep -oP '\d{1,5}/open' "$file" | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' "$file" | sort -u | head -n 1)"

    # Validate results
    if [[ -z "$ports" ]]; then
        echo -e "  ${CROSS} ${YELLOW}No open ports found in this file.${RESET}"
        echo ""
        return 1
    fi

    # Count ports
    port_count=$(echo "$ports" | tr ',' '\n' | wc -l)

    # Display results
    echo -e ""
    echo -e "  ${ARROW} ${BOLD}${WHITE}IP Address${RESET}   ${DIM}│${RESET}  ${GREEN}${ip_address:-"N/A"}${RESET}"
    echo -e "  ${ARROW} ${BOLD}${WHITE}Open Ports${RESET}   ${DIM}│${RESET}  ${YELLOW}${ports}${RESET}"
    echo -e "  ${ARROW} ${BOLD}${WHITE}Port Count${RESET}   ${DIM}│${RESET}  ${ORANGE}${port_count}${RESET} ${DIM}ports detected${RESET}"
    echo -e ""

    # Copy to clipboard
    if command -v xclip &>/dev/null; then
        echo -n "$ports" | xclip -sel clip
        echo -e "  ${CLIP} ${CHECK} ${GREEN}Ports copied to clipboard!${RESET}"
    elif command -v xsel &>/dev/null; then
        echo -n "$ports" | xsel --clipboard
        echo -e "  ${CLIP} ${CHECK} ${GREEN}Ports copied to clipboard!${RESET}"
    elif command -v wl-copy &>/dev/null; then
        echo -n "$ports" | wl-copy
        echo -e "  ${CLIP} ${CHECK} ${GREEN}Ports copied to clipboard!${RESET}"
    else
        echo -e "  ${INFO} ${DIM}${GRAY}No clipboard tool found (xclip/xsel/wl-copy).${RESET}"
        echo -e "  ${INFO} ${DIM}${GRAY}Ports:${RESET} ${WHITE}${ports}${RESET}"
    fi

    echo -e ""
}

# ─── Usage Message ────────────────────────────────────────────
show_usage() {
    echo -e ""
    echo -e "  ${CROSS} ${RED}${BOLD}No input file provided.${RESET}"
    echo -e ""
    echo -e "  ${BOLD}${WHITE}Usage:${RESET}"
    echo -e "    ${DIM}\$${RESET} ${GREEN}$0${RESET} ${ITALIC}${GRAY}<file1> [file2] [file3] ...${RESET}"
    echo -e ""
    echo -e "  ${BOLD}${WHITE}Example:${RESET}"
    echo -e "    ${DIM}\$${RESET} ${GREEN}$0${RESET} ${CYAN}allPorts.gnmap${RESET}"
    echo -e "    ${DIM}\$${RESET} ${GREEN}$0${RESET} ${CYAN}scan1.gnmap scan2.gnmap${RESET}"
    echo -e ""
}

# ─── Main ─────────────────────────────────────────────────────
main() {
    show_banner

    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local total_files=$#
    local current=0

    for file in "$@"; do
        ((current++))

        if [[ $total_files -gt 1 ]]; then
            echo -e "  ${BOLT} ${BOLD}${ORANGE}[ ${current}/${total_files} ]${RESET}"
        fi

        extractPorts "$file"

        if [[ $current -lt $total_files ]]; then
            separator
        fi
    done

    separator
    echo -e "  ${CHECK} ${BOLD}${GREEN}Done!${RESET} ${DIM}${GRAY}Processed ${total_files} file(s).${RESET}"
    echo -e ""
}

main "$@"
