-- Step 1: Set Up Plugin Manager (lazy.nvim)
-- This section ensures that the lazy.nvim plugin manager is installed automatically.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Step 2: Configure Core Neovim Settings
-- These settings make the editor behave more like a modern text editor.
vim.opt.termguicolors = true -- This is critical for themes to work correctly

-- [[ Virtual Whitespace ]]
vim.opt.virtualedit = "block"

-- [[ Basic Editor Settings ]]
vim.opt.number = true
vim.opt.mouse = "nic"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.whichwrap = "b,s,h,l,<,>,[,]"
vim.opt.guicursor = "i:block-Cursor"
vim.opt.showtabline = 2
vim.o.ruler = false
vim.o.tabline = "%f %m %= %l:%c %P"
vim.o.laststatus = 0

-- [[ Tabs and Indentation ]]
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.completeopt = ""

-- [[ Persistent Undo ]]
vim.opt.undofile = true
local undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undodir = undodir
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

-- Step 3: Define Keybindings (4coder Style)
local map = vim.keymap.set

local function confirm_quit()
  -- Pressing Esc again in the confirm dialog defaults to the last option, "Cancel".
  local choice = vim.fn.confirm("Would you like to save the current file before quitting?", "&Save and quit\n&Quit without saving\n&Cancel", 3)
  if choice == 1 then
    vim.cmd('wq')
  elseif choice == 2 then
    vim.cmd('q!')
  end
end

map("i", "<Esc>", confirm_quit, { noremap = true, silent = true, desc = "Confirm and quit" })
map("i", "<C-s>", "<ESC>:w<CR>a", { desc = "Save File" })
map("i", "<C-q>", "<ESC>:q!<CR>", { desc = "Quit" })
map("i", "<C-z>", "<ESC>ua", { desc = "Undo" })
map("i", "<C-y>", "<ESC><C-r>a", { desc = "Redo" })

-- Visual line navigation for wrapped lines
map({"n", "v"}, "j", "gj", { desc = "Move down by visual line" })
map({"n", "v"}, "k", "gk", { desc = "Move up by visual line" })
map({"n", "v"}, "<Down>", "gj", { desc = "Move down by visual line" })
map({"n", "v"}, "<Up>", "gk", { desc = "Move up by visual line" })

map("i", "<Up>", function()
  if vim.fn.line(".") == 1 then
    return "<C-o>0"
  else
    return "<C-o>gk"
  end
end, { expr = true, desc = "Move up by visual line, or to beginning of first line" })

map("i", "<Down>", function()
  if vim.fn.line(".") == vim.fn.line("$") then
    return "<C-o>$"
  else
    return "<C-o>gj"
  end
end, { expr = true, desc = "Move down by visual line, or to end of last line" })

map("n", "<M-x>", ":", { desc = "Enter Command Mode" })
map("i", "<M-x>", "<C-o>:", { desc = "Enter Command Mode (from Insert Mode)" })
map("c", "<Esc>", "<C-c>", { desc = "Exit Command Mode to Insert Mode" })
map("c", "<M-x>", "<C-c>", { desc = "Exit Command Mode to Insert Mode" })

map("i", "<C-Down>", "<C-o>}", { desc = "Go to next empty line" })
map("i", "<C-Up>", "<C-o>{", { desc = "Go to previous empty line" })

map("i", "<C-f>", "<C-o>/", { desc = "Incremental search" })

map("i", "<C-BS>", "<C-w>", { desc = "Delete word backwards" })
map("i", "<C-Del>", "<C-o>dw", { desc = "Delete word forwards" })

map('c', '<Up>', function()
      if vim.fn.getcmdtype() == '?' or vim.fn.getcmdtype() == '/' then
            return '<C-t>'
          else
        return '<Up>'
          end
end, { expr = true })

map('c', '<Down>', function()
      if vim.fn.getcmdtype() == '?' or vim.fn.getcmdtype() == '/' then
            return '<C-g>'
          else
        return '<Down>'
          end
end, { expr = true })

map('c', '<CR>', function()
  if vim.fn.getcmdtype() == '?' or vim.fn.getcmdtype() == '/' then
    -- The first <CR> confirms the search.
    -- <Cmd>nohlsearch<CR> then clears the highlight.
    return '<CR><Cmd>nohlsearch<CR>'
  else
    return '<CR>'
  end
end, { expr = true, desc = "Confirm search and clear highlight" })
-- [[ Marker-based editing ]]
local marker_ns = vim.api.nvim_create_namespace("marker_ns")

