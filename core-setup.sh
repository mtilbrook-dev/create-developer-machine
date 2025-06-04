#!/usr/bin/env bash
#
# If you want the script to auto accept terms in the Android Script then run with yes
# $ yes | ./core-setup.sh

set -e

scriptPath=$(dirname "$0")

if [ ! -d /Applications/Xcode.app ]; then
    echo "Xcode is required to run this script. Once you have installed xcode rerun this script."
fi

if [ -f "$(/opt/homebrew/bin/brew shellenv)" ] && [ ! -x "$(command -v brew)" ]; then
    echo "Brew install but not on PATH"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    printf '\neval "$(/opt/homebrew/bin/brew shellenv)"\n\n' >> ~/.zsh_profile
else
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "Using brew at $(which brew)"
fi

if [ ! -x "$(command -v brew)" ]; then
    echo "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Make sure brew is on PATH
# This covers the case when the setup script fails and need to be re-run
if [ ! -x "$(command -v brew)" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Always use latest
echo "Updating Brew"
brew update

# oahd is the process name for Rosetta2
# https://apple.stackexchange.com/a/435190
if [ ! "$(/usr/bin/pgrep -q oahd)" ]; then
    echo "Installing Rosetta2"
    softwareupdate --install-rosetta
fi

echo "Installing core apps and utilities"
brew bundle --file="$scriptPath/brew/core"
if [ ! -d "/Applications/Google Chrome.app" ]; then
    useChrome=""
    read -r -p 'Install Chrome y/n: ' useChrome
    if [ "$useChrome" = "y" ]; then
        echo "installing cask chrome."
        brew cask install google-chrome
    fi
fi

if [ ! "$ZSH_THEME" = "robbyrussell" ]; then
    useOhMyZsh="n"
    read -r -p 'Setup Oh My Zsh y/n: ' useOhMyZsh
    if [ "$useOhMyZsh" = "y" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
        cat .zshrc >> ~/.zshrc
    fi
fi
useFishShell="n"
read -r -p 'Setup Oh fish shell y/n: ' useFishShell
if [ "$useFishShell" = "y" ]; then
    brew install fish
fi

isAndroidDev="n"
read -r -p 'Setup for Android y/n: ' isAndroidDev
if [ "$isAndroidDev" = "y" ]; then
    yes | ./android.sh
fi

mdmShellFix="""
function fixShellExecute() {
  shellFile=\"\$1\"

  isQuarantined=\$(xattr -l \"\$shellFile\" | grep -c \"com.apple.quarantine\")
  if [ ! \"\$isQuarantined\" = \"0\" ]; then
    xattr -d \"com.apple.quarantine\" \"\$shellFile\"
    echo \"\$shellFile was removed from Apple quarantine\"
  fi

  hasExecutable=\$(ls -l \"\$shellFile\" | grep -c \"x\")
  if [ \"\$hasExecutable\" = \"0\" ]; then
    echo \"File was not executable\"
    chmod +x \"\$shellFile\"
    echo \"File is now executable\"
  fi
}
"""
printf "%s" "$mdmShellFix"  >> "$HOME/.zshrc"
