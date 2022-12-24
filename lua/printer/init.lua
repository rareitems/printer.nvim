---@mod printer.configuration Configuration
---@brief [[
--->
---{
---    behavior = "insert_below" -- behavior for the operator, "yank" will not insert but instead put text into the default '"' register
---    formatters  = {
---        filetype = function (text, text) return text end
---        -- check lua/formatters.lua for default value of formatters
---    }
---    add_to_inside = function(text) return text end -- function which adds some text to the string inside print statement, if explicitly set to 'nil' it won't add anything
---}
---<
---@brief ]]

---@mod printer.setting_custom_formatters Setting Custom Formatters
---@brief [[
--- Custom formatters can be setup from 'printer.setup', setting 'vim.b.printer' variable or 'vim.g.printer[filtetype]' where 'filetype' is name of the filetype.
---@brief ]]

local UsersFormatters = {}
local Behavior = nil

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
    notify("printer.nvim doesn't support multiple lines ranges")
    return nil
  end
end

local Printer = {}

AddToInside = function(text)
  return string.format("[%s:%s] %s", vim.fn.expand("%"), vim.fn.line("."), text)
end

local function input(text)
  local filetype = vim.bo.filetype
  local printer = vim.b["printer"] or vim.g.printer[filetype] or UsersFormatters[filetype] or require("printer.formatters")[filetype]

  if printer == nil then
    notify("no formatter defined for " .. filetype .. " filetype")
    return
  end

  if text ~= nil then
    local text_to_insert

    if AddToInside then
      text_to_insert = printer(AddToInside(text), text)
    else
      text_to_insert = printer(text, text)
    end

    if Behavior == "insert_below" then
      vim.fn.execute("normal! o" .. text_to_insert)
    elseif Behavior == "yank" then
      vim.fn.setreg('"', text_to_insert)
    end
  end
end

---@private
Printer._normal_print = function()
  input(get_text_from_textobject()[1])
end

local function operator_normal()
  vim.cmd([[set operatorfunc=v:lua.require'printer'._normal_print]])
  return "g@"
end

---@private
Printer._visual_print = function()
  input(get_text_from_visualrange()[1])
end

local function operator_visual()
  vim.cmd([[set operatorfunc=v:lua.require'printer'._visual_print]])
  return "g@"
end

--- Used for setting initial configuration see |printer.configuration|
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

  -- check if cfg_user has add_to_inside key,
  -- add_to_inside = nill should be valid can't check it just through nill check
  local has_add_to_inside = false
  for key, _ in pairs(cfg_user) do
    if key == 'add_to_inside' then
      has_add_to_inside = true
    end
  end

  if has_add_to_inside then
    AddToInside = cfg_user.add_to_inside
  end

  UsersFormatters = cfg_user.formatters or {}
  Behavior = cfg_user.behavior or "insert_below"
  vim.g.printer = {}
end

return Printer
