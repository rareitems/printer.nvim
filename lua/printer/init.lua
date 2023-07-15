---@mod Printer.configuration Config
---@brief [[
--->
---{
---    behavior = "insert_below", -- behavior for the operator, "yank" will not insert but instead put text into the default '"' register
---    formatters  = {
---        filetype = function (text, text) return text end
---        -- check lua/formatters.lua for default value of formatters
---    },
---    add_to_inside = function(text) return text end -- function which adds some text to the string inside print statement
---}
---<
---@brief ]]

---@mod Printer.setting_custom_formatters Setting Custom Formatters
---@brief [[
--- Custom formatters can be setup from 'printer.setup', setting 'vim.b.printer' variable or 'vim.g.printer[filtetype]' where 'filetype' is name of the filetype.
---@brief ]]

local UsersFormatters = {}
local Behavior = nil


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
        )
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
        )
    else
        notify("printer.nvim doesn't support multiple lines ranges", vim.log.levels.ERROR)
        return nil
    end
end

local Printer = {}

AddToInside = function(text)
    return string.format("[%s:%s] %s", vim.fn.expand("%"), vim.fn.line("."), text)
end

local function input(text)
    local filetype = vim.bo.filetype
    local printer = vim.b["printer"]
        or vim.g.printer[filetype]
        or UsersFormatters[filetype]
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
    local text = get_text_from_textobject()[1]
    if text then
        input(text)
    end
end

local function operator_normal()
    vim.cmd([[set operatorfunc=v:lua.require'printer'._normal_print]])
    return "g@"
end

---@private
Printer._visual_print = function()
    local text = get_text_from_visualrange()[1]
    if text then
        input(text)
    end
end

local function operator_visual()
    vim.cmd([[set operatorfunc=v:lua.require'printer'._visual_print]])
    return "g@"
end

--- Used for setting initial configuration see |printer.configuration|
Printer.setup = function(cfg_user)
    cfg_user = cfg_user or {}

    if cfg_user.keymap then
        vim.keymap.set(
            "n",
            cfg_user.keymap,
            operator_normal,
            { expr = true, desc = "Operator keymap for printer.nvim" }
        )
        vim.keymap.set(
            "v",
            cfg_user.keymap,
            operator_visual,
            { expr = true, desc = "Operator keymap for printer.nvim" }
        )
    else
        notify("Printer config was called without a keymap")
    end

    vim.keymap.set(
        "n",
        "<Plug>(printer_print)",
        operator_normal,
        { expr = true, desc = "Get text out of textobject formatted for debug printing" }
    )

    if cfg_user.add_to_inside then
        if type(cfg_user.add_to_inside) == "function" then
            AddToInside = cfg_user.add_to_inside
        else
            notify("add_to_inside field is not a function", vim.log.levels.ERROR)
        end
    end

    UsersFormatters = cfg_user.formatters or {}
    Behavior = cfg_user.behavior or "insert_below"
    vim.g.printer = {}
end

return Printer
