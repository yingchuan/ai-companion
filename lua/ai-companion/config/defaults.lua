local M = {}

-- 插件默認配置
M.plugin_defaults = {
  -- 工作空間配置
  workspace_dir = "~/workspace",

  -- AI 配置
  ai_config = {
    embedding_model = "openai:text-embedding-3-small",
    generation_model = "openai:o3-mini-high",
    temperature = 0.7,
    max_tokens = 4000,
    timeout = 30000, -- 30 秒超時
  },

  -- Git 整合配置
  git_integration = {
    enabled = true,
    auto_hooks = true,
    auto_commit = false,
    commit_message_template = "AI Companion: Auto-update knowledge base",
  },

  -- UI 配置
  ui = {
    chat_height = 15,
    chat_width = 80,
    auto_focus = true,
    auto_scroll = true,
    show_timestamps = true,
    theme = "default",
  },

  -- 文件組織配置
  file_organization = {
    auto_categorize = true,
    date_prefix = true,
    use_subdirectories = true,
    max_files_per_dir = 100,
  },

  -- 搜索配置
  search = {
    fuzzy_threshold = 0.8,
    max_results = 50,
    include_archived = false,
    search_in_content = true,
  },

  -- 通知配置
  notifications = {
    enabled = true,
    level = "INFO", -- DEBUG, INFO, WARN, ERROR
    show_success = true,
    show_errors = true,
    auto_hide_delay = 3000, -- 3 秒後自動隱藏
  },

  -- 性能配置
  performance = {
    async_processing = true,
    debounce_delay = 500, -- 500ms 防抖延遲
    max_concurrent_requests = 3,
    cache_size = 100,
    rag_chunk_size = 1000,
    rag_overlap = 200,
  },
}

-- 模型配置預設
M.model_presets = {
  -- OpenAI 配置
  openai = {
    embedding_model = "openai:text-embedding-3-small",
    generation_model = "openai:o3-mini-high",
    temperature = 0.7,
    max_tokens = 4000,
  },

  -- Anthropic 配置
  anthropic = {
    embedding_model = "openai:text-embedding-3-small", -- Anthropic 沒有 embedding 模型
    generation_model = "claude-sonnet-4-20250514",
    temperature = 0.7,
    max_tokens = 4000,
  },

  -- 本地模型配置
  ["local"] = {
    embedding_model = "local:sentence-transformers/all-MiniLM-L6-v2",
    generation_model = "local:llama2",
    temperature = 0.8,
    max_tokens = 2000,
  },

  -- 混合配置（OpenAI embedding + o3-mini-high generation）
  hybrid = {
    embedding_model = "openai:text-embedding-3-small",
    generation_model = "openai:o3-mini-high",
    temperature = 0.7,
    max_tokens = 4000,
  },
}

-- 工作流程模板
M.workflow_templates = {
  -- 軟件開發工作流
  software_development = {
    directories = {
      "projects",
      "tasks",
      "meetings",
      "notes/technical",
      "notes/learning",
      "discussions/architecture",
      "discussions/code-review",
      "reviews/sprint",
      "reviews/quarterly",
    },
    auto_tags = {
      "#development",
      "#project",
      "#learning",
      "#meeting",
    },
    file_naming = {
      tasks = "task-{date}-{id}",
      meetings = "meeting-{date}-{topic}",
      notes = "note-{date}-{category}",
    },
  },

  -- 研究工作流
  research = {
    directories = {
      "papers",
      "experiments",
      "ideas",
      "meetings/lab",
      "notes/literature",
      "notes/methodology",
      "discussions/hypothesis",
      "reviews/progress",
    },
    auto_tags = {
      "#research",
      "#experiment",
      "#paper",
      "#idea",
    },
    file_naming = {
      papers = "paper-{date}-{title}",
      experiments = "exp-{date}-{id}",
      ideas = "idea-{date}-{topic}",
    },
  },

  -- 通用工作流
  general = {
    directories = {
      "tasks",
      "meetings",
      "notes",
      "discussions",
      "reviews",
    },
    auto_tags = {
      "#work",
      "#personal",
      "#important",
    },
    file_naming = {
      tasks = "{date}-task-{id}",
      meetings = "{date}-meeting",
      notes = "{date}-note",
    },
  },
}

