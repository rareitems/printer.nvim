local UsersFormatters = {}
local Behavior = nil

local function try_get_global_scope(ft)
  if vim.g.printer then
    return vim.g.printer[ft]
  end
end

local notify = function(text)
  vim.notify("PRINTER: " .. text)
end

-- Get range of a textobject
local function get_textobject_range()
  local marks = { "[", "]" }
  local start, endd = vim.api.nvim_buf_get_mark(0, marks[1]), vim.api.nvim_buf_get_mark(0, marks[2])
  return { srow = start[1], scol = start[2], erow = endd[1], ecol = endd[2] }
end

-- Get text from a range of a textobject
local function get_text_from_textobject()
  local range = get_textobject_range()
  if range.srow == range.erow then
    -- rows (lines) are 1 based indexed but have to be 0-based and inclusive so substracting 1 from both start and end
    -- columns are 0 based indexed, have to be exclusive, so adding 1 to the end
    return vim.api.nvim_buf_get_text(0, range.srow - 1, range.scol, range.erow - 1, range.ecol + 1, {})
  else
    vim.pretty_print("printer.nvim doesn't support multiple lines textobjects")
    return nil
  end
end

-- Get range of a visual selection
local function get_visual_range()
  local marks = { "<", ">" }
  local start, endd = vim.api.nvim_buf_get_mark(0, marks[1]), vim.api.nvim_buf_get_mark(0, marks[2])
  return { srow = start[1], scol = start[2], erow = endd[1], ecol = endd[2] }
end

-- Get text from a range of a visual selection
local function get_text_from_visualrange()
  local range = get_visual_range()
  if range.srow == range.erow then
    -- rows (lines) are 1 based indexed but have to be 0-based and inclusive so substracting 1 from both start and end
    -- columns are 0 based indexed, have to be exclusive, so adding 1 to the end
    return vim.api.nvim_buf_get_text(0, range.srow - 1, range.scol, range.erow - 1, range.ecol + 1, {})
  else
    notify("printer.nvim doesn't support multiple lines textobjects")
    return nil
  end
end

local Printer = {}

local function input(text)
  local filetype = vim.bo.filetype
  local printer = vim.b["printer"] or try_get_global_scope(filetype) or UsersFormatters[filetype] or require("printer.formatters")[filetype]

  if printer == nil then
    notify("no formatter defined for " .. filetype .. " filetype")
    return
  end

  if text ~= nil then
    local text_to_insert = printer(text)
    if Behavior == "insert_below" then
      vim.fn.execute("normal! o" .. text_to_insert)
    elseif Behavior == "yank" then
      vim.fn.setreg('"', text_to_insert)
    end
  end
end

Printer._normal_print = function()
  input(get_text_from_textobject()[1])
end

local function operator_normal()
  vim.cmd([[set operatorfunc=v:lua.require'printer'._normal_print]])
  return "g@"
end

Printer._visual_print = function()
  input(get_text_from_visualrange()[1])
end

local function operator_visual()
  vim.cmd([[set operatorfunc=v:lua.require'printer'._visual_print]])
  return "g@"
end

Printer.setup = function(cfg_user)
  local keymap = cfg_user.keymap

  if keymap == nil then
    vim.schedule_wrap(function()
      vim.notify("Printer config was called without a keymap")
    end)
  else
    vim.keymap.set("n", keymap, operator_normal, { expr = true, desc = "Operator keymap for printer.nvim" })
    vim.keymap.set("v", keymap, operator_visual, { expr = true, desc = "Operator keymap for printer.nvim" })
  end

  UsersFormatters = cfg_user.formatters or {}
  Behavior = cfg_user.behavior or "insert_below"
end

return Printer
