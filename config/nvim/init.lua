-- ==========================
-- Basic Sane Defaults
-- ==========================

vim.g.mapleader = " "

vim.opt.number = true -- show line numbers
vim.opt.relativenumber = true
vim.opt.hidden = true -- allow switching buffers without saving
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.updatetime = 300
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
vim.opt.wrap = false

vim.o.autoread = true -- read files when changed on disk

vim.opt.timeoutlen = 250
vim.opt.ttimeoutlen = 50

vim.opt.splitright = true  -- :vsplit opens to the right
vim.opt.splitbelow = true

-- Autocomplete
vim.opt.complete = {'.', 'w', 'b', 'u'} -- complete based on tokens in { current buffer, other windows, all buffers, unloaded buffers in buffer list }
vim.opt.completeopt = {"menu", "menuone", "noselect"} -- show completion popup nicely

-- Command-line completion: show suggestions in a popup menu.
-- Press <Tab> after ':' to see/cycle available commands (and their args).
vim.opt.wildmenu = true
vim.opt.wildmode = {"longest:full", "full"} -- complete longest common, then cycle full matches
vim.opt.wildoptions = "pum" -- show candidates in a popup menu above the command line

-- Tab Behavior
vim.opt.expandtab = true -- insert spaces
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4 -- literal tab is 4 spaces
vim.opt.softtabstop = 4 -- tab in insert mode = 4 spaces
vim.opt.smartindent = true
vim.opt.autoindent = true -- copy indentation of previous line

-- Use ripgrep for grep
vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

-- Make find and ** work recursively
vim.opt.path:append("**")

-- Sane Indentation Defaults
vim.opt.cinoptions = "l1,g0,N-s,+0"

-- ==========================
-- netrw config
-- ==========================

vim.g.netrw_banner = 0 -- hide banner
vim.g.netrw_liststyle = 3 -- tree view

-- ==========================
-- plugin config
-- ==========================

-- INSTALLATION
-- 1. brew install fzf, or apt install fzf

local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/vendor/start"

-- Helper to clone a repo if it doesn't exist
local function ensure_repo(repo_url, folder_name, branch)
	local path = install_path .. "/" .. folder_name
	if vim.fn.isdirectory(install_path) == 0 then
		vim.fn.mkdir(install_path, 'p')
	    	print("Created directory: " .. install_path)
	end
	if vim.fn.empty(fn.glob(path)) > 0 then
		print("Installing " .. folder_name .. "...")
		local cmd = {"git", "clone", "--depth", "1"}
		if branch then
			table.insert(cmd, "--branch")
			table.insert(cmd, branch)
		end
		table.insert(cmd, repo_url)
		table.insert(cmd, path)
		vim.fn.system(cmd)
		if vim.fn.isdirectory(path) == 1 then
		    vim.opt.runtimepath:append(path)
		end
		return true
	end
	return false
end

-- ==========================
-- tokyonight
-- ==========================

ensure_repo("https://github.com/folke/tokyonight.nvim.git", "tokyonight.nvim")
pcall(vim.cmd.colorscheme, "tokyonight-night")

-- Easy-to-remember theme switching: :Dark and :Light
vim.api.nvim_create_user_command("Dark", function()
  vim.opt.background = "dark"
  pcall(vim.cmd.colorscheme, "tokyonight-night")
end, { desc = "switch to dark theme" })

vim.api.nvim_create_user_command("Light", function()
  vim.opt.background = "light"
  pcall(vim.cmd.colorscheme, "tokyonight-day")
end, { desc = "switch to light theme" })

-- ==========================
-- fzf config
-- ==========================

ensure_repo("https://github.com/junegunn/fzf.git", "fzf")
ensure_repo("https://github.com/junegunn/fzf.vim.git", "fzf.vim")

vim.g.fzf_layout = {
	window = {
		width = 0.9,
		height = 0.8,
	}
}

-- Better default ripgrep command for fzf
vim.env.FZF_DEFAULT_COMMAND = "rg --files --hidden --follow --glob '!.git/*'"

