local intro_logo = {
    ".▄▄ ·  ▄· ▄▌.▄▄ · ▄▄▌ ▐ ▄▌▄▄▄   ▄▄▄· ▪  ▄▄▄▄▄ ▄ .▄",
    "▐█ ▀. ▐█▪██▌▐█ ▀. ██· █▌▐█▀▄ █·▐█ ▀█ ██ •██  ██▪▐█",
    "▄▀▀▀█▄▐█▌▐█▪▄▀▀▀█▄██▪▐█▐▐▌▐▀▀▄ ▄█▀▀█ ▐█· ▐█.▪██▀▐█",
    "▐█▄▪▐█ ▐█▀·.▐█▄▪▐█▐█▌██▐█▌▐█•█▌▐█ ▪▐▌▐█▌ ▐█▌·██▌▐▀",
    " ▀▀▀▀   ▀ •  ▀▀▀▀  ▀▀▀▀ ▀▪.▀  ▀ ▀  ▀ ▀▀▀ ▀▀▀ ▀▀▀ ·",
    "         Magic blooms only in rare souls          "
}
local PLUGIN_NAME = "erised"
local DEFAULT_COLOR = "#d4be9a"
local INTRO_LOGO_HEIGHT = #intro_logo
local INTRO_LOGO_WIDTH = 55
local autocmd_group = vim.api.nvim_create_augroup(PLUGIN_NAME, {})
local highlight_ns_id = vim.api.nvim_create_namespace(PLUGIN_NAME)
local minintro_buff = -1

local function draw_minintro(buf, logo_width, logo_height)
    local window = vim.fn.bufwinid(buf)
    if window == -1 then
        return
    end
    local screen_width = vim.api.nvim_win_get_width(window)
    local screen_height = vim.api.nvim_win_get_height(window) - vim.opt.cmdheight:get()
    local start_col = math.floor((screen_width - logo_width) / 2)
    local start_row = math.floor((screen_height - logo_height) / 2)
    if start_col < 0 or start_row < 0 then
        return
    end

    local virt_lines = {}
    -- pad down to vertically center, instead of anchoring the extmark
    -- on a buffer row that may not exist yet (fixes crash on fresh buffers)
    for _ = 1, start_row do
        table.insert(virt_lines, { { "", "Default" } })
    end
    for _, line in ipairs(intro_logo) do
        table.insert(virt_lines, {
            {
                string.rep(" ", start_col) .. line,
                "Default",
            },
        })
    end

    vim.api.nvim_buf_clear_namespace(buf, highlight_ns_id, 0, -1)
    vim.api.nvim_buf_set_extmark(buf, highlight_ns_id, 0, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
    })
end

local function set_options()
    local saved = {
        number = vim.opt_local.number:get(),
        relativenumber = vim.opt_local.relativenumber:get(),
        list = vim.opt_local.list:get(),
        fillchars = vim.opt_local.fillchars:get(),
        colorcolumn = vim.opt_local.colorcolumn:get(),
    }
    vim.opt_local.number = false            -- disable line numbers
    vim.opt_local.relativenumber = false    -- disable relative line numbers
    vim.opt_local.list = false              -- disable displaying whitespace
    vim.opt_local.fillchars = { eob = ' ' } -- do not display "~" on each new line
    vim.opt_local.colorcolumn = "0"         -- disable colorcolumn
    return saved
end

local function restore_options(saved)
    vim.opt_local.number = saved.number
    vim.opt_local.relativenumber = saved.relativenumber
    vim.opt_local.list = saved.list
    vim.opt_local.fillchars = saved.fillchars
    vim.opt_local.colorcolumn = saved.colorcolumn
end

local function redraw()
    if not vim.api.nvim_buf_is_valid(minintro_buff) then
        return
    end
    draw_minintro(minintro_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)
end

local function display_minintro(payload)
    local is_dir = vim.fn.isdirectory(payload.file) == 1
    local default_buff = vim.api.nvim_get_current_buf()
    local default_buff_name = vim.api.nvim_buf_get_name(default_buff)

    -- only show the intro on an empty, unnamed buffer (or a directory arg)
    if not is_dir and default_buff_name ~= "" then
        return
    end

    minintro_buff = default_buff
    local saved_options = set_options()
    draw_minintro(minintro_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)

    vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
        group = autocmd_group,
        buffer = minintro_buff,
        callback = redraw,
    })

    -- as soon as you start typing, the logo goes away, options are
    -- restored, and you're just editing the buffer like normal
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = autocmd_group,
        buffer = minintro_buff,
        once = true,
        callback = function()
            vim.api.nvim_buf_clear_namespace(minintro_buff, highlight_ns_id, 0, -1)
            restore_options(saved_options)
        end,
    })
end

local function setup(options)
    options = options or {}
    vim.opt.shortmess:append("I") -- suppress the built-in :intro message
    vim.api.nvim_set_hl(highlight_ns_id, "Default", { fg = options.color or DEFAULT_COLOR })
    vim.api.nvim_set_hl_ns(highlight_ns_id)
    vim.api.nvim_create_autocmd("VimEnter", {
        group = autocmd_group,
        callback = display_minintro,
        once = true,
    })
end

return {
    setup = setup,
}
