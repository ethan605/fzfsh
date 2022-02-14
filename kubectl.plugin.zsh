# Ensure kubectl is available
if (( ! ${+commands[kubectl]} )); then
  return 1
fi

# Shared helper to utilise FZF for Kubectl
function __fzfsh_kubectl() {
  # convert input args into a single string
  local query=$(printf ' %q' "$@")
  fzf --header-lines=1 --query="${query:1}" | cut -d' ' -f1
}

# K8s - show an argo rollout
function fzfsh::kargo() {
  kubectl argo rollouts version &> /dev/null || return 1

  if [[ "$1" == "--context" ]]; then
    shift
    local context=$(kubectx | fzf)
  fi

  local rollout=$(kubectl argo rollouts list rollout --context="$context" | __fzfsh_kubectl "$@")
  [[ -z "$rollout" ]] && return 1
  kubectl argo rollouts get rollout "$rollout" --context="$context"
}

# K8s - ssh to a pod
function fzfsh::kexec() {
  if [[ "$1" == "--context" ]]; then
    shift
    local context=$(kubectx | fzf)
  fi

  local pod=$(kubectl get pods --context="$context" | __fzfsh_kubectl "$@")
  [[ -z "$pod" ]] && return 1
  kubectl exec -it "$pod" --context="$context" -- bash
}

# K8s - list pods
function fzfsh::kpods() {
  if [[ "$1" == "--context" ]]; then
    shift
    local context=$(kubectx | fzf)
  fi

  local app=$(kubectl get services --context="$context" | __fzfsh_kubectl "$@")
  [[ -z "$app" ]] && return 1
  kubectl get pods -lapp="$app" --context="$context"
}

alias kargo='fzfsh::kargo'
alias kargo!='fzfsh::kargo --context'
alias kexec='fzfsh::kexec'
alias kexec!='fzfsh::kexec --context'
alias kpods='fzfsh::kpods'
alias kpods!='fzfsh::kpods --context'
