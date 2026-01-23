local M = {}

-- 配置文件路径，存储在 Neovim 的数据目录下
local config_file_path = vim.fn.stdpath("data") .. "/runner_file_configs.json"
local configs = {}

-- 项目配置的命名空间
local PROJECT_KEY_PREFIX = "project:"

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

--- 获取当前项目的根目录
--- @return string|nil 项目根目录或 nil
function M.get_project_root()
    -- 尝试使用 git 根目录
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
    if git_root and git_root ~= "" then
        return git_root
    end

    -- 回退到当前文件的目录
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file and current_file ~= "" then
        return vim.fn.fnamemodify(current_file, ":h")
    end

    return nil
end

--- 设置项目运行命令（完整命令）
--- @param project_root string 项目根目录
--- @param command string 完整的运行命令
function M.set_project_runner(project_root, command)
    local trimmed_command = command:gsub("^%s*(.-)%s*$", "%1")
    configs[PROJECT_KEY_PREFIX .. project_root] = trimmed_command
    write_config()
end

--- 获取项目运行命令
--- @param project_root string 项目根目录
--- @return string|nil 运行命令或 nil
function M.get_project_runner(project_root)
    return configs[PROJECT_KEY_PREFIX .. project_root]
end

--- 清除项目运行命令
--- @param project_root string 项目根目录
function M.clear_project_runner(project_root)
    configs[PROJECT_KEY_PREFIX .. project_root] = nil
    write_config()
end

--- 获取当前项目的运行命令
--- @return string|nil 运行命令或 nil
function M.get_current_project_runner()
    local root = M.get_project_root()
    if root then
        return M.get_project_runner(root)
    end
    return nil
end

-- 浏览器 URL 配置的命名空间
local BROWSER_PROJECT_KEY_PREFIX = "browser_project:"
local BROWSER_FILE_KEY_PREFIX = "browser_file:"

--- 设置项目浏览器 URL
--- @param project_root string 项目根目录
--- @param url string 浏览器 URL
function M.set_project_browser(project_root, url)
    local trimmed_url = url:gsub("^%s*(.-)%s*$", "%1")
    configs[BROWSER_PROJECT_KEY_PREFIX .. project_root] = trimmed_url
    write_config()
end

--- 获取项目浏览器 URL
--- @param project_root string 项目根目录
--- @return string|nil URL 或 nil
function M.get_project_browser(project_root)
    return configs[BROWSER_PROJECT_KEY_PREFIX .. project_root]
end

--- 清除项目浏览器 URL
--- @param project_root string 项目根目录
function M.clear_project_browser(project_root)
    configs[BROWSER_PROJECT_KEY_PREFIX .. project_root] = nil
    write_config()
end

--- 获取当前项目的浏览器 URL
--- @return string|nil URL 或 nil
function M.get_current_project_browser()
    local root = M.get_project_root()
    if root then
        return M.get_project_browser(root)
    end
    return nil
end

--- 设置文件浏览器 URL
--- @param file_path string 文件路径
--- @param url string 浏览器 URL
function M.set_file_browser(file_path, url)
    local trimmed_url = url:gsub("^%s*(.-)%s*$", "%1")
    configs[BROWSER_FILE_KEY_PREFIX .. file_path] = trimmed_url
    write_config()
end

--- 获取文件浏览器 URL
--- @param file_path string 文件路径
--- @return string|nil URL 或 nil
function M.get_file_browser(file_path)
    return configs[BROWSER_FILE_KEY_PREFIX .. file_path]
end

--- 清除文件浏览器 URL
--- @param file_path string 文件路径
function M.clear_file_browser(file_path)
    configs[BROWSER_FILE_KEY_PREFIX .. file_path] = nil
    write_config()
end

-- 在模块加载时读取一次配置
read_config()

return M
