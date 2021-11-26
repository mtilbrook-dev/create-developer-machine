#!/usr/bin/env sh

brew bundle --file=./brew/extras

# Setup VSCode
vscodeConfig="{
  \"editor.fontSize\": 14,
  \"editor.formatOnSave\": true,
  \"editor.tabSize\": 2,
  \"editor.trimAutoWhitespace\": true,
  \"files.autoSave\": \"onFocusChange\",
  \"files.insertFinalNewline\": true,
  \"files.trimTrailingWhitespace\": true,
}
"
echo "$vscodeConfig" >"$HOME/Library/Application Support/Code/User/settings.json"
