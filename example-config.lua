-- AI 工作夥伴插件 - LazyVim 配置示例
-- 將此文件放在 ~/.config/nvim/lua/plugins/ai-companion.lua

return {
  {
    "yingchuan/ai-companion",
    -- 從 GitHub 倉庫安裝（推薦）
    -- 如果使用本地開發版本，可以使用：
    -- dir = vim.fn.stdpath("config") .. "/lua/ai-companion",

    dependencies = {
      "ibhagwan/fzf-lua",      -- 必需：文件搜索
      "nvim-lua/plenary.nvim", -- 必需：Lua 工具函數
    },

    -- 延遲加載，提高啟動速度
    event = "VeryLazy",

    -- 插件配置
    opts = {
      -- 工作目錄設置
      workspace_dir = "~/workspace", -- 可自定義路徑

      -- AI 模型配置
      ai_config = {
        -- 使用 OpenAI 的 embedding 模型（推薦）
        embedding_model = "openai:text-embedding-3-small",

        -- 主生成模型（可選擇以下之一）
        generation_model = "claude-3-5-sonnet",           -- Anthropic Claude（推薦）
        -- generation_model = "openai:gpt-4",             -- OpenAI GPT-4
        -- generation_model = "openai:gpt-3.5-turbo",     -- OpenAI GPT-3.5（經濟選擇）

        temperature = 0.7,      -- 創意度（0-2）
        max_tokens = 4000,      -- 最大回應長度
        timeout = 30000,        -- 超時時間（毫秒）
      },

      -- Git 整合設置
      git_integration = {
        enabled = true,         -- 啟用 Git 整合
        auto_hooks = true,      -- 自動安裝 Git hooks
        auto_commit = false,    -- 不自動提交（建議手動控制）
      },

      -- 用戶界面設置
      ui = {
        chat_height = 15,       -- 對話窗口高度
        auto_focus = true,      -- 自動聚焦到對話窗口
        show_timestamps = true, -- 顯示時間戳
      },

      -- 文件組織設置
      file_organization = {
        auto_categorize = true,    -- 自動分類
        date_prefix = true,        -- 文件名加日期前綴
        use_subdirectories = true, -- 使用子目錄組織
        max_files_per_dir = 100,   -- 每目錄最大文件數
      },

      -- 搜索配置
      search = {
        fuzzy_threshold = 0.8,  -- 模糊搜索閾值
        max_results = 50,       -- 最大搜索結果數
        include_archived = false, -- 不包含歸檔文件
        search_in_content = true, -- 搜索文件內容
      },

      -- 通知設置
      notifications = {
        enabled = true,
        level = "INFO",         -- DEBUG, INFO, WARN, ERROR
        show_success = true,
        show_errors = true,
        auto_hide_delay = 3000, -- 3秒後自動隱藏
      },

      -- 性能設置
      performance = {
        async_processing = true,      -- 異步處理
        debounce_delay = 500,         -- 防抖延遲（毫秒）
        max_concurrent_requests = 3,  -- 最大並發請求數
        cache_size = 100,             -- 緩存大小
        rag_chunk_size = 1000,        -- RAG 分塊大小
        rag_overlap = 200,            -- RAG 重疊大小
      },
    },

    -- 設置函數
    config = function(_, opts)
      require('ai-companion').setup(opts)

      -- 可選：自定義快捷鍵
      vim.keymap.set('n', '<leader>ac', function()
        require('ai-companion.core.chat').start_conversation()
      end, { desc = "AI 對話" })

      vim.keymap.set('n', '<leader>an', function()
        require('ai-companion.core.chat').start_conversation()
        vim.defer_fn(function()
          vim.fn.feedkeys('i記錄筆記：')
        end, 100)
      end, { desc = "快速筆記" })

      vim.keymap.set('n', '<leader>at', function()
        require('ai-companion.core.chat').start_conversation()
        vim.defer_fn(function()
          vim.fn.feedkeys('i創建任務：')
        end, 100)
      end, { desc = "快速任務" })
    end,
  },

  -- 可選：為不同工作流程創建預設配置
  {
    "yingchuan/ai-companion",
    name = "ai-companion-research", -- 研究工作流
    enabled = false, -- 默認禁用，需要時啟用
    opts = function()
      local defaults = require('ai-companion.config.defaults')
      return vim.tbl_deep_extend("force", defaults.plugin_defaults, {
        workspace_dir = "~/research",
        file_organization = defaults.workflow_templates.research,
        ai_config = {
          generation_model = "claude-3-5-sonnet", -- 研究工作推薦使用 Claude
          temperature = 0.3, -- 更保守的創意度
        },
      })
    end,
  },

  {
    "yingchuan/ai-companion",
    name = "ai-companion-dev", -- 開發工作流
    enabled = false, -- 默認禁用，需要時啟用
    opts = function()
      local defaults = require('ai-companion.config.defaults')
      return vim.tbl_deep_extend("force", defaults.plugin_defaults, {
        workspace_dir = "~/projects/notes",
        file_organization = defaults.workflow_templates.software_development,
        ai_config = {
          generation_model = "openai:gpt-4", -- 開發工作可能更適合 GPT-4
          temperature = 0.5,
        },
      })
    end,
  },
}

