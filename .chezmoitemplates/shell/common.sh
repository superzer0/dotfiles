# -- Editor --
export EDITOR='code --wait'
export K9S_EDITOR='code --wait'
export KUBE_EDITOR='code --wait'

# -- Git --
alias g='git'
alias gpr='git pull --rebase'
alias gforce='git push --force-with-lease'
alias glog='git log --oneline --graph --decorate --all'

# -- Containers and infrastructure --
alias d='docker'
alias k='kubectl'
alias tf='terraform'

if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd -alh --color=auto'
  alias l='lsd -lh --color=auto'
fi

alias listening="lsof -i -P | grep -i 'listen'"
