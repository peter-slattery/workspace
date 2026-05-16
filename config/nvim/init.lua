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
pcall(vim.cmd.colorscheme, "tokyonight")

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
    -- Oil provides its own keymaps inside the directory buffer.
    -- Leaving defaults is fine for minimal config.
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

-- Pane navigation
map("n", "<leader>r", "<C-w>h", opts)
map("n", "<leader>u", "<C-w>l", opts)

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
map("n", "<leader>q", ":copen<CR>", opts) --
map("n", "<leader>c", ":cclose<CR>", opts) --
map("n", "]q", ":vertical cnext<CR>zz", opts)
map("n", "[q", ":vertical cprev<CR>zz", opts)
map("n", "[Q", ":vertical cfirst<CR>zz", opts)
map("n", "]Q", ":vertical clast<CR>zz", opts)

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

-- Terminal Nav
local function jump_to_terminal(name, repeat_last_command)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf):match(name .. "$") then
      local ok, chan = pcall(vim.api.nvim_buf_get_option, buf, "channel")
      if not ok or chan == 0 then return end
      vim.api.nvim_set_current_win(win)
      vim.cmd("startinsert")
      vim.api.nvim_chan_send(chan, "\027[A")
      return
    end
  end

  local target_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match(name .. "$") then
      target_buf = buf
      break
    end
  end

  if target_buf == nil then
    if #vim.api.nvim_list_wins() > 1 then vim.cmd("wincmd w") end
    vim.cmd("terminal")
    vim.cmd("file " .. name)
    vim.cmd("startinsert")
    return
  end

  local ok, chan = pcall(vim.api.nvim_buf_get_option, target_buf, "channel")
  if not ok or chan == 0 then return end
  if #vim.api.nvim_list_wins() > 1 then vim.cmd("wincmd w") end
  vim.api.nvim_set_current_buf(target_buf)
  vim.cmd("startinsert")
  if repeat_last_command then
      vim.api.nvim_chan_send(chan, "\027[A")
  end
end

vim.keymap.set('n', '<leader>1', function() jump_to_terminal("build", true) end, { noremap = true })
vim.keymap.set('n', '<leader>2', function() jump_to_terminal("git") end, { noremap = true })
vim.keymap.set('n', '<leader>3', function() jump_to_terminal("llm") end, { noremap = true })

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
-- Start Up
-- ==========================

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("vertical botright split")
    vim.cmd("terminal")
    vim.cmd("file build")
    vim.cmd("wincmd h")
  end
})

