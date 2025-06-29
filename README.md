# AI 工作夥伴插件 (ai-companion.nvim)

一個為 LazyVim 設計的純對話式 AI 助手，統一管理筆記、任務、會議、討論等所有工作內容。

## ✨ 特性

- 🤖 **純對話式交互** - 自然語言處理所有工作需求
- 📚 **智能內容管理** - 自動分類保存任務、會議、筆記、討論
- 🧠 **RAG 知識庫** - 基於工作內容的智能問答
- 🔄 **Git 整合** - 自動同步知識庫，版本控制工作內容
- 🎯 **意圖識別** - 自動理解用戶需求並執行相應操作
- 📊 **工作回顧** - 自動生成效率分析和改進建議

## 🚀 快速開始

### 前置要求

1. **安裝 aichat**
```bash
# 使用 Cargo
cargo install aichat

# 或使用 Homebrew (macOS)
brew install aichat

# 確認安裝
aichat --version
```

2. **配置 API 密鑰**
```bash
# 設置 OpenAI API 密鑰（用於 embedding）
export OPENAI_API_KEY="your-openai-api-key"

# 設置 Anthropic API 密鑰（用於 Claude）
export ANTHROPIC_API_KEY="your-anthropic-api-key"
```

### 安裝插件

在你的 LazyVim 配置中添加：

```lua
-- ~/.config/nvim/lua/plugins/ai-companion.lua
return {
  {
    "ai-companion.nvim",
    dir = vim.fn.stdpath("config") .. "/lua/ai-companion", -- 本地路徑
    dependencies = {
      "ibhagwan/fzf-lua",
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspace_dir = "~/workspace",
      ai_config = {
        embedding_model = "openai:text-embedding-3-small",
        generation_model = "claude-3-5-sonnet",
        temperature = 0.7,
      },
    },
    config = function(_, opts)
      require('ai-companion').setup(opts)
    end,
    -- 延遲加載，提高啟動速度
    event = "VeryLazy",
  }
}
```

## 💬 使用方法

### 基本對話

按 `<leader><space>` 開始與 AI 對話：

```
你: "明天要開會討論新功能設計"
AI: 🤝 會議已記錄: 會議: 討論新功能設計
    ⏰ 時間: 待確認
    📋 議題: 新功能設計
    📚 背景資料已準備
    🔔 已設置會議提醒
    📝 需要我協助準備會議大綱嗎？
```

### 功能示例

| 輸入 | 效果 |
|------|------|
| "週五前要完成API文檔" | 📋 創建任務，自動設置截止日期 |
| "記錄一下今天學的 React Hooks" | 📝 保存學習筆記，自動分類標記 |
| "剛才會議決定用 TypeScript 重構" | 💬 記錄決議，分析影響 |
| "這週工作怎麼樣？" | 📊 生成工作回顧報告 |
| "如何優化數據庫查詢？" | 🔍 基於筆記智能回答 |

### 快捷鍵

- `<leader><space>` - 開始 AI 對話
- `<leader>fn` - 搜索工作文件
- `<leader>sn` - 搜索工作內容

**對話窗口內：**
- `<CR>` 或 `i` - 發送消息
- `q` 或 `<Esc>` - 關閉對話
- `<C-l>` - 清空對話
- `<Up>`/`<Down>` - 瀏覽歷史

## ⚙️ 配置選項

### 完整配置示例

```lua
require('ai-companion').setup({
  -- 工作目錄
  workspace_dir = "~/workspace",
  
  -- AI 配置
  ai_config = {
    embedding_model = "openai:text-embedding-3-small",
    generation_model = "claude-3-5-sonnet",
    temperature = 0.7,
    max_tokens = 4000,
    timeout = 30000,
  },
  
  -- Git 整合
  git_integration = {
    enabled = true,
    auto_hooks = true,
    auto_commit = false,
  },
  
  -- 界面設置
  ui = {
    chat_height = 15,
    auto_focus = true,
    show_timestamps = true,
  },
  
  -- 文件組織
  file_organization = {
    auto_categorize = true,
    date_prefix = true,
    use_subdirectories = true,
  },
  
  -- 性能設置
  performance = {
    async_processing = true,
    debounce_delay = 500,
    max_concurrent_requests = 3,
    cache_size = 100,
  },
})
```

### AI 模型預設

```lua
-- 使用 OpenAI
ai_config = require('ai-companion.config.defaults').model_presets.openai

-- 使用 Anthropic
ai_config = require('ai-companion.config.defaults').model_presets.anthropic

-- 混合使用（推薦）
ai_config = require('ai-companion.config.defaults').model_presets.hybrid
```

