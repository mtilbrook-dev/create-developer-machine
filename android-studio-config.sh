#!/bin/bash

scriptPath=$(dirname "$0")

# TODO add Linux

cpuThreadMax=$(sysctl -n hw.ncpu)
systemMemoryGb="$(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024}')"
smallMachineGb=18 # M3 pro smaller ram is 18GB
find /Applications -maxdepth 1 -type d -name "Android Studio*.app" -print0 | while read -r -d $'\0' app
do
    # Check if the user has granted write permission to the app
    # TODO validate if this works for granting teminal emulator app directory access aswell.
    if [ ! -w "${app}" ]; then
        echo "Granting write permission to ${app}…"
        sudo chmod +w "${app}"
    fi
    echo """
    #---------------------------------------------------------------------
    #  User specific system properties
    #---------------------------------------------------------------------
    projectview=true
    idea.config.path=\${user.home}/.AndroidStudio/config
    """ >> "${app}/Contents/bin/idea.properties"

    # Copy IDEA vmoptions into Android Studio
    cp "$scriptPath/studio.vmoptions" "${app}/Contents/bin/studio.vmoptions"
    sed -i '' 's/^\(\-Dcaches\.indexerThreadsCount=\).*/\1'"$cpuThreadMax"'/' "${app}/Contents/bin/studio.vmoptions"
    if [ "$systemMemoryGb" -lt "$smallMachineGb" ] || [ "$x" -eq "$smallMachineGb" ]; then
        sed -i '' 's/^\(\-Xmx\).*/\1'"6G"'/' "${app}/Contents/bin/studio.vmoptions"
    else 
        sed -i '' 's/^\(\-Xmx\).*/\1'"8G"'/' "${app}/Contents/bin/studio.vmoptions"
    fi
done