--[[
環境變量設置說明：

1. 在 shell 配置文件中添加（~/.bashrc, ~/.zshrc 等）：
   export OPENAI_API_KEY="your-openai-api-key"
   export ANTHROPIC_API_KEY="your-anthropic-api-key"

2. 或在 Neovim 配置中設置：
   vim.env.OPENAI_API_KEY = "your-openai-api-key"
   vim.env.ANTHROPIC_API_KEY = "your-anthropic-api-key"

3. 或使用 .env 文件（不推薦提交到 Git）：
   在 ~/workspace/ 目錄下創建 .env 文件：
   OPENAI_API_KEY=your-openai-api-key
   ANTHROPIC_API_KEY=your-anthropic-api-key

快捷鍵說明：

默認快捷鍵：
- <leader><space>  開始 AI 對話
- <leader>fn       搜索工作文件
- <leader>sn       搜索工作內容

對話窗口內：
- <CR> 或 i       發送消息
- q 或 <Esc>       關閉對話
- <C-l>           清空對話
- <Up>/<Down>     瀏覽歷史

自定義快捷鍵（在 config 函數中添加）：
- <leader>ac      AI 對話
- <leader>an      快速筆記
- <leader>at      快速任務

使用技巧：

1. 自然語言交互：
   - "明天開會討論新功能"
   - "記錄今天學的 Rust 所有權"
   - "週五前完成用戶認證模塊"
   - "這週工作進展如何？"

2. 批量導入現有筆記：
   - 將現有 Markdown 文件複製到 workspace 目錄
   - 運行 :AiRagUpdate 重建知識庫

3. 團隊協作：
   - 使用 Git 倉庫共享 workspace
   - 定期 pull/push 同步團隊知識

4. 備份重要數據：
   - workspace 目錄定期備份
   - 使用 Git 進行版本控制

故障排除：

1. 插件無法加載：
   - 檢查路徑是否正確
   - 確認依賴插件已安裝

2. AI 無法回應：
   - 檢查 API 密鑰設置
   - 運行 :AiConfigTest 測試連接
   - 檢查網絡連接

3. 文件無法保存：
   - 檢查工作目錄權限
   - 確認磁盤空間充足

4. 搜索無結果：
   - 運行 :AiRagUpdate 重建索引
   - 檢查文件格式（應為 Markdown）

更多幫助：
- 查看 README.md 獲取詳細文檔
- 運行 :AiStatus 查看系統狀態
- 在對話中輸入 "幫助" 獲取使用指南
]]
