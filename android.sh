#!/usr/bin/env bash

set -e

brew bundle --file=./brew/android

if [ ! -d "/Applications/Android Studio.app" ]; then
  if [ "$(uname -m)" = "arm64" ]; then
    echo "Downloading Android Studio"
    wget -O "android-studio.dmg" "https://redirector.gvt1.com/edgedl/android/studio/install/2020.3.1.26/android-studio-2020.3.1.26-mac_arm.dmg"
    echo "Downloading Android Studio Preview"
    wget -O "android-studio-preview.zip" "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2021.2.1.6/android-studio-2021.2.1.6-mac_arm.zip"
  else
    {
      echo "Downloading Android Studio"
      wget -O "android-studio.dmg" "https://redirector.gvt1.com/edgedl/android/studio/install/2020.3.1.26/android-studio-2020.3.1.26-mac.dmg"
      echo "Downloading Android Studio Preview"
      wget -O "android-studio-preview.zip" "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2021.2.1.6/android-studio-2021.2.1.6-mac.zip"
    }
  fi

  # Unpack Stable Release
  hdiutil attach "./android-studio.dmg"
  stableStudioPath="$(find /Volumes -name "Android Studio*" -print | head -n 1)"
  cp -r "$stableStudioPath/Android Studio.app" /Applications
  hdiutil unmount "$stableStudioPath"
  rm "android-studio.dmg"

  # Unpack Preview Release
  unzip "android-studio-preview.zip"
  mv "Android Studio Preview.app" /Applications
else
  echo "Android Studio is installed already"
fi

ANDROID_HOME=""
if [ "$(uname)" = "Darwin" ]; then
  ANDROID_HOME="$HOME/Library/Android/sdk"
else
  ANDROID_HOME="$HOME/.android/sdk"
fi
androidSdkVersion="7583922"

echo "Download android SDK tools"
mkdir -p ./tmp
if [ "$(uname)" = "Darwin" ]; then
  mkdir -p "./tmp"
  mkdir -p "${ANDROID_HOME}"
  wget "https://dl.google.com/android/repository/commandlinetools-mac-${androidSdkVersion}_latest.zip" -O "./tmp/${androidSdkVersion}"
  unzip -q "./tmp/${androidSdkVersion}" -d "./tmp/"
else # Assume Linux
  mkdir -p "${ANDROID_HOME}"
  wget "https://dl.google.com/android/repository/commandlinetools-linux-x64-${androidSdkVersion}_latest.zip" -O "./tmp/${androidSdkVersion}"
  unzip -q "./tmp/${androidSdkVersion}" -d "${ANDROID_HOME}"
fi
mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
cp -r ./tmp/cmdline-tools/* "$ANDROID_HOME/cmdline-tools/latest"
rm -rf "./tmp/"

printf "Checking %s is in \$PATH\n\n" "$ANDROID_HOME"

(sdkmanager --version &>/dev/null && echo "Android SDK is PATH skipping PATH setup.") || {
  # Install Android SDK into PATH
  echo "Android SDK is not in the PATH"
  echo "Adding SDK env variables to bash_profile and zshrc"

  shellParams="""
# Android & Java

export ANDROID_SDK_ROOT=\"\$HOME/Library/Android/sdk\"
export ANDROID_HOME=\"\$HOME/Library/Android/sdk\"
export PATH=\"\$PATH:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:\$ANDROID_SDK_ROOT/platform-tools\"

export JAVA_OPTS=\"\$JAVA_OPTS -Dorg.gradle.android.cache-fix.ignoreVersionCheck=true\"
export GRADLE_OPTS='-Dorg.gradle.vfs.watch=true -Dorg.gradle.jvmargs=\"-server -XX:MaxMetaspaceSize=512m -Xms512m -Xmx2048M\" -Dkotlin.daemon.jvm.options=\"-Xmx2048M\"'

setJavaHomeWithStudiJDK() {
  export JAVA_HOME=\"\$1/Contents/jre/jdk/Contents/Home/\"
}
jdk() {
  version="\$1"
  export JAVA_HOME=\"/Library/Java/JavaVirtualMachines/zulu-\$version.jdk/Contents/Home\"
  java -version
}

# On M1 Mac we always want to use the Zulu JVM. While we don't share the Deamon with Android Studio.
# From Android Studio Artic Fox and later. Android Studio should use the User Daemon and not it's internal Daemon.
jdk 11
export GRADLE_OPTS='-Dorg.gradle.vfs.watch=true -Dorg.gradle.jvmargs=\"-server -XX:MaxMetaspaceSize=512m -Xms512m -Xmx2048M\" -Dkotlin.daemon.jvm.options=\"-Xmx2048M\" -Dorg.gradle.classloaderscope.strict=true'
alias gradleNuke=\"./gradlew clean && rm -rf ~/.gradle/caches/build-cache-1\"
"""
  echo "$shellParams" >>"$HOME/.zshrc"
  echo "$shellParams" >>"$HOME/.bash_profile"

  export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
  echo "$PATH"
}

if [ "$JAVA_HOME" = "" ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home"
fi

yes | sdkmanager --licenses
sdkmanager --update

sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator" \
  "build-tools;29.0.3" \
  "platforms;android-29" \
  "sources;android-29" \
  "build-tools;30.0.3" \
  "platforms;android-30" \
  "sources;android-30" \
  "cmdline-tools;latest"

cpuThreadMax=$(sysctl -n hw.ncpu)
androidStudioConfig="""
-Xms256m
-Xmx2048m
-XX:ReservedCodeCacheSize=240m
-XX:+UseG1GC
-XX:SoftRefLRUPolicyMSPerMB=50
-XX:CICompilerCount=2
-Dsun.io.useCanonPrefixCache=false
-Djdk.http.auth.tunneling.disabledSchemes=""
-Djdk.attach.allowAttachSelf=true
-Dkotlinx.coroutines.debug=off
-Djdk.module.illegalAccess.silent=true
-Djna.nosys=true
-Djna.boot.library.path=
-Didea.vendor.name=Google
-XX:MaxJavaStackTraceDepth=10000
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-ea
-XX:+UseCompressedOops

-Dfile.encoding=UTF-8

# Indexing
-Dcaches.indexerThreadsCount=$cpuThreadMax

# Kotlin
-Dkotlinx.coroutines.debug=off

-da
-Xverify:none

-XX:ErrorFile=\$HOME/logs/java_error_in_studio_%p.log
-XX:HeapDumpPath=\$HOME/logs/java_error_in_studio.hprof

# ###############################################
# custom settings from
# https://github.com/artem-zinnatullin/AndroidStudio-VM-Options/blob/master/studio.vmoptions
# ###############################################

# Runs JVM in Server mode with more optimizations and resources usage
# It may slow down the startup, but if you usually keep IDE running for few hours/days
# JVM may profile and optimize IDE better. Feel free to remove this flag.
-server

# Sets the initial size of the heap, default value is 256m
-Xms1G

# Max size of the memory allocation pool, default value is 1280m
-Xmx2560m

# Sets the size of the allocated class metadata space that will trigger a GC the first time it is exceeded, default max value is 350m
-XX:MetaspaceSize=512m
"""

echo "$androidStudioConfig" >"/Applications/Android Studio.app/Contents/bin/studio.vmoptions"
echo "$androidStudioConfig" >"/Applications/Android Studio Preview.app/Contents/bin/studio.vmoptions"
