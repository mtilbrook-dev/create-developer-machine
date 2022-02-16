function installAutoSuggest() {
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
}

plugins=(git jump zsh-autosuggestions)

eval $(/opt/homebrew/bin/brew shellenv)
export PATH="$PATH:$HOME/.bin"

alias grbom="git fetch && grb origin/master"
alias gcln='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d && git remote prune origin && git prune'
alias gpshf="ggpush --force-with-lease"
alias gpshn="ggpush --no-verify"
alias gpshfn="ggpush --force-with-lease --no-verify"
alias gcn="gc --no-verify"
alias gam="gc --am --no-verify"
alias glog="glg --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias fbld="flutter pub run build_runner build"
alias fbldw="flutter pub run build_runner watch"
alias fbldc="flutter pub run build_runner build --delete-conflicting-outputs && flutter pub run build_runner watch"
