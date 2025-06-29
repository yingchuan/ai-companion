# Contributing to AI Companion

感謝你對 AI Companion 項目的關注！我們歡迎所有形式的貢獻。

## 🤝 如何貢獻

### 報告問題 (Issues)

如果你發現了 bug 或有功能建議：

1. 先檢查 [Issues](https://github.com/yingchuan/ai-companion/issues) 確認問題是否已經被報告
2. 創建新的 Issue，請包含：
   - 清晰的問題描述
   - 重現步驟
   - 預期行為 vs 實際行為
   - 環境信息（Neovim 版本、操作系統等）
   - 相關的錯誤信息和日誌

### 提交代碼 (Pull Requests)

1. **Fork 倉庫**
   ```bash
   git clone git@github.com:your-username/ai-companion.git
   cd ai-companion
   ```

2. **設置開發環境**
   ```bash
   # 自動安裝所有開發工具
   chmod +x setup-dev.sh
   ./setup-dev.sh
   
   # 或手動安裝
   pip install pre-commit
   pre-commit install
   luarocks install luacheck
   ```

3. **創建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/issue-number
   ```

4. **開發和測試**
   - 代碼會在提交時自動檢查格式和語法
   - 手動運行檢查：`pre-commit run --all-files`
   - 確保通過所有 pre-commit hooks
   - 添加必要的注釋和文檔

5. **提交更改**
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   # 或
   git commit -m "fix: 修復問題描述"
   
   # pre-commit hooks 會自動運行：
   # ✅ Lua 語法檢查
   # ✅ Lua 代碼格式化  
   # ✅ 安全掃描
   # ✅ Markdown 檢查
   ```

6. **推送並創建 PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   然後在 GitHub 上創建 Pull Request

## 📝 代碼規範

### Lua 代碼風格

```lua
-- 使用 2 空格縮進
local M = {}

-- 函數命名使用 snake_case
function M.create_task(task_info, original_message)
  -- 函數體
end

-- 常量使用 UPPER_CASE
local MAX_RETRIES = 3

-- 局部變量使用 snake_case
local user_input = "hello"

-- 表的鍵使用 snake_case
local config = {
  workspace_dir = "~/workspace",
  ai_config = {
    temperature = 0.7,
  }
}
```

### 注釋規範

```lua
-- 單行注釋使用 --

--[[
多行注釋使用這種格式
用於描述複雜的邏輯或模塊
]]

--- 函數文檔注釋
--- @param message string 用戶輸入的消息
--- @param callback function 回調函數
--- @return boolean 是否成功
function M.process_message(message, callback)
  -- 實現
end
```

### 錯誤處理

```lua
-- 使用 pcall 進行錯誤處理
local ok, result = pcall(vim.fn.json_decode, response)
if not ok then
  vim.notify("JSON 解析失敗", vim.log.levels.ERROR)
  return
end

-- 提供有意義的錯誤信息
if not user_input or user_input == "" then
  vim.notify("輸入不能為空", vim.log.levels.WARN)
  return
end
```

## 🪝 Pre-commit Hooks

項目使用 pre-commit hooks 確保代碼質量：

### **自動檢查項目**
- **Lua 語法檢查** - 確保 Lua 代碼可執行
- **Lua 代碼檢查** - 使用 luacheck 進行靜態分析
- **代碼格式化** - 使用 stylua 統一代碼風格
- **安全掃描** - 檢查潛在的 API 密鑰洩露
- **Markdown 檢查** - 確保文檔格式正確
- **文件清理** - 移除多餘空白、統一換行符

### **手動運行檢查**
```bash
# 運行所有檢查
pre-commit run --all-files

# 運行特定檢查
pre-commit run luacheck
pre-commit run check-secrets

# 更新 hooks 版本
pre-commit autoupdate
```

### **繞過檢查** (不推薦)
```bash
# 緊急情況下可以跳過檢查
git commit --no-verify -m "emergency fix"
```

## 🧪 測試

雖然我們目前沒有自動化測試框架，但請確保：

1. **自動檢查通過**
   - 所有 pre-commit hooks 通過
   - CI 檢查全部成功
   - 無 linting 錯誤或警告

2. **手動測試你的更改**
   - 測試正常流程
   - 測試錯誤情況
   - 測試邊界條件

3. **測試環境**
   ```bash
   # 創建測試工作空間
   mkdir -p test-workspace
   
   # 使用測試配置
   nvim -u test-config.lua
   ```

4. **檢查基本功能**
   - 對話界面正常工作
   - AI 回應正確生成
   - 文件正確保存
   - Git 整合正常

## 📚 文檔

### 更新文檔

如果你的更改影響了用戶界面或配置：

1. 更新 `README.md`
2. 更新 `example-config.lua`
3. 更新相關的注釋和文檔字符串
4. 更新 `CHANGELOG.md`

### 文檔風格

- 使用清晰、簡潔的語言
- 提供實際的示例代碼
- 包含常見問題的解決方案
- 中英文混排時注意格式

## 🏗️ 項目結構

```
ai-companion/
├── init.lua              # 主入口
├── core/                 # 核心功能
│   ├── chat.lua         # 對話界面
│   ├── ai.lua           # AI 調用
│   ├── intent.lua       # 意圖識別
│   └── content.lua      # 內容管理
├── utils/                # 工具函數
│   ├── git.lua          # Git 整合
│   ├── aichat.lua       # aichat 配置
│   └── helpers.lua      # 通用工具
├── config/              # 配置
│   └── defaults.lua     # 默認配置
├── templates/           # 模板
│   └── prompts.lua      # AI 提示詞
└── docs/                # 文檔（如果需要）
```

## 💡 開發建議

### 添加新功能

1. 先在 Issues 中討論你的想法
2. 確保功能符合項目目標
3. 考慮向後兼容性
4. 添加適當的配置選項
5. 更新文檔

### 性能考慮

- 使用異步操作避免阻塞
- 實現合理的緩存機制
- 避免不必要的 AI API 調用
- 優化大文件處理

### 安全考慮

- 不要在代碼中硬編碼 API 密鑰
- 驗證用戶輸入
- 安全地處理文件操作
- 注意權限問題

## 🎯 優先級

我們特別歡迎以下類型的貢獻：

### 高優先級
- Bug 修復
- 性能優化
- 文檔改進
- 錯誤處理增強

### 中優先級
- 新的 AI 模型支持
- 工作流程模板
- 界面改進
- 配置選項

### 低優先級
- 代碼重構
- 新功能（需要先討論）

## 📋 提交檢查清單

在提交 PR 之前，請確認：

- [ ] 代碼遵循項目風格
- [ ] 功能已經手動測試
- [ ] 錯誤情況已經處理
- [ ] 文檔已經更新
- [ ] 提交信息清晰描述了更改
- [ ] 沒有引入不必要的依賴
- [ ] 向後兼容性考慮

## 🤔 需要幫助？

如果你在貢獻過程中遇到問題：

1. 查看現有的 Issues 和 Discussions
2. 創建新的 Issue 詢問
3. 在 PR 中 @mention 維護者

## 📜 許可證

通過貢獻代碼，你同意你的貢獻將在 MIT 許可證下發布。

---

再次感謝你的貢獻！🎉