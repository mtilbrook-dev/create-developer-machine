#!/usr/bin/env sh -e

brew bundle --file=./brew/jvm

if [ "$JAVA_HOME" = "" ]; then
    export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home"
fi
