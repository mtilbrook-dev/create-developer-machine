#!/usr/bin/env bash
#
# If you want the script to auto accept terms in the Android Script then run with yes
# $ yes | ./core-setup.sh

set -e

scriptPath=$(dirname "$0")

if [ ! -d /Applications/Xcode.app ]; then
    echo "Xcode is required to run this script. Once you have installed xcode rerun this script."
fi

brew -v >/dev/null 2>&1 || {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

# Always use latest
echo "Updating Brew"
brew update
echo "Installing Rosetta2"
softwareupdate --install-rosetta

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

isAndroidDev="n"
read -r -p 'Setup for Android y/n: ' isAndroidDev
if [ "$isAndroidDev" = "y" ]; then
    yes | ./android.sh
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
