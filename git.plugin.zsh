# Ensure git and delta is available
if (( ! ${+commands[git]} )) || (( ! ${+commands[delta]} )); then
  return 1
fi

# Heavily based on https://github.com/wfxr/forgit
__fzfsh_git_pager=$(git config core.pager || echo 'delta')
__fzfsh_git_show_pager=$(git config pager.show || echo "$__fzfsh_git_pager")
__fzfsh_git_diff_pager=$(git config pager.diff || echo "$__fzfsh_git_pager")
__fzfsh_git_ignore_pager="bat -l gitignore --color=always"

FZFSH_GIT_FZF_OPTS="
  $FZF_DEFAULT_OPTS
  --ansi
  --bind='?:toggle-preview'
  --bind='alt-j:preview-down,alt-n:preview-down'
  --bind='alt-k:preview-up,alt-p:preview-up'
  --bind='alt-w:toggle-preview-wrap'
  --bind='ctrl-r:toggle-all'
  --bind='ctrl-s:toggle-sort'
  --preview-window='right:60%'
  +1
"

function __fzfsh_git_inside_work_tree() { git rev-parse --is-inside-work-tree >/dev/null; }

function fzfsh::git::add() {
  __fzfsh_git_inside_work_tree || return 1

  # Add files if passed as arguments
  [[ $# -ne 0 ]] && git add "$@" && git status -su && return 0

  local changed=$(git config --get-color color.status.changed red)
  local unmerged=$(git config --get-color color.status.unmerged red)
  local untracked=$(git config --get-color color.status.untracked red)

  # NOTE: paths listed by 'git status -su' mixed with quoted and unquoted style
  # remove indicators | remove original path for rename case | remove surrounding quotes
  local extract="
    sed 's/^.*]  //' |
    sed 's/.* -> //' |
    sed -e 's/^\\\"//' -e 's/\\\"\$//'
  "

  local preview="
    file=\$(echo {} | $extract)
    if (git status -s -- \$file | grep '^??') &>/dev/null; then  # diff with /dev/null for untracked files
      git diff --color=always --no-index -- /dev/null \$file | $__fzfsh_git_diff_pager | sed '2 s/added:/untracked:/'
    else
      git diff --color=always -- \$file | $__fzfsh_git_diff_pager
    fi
  "

  local opts="
    $FZFSH_GIT_FZF_OPTS
    -0 -m --nth 2..,..
  "

  local files=$(
    git -c color.status=always -c status.relativePaths=true status -su |
    grep -F -e "$changed" -e "$unmerged" -e "$untracked" |
    sed -E 's/^(..[^[:space:]]*)[[:space:]]+(.*)$/[\1]  \2/' |
    FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
    sh -c "$extract"
  )

  [[ ! -n "$files" ]] && echo 'Nothing to add.'
  echo "$files" | tr '\n' '\0' | xargs -0 -I% git add % \
    && git status -su
}

alias g=git
alias gaa='git add --all'
alias gau='git add --update'
alias gb='git branch --all --color=always | sort -k1.1,1.1 -r | fzf --header-lines=1'
alias gcl='git clone --recurse-submodules'
alias gcm='git commit --message'
alias gfl='git fetch --prune && git pull origin $(git branch --show-current)'
alias ggl='git pull origin $(git branch --show-current)'
alias ggp='git push origin $(git branch --show-current)'
alias ggpu='git push --set-upstream origin $(git branch --show-current)'
alias glgg='git log --all --decorate --graph'
alias glgo='git log --all --decorate --graph --oneline'
alias gpush='git push --force'
alias greset='git reset --hard origin $(git branch --show-current)'
alias gst='git status'

alias ga='fzfsh::git::add'
#alias gbD='fzfsh::git::delete::branch'
#alias gclean='fzfsh::git::clean'
#alias gco='fzfsh::git::checkout::commit'
#alias gd='fzfsh::git::diff'
#alias glo='fzfsh::git::log'
#alias gm='fzfsh::git::merge'
#alias grb='fzfsh::git::rebase'
#alias grs='fzfsh::git::restore'
#alias gss='fzfsh::git::stash::show'
#alias gsw='fzfsh::git::switch'
