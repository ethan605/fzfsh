# Ensure pass is available
if (( ! ${+commands[pass]} )); then
  return 1
fi

function __fzfsh_pass() {
  local pass_dir="$HOME/.password-store"
  fd --type=file .gpg "$pass_dir" | sed "s|^$pass_dir/||;s|.gpg$||" | fzf
}

function fzfsh::pass::clip() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass --clip "$entry"
}

function fzfsh::pass::edit() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass edit "$entry"
}

function fzfsh::pass::otp() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass otp -c "$entry"
}

function fzfsh::pass::show() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass show "$entry" | bat --language=yaml --paging=always
}

function fzfsh::pass::update() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass update -E "$entry"
}

alias pclip='fzfsh::pass::clip'
alias pedit='fzfsh::pass::edit'
alias potp='fzfsh::pass::otp'
alias pshow='fzfsh::pass::show'
alias pupdate='fzfsh::pass::update'
