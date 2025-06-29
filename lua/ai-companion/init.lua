-- AI 工作夥伴插件 - 主入口模塊
local M = {}

-- 默認配置
M.defaults = {
  workspace_dir = "~/workspace",
  ai_config = {
    embedding_model = "openai:text-embedding-3-small",
    generation_model = "openai:o3-mini-high",
    temperature = 0.7,
  },
  git_integration = {
    enabled = true,
    auto_hooks = true,
  },
  ui = {
    chat_height = 15,
    auto_focus = true,
  },
}

-- 主設置函數
function M.setup(opts)
  -- 1. 合併用戶配置
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- 2. 驗證配置
  M.validate_config()

  -- 3. 初始化子模塊
  require("ai-companion.core.ai").setup(M.config.ai_config)
  require("ai-companion.utils.aichat").setup_config(M.config)

  -- 4. 設置快捷鍵
  M.setup_keymaps()

  -- 5. 設置 Git 整合
  if M.config.git_integration.enabled then
    require("ai-companion.utils.git").setup(M.config.workspace_dir)
  end

  -- 6. 創建用戶命令
  M.create_user_commands()

  -- 7. 創建輔助工具命令
  require("ai-companion.utils.git").create_commands()
  require("ai-companion.utils.aichat").create_commands()
end

-- 快捷鍵設置
function M.setup_keymaps()
  vim.keymap.set("n", "<leader><space>", function()
    require("ai-companion.core.chat").start_conversation()
  end, { desc = "與 AI 對話" })

  -- 可選的傳統搜索快捷鍵
  vim.keymap.set("n", "<leader>fn", function()
    require("fzf-lua").files({ cwd = vim.fn.expand(M.config.workspace_dir) })
  end, { desc = "搜索工作文件" })

  vim.keymap.set("n", "<leader>sn", function()
    require("fzf-lua").live_grep({ cwd = vim.fn.expand(M.config.workspace_dir) })
  end, { desc = "搜索工作內容" })
end

-- 配置驗證
function M.validate_config()
  -- 檢查工作目錄
  local workspace = vim.fn.expand(M.config.workspace_dir)
  if vim.fn.isdirectory(workspace) == 0 then
    vim.fn.mkdir(workspace, "p")
  end

  -- 檢查 aichat 可用性
  if vim.fn.executable("aichat") == 0 then
    vim.notify("Warning: aichat not found, please install it first", vim.log.levels.WARN)
  end
end

-- 用戶命令
function M.create_user_commands()
  vim.api.nvim_create_user_command("AiChat", function()
    require("ai-companion.core.chat").start_conversation()
  end, { desc = "開始 AI 對話" })

  vim.api.nvim_create_user_command("AiStatus", function()
    require("ai-companion.core.ai").show_status()
  end, { desc = "顯示 AI 狀態" })
end

return M
