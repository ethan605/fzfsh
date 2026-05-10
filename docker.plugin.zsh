# Ensure docker is available
if ((!${+commands[docker]})); then
  return 1
fi

# Shared helper to utilise FZF for Docker
function __fzfsh_docker() {
  fzf --header-lines=1 --multi
}

# Docker - containers-related commands
function fzfsh::docker::containers() {
  local subcommand=${1:-}

  if [[ -z "$subcommand" ]]; then
    return 1
  fi

  docker ps --all --format='table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}}' |
    __fzfsh_docker |
    awk '{ print $1 }' |
    xargs -I% docker container "$subcommand" %
}

# Docker - remove images by ID
function fzfsh::docker::rmi() {
  docker images --format=table |
    __fzfsh_docker |
    awk '{ print $3 }' |
    xargs -I% docker rmi -f %
}

function fzfsh::docker::volume_rm() {
  docker volume ls --filter dangling=true --format '{{ .Name }}' |
    fzf --multi |
    xargs -I% docker volume rm %
}

# Regular aliases
alias ddf='docker system df'
alias dprune!='docker system prune --volumes'

# FZF aliases
alias dstop!='fzfsh::docker::containers stop'
alias dkill!='fzfsh::docker::containers kill'
alias drmi!='fzfsh::docker::rmi'
alias dvol!='fzfsh::docker::volume_rm'
