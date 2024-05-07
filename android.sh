#!/usr/bin/env bash

set -e

brew bundle --file=./brew/android

ANDROID_HOME=""
if [ "$(uname)" = "Darwin" ]; then
  ANDROID_HOME="$HOME/Library/Android/sdk"
else
  ANDROID_HOME="$HOME/.android/sdk"
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
mv "$skdDownloadPath/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"


if [ "$JAVA_HOME" = "" ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home"
fi

export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest"

yes | sdkmanager --licenses
sdkmanager --update

sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator" \
  "build-tools;34.0.0" \
  "platforms;android-34" \
  "platforms;android-29" \
  "sources;android-29" \
  "sources;android-34" \
  "cmdline-tools;latest"

cpuThreadMax=$(sysctl -n hw.ncpu)
androidStudioConfig="""
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
-Xmx8G

# Sets the size of the allocated class metadata space that will trigger a GC the first time it is exceeded, default max value is 350m
-XX:MetaspaceSize=1024m
"""

echo "$androidStudioConfig" >"/Applications/Android Studio.app/Contents/bin/studio.vmoptions"
echo "$androidStudioConfig" >"/Applications/Android Studio Preview.app/Contents/bin/studio.vmoptions"