-- Function to get the marker and cursor positions in the correct order
local function get_ordered_region()
      if not vim.b.marker_extmark_id then
            print("Marker not set.")
        return nil
          end
      local marker_pos = vim.api.nvim_buf_get_extmark_by_id(0, marker_ns, vim.b.marker_extmark_id, {})
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      -- Adjust for API which returns 0-indexed line, 0-indexed col
      local pos1 = { marker_pos[1] + 1, marker_pos[2] }
      local pos2 = cursor_pos
      if pos1[1] > pos2[1] or (pos1[1] == pos2[1] and pos1[2] > pos2[2]) then
            return pos2, pos1
          end
      return pos1, pos2
end

local function clear_marker_if_exists()
      if vim.b.marker_extmark_id then
            vim.api.nvim_buf_clear_namespace(0, marker_ns, 0, -1)
        vim.b.marker_extmark_id = nil
      end
end

-- Reusable function to set the marker at the current cursor position
function _G.set_marker_at_cursor()
      clear_marker_if_exists()
      local pos = vim.api.nvim_win_get_cursor(0)
      local line_content = vim.api.nvim_get_current_line()
      local opts = {}

      if #line_content == 0 or pos[2] >= #line_content then
            opts.virt_text = {{' ', 'MarkerHighlight'}}
        opts.virt_text_pos = 'overlay'
      else
        opts.hl_group = 'MarkerHighlight'
        opts.end_col = pos[2] + 1
      end

      vim.b.marker_extmark_id = vim.api.nvim_buf_set_extmark(0, marker_ns, pos[1] - 1, pos[2], opts)
end

-- Set marker at current cursor position
map("i", "<C-space>", "<Cmd>lua _G.set_marker_at_cursor()<CR>", { desc = "Set marker" })

map({"i", "n"}, "<LeftDrag>", "", { noremap = true, silent = true })
map({"i", "n"}, "<RightDrag>", "", { noremap = true, silent = true })

-- Disable visual mode on drag by remapping it to a simple cursor move
map("i", "<LeftDrag>", "<LeftMouse>")
map("i", "<RightDrag>", "<RightMouse>")

-- Move cursor and set marker on click
map("i", "<LeftMouse>", "<LeftMouse><Cmd>lua _G.set_marker_at_cursor()<CR>", { desc = "Move cursor and set marker on click" })

-- Swap cursor and marker positions
map("i", "<C-m>", function()
      if not vim.b.marker_extmark_id then return end
      local marker_pos_api = vim.api.nvim_buf_get_extmark_by_id(0, marker_ns, vim.b.marker_extmark_id, {})
      local marker_pos_cursor = { marker_pos_api[1] + 1, marker_pos_api[2] }
      local current_pos = vim.api.nvim_win_get_cursor(0)

      clear_marker_if_exists()
      vim.api.nvim_win_set_cursor(0, marker_pos_cursor)

      local line_content = vim.api.nvim_buf_get_lines(0, current_pos[1] - 1, current_pos[1], false)[1] or ""
      local opts = {}

      if #line_content == 0 or current_pos[2] >= #line_content then
            opts.virt_text = {{' ', 'MarkerHighlight'}}
        opts.virt_text_pos = 'overlay'
      else
        opts.hl_group = 'MarkerHighlight'
        opts.end_col = current_pos[2] + 1
      end

      vim.b.marker_extmark_id = vim.api.nvim_buf_set_extmark(0, marker_ns, current_pos[1] - 1, current_pos[2], opts)
end, { desc = "Swap cursor and marker" })

-- Copy text between marker and cursor
map("i", "<C-c>", function()
      local start_pos, end_pos = get_ordered_region()
      if not start_pos then return end
      local lines = vim.api.nvim_buf_get_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2], {})
      local text = table.concat(lines, '\n')
      vim.fn.setreg('+', text)
      vim.fn.setreg('"', text)
end, { desc = "Copy between marker and cursor" })

-- Delete text between marker and cursor
map("i", "<C-d>", function()
      local start_pos, end_pos = get_ordered_region()
      if not start_pos then return end
      vim.api.nvim_buf_set_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2], {})
      vim.api.nvim_win_set_cursor(0, start_pos)
      clear_marker_if_exists()
end, { desc = "Delete between marker and cursor" })

-- Cut text between marker and cursor
map("i", "<C-x>", function()
      local start_pos, end_pos = get_ordered_region()
      if not start_pos then return end
      local lines = vim.api.nvim_buf_get_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2], {})
      local text = table.concat(lines, '\n')
      vim.fn.setreg('+', text)
      vim.fn.setreg('"', text)
      vim.api.nvim_buf_set_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2], {})
      vim.api.nvim_win_set_cursor(0, start_pos)
      clear_marker_if_exists()
end, { desc = "Cut between marker and cursor" })

