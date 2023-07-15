---@mod Printer.default_config Default Config
---@brief [[
--->
---{
---    behavior = "insert_below", -- default behaviour either "insert_below" for inserting the debug print below or "yank" for yanking the debug print
---    formatters  = { -- check lua/formatters.lua for default value of formatters },
---    add_to_inside = function default_addtoinside(text) return string.format("[%s:%s] %s", vim.fn.expand("%"), vim.fn.line("."), text) end,
---    -- function with signature (string) -> string which adds some text to the string inside print statement
---    default_register = [["]], -- if register is not specified to which register should "yank" put debug print
---}
---<
---@brief ]]

---@mod Printer.setting_custom_formatters Setting Custom Formatters
---@brief [[
--- Custom formatters can be setup from 'printer.setup', setting 'vim.b.printer' variable or 'vim.g.printer[filtetype]' where 'filetype' is name of the filetype.
---@brief ]]

---@mod Printer.available_keymaps Available Keymaps
---@brief [[
--- "<Plug>(printer_below)" -> Adds a line below with debug print based on the motion
--- "<Plug>(printer_yank)"  -> Yanks a line with debug print based on the motion
--- "<Plug>(printer_print)" -> Either adds or yanks the debug print (based on the supplied config)
---Example:
---   vim.keymap.set("n", "gP", "<Plug>(printer_yank)")
---   vim.keymap.set("v", "gP", "<Plug>(printer_yank)")
---@brief ]]

---@mod Printer.setting_custom_addtoinside Setting Custom addtoinside
---@brief [[
--- Function which adds some text to the string inside the print statement with '(string) -> string' signature can be setup from 'printer.setup', setting 'vim.b.printer_addtoinside' variable or 'vim.g.printer_addtoinside'
---@brief ]]

---@class Printer.config
---@field behavior string default behaviour either "insert_below" for inserting the debug print below or "yank" for yanking the debug print
---@field add_to_inside function function with signature (string) -> string which adds some text to the string inside print statement
---@field keymap string default keymap
---@field formatters table table of filetypes and function formatters
---@field default_register string to which register should "yank" put debug print if register is not specified
local CONFIG = {}

local function notify(msg, level, opts)
    vim.notify(
        "printer: " .. msg,
        level or vim.log.levels.INFO,
        vim.tbl_extend("keep", opts or {}, {
            title = "printer",
            icon = "󰐪",
        })
    )
end

-- Get range of a textobject
local function get_textobject_range()
    local marks = { "[", "]" }
    local start, endd =
        vim.api.nvim_buf_get_mark(0, marks[1]), vim.api.nvim_buf_get_mark(0, marks[2])
    return { srow = start[1], scol = start[2], erow = endd[1], ecol = endd[2] }
end

-- Get text from a range of a textobject
local function get_text_from_textobject()
    local range = get_textobject_range()
    if range.srow == range.erow then
        -- rows (lines) are 1 based indexed but have to be 0-based and inclusive so subtracting 1 from both start and end
        -- columns are 0 based indexed, have to be exclusive, so adding 1 to the end
        return vim.api.nvim_buf_get_text(
            0,
            range.srow - 1,
            range.scol,
            range.erow - 1,
            range.ecol + 1,
            {}
        )[1]
    else
        notify("printer.nvim doesn't support multiple lines ranges", vim.log.levels.ERROR)
        return nil
    end
end

-- Get range of a visual selection
local function get_visual_range()
    local marks = { "<", ">" }
    local start, endd =
        vim.api.nvim_buf_get_mark(0, marks[1]), vim.api.nvim_buf_get_mark(0, marks[2])
    return { srow = start[1], scol = start[2], erow = endd[1], ecol = endd[2] }
end

-- Get text from a range of a visual selection
local function get_text_from_visualrange()
    local range = get_visual_range()
    if range.srow == range.erow then
        -- rows (lines) are 1 based indexed but have to be 0-based and inclusive so subtracting 1 from both start and end
        -- columns are 0 based indexed, have to be exclusive, so adding 1 to the end
        return vim.api.nvim_buf_get_text(
            0,
            range.srow - 1,
            range.scol,
            range.erow - 1,
            range.ecol + 1,
            {}
        )[1]
    else
        notify("printer.nvim doesn't support multiple lines ranges", vim.log.levels.ERROR)
        return nil
    end
end

local function default_addtoinside(text)
    return string.format("[%s:%s] %s", vim.fn.expand("%"), vim.fn.line("."), text)
end

local function input_below(text)
    local filetype = vim.bo.filetype
    local printer = vim.b["printer"]
        or vim.g.printer[filetype]
        or CONFIG.formatters[filetype]
        or require("printer.formatters")[filetype]

    if printer == nil then
        notify(
            "no formatter defined for "
            .. filetype
            .. " filetype. See ':help Printer.setting_custom_formatters' on how to add formatter for this filetype."
        )
        return
    end

    if text ~= nil then
        local add_to_inside = vim.b["printer_addtoinside"]
            or vim.g["printer_addtoinside"]
            or CONFIG.add_to_inside
            or default_addtoinside

        local text_to_insert = printer(add_to_inside(text), text)
        vim.fn.execute("normal! o" .. text_to_insert)
    end
end

local function yank(text)
    local filetype = vim.bo.filetype
    local printer = vim.b["printer"]
        or vim.g.printer[filetype]
        or CONFIG.formatters[filetype]
        or require("printer.formatters")[filetype]

    if printer == nil then
        notify(
            "no formatter defined for "
            .. filetype
            .. " filetype. See ':help Printer.setting_custom_formatters' on how to add formatter for this filetype."
        )
        return
    end

    if text ~= nil then
        local add_to_inside = vim.b["printer_addtoinside"]
            or vim.g["printer_addtoinside"]
            or CONFIG.add_to_inside
            or default_addtoinside

        local text_to_insert = printer(add_to_inside(text), text)
        local register = vim.v.register or CONFIG.default_register
        vim.fn.setreg(register, text_to_insert)
    end
end

---@private
local Printer = {}

---@private
Printer._normal_print_below = function()
    local text = get_text_from_textobject()
    if text then
        input_below(text)
    end
end

---@private
Printer._normal_print_yank = function()
    local text = get_text_from_textobject()
    if text then
        yank(text)
    end
end

---@private
Printer._visual_print_below = function()
    local text = get_text_from_visualrange()
    if text then
        yank(text)
    end
end

---@private
Printer._visual_print_yank = function()
    local text = get_text_from_visualrange()
    if text then
        yank(text)
    end
end

local function operator_below()
    local mode = vim.fn.mode()
    if mode == "n" then
        vim.cmd([[set operatorfunc=v:lua.require'printer'._normal_print_below]])
    elseif mode == "v" then
        vim.cmd([[set operatorfunc=v:lua.require'printer'._visual_print_below]])
    else
        notify("called from unsupported mode :" .. mode, vim.log.levels.ERROR)
        return
    end
    return "g@"
end

local function operator_yank()
    local mode = vim.fn.mode()
    if mode == "n" then
        vim.cmd([[set operatorfunc=v:lua.require'printer'._normal_print_yank]])
    elseif mode == "v" then
        vim.cmd([[set operatorfunc=v:lua.require'printer'._visual_print_yank]])
    else
        notify("called from unsupported mode :" .. mode, vim.log.levels.ERROR)
        return
    end
    return "g@"
end

---@private
Printer._normal_print_behavior = function()
    local text = get_text_from_textobject()
    if text then
        if CONFIG.behavior == "insert_below" then
            input_below(text)
        elseif CONFIG.behavior == "yank" then
            yank(text)
        end
    end
end

local function operator_normal_behavior()
    vim.cmd([[set operatorfunc=v:lua.require'printer'._normal_print_behavior]])
    return "g@"
end

---@private
Printer._visual_print_behavior = function()
    local text = get_text_from_visualrange()
    if text then
        if CONFIG.behavior == "insert_below" then
            input_below(text)
        elseif CONFIG.behavior == "yank" then
            yank(text)
        end
    end
end

local function operator_visual_behavior()
    vim.cmd([[set operatorfunc=v:lua.require'printer'._visual_print_behavior]])
    return "g@"
end

--- Used for setting initial configuration see |Printer.config|
Printer.setup = function(cfg_user)
    cfg_user = cfg_user or {}

    if cfg_user.keymap then
        vim.keymap.set(
            "n",
            cfg_user.keymap,
            operator_normal_behavior,
            { expr = true, desc = "(printer.nvim) Operator keymap for printer.nvim" }
        )
        vim.keymap.set(
            "v",
            cfg_user.keymap,
            operator_visual_behavior,
            { expr = true, desc = "(printer.nvim) Operator keymap for printer.nvim" }
        )
    else
        notify("Printer config was called without a keymap")
    end

    vim.keymap.set("n", "<Plug>(printer_print)", operator_normal_behavior, {
        expr = true,
        desc = "(printer.nvim) Debug print based on the config behavior",
    })

    vim.keymap.set("v", "<Plug>(printer_print)", operator_visual_behavior, {
        expr = true,
        desc = "(printer.nvim) Debug print based on the config behavior - visual",
    })

    vim.keymap.set("n", "<Plug>(printer_below)", operator_below, {
        expr = true,
        desc = "(printer.nvim) Add a line below with debug print based on the motion",
    })

    vim.keymap.set("v", "<Plug>(printer_below)", operator_below, {
        expr = true,
        desc = "(printer.nvim) Add a line below with debug print based on the visual selection",
    })

    vim.keymap.set("n", "<Plug>(printer_yank)", operator_yank, {
        expr = true,
        desc = "(printer.nvim) Yank a debug print based on the motion",
    })

    vim.keymap.set("v", "<Plug>(printer_yank)", operator_yank, {
        expr = true,
        desc = "(printer.nvim) Yank a debug print based on the visual selection",
    })

    if cfg_user.add_to_inside then
        if type(cfg_user.add_to_inside) == "function" then
            CONFIG.add_to_inside = cfg_user.add_to_inside
        else
            notify("add_to_inside field is not a function", vim.log.levels.ERROR)
        end
    end

    CONFIG.behavior = cfg_user.behavior or "insert_below"
    CONFIG.formatters = cfg_user.formatters or {}
    CONFIG.default_register = cfg_user.default_register or [["]]
    vim.g.printer = {}
end

return Printer
