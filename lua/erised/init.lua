-- local erised_opened = false

local intro_logo = {
    "   .▄▄ ·  ▄· ▄▌.▄▄ · ▄▄▌ ▐ ▄▌▄▄▄   ▄▄▄· ▪  ▄▄▄▄▄ ▄ .▄",
    "   ▐█ ▀. ▐█▪██▌▐█ ▀. ██· █▌▐█▀▄ █·▐█ ▀█ ██ •██  ██▪▐█",
    "   ▄▀▀▀█▄▐█▌▐█▪▄▀▀▀█▄██▪▐█▐▐▌▐▀▀▄ ▄█▀▀█ ▐█· ▐█.▪██▀▐█",
    "   ▐█▄▪▐█ ▐█▀·.▐█▄▪▐█▐█▌██▐█▌▐█•█▌▐█ ▪▐▌▐█▌ ▐█▌·██▌▐▀",
    "    ▀▀▀▀   ▀ •  ▀▀▀▀  ▀▀▀▀ ▀▪.▀  ▀ ▀  ▀ ▀▀▀ ▀▀▀ ▀▀▀ ·",
    "            Magic blooms only in rare souls          "
}

local PLUGIN_NAME = "erised"
local DEFAULT_COLOR = "#98c379"
local INTRO_LOGO_HEIGHT = #intro_logo
local INTRO_LOGO_WIDTH = 55

local autocmd_group = vim.api.nvim_create_augroup(PLUGIN_NAME, {})
local highlight_ns_id = vim.api.nvim_create_namespace(PLUGIN_NAME)
local minintro_buff = -1

local function draw_minintro(buf, logo_width, logo_height)
    local window = vim.fn.bufwinid(buf)
    local screen_width = vim.api.nvim_win_get_width(window)
    local screen_height = vim.api.nvim_win_get_height(window) - vim.opt.cmdheight:get()

    local start_col = math.floor((screen_width - logo_width) / 2)
    local start_row = math.floor((screen_height - logo_height) / 2)

    if start_col < 0 or start_row < 0 then
        return
    end

    local virt_lines = {}

    for _, line in ipairs(intro_logo) do
        table.insert(virt_lines, {
            {
                string.rep(" ", start_col) .. line,
                "Default",
            },
        })
    end

    vim.api.nvim_buf_clear_namespace(buf, highlight_ns_id, 0, -1)

    vim.api.nvim_buf_set_extmark(buf, highlight_ns_id, start_row, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
    })
end
local function set_options()
    vim.opt_local.number = false         -- disable line numbers
    vim.opt_local.relativenumber = false -- disable relative line numbers
    vim.opt_local.list = false           -- disable displaying whitespace
    vim.opt_local.fillchars = { eob = ' ' } -- do not display "~" on each new line
    vim.opt_local.colorcolumn = "0"      -- disable colorcolumn
end

local function redraw()
    vim.api.nvim_buf_set_lines(minintro_buff, 0, -1, true, {})
    draw_minintro(minintro_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = autocmd_group,
        buffer = minintro_buff,
        once = true,
        callback = function()
            vim.api.nvim_buf_clear_namespace(minintro_buff, highlight_ns_id, 0, -1)
        end,
    })
end

local function display_minintro(payload)
    local is_dir = vim.fn.isdirectory(payload.file) == 1

    local default_buff = vim.api.nvim_get_current_buf()
    local default_buff_name = vim.api.nvim_buf_get_name(default_buff)
    local default_buff_filetype = vim.api.nvim_get_option_value("filetype", { buf = default_buff })
    if not is_dir and default_buff_name ~= "" and default_buff_filetype ~= PLUGIN_NAME then
        return
    end

    minintro_buff = default_buff
    set_options()

    draw_minintro(minintro_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)

    vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
        group = autocmd_group,
        buffer = minintro_buff,
        callback = redraw
    })
end

local function setup(options)
    options = options or {}
    vim.api.nvim_set_hl(highlight_ns_id, "Default", { fg = options.color or DEFAULT_COLOR })
    vim.api.nvim_set_hl_ns(highlight_ns_id)

    vim.api.nvim_create_autocmd("VimEnter", {
        group = autocmd_group,
        callback = display_minintro,
        once = true
    })
end

return {
    setup = setup
}
