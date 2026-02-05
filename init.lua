vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.zig_fmt_autosave = false    -- Disable builtin zig autoformatter

vim.opt.wrap = false              -- Disable line wrapping
vim.opt.expandtab = true          -- Use spaces instead of tabs
vim.opt.tabstop = 4               -- Number of spaces a <Tab> counts for
vim.opt.softtabstop = 4           -- Number of spaces a <Tab> counts for while editing
vim.opt.shiftwidth = 4            -- Number of spaces to use for each step of (auto)indent
vim.opt.number = true             -- Show absolute line numbers
vim.opt.relativenumber = true     -- Show relative line numbers
vim.opt.mouse = "a"               -- Disable mouse support
vim.opt.showmode = true           -- Show current mode (e.g., -- INSERT --)
vim.opt.breakindent = true        -- Maintain indent when wrapping lines
vim.opt.undofile = true           -- Persist undo history across sessions
vim.opt.ignorecase = true         -- Ignore case in search patterns
vim.opt.smartcase = true          -- Make search case-sensitive if uppercase is used
vim.opt.signcolumn = "yes"        -- Always show the sign column
vim.opt.updatetime = 250          -- Delay (ms) before triggering swap write and CursorHold
vim.opt.timeoutlen = 1000         -- Time (ms) to wait for mapped sequence to complete
vim.opt.splitright = true         -- Open vertical splits to the right
vim.opt.splitbelow = true         -- Open horizontal splits below
vim.opt.inccommand = "split"      -- Show live preview of substitute in a split
vim.opt.cursorline = true         -- Highlight the current line
vim.opt.scrolloff = 5             -- Keep 5 lines visible above/below cursor
vim.opt.hlsearch = true           -- Highlight all search matches
vim.opt.fixeol = false            -- Do not enforce newline at end of file
vim.opt.colorcolumn = "120"       -- Highlight column 120 as a guide
vim.opt.list = true               -- Show invisible characters
vim.opt.clipboard = "unnamedplus" -- Share clipboard with OS
vim.opt.listchars = {             -- Define symbols for invisibles
    tab = '» ',
    trail = '·',
    nbsp = '␣',
}

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader>m", function()
    if vim.o.mouse == "" then
        vim.o.mouse = "a"
    else
        vim.o.mouse = ""
    end
end, { desc = "Toggle mouse" })

-- Bootstrap lazy.nvim: compute install path inside Neovim's data directory,
-- clone the plugin if it is not already installed, then prepend it to the
-- runtimepath so it can manage and load plugins during startup.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "catppuccin/nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("catppuccin-mocha")
            vim.cmd.hi("Comment gui=none")
        end,
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = false,
                window = {
                    width = 30,
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
        },
        opts = {
            diagnostics = { virtual_text = false, underline = false },
            servers = {
                -- gopls = {},
                -- rust_analyzer = {},
                lua_ls = {},
            },
        },
        config = function(_, opts)
            vim.diagnostic.config(opts.diagnostics)
            vim.api.nvim_create_autocmd("DiagnosticChanged", {
                callback = function()
                    vim.diagnostic.setqflist({ open = false })
                end,
            })

            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            for server, server_opts in pairs(opts.servers) do
                server_opts.capabilities = capabilities
                server_opts.on_attach = function(_, bufnr)
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "Find references" })
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover info" })
                    vim.keymap.set("n", "<leader>d", function()
                        vim.diagnostic.open_float(nil, { focusable = true })
                    end, { buffer = bufnr, desc = "Show diagnostic" })
                end
                vim.lsp.config(server, server_opts)
                vim.lsp.enable(server)
            end
        end,
    },
    -- {
    --     "hrsh7th/nvim-cmp",
    --     dependencies = {
    --         "hrsh7th/cmp-nvim-lsp",
    --     },
    --     config = function()
    --         local cmp = require("cmp")
    --         cmp.setup({
    --             mapping = {
    --                 ["<C-n>"]     = cmp.mapping.select_next_item(),
    --                 ["<C-p>"]     = cmp.mapping.select_prev_item(),
    --                 ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    --                 ["<C-Space>"] = cmp.mapping.complete(),
    --             },
    --             sources = {
    --                 { name = "nvim_lsp" },
    --             },
    --             completion = {
    --                 autocomplete = false,
    --             },
    --         })
    --     end,
    -- },
    --      {
    --          "echasnovski/mini.pick",
    --          version = false,
    --          config = function()
    --              require("mini.pick").setup({
    --                  window = {
    --                      config = {
    --                          anchor = 'NW',
    --                          col = math.floor(vim.o.columns * 0.05),
    --                          width = math.floor(vim.o.columns * 0.90),
    --                          row = math.floor(vim.o.lines * 0.05),
    --                          height = math.floor(vim.o.lines * 0.80),
    --                      },
    --                  },
    --              })
    --              vim.keymap.set("n", "<leader>ff", MiniPick.builtin.files, { desc = "Find files" })
    --              vim.keymap.set("n", "<leader>fg", MiniPick.builtin.grep_live, { desc = "Live grep" })
    --          end,
    --      },
})
