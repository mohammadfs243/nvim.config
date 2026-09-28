return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- main does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({}) -- only option: install_dir (defaults to stdpath("data") .. "/site")

      -- replaces ensure_installed (async, non-blocking)
      local parsers = {
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "html",
        "css",
        "javascript",
        "typescript",
        "astro",
      }
      local installed = ts.get_installed()
      local missing = vim.tbl_filter(function(p)
        return not vim.tbl_contains(installed, p)
      end, parsers)
      if #missing > 0 then
        ts.install(missing)
      end

      -- replaces highlight/folds/indent modules
      local max_filesize = 100 * 1024 -- 100 KB
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(args.match) -- filetype -> parser name
          if not lang then
            return
          end

          -- replaces highlight.disable(lang, buf)
          local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
          if stats and stats.size > max_filesize then
            return
          end

          if not pcall(vim.treesitter.start, buf, lang) then
            -- replaces auto_install: fetch the parser now, active on the next open of the buffer
            if
                vim.tbl_contains(ts.get_available(), lang)
                and not vim.tbl_contains(ts.get_installed(), lang)
            then
              ts.install({ lang })
            end
            return
          end

          -- replaces folds.enable
          vim.wo[0][0].foldmethod = "expr"
          vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"

          -- replaces indent.enable (experimental upstream)
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
