vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.zig_fmt_autosave = false -- Disable builtin zig autoformatter

-- Disable line wrapping
vim.opt.wrap = false

-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Number of spaces a <Tab> counts for
vim.opt.tabstop = 4

-- Number of spaces a <Tab> counts for while editing
vim.opt.softtabstop = 4

-- Number of spaces to use for each step of (auto)indent
vim.opt.shiftwidth = 4

-- Show absolute line numbers
vim.opt.number = true

-- Show relative line numbers
vim.opt.relativenumber = true

-- Disable mouse support
vim.opt.mouse = "a"

-- Show current mode (e.g., INSERT)
vim.opt.showmode = true

-- Maintain indent when wrapping lines
vim.opt.breakindent = true

-- Persist undo history across sessions
vim.opt.undofile = true

-- Ignore case in search patterns
vim.opt.ignorecase = true

-- Make search case-sensitive if uppercase is used
vim.opt.smartcase = true

-- Always show the sign column
vim.opt.signcolumn = "yes"

-- Delay (ms) before triggering swap write and CursorHold
vim.opt.updatetime = 250

-- Time (ms) to wait for mapped sequence to complete
vim.opt.timeoutlen = 1000

-- Open vertical splits to the right
vim.opt.splitright = true

-- Open horizontal splits below
vim.opt.splitbelow = true

-- Show live preview of substitute in a split
vim.opt.inccommand = "split"

-- Highlight the current line
vim.opt.cursorline = true

-- Keep 5 lines visible above/below cursor
vim.opt.scrolloff = 5

-- Highlight all search matches
vim.opt.hlsearch = true

-- Do not enforce newline at end of file
vim.opt.fixeol = false

-- Highlight column 120 as a guide
vim.opt.colorcolumn = "120"

-- Show invisible characters
vim.opt.list = true

-- Share clipboard with OS
vim.opt.clipboard = "unnamedplus"