## 📂 文件結構

插件會在工作目錄中創建以下結構：

```
~/workspace/
├── tasks/           # 任務文件
├── meetings/        # 會議記錄
├── notes/           # 學習筆記
├── discussions/     # 討論記錄
└── reviews/         # 工作回顧
```

每個文件都是標準的 Markdown 格式，包含：
- 自動生成的元數據
- 智能提取的標籤
- 結構化的內容組織

## 🔧 管理命令

| 命令 | 功能 |
|------|------|
| `:AiChat` | 開始對話 |
| `:AiStatus` | 顯示 AI 狀態 |
| `:AiGitStatus` | Git 整合狀態 |
| `:AiGitRepair` | 修復 Git hooks |
| `:AiRagUpdate` | 手動更新知識庫 |
| `:AiConfigStatus` | aichat 配置狀態 |
| `:AiConfigTest` | 測試 AI 連接 |
| `:AiConfigReset` | 重置配置 |

## 🔍 故障排除

### 常見問題

**1. aichat 命令不存在**
```bash
# 安裝 aichat
cargo install aichat
# 或
brew install aichat
```

**2. API 密鑰錯誤**
```bash
# 檢查環境變量
echo $OPENAI_API_KEY
echo $ANTHROPIC_API_KEY

# 或在 shell 配置文件中設置
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
```

**3. 權限問題**
```bash
# 檢查工作目錄權限
ls -la ~/workspace
# 修復權限
chmod -R 755 ~/workspace
```

**4. Git hooks 不工作**
```vim
:AiGitRepair
```

**5. 知識庫初始化失敗**
```vim
:AiRagUpdate
```

### 調試模式

```lua
-- 在配置中啟用調試
notifications = {
  level = "DEBUG",
  show_success = true,
  show_errors = true,
}
```

## 🎯 工作流程

### 典型的一天

1. **早晨** - 查看狀態和計劃
   ```
   "狀態" → 查看工作概況
   "今天要完成什麼？" → 基於任務和會議安排
   ```

2. **工作中** - 實時記錄
   ```
   "學了新的 Kubernetes 概念" → 自動保存筆記
   "發現性能瓶頸在數據庫" → 記錄問題和解決思路
   ```

3. **會議** - 快速記錄
   ```
   "會議決定使用微服務架構" → 自動記錄決議
   "需要調研 gRPC vs REST" → 創建研究任務
   ```

4. **晚上** - 回顧總結
   ```
   "今天工作怎麼樣？" → 生成日報
   "這週進展如何？" → 週報分析
   ```

### 團隊協作

1. **共享工作目錄**
   ```bash
   # 初始化共享倉庫
   cd ~/workspace
   git init
   git remote add origin <team-repo>
   ```

2. **同步知識**
   ```bash
   git pull  # 自動觸發 RAG 更新
   git push  # 分享你的筆記和想法
   ```

## 🔮 高級特性

### 自定義工作流

```lua
-- 使用軟件開發工作流
file_organization = require('ai-companion.config.defaults').workflow_templates.software_development

-- 使用研究工作流
file_organization = require('ai-companion.config.defaults').workflow_templates.research
```

### 自定義提示詞

```lua
-- 覆蓋默認提示詞
local prompts = require('ai-companion.templates.prompts')
prompts.intent_analysis = function(message)
  return "你的自定義提示詞: " .. message
end
```

### 性能優化

```lua
performance = {
  -- 使用本地模型減少延遲
  use_local_models = true,
  
  -- 調整並發請求數
  max_concurrent_requests = 5,
  
  -- 增大緩存提高響應速度
  cache_size = 200,
  
  -- 異步處理避免阻塞
  async_processing = true,
}
```

## 📋 開發計劃

- [ ] **v1.1** - 添加語音輸入支持
- [ ] **v1.2** - 集成日歷和提醒系統
- [ ] **v1.3** - 支持多語言（英文、中文、日文）
- [ ] **v1.4** - 網頁端同步查看
- [ ] **v1.5** - 智能工作量預測
- [ ] **v2.0** - 團隊協作功能

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

1. Fork 本項目
2. 創建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

## 📄 許可證

MIT License - 詳見 [LICENSE](LICENSE) 文件

## 🙏 致謝

- [aichat](https://github.com/sigoden/aichat) - 強大的 AI 命令行工具
- [LazyVim](https://github.com/LazyVim/LazyVim) - 優秀的 Neovim 配置框架
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - 快速模糊搜索

---

**AI 工作夥伴 - 讓工作更智能，讓思考更清晰** 🚀