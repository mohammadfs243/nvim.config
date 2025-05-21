vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")

vim.keymap.set("n", "<tab>", ":bnext<CR>")
vim.keymap.set("n", "<S-tab>", ":bprevious<CR>")
vim.keymap.set("n", "<space>bd", ":bdelete<CR>")

vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>")
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>")

vim.keymap.set("n", "<space>pv", ":Exp<CR>")
vim.keymap.set("n", "<esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("t", "<C-q>", "<C-\\><C-n>")

vim.keymap.set("n", "<space>va", "ggVG")
vim.keymap.set({ "n", "v" }, "<space>y", "\"+y")
vim.keymap.set("n", "<space>Y", "\"+Y")
vim.keymap.set({ "n", "v" }, "<space>p", "\"+p")
vim.keymap.set({ "n", "v" }, "<space>P", "\"+P")

vim.keymap.set("n", "<C-h>", "<C-w><C-h>")
vim.keymap.set("n", "<C-j>", "<C-w><C-j>")
vim.keymap.set("n", "<C-k>", "<C-w><C-k>")
vim.keymap.set("n", "<C-l>", "<C-w><C-l>")

vim.keymap.set("n", "<space>s", "<cmd>split<CR>")
vim.keymap.set("n", "<space>sn", "<cmd>split new<CR>")
vim.keymap.set("n", "<space>sv", "<cmd>vsplit<CR>")
vim.keymap.set("n", "<space>svn", "<cmd>vsplit new<CR>")

vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.softtabstop = 4
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.timeoutlen = 500

vim.opt.ignorecase = true
vim.opt.smartcase = true

-- undo tree related
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
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

local harpoon = require("harpoon.ui")
vim.keymap.set("n", "<leader>ht", harpoon.toggle_quick_menu, { desc = "Toggle harpoon quick menu" })
vim.keymap.set("n", "<leader>ha", require("harpoon.mark").add_file, { desc = "Add current file to harpoon" })
vim.keymap.set("n", "<leader>hr", function()
  local harpoon = require("harpoon.mark")
  harpoon.rm_file(harpoon.get_current_index())
end, { desc = "Remove current file from harpoon" })
vim.keymap.set("n", "<space>>", harpoon.nav_next, { desc = "Go to next harpoon mark" })
vim.keymap.set("n", "<space><", harpoon.nav_prev, { desc = "Go to previous harpoon mark" })
vim.keymap.set("n", "<space>1", function() harpoon.nav_file(1) end, { desc = "Go to file 1 in harpoon marks" })
vim.keymap.set("n", "<space>2", function() harpoon.nav_file(2) end, { desc = "Go to file 2 in harpoon marks" })
vim.keymap.set("n", "<space>3", function() harpoon.nav_file(3) end, { desc = "Go to file 3 in harpoon marks" })
vim.keymap.set("n", "<space>4", function() harpoon.nav_file(4) end, { desc = "Go to file 4 in harpoon marks" })
vim.keymap.set("n", "<space>5", function() harpoon.nav_file(5) end, { desc = "Go to file 5 in harpoon marks" })
vim.keymap.set("n", "<leader>hgt", function() harpoon.nav_file(tonumber(vim.fn.input("Mark number? "))) end,
  { desc = "Go to file 5 in harpoon marks" })
