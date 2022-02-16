# Ensure pass is available
if (( ! ${+commands[pass]} )); then
  return 1
fi

function __fzfsh_pass() {
  local pass_dir="$HOME/.password-store"
  fd --type=file .gpg "$pass_dir" | sed "s|^$pass_dir/||;s|.gpg$||" | fzf
}

function fzfsh::pclip() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass --clip "$entry"
}

function fzfsh::pedit() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass tailedit "$entry"
}

function fzfsh::potp() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass otp -c "$entry"
}

function fzfsh::pshow() {
  local entry=${1:-$(__fzfsh_pass)}
  [[ -z "$entry" ]] && return 1
  pass show "$entry" | bat --language=yaml --paging=always
}

alias pclip='fzfsh::pclip'
alias pedit='fzfsh::pedit'
alias potp='fzfsh::potp'
alias pshow='fzfsh::pshow'
