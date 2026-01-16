--==============================================================================
-- lazy.nvim 插件管理器配置
--==============================================================================
-- 本文件负责配置 lazy.nvim 插件管理器
--
-- lazy.nvim 是现代 Neovim 插件管理器，具有以下特点：
-- - 快速：异步加载，启动速度快
-- - 易用：自动管理插件依赖、更新、清理
-- - 灵活：支持懒加载、条件加载、事件触发加载
-- - 可视化：提供 :Lazy 命令查看和管理插件

-- 禁用 LazyVim 的导入顺序严格检查
-- 说明：我们的配置符合规范（lazyvim.plugins -> extras -> 自定义插件）
-- 但 LazyVim 的检查器无法识别我们使用 extras.lua 文件来组织 extras
-- 实际加载顺序是正确的，所以禁用此检查
vim.g.lazyvim_check_order = false

-- 设置 lazy.nvim 的安装路径
-- 路径：~/.local/share/nvim/lazy/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

--==============================================================================
-- 自动安装 lazy.nvim
--==============================================================================
-- 检查 lazy.nvim 是否已安装，如果未安装则自动克隆
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	-- lazy.nvim 的 GitHub 仓库地址
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	-- 使用 git 克隆仓库（使用 --filter=blob:none 减少下载大小）
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	-- 如果克隆失败，显示错误信息并退出
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end

--==============================================================================
-- 将 lazy.nvim 添加到运行时路径的最前面
--==============================================================================
-- 这确保 Neovim 优先使用 lazy.nvim，而不是可能存在的其他插件管理器
vim.opt.rtp:prepend(lazypath)

--==============================================================================
-- lazy.nvim 配置
--==============================================================================
require("lazy").setup({
	-- 插件规范列表
	spec = {
		-- 添加 LazyVim 核心配置并导入其所有插件
		-- LazyVim 预配置了大量常用的 Neovim 插件
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },

		-- 导入你的自定义插件配置（位于 lua/plugins/ 目录）
		-- 在该目录中的任何 .lua 文件都会被自动加载
		--
		-- 注意：为了符合 LazyVim 导入顺序规范，我们在 plugins/ 目录中
		-- 创建了 extras.lua 文件来集中管理所有官方 extras
		{ import = "plugins" },
	},

	-- 默认配置
	defaults = {
		-- 懒加载设置
		-- false: 默认情况下，你的自定义插件会在启动时加载（LazyVim 的插件仍然是懒加载的）
		-- true: 将所有自定义插件也设置为懒加载（需要你在插件配置中正确设置事件、命令等）
		lazy = false,

		-- 版本管理设置
		-- 建议保持 version=false，因为许多支持版本控制的插件的发布版本都已过时
		-- 这可能导致你的 Neovim 安装出现问题
		version = false, -- 始终使用最新的 git 提交
		-- version = "*", -- 如果要使用稳定版本，可以取消注释这行（仅适用于支持语义化版本的插件）
	},

	-- 安装配置
	install = {
		-- 首次安装时尝试设置配色方案
		-- 如果这些配色方案未安装，lazy.nvim 会在启动前自动安装它们
		colorscheme = { "tokyonight", "habamax" },
	},

	-- 更新检查器配置
	checker = {
		-- 定期检查插件更新（默认每周检查一次）
		enabled = true,
		-- 检查到更新时显示通知
		notify = true,
	}, -- automatically check for plugin updates

	-- 性能优化配置
	performance = {
		-- 运行时路径（rtp）优化
		rtp = {
			-- 禁用一些不需要的 Neovim 内置插件
			-- 这些插件通常不需要，禁用它们可以提高启动速度
			disabled_plugins = {
				"gzip",          -- 禁用 gzip 压缩支持
				-- "matchit",     -- 保持启用（提供 % 命令的增强功能）
				-- "matchparen",  -- 保持启用（高亮匹配的括号）
				-- "netrwPlugin", -- 保持启用（内置文件浏览器，LazyVim 使用其他文件浏览器替代）
				"tarPlugin",     -- 禁用 tar 归档文件支持
				"tohtml",        -- 禁用语法高亮导出为 HTML
				"tutor",         -- 禁用 Vim 教程
				"zipPlugin",     -- 禁用 zip 压缩文件支持
			},
		},
	},
})
