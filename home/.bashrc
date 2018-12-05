. /etc/bash_completion

PS1="\u@[qserv-deploy]:\w # "

# k8s cli helpers
. /etc/kubectl.completion
alias k='kubectl'
