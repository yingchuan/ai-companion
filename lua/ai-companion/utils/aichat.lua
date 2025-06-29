local M = {}

-- 配置路徑
M.config_paths = {
  config_dir = vim.fn.expand("~/.config/aichat"),
  config_file = vim.fn.expand("~/.config/aichat/config.yaml"),
  roles_file = vim.fn.expand("~/.config/aichat/roles.yaml"),
}

-- 設置 aichat 配置
function M.setup_config(plugin_config)
  M.plugin_config = plugin_config

  -- 確保配置目錄存在
  vim.fn.mkdir(M.config_paths.config_dir, "p")

  -- 設置主配置
  M.setup_main_config()

  -- 設置角色配置
  M.setup_roles_config()

  vim.notify("✅ aichat 配置已更新", vim.log.levels.INFO)
end

-- 設置主配置文件
function M.setup_main_config()
  local config_content = M.generate_main_config()

  -- 備份現有配置
  if vim.fn.filereadable(M.config_paths.config_file) == 1 then
    local backup_path = M.config_paths.config_file .. ".backup." .. os.date("%Y%m%d_%H%M%S")
    vim.fn.rename(M.config_paths.config_file, backup_path)
  end

  -- 寫入新配置
  vim.fn.writefile(vim.split(config_content, '\n'), M.config_paths.config_file)
end

-- 生成主配置內容
function M.generate_main_config()
  local ai_config = M.plugin_config.ai_config

  return string.format([[
# AI Companion - Auto-generated aichat configuration

model: %s
save: true
save_session: true
highlight: true
light_theme: false
temperature: %s

# 客戶端配置 - 必需配置
clients:
  # OpenAI 配置
  - type: openai
    api_key: # 請設置環境變量 OPENAI_API_KEY
    models:
      - name: gpt-3.5-turbo
        max_tokens: 4096
      - name: gpt-4
        max_tokens: 8192
      - name: gpt-4-turbo
        max_tokens: 128000
      - name: o1-mini-high
        max_tokens: 65536
      - name: text-embedding-3-small
        type: embedding
      - name: text-embedding-3-large
        type: embedding

  # Anthropic 配置
  - type: claude
    api_key: # 請設置環境變量 ANTHROPIC_API_KEY
    models:
      - name: claude-3-5-sonnet-20241022
        max_tokens: 8192
      - name: claude-3-5-haiku-20241022
        max_tokens: 8192
      - name: claude-sonnet-4-20250514
        max_tokens: 8192

# RAG 配置
rag_embedding_model: %s
rag_top_k: 4
rag_chunk_size: 1000
rag_chunk_overlap: 200

# 會話配置
compress_threshold: 4000
summarize_prompt: |
  請簡潔地總結上述對話的關鍵要點，保留重要的技術細節和決議。

# 文檔加載器
document_loaders:
  md: 'cat $1'
  txt: 'cat $1'
  org: 'cat $1'

# 角色配置文件
roles_file: %s
]],
  ai_config.generation_model,
  ai_config.temperature,
  ai_config.embedding_model,
  M.config_paths.roles_file
)
end

-- 設置角色配置
function M.setup_roles_config()
  local roles_content = M.generate_roles_config()
  vim.fn.writefile(vim.split(roles_content, '\n'), M.config_paths.roles_file)
end

-- 生成角色配置
function M.generate_roles_config()
  return [[
# AI Companion 工作助手角色

- name: companion
  prompt: |
    你是用戶的個人 AI 工作助手 FRIDAY。

    核心職責:
    1. 理解和處理用戶的工作需求（任務、會議、筆記、討論）
    2. 基於用戶的筆記和歷史提供個性化建議
    3. 主動發現問題並提供解決方案
    4. 保持專業、友好、高效的協助風格

    回應原則:
    - 確認理解用戶需求並提供具體幫助
    - 基於已有信息提供個性化建議
    - 主動詢問是否需要進一步協助
    - 保持 FRIDAY 助手的專業語調

    請始終以用戶的工作效率和成功為目標。

- name: analyst
  prompt: |
    你是數據分析和洞察專家。

    專長領域:
    - 工作效率分析
    - 趨勢識別和模式發現
    - 性能評估和改進建議
    - 風險識別和緩解策略

    分析方法:
    - 基於數據提供客觀分析
    - 識別關鍵指標和趨勢
    - 提供可操作的改進建議
    - 預測潛在問題和機會

- name: organizer
  prompt: |
    你是內容整理和知識管理專家。

    核心能力:
    - 信息結構化和分類
    - 知識關聯和整合
    - 內容總結和提煉
    - 標籤和索引優化

    整理原則:
    - 保持信息的完整性和準確性
    - 建立清晰的層次結構
    - 發現內容間的關聯
    - 便於後續查找和使用

- name: planner
  prompt: |
    你是項目規劃和任務管理專家。

    專業技能:
    - 項目分解和時間估算
    - 資源分配和優先級排序
    - 風險評估和應對策略
    - 進度跟蹤和調整建議

    規劃方法:
    - 基於歷史數據和經驗
    - 考慮資源限制和約束
    - 提供現實可行的計劃
    - 建立有效的監控機制
]]
end

