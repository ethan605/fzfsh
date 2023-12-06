# Ensure git and delta are available
if (( ! ${+commands[git]} )) || (( ! ${+commands[delta]} )); then
  return 1
fi

# Heavily based on https://github.com/wfxr/forgit
FZFSH_GIT_FZF_OPTS="
  $FZF_DEFAULT_OPTS
  --ansi
  --bind='?:toggle-preview'
  --bind='ctrl-d:preview-down'
  --bind='ctrl-u:preview-up'
  --bind='alt-w:toggle-preview-wrap'
  --bind='ctrl-r:toggle-all'
  --bind='ctrl-s:toggle-sort'
  --preview-window='right:60%'
  +1
"

__fzfsh_git_pager=$(git config core.pager || echo 'delta')
__fzfsh_git_show_pager=$(git config pager.show || echo "$__fzfsh_git_pager")
__fzfsh_git_diff_pager=$(git config pager.diff || echo "$__fzfsh_git_pager")
__fzfsh_git_ignore_pager="bat -l gitignore --color=always"
__fzfsh_git_log_format="%C(auto)%h%d %s %C(black)%C(bold)%cr%Creset"

__fzfsh_copy_cmd=$([[ $(uname) == "Linux" ]] && echo "wl-copy" || echo "pbcopy")

function __fzfsh_git_inside_work_tree() { git rev-parse --is-inside-work-tree > /dev/null; }