vim.g.fzf_action = {
  -- keep default enter behavior (open)
  ["enter"]  = "edit",
  ["ctrl-s"] = "split",
  ["ctrl-v"] = "vsplit",
  ["ctrl-t"] = "tabedit",
  ["ctrl-q"] = function(lines)
    vim.fn.setqflist({}, " ", { title = "FZF", lines = lines })
    vim.cmd("copen")
  end,
}

-- ==========================
-- lualine config
-- ==========================

ensure_repo("https://github.com/nvim-lualine/lualine.nvim.git", "lualine.nvim")

vim.opt.showmode = false
pcall(function()
  require("lualine").setup({
    options = {
      theme = "auto",
      icons_enabled = false,
      section_separators = "",
      component_separators = "|",
    },
    sections = {
      lualine_a = { "mode" },      -- mode now lives here
      lualine_b = { "branch" },
      lualine_c = { { "filename", path = 1 } }, -- 0=name, 1=relative, 2=absolute
      lualine_x = { "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    }
  })
end)

-- ==========================
-- oil.nvim (file explorer with real file ops)
-- ==========================

ensure_repo("https://github.com/stevearc/oil.nvim.git", "oil.nvim")

pcall(function()
  require("oil").setup({
    -- Keep it simple and fast; no icons needed
    columns = {},
    view_options = {
      show_hidden = true, -- set false if you prefer
    },
    lsp_file_methods = {
      enabled = false,
    },
    keymaps = {
      ["<C-h>"] = false,
      ["<C-j>"] = false,
      ["<C-k>"] = false,
      ["<C-l>"] = false,
    }
  })
end)

-- Keybind: open Oil in the current file's directory
vim.keymap.set("n", "<leader>e", function()
  pcall(function() require("oil").open(vim.fn.expand("%:p:h")) end)
end, { noremap = true, silent = true })

-- Keybind: open Oil in current working directory
vim.keymap.set("n", "<leader>E", function()
  pcall(function() require("oil").open(vim.loop.cwd()) end)
end, { noremap = true, silent = true })

-- ==========================
-- fugitive (git)
-- ==========================

ensure_repo("https://github.com/tpope/vim-fugitive.git", "vim-fugitive")

vim.keymap.set("n", "<leader>gs", ":Git<CR>", { noremap = true, silent = true })      -- status
vim.keymap.set("n", "<leader>gd", ":Gdiffsplit<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gb", ":Gblame<CR>", { noremap = true, silent = true })

-- ==========================
-- vim-easy-align
-- ==========================

ensure_repo("https://github.com/junegunn/vim-easy-align.git", "vim-easy-align")

-- Start interactive EasyAlign in visual mode (e.g. vipga) and for motion/text object (e.g. gaip)
vim.keymap.set("x", "ga", "<Plug>(EasyAlign)", {})
vim.keymap.set("n", "ga", "<Plug>(EasyAlign)", {})

-- ==========================
-- tree-sitter
-- ==========================

-- INSTALLATION
-- 1. Requires a C compiler (cc / gcc / clang) on PATH to build parsers
-- 2. After first start, run :TSUpdate to fetch the parsers in ensure_installed
-- 3. Pinned to 'master' branch — the in-progress 'main' rewrite has a different API

local ts_fresh = ensure_repo("https://github.com/nvim-treesitter/nvim-treesitter.git",
                             "nvim-treesitter", "master")
ensure_repo("https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git",
            "nvim-treesitter-textobjects", "master")

pcall(function()
  require("nvim-treesitter.configs").setup({
    ensure_installed = {
      "c", "cpp", "rust", "typescript", "tsx", "javascript",
      "lua", "vim", "vimdoc", "query",
    },
    sync_install = false,
    auto_install = false, -- only install what's listed above
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
      disable = { "cpp" }, -- cinoptions handles C++ better; TS indent fights it
    },
    incremental_selection = {
      enable = true,
      -- defaults: gnn / grn / grc / grm (won't shadow your leader maps)
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- jump forward to the next textobject
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- adds to jumplist so <C-o>/<C-i> work
        goto_next_start     = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
        goto_previous_start = { ["[m"] = "@function.outer", ["[["] = "@class.outer" },
      },
    },
  })
  if ts_fresh then
    vim.schedule(function() vim.cmd("TSUpdate") end)
  end
end)

-- Tree-sitter folding (off by default; toggle with zi, fold/unfold with za)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr   = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false

-- ==========================
-- Key mappings
-- ==========================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Basic Navigation
-- Should remain similar to default vim/neovim bindings
map("n", "j", "jzz", opts)
map("n", "k", "kzz", opts)

-- Pane navigation (tmux gets Alt-hjkl, apps get Ctrl).
-- Terminal-mode variants drop out of insert first, then jump.
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)

