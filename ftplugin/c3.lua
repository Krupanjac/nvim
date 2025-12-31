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

-- Disable folding by default for c3 buffers (user requested)
-- Keep treesitter-based folding available but turned off so code is visible on open
pcall(function()
  vim.wo.foldenable = false
  -- keep the foldmethod/expr available if the user wants to enable later
  vim.wo.foldmethod = 'expr'
  vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  -- keep treesitter indentation enabled
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end)
