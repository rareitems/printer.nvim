local Printer = {}
local Helper = {}

-- Get range of a textobject
Helper.get_textobject_range = function()
  local marks = { "[", "]" }
  local start, endd = vim.api.nvim_buf_get_mark(0, marks[1]), vim.api.nvim_buf_get_mark(0, marks[2])

  return { srow = start[1], scol = start[2], erow = endd[1], ecol = endd[2] }
end

-- Get text from a range of a textobject
Helper.get_text = function()
  local range = Helper.get_textobject_range()
  if range.srow == range.erow then
    -- rows (lines) are 1 based indexed but have to be 0-based and inclusive so substracting 1 from both start and end
    -- columns are 0 based indexed, have to be exclusive, so adding 1 to the end
    return vim.api.nvim_buf_get_text(0, range.srow - 1, range.scol, range.erow - 1, range.ecol + 1, {})
  else
    vim.pretty_print "printer.nvim doesn't support multiple lines textobjects"
    return nil
  end
end

-- Combine default config and user config, replacing default values with user supplies ones
local function setup_config(cfg_user)
  local default_cfg = require "printer.config"
  local cfg = vim.tbl_deep_extend("force", default_cfg, cfg_user or {})
  return cfg
end

Printer.setup = function(cfg_user)
  _G.Printer = Printer -- export module to global scope
  local keymap = cfg_user.keymap
  if keymap == nil then
    vim.notify "Printer config was called without a keymap"
  else
    vim.keymap.set("n", keymap, Printer.operator, { expr = true, desc = "Operator keymap for printer.nvim" })
  end
  vim.keymap.set("n", "<Plug>(printer_print)", Printer.operator, { expr = true, desc = "Get text out of textobject formatted for debug printing" })
  Printer.cfg = setup_config(cfg_user)
end

Printer.print = function()
  local filetype = vim.bo.filetype
  local printer = Printer.cfg.formatters[filetype]
  if printer == nil then
    vim.pretty_print("printer.nvim doesn't support " .. filetype .. " filetype")
  else
    local text = Helper.get_text()[1]
    if text ~= nil then
      local text_to_insert = printer(text)
      if Printer.cfg.behavior == "insert_below" then
        vim.fn.execute("normal! o" .. text_to_insert)
      elseif Printer.cfg.behavior == "yank" then
        vim.fn.setreg('"', text_to_insert)
      end
    end
  end
end

Printer.operator = function()
  vim.cmd "set operatorfunc=v:lua.Printer.print"
  return "g@"
end

return Printer