-- Paste from system clipboard
map("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })

-- Helper function to escape special characters in Lua patterns
local function escape_pattern(s)
      return s:gsub("([%(%)%.%+%-%*%?%[%^%$%%])", "%%%1")
end

-- Replace text within the marked region
local function replace_in_region()
      local to_replace = vim.fn.input('Replace: ')
      if to_replace == '' then
            print("Replacement cancelled.")
        return
          end
      local replace_with = vim.fn.input('With: ')

      local start_pos, end_pos = get_ordered_region()
      if not start_pos then return end

      -- Save marker position before making changes
      local marker_pos_before = vim.api.nvim_buf_get_extmark_by_id(0, marker_ns, vim.b.marker_extmark_id, {})

      local lines = vim.api.nvim_buf_get_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2], {})
      local text_in_region = table.concat(lines, '\n')

      local escaped_pattern = escape_pattern(to_replace)
      local new_text, count = text_in_region:gsub(escaped_pattern, replace_with)

      local new_lines = vim.split(new_text, '\n', { plain = true })

      vim.api.nvim_buf_set_text(0, start_pos[1] - 1, start_pos[2], end_pos[1] - 1, end_pos[2], new_lines)

      -- Restore the marker to its original position
      if marker_pos_before then
        clear_marker_if_exists()
        local line_content = vim.api.nvim_buf_get_lines(0, marker_pos_before[1], marker_pos_before[1] + 1, false)[1] or ""
        local opts = {}

        if #line_content == 0 or marker_pos_before[2] >= #line_content then
            opts.virt_text = {{' ', 'MarkerHighlight'}}
            opts.virt_text_pos = 'overlay'
        else
            opts.hl_group = 'MarkerHighlight'
            opts.end_col = marker_pos_before[2] + 1
        end
        vim.b.marker_extmark_id = vim.api.nvim_buf_set_extmark(0, marker_ns, marker_pos_before[1], marker_pos_before[2], opts)
      end

      print(count .. " replacements made.")
end

map("i", "<C-a>", replace_in_region, { desc = "Replace in region" })

