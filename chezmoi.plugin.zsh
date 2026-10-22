# Ensure chezmoi is available
if (( !${+commands[chezmoi]} )); then
  return 1
fi

PREVIEW_CMD='chezmoi diff $HOME/{}'
PREVIEW_WINDOW='70%'

function __fzfsh_chezmoi_parse() {
  local files=()
  while read -r item; do files+=("$HOME/$item"); done <<<"$1"
  echo $files
}

function fzfsh::chezmoi::re-add() {
  local options=$(chezmoi status)
  [[ -z "$options" ]] && return 1

  local files=()
  local items=$(
    echo "$options" |
      awk '{ print substr($0, 4) }' |
      fzf --multi --preview="$PREVIEW_CMD" --preview-window="$PREVIEW_WINDOW"
  )
  [[ -z "$items" ]] && return 1

  while read -r item; do files+=("$HOME/$item"); done <<<"$items"
  chezmoi re-add $files
}

function fzfsh::chezmoi::apply() {
  local options=$(chezmoi status)
  [[ -z "$options" ]] && return 1

  local files=()
  local items=$(
    echo "$options" |
      awk '{ print substr($0, 4) }' |
      fzf --multi --preview="$PREVIEW_CMD" --preview-window="$PREVIEW_WINDOW"
  )
  [[ -z "$items" ]] && return 1

  while read -r item; do files+=("$HOME/$item"); done <<<"$items"
  chezmoi apply $files
}

function fzfsh::chezmoi::edit() {
  local files=()
  local items=$(chezmoi list --include=files | fzf --multi)
  [[ -z "$items" ]] && return 1

  while read -r item; do files+=("$HOME/$item"); done <<<"$items"
  chezmoi edit $files
}

function fzfsh::chezmoi::diff() {
  local options=$(chezmoi status)
  [[ -z "$options" ]] && return 1

  local addopts=''

  while (("$#")); do
		case "$1" in
      reverse)
        addopts+=" --reverse"
        shift ;;
      *)
        shift ;;
    esac
  done

  local cmd="chezmoi diff $addopts $HOME/{}"

  echo "$options" |
    awk '{ print substr($0, 4) }' |
    fzf --bind="enter:execute($cmd --side-by-side --paging=always)" --preview="$cmd" --preview-window="$PREVIEW_WINDOW"
}

# Regular aliases
alias c=chezmoi
alias cst='chezmoi status'

# FZF aliases
alias cadd='fzfsh::chezmoi::re-add'
alias capply='fzfsh::chezmoi::apply'
alias cdiff='fzfsh::chezmoi::diff'
alias cedit='fzfsh::chezmoi::edit'
