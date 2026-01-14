--==============================================================================
-- LazyVim 配置入口文件
--==============================================================================
-- 本文件是 LazyVim 的主入口，负责引导加载 lazy.nvim 插件管理器
--
-- 文件加载顺序：
-- 1. 首先加载 lua/config/lazy.lua（插件管理器配置）
-- 2. lazy.nvim 会自动加载 lua/config/options.lua（基础选项配置）
-- 3. 然后加载 lua/config/keymaps.lua（键位映射配置）
-- 4. 最后加载 lua/config/autocmds.lua（自动命令配置）
-- 5. 加载 lua/plugins/ 目录下的所有插件配置文件

-- 引导加载 lazy.nvim 插件管理器和 LazyVim 核心配置
require("config.lazy")
