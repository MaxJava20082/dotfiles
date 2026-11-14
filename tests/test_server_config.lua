-- Emulate Neovim 0.4: vim.opt and vim.keymap do not exist.
local maps = {}
vim = {
  g = {}, o = {}, api = {
    nvim_set_keymap = function(mode, lhs, rhs, opts)
      assert(mode == 'n' and opts.noremap and opts.silent)
      maps[lhs] = rhs
    end,
  },
}
dofile('profiles/server/nvim/init.lua')
assert(vim.o.number == true)
assert(vim.o.shell == '/bin/bash')
assert(maps['<leader>w'] == ':write<CR>')
assert(maps['<leader>lg'] == ':terminal lazygit<CR>')
print('Server config: legacy Neovim API OK')
