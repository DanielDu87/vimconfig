local M = {}

-- 配置文件路径，存储在 Neovim 的数据目录下
local config_file_path = vim.fn.stdpath("data") .. "/runner_file_configs.json"
local configs = {}

-- 读取配置文件
local function read_config()
    local file = io.open(config_file_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if content and content ~= "" then
            local ok, decoded = pcall(vim.fn.json_decode, content)
            if ok and type(decoded) == "table" then
                configs = decoded
            else
                vim.notify("Runner配置: 解析JSON文件失败，将使用空配置。", vim.log.levels.WARN)
                configs = {}
            end
        end
    end
end

-- 写入配置文件
local function write_config()
    local ok, encoded = pcall(vim.fn.json_encode, configs)
    if ok then
        local file = io.open(config_file_path, "w")
        if file then
            file:write(encoded)
            file:close()
        else
            vim.notify("Runner配置: 无法写入JSON文件: " .. config_file_path, vim.log.levels.ERROR)
        end
    else
        vim.notify("Runner配置: 编码JSON数据失败。", vim.log.levels.ERROR)
    end
end

--- 设置特定文件的运行命令
--- @param file_path string 文件的绝对路径
--- @param command string 运行命令
function M.set_file_runner(file_path, command)
    -- 清除命令字符串两端的空白字符
    local trimmed_command = command:gsub("^%s*(.-)%s*$", "%1")
    configs[file_path] = trimmed_command
    write_config()
end

--- 获取特定文件的运行命令
--- @param file_path string 文件的绝对路径
--- @return string|nil 运行命令或 nil (如果未设置)
function M.get_file_runner(file_path)
    return configs[file_path]
end

--- 清除特定文件的运行命令
--- @param file_path string 文件的绝对路径
function M.clear_file_runner(file_path)
    configs[file_path] = nil
    write_config()
end

-- 在模块加载时读取一次配置
read_config()

return M
