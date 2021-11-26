#!/usr/bin/env bash -e

brew bundle --file=./brew/android

if [ $(uname -m) = "arm64" ]; then 
  wget -O android-studio.dmg \ 
    "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2020.3.1.25/android-studio-2020.3.1.25-mac_arm.zip"
  wget -O android-studio-beta-preview.zip \ 
    "https://redirector.gvt1.com/edgedl/android/studio/install/2020.3.1.25/android-studio-2020.3.1.25-mac_arm.zip"
else {
  wget -O android-studio.dmg \ 
    "https://redirector.gvt1.com/edgedl/android/studio/install/2020.3.1.25/android-studio-2020.3.1.25-mac.dmg"
  wget -O android-studio-beta-preview.zip \ 
    "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2021.1.1.17/android-studio-2021.1.1.17-mac.zip"
}

# TODO unpack Android Studio
  

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
else # Linux I guess
  mkdir -p "${ANDROID_HOME}"
  wget "https://dl.google.com/android/repository/commandlinetools-linux-x64-${androidSdkVersion}_latest.zip" -O "./tmp/${androidSdkVersion}"
  unzip -q "./tmp/${androidSdkVersion}" -d "${ANDROID_HOME}"
fi
mkdir -p "$ANDROID_HOME/cmdline-tools/latest"
cp -r ./tmp/cmdline-tools/* "$ANDROID_HOME/cmdline-tools/latest" 
rm -rf "./tmp/"

printf "Checking %s is in \$PATH\n\n" "$ANDROID_HOME"

# androidPath="\$ANDROID_HOME/tools:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/latest/bin"
androidPath="$ANDROID_HOME/cmdline-tools/latest/bin"
ANDROID_SDK_ROOT="$ANDROID_HOME"
ANDROID_SDK_PATHS="\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
# ANDROID_SDK_PATHS="\$ANDROID_SDK_ROOT/tools:\$ANDROID_SDK_ROOT/tools/bin:\$ANDROID_SDK_ROOT/platform-tools:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"

path="$PATH"
case ":$PATH:" in
*:$androidPath:*)
  echo "Android SDK is PATH skipping PATH setup."
  ;;
*)
  # Install Android SDK into PATH
  echo "Android SDK is not in the PATH"
  echo "Adding SDK env variables to bash_profile and zshrc"
# TODO
  # echo "export ANDROID_SDK_ROOT=\"$ANDROID_SDK_ROOT\"" >>"$HOME/.zshrc"
  # echo "export PATH=\"\$PATH:$ANDROID_SDK_PATHS\"" >>"$HOME/.zshrc"
  path="$path:$androidPath"
  ;;
esac

if [ "$JAVA_HOME" = "" ]; then
  shellParams="""
# Android & Java

export ANDROID_SDK_ROOT=\"\$HOME/Library/Android/sdk\"
export ANDROID_HOME=\"\$HOME/Library/Android/sdk\"
export PATH=\"\$PATH:\$ANDROID_SDK_ROOT/tools:\$ANDROID_SDK_ROOT/tools/bin:\$ANDROID_SDK_ROOT/platform-tools\"

export JAVA_OPTS=\"\$JAVA_OPTS -Dorg.gradle.android.cache-fix.ignoreVersionCheck=true\"
export GRADLE_OPTS='-Dorg.gradle.vfs.watch=true -Dorg.gradle.jvmargs=\"-server -XX:MaxMetaspaceSize=512m -Xms512m -Xmx2048M\" -Dkotlin.daemon.jvm.options=\"-Xmx2048M\"'
setJavaHomeWithStudiJDK() {
  export JAVA_HOME=\"\$1/Contents/jre/jdk/Contents/Home/\"
}
jdk() {
  version="\$1"
  export JAVA_HOME=$(/usr/libexec/java_home -v\"$version\")
  java -version
}

# Android stuff
jdk 11
export GRADLE_OPTS='-Dorg.gradle.vfs.watch=true -Dorg.gradle.jvmargs=\"-server -XX:MaxMetaspaceSize=512m -Xms512m -Xmx2048M\" -Dkotlin.daemon.jvm.options=\"-Xmx2048M\" -Dorg.gradle.classloaderscope.strict=true'
alias gradleNuke=\"./gradlew clean && rm -rf ~/.gradle/caches/build-cache-1\"
"""
  echo "$shellParams" >>"$HOME/.zshrc"
  echo "$shellParams" >>"$HOME/.bash_profile"
else
  echo "JAVA_HOME=$JAVA_HOME"
fi

export PATH="$path"
echo "$PATH"

sdkmanager --licenses | sdkmanager --update

sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator" \
  "build-tools;30.0.3" \
  "platforms;android-30" \
  "sources;android-30" \
  "system-images;android-30;google_apis_playstore;x86" \
  "system-images;android-22;google_apis;x86" \
  "ndk;21.3.6528147"

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
-Dcaches.indexerThreadsCount=16

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
