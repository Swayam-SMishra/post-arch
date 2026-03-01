#!/usr/bin/env bash
set -euo pipefail


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
REPO_URL="https://github.com/Swayam-SMishra/post-arch.git"
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
        pacman -S --needed gum
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


# ============================================
# SECTION 5: Package Selection (gum filter)
# ============================================
select_packages() {
    local packages=(
        "neovim"
        "micro"
        "htop"
        "btop"
        "curl"
        "wget"
        # "yay"
        # "paru"
        "ttf-hack"
        "ttf-0xproto-nerd"
        "ttf-jetbrains-mono-nerd"
        "zed"
        "fish"
        "zsh"
        "nushell"
        "fastfetch"
        "yazi"
        "nerd-fonts"
        "foot"
        "kitty"
        "fzf"
        "tmux"
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
        "reminna"
        "kde-connect"
        "termius"
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
    )
    
    SELECTED=$(gum filter --no-limit \
        --indicator " >" \
        --placeholder "Select packages to install (space to toggle)" \
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
            pacman -S --needed --noconfirm "$pkg" 2>&1 | gum log warn "Failed: $pkg" || true
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
# SECTION 9: Fetch Configs (git clone / curl)
# ============================================
declare -A CONFIG_MAP=(
    ["nvim"]="nvim"
    ["zsh"]="zsh"
    ["fish"]="fish"
    ["tmux"]="tmux"
    ["kitty"]="kitty"
    ["alacritty"]="alacritty"
    ["foot"]="foot"
    ["yazi"]="yazi"
    ["fastfetch"]="fastfetch"
    ["zathura"]="zathura"
)


fetch_configs_for_selected() {
    local packages=("$@")
    local fetched=0
    local skipped=0
    
    gum log info "Fetching configs for selected packages..."
    
    for pkg in "${packages[@]}"; do
        local config_path="${CONFIG_MAP[$pkg]:-}"
        
        if [[ -z "$config_path" ]]; then
            ((skipped++))
            continue
        fi
        
        local url="https://raw.githubusercontent.com/Swayam-SMishra/post-arch/main/$config_path"
        local dest="$CONFIG_DIR/$pkg"
        
        if gum spin --title "Fetching config for $pkg..." -- \
            curl -fsSL "$url" -o "$dest" 2>/dev/null; then
            gum log success "Fetched config: $pkg → $dest"
            ((fetched++))
        else
            gum log warn "No config found for $pkg (skipping)"
            ((skipped++))
        fi
    done
    
    gum log info "Config fetch complete: $fetched fetched, $skipped skipped"
}


fetch_configs() {
    gum confirm "Fetch dotfiles/configs from GitHub?" || return
    
    local config_choice=$(gum choose "git clone full repo" "curl specific files")
    
    case "$config_choice" in
        "git clone full repo")
            gum spin --title "Cloning config repository..." -- \
                git clone "$REPO_URL" "$CONFIG_DIR/post-install-configs" 2>&1 || log_error "Clone failed"
            ;;
        "curl specific files")
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
    echo "Syncing latest packages..." && pacman -Sy

    check_gum
    show_banner
    
    # Full system update
    gum spin --title "Updating system..." --title.foreground="212" --padding="2 0"  --show-output -- pacman -Syu --noconfirm
    
    packages=($(select_packages))
    SELECTED_COUNT=${#packages[@]}
    
    confirm_install
    install_packages "${packages[@]}"
    fetch_configs
    show_summary
}
main "$@"
