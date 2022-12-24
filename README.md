<h1 align="center"> printer.nvim </h1>
<p align="center"><sup> Neovim plugin that adds an operator which allows quick adding printing/logging statements with text from textobjects / visual range based on the filetype </sup></p>

### Installation

- With [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'rareitems/printer.nvim',
    config = function()
        require('printer').setup({
            keymap = "gp" -- Plugin doesn't have any keymaps by default
          })
    end
}
```

### Usage

Use your keymap followed by a motion to quickly print/log the text from the motion.

### Default Configuration

```lua
{
    behavior = "insert_below" -- behavior for the operator, "yank" will not insert but instead put text into the default '"' register
    formatters  = {
      -- check lua/formatters.lua for default value of formatters
    }
}
```

#### More Configuration Stuffs

```lua
use {
    'rareitems/printer.nvim',
    config = function()
        require('printer').setup({
            keymap = "gp" -- Plugin doesn't have any keymaps by default
            behavior = "insert_below" -- how operator should behave
            -- "insert_below" will insert the text below the cursor
            --  "yank" will not insert but instead put text into the default '"' register
            formatters = {
              -- you can define your formatters for specific filetypes
              -- by assigning function that takes two strings
              -- one text modified by 'add_to_inside' function
              -- second the variable (thing) you want to print out
              -- see examples in lua/formatters.lua
              lua = function(inside, variable)
                return string.format('print("%s: " .. %s)', inside, variable)
              end,
            }
            -- function which modifies the text inside string in the print statement, by default it adds the path and line number
            add_to_inside = function(text)
                return string.format("[%s:%s] %s", vim.fn.expand("%"), vim.fn.line("."), text)
            end
            -- can explicitly set to nil to turn off default behaviour
            -- add_to_inside = nil
          })
    end
}
```
