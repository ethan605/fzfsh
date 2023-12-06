# Ensure docker is available
if (( ! ${+commands[docker]} )); then
  return 1
fi

# Shared helper to utilise FZF for Docker
function __fzfsh_docker() {
  fzf --header-lines=1 --multi
}

# Docker - stop containers by ID
function fzfsh::docker::stop() {
  docker container stop $(
    docker ps --all --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}}' \
      | __fzfsh_docker \
      | awk '{ print $1 }'
  )
}

# Docker - kill containers by ID
function fzfsh::docker::kill() {
  docker container kill $(
    docker ps --all --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}}' \
      | __fzfsh_docker \
      | awk '{ print $1 }'
  )
}

# Docker - remove images by ID
function fzfsh::docker::rmi() {
  docker rmi -f $(
    docker images | __fzfsh_docker | awk '{ print $3 }'
  )
}

alias dstop='fzfsh::docker::stop'
alias drmi='fzfsh::docker::rmi'
alias ddf='docker system df'
alias dkill!='fzfsh::docker::kill'
alias dprune!='docker system prune --volumes'
