-- init.lua (copy-paste)
--------------------------------------------------
-- BASIC OPTIONS
--------------------------------------------------
local opt = vim.opt

opt.compatible = false
opt.showmatch = true
opt.ignorecase = true
opt.hlsearch = true
opt.incsearch = true

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

opt.number = true
opt.wildmode = { "longest", "list" }
opt.colorcolumn = "80"

opt.mouse = "a"
opt.clipboard = "unnamedplus"

opt.cursorline = true
opt.ttyfast = true

--------------------------------------------------
-- FILETYPE & SYNTAX
--------------------------------------------------
vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")

--------------------------------------------------
-- LAZY.NVIM BOOTSTRAP
--------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------
-- PLUGINS
--------------------------------------------------
require("lazy").setup({

  -- LSP core
  { "neovim/nvim-lspconfig" },

  -- Treesitter + custom C3 parser registration inside config
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    -- config receives (plugin, opts) when using lazy.nvim; register parser FIRST, then setup
    config = function(_, opts)
      -- Register c3 parser in a retry-safe way (nvim-treesitter may not be loaded yet)
      local function register_c3()
        local ok, parsers = pcall(require, "nvim-treesitter.parsers")
        if ok and parsers and parsers.get_parser_configs then
          local parser_config = parsers.get_parser_configs()
          parser_config.c3 = {
            install_info = {
              -- repo for the tree-sitter C3 grammar
              url = "https://github.com/c3lang/tree-sitter-c3",
              -- core parser file(s) to compile
              files = { "src/parser.c", "src/scanner.c" },
              queries = "queries",
              -- branch can be main or master depending on the repo
              branch = "main",
              -- set to true if the grammar requires npm for generation; this grammar uses C
              generate_requires_npm = false,
            },
            filetype = "c3",
          }
          return true
        end
        return false
      end

      if not register_c3() then
        -- Try a few times with a small delay; this avoids ordering issues during startup
        local tries = 0
        local function try()
          tries = tries + 1
          if not register_c3() and tries < 10 then
            vim.defer_fn(try, 200)
          end
        end
        try()
      end

      -- Finally setup nvim-treesitter with provided opts
      local ok2, configs = pcall(require, "nvim-treesitter.configs")
      if not ok2 then
        vim.notify("nvim-treesitter.configs not available; skipping ts setup", vim.log.levels.WARN)
        return
      end
      configs.setup(opts)

      -- Use the new nvim-treesitter install API ONLY. No legacy fallbacks.
      local ok_ts, ts = pcall(require, "nvim-treesitter")
      if ok_ts and ts and type(ts.install) == "function" then
        -- Ensure c3 is installed explicitly (safe no-op if already installed)
        pcall(function()
          if not vim.tbl_contains(ts.get_installed(), "c3") then
            ts.install({ "c3" }):wait(120000)
          end
        end)
      end

      -- Ensure treesitter highlighting starts/attaches for c3 filetype
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'c3' },
        callback = function()
          -- Prefer the highlight attach API, fallback to vim.treesitter.start()
          local ok, hl = pcall(require, 'nvim-treesitter.highlight')
          if ok and hl and type(hl.attach) == 'function' then
            pcall(function() hl.attach(0, 'c3') end)
          else
            pcall(function() vim.treesitter.start() end)
          end
        end,
      })
    end,
    opts = {
      highlight = {
        enable = true,
        -- do NOT disable "c3" here since we register a parser and want TS highlighting
      },
    },
  },

  -- C3 Highlighter / filetype helper (fallback & other helpers)
  {
    "wstucco/c3.nvim",
    ft = { "c3" },
    -- plugin uses default config; you may customize if needed
  },

  -- Smooth scrolling (neoscroll.nvim)
  {
    "karb94/neoscroll.nvim",
    event = "WinScrolled",
    config = function()
      require('neoscroll').setup({
        -- mappings to enable smooth scrolling on
        mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
        hide_cursor = true,
        stop_eof = true,
        respect_scrolloff = false,
        cursor_scrolls_alone = true,
        easing_function = "cubic",
      })
    end,
  },


  -- Theme & UI
  { "dracula/vim" },
  { "ryanoasis/vim-devicons" },
  { "SirVer/ultisnips" },
  { "honza/vim-snippets" },
  { "preservim/nerdtree" },
  { "preservim/nerdcommenter" },
  { "mhinz/vim-startify" },
  { "github/copilot.vim" },
  {
    "sphamba/smear-cursor.nvim",
    opts = {
      smear_between_buffers = true,
      smear_between_neighbor_lines = true,
      scroll_buffer_space = true,
      legacy_computing_symbols_support = false,
      smear_insert_mode = true,
    },
    config = function(_, opts)
      local ok, m = pcall(require, "smear_cursor")
      if not ok then
        vim.notify("smear_cursor not available", vim.log.levels.WARN)
        return
      end
      if type(m.setup) == "function" then
        m.setup(opts or {})
      end
      -- Ensure smear-cursor is enabled on startup. If the module exposes
      -- a boolean `enabled` field set it; otherwise call `toggle()` once
      -- to activate when appropriate.
      if m.enabled == nil then
        if type(m.toggle) == "function" then
          pcall(m.toggle)
        end
      else
        m.enabled = true
      end
    end,
  },
})