-- Search
map("n", "<leader>g", ":Rg<CR>", opts) -- ripgrep search
map("x", "<leader>g", function() -- ripgrep visual selection (literal, no regex)
  local save = vim.fn.getreg('h')
  local save_type = vim.fn.getregtype('h')
  vim.cmd('noautocmd silent normal! gv"hy')
  local sel = vim.fn.getreg('h'):gsub("\n", " ")
  vim.fn.setreg('h', save, save_type)
  if sel == "" then return end
  local cmd = "rg --column --line-number --no-heading --color=always --smart-case --fixed-strings -- "
              .. vim.fn["fzf#shellescape"](sel)
  local spec = vim.fn["fzf#vim#with_preview"]({ options = { "--query=" .. sel } })
  vim.fn["fzf#vim#grep"](cmd, spec)
end, { noremap = true, silent = true })
map("n", "<leader>/", ":BLines<CR>", opts) -- search in current buffer

-- Quickfix
-- Force the quickfix window to span the full width at the very bottom
-- (rather than inheriting the current split column). Loclists stay per-window.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    if vim.fn.win_gettype() == "quickfix" then
      vim.cmd("wincmd J")
    end
  end,
})

map("n", "<leader>q", ":copen<CR>", opts) --
map("n", "<leader>c", ":cclose<CR>", opts) --
-- Jump through quickfix and center the destination. The recenter is scheduled
-- so it lands after :cnext's buffer-load autocmds (e.g. cursor restore) and the
-- redraw settle, which an inline `zz` can race against.
local function qf_nav(cmd)
  local ok, err = pcall(vim.cmd, "vertical " .. cmd)
  if not ok then
    return vim.notify(err:gsub("^Vim%(.-%):", ""), vim.log.levels.WARN)
  end
  vim.schedule(function() vim.cmd("normal! zz") end)
end

map("n", "qj", function() qf_nav("cnext") end, opts)
map("n", "qk", function() qf_nav("cprev") end, opts)
map("n", "qJ", function() qf_nav("cfirst") end, opts)
map("n", "qK", function() qf_nav("clast") end, opts)

-- File navigation
map("n", "<leader>f", ":Files<CR>", opts) -- project files
map("n", "<leader>b", ":Buffers<CR>", opts) -- buffers
map("n", "<leader>h", ":History<CR>", opts) -- file history

-- Parse current buffer into quickfix
vim.api.nvim_create_user_command("QfFromBuffer", function()
  -- Use current 'errorformat' to parse current buffer into quickfix
  vim.cmd("cgetbuffer")
  vim.cmd("copen")
end, {})
map("n", "<leader>qb", ":QfFromBuffer<CR>", opts)