-- Step 4: Install and Configure Plugins
require("lazy").setup({
  -- THEME
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
        style = "night",
        on_highlights = function(hl, c)
            local red = "#d14557"
            local pink = "#ff73cc"
            local blue = "#5BCEFA"
            local default_fg = "#b3a1a4"

            -- Base Colors
            hl.Normal = { fg = default_fg, bg = "#000000" }
            hl.NormalNC = { fg = default_fg, bg = "#000000" }
            hl.Comment = { fg = blue }

            -- Keywords and Types
            hl.Keyword = { fg = red }
            hl.Statement = { fg = red }
            hl.Conditional = { fg = red }
            hl.Repeat = { fg = red }
            hl.Operator = { fg = red }
            hl.Function = { fg = red }
            hl.Identifier = { fg = default_fg }
            hl.Label = { fg = red }
            hl.Exception = { fg = default_fg }

            local dark_gray = "#807074"

            -- Types and Structures
            hl.Type = { fg = red }
            hl.StorageClass = { fg = red }
            hl.Structure = { fg = red }
            hl.Typedef = { fg = red }

            -- Preprocessor
            hl.PreProc = { fg = dark_gray }
            hl.Include = { fg = dark_gray }
            hl.Macro = { fg = dark_gray }
            hl.PreCondit = { fg = dark_gray }

            -- Constants
            hl.Constant = { fg = pink }
            hl.String = { fg = pink }
            hl.Character = { fg = pink }
            hl.Number = { fg = pink }
            hl.Boolean = { fg = pink }
            hl.Float = { fg = pink }

            -- Special Symbols
            hl.Special = { fg = default_fg }
            hl.SpecialChar = { fg = default_fg }
            hl.Tag = { fg = default_fg }
            hl.Delimiter = { fg = default_fg }
            hl.SpecialComment = { fg = default_fg }
            hl.Debug = { fg = default_fg }

            -- Text Formatting & UI
            hl.Underlined = { fg = default_fg }
            hl.Error = { fg = red }
            hl.Todo = { fg = blue }
            hl.Cursor = { fg = "#000000", bg = "#F5A9B8" }
            hl.CursorLine = { bg = "#1E1E1E" }
            hl.Visual = { bg = "#DDEE00", fg = "#000000" }
            hl.LineNr = { fg = "#404040", bg = "#101010" }
            hl.MarkerHighlight = { bg = "#333333" }
        end,
    },
  },
  -- [[ Fuzzy Finder (Telescope) ]]
      {
            "nvim-telescope/telescope.nvim",
            tag = "0.1.6",
            dependencies = {
              "nvim-lua/plenary.nvim",
              "nvim-telescope/telescope-file-browser.nvim",
            },
            config = function()
                  local telescope = require("telescope")
          local actions = require("telescope.actions")

          -- This function defines the new behavior for the Enter key.
          local function select_and_start_insert(prompt_bufnr)
            -- Use the default action to select and open the file. This also closes Telescope.
            actions.select_default(prompt_bufnr)
            -- Defer starting insert mode to ensure it happens after the file is loaded.
            vim.defer_fn(function()
                  vim.cmd.startinsert()
            end, 1)
          end

          telescope.setup({
                defaults = {
                      borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
                      prompt_prefix = "  ",
                      selection_caret = "  ",
                      mappings = {
                    i = {
                                   ["<Esc>"] = function(prompt_bufnr)
                                                actions.close(prompt_bufnr)
                                                vim.defer_fn(function()
                                                  vim.cmd.startinsert()
                                                end, 10)
                                              end,
                    -- Map Enter to the new custom function.
                      ["<CR>"] = select_and_start_insert,
                    },
                    n = {
                      ["<CR>"] = select_and_start_insert,
                    },
                  },
                    },
                extensions = {
                      file_browser = {
                    hidden = true,
                    grouped = true,
                  },
                    },
              })
          telescope.load_extension("file_browser")

          local builtin = require("telescope.builtin")

          local function browse_files_in_current_dir()
            require("telescope").extensions.file_browser.file_browser({
                  path = vim.fn.expand("%:p:h") or vim.fn.getcwd(),
                })
          end

          map("n", "<C-o>", browse_files_in_current_dir, { desc = "Browse files in current dir" })
          map("i", "<C-o>", function()
                vim.cmd.stopinsert()
            browse_files_in_current_dir()
          end, { desc = "Browse files in current dir" })

          map("n", "<C-S-p>", builtin.commands, { desc = "Command Palette" })
          map("i", "<C-S-p>", "<ESC><CMD>Telescope commands<CR>", { desc = "Command Palette" })
        end,
          },

      -- [[ File Explorer ]]
      {
            "nvim-neo-tree/neo-tree.nvim",
            branch = "v3.x",
            dependencies = {
              "nvim-lua/plenary.nvim",
              "nvim-tree/nvim-web-devicons",
              "MunifTanjim/nui.nvim",
            },
            config = function()
                  require("neo-tree").setup({
                close_if_last_window = true,
                window = { mappings = { ["<space>"] = "none", ["<cr>"] = "open", o = "open" } },
                filesystem = { follow_current_file = true, hijack_netrw_behavior = "open_current" },
                event_handlers = {
                      {
                    event = "file_opened",
                    handler = function()
                          require("neo-tree.command").execute({ action = "close" })
                end,
                  },
                    },
              })
          -- The original <C-o> mapping is removed.
          -- You can optionally map Neotree to a different key, for example <C-e>:
          -- map("n", "<C-e>", "<CMD>Neotree toggle<CR>", { desc = "Toggle File Explorer" })
          -- map("i", "<C-e>", "<ESC><CMD>Neotree toggle<CR>", { desc = "Toggle File Explorer" })
        end,
  },

  -- [[ LSP & Autocompletion ]]
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    dependencies = {
      { "neovim/nvim-lspconfig" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "L3MON4D3/LuaSnip" },
    },
  },

  -- [[ Treesitter for Advanced Highlighting ]]
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = false },
        indent = { enable = true },
        ensure_installed = { "c", "lua", "vim", "vimdoc" },
      })
    end,
  },
})

-- [[ Configure LSP ]]
local lsp = require("lsp-zero").preset({})
lsp.on_attach(function(client, bufnr)
  lsp.default_keymaps({ buffer = bufnr })

  -- Configure auto-formatting on save
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("LspFormat", {}),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })
  end
end)
lsp.setup()

-- Configure nvim-cmp for tab completion
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  completion = { completeopt = "" },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'buffer' },
  }),
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
})

-- Map Tab for simple word completion
map("i", "<Tab>", "<C-n>", { desc = "Cycle next word completion" })
map("i", "<S-Tab>", "<C-p>", { desc = "Cycle previous word completion" })

-- Set the colorscheme
vim.cmd.colorscheme("tokyonight")

-- Step 5: Make it Default to Insert Mode
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "VimEnter" }, {
  pattern = "*",
  command = "startinsert",
})

-- Step 6: Dynamic Updates & Auto-Save
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  pattern = "*",
  command = "redrawtabline",
})
vim.api.nvim_create_autocmd("FocusLost", {
    pattern = "*",
    command = "silent! wa",
})

vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
      end,
      desc = "Disable automatic comment continuation on new lines"
})

print("Neovim config loaded!")
