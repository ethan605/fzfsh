# Ensure kubectl and kubectx are available
if (( ! ${+commands[kubectl]} )) || (( ! ${+commands[kubectx]} )); then
  return 1
fi

# Shared helper to utilise FZF for Kubectl
function __fzfsh_kubectl() {
  fzf --header-lines=1 | awk '{ print $1 }'
}

# K8s - show an argo rollout
function fzfsh::kubectl::argo() {
  kubectl argo rollouts version &> /dev/null || { echo "argo-rollouts not found"; return 1 }

  local rollout=""
  local context=""
  local extra=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context="--context=$(kubectx | fzf)"; shift ;;
      -*|--*) extra+="$1 "; shift ;;
      *) rollout="$1"; shift ;;
    esac
  done

  [[ -z "$rollout" ]] && rollout=$(eval "kubectl argo rollouts list rollout $context" | __fzfsh_kubectl)
  [[ -z "$rollout" ]] && return 1

  eval "kubectl argo rollouts get rollout $rollout $context $extra"
}

# K8s - ssh to a pod
function fzfsh::kubectl::exec() {
  local app=""
  local context=""
  local extra=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context="--context=$(kubectx | fzf)"; shift ;;
      -*|--*) extra+="$1 "; shift ;;
      *) app="$1"; shift ;;
    esac
  done

  if [[ -z "$app" ]]; then
    pod=$(eval "kubectl get pods $context" | __fzfsh_kubectl)
  else
    pod=$(eval "kubectl get pods $context -lapp=$app" | __fzfsh_kubectl)
  fi

  [[ -z "$pod" ]] && return 1
  eval "kubectl exec -it $context $extra $pod -- /bin/bash"
}

# K8s - logs
function fzfsh::kubectl::logs() {
  local app=""
  local by_pod=false
  local context=""
  local extra=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context="--context=$(kubectx | fzf)"; shift ;;
      --pod) by_pod=true; shift ;;
      -*|--*) extra+="$1 "; shift ;;
      *) app="$1"; shift ;;
    esac
  done

  [[ -z "$app" ]] && app=$(eval "kubectl get services $context" | __fzfsh_kubectl)
  [[ -z "$app" ]] && return 1

  if [[ "$by_pod" = true ]]; then
    local pod=$(eval "kubectl get pods $context -lapp=$app" | __fzfsh_kubectl)
    [[ -z "$pod" ]] && return 1

    eval "kubectl logs $context $extra $pod"
  else
    eval "kubectl logs $context $extra -lapp=$app --all-containers"
  fi
}

# K8s - list pods
function fzfsh::kubectl::pods() {
  local app=""
  local context=""
  local extra=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context="--context=$(kubectx | fzf)"; shift ;;
      -*|--*) extra+="$1 "; shift ;;
      *) app="$1"; shift ;;
    esac
  done

  [[ -z "$app" ]] && app=$(eval "kubectl get services $context" | __fzfsh_kubectl)
  [[ -z "$app" ]] && return 1

  eval "kubectl get pods -lapp=$app $context $extra"
}

alias kargo='fzfsh::kubectl::argo'
alias kargo!='fzfsh::kubectl::argo --context'
alias kexec='fzfsh::kubectl::exec'
alias kexec!='fzfsh::kubectl::exec --context'
alias klogs='fzfsh::kubectl::logs'
alias klogs!='fzfsh::kubectl::logs --context'
alias kpods='fzfsh::kubectl::pods'
alias kpods!='fzfsh::kubectl::pods --context'