--------------------------------------------------
-- COLORSCHEME
--------------------------------------------------
vim.cmd("colorscheme dracula")

--------------------------------------------------
-- AUTOCOMMANDS
--------------------------------------------------
vim.api.nvim_create_autocmd("VimEnter", {
  command = "NERDTree",
})

-- Set filetype for C3 files (also c3i, c3t) using modern filetype detection
vim.filetype.add({
  extension = {
    c3 = "c3",
    c3i = "c3",
    c3t = "c3",
  },
})
-- Fallback: ensure older-style patterns still set filetype if needed
vim.api.nvim_create_autocmd({"BufRead","BufNewFile"}, {
  pattern = {"*.c3", "*.c3i", "*.c3t"},
  callback = function()
    vim.bo.filetype = "c3"
  end,
})

-- Sanity check: warn if required external tools for parser build are missing
local function _check_ts_prereqs()
  if vim.fn.executable('tree-sitter') == 0 then
    vim.schedule(function()
      vim.notify("warning: tree-sitter CLI not found in PATH; parser generation may fail. Install via npm or your distro package manager.", vim.log.levels.WARN)
    end)
  end
  if vim.fn.executable('gcc') == 0 and vim.fn.executable('clang') == 0 then
    vim.schedule(function()
      vim.notify("warning: no C compiler (gcc/clang) found; building parsers may fail.", vim.log.levels.WARN)
    end)
  end
end
_check_ts_prereqs()

-- Ensure user-level queries exist for c3; copy from runtime queries if missing
local function _ensure_c3_queries()
  local dst = vim.fn.stdpath('config') .. '/queries/c3'
  if vim.fn.isdirectory(dst) == 1 then
    return
  end
  local rt = (vim.api.nvim_get_runtime_file or function() return {} end)('queries/c3', false)[1]
  if not rt or rt == '' then
    -- try the installed nvim-treesitter runtime location fallback
    rt = vim.fn.stdpath('data') .. '/site/lazy/nvim-treesitter/runtime/queries/c3'
  end
  if not rt or rt == '' or vim.fn.isdirectory(rt) == 0 then
    return
  end
  vim.fn.mkdir(dst, 'p')
  local files = vim.fn.globpath(rt, '*', false, true)
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ':t')
    pcall(vim.fn.copy, f, dst .. '/' .. name)
  end
  vim.schedule(function()
    vim.notify('Copied c3 queries to ' .. dst, vim.log.levels.INFO)
  end)
end
_ensure_c3_queries()


--------------------------------------------------
-- KEYMAPS
--------------------------------------------------
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Move line / block with Alt + j/k
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)
map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)

-- Move split panes (Alt)
map("n", "<A-h>", "<C-W>H", opts)
map("n", "<A-j>", "<C-W>J", opts)
map("n", "<A-k>", "<C-W>K", opts)
map("n", "<A-l>", "<C-W>L", opts)

-- Move between panes (Ctrl)
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- NERDTree
map("n", "<C-n>", ":NERDTree<CR>", opts)
map("n", "<C-t>", ":NERDTreeToggle<CR>", opts)

-- Exit insert / visual  mode
map("i", "ii", "<Esc>", opts)
map("i", "jk", "<Esc>", opts)
map("i", "kj", "<Esc>", opts)
map("v", "jk", "<Esc>", opts)
map("v", "kj", "<Esc>", opts)

-- LSP Keymaps
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)

map("n", "<leader>li", ":LspInfo<CR>", opts)

--------------------------------------------------
-- LSP SETTINGS
--------------------------------------------------

-- Configure C3 Language Server
local lsp_ok, lspconfig = pcall(require, "lspconfig")
if lsp_ok then
  local configs = require("lspconfig.configs")
  if not configs.c3_lsp then
    configs.c3_lsp = {
      default_config = {
        cmd = { "c3-lsp" },
        filetypes = { "c3" },
        root_dir = lspconfig.util.root_pattern(".git", "."),
      },
    }
  end
  lspconfig.c3_lsp.setup({})
else
  vim.notify("nvim-lspconfig not available; c3 LSP not configured", vim.log.levels.WARN)
end

--------------------------------------------------
-- HELPFUL NOTES (displayed as comment)
--------------------------------------------------
-- After placing this file:
-- 1) Open nvim and run :Lazy sync
-- 2) Run :TSInstall c3
-- 3) If :TSInstall c3 fails, inspect :messages and run :checkhealth nvim-treesitter
-- 4) If parser builds successfully but highlighting is missing, ensure queries were installed to:
--    ~/.config/nvim/queries/c3/      (TSInstall should copy them from the repo's queries folder)

