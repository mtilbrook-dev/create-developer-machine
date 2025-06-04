#!/usr/bin/env bash

set -e

scriptPath=$(dirname "$0")

brew bundle --file=./brew/android

function setupGradleJavaHomeMacro() {
  local jdkPath="$1"
  printf "java.home=%s\n" "$jdkPath" >> "$HOME/.gradle/config.properties"
}

mkdir -p "$HOME/.gradle"
ANDROID_HOME=""
if [ "$(uname)" = "Darwin" ]; then
  ANDROID_HOME="$HOME/Library/Android/sdk"
  setupGradleJavaHomeMacro "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home"
else # Assume Linux
  ANDROID_HOME="$HOME/.android/sdk"
  echo '''
    # To set the default Android Studio JVM run
    jdkPath=PATH_TO_JDK_HERE
    printf "java.home=%s\n" "$jdkPath" >> "$HOME/.gradle/config.properties"
  '''
fi
androidSdkVersion="13114758"

echo "Download android SDK tools"
sdkTmpDir=/var/tmp/android-sdk
skdDownloadPath="${sdkTmpDir}/${androidSdkVersion}"
skdZip="${skdDownloadPath}.zip"
mkdir -p "$sdkTmpDir"
mkdir -p "$ANDROID_HOME"

if [ "$(uname)" = "Darwin" ]; then
  wget "https://dl.google.com/android/repository/commandlinetools-mac-${androidSdkVersion}_latest.zip" -O "$skdZip"
else # Assume Linux
  wget "https://dl.google.com/android/repository/commandlinetools-linux-x64-${androidSdkVersion}_latest.zip" -O "$skdZip"
fi
unzip -q "$skdDownloadPath" -d "$skdDownloadPath"

printf "Checking %s is in \$PATH\n\n" "$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

printf 'export ANDROID_HOME=$%s' "$ANDROID_HOME" >> ~/.zshrc
printf 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >> ~/.zshrc

if [ "$JAVA_HOME" = "" ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home"
fi

yes | "$skdDownloadPath/cmdline-tools/bin/sdkmanager" --sdk_root="$ANDROID_HOME" --licenses
"$skdDownloadPath/cmdline-tools/bin/sdkmanager" --sdk_root="$ANDROID_HOME" --update

"$skdDownloadPath/cmdline-tools/bin/sdkmanager" --sdk_root="$ANDROID_HOME" \
  "platform-tools" \
  "emulator" \
  "build-tools;34.0.0" \
  "platforms;android-34" \
  "platforms;android-29" \
  "sources;android-29" \
  "sources;android-34" \
  "cmdline-tools;latest"


