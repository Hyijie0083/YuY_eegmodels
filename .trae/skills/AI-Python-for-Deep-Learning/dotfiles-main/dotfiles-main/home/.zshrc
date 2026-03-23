# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Which plugins would you like to load?
plugins=(git pyenv rbenv macos z direnv tmux)

source $ZSH/oh-my-zsh.sh

# rbenv
eval "$(rbenv init -)"

# starship
eval "$(starship init zsh)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
eval "$(pyenv virtualenv-init -)"


#ssh
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check if ssh-agent is already running
   ps -ef | grep ssh-agent | grep -v grep > /dev/null
   if [ $? -eq 1 ]; then
     # Start ssh-agent
    eval "$(ssh-agent -s)" > /dev/null 2>&1
   fi
fi

ssh-add --apple-use-keychain $DAFAULT_SSH_KEY 2>/dev/null


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$HOME/.local/bin:$PATH"

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/nategreen/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# source all custom scripts in ~/.zsh/
for config (~/.zsh/*.zsh) source $config

compinit -u

export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# llm-orc completion (must be after compinit)
eval "$(_LLM_ORC_COMPLETE=zsh_source llm-orc completion)"