-- Horizontal split in current pane
vim.api.nvim_create_user_command("Hs", "split", {})
vim.cmd([[cnoreabbrev <expr> hs (getcmdtype() == ':' && getcmdline() ==# 'hs') ? 'Hs' : 'hs']])

-- Location list (per-window)
map("n", "]l", ":lnext<CR>zz", opts)
map("n", "[l", ":lprev<CR>zz", opts)
map("n", "<leader>lo", ":lopen<CR>", opts)
map("n", "<leader>lq", ":lclose<CR>", opts)

-- Terminal
map("n", "<leader>t", ":terminal<CR>", opts) --
map("t", "jk", "<C-\\><C-n>", opts) -- exit terminal insert mode

-- Rerun last shell command
map("n", "<leader>!", ":!!<CR>", opts) --

-- Autocomplete
map('i', '<Tab>', 'v:lua.smart_tab()', { expr = true, noremap = true })
map('i', '<S-Tab>', '<C-p>', { noremap = true })

-- Checks if we're indenting vs trying to autocomplete
function _G.smart_tab()
	local col = vim.fn.col('.') - 1
	local line = vim.fn.getline('.')
	
	-- Always indent if at start of line or only whitespace before cursor
	if col == 0 or line:sub(1, col):match('^%s*$') then
		return vim.api.nvim_replace_termcodes('<Tab>', true, true, true)
	else
		-- Use regular insert completion (<C-n>) instead of omni
		return vim.fn["pumvisible"]() == 1 and vim.api.nvim_replace_termcodes('<C-n>', true, true, true) or vim.api.nvim_replace_termcodes('<C-n>', true, true, true)
	end
end

-- Exit Insert Mode
map('i', 'jk', '<Esc>', { noremap = true, silent = true })

-- Center screen on jumps
map('n', 'n', 'nzz', opts)
map('n', 'N', 'Nzz', opts)
map('n', '{', '{zz', opts)
map('n', '}', '}zz', opts)
map('n', '<C-d>', '<C-d>zz', opts)
map('n', '<C-u>', '<C-u>zz', opts)

-- Search and Replace
map('n', '<leader>s', ':%s/\\<<C-r><C-w>\\>//g<Left><Left>', { noremap = true }) -- replace word under cursor
map('v', '<leader>s', '"hy:%s/<C-r>h//g<Left><Left>', { noremap = true }) -- replace visual selection

-- ==========================
-- Quality of Life
-- ==========================

vim.api.nvim_create_autocmd("BufReadPost", {
	-- Remember last cursor position
	callback = function()
		-- Remember mark
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end

		-- Detect File Indentation based on first 100 lines
		local buf = vim.api.nvim_get_current_buf()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, 100, false)
		local prev_indent = nil
		local diffs = {}
		for _, line in ipairs(lines) do
			local indent = line:match("^(%s+)")
			if indent then
				local n = #indent
				if prev_indent then
					local diff = n - prev_indent
					if diff > 0 then
						diffs[diff] = (diffs[diff] or 0) + 1
					end
				end
				prev_indent = n
			end
		end
		local max_diff, max_freq = 0, 0
		for n, freq in pairs(diffs) do
			if freq > max_freq then
				max_freq = freq
				max_diff = n
			end
		end
		if max_diff > 0 and max_diff ~= 4 then
			vim.opt_local.shiftwidth = max_diff
			vim.opt_local.tabstop = max_diff
			vim.opt_local.softtabstop = max_diff
		end
	end
})

vim.cmd [[
	autocmd! User FzfPreviewClose redraw!
]]

-- Stop auto-continuing comments on <Enter> (r) and o/O (o).
-- Bundled ftplugins re-add these flags per filetype, so strip on every FileType.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

-- ==========================
-- Run Command List / Buffer
-- ==========================

local cmd_buf = nil
local CMD_BUF_NAME = 'Run Commands'
local last_command_line = nil

-- reuse the Run Commands buffer if it exists, otherwise create it empty
local function ensure_buf()
  if cmd_buf and vim.api.nvim_buf_is_valid(cmd_buf) then return cmd_buf end
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b)
       and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ':t') == CMD_BUF_NAME then
      cmd_buf = b
      return b
    end
  end
  cmd_buf = vim.api.nvim_create_buf(true, true)  -- listed, scratch (nofile/hide/noswap)
  vim.api.nvim_buf_set_name(cmd_buf, CMD_BUF_NAME)
  -- vim.bo[cmd_buf].filetype = 'sh'  -- optional: shell highlighting for each line
  return cmd_buf
end

-- create it at startup so it's ready (not shown; opened on demand below)
vim.api.nvim_create_autocmd('VimEnter', { callback = ensure_buf })

-- toggle the buffer in a split
vim.keymap.set('n', '<leader>R', function()
  local buf = ensure_buf()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return vim.api.nvim_win_close(win, false)
    end
  end
  vim.cmd.split()
  vim.api.nvim_win_set_buf(0, buf)
end, { desc = 'toggle Run Commands buffer' })

-- run line N of the Run Commands buffer via :make
local function run_line(n)
  local buf = ensure_buf()
  local line = vim.api.nvim_buf_get_lines(buf, n - 1, n, false)[1]
  if not line or line:match('^%s*$') or line:match('^%s*#') then
    return vim.notify('no command on line ' .. n, vim.log.levels.WARN)
  end
  vim.o.makeprg = line
  vim.cmd.make()
end

for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, function() run_line(i) end,
    { desc = 'run Run Commands line ' .. i })
