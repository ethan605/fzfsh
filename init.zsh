# Ensure fzf is available
if (( ! ${+commands[fzf]} )); then
  return 1
fi

source ${0:A:h}/chezmoi.plugin.zsh
source ${0:A:h}/docker.plugin.zsh
source ${0:A:h}/git.plugin.zsh
source ${0:A:h}/kubectl.plugin.zsh
source ${0:A:h}/pass.plugin.zsh
