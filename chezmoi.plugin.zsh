# Ensure chezmoi is available
if (( ! ${+commands[chezmoi]} )); then
  return 1
fi

function __fzfsh_chezmoi_parse() {
  local files=()
  while read -r item; do files+=("$HOME/$item"); done <<< "$1"
  echo $files
}

function fzfsh::cadd() {
  local options=$(chezmoi status)
  [[ -z "$options" ]] && return 1

  local files=()
  local items=$(echo "$options" \
    | awk '{ print substr($0, 4) }' \
    | fzf --multi --preview="chezmoi diff $HOME/{} | delta")
  [[ -z "$items" ]] && return 1

  while read -r item; do files+=("$HOME/$item"); done <<< "$items"
  chezmoi add $files
}

function fzfsh::capply() {
  local options=$(chezmoi status)
  [[ -z "$options" ]] && return 1

  local files=()
  local items=$(echo "$options" \
    | awk '{ print substr($0, 4) }' \
    | fzf --multi --preview="chezmoi diff $HOME/{} | delta")
  [[ -z "$items" ]] && return 1

  while read -r item; do files+=("$HOME/$item"); done <<< "$items"
  chezmoi apply $files
}

function fzfsh::cedit() {
  local files=()
  local items=$(chezmoi list --include=files | fzf --multi)
  [[ -z "$items" ]] && return 1

  while read -r item; do files+=("$HOME/$item"); done <<< "$items"
  chezmoi edit $files
}

function fzfsh::cdiff() {
  local options=$(chezmoi status)
  [[ -z "$options" ]] && return 1

  local cmd="chezmoi diff $HOME/{} | delta"
  echo "$options" \
    | awk '{ print substr($0, 4) }' \
    | fzf --bind="enter:execute($cmd --side-by-side --paging=always)" --preview="$cmd"
}

alias cadd='fzfsh::cadd'
alias capply='fzfsh::capply'
alias cdiff='fzfsh::cdiff'
alias cedit='fzfsh::cedit'
