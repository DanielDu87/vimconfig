# 终端左边距配置（用于 Neovim 浮窗）
# 只在 Neovim 内的终端中生效

if [ -n "$NVIM" ]; then
    # 直接在提示符前添加 2 个空格
    # 这会影响每次显示提示符
    autoload -Uz add-zsh-hook

    # 在提示符显示前添加左边距
    add-zsh-hook precmd nvim_add_padding

    nvim_add_padding() {
        # 使用 print 在新行开头输出空格
        # printf '\r  \r'
    }

    # 修改 PROMPT 在前面添加空格
    if [[ -n "$PROMPT" && "$PROMPT" != "  "* ]]; then
        PROMPT="  ${PROMPT}"
    fi
fi
