-- markdown_formatter.lua
-- A Neovim plugin to format markdown paragraphs to 80 columns using Tree-sitter

local M = {}

-- Configuration
M.config = {
  width = 80,
  preserve_indentation = true,
  skip_code_blocks = true,
  skip_tables = true,
}

-- Setup function to allow user configuration
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- Helper function to get the Tree-sitter parser
local function get_parser()
  local parser = vim.treesitter.get_parser(0, "markdown")
  if not parser then
    vim.notify("Markdown parser not available", vim.log.levels.ERROR)
    return nil
  end
  return parser
end

-- Helper function to check if a node should be skipped
local function should_skip_node(node)
  local node_type = node:type()

  if M.config.skip_code_blocks then
    local skip_types = {
      "fenced_code_block",
      "indented_code_block",
      "code_span",
    }
    for _, skip_type in ipairs(skip_types) do
      if node_type == skip_type then
        return true
      end
    end
  end

  if M.config.skip_tables then
    if node_type == "pipe_table" then
      return true
    end
  end

  -- Skip other special markdown elements
  local special_types = {
    "atx_heading",
    "setext_heading",
    "thematic_break",
    "block_quote",
    "list",
    "html_block",
  }

  for _, special_type in ipairs(special_types) do
    if node_type == special_type then
      return true
    end
  end

  return false
end

-- Helper function to wrap text to specified width
local function wrap_text(text, width, indent)
  indent = indent or ""
  local lines = {}
  local current_line = indent

  -- Split text into words
  for word in text:gmatch("%S+") do
    -- Check if adding this word would exceed the width
    local test_line = current_line == indent and (indent .. word) or (current_line .. " " .. word)

    if #test_line > width and current_line ~= indent then
      -- Start a new line
      table.insert(lines, current_line)
      current_line = indent .. word
    else
      current_line = test_line
    end
  end

  -- Add the last line if it's not empty
  if current_line ~= indent then
    table.insert(lines, current_line)
  end

  return lines
end

-- Helper function to get indentation from a line
local function get_indentation(line)
  local indent = line:match("^(%s*)")
  return indent or ""
end

-- Helper function to check if a node is a paragraph
local function is_paragraph_node(node)
  return node:type() == "paragraph"
end

-- Helper function to get text content from a node
local function get_node_text(node, bufnr)
  local start_row, start_col, end_row, end_col = node:range()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)

  if #lines == 0 then
    return ""
  end

  -- Handle single line
  if #lines == 1 then
    return lines[1]:sub(start_col + 1, end_col)
  end

  -- Handle multiple lines
  local text_parts = {}
  for i, line in ipairs(lines) do
    if i == 1 then
      table.insert(text_parts, line:sub(start_col + 1))
    elseif i == #lines then
      table.insert(text_parts, line:sub(1, end_col))
    else
      table.insert(text_parts, line)
    end
  end

  return table.concat(text_parts, "\n")
end

-- Main function to format paragraphs
function M.format_paragraphs()
  local parser = get_parser()
  if not parser then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local tree = parser:parse()[1]
  local root = tree:root()

  -- Collect all paragraph nodes that need formatting
  local paragraphs = {}

  local function collect_paragraphs(node)
    if should_skip_node(node) then
      return
    end

    if is_paragraph_node(node) then
      table.insert(paragraphs, node)
    else
      -- Recursively check children
      for child in node:iter_children() do
        collect_paragraphs(child)
      end
    end
  end

  collect_paragraphs(root)

  -- Sort paragraphs by position (bottom to top for safe editing)
  table.sort(paragraphs, function(a, b)
    local a_start = a:start()
    local b_start = b:start()
    return a_start > b_start
  end)

  -- Format each paragraph
  for _, node in ipairs(paragraphs) do
    local start_row, start_col, end_row, end_col = node:range()
    local text = get_node_text(node, bufnr)

    -- Get the indentation from the first line
    local first_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    local indent = ""

    if M.config.preserve_indentation and first_line then
      indent = get_indentation(first_line)
    end

    -- Clean up the text (remove extra whitespace and newlines)
    local clean_text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

    if clean_text ~= "" then
      -- Wrap the text
      local wrapped_lines = wrap_text(clean_text, M.config.width, indent)

      -- Replace the original text with wrapped text
      vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, wrapped_lines)
    end
  end

  vim.notify(string.format("Formatted %d paragraphs to %d columns", #paragraphs, M.config.width))
end

-- Function to format a single paragraph under cursor
function M.format_current_paragraph()
  local parser = get_parser()
  if not parser then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local tree = parser:parse()[1]
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1   -- Convert to 0-based

  -- Find the paragraph node at cursor position
  local function find_paragraph_at_position(node, target_row)
    if is_paragraph_node(node) then
      local start_row, _, end_row, _ = node:range()
      if start_row <= target_row and target_row <= end_row then
        return node
      end
    end

    for child in node:iter_children() do
      local result = find_paragraph_at_position(child, target_row)
      if result then
        return result
      end
    end

    return nil
  end

  local paragraph_node = find_paragraph_at_position(tree:root(), row)

  if not paragraph_node then
    vim.notify("No paragraph found at cursor position", vim.log.levels.WARN)
    return
  end

  if should_skip_node(paragraph_node) then
    vim.notify("Skipping formatting for this type of content", vim.log.levels.WARN)
    return
  end

  -- Format the paragraph
  local start_row, start_col, end_row, end_col = paragraph_node:range()
  local text = get_node_text(paragraph_node, bufnr)

  -- Get the indentation from the first line
  local first_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
  local indent = ""

  if M.config.preserve_indentation and first_line then
    indent = get_indentation(first_line)
  end

  -- Clean up the text
  local clean_text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  if clean_text ~= "" then
    -- Wrap the text
    local wrapped_lines = wrap_text(clean_text, M.config.width, indent)

    -- Replace the original text with wrapped text
    vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, wrapped_lines)
    vim.notify("Formatted current paragraph")
  end
end

-- Create user commands
vim.api.nvim_create_user_command("FormatMarkdownParagraphs", M.format_paragraphs, {
  desc = "Format all markdown paragraphs to configured width"
})

vim.api.nvim_create_user_command("FormatCurrentParagraph", M.format_current_paragraph, {
  desc = "Format the current paragraph under cursor"
})

return M
