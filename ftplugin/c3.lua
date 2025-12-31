-- ftplugin/c3.lua
-- Ensure treesitter highlighting is attached and useful ft settings applied for c3
local function safe_attach()
  -- Try new highlight attach API, otherwise start treesitter for the buffer
  local ok_hl, hl = pcall(require, 'nvim-treesitter.highlight')
  if ok_hl and hl and type(hl.attach) == 'function' then
    pcall(function() hl.attach(0, 'c3') end)
    return
  end
  pcall(function() vim.treesitter.start() end)
end

-- Attach on load
safe_attach()

-- Enable folding and indentation powered by treesitter (experimental features)
pcall(function()
  vim.wo.foldmethod = 'expr'
  vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