-- Define symbols for invisibles
vim.opt.listchars = {
	tab = "» ",
	trail = "·",
	nbsp = "␣",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "lua", "go" },
	callback = function()
		vim.opt_local.expandtab = false
		vim.opt_local.listchars:append({ tab = "  " })
	end,
})

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
		"folke/which-key.nvim",
		event = "VimEnter",
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

			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		opts = {
			diagnostics = { virtual_text = false, underline = false },
			servers = {
				gopls = {},
				rust_analyzer = {},
				pyright = {},
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
						},
					},
				},
				ts_ls = {},
				eslint = {
					on_attach = function(client, bufnr)
						-- Disable eslint formatting; prettier (conform.nvim) owns that
						client.server_capabilities.documentFormattingProvider = false
						vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
							client:request_sync("workspace/executeCommand", {
								command = "eslint.applyAllFixes",
								arguments = { {
									uri = vim.uri_from_bufnr(bufnr),
									version = vim.lsp.util.buf_versions[bufnr],
								} },
							}, nil, bufnr)
						end, {})
						vim.api.nvim_create_autocmd("BufWritePre", {
							buffer = bufnr,
							command = "LspEslintFixAll",
						})
					end,
				},
			},
		},
		config = function(_, opts)
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(opts.servers),
			})
			require("mason-tool-installer").setup({
				ensure_installed = { "prettierd" },
			})

			vim.diagnostic.config(opts.diagnostics)
			vim.api.nvim_create_autocmd("DiagnosticChanged", {
				callback = function()
					vim.diagnostic.setqflist({ open = false })
				end,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if not client then
						return
					end

					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
					end

					map("<leader>ld", vim.lsp.buf.definition, "Go to definition")
					map("<leader>lr", function()
						require("mini.extra").pickers.lsp({ scope = "references" })
					end, "Find references")
					map("<leader>ln", vim.lsp.buf.rename, "Rename")
					map("<leader>la", vim.lsp.buf.code_action, "Code action")
					map("<leader>lh", vim.lsp.buf.hover, "Hover info")
					map("<leader>li", vim.lsp.buf.implementation, "Go to implementation")
					map("<leader>le", function()
						vim.diagnostic.open_float(nil, { focusable = true })
					end, "Show diagnostic")
				end,
			})

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			for server, server_opts in pairs(opts.servers) do
				server_opts.capabilities = capabilities
				vim.lsp.config[server] = server_opts
				vim.lsp.enable(server)
			end
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		opts = {
			format_on_save = {
				lsp_fallback = true,
				timeout_ms = 500,
			},
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		},
		},
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				mapping = {
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
				},
				sources = {
					{ name = "nvim_lsp" },
				},
				completion = {
					-- disable completion because we use a keymap to trigger it
					autocomplete = false,
				},
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			ensure_installed = { "lua", "go", "rust", "vim", "vimdoc" },
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		},
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"echasnovski/mini.pick",
		},
		config = function()
			local neogit = require("neogit")
			neogit.setup({})
			vim.keymap.set("n", "<leader>gg", neogit.open, { desc = "Open Neogit" })
		end,
	},
	{
		"echasnovski/mini.diff",
		version = false,
		config = function()
			local diff = require("mini.diff")
			diff.setup({
				view = {
					style = "sign",
					signs = { add = "┃", change = "┃", delete = "_" },
				},
			})

			vim.keymap.set("n", "<leader>gd", diff.toggle_overlay, { desc = "Toggle diff overlay" })
		end,
	},
	{
		"echasnovski/mini-git",
		version = false,
		config = function()
			require("mini.git").setup()

			vim.keymap.set("n", "<leader>gc", function()
				require("mini.extra").pickers.git_commits()
			end, { desc = "Browse Git commits" })

			vim.keymap.set("n", "<leader>gh", function()
				local path = vim.fn.expand("%")
				if path == "" then
					vim.notify("No file to show history for")
					return
				end
				-- Use mini.git's :Git command to show log for current file
				vim.cmd("Git log -- " .. path)
			end, { desc = "Show file history" })
		end,
	},
	{
		"echasnovski/mini.extra",
		version = false,
	},
	{
		"echasnovski/mini.pick",
		version = false,
		config = function()
			local pick = require("mini.pick")

			pick.setup({
				window = {
					config = {
						width = math.floor(vim.o.columns * 1.0),
						height = math.floor(vim.o.lines * 1.0),
						row = math.floor(vim.o.lines * 0.0),
						col = math.floor(vim.o.columns * 0.0),
					},
				},
			})

			vim.keymap.set("n", "<leader>ff", pick.builtin.files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", pick.builtin.grep_live, { desc = "Live grep" })
		end,
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"williamboman/mason.nvim",
			"jay-babu/mason-nvim-dap.nvim",
			"leoluz/nvim-dap-go",
			"mfussenegger/nvim-dap-python",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			require("mason-nvim-dap").setup({
				automatic_installation = true,
				handlers = {},
				ensure_installed = {
					"delve",
					"codelldb",
					"python",
				},
			})

			-- Basic DAP UI setup
			dapui.setup()

			-- Manual setup for codelldb to ensure correct path
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
					args = { "--port", "${port}" },
				},
			}

			-- Open UI automatically when debugging starts
			dap.listeners.after.event_initialized["dapui_config"] = dapui.open

			-- Go setup
			require("dap-go").setup()

			-- Python setup
			local python_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
			require("dap-python").setup(python_path)

			-- Rust setup (codelldb) via Mason
			local last_rust_exe = nil
			dap.configurations.rust = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",
					program = function()
						return coroutine.create(function(dap_run_co)
							local cwd = vim.fn.getcwd()
							local cmd = "cargo metadata --no-deps --format-version 1"
							local handle = io.popen(cmd)
							local result = ""
							if handle then
								result = handle:read("*a")
								handle:close()
							end

							local executables = {}
							local target_dir = cwd .. "/target"

							if result and result ~= "" then
								local ok, parsed = pcall(vim.json.decode, result)
								if ok and parsed then
									target_dir = parsed.target_directory
									if parsed.packages then
										for _, package in ipairs(parsed.packages) do
											for _, target in ipairs(package.targets) do
												if vim.tbl_contains(target.kind, "bin") then
													table.insert(executables, target_dir .. "/debug/" .. target.name)
												end
											end
										end
									end
								end
							end

							if #executables == 0 then
								vim.ui.input({
									prompt = "Path to executable: ",
									default = target_dir .. "/debug/",
									completion = "file",
								}, function(input)
									coroutine.resume(dap_run_co, input)
								end)
							else
								table.sort(executables, function(a, b)
									if a == last_rust_exe then
										return true
									end
									if b == last_rust_exe then
										return false
									end
									return a < b
								end)

								vim.ui.select(executables, {
									prompt = "Select executable to debug:",
									format_item = function(item)
										if item == last_rust_exe then
											return item .. " (Last Used)"
										end
										return item
									end,
								}, function(choice)
									if choice then
										last_rust_exe = choice
										coroutine.resume(dap_run_co, choice)
									else
										coroutine.resume(dap_run_co, nil)
									end
								end)
							end
						end)
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}

			-- Keymaps
			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
			vim.keymap.set("n", "<F1>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F2>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F3>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>dB", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: Set Breakpoint with Condition" })
			vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
		end,
	},
})
