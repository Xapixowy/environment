# Load Spaceship ZSH Prompt
source /opt/homebrew/opt/spaceship/spaceship.zsh

# Enable CLI Colors
export CLICOLOR=1

# Load Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load Angular CLI autocompletion.
source <(ng completion script)

# Load Brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Aliases
alias ls='ls -G'
alias ll='ls -lG'