#!/usr/bin/env bash

set -e

email=""
read -r -p 'Git Email? ' email
sshPassword=""

usePasswordManager="n"
read -r -p 'Use password manager save SHH key password? [y|n] ' usePasswordManager
machineName=$(hostname)
itemName="SSH-Key-$machineName"
if [ "$usePasswordManager" = "y" ]; then

  useOnePassword="n"
  read -r -p 'Use 1Password CLI? [y|n] ' useOnePassword
  if [ "$useOnePassword" = "y" ]; then
    op --version || {
      wget "https://cache.agilebits.com/dist/1P/op/pkg/v1.12.3/op_apple_universal_v1.12.3.pkg" "/tmp/one-password-cli.pkg"
      sudo installer -pkg /tmp/one-password-cli.pkg

      teamAddress="n"
      read -r -p '1Password team address?: ' teamAddress
      userAddress=""
      read -r -p '1Password email address?' userAddress
      op signin "$team"
      op signin "$teamAddress" "$userAddress"
    }
    # Check for any CLI updates.
    printf "\n\n"
    op update

    team=""
    read -r -p '1Password team name? ' team
    eval "$(op signin "$team")"

    itemKey=$(
      op create item login \
        --title "$itemName" \
        --generate-password='letters,digits,symbols,24' \
        username="$email" | jq -r '.uuid'
    )
    sshPassword=$(op get item "$itemName" --fields password)
    op get item "$itemKey" --fields password
  fi
fi

ssh-keygen -t rsa -b 4096 -C "$email" -P "$sshPassword" -f "$HOME/.ssh/id_rsa"

eval "$(ssh-agent -s)"

sshConfig="Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
"
echo "Setting up ssh config"
echo "$sshConfig"
echo "$sshConfig" >~/.ssh/config

echo "Adding SSH password to keychain"
echo "$sshPassword"
ssh-add -K ~/.ssh/id_rsa

echo "pbcopy < ~/.ssh/id_rsa.pub"
pbcopy <~/.ssh/id_rsa.pub

printf "\n\nAdd the key to gtihub account"
echo "https://github.com/settings/ssh/new"

gitUserName=""
printf "\n\nSetting git config\n"
read -r -p 'Git user.name  ? ' gitUserName
read -r -p "Git user.email ? $email" gitEmail
gitEmail="${gitEmail:-email}"

git config --global user.email "$email"
git config --global user.name "$gitUserName"
