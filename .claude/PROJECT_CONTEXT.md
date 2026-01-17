# Neovim 配置项目

## 项目概述

这是基于 LazyVim 的个人 Neovim 配置。

## 关键配置

### 文件树

- 使用 **snacks.nvim 的 Explorer**（不是 neo-tree）
- 配置文件：`lua/plugins/explorer.lua`
- 启动时自动打开

### 中文化

- Explorer 操作提示已中文化（复制、粘贴、新建、删除等）

## 开发规范

### 插件管理

- 使用 Lazy.nvim 管理插件
- 插件配置放在 `lua/plugins/` 目录

### 代码风格

- Lua 文件使用 tab 缩进
- 不要使用 emoji（除非用户明确要求）
- 保持配置简洁，避免过度工程化

## 禁止事项

- 不要自动创建 Git 提交（除非用户明确要求）
- 不要修改核心插件文件（只修改用户配置）
- 不要生成无用的注释或文档

## 注意事项

- 所有自定义配置应该在 `lua/plugins/` 目录
- 避免与 LazyVim 默认配置冲突

严格遵守Lazyvim的官方规范和配置文件规范，严格遵守Lazyvim的官方配置文件目录结构，严格遵守
一切配置以性能优先
