# shell config
alias zshconfig="$EDITOR ~/.zshrc"
alias zprofile="$EDITOR ~/.zprofile"
alias zshenv="$EDITOR ~/.zshenv"

# alias aliases :)
alias list_aliases="cat ~/.zsh/aliases.zsh"
alias aliasconfig="$EDITOR ~/.zsh/aliases.zsh"

# tool config
alias awsconfig="$EDITOR ~/.aws/config"
alias sshconfig="$EDITOR ~/.ssh/config"
alias tmuxconfig="$EDITOR ~/.tmux.conf"
alias nvimconfig="$EDITOR ~/.config/nvim/init.lua"
alias starshipconfig="$EDITOR ~/.config/starship.toml"
alias chezmoiconfig="$EDITOR ~/.zsh/chezmoi.zsh"
alias czconfig="$EDITOR ~/.zsh/chezmoi.zsh"
alias czopt="$EDITOR ~/.config/chezmoi/chezmoi.toml"
alias secretsconfig="$EDITOR ~/.zsh/secrets.zsh"
alias gitconfig="$EDITOR ~/.gitconfig"
alias termconfig="$EDITOR ~/.config/ghostty/config"

# command aliases
alias la="ll -a --color=auto"
alias ls="ls --color=auto"
alias gs="git status"
alias docker-compose="docker compose"
alias dc="docker compose"
alias ports="lsof -i -P | grep LISTEN"
alias edit="$EDITOR ."
alias reload="source ~/.zshrc" # or ~/.bashrc
alias c="clear"
alias h="history"
alias bdf="cd ~ && brew bundle dump --force && cd -" # update Brewfile
alias bb="cd ~ && brew bundle && cd -"


# remotes
alias tmux-tailscale-remote="TERM=xterm-256color ssh $TAILSCALE_REMOTE -t 'zsh -l -c \"tmux attach || tmux new\"'"
alias ttr=tmux-tailscale-remote

# ai/llm
alias aider-ollama="OLLAMA_API_BASE=$OLLAMA_API_BASE aider --model ollama_chat/$AIDER_OLLAMA_MODEL --no-auto-commits --no-attribute-author --no-attribute-committer"
alias aider-claude="aider --model $ANTHROPIC_MODEL --no-auto-commits --no-attribute-author --no-attribute-committer"

# chezmoi shortcuts
alias cz="chezmoi"
alias cza="chezmoi add"
alias czfetch="chezmoi_fetch"
alias czapply="chezmoi apply"
alias czs="chezmoi status"
alias czd="chezmoi diff"
alias cze="chezmoi edit"
alias czu="chezmoi update"
alias czm="chezmoi_manage" # update local tracked files 
alias czpath="chezmoi source-path"
alias czg="chezmoi_git_status"
alias czgs="chezmoi_git_sync"
alias czpush="chezmoi_push"
alias czpull="chezmoi_pull"

# Tmux pane management aliases
alias tsplit="tmux split-window -h"     # Split vertically (side by side)
alias tvsplit="tmux split-window -v"    # Split horizontally (one above the other)
alias tkill="tmux kill-pane"            # Kill the current pane
alias tnew="tmux new-window"     # Create a new window
alias tleft="tmux swap-pane -D"      # Move pane left
alias tright="tmux swap-pane -U"     # Move pane right
alias tup="tmux swap-pane -U"        # Move pane up
alias tdown="tmux swap-pane -D"      # Move pane down