function fzfsh::git::add() {
  __fzfsh_git_inside_work_tree || return 1

  # Add files if passed as arguments
  [[ $# -ne 0 ]] && { git add "$@"; git status -su; return 0 }

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
    if (git status --short -- \$file | grep '^??') &>/dev/null; then  # diff with /dev/null for untracked files
      git diff --color=always --no-index -- /dev/null \$file | $__fzfsh_git_diff_pager | sed '2 s/added:/untracked:/'
    else
      git diff --color=always -- \$file | $__fzfsh_git_diff_pager
    fi
  "

  local opts="$FZFSH_GIT_FZF_OPTS -0 -m --nth 2..,.."

  local files=$(
    git -c color.status=always -c status.relativePaths=true status -su |
      grep -F -e "$changed" -e "$unmerged" -e "$untracked" |
      sed -E 's/^(..[^[:space:]]*)[[:space:]]+(.*)$/[\1]  \2/' |
      FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
      sh -c "$extract"
  )

  [[ ! -n "$files" ]] && return 0
  echo "$files" | tr '\n' '\0' | xargs -0 -I% git add % && git status -su
}

function fzfsh::git::delete_branch() {
  __fzfsh_git_inside_work_tree || return 1

  # Delete branches if passed as arguments
  [[ $# -ne 0 ]] && { git branch --delete --force "$@"; return $?; }

  local preview="git log {1} --graph --pretty=format:'$__fzfsh_git_log_format' --color=always --abbrev-commit --date=relative"
  local opts="$FZFSH_GIT_FZF_OPTS +s -m --tiebreak=index --header-lines=1"

  local branches=$(
    git branch --color=always | sort -k1.1,1.1 -r |
      FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
      awk '{print $0}'
  )

  [[ -z "$branches" ]] && return 1
  echo "$branches" | sed -r 's/^\s+//gi' | tr '\n' '\0' | xargs -0 -I% git branch --delete --force %
}

function fzfsh::git::clean() {
  __fzfsh_git_inside_work_tree || return 1

  # Clean files if passed as arguments
  [[ $# -ne 0 ]] && { git clean -xdff "$@"; return $?; }

  local opts="$FZFSH_GIT_FZF_OPTS -m -0"

  # Note: Postfix '/' in directory path should be removed. Otherwise the directory itself will not be removed.
  local files=$(
    git clean -xdffn "$@" |
      sed 's/^Would remove //' |
      FZF_DEFAULT_OPTS="$opts" fzf |
      sed 's#/$##'
  )

  [[ ! -n "$files" ]] && return 0
  echo "$files" | tr '\n' '\0' | xargs -0 -I% git clean -xdff '%' && git status -su
}

function fzfsh::git::checkout_commit() {
  __fzfsh_git_inside_work_tree || return 1

  # Checkout commit if passed as arguments
  [[ $# -ne 0 ]] && { git checkout "$@"; return $?; }

  local preview="echo {} | grep -Eo '[a-f0-9]+' | head -1 | xargs -I% git show --color=always % | $__fzfsh_git_show_pager"
  local opts="
    $FZFSH_GIT_FZF_OPTS
    +s +m --tiebreak=index
    --bind=\"ctrl-y:execute-silent(echo {} | grep -Eo '[a-f0-9]+' | head -1 | tr -d '[:space:]' | $__fzfsh_copy_cmd)\"
  "

  git log --graph --color=always --format="$__fzfsh_git_log_format" |
    FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
    grep -Eo '[a-f0-9]+' |
    head -1 |
    xargs -I% git checkout % --
}

function fzfsh::git::diff() {
  __fzfsh_git_inside_work_tree || return 1

  # Show diff if passed as arguments
  [[ $# -ne 0 ]] && { git diff "$@" | eval "$__fzfsh_git_diff_pager --side-by-side"; return $? }

  local repo="$(git rev-parse --show-toplevel)"
  local preview="echo {} | sed 's/.*]  //' | xargs -I% git diff --color=always -- '$repo/%' | $__fzfsh_git_diff_pager"
  local opts="
    $FZFSH_GIT_FZF_OPTS
    +m -0
    --bind=\"enter:execute($preview --side-by-side --paging=always)\"
  "

  git diff --name-status |
    sed -E 's/^(.)[[:space:]]+(.*)$/[\1]  \2/' |
    FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview"
}

function fzfsh::git::log() {
  __fzfsh_git_inside_work_tree || return 1

  # Extract files parameters for `git show` command
  local files=$(sed -nE 's/.* -- (.*)/\1/p' <<< "$*")
  local preview="echo {} | grep -Eo '[a-f0-9]+' | head -1 | xargs -I% git show --color=always % -- $files | $__fzfsh_git_show_pager"
  local opts="
    $FZFSH_GIT_FZF_OPTS
    +s +m --tiebreak=index
    --bind=\"enter:execute($preview --side-by-side --paging=always)\"
    --bind=\"ctrl-y:execute-silent(echo {} | grep -Eo '[a-f0-9]+' | head -1 | tr -d '[:space:]' | $__fzfsh_copy_cmd)\"
  "

  git log --all --decorate --graph --color=always --format="$__fzfsh_git_log_format" $* |
    FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview"
}

function fzfsh::git::merge() {
  __fzfsh_git_inside_work_tree || return 1

  # Merge branch if passed as arguments
  [[ $# -ne 0 ]] && { git merge "$@"; return $?; }

  local preview="git log {1} --abbrev-commit --decorate --graph --pretty=format:'$__fzfsh_git_log_format' --color=always --date=relative"
  local opts="$FZFSH_GIT_FZF_OPTS +s +m --tiebreak=index --header-lines=1"

  local branch=$(
    git branch --color=always --all |
      sort -k1.1,1.1 -r |
      FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
      awk '{print $1}'
  )

  [[ -z "$branch" ]] && return 1
  git merge "$branch"
}

function fzfsh::git::rebase_interactive() {
  __fzfsh_git_inside_work_tree || return 1

  # Rebase if passed as arguments
  [[ $# -ne 0 ]] && { git rebase -i "$@"; return $?; }

  # Extract files parameters for `git show` command
  local files=$(sed -nE 's/.* -- (.*)/\1/p' <<< "$*")
  local preview="echo {} | grep -Eo '[a-f0-9]+' | head -1 | xargs -I% git show --color=always % -- $files | $__fzfsh_git_show_pager"
  local opts="
    $FZFSH_GIT_FZF_OPTS
    +s +m --tiebreak=index
    --bind=\"ctrl-y:execute-silent(echo {} | grep -Eo '[a-f0-9]+' | head -1 | tr -d '[:space:]' | $__fzfsh_copy_cmd)\"
  "
  local commit=$(
    git log --graph --color=always --format="$__fzfsh_git_log_format" $* |
      FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
      grep -Eo '[a-f0-9]+' |
      head -1
  )

  [[ -z "$commit" ]] && return 1
  git rebase -i "$commit"
}

function fzfsh::git::rebase_branch() {
  __fzfsh_git_inside_work_tree || return 1

  # Rebase if passed as arguments
  [[ $# -ne 0 ]] && { git rebase "$@"; return $?; }

  local preview="git log {1} --abbrev-commit --decorate --graph --pretty=format:'$__fzfsh_git_log_format' --color=always --date=relative"
  local opts="$FZFSH_GIT_FZF_OPTS +s +m --tiebreak=index --header-lines=1"

  local branch=$(
    git branch --color=always --all |
      sort -k1.1,1.1 -r |
      FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
      awk '{print $1}'
  )

  [[ -z "$branch" ]] && return 1
  git rebase --reapply-cherry-picks "$branch"
}

function fzfsh::git::restore() {
  __fzfsh_git_inside_work_tree || return 1

  # Add files if passed as arguments
  [[ $# -ne 0 ]] && { git restore "$@"; git status -su; return }

  local changed=$(git config --get-color color.status.changed red)

  # NOTE: paths listed by 'git status -su' mixed with quoted and unquoted style
  # remove indicators | remove original path for rename case | remove surrounding quotes
  local extract="
    sed 's/^.*]  //' |
    sed 's/.* -> //' |
    sed -e 's/^\\\"//' -e 's/\\\"\$//'
  "

  local preview="
    file=\$(echo {} | $extract)
    git diff --color=always -- \$file | $__fzfsh_git_diff_pager
  "

  local opts="$FZFSH_GIT_FZF_OPTS -0 -m --nth 2..,.."

  local files=$(
    git -c color.status=always -c status.relativePaths=true status -su |
      grep -F -e "$changed" |
      sed -E 's/^(..[^[:space:]]*)[[:space:]]+(.*)$/[\1]  \2/' |
      FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
      sh -c "$extract"
  )

  [[ -z "$files" ]] && return 1
  echo "$files" | tr '\n' '\0' | xargs -0 -I% git restore % && git status -su
}

function fzfsh::git::stash_show() {
  __fzfsh_git_inside_work_tree || return 1

  local preview="echo {} | cut -d: -f1 | xargs -I% git stash show --color=always --ext-diff % | $__fzfsh_git_diff_pager"
  local opts="
    $FZFSH_GIT_FZF_OPTS
    +s +m -0
    --tiebreak=index --bind=\"enter:execute($preview --side-by-side --paging=always)\"
  "

  git stash list | FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview"
}

function fzfsh::git::switch() {
  __fzfsh_git_inside_work_tree || return 1

  # Switch if passed as arguments
  [[ $# -ne 0 ]] && { git switch "$@"; return $?; }

  local preview="git log {1} --graph --pretty=format:'$__fzfsh_git_log_format' --color=always --abbrev-commit --date=relative"
  local opts="$FZFSH_GIT_FZF_OPTS +s +m --tiebreak=index --header-lines=1"

  local branch=$(
    git branch --color=always --all |
      sort -k1.1,1.1 -r |
      FZF_DEFAULT_OPTS="$opts" fzf --preview="$preview" |
      awk '{print $1}'
  )
  [[ -z "$branch" ]] && return 1

  # Only track for branches started with "remotes/"
  if [[ "$branch" != remotes/* ]]; then
    git switch "$branch"
    return
  fi

  if ! git switch --track "$branch" 2>/dev/null; then
    git switch "${branch#remotes/origin/}"
  fi
}

# Regular aliases
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
alias gst='git status --short --untracked-files=all'
alias gpush!='git push --force'
alias greset!='git reset --hard origin $(git branch --show-current)'

# FZF aliases
alias ga='fzfsh::git::add'
alias gbD='fzfsh::git::delete_branch'
alias gclean='fzfsh::git::clean'
alias gco='fzfsh::git::checkout_commit'
alias gd='fzfsh::git::diff'
alias glo='fzfsh::git::log'
alias gm='fzfsh::git::merge'
alias grb='fzfsh::git::rebase_interactive'
alias grB='fzfsh::git::rebase_branch'
alias grs='fzfsh::git::restore'
alias gss='fzfsh::git::stash_show'
alias gsw='fzfsh::git::switch'
