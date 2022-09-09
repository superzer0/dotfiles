# LSD
alias ls="lsd -alh --color=auto"
alias l="lsd -lh --color=auto"

#Other:
alias listening="lsof -i -P | grep -i 'listen'"

# -- Git --
alias g="git"
alias gpr="git pull --rebase"
alias gforce="git push --force-with-lease"

# -- Containers --
alias d="docker"
alias k="kubectl"
#export KUBECONFIG=~/.kube/config-2
# Kubectl edit command will use this env var.
export EDITOR='code --wait'
# Should your editor deal with streamed vs on disk files differently, also set...
export K9S_EDITOR='code --wait'
complete -F __start_kubectl k

# oh-my-posh
# https://ohmyposh.dev/docs/installation/linux
eval "$(oh-my-posh init bash)"
eval "$(oh-my-posh init bash --config $(brew --prefix oh-my-posh)/themes/kali.omp.json)"

eval $(thefuck --alias)
