#!/usr/bin/env sh
# The script checks if gcloud is installed and updates when run
# If gcloud can't be found it will install gcloud CLI to the HOME/Library
# and setup the env variables for ZSH and Bash. PRs welcome for nushell and fish.

gcloud -v >/dev/null 2>&1 && {
  echo "GCloud cli always setup. Updating components and exiting"
  gcloud components update
  exit 0
}

version="264.0.0"
gcloudZip="gcloud.tar.gz"
library="$HOME/Library"
sdkPath="$library/google-cloud-sdk"

name=$(uname)
echo "Getting gcloud platform download"
if [ ! -d "$sdkPath" ] && [ "$name" = "Darwin" ]; then
  echo "Darwin: Download and unpack gcloud"
  wget -O "$gcloudZip" "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$version-darwin-x86_64.tar.gz"

  mkdir -p "$sdkPath"
  mv "$gcloudZip" "$library"

  cd "$library" && gunzip -c "$gcloudZip" | tar xopf -

  # Clean up a bit
  rm "$gcloudZip"
else
  echo "Unsupported platform please make a PR"
fi

gcloud -v >/dev/null 2>&1 || {
  binPath="
# Google Cloud
export PATH=\"\$PATH:$sdkPath/bin\"
"
  echo "$binPath" >> "$HOME/.zshrc"
  echo "$binPath" >> "$HOME/.bash_profile"

  export PATH="$PATH:$sdkPath/bin"
  echo "Installing gcloud"
  "$sdkPath/install.sh"
}

echo "Update gcloud"
gcloud components update

echo "Login to gcloud"
gcloud auth login
