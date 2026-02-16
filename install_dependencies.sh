#!/bin/bash
#==============================================================================
# Neovim 配置依赖自动安装脚本
#==============================================================================
# 此脚本自动安装 LazyVim 配置所需的所有依赖
# 使用方法: ./install_dependencies.sh

set -e  # 遇到错误立即退出

echo "========================================"
echo "开始安装 Neovim 配置依赖..."
echo "========================================"

#------------------------------------------------------------------------------
# 检查系统
#------------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "检测到 macOS 系统"
    PKG_MANAGER="brew"
elif command -v apt-get &> /dev/null; then
    echo "检测到 Debian/Ubuntu 系统"
    PKG_MANAGER="apt"
else
    echo "不支持的系统，请手动安装依赖"
    exit 1
fi

#------------------------------------------------------------------------------
# 检查 Homebrew (macOS)
#------------------------------------------------------------------------------
if [[ "$PKG_MANAGER" == "brew" ]] && ! command -v brew &> /dev/null; then
    echo "错误: 未找到 Homebrew，请先安装:"
    echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

#------------------------------------------------------------------------------
# 安装 Node.js 和 npm
#------------------------------------------------------------------------------
echo ""
echo "----------------------------------------"
echo "安装 Node.js 依赖..."
echo "----------------------------------------"

if ! command -v node &> /dev/null; then
    echo "安装 Node.js..."
    if [[ "$PKG_MANAGER" == "brew" ]]; then
        brew install node
    else
        sudo apt-get install -y nodejs npm
    fi
else
    echo "Node.js 已安装: $(node --version)"
fi

# 安装 npm 全局包
echo "安装 npm 全局语言服务器..."
npm install -g \
    typescript \
    typescript-language-server \
    vscode-langservers-extracted \
    @tailwindcss/language-server \
    @fsouza/prettierd \
    eslint_d \
    eslint \
    prettier \
    prettier-plugin-tailwindcss \
    typescript-eslint \
    dockerfile-language-server-nodejs

echo "✓ npm 依赖安装完成"

#------------------------------------------------------------------------------
# 安装 Python 工具
#------------------------------------------------------------------------------
echo ""
echo "----------------------------------------"
echo "安装 Python 工具..."
echo "----------------------------------------"

# macOS 使用 Homebrew 安装
if [[ "$PKG_MANAGER" == "brew" ]]; then
    brew install pyright ruff black || true
    echo "✓ Python 工具安装完成"
else
    # Linux 使用 pip
    if command -v pip3 &> /dev/null; then
        pip3 install --user -U pyright ruff black || true
        echo "✓ Python 工具安装完成"
    else
        echo "警告: 未找到 pip3，跳过 Python 工具安装"
    fi
fi

#------------------------------------------------------------------------------
# 安装其他工具
#------------------------------------------------------------------------------
echo ""
echo "----------------------------------------"
echo "安装其他工具..."
echo "----------------------------------------"

if [[ "$PKG_MANAGER" == "brew" ]]; then
    # macOS
    brew install \
        hadolint \
        shfmt \
        fd \
        ripgrep \
        fzf \
        tree-sitter \
        lazygit || true
else
    # Linux
    sudo apt-get install -y \
        hadolint \
        shellcheck \
        shfmt \
        fd-find \
        ripgrep \
        fzf \
        tree-sitter \
        lazygit || true
fi

echo "✓ 其他工具安装完成"

#------------------------------------------------------------------------------
# 安装 Neovim 插件
#------------------------------------------------------------------------------
echo ""
echo "----------------------------------------"
echo "安装 Neovim 插件..."
echo "----------------------------------------"

if ! command -v nvim &> /dev/null; then
    echo "错误: 未找到 Neovim，请先安装 Neovim"
    exit 1
fi

# 同步插件并安装 Mason 工具
nvim --headless "+Lazy! sync" +qa

echo "✓ Neovim 插件安装完成"

#------------------------------------------------------------------------------
# 完成
#------------------------------------------------------------------------------
echo ""
echo "========================================"
echo "所有依赖安装完成！"
echo "========================================"
echo ""
echo "接下来:"
echo "1. 重启 Neovim"
echo "2. 打开任意文件，LSP 服务器会自动启动"
echo "3. 如需手动安装其他工具，运行 :Mason"
echo ""
