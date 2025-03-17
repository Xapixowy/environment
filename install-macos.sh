#!/bin/bash

font_list=(
  font-fira-code-nerd-font
  font-fira-mono-nerd-font
  font-geist-mono-nerd-font
)

function command_exists() {
    command -v "$1" &> /dev/null
}

print_separator() {
    TERM_WIDTH=$(tput cols)
    printf ' %.0s' $(seq 1 $TERM_WIDTH)
    printf '=%.0s' $(seq 1 $TERM_WIDTH)
    printf ' %.0s' $(seq 1 $TERM_WIDTH)
    echo
}

function display_script_header() {
    echo "                                                               "
    echo "██╗  ██╗ █████╗ ██████╗ ██╗██╗  ██╗ ██████╗ ██╗    ██╗██╗   ██╗"
    echo "╚██╗██╔╝██╔══██╗██╔══██╗██║╚██╗██╔╝██╔═══██╗██║    ██║╚██╗ ██╔╝"
    echo " ╚███╔╝ ███████║██████╔╝██║ ╚███╔╝ ██║   ██║██║ █╗ ██║ ╚████╔╝ "
    echo " ██╔██╗ ██╔══██║██╔═══╝ ██║ ██╔██╗ ██║   ██║██║███╗██║  ╚██╔╝  "
    echo "██╔╝ ██╗██║  ██║██║     ██║██╔╝ ██╗╚██████╔╝╚███╔███╔╝   ██║   "
    echo "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝    ╚═╝   "
    echo "                                                               "
    echo "███████╗███╗   ██╗██╗   ██╗                                    "
    echo "██╔════╝████╗  ██║██║   ██║                                    "
    echo "█████╗  ██╔██╗ ██║██║   ██║                                    "
    echo "██╔══╝  ██║╚██╗██║╚██╗ ██╔╝                                    "
    echo "███████╗██║ ╚████║ ╚████╔╝██╗██╗██╗                            "
    echo "╚══════╝╚═╝  ╚═══╝  ╚═══╝ ╚═╝╚═╝╚═╝                            "
    echo "                                                               "
    echo "👋 Welcome to the Xapixowy's environment installation script!"
}

function display_system_info() {
    OS_NAME=$(sw_vers -productName)
    OS_VERSION=$(sw_vers -productVersion)
    OS_ARCH=$(uname -m)

    CPU_INFO=$(sysctl -n machdep.cpu.brand_string)
    GPU_INFO=$(system_profiler SPDisplaysDataType | awk -F': ' '/Chipset Model/ {print $2}' | head -n 1)
    MEMORY_INFO=$(system_profiler SPHardwareDataType | awk '/Memory:/ {print $2, $3}')
    TOTAL=$(df -H / | awk 'NR==2 {print $2}' | tr -d 'G')
    AVAILABLE=$(df -H / | awk 'NR==2 {print $4}' | tr -d 'G')
    USED=$(echo "$TOTAL - $AVAILABLE" | bc)

    echo "Here are some information about your system:"
    echo
    echo "📌 OS: $OS_NAME $OS_VERSION ($OS_ARCH)"
    echo "🖥️  CPU: $CPU_INFO"
    echo "🎮 GPU: $GPU_INFO"
    echo "💾 Memory: $MEMORY_INFO"
    echo "💽 Disk Usage: ${USED}GB / ${TOTAL}GB"
}

function ask_for_sudo() {
    echo "🔐 This script requires sudo privileges for installation."
    echo "💡 Please enter your password (it won't be displayed while typing)."

    if sudo -v; then
        tput cuu 2 && tput el
        tput cuu 1 && tput el
        echo "✅ Sudo privileges granted!"
    else
        echo "❌ Sudo authentication failed. Exiting..."
        exit 1
    fi
}

function decorate_with_logging() {
    local message="$1"
    shift
    local command="$1"
    shift

    echo -ne "⏳ $message in progress...\r"

    "$command" "$@" > /dev/null 2>&1
    local exit_code=$?

    if [[ "$exit_code" -ne 0 ]]; then
        echo -e "❌ $message stopped because of an error!"
        exit 1
    else
        echo -e "✅ $message completed successfully"
    fi
}

