# zsh-autosuggestions plugin
# function installAutoSuggest() {
#   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# }
# plugins=(git jump)

eval $(/opt/homebrew/bin/brew shellenv)
export PATH="$PATH:$HOME/.bin"

alias grbom="git fetch && grb origin/$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
alias gcln='git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d && git remote prune origin && git prune'
alias gpshf="ggpush --force-with-lease"
alias gpshn="ggpush --no-verify"
alias gpshfn="ggpush --force-with-lease --no-verify"
alias gcn="gc --no-verify"
alias gam="gc --am --no-verify"
alias glog="glg --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gsc="git switch -c"

alias code="open -a \"Visual Studio Code\""

# Ruby
# export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
# export GEM_HOME=$HOME/.gem
# export PATH=$GEM_HOME/bin:$PATH
# export LC_ALL=en_US.UTF-8


# Android & Java
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools"

export JAVA_OPTS="$JAVA_OPTS -Dorg.gradle.android.cache-fix.ignoreVersionCheck=true"

if [ ! -f "$HOME/.gradle_opts" ]; then
  gradleMaxMemory=$(sysctl -n hw.memsize | awk '{print $0/1024/1024*0.34}' | sed 's/\..*//')
  kotlinMaxMemory=$(sysctl -n hw.memsize | awk '{print $0/1024/1024*0.45}' | sed 's/\..*//')
  
  jvmargs="-XX:MaxMetaspaceSize=2G -Xms2G -Xmx${gradleMaxMemory}M -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=67 -XX:G1MaxNewSizePercent=67 -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"
  kotlinArgs="-Xms2G -Xmx${kotlinMaxMemory}M -XX:MaxMetaspaceSize=2G"

  GRADLE_OPTS="-Dorg.gradle.unsafe.watch-fs=true -Dorg.gradle.jvmargs=\"${jvmargs}\""  
  GRADLE_OPTS="$GRADLE_OPTS -Dkotlin.daemon.jvm.options=\"-Xms2G,-Xmx${kotlinMaxMemory}M,-XX:MaxMetaspaceSize=2G\""  
  echo "$GRADLE_OPTS" > "$HOME/.gradle_opts"
else 
  "$GRADLE_OPTS" < "$HOME/.gradle_opts"
fi
export GRADLE_OPTS="$GRADLE_OPTS"


alias gw="./gradlew"
jdk() {
  version="$1"
  if [ "$version" = "8" ]; then
    version="1.8"
  fi
  export JAVA_HOME="$(/usr/libexec/java_home -v $version)"
  java -version
}
jdk 21