-- 驗證配置
function M.validate_config()
  local issues = {}

  -- 檢查配置文件是否存在
  if vim.fn.filereadable(M.config_paths.config_file) == 0 then
    table.insert(issues, "主配置文件不存在")
  end

  if vim.fn.filereadable(M.config_paths.roles_file) == 0 then
    table.insert(issues, "角色配置文件不存在")
  end

  -- 檢查 aichat 可執行性
  if vim.fn.executable('aichat') == 0 then
    table.insert(issues, "aichat 命令不可用")
  end

  return issues
end

-- 測試配置
function M.test_config()
  local issues = M.validate_config()

  if #issues > 0 then
    vim.notify("❌ 配置問題: " .. table.concat(issues, ", "), vim.log.levels.ERROR)
    return false
  end

  -- 檢查環境變量
  local env_issues = {}
  if not vim.env.OPENAI_API_KEY and not vim.env.ANTHROPIC_API_KEY then
    table.insert(env_issues, "未設置 API 密鑰環境變量")
  end

  -- 測試 aichat 列出模型
  local list_models_cmd = 'aichat --list-models 2>&1'
  local models_result = vim.fn.system(list_models_cmd)

  if vim.v.shell_error ~= 0 or models_result:match("^%s*$") then
    vim.notify("❌ aichat 無法列出模型，可能配置有誤:\n" .. models_result, vim.log.levels.ERROR)
    if #env_issues > 0 then
      vim.notify("💡 提示: " .. table.concat(env_issues, ", "), vim.log.levels.WARN)
    end
    return false
  end

  -- 測試 aichat 基本功能
  local test_cmd = 'aichat --role companion "簡單測試連接" 2>&1'
  local result = vim.fn.system(test_cmd)

  if vim.v.shell_error == 0 then
    vim.notify("✅ aichat 配置測試通過\n可用模型:\n" .. models_result, vim.log.levels.INFO)
    return true
  else
    vim.notify("❌ aichat 測試失敗: " .. result, vim.log.levels.ERROR)
    if #env_issues > 0 then
      vim.notify("💡 提示: " .. table.concat(env_issues, ", "), vim.log.levels.WARN)
    end
    return false
  end
end

-- 顯示配置狀態
function M.show_config_status()
  local issues = M.validate_config()
  local status = #issues == 0 and "✅ 正常" or "❌ 有問題"

  local report = string.format([[
🤖 **aichat 配置狀態**

狀態: %s
配置目錄: %s
主配置: %s
角色配置: %s
可執行: %s

%s
]],
    status,
    M.config_paths.config_dir,
    vim.fn.filereadable(M.config_paths.config_file) == 1 and "✅" or "❌",
    vim.fn.filereadable(M.config_paths.roles_file) == 1 and "✅" or "❌",
    vim.fn.executable('aichat') == 1 and "✅" or "❌",
    #issues > 0 and ("問題: " .. table.concat(issues, ", ")) or "所有檢查通過"
  )

  vim.notify(report, vim.log.levels.INFO)
end

-- 重置配置
function M.reset_config()
  local choice = vim.fn.confirm(
    "確定要重置 aichat 配置嗎？這將覆蓋現有配置。",
    "&是\n&否", 2
  )

  if choice == 1 then
    M.setup_config(M.plugin_config)
    vim.notify("✅ aichat 配置已重置", vim.log.levels.INFO)
  end
end

-- 創建用戶命令
function M.create_commands()
  vim.api.nvim_create_user_command('AiConfigStatus', function()
    M.show_config_status()
  end, { desc = "顯示 aichat 配置狀態" })

  vim.api.nvim_create_user_command('AiConfigTest', function()
    M.test_config()
  end, { desc = "測試 aichat 配置" })

  vim.api.nvim_create_user_command('AiConfigReset', function()
    M.reset_config()
  end, { desc = "重置 aichat 配置" })
end

return M
