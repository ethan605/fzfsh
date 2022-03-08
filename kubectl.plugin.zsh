# Ensure kubectl and kubectx is available
if (( ! ${+commands[kubectl]} )) || (( ! ${+commands[kubectx]} )); then
  return 1
fi

__fzfsh_watch="watch --color --differences --errexit --exec"

# Shared helper to utilise FZF for Kubectl
function __fzfsh_kubectl() {
  fzf --header-lines=1 | awk '{ print $1 }'
}

# K8s - show an argo rollout
function fzfsh::kubectl::argo() {
  kubectl argo rollouts version &> /dev/null || { echo "argo-rollouts not found"; return 1 }

  local rollout=""
  local context=""
  local watch=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context=$(kubectx | fzf); shift ;;
      --watch) watch=true; shift ;;
      *) rollout="$1"; shift ;;
    esac
  done

  [[ -z "$rollout" ]] && rollout=$(kubectl argo rollouts list rollout --context="$context" | __fzfsh_kubectl)
  [[ -z "$rollout" ]] && return 1

  local cmd="kubectl argo rollouts get --context=$context rollout $rollout"

  [[ "$watch" = true ]] && cmd="$__fzfsh_watch $cmd"
  eval "$cmd"
}

# K8s - ssh to a pod
function fzfsh::kubectl::exec() {
  local app=""
  local context=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context=$(kubectx | fzf); shift ;;
      *) app="$1"; shift ;;
    esac
  done

  if [[ -z "$app" ]]; then
    pod=$(kubectl get pods --context="$context" | __fzfsh_kubectl)
  else
    pod=$(kubectl get pods --context="$context" -lapp="$app" | __fzfsh_kubectl)
  fi

  [[ -z "$pod" ]] && return 1
  kubectl exec -it "$pod" --context="$context" -- bash
}

# K8s - logs
function fzfsh::kubectl::logs() {
  local app=""
  local args=()
  local by_pod=false
  local context=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context=$(kubectx | fzf); shift ;;
      --pod) by_pod=true; shift ;;
      -*|--*) args+=("$1"); shift ;;
      *) app="$1"; shift ;;
    esac
  done

  [[ -z "$app" ]] && app=$(kubectl get services --context="$context" | __fzfsh_kubectl)
  [[ -z "$app" ]] && return 1

  if [[ "$by_pod" = true ]]; then
    local pod=$(kubectl get pods --context="$context" -lapp="$app" | __fzfsh_kubectl)
    [[ -z "$pod" ]] && return 1

    kubectl logs "${args[@]}" --context="$context" "$pod"
  else
    kubectl logs "${args[@]}" --context="$context" -lapp="$app" --all-containers=true
  fi
}

# K8s - list pods
function fzfsh::kubectl::pods() {
  local app=""
  local context=""
  local watch=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --context) context=$(kubectx | fzf); shift ;;
      --watch) watch=true; shift ;;
      *) app="$1"; shift ;;
    esac
  done

  [[ -z "$app" ]] && app=$(kubectl get services --context="$context" | __fzfsh_kubectl)
  [[ -z "$app" ]] && return 1

  local cmd="kubectl get pods --context=$context -lapp=$app"

  [[ "$watch" = true ]] && cmd="$__fzfsh_watch $cmd"
  eval "$cmd"
}

alias kargo='fzfsh::kubectl::argo'
alias kargo!='fzfsh::kubectl::argo --context'
alias kargo~='fzfsh::kubectl::argo --context --watch'
alias kexec='fzfsh::kubectl::exec'
alias kexec!='fzfsh::kubectl::exec --context'
alias klogs='fzfsh::kubectl::logs'
alias klogs!='fzfsh::kubectl::logs --context'
alias kpods='fzfsh::kubectl::pods'
alias kpods!='fzfsh::kubectl::pods --context'
alias kpods~='fzfsh::kubectl::pods --context --watch'
