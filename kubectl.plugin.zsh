# Shared helper to utilise FZF for Kubectl
function __fzfsh_kubectl() {
  query="${$(printf ' %q' "$@"):1}"       # convert input args into a single string
  [[ ! -z "$query" ]] && query="^$query"  # prepend ^ if query isn't empty
  fzf --header-lines=1 --query="$query" | cut -d' ' -f1
}

# K8s - show an argo rollout
function fzfsh::kargo() {
  rollout=$(kubectl argo rollouts list rollout | __fzfsh_kubectl "$@")
  [[ -z "$rollout" ]] && return 1
  kubectl argo rollouts get rollout "$rollout"
}

# K8s - show an argo rollouts (with context)
function fzfsh::kargo!() {
  context=$(kubectx | fzf)
  [[ -z "$context" ]] && return 1
  rollout=$(kubectl argo rollouts list rollout --context="$context" | __fzfsh_kubectl "$@")
  [[ -z "$rollout" ]] && return 1
  kubectl argo rollouts get rollout "$rollout" --context="$context"
}

# K8s - ssh to a pod
function fzfsh::kexec() {
  pod=$(kubectl get pods | __fzfsh_kubectl "$@")
  [[ -z "$pod" ]] && return 1
  kubectl exec -it "$pod" -- bash
}

# K8s - ssh to a pod (with context)
function fzfsh::kexec!() {
  context=$(kubectx | fzf)
  [[ -z "$context" ]] && return 1
  pod=$(kubectl get pods --context="$context" | __fzfsh_kubectl "$@")
  [[ -z "$pod" ]] && return 1
  kubectl exec -it "$pod" --context="$context" -- bash
}

# K8s - list pods
function fzfsh::kpods() {
  app=$(kubectl get services | __fzfsh_kubectl "$@")
  [[ -z "$app" ]] && return 1
  kubectl get pods -lapp="$app"
}

# K8s - list pods (with context)
function fzfsh::kpods!() {
  context=$(kubectx | fzf)
  [[ -z "$context" ]] && return 1
  app=$(kubectl get services --context="$context" | __fzfsh_kubectl "$@")
  [[ -z "$app" ]] && return 1
  kubectl get pods -lapp="$app" --context="$context"
}

alias kargo='fzfsh::kargo'
alias kargo!='fzfsh::kargo!'
alias kexec='fzfsh::kexec'
alias kexec!='fzfsh::kexec!'
alias kpods='fzfsh::kpods'
alias kpods!='fzfsh::kpods!'
