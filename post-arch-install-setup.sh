#!/usr/bin/env bash
set -uo pipefail


# ============================================
# SECTION 1: Global Variables & Colors
# ============================================
BOLD_ORANGE='\033[1;33m'
NO_COLOR='\033[0m'
GUM_PINK="212"
GUM_GREEN="76"
GUM_YELLOW="226"
GUM_RED="196"
GUM_BLUE="75"
REPO_URL="https://github.com/Swayam-SMishra/post-arch"
RAW_FILE_URL="https://raw.githubusercontent.com/Swayam-SMishra/post-arch/refs/heads/main/"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"


# ============================================
# SECTION 2: Root Check
# ============================================
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as sudo"
   exit 1
fi


# ============================================
# SECTION 3: Gum Installation Check
# ============================================
check_gum() {
    if command -v gum &> /dev/null; then
        gum log info "Gum is already installed"
    else
        echo -e "${BOLD_ORANGE}WARNING:${NO_COLOR} Gum not found. Installing..."
        pacman -Sy --needed gum --noconfirm
    fi
}


# ============================================
# SECTION 4: Welcome Banner
# ============================================
show_banner() {
    gum style \
        --foreground "$GUM_PINK" \
        --border-foreground "$GUM_PINK" \
        --border double \
        --align center \
        --width 50 \
        --margin "1 2" \
        --padding "1 2" \
        'Arch Linux Post-Install Script By Swayam' 'Ready to configure your system!'
}

check_full_system_update() {
    gum confirm \
        --show-output "Run full system update ?" && \
    gum spin \
        --title "Updating system..." \
        --title.foreground="212" \
        --padding="2 0"  \
        --show-output -- pacman -Syu --noconfirm
}

# ============================================
# SECTION 5: Package Selection (gum filter)
# ============================================
select_packages() {
    local packages=(
        "neovim"
        "micro"
        "htop"
        "btop"
        "git"
        "curl"
        "wget"
        "zed"
        "fish"
        "zsh"
        "tmux"
        "zellij"
        "nushell"
        "fastfetch"
        "yazi"
        "fzf"
        "eza"
        "jq"
        "poppler"
        "zoxide"
        "foot"
        "kitty"
        "termius"
        "remmina"
        "thunar"
        "gvfs"
        "thunar-volman"
        "zen-browser-bin"
        "brave-bin"
        "kvantum-qt5"
        "nwg-look"
        "qt6ct"
        "ark"
        "mpv"
        "reflector"
        "kde-connect"
        "podman"
        "docker"
        "docker-compose"
        "easyeffects"
        "termusic"
        "freetube"
        "yt-dlp"
        "localsend"
        "croc"
        "flatpak"
        "timeshift"
        "kdiskmark"
        "ncdu"
        "gparted"
        "obsidian"
        "flameshot"
        "ristretto"
        "zathura"
        "zathura-pdf-poppler"
        "ttf-hack"
        "ttf-0xproto-nerd"
        "ttf-jetbrains-mono-nerd"
    )
    
    SELECTED=$(gum filter --no-limit \
        --indicator " >" \
        --placeholder "Select packages to install " \
        --selected-prefix "[✓]" \
        --unselected-prefix "[ ]" \
        "${packages[@]}")
    
    echo "$SELECTED"
}


# ============================================
# SECTION 6: Confirmation
# ============================================
confirm_install() {
    gum confirm "Install $SELECTED_COUNT packages?" || exit 0
}
# ============================================
# SECTION 7: Package Installation (gum spin)
# ============================================
install_packages() {
    local packages=("$@")
    local total=${#packages[@]}
    local current=0

    for pkg in "${packages[@]}"; do
        ((current++))
        gum spin --title "Installing ($current/$total): $pkg" -- \
            bash -c "pacman -S --needed --noconfirm \"$pkg\" || { echo \"Failed to install $pkg.\"; exit 1; }" 2>&1 | \
            {
                # Read pacman output line by line
                while IFS= read -r line; do
                    gum log info "$pkg: $line" # Log all output as info
                done
            }
    done   

}


# ============================================
# SECTION 8: Error/Warning Logging
# ============================================
log_error() {
    gum log error "$1"
}
log_success() {
    gum log success "$1"
}
log_warn() {
    gum log warn "$1"
}
log_info() {
    gum log info "$1"
}


# ============================================
# SECTION 9: Fetch Configs (git clone / ghgrab)
# ============================================


check_npm() {
    if command -v npm &> /dev/null; then
        gum log info "Npm is already installed"
    else
        echo -e "${BOLD_ORANGE}WARNING:${NO_COLOR} Npm not found. Installing..."
        pacman -S --needed npm --noconfirm
    fi
}


fetch_configs_for_selected() {
    check_npm
    
    gum log info "Fetching configs for selected packages..."
    mkdir -p "${CONFIG_DIR}"

    # Using npm not pipx, as env path doesn't auto load into shell.
    gum log info "Setting up for Grabbing Files.."
    npm install -g @ghgrab/ghgrab

    ghgrab config set path ${CONFIG_DIR} && gum log info "Env Set.. Ready for file selection.."

    # select whole folder only, as single file from folder will download that file without directory name and have to manually move them to directory.
    ghgrab ${REPO_URL} --no-folder 
    ghgrab config unset path && gum log info "Env Cleared.."

    gum log success "Successfully fetched all files.. Kindly check files in config directory..   :)"
}


fetch_configs() {
    gum confirm "Fetch configs from GitHub ?" || return
    
    local config_choice=$(gum choose "git clone full repo" "fetch specific files")
    
    case "$config_choice" in
        "git clone full repo")
            gum spin --title "Cloning config repository..." -- \
                git clone "${REPO_URL}.git" "$CONFIG_DIR/post-install-configs" 2>&1 || log_error "Clone failed"
            ;;
        "fetch specific files")
            fetch_configs_for_selected
            ;;
    esac
}


# ============================================
# SECTION 10: Final Summary
# ============================================
show_summary() {
    gum style \
        --foreground "$GUM_GREEN" \
        --border-foreground "$GUM_GREEN" \
        --border double \
        --align center \
        --width 50 \
        "Installation Complete!" \
        "Selected: $SELECTED_COUNT packages"
}


# ============================================
# MAIN EXECUTION
# ============================================
main() {
    check_gum
    show_banner
    check_full_system_update
    
    packages=($(select_packages))
    SELECTED_COUNT=${#packages[@]}
    
    confirm_install
    install_packages "${packages[@]}"
    show_summary

    fetch_configs
}
main "$@"
