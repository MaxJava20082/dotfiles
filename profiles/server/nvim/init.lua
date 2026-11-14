-- No plugins, downloads, LSP runtimes or clipboard provider required over SSH.
vim.g.mapleader = ' '
vim.o.number = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.undofile = true
vim.o.mouse = ''
vim.o.shell = '/bin/bash'
vim.api.nvim_set_keymap('n', '<leader>w', ':write<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>lg', ':terminal lazygit<CR>', { noremap = true, silent = true })