end

-- run the current make line - if one was set via <leader># earlier, it will be run here
map("n", "<leader>r", ":make<CR>", opts)

-- ==========================
-- UI Improvements
-- ==========================

vim.opt.cursorline = true
vim.opt.pumheight = 12 -- Slightly nicer completion/menu borders (built-in UI)

vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a2a" })
vim.api.nvim_set_hl(0, "Search", { fg = "#000000", bg = "#ffd75f" })
vim.api.nvim_set_hl(0, "IncSearch", { fg = "#000000", bg = "#ffaf00" })

-- Simple informative statusline
vim.opt.laststatus = 2
vim.opt.statusline = table.concat({
  " %f",            -- file path
  "%m%r%h%w",       -- flags: modified/readonly/help/preview
  " %=",
  " %{&filetype}",
  " [%{&fileformat}]",
  " %l:%c ",
})

-- Show some invisible characters
vim.opt.list = true
vim.opt.listchars = {
  tab = "»·",
  trail = "·",
  extends = "›",
  precedes = "‹",
  nbsp = "␣",
}

-- ==========================
-- Section break rendering
-- ==========================
-- A line of the form `<comment> ~` renders as a full-width rule.
-- A line of the form `<comment> ~ <title>` renders as `── title ──`.
-- The line the cursor is on always shows its raw text, so it stays editable
-- and the cursor is never lost under the overlay.

local section_ns = vim.api.nvim_create_namespace("section_break")

-- box-drawing horizontal line; swap for "=" if your font lacks it
local SECTION_RULE = "─"

local function section_leader(bufnr)
  local cs = vim.bo[bufnr].commentstring
  if cs == nil or cs == "" then return nil end
  local prefix = cs:match("^(.-)%s*%%s")
  if prefix == nil or prefix == "" then return nil end
  return vim.trim(prefix)
end

local function section_render(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, section_ns, 0, -1)

  local leader = section_leader(bufnr)
  if not leader then return end

  local leader_pat = vim.pesc(leader)
  local break_pat = "^%s*" .. leader_pat .. "%s*~%s*$"
  local title_pat = "^%s*" .. leader_pat .. "%s*~%s+(.-)%s*$"

  local width = vim.bo[bufnr].textwidth
  if width == nil or width <= 0 then width = 80 end

  -- Don't render the line the cursor sits on (in windows showing this buffer),
  -- so it reveals its raw, editable text.
  local skip = {}
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    skip[vim.api.nvim_win_get_cursor(win)[1]] = true
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if not skip[i] then
      local rendered
      if line:match(break_pat) then
        rendered = string.rep(SECTION_RULE, width)
      else
        local title = line:match(title_pat)
        if title and title ~= "" then
          local pad = width - #title - 2
          if pad < 4 then pad = 4 end
          local left = math.floor(pad / 2)
          local right = pad - left
          rendered = string.rep(SECTION_RULE, left) .. " " .. title .. " " .. string.rep(SECTION_RULE, right)
        end
      end
      if rendered then
        vim.api.nvim_buf_set_extmark(bufnr, section_ns, i - 1, 0, {
          virt_text = { { rendered, "Comment" } },
          virt_text_pos = "overlay",
          hl_mode = "combine",
        })
      end
    end
  end
end

vim.api.nvim_create_autocmd({
  "BufEnter", "BufWinEnter", "FileType", "TextChanged", "TextChangedI",
  "CursorMoved", "CursorMovedI",
}, {
  callback = function(args) section_render(args.buf) end,
})
