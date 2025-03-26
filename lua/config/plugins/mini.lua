return {
  {
    'echasnovski/mini.statusline',
    config = function()
      local statusline = require('mini.statusline')
      statusline.setup { use_icons = true }
      -- require("mini.pairs").setup()
    end
  }
}
