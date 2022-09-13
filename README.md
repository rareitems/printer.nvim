<h1 align="center"> printer.nvim </h1>
<p align="center"><sup> Neovim plugin adding an operator for debug printing </sup></p>

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

#### Default Configuration

```lua
{
    behavior = "insert_below" -- behavior for the operator, "yank" will not insert but instead put text into the default '"' register
    formatters  = {
      -- check lua/config.lua for default value of formatters
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
            behavior = "insert_below" -- behavior for the operator, "yank" will not insert but instead put text into the default '"' register
            formatters = {
              -- you can define your formatters for specific filetypes by assigning function that takes a string, which is a text from the motion and returns a string
              lua = function(text)
                return string.format('print("%s: " .. %s)', text, text)
              end,
            }
          })
      -- Optional keymaps
      vim.keymap.set("n", "<C-p>", "<Plug>(printer_print)iw", {})
      vim.keymap.set("n", "<C-P>", "<Plug>(printer_print)iW", {})
      -- You can also assign your formatters through the exported global object
      Printer.cfg.formatters.lua = function(text) return text end
    end
}
```
