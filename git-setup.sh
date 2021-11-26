#!/usr/bin/env bash

sshPassword=""

usePasswordManager="n"
read -r -p 'Use password manager save SHH key password?: ' usePasswordManager
if [ "$usePasswordManager" = "y" ]; then 
  passwordManagerEmail="n"
  read -r -p 'Password manager login email?: ' passwordManagerEmail

  useOnePassword="n"
  read -r -p 'Use 1Password CLI?' useOnePassword
  if [ "$useOnePassword" = "y" ]; then
    op --version || {
      wget "https://cache.agilebits.com/dist/1P/op/pkg/v1.8.0/op_darwin_amd64_v1.8.0.pkg" "/tmp/one-password-cli.pkg"
      sudo installer -pkg /tmp/one-password-cli.pkg
    }
    team=""
    read -r -p '1Password Team?' team
    op signin "$team" "$passwordManagerEmail"
    # # OnePassword
      # export OP_SESSION_tilbrook=""
      # op-signin() {
      #   eval $(op signin "$team")
      # }
  fi

  useLastPassword="n"
  read -r -p 'Use last password CLI?' useLastPassword
  if [ "$useLastPassword" = "y" ]; then
    lpass login "$passwordManagerEmail"
    sshPassword=$(lpass generate --sync=auto --username=git-key --no-symbols "Github SSH" 16)
  fi
else 
  read -r -p 'SHH key password?: ' usePasswordManager
fi

email=""
read -r -p 'Github Email?' email
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

echo "Add the key to gtihub account"
echo "https://github.com/settings/ssh/new"

githubUserName=""
read -r -p 'Github user name?' githubUserName
echo "Setting git config"
git config --global user.email "$email"
git config --global user.name "$githubUserName"
