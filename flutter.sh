#!/usr/bin/env bash

xcodeVersion="Xcode"
read -r -p 'Select the Xcode app you are using in Applications, default is Xcode: ' xcodeVersion
echo "sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
sudo xcode-select --switch "/Applications/$xcodeVersion.app/Contents/Developer"
sudo xcodebuild -runFirstLaunch


# echo "Running brew"
# brew update
# brew bundle --file=./brew/flutter
# if [ ! -d "$HOME/.cocoapods" ]; then
#   pod setup
# fi

flutterHome="$HOME/Library/flutter"
if [ ! -d "$HOME/Library/flutter" ]; then
  git clone git@github.com:flutter/flutter.git "$flutterHome"
fi

path="$PATH"
case ":$PATH:" in
  *:"$flutterHome/bin":*)
    echo "Flutter path is ready to go.";;
  *)
    echo "Installing Flutter and Dart SDK env PATH for bash and zsh"
    flutterPath="
# Flutter
export PATH=\"\$PATH:\$HOME/Library/flutter/bin:\$HOME/Library/flutter/bin/cache/dart-sdk/bin:\$HOME/.pub-cache/bin\"
"
    echo "$flutterPath" >> "$HOME/.zshrc"
    echo "$flutterPath" >> "$HOME/.bash_profile"
    path="$PATH:$flutterHome/bin";;
esac

export PATH="$path"

echo "Accept Android licenses"
flutter doctor --android-licenses
echo "Install Dart protoc plugin"
flutter pub global activate protoc_plugin
