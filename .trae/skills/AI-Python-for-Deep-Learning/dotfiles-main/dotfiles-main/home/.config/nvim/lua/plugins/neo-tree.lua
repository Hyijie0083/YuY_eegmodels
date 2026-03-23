return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = false, -- Show hidden files by default
        hide_dotfiles = false, -- Don't hide dotfiles (i.e., files starting with a dot)
        hide_gitignored = false,
      },
      never_show = {
        ".DS_Store",
        "thumbs.db",
      },
      follow_current_file = true, -- Optionally, if you want Neo-tree to always follow the current file
      group_empty_dirs = true, -- Optionally group empty dirs
      sort_by = "type", -- Sort by type
    },
  },
}
