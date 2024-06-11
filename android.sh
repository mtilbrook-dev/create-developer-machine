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
androidSdkVersion="11076708"

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
mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
echo "mv \"$skdDownloadPath/cmdline-tools\" \"$ANDROID_HOME/cmdline-tools/latest\""

printf "Checking %s is in \$PATH\n\n" "$ANDROID_HOME"

export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

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

if [ ! -d "$HOME/.AndroidStudio/config" ]; then
  mkdir -p "$HOME/.AndroidStudio/config"
fi
unzip ./studio-settings.zip -d "$HOME/.AndroidStudio/config/"

cpuThreadMax=$(sysctl -n hw.ncpu)
find /Applications -maxdepth 1 -type d -name "Android Studio*.app" -print0 | while read -d $'\0' file
do
    echo """
    #---------------------------------------------------------------------
    #  User specific system properties
    #---------------------------------------------------------------------
    projectview=true
    idea.config.path=\${user.home}/.AndroidStudio/config
    """ >> "${file}/Contents/bin/idea.properties"
    cp "$scriptPath/studio.vmoptions" "${file}/Contents/bin/studio.vmoptions"
    sed -i '' 's/^\(\-Dcaches\.indexerThreadsCount=\).*/\1'"$cpuThreadMax"'/' "${file}/Contents/bin/studio.vmoptions"
done
