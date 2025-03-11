-- for easier and more intuitive setting options
local set = vim.opt

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")

vim.keymap.set("n", "<tab>", ":bnext<CR>")
vim.keymap.set("n", "<S-tab>", ":bprevious<CR>")
vim.keymap.set("n", "<space>bd", ":bdelete<CR>")

vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>")
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>")

vim.keymap.set("n", "<space>pv", ":Exp<CR>")

set.shiftwidth = 4
set.expandtab = true
set.number = true
set.relativenumber = true

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

local job_id = 0
vim.keymap.set("n", "<space>to", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 9)

  job_id = vim.bo.channel
end)

local current_command = ""
vim.keymap.set("n", "<space>te", function()
  current_command = vim.fn.input("Command: ")
end)

vim.keymap.set("n", "<space>tr", function()
  if current_command == "" then
    current_command = vim.fn.input("Command: ")
  end

  vim.fn.chansend(job_id, { current_command .. "\r\n" })
end)

require("config.lazy")