-- 快捷鍵配置
M.keymap_defaults = {
  -- 主要功能
  start_chat = "<leader><space>",
  quick_note = "<leader>an",
  quick_task = "<leader>at",
  search_workspace = "<leader>as",

  -- 對話窗口內
  chat = {
    send_message = "<CR>",
    insert_mode = "i",
    close_chat = "q",
    clear_chat = "<C-l>",
    history_up = "<Up>",
    history_down = "<Down>",
  },

  -- 文件操作
  files = {
    search_files = "<leader>fn",
    search_content = "<leader>sn",
    recent_files = "<leader>fr",
  },

  -- 管理功能
  admin = {
    show_status = "<leader>as",
    rebuild_rag = "<leader>ar",
    git_status = "<leader>ag",
  },
}

-- 提示詞模板
M.prompt_templates = {
  -- 系統提示詞
  system_prompts = {
    companion = "你是用戶的個人 AI 工作夥伴 FRIDAY，專注於提高工作效率和組織管理。",
    analyst = "你是數據分析專家，擅長發現模式和提供洞察。",
    organizer = "你是內容整理專家，擅長結構化信息和知識管理。",
    planner = "你是項目規劃專家，擅長任務分解和時間管理。",
  },

  -- 任務模板
  task_templates = {
    simple = "創建任務：{title}",
    detailed = "創建詳細任務：{title}\n描述：{description}\n截止日期：{deadline}\n優先級：{priority}",
    project = "創建項目任務：{title}\n所屬項目：{project}\n依賴任務：{dependencies}",
  },

  -- 會議模板
  meeting_templates = {
    standup = "每日站會 - {date}\n參與者：{participants}\n議題：{agenda}",
    planning = "規劃會議 - {topic}\n目標：{objectives}\n決策項：{decisions}",
    review = "回顧會議 - {period}\n成果：{achievements}\n問題：{issues}",
  },
}

-- 驗證規則
M.validation_rules = {
  workspace_dir = {
    type = "string",
    required = true,
    validator = function(value)
      return value and value ~= ""
    end,
  },

  ai_config = {
    type = "table",
    required = true,
    fields = {
      embedding_model = { type = "string", required = true },
      generation_model = { type = "string", required = true },
      temperature = {
        type = "number",
        required = false,
        validator = function(value)
          return value >= 0 and value <= 2
        end,
      },
    },
  },

  ui = {
    type = "table",
    required = false,
    fields = {
      chat_height = {
        type = "number",
        validator = function(value)
          return value > 5 and value < 50
        end,
      },
      chat_width = {
        type = "number",
        validator = function(value)
          return value > 40 and value < 200
        end,
      },
    },
  },
}

-- 錯誤消息
M.error_messages = {
  invalid_config = "配置驗證失敗：{errors}",
  missing_aichat = "未找到 aichat 命令，請先安裝",
  workspace_creation_failed = "無法創建工作目錄：{path}",
  git_init_failed = "Git 倉庫初始化失敗：{error}",
  ai_service_unavailable = "AI 服務暫時不可用",
  rag_initialization_failed = "知識庫初始化失敗",
  file_save_failed = "文件保存失敗：{path}",
  permission_denied = "權限不足：{operation}",
}

-- 成功消息
M.success_messages = {
  plugin_loaded = "AI 工作夥伴插件已加載",
  workspace_ready = "工作空間已就緒：{path}",
  git_initialized = "Git 倉庫初始化成功",
  rag_ready = "AI 知識庫已就緒",
  file_saved = "文件已保存：{type}",
  config_updated = "配置已更新",
}

-- 幫助文檔
M.help_docs = {
  quick_start = [[
🚀 AI 工作夥伴快速開始指南

1. 基本使用
   - 按 <leader><space> 開始對話
   - 直接用自然語言描述需求
   - 系統會自動識別意圖並創建相應內容

2. 常用功能
   - "明天開會討論新功能" → 創建會議記錄
   - "記錄學習的 React Hooks" → 保存學習筆記
   - "週五前完成API文檔" → 創建任務
   - "這週工作怎麼樣？" → 生成工作回顧

3. 快捷鍵
   - <leader>as: 查看狀態
   - <leader>fn: 搜索文件
   - <leader>sn: 搜索內容
]],

  advanced_usage = [[
🔧 高級使用技巧

1. 自定義配置
   - 在 LazyVim 配置中覆蓋默認設置
   - 選擇合適的 AI 模型
   - 調整工作流程模板

2. Git 整合
   - 自動同步知識庫
   - 版本控制筆記
   - 團隊協作

3. 性能優化
   - 調整緩存大小
   - 設置合理的超時時間
   - 使用本地模型減少延遲
]],
}

return M
