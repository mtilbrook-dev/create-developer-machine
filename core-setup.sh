#!/usr/bin/env bash -x
#
# If you want the script to auto accept automatically then run with yes
# $ yes | ./core-setup.sh

scriptPath=$(dirname "$0")

brew -v >/dev/null 2>&1 || {
    echo "Installing Brew requires Xcode to be set up. The script will need to be re-run once Xcode is set up."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo 'eval $(/opt/homebrew/bin/brew shellenv)' >> "$HOME/.zshrc"
    eval $(/opt/homebrew/bin/brew shellenv)
    exit 0
}

# Always use latest
brew update
softwareupdate --install-rosetta

if [ ! "$ZSH_THEME" = "robbyrussell"]; then
useOhMyZsh="n"
read -r -p 'Setup Oh My Zsh y/n: ' useOhMyZsh
if [ "$useOhMyZsh" = "y" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    echo """
jdk() {
    version=\$1
    export JAVA_HOME=$(/usr/libexec/java_home -v"\$version");
    java -version
 }""" >>"$HOME/.zshrc"
    exit 0
fi
fi
    useFishShell="n"
    read -r -p 'Setup Oh fish shell y/n: ' useFishShell
    if [ "$useFishShell" = "y" ]; then
        brew install fish
        echo """
function jdk
    set java_version \$argv
    set -Ux JAVA_HOME (/usr/libexec/java_home -v \$java_version)
    java -version
end""" >>"$HOME/.config/fish/functions"
    else
        echo "Using bash shell. Make a PR"
    fi

echo "Installing core apps and utilities"
brew bundle --file="$scriptPath/brew/core"
if [ ! -d "/Applications/Google Chrome.app" ]; then
    echo "installing cask chrome."
    brew cask install google-chrome
else
    echo "Skipping cask install of chrome."
fi

isAndroidDev="n"
read -r -p 'Setup for Android y/n: ' isAndroidDev
 zif [ "$isAndroidDev" = "y" ]; then
    yes | ./android.sh
fi
