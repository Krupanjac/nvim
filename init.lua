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

  -- Theme & UI
  { "dracula/vim" },
  { "ryanoasis/vim-devicons" },
  { "SirVer/ultisnips" },
  { "honza/vim-snippets" },
  { "preservim/nerdtree" },
  { "preservim/nerdcommenter" },
  { "mhinz/vim-startify" }
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

-- Set filetype for C3 files
vim.api.nvim_create_autocmd({"BufRead","BufNewFile"}, {
  pattern = "*.c3",
  callback = function()
    vim.bo.filetype = "c3"
  end,
})


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
