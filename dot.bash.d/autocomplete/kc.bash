
function __kc_complete() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=( $(compgen -W "$(kubectl config get-contexts -o name | sort )" -- "$cur") )
}
complete -F __kc_complete kc

# kubectl context, local
function kc() {
    local context="$1"; shift
    if [ "$context" = "" ]; then
        kubectl config get-contexts
    else
        kubectl config use-context "$context"
    fi
}