function install_homebrew() {
    if ! command_exists brew; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH (for Intel and Apple Silicon processors)
        if [[ "$(uname -m)" == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

function install_fonts() {
    brew tap homebrew/cask-fonts
    for font in "${font_list[@]}"
    do
        brew install --cask "$font"
    done
}

function install_ghostty() {
    brew install --cask ghostty > /dev/null 2>&1

    CONFIG_SOURCE="./configs/ghostty/config"
    CONFIG_DEST_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
    CONFIG_DEST="$CONFIG_DEST_DIR/config"

    if [ ! -d "$CONFIG_DEST_DIR" ]; then
        return 1
    fi

    cp "$CONFIG_SOURCE" "$CONFIG_DEST" > /dev/null 2>&1 || return 1

    return 0
}

function install_spaceship() {
    brew install spaceship > /dev/null 2>&1
}

function install_nvm_and_node() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install --lts > /dev/null 2>&1
}

function install_webstorm() {
    DOWNLOAD_PAGE="https://data.services.jetbrains.com/products/releases?code=WS&latest=true&type=release"
    JSON_RESPONSE=$(curl -s "$DOWNLOAD_PAGE")
    DOWNLOAD_LINK=$(echo "$JSON_RESPONSE" | grep -oE 'https://download\.jetbrains\.com/webstorm/WebStorm-[0-9.]+-aarch64\.dmg' | head -1)

    if [[ -z "$DOWNLOAD_LINK" ]]; then
        echo "❌ Failed to find the WebStorm download link for Apple Silicon!"
        exit 1
    fi

    curl -L "$DOWNLOAD_LINK" -o webstorm.dmg
    MOUNT_DIR=$(hdiutil attach webstorm.dmg | grep "Volumes" | awk '{print $3}')

    if [[ -z "$MOUNT_DIR" ]]; then
        echo "❌ Failed to mount the DMG file!"
        exit 1
    fi

    cp -R "$MOUNT_DIR/WebStorm.app" /Applications
    hdiutil detach "$MOUNT_DIR"
    rm -f webstorm.dmg
}

function install_vscode() {
    brew install --cask visual-studio-code > /dev/null 2>&1

    VSCODE_CONFIG_PATH="$HOME/Library/Application Support/Code/User"
    CONFIG_SOURCE_PATH="./configs/vscode"

    mkdir -p "$VSCODE_CONFIG_PATH"
    cp "$CONFIG_SOURCE_PATH/settings.json" "$VSCODE_CONFIG_PATH/"
    cp "$CONFIG_SOURCE_PATH/keybindings.json" "$VSCODE_CONFIG_PATH/"
    cat "$CONFIG_SOURCE_PATH/extensions.txt" | xargs -n 1 code --install-extension
}

function install_cli_tools() {
    npm install -g @angular/cli # Angular CLI
}

function install_other_brew_apps() {
    brew install --cask rectangle # Move and resize windows
    brew install --cask alt-tab # Windows-like window switching
    brew install --cask clipbook # Clipboard manager
    brew install --cask karabiner-elements # Keyboard customization tool (swaps § with ~)
    brew install --cask linearmouse # Mouse customization tool (turns off acceleration)
    brew install --cask brave-browser
    brew install --cask discord
    brew install --cask notion
    brew install --cask postman
    brew install --cask docker
    brew install --cask dbeaver-community
    brew install --cask google-drive
}

function install_everything() {
    decorate_with_logging "Installing Homebrew" install_homebrew
    decorate_with_logging "Installing Fonts" install_fonts
    decorate_with_logging "Installing Ghostty" install_ghostty
    decorate_with_logging "Installing Spaceship" install_spaceship
    decorate_with_logging "Installing Node and NPM" install_nvm_and_node
    decorate_with_logging "Installing WebStorm" install_webstorm
    decorate_with_logging "Installing VS Code" install_vscode
    decorate_with_logging "Installing CLI Tools" install_cli_tools
    decorate_with_logging "Installing Other Brew Apps" install_other_brew_apps
}

function main() {
    display_script_header
    print_separator
    display_system_info
    print_separator
    ask_for_sudo
    print_separator
    install_everything
}

main

