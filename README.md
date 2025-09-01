# floatingtodo.nvim

A quick todo list that you can quickly open for your current project or globally.

## Install

Lazy.nvim installation:

```lua
return {
  "agokule/floatingtodo.nvim",
  -- note the following options are defaults and are not required, feel free to delete them
  opts = {
    -- the file used for :TodoLocal
    --
    -- can also be a function that takes in the current file
    -- and process directory and returns the file
    target_file = ".floatingtodo.md",
    -- the file used for :TodoGlobal
    global_file = vim.fn.stdpath('data') .. '/floatingtodo.md',
    -- whether to autosave when closing
    autosave = true,
    -- can be anything mentioned in :h 'winborder'
    border = "single",
    -- width of window in % of screen size
    width = 0.8,
    -- height of window in % of screen size
    height = 0.8,
    -- can also be topleft, topright, bottomleft, bottomright
    position = "center",
    -- whether to set the mappings to auto add tasks and toggle them
    mappings = true,
  },
  keys = {
      { '<leader>tl', ':TodoLocal<cr>' },
      { '<leader>th', ':TodoGlobal<cr>' },
  }
}
```

For other package managers, you can use the following to setup floatingtodo:

```lua
require("floatingtodo").setup(<copy and paste the "opts =" table from above>)
```


