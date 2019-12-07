#!/bin/sh

# kubectl
alias k='kubectl'
alias ks='kubectl -n kube-system'
complete -o default -F __start_kubectl k

# bash completions
source <(kubectl completion bash)
source <(helm completion bash)
source <(velero completion bash)
source <(stern --completion=bash)

# kube-ps1
source "/etc/profile.d/99-kubeps1.sh"
PS1='[\u@\h \W $(kube_ps1)]\$ '

# krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
