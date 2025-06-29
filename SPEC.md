# AI 工作夥伴插件 - 完整技術規格

## 1. 項目概述

### 1.1 項目名稱
`ai-companion.nvim` - LazyVim 的 AI 工作夥伴插件

### 1.2 核心功能
純對話式 AI 助手，統一管理筆記、任務、會議、討論等所有工作內容

### 1.3 技術棧
- **前端**: Neovim + Lua
- **AI引擎**: aichat (with RAG)
- **搜索**: LazyVim 內建的 fzf-lua + ripgrep
- **版本控制整合**: Git hooks
- **配置**: YAML

## 2. 文件結構

```
~/.config/nvim/lua/lib/ai-companion/
├── init.lua              -- 主入口和設置
├── core/
│   ├── chat.lua          -- 對話界面管理
│   ├── ai.lua            -- AI 調用和處理
│   ├── intent.lua        -- 意圖識別和分發
│   └── content.lua       -- 內容管理
├── config/
│   ├── defaults.lua      -- 默認配置
│   └── models.lua        -- 模型配置策略
├── utils/
│   ├── git.lua           -- Git 整合
│   ├── aichat.lua        -- aichat 配置管理
│   └── helpers.lua       -- 工具函數
└── templates/
    └── prompts.lua       -- AI prompt 模板
```

## 3. 核心模塊規格

### 3.1 主入口模塊 (init.lua)

```lua
-- 模塊接口定義
local M = {}

-- 默認配置
M.defaults = {
  workspace_dir = "~/workspace",
  ai_config = {
    embedding_model = "openai:text-embedding-3-small",
    generation_model = "claude-3-5-sonnet",
    temperature = 0.7,
  },
  git_integration = {
    enabled = true,
    auto_hooks = true,
  },
  ui = {
    chat_height = 15,
    auto_focus = true,
  }
}

-- 主設置函數
function M.setup(opts)
  -- 1. 合併用戶配置
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  
  -- 2. 驗證配置
  M.validate_config()
  
  -- 3. 初始化子模塊
  require('lib.ai-companion.core.ai').setup(M.config.ai_config)
  require('lib.ai-companion.utils.aichat').setup_config(M.config)
  
  -- 4. 設置快捷鍵
  M.setup_keymaps()
  
  -- 5. 設置 Git 整合
  if M.config.git_integration.enabled then
    require('lib.ai-companion.utils.git').setup(M.config.workspace_dir)
  end
  
  -- 6. 創建用戶命令
  M.create_user_commands()
end

-- 快捷鍵設置
function M.setup_keymaps()
  vim.keymap.set('n', '<leader><space>', function()
    require('lib.ai-companion.core.chat').start_conversation()
  end, { desc = "與 AI 對話" })
  
  -- 可選的傳統搜索快捷鍵
  vim.keymap.set('n', '<leader>fn', function()
    require('fzf-lua').files({ cwd = vim.fn.expand(M.config.workspace_dir) })
  end, { desc = "搜索工作文件" })
  
  vim.keymap.set('n', '<leader>sn', function()
    require('fzf-lua').live_grep({ cwd = vim.fn.expand(M.config.workspace_dir) })
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
  if vim.fn.executable('aichat') == 0 then
    vim.notify("警告: aichat 未找到，請先安裝", vim.log.levels.WARN)
  end
end

-- 用戶命令
function M.create_user_commands()
  vim.api.nvim_create_user_command('AiChat', function()
    require('lib.ai-companion.core.chat').start_conversation()
  end, { desc = "開始 AI 對話" })
  
  vim.api.nvim_create_user_command('AiStatus', function()
    require('lib.ai-companion.core.ai').show_status()
  end, { desc = "顯示 AI 狀態" })
end

return M
```

### 3.2 對話界面模塊 (core/chat.lua)

```lua
local M = {}
local ai = require('lib.ai-companion.core.ai')
local intent = require('lib.ai-companion.core.intent')

-- 對話狀態
M.chat_state = {
  is_active = false,
  chat_buf = nil,
  chat_win = nil,
  input_history = {},
  conversation_id = nil,
}

-- 開始對話
function M.start_conversation()
  if M.chat_state.is_active then
    M.focus_chat()
    return
  end
  
  M.create_chat_interface()
  M.chat_state.is_active = true
  M.chat_state.conversation_id = M.generate_conversation_id()
  
  -- 顯示歡迎信息
  M.display_ai_message("🤖 FRIDAY", "您好！我是您的 AI 工作夥伴。有什麼可以協助您的嗎？")
end

-- 創建對話界面
function M.create_chat_interface()
  -- 創建底部分屏
  vim.cmd('botright split')
  vim.cmd('resize ' .. require('lib.ai-companion').config.ui.chat_height)
  
  -- 創建對話緩衝區
  M.chat_state.chat_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(M.chat_state.chat_buf)
  M.chat_state.chat_win = vim.api.nvim_get_current_win()
  
  -- 設置緩衝區屬性
  vim.bo[M.chat_state.chat_buf].filetype = 'markdown'
  vim.bo[M.chat_state.chat_buf].buftype = 'nofile'
  vim.bo[M.chat_state.chat_buf].swapfile = false
  
  -- 設置窗口選項
  vim.wo[M.chat_state.chat_win].wrap = true
  vim.wo[M.chat_state.chat_win].linebreak = true
  vim.wo[M.chat_state.chat_win].number = false
  vim.wo[M.chat_state.chat_win].relativenumber = false
  
  -- 設置對話快捷鍵
  M.setup_chat_keymaps()
end

-- 對話快捷鍵
function M.setup_chat_keymaps()
  local opts = { buffer = M.chat_state.chat_buf, silent = true }
  
  -- 發送消息
  vim.keymap.set('n', '<CR>', M.prompt_user_input, opts)
  vim.keymap.set('n', 'i', M.prompt_user_input, opts)
  
  -- 關閉對話
  vim.keymap.set('n', 'q', M.close_chat, opts)
  vim.keymap.set('n', '<Esc>', M.close_chat, opts)
  
  -- 清空對話
  vim.keymap.set('n', '<C-l>', M.clear_chat, opts)
  
  -- 歷史記錄
  vim.keymap.set('n', '<Up>', M.previous_input, opts)
  vim.keymap.set('n', '<Down>', M.next_input, opts)
end

-- 用戶輸入處理
function M.prompt_user_input()
  vim.ui.input({
    prompt = '💬 說話: ',
    completion = 'customlist,v:lua.require("lib.ai-companion.core.chat").input_completion',
  }, function(input)
    if input and input:match("%S") then
      M.handle_user_message(input)
    end
  end)
end

-- 處理用戶消息
function M.handle_user_message(message)
  -- 1. 顯示用戶消息
  M.display_user_message(message)
  
  -- 2. 添加到歷史
  table.insert(M.chat_state.input_history, message)
  if #M.chat_state.input_history > 50 then
    table.remove(M.chat_state.input_history, 1)
  end
  
  -- 3. 處理消息 (異步)
  vim.schedule(function()
    M.process_message_async(message)
  end)
end

-- 異步消息處理
function M.process_message_async(message)
  -- 顯示處理中狀態
  M.display_ai_message("🤖 FRIDAY", "正在思考中...")
  
  -- 意圖識別和處理
  intent.process_user_message(message, function(response)
    -- 更新最後的 AI 消息
    M.update_last_ai_message(response)
  end)
end

-- 顯示用戶消息
function M.display_user_message(message)
  local timestamp = os.date("%H:%M")
  local formatted = string.format("\n**👤 用戶** (%s)\n%s\n", timestamp, message)
  M.append_to_chat(formatted)
end

-- 顯示 AI 消息
function M.display_ai_message(sender, message)
  local timestamp = os.date("%H:%M")
  local formatted = string.format("\n**%s** (%s)\n%s\n", sender, timestamp, message)
  M.append_to_chat(formatted)
end

-- 更新最後的 AI 消息
function M.update_last_ai_message(new_message)
  local lines = vim.api.nvim_buf_get_lines(M.chat_state.chat_buf, 0, -1, false)
  
  -- 找到最後的 AI 消息並替換
  for i = #lines, 1, -1 do
    if lines[i]:match("^%*%*🤖 FRIDAY%*%*") then
      -- 找到 AI 消息的開始，替換到緩衝區末尾
      local timestamp = os.date("%H:%M")
      local formatted = string.format("**🤖 FRIDAY** (%s)\n%s", timestamp, new_message)
      local new_lines = vim.split(formatted, '\n')
      
      vim.api.nvim_buf_set_lines(M.chat_state.chat_buf, i-1, -1, false, new_lines)
      break
    end
  end
  
  M.scroll_to_bottom()
end

-- 添加內容到對話
function M.append_to_chat(content)
  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(M.chat_state.chat_buf, -1, -1, false, lines)
  M.scroll_to_bottom()
end

-- 滾動到底部
function M.scroll_to_bottom()
  if M.chat_state.chat_win and vim.api.nvim_win_is_valid(M.chat_state.chat_win) then
    local line_count = vim.api.nvim_buf_line_count(M.chat_state.chat_buf)
    vim.api.nvim_win_set_cursor(M.chat_state.chat_win, {line_count, 0})
  end
end

-- 關閉對話
function M.close_chat()
  if M.chat_state.chat_win and vim.api.nvim_win_is_valid(M.chat_state.chat_win) then
    vim.api.nvim_win_close(M.chat_state.chat_win, true)
  end
  M.chat_state.is_active = false
  M.chat_state.chat_buf = nil
  M.chat_state.chat_win = nil
end

-- 清空對話
function M.clear_chat()
  if M.chat_state.chat_buf and vim.api.nvim_buf_is_valid(M.chat_state.chat_buf) then
    vim.api.nvim_buf_set_lines(M.chat_state.chat_buf, 0, -1, false, {})
    M.display_ai_message("🤖 FRIDAY", "對話已清空。有什麼可以協助您的嗎？")
  end
end

-- 生成對話 ID
function M.generate_conversation_id()
  return string.format("conv_%s_%d", os.date("%Y%m%d_%H%M%S"), math.random(1000, 9999))
end

-- 輸入補全
function M.input_completion()
  local common_inputs = {
    "幫我總結一下今天的工作",
    "創建一個新任務",
    "分析當前項目的進度",
    "整理最近的會議記錄",
    "我想學習",
    "檢查有什麼需要處理的事項",
  }
  return common_inputs
end

return M
```

### 3.3 AI 調用模塊 (core/ai.lua)

```lua
local M = {}

-- AI 狀態
M.ai_state = {
  available = false,
  current_model = nil,
  rag_initialized = false,
  cost_tracking = {
    monthly_usage = 0,
    last_reset = os.date("%Y-%m"),
  }
}

-- 設置 AI 配置
function M.setup(config)
  M.config = config
  M.check_ai_availability()
  M.setup_rag()
end

-- 檢查 AI 可用性
function M.check_ai_availability()
  if vim.fn.executable('aichat') == 1 then
    M.ai_state.available = true
    M.ai_state.current_model = M.config.generation_model
    vim.notify("✅ AI 助手已就緒", vim.log.levels.INFO)
  else
    M.ai_state.available = false
    vim.notify("❌ aichat 未找到，請先安裝", vim.log.levels.ERROR)
  end
end

-- 設置 RAG
function M.setup_rag()
  if not M.ai_state.available then return end
  
  local workspace_dir = vim.fn.expand(require('lib.ai-companion').config.workspace_dir)
  
  -- 檢查 RAG 是否已初始化
  local rag_check_cmd = string.format('aichat --rag workspace-rag --info 2>/dev/null')
  local result = vim.fn.system(rag_check_cmd)
  
  if vim.v.shell_error ~= 0 then
    -- 初始化 RAG
    vim.notify("🔧 正在初始化 AI 知識庫...", vim.log.levels.INFO)
    M.initialize_rag(workspace_dir)
  else
    M.ai_state.rag_initialized = true
    vim.notify("✅ AI 知識庫已就緒", vim.log.levels.INFO)
  end
end

-- 初始化 RAG
function M.initialize_rag(workspace_dir)
  local init_cmd = string.format('aichat --rag workspace-rag "%s"', workspace_dir)
  
  vim.fn.jobstart(init_cmd, {
    on_exit = function(_, code)
      if code == 0 then
        M.ai_state.rag_initialized = true
        vim.notify("✅ AI 知識庫初始化完成", vim.log.levels.INFO)
      else
        vim.notify("❌ AI 知識庫初始化失敗", vim.log.levels.ERROR)
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

-- 調用 AI (帶 RAG)
function M.call_ai_with_rag(message, callback)
  if not M.ai_state.available or not M.ai_state.rag_initialized then
    callback("抱歉，AI 服務暫時不可用")
    return
  end
  
  local cmd = string.format('aichat --rag workspace-rag "%s"', M.escape_shell_arg(message))
  
  local response_parts = {}
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(response_parts, line)
          end
        end
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        local response = table.concat(response_parts, '\n')
        M.track_usage(message, response)
        callback(response)
      else
        callback("抱歉，AI 處理時發生錯誤")
      end
    end,
    stdout_buffered = false,
  })
end

-- 調用 AI (無 RAG)
function M.call_ai_direct(message, callback)
  if not M.ai_state.available then
    callback("抱歉，AI 服務暫時不可用")
    return
  end
  
  local cmd = string.format('aichat "%s"', M.escape_shell_arg(message))
  
  local response_parts = {}
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(response_parts, line)
          end
        end
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        local response = table.concat(response_parts, '\n')
        M.track_usage(message, response)
        callback(response)
      else
        callback("抱歉，AI 處理時發生錯誤")
      end
    end,
    stdout_buffered = false,
  })
end

-- JSON 格式 AI 調用
function M.call_ai_json(message, callback)
  local json_prompt = string.format([[
%s

請以 JSON 格式回應，不要包含其他內容。
]], message)
  
  M.call_ai_direct(json_prompt, function(response)
    local ok, parsed = pcall(vim.fn.json_decode, response)
    if ok then
      callback(parsed)
    else
      -- 嘗試提取 JSON 部分
      local json_match = response:match('{.-}') or response:match('%[.-%]')
      if json_match then
        local ok2, parsed2 = pcall(vim.fn.json_decode, json_match)
        if ok2 then
          callback(parsed2)
        else
          callback({ error = "JSON 解析失敗", raw_response = response })
        end
      else
        callback({ error = "未找到 JSON 格式", raw_response = response })
      end
    end
  end)
end

-- 重建 RAG
function M.rebuild_rag()
  if not M.ai_state.available then return end
  
  vim.notify("🔄 正在重建 AI 知識庫...", vim.log.levels.INFO)
  
  local rebuild_cmd = 'aichat --rag workspace-rag --rebuild'
  vim.fn.jobstart(rebuild_cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("✅ AI 知識庫重建完成", vim.log.levels.INFO)
      else
        vim.notify("❌ AI 知識庫重建失敗", vim.log.levels.ERROR)
      end
    end,
  })
end

-- 使用量追蹤
function M.track_usage(input, output)
  local current_month = os.date("%Y-%m")
  if M.ai_state.cost_tracking.last_reset ~= current_month then
    M.ai_state.cost_tracking.monthly_usage = 0
    M.ai_state.cost_tracking.last_reset = current_month
  end
  
  -- 簡單的 token 估算
  local input_tokens = M.estimate_tokens(input)
  local output_tokens = M.estimate_tokens(output)
  M.ai_state.cost_tracking.monthly_usage = M.ai_state.cost_tracking.monthly_usage + input_tokens + output_tokens
end

-- Token 估算
function M.estimate_tokens(text)
  -- 簡單估算：1 token ≈ 4 字符
  return math.ceil(#text / 4)
end

-- 顯示狀態
function M.show_status()
  local status = string.format([[
🤖 AI 助手狀態

可用性: %s
當前模型: %s
知識庫: %s
本月使用: ~%d tokens

配置:
- Embedding: %s
- Generation: %s
]], 
    M.ai_state.available and "✅ 可用" or "❌ 不可用",
    M.ai_state.current_model or "未設置",
    M.ai_state.rag_initialized and "✅ 已就緒" or "❌ 未初始化",
    M.ai_state.cost_tracking.monthly_usage,
    M.config.embedding_model,
    M.config.generation_model
  )
  
  vim.notify(status, vim.log.levels.INFO)
end

-- Shell 參數轉義
function M.escape_shell_arg(arg)
  return "'" .. arg:gsub("'", "'\"'\"'") .. "'"
end

return M
```

### 3.4 意圖識別模塊 (core/intent.lua)

```lua
local M = {}
local ai = require('lib.ai-companion.core.ai')
local content = require('lib.ai-companion.core.content')
local prompts = require('lib.ai-companion.templates.prompts')

-- 處理用戶消息
function M.process_user_message(message, callback)
  -- 1. 先嘗試簡單的關鍵詞匹配
  local quick_response = M.try_quick_response(message)
  if quick_response then
    callback(quick_response)
    return
  end
  
  -- 2. 使用 AI 進行意圖識別
  M.identify_intent(message, function(intent_result)
    -- 3. 處理識別的意圖
    M.process_intent(message, intent_result, callback)
  end)
end

-- 快速回應匹配
function M.try_quick_response(message)
  local quick_patterns = {
    ["你好"] = "您好！我是您的 AI 工作夥伴 FRIDAY。有什麼可以協助您的嗎？",
    ["謝謝"] = "不客氣！還有其他需要協助的嗎？",
    ["狀態"] = function() return M.get_status_summary() end,
    ["幫助"] = function() return M.get_help_info() end,
  }
  
  for pattern, response in pairs(quick_patterns) do
    if message:lower():find(pattern:lower()) then
      if type(response) == "function" then
        return response()
      else
        return response
      end
    end
  end
  
  return nil
end

-- 意圖識別
function M.identify_intent(message, callback)
  local prompt = prompts.intent_analysis(message)
  
  ai.call_ai_json(prompt, function(result)
    if result.error then
      -- 降級到基於 RAG 的一般回應
      M.fallback_to_rag_response(message, callback)
    else
      callback(result)
    end
  end)
end

-- 處理意圖
function M.process_intent(message, intent_result, callback)
  local processors = {
    question = M.process_question,
    task = M.process_task,
    meeting = M.process_meeting,
    note = M.process_note,
    discussion = M.process_discussion,
    review = M.process_review,
    general = M.process_general,
  }
  
  local intent_types = intent_result.intent or {"general"}
  local primary_intent = intent_types[1]
  
  local processor = processors[primary_intent] or processors.general
  processor(message, intent_result, callback)
end

-- 問題處理
function M.process_question(message, intent_result, callback)
  -- 使用 RAG 回答問題
  ai.call_ai_with_rag(message, function(response)
    -- 添加相關建議
    local enhanced_response = M.enhance_question_response(response, intent_result)
    callback(enhanced_response)
  end)
end

-- 任務處理
function M.process_task(message, intent_result, callback)
  -- 1. 創建任務
  local task_info = intent_result.extracted_info or {}
  local task = content.create_task(task_info, message)
  
  -- 2. 檢查相關知識
  local knowledge_check = content.check_task_knowledge(task)
  
  -- 3. 生成回應
  local response = string.format([[
✅ **任務已創建**: %s

📅 **預估完成**: %s
🎯 **優先級**: %s
📝 **詳細信息**: %s

%s

💡 需要我協助制定詳細計劃嗎？
]], 
    task.title,
    task.deadline or "未設定",
    task.priority or "中等",
    task.description or "待補充",
    knowledge_check.suggestions or ""
  )
  
  callback(response)
end

-- 會議處理
function M.process_meeting(message, intent_result, callback)
  local meeting_info = intent_result.extracted_info or {}
  local meeting = content.create_meeting(meeting_info, message)
  
  -- 準備背景材料
  local background = content.prepare_meeting_background(meeting.topic)
  
  local response = string.format([[
🤝 **會議已記錄**: %s

⏰ **時間**: %s
👥 **參與者**: %s
📋 **議題**: %s

📚 **背景資料已準備**:
%s

🔔 **提醒**: 已設置會議提醒
📝 需要我協助準備會議大綱嗎？
]], 
    meeting.title,
    meeting.datetime or "待確認",
    table.concat(meeting.participants or {}, ", "),
    meeting.topic or "待補充",
    background.summary or "相關筆記和歷史討論"
  )
  
  callback(response)
end

-- 筆記處理
function M.process_note(message, intent_result, callback)
  local note_info = intent_result.extracted_info or {}
  local note = content.create_note(note_info, message)
  
  -- 尋找關聯
  local connections = content.find_note_connections(note)
  
  local response = string.format([[
📝 **筆記已保存**: %s

🏷️ **自動標籤**: %s
📁 **分類**: %s
🔗 **發現關聯**: %s

❓ 想要深入探討什麼方面？我可以基於相關筆記提供更多見解。
]], 
    note.title,
    table.concat(note.tags or {}, ", "),
    note.category or "一般",
    connections.summary or "暫無"
  )
  
  callback(response)
end

-- 討論處理
function M.process_discussion(message, intent_result, callback)
  local discussion_info = intent_result.extracted_info or {}
  local discussion = content.create_discussion(discussion_info, message)
  
  local response = string.format([[
💬 **討論已記錄**: %s

🎯 **主要觀點**: %s
⚡ **爭議焦點**: %s
✅ **達成共識**: %s

📊 需要我分析不同觀點並提供決策建議嗎？
]], 
    discussion.title,
    discussion.viewpoints_summary or "待整理",
    discussion.controversies or "暫無",
    discussion.consensus or "待形成"
  )
  
  callback(response)
end

-- 回顧處理
function M.process_review(message, intent_result, callback)
  local review_info = intent_result.extracted_info or {}
  local review_data = content.collect_review_data(review_info.period)
  
  -- 生成回顧報告
  content.generate_review_report(review_data, function(report)
    local response = string.format([[
📊 **%s回顧報告**

%s

🎯 **改進建議**: 基於分析結果制定下階段計劃

📈 需要我協助制定具體的改進行動計劃嗎？
]], 
      review_info.period or "本期",
      report
    )
    
    callback(response)
  end)
end

-- 一般處理
function M.process_general(message, intent_result, callback)
  -- 使用 RAG 進行一般回應
  ai.call_ai_with_rag(message, function(response)
    callback(response)
  end)
end

-- 降級到 RAG 回應
function M.fallback_to_rag_response(message, callback)
  ai.call_ai_with_rag(message, function(response)
    local enhanced = string.format([[
%s

💡 **提示**: 您可以告訴我具體的任務、會議安排或想要記錄的內容，我會自動為您整理和管理。
]], response)
    callback(enhanced)
  end)
end

-- 增強問題回應
function M.enhance_question_response(response, intent_result)
  local suggestions = {}
  
  -- 根據問題類型添加建議
  if intent_result.extracted_info then
    local info = intent_result.extracted_info
    if info.technical_topic then
      table.insert(suggestions, "💡 要不要我創建學習任務來深入研究這個主題？")
    end
    if info.mentions_project then
      table.insert(suggestions, "📋 需要我幫您規劃相關的項目任務嗎？")
    end
  end
  
  if #suggestions > 0 then
    return response .. "\n\n" .. table.concat(suggestions, "\n")
  else
    return response
  end
end

-- 狀態總結
function M.get_status_summary()
  local workspace_dir = vim.fn.expand(require('lib.ai-companion').config.workspace_dir)
  local file_count = vim.fn.len(vim.fn.glob(workspace_dir .. "/**/*.md", 0, 1))
  
  return string.format([[
📊 **工作狀態總覽**

📁 工作目錄: %s
📝 文件總數: %d 個
🤖 AI 狀態: %s
🧠 知識庫: %s

⚡ 一切就緒！有什麼可以協助您的嗎？
]], 
    workspace_dir,
    file_count,
    ai.ai_state.available and "✅ 在線" or "❌ 離線",
    ai.ai_state.rag_initialized and "✅ 已同步" or "⏳ 同步中"
  )
end

-- 幫助信息
function M.get_help_info()
  return [[
🚀 **AI 工作夥伴使用指南**

💬 **對話方式**:
• 直接告訴我您想做什麼
• 使用自然語言，不需要特殊命令

📝 **功能示例**:
• "明天要開會討論新功能" → 自動創建會議記錄
• "記錄一下今天學的 MLIR 優化" → 智能保存筆記
• "週五前要完成API文檔" → 創建任務並評估
• "剛才的會議決定用 React 重構" → 記錄決議
• "這週工作怎麼樣？" → 自動生成回顧報告

🔍 **搜索功能**:
• 問任何技術問題，我會基於您的筆記回答
• 自動發現相關內容和關聯

⚡ **快捷操作**:
• 輸入 "狀態" 查看工作概況
• 輸入 "幫助" 顯示此信息
• 按 'q' 或 Esc 關閉對話窗口

💡 就像跟同事聊天一樣自然使用即可！
]]
end

return M
```

### 3.5 內容管理模塊 (core/content.lua)

```lua
local M = {}
local ai = require('lib.ai-companion.core.ai')

-- 創建任務
function M.create_task(task_info, original_message)
  local workspace_dir = vim.fn.expand(require('lib.ai-companion').config.workspace_dir)
  
  -- 解析任務信息
  local task = {
    id = M.generate_id("task"),
    title = task_info.task or M.extract_task_title(original_message),
    description = original_message,
    priority = task_info.priority or "medium",
    deadline = task_info.deadline or nil,
    status = "pending",
    created = os.date("%Y-%m-%d %H:%M:%S"),
    tags = M.extract_tags(original_message),
    related_people = task_info.related_people or {},
  }
  
  -- 保存任務到文件
  M.save_task(task, workspace_dir)
  
  return task
end

-- 創建會議記錄
function M.create_meeting(meeting_info, original_message)
  local workspace_dir = vim.fn.expand(require('lib.ai-companion').config.workspace_dir)
  
  local meeting = {
    id = M.generate_id("meeting"),
    title = meeting_info.meeting or M.extract_meeting_title(original_message),
    topic = meeting_info.topic or "",
    datetime = meeting_info.datetime or nil,
    participants = meeting_info.participants or {},
    content = original_message,
    created = os.date("%Y-%m-%d %H:%M:%S"),
    tags = M.extract_tags(original_message),
  }
  
  -- 保存會議記錄
  M.save_meeting(meeting, workspace_dir)
  
  return meeting
end

-- 創建筆記
function M.create_note(note_info, original_message)
  local workspace_dir = vim.fn.expand(require('lib.ai-companion').config.workspace_dir)
  
  local note = {
    id = M.generate_id("note"),
    title = note_info.title or M.extract_note_title(original_message),
    content = original_message,
    category = note_info.category or "general",
    created = os.date("%Y-%m-%d %H:%M:%S"),
    tags = M.extract_tags(original_message),
  }
  
  -- 保存筆記
  M.save_note(note, workspace_dir)
  
  return note
end

-- 創建討論記錄
function M.create_discussion(discussion_info, original_message)
  local workspace_dir = vim.fn.expand(require('lib.ai-companion').config.workspace_dir)
  
  local discussion = {
    id = M.generate_id("discussion"),
    title = discussion_info.title or M.extract_discussion_title(original_message),
    content = original_message,
    viewpoints_summary = "待AI分析",
    controversies = "待識別",
    consensus = "待形成",
    created = os.date("%Y-%m-%d %H:%M:%S"),
    tags = M.extract_tags(original_message),
  }
  
  -- 異步分析討論內容
  M.analyze_discussion_async(discussion)
  
  -- 保存討論記錄
  M.save_discussion(discussion, workspace_dir)
  
  return discussion
end

-- 檢查任務相關知識
function M.check_task_knowledge(task)
  -- 使用 AI 分析任務需要的知識
  local prompt = string.format([[
分析以下任務，評估需要的知識和技能：

任務: %s
描述: %s

請提供：
1. 需要的核心知識點
2. 可能的挑戰和解決方案
3. 相關的學習建議
4. 預估難度和時間
]], task.title, task.description)
  
  local result = {
    suggestions = "正在分析相關知識...",
    difficulty = "待評估",
    time_estimate = "待評估"
  }
  
  -- 異步獲取分析結果
  ai.call_ai_with_rag(prompt, function(response)
    result.suggestions = response
  end)
  
  return result
end

-- 準備會議背景
function M.prepare_meeting_background(topic)
  if not topic or topic == "" then
    return { summary = "無特定議題，未準備背景資料" }
  end
  
  local result = {
    summary = "正在準備背景資料..."
  }
  
  -- 使用 RAG 搜索相關內容
  local prompt = string.format([[
為即將舉行的會議準備背景資料：

會議議題: %s

請基於已有的筆記、歷史討論和相關內容，提供：
1. 相關背景信息
2. 歷史決議和討論要點
3. 需要注意的問題
4. 建議的討論方向
]], topic)
  
  ai.call_ai_with_rag(prompt, function(response)
    result.summary = response
  end)
  
  return result
end

-- 尋找筆記關聯
function M.find_note_connections(note)
  local result = {
    summary = "正在分析關聯..."
  }
  
  local prompt = string.format([[
分析這個新筆記與已有內容的關聯：

新筆記: %s
內容: %s

請基於已有的筆記和討論，找出：
1. 相關的概念和主題
2. 可以建立的知識連接
3. 互補或對比的觀點
4. 後續可以深入的方向
]], note.title, note.content)
  
  ai.call_ai_with_rag(prompt, function(response)
    result.summary = response
  end)
  
  return result
end

-- 收集回顧數據
function M.collect_review_data(period)
  local workspace_dir = vim.fn.expand(require('lib.ai-companion').config.workspace_dir)
  local end_date = os.date("%Y-%m-%d")
  local start_date = M.calculate_start_date(period, end_date)
  
  return {
    period = period,
    start_date = start_date,
    end_date = end_date,
    tasks = M.get_tasks_in_period(start_date, end_date, workspace_dir),
    meetings = M.get_meetings_in_period(start_date, end_date, workspace_dir),
    notes = M.get_notes_in_period(start_date, end_date, workspace_dir),
    discussions = M.get_discussions_in_period(start_date, end_date, workspace_dir),
  }
end

-- 生成回顧報告
function M.generate_review_report(review_data, callback)
  local prompt = string.format([[
請基於以下數據生成%s回顧報告：

時間範圍: %s 到 %s

活動統計:
- 任務: %d 項
- 會議: %d 次
- 筆記: %d 篇
- 討論: %d 次

詳細內容:
%s

請提供：
1. 🎯 主要成就和亮點
2. 📊 工作效率分析
3. 🔍 發現的模式和趨勢
4. ⚠️ 需要注意的問題
5. 💡 改進建議
6. 🎯 下期重點建議
]], 
    review_data.period,
    review_data.start_date,
    review_data.end_date,
    #review_data.tasks,
    #review_data.meetings,
    #review_data.notes,
    #review_data.discussions,
    M.format_review_details(review_data)
  )
  
  ai.call_ai_with_rag(prompt, callback)
end

-- 保存任務
function M.save_task(task, workspace_dir)
  local tasks_dir = workspace_dir .. "/tasks"
  vim.fn.mkdir(tasks_dir, "p")
  
  local filename = string.format("%s/%s-%s.md", tasks_dir, os.date("%Y%m%d"), task.id)
  local content = M.format_task_content(task)
  
  vim.fn.writefile(vim.split(content, '\n'), filename)
end

-- 保存會議記錄
function M.save_meeting(meeting, workspace_dir)
  local meetings_dir = workspace_dir .. "/meetings"
  vim.fn.mkdir(meetings_dir, "p")
  
  local filename = string.format("%s/%s-%s.md", meetings_dir, os.date("%Y%m%d"), meeting.id)
  local content = M.format_meeting_content(meeting)
  
  vim.fn.writefile(vim.split(content, '\n'), filename)
end

-- 保存筆記
function M.save_note(note, workspace_dir)
  local notes_dir = workspace_dir .. "/notes"
  vim.fn.mkdir(notes_dir, "p")
  
  local filename = string.format("%s/%s-%s.md", notes_dir, os.date("%Y%m%d"), note.id)
  local content = M.format_note_content(note)
  
  vim.fn.writefile(vim.split(content, '\n'), filename)
end

-- 保存討論記錄
function M.save_discussion(discussion, workspace_dir)
  local discussions_dir = workspace_dir .. "/discussions"
  vim.fn.mkdir(discussions_dir, "p")
  
  local filename = string.format("%s/%s-%s.md", discussions_dir, os.date("%Y%m%d"), discussion.id)
  local content = M.format_discussion_content(discussion)
  
  vim.fn.writefile(vim.split(content, '\n'), filename)
end

-- 格式化任務內容
function M.format_task_content(task)
  return string.format([[
# 任務: %s

**創建時間**: %s
**任務ID**: %s
**優先級**: %s
**截止日期**: %s
**狀態**: %s

## 描述
%s

## 相關人員
%s

## 標籤
%s

## 進度記錄
- [ ] 任務創建 (%s)

]], 
    task.title,
    task.created,
    task.id,
    task.priority,
    task.deadline or "未設定",
    task.status,
    task.description,
    table.concat(task.related_people, ", "),
    table.concat(task.tags, " "),
    task.created
  )
end

-- 格式化會議內容
function M.format_meeting_content(meeting)
  return string.format([[
# 會議: %s

**創建時間**: %s
**會議ID**: %s
**會議時間**: %s
**參與者**: %s

## 議題
%s

## 會議內容
%s

## 行動項目
- [ ] 待補充

## 標籤
%s

]], 
    meeting.title,
    meeting.created,
    meeting.id,
    meeting.datetime or "待確認",
    table.concat(meeting.participants, ", "),
    meeting.topic,
    meeting.content,
    table.concat(meeting.tags, " ")
  )
end

-- 格式化筆記內容
function M.format_note_content(note)
  return string.format([[
# %s

**創建時間**: %s
**筆記ID**: %s
**分類**: %s

## 內容
%s

## 相關鏈接
- 

## 標籤
%s

]], 
    note.title,
    note.created,
    note.id,
    note.category,
    note.content,
    table.concat(note.tags, " ")
  )
end

-- 格式化討論內容
function M.format_discussion_content(discussion)
  return string.format([[
# 討論: %s

**創建時間**: %s
**討論ID**: %s

## 討論內容
%s

## 觀點總結
%s

## 爭議焦點
%s

## 達成共識
%s

## 標籤
%s

]], 
    discussion.title,
    discussion.created,
    discussion.id,
    discussion.content,
    discussion.viewpoints_summary,
    discussion.controversies,
    discussion.consensus,
    table.concat(discussion.tags, " ")
  )
end

-- 工具函數
function M.generate_id(prefix)
  return string.format("%s_%s_%d", prefix, os.date("%H%M%S"), math.random(100, 999))
end

function M.extract_task_title(message)
  -- 簡單的任務標題提取
  local patterns = {
    "要([^，。]+)",
    "需要([^，。]+)", 
    "完成([^，。]+)",
    "做([^，。]+)"
  }
  
  for _, pattern in ipairs(patterns) do
    local match = message:match(pattern)
    if match then
      return match:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end
  
  -- 如果沒匹配到，返回消息的前半部分
  return message:sub(1, 30) .. (message:len() > 30 and "..." or "")
end

function M.extract_meeting_title(message)
  local patterns = {
    "會議([^，。]+)",
    "開會([^，。]+)",
    "討論([^，。]+)",
    "約([^，。]+)"
  }
  
  for _, pattern in ipairs(patterns) do
    local match = message:match(pattern)
    if match then
      return "會議: " .. match:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end
  
  return "會議: " .. message:sub(1, 20) .. (message:len() > 20 and "..." or "")
end

function M.extract_note_title(message)
  local patterns = {
    "學了([^，。]+)",
    "記錄([^，。]+)",
    "筆記([^，。]+)",
    "了解([^，。]+)"
  }
  
  for _, pattern in ipairs(patterns) do
    local match = message:match(pattern)
    if match then
      return match:gsub("^%s+", ""):gsub("%s+$", "")
    end
  end
  
  return message:sub(1, 30) .. (message:len() > 30 and "..." or "")
end

function M.extract_discussion_title(message)
  return "討論: " .. message:sub(1, 25) .. (message:len() > 25 and "..." or "")
end

function M.extract_tags(message)
  local tags = {}
  
  -- 技術標籤檢測
  local tech_keywords = {
    ["python"] = "#python",
    ["javascript"] = "#javascript", 
    ["react"] = "#react",
    ["vue"] = "#vue",
    ["mlir"] = "#mlir",
    ["llvm"] = "#llvm",
    ["ai"] = "#ai",
    ["ml"] = "#ml",
    ["api"] = "#api",
    ["database"] = "#database",
    ["優化"] = "#optimization",
    ["性能"] = "#performance",
    ["測試"] = "#testing",
    ["部署"] = "#deployment"
  }
  
  for keyword, tag in pairs(tech_keywords) do
    if message:lower():find(keyword:lower()) then
      table.insert(tags, tag)
    end
  end
  
  -- 添加基於時間的標籤
  table.insert(tags, "#" .. os.date("%Y-%m"))
  
  return tags
end

-- 異步分析討論
function M.analyze_discussion_async(discussion)
  local prompt = string.format([[
分析以下討論內容：

%s

請提供：
1. 主要觀點總結
2. 爭議焦點識別  
3. 達成的共識
4. 待解決的問題
]], discussion.content)
  
  ai.call_ai_with_rag(prompt, function(response)
    -- 解析回應並更新討論記錄
    -- 這裡可以進一步解析 AI 回應來更新具體字段
    discussion.viewpoints_summary = response
  end)
end

-- 時間計算函數
function M.calculate_start_date(period, end_date)
  local patterns = {
    ["今天"] = 0,
    ["昨天"] = 1,
    ["本週"] = 7,
    ["上週"] = 14, 
    ["本月"] = 30,
    ["上月"] = 60,
    ["季度"] = 90,
    ["年度"] = 365
  }
  
  local days = patterns[period] or 7
  local end_timestamp = os.time()
  local start_timestamp = end_timestamp - (days * 24 * 60 * 60)
  
  return os.date("%Y-%m-%d", start_timestamp)
end

-- 獲取期間內的文件
function M.get_tasks_in_period(start_date, end_date, workspace_dir)
  return M.get_files_in_period(start_date, end_date, workspace_dir .. "/tasks")
end

function M.get_meetings_in_period(start_date, end_date, workspace_dir)
  return M.get_files_in_period(start_date, end_date, workspace_dir .. "/meetings")
end

function M.get_notes_in_period(start_date, end_date, workspace_dir)
  return M.get_files_in_period(start_date, end_date, workspace_dir .. "/notes")
end

function M.get_discussions_in_period(start_date, end_date, workspace_dir)
  return M.get_files_in_period(start_date, end_date, workspace_dir .. "/discussions")
end

function M.get_files_in_period(start_date, end_date, dir)
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end
  
  local files = vim.fn.glob(dir .. "/*.md", 0, 1)
  local result = {}
  
  for _, file in ipairs(files) do
    local stat = vim.uv.fs_stat(file)
    if stat then
      local file_date = os.date("%Y-%m-%d", stat.mtime.sec)
      if file_date >= start_date and file_date <= end_date then
        table.insert(result, {
          path = file,
          name = vim.fn.fnamemodify(file, ":t:r"),
          modified = file_date
        })
      end
    end
  end
  
  return result
end

function M.format_review_details(review_data)
  local details = {}
  
  if #review_data.tasks > 0 then
    table.insert(details, "任務: " .. table.concat(vim.tbl_map(function(t) return t.name end, review_data.tasks), ", "))
  end
  
  if #review_data.meetings > 0 then
    table.insert(details, "會議: " .. table.concat(vim.tbl_map(function(m) return m.name end, review_data.meetings), ", "))
  end
  
  if #review_data.notes > 0 then
    table.insert(details, "筆記: " .. table.concat(vim.tbl_map(function(n) return n.name end, review_data.notes), ", "))
  end
  
  return table.concat(details, "\n")
end

return M
```

### 3.6 Prompt 模板 (templates/prompts.lua)

```lua
local M = {}

-- 意圖分析 prompt
function M.intent_analysis(message)
  return string.format([[
分析用戶輸入的意圖和內容，以 JSON 格式回應：

用戶輸入: "%s"

請識別可能的意圖類型（可多選）：
- question: 問問題、查詢信息
- task: 任務、待辦事項、需要完成的工作
- meeting: 會議、約會、討論安排
- note: 筆記、學習內容、記錄想法
- discussion: 討論、決議、多方觀點
- review: 回顧、總結、分析
- general: 一般對話

同時提取相關信息：

JSON 格式:
{
  "intent": ["task", "meeting"],
  "confidence": 0.9,
  "extracted_info": {
    "task": "具體任務內容",
    "deadline": "時間信息",
    "priority": "high/medium/low",
    "related_people": ["人名1", "人名2"],
    "meeting": "會議相關信息",
    "topic": "主題",
    "datetime": "時間",
    "participants": ["參與者"],
    "technical_topic": "技術主題",
    "mentions_project": "是否提及項目"
  }
}
]], message)
end

-- 任務分析 prompt
function M.task_analysis(task_description)
  return string.format([[
分析以下任務的詳細信息：

任務描述: %s

請提供：
1. 任務的核心目標
2. 所需的技能和知識
3. 預估的時間和難度
4. 可能的風險和挑戰
5. 建議的執行步驟
6. 相關的學習資源建議

請基於已有的筆記和經驗提供具體可行的建議。
]], task_description)
end

-- 會議背景 prompt
function M.meeting_background(topic, context)
  return string.format([[
為即將舉行的會議準備背景資料：

會議主題: %s
相關上下文: %s

請基於已有的筆記、歷史討論和相關項目，提供：

1. **背景信息**
   - 相關的歷史決議
   - 之前的討論要點
   - 當前狀態總結

2. **關鍵問題**
   - 需要討論的核心問題
   - 可能的爭議點
   - 決策所需的信息

3. **建議準備**
   - 會議前需要準備的材料
   - 邀請的關鍵參與者
   - 預期的會議結果

4. **風險提醒**
   - 需要特別注意的事項
   - 可能的阻礙因素

請提供具體、可操作的建議。
]], topic, context or "")
end

-- 筆記關聯 prompt
function M.note_connections(note_title, note_content)
  return string.format([[
分析新筆記與已有知識的關聯：

新筆記標題: %s
新筆記內容: %s

請基於已有的筆記、項目和討論，分析：

1. **概念關聯**
   - 相關的技術概念
   - 類似的問題和解決方案
   - 可以交叉引用的內容

2. **知識連接**
   - 與哪些已有筆記形成互補
   - 哪些概念可以進一步深入
   - 發現的知識盲點

3. **實踐應用**
   - 如何應用到當前項目
   - 潛在的改進機會
   - 值得實驗的想法

4. **學習路徑**
   - 建議接下來學習的內容
   - 相關的高級主題
   - 推薦的實踐練習

請提供具體的關聯點和可行的建議。
]], note_title, note_content)
end

-- 討論分析 prompt
function M.discussion_analysis(discussion_content)
  return string.format([[
分析以下討論的內容：

討論內容: %s

請提供結構化的分析：

1. **觀點梳理**
   - 主要的不同觀點
   - 每個觀點的核心論據
   - 觀點之間的差異

2. **爭議識別**
   - 主要的分歧點
   - 爭議的根本原因
   - 各方關注的重點

3. **共識發現**
   - 各方都同意的部分
   - 可以達成一致的領域
   - 共同的目標和價值

4. **決策建議**
   - 推薦的解決方案
   - 決策的判斷標準
   - 風險評估和緩解措施

5. **後續行動**
   - 需要進一步討論的問題
   - 具體的執行步驟
   - 責任分工建議

請提供客觀、平衡的分析。
]], discussion_content)
end

-- 回顧分析 prompt
function M.review_analysis(period, activities_data)
  return string.format([[
生成%s的工作回顧報告：

活動數據: %s

請提供全面的分析報告：

## 🎯 主要成就
- 完成的重要任務和項目
- 取得的關鍵進展
- 值得慶祝的里程碑

## 📊 效率分析
- 工作模式和時間分配
- 高效和低效的時段識別
- 生產力趨勢分析

## 🔍 模式發現
- 發現的工作規律
- 重複出現的問題類型
- 成功的方法和策略

## ⚠️ 挑戰識別
- 遇到的主要困難
- 未能完成的任務分析
- 需要改進的領域

## 💡 改進建議
- 具體的優化措施
- 工作流程改進
- 技能提升建議

## 🎯 下期重點
- 優先處理的事項
- 新的目標設定
- 資源分配建議

請基於數據提供具體、可操作的洞察。
]], period, activities_data)
end

-- 知識查詢 prompt
function M.knowledge_query(question, context)
  return string.format([[
基於已有的筆記和知識庫回答問題：

問題: %s
上下文: %s

請提供：

1. **直接回答**
   - 基於已有筆記的準確回答
   - 相關的技術細節和概念

2. **補充信息**
   - 相關的背景知識
   - 實際應用示例
   - 最佳實踐建議

3. **關聯內容**
   - 相關的筆記和討論
   - 類似的問題和解決方案
   - 可以深入學習的方向

4. **實踐建議**
   - 如何應用這些知識
   - 推薦的練習和實驗
   - 進一步學習的路徑

請確保回答基於已有的筆記內容，並提供具體可操作的建議。
]], question, context or "")
end

-- 智能建議 prompt
function M.smart_suggestions(current_context, user_activity)
  return string.format([[
基於當前上下文和用戶活動模式，提供智能建議：

當前上下文: %s
用戶活動: %s

請提供：

1. **即時建議**
   - 當前可以採取的行動
   - 需要關注的優先事項
   - 潛在的機會點

2. **效率優化**
   - 工作流程改進建議
   - 時間管理優化
   - 任務排序建議

3. **學習機會**
   - 相關的學習主題
   - 技能提升建議
   - 知識盲點識別

4. **風險提醒**
   - 需要注意的潛在問題
   - 即將到期的任務
   - 可能的阻礙因素

請提供個性化、可操作的建議。
]], current_context, user_activity)
end

-- 錯誤處理 prompt
function M.error_recovery(error_context, user_input)
  return string.format([[
處理錯誤情況並提供友好的回應：

錯誤上下文: %s
用戶輸入: %s

請提供：

1. **友好的錯誤說明**
   - 用易懂的語言解釋發生了什麼
   - 避免技術術語

2. **可能的原因**
   - 常見的導致此問題的原因
   - 用戶可能的誤解

3. **解決建議**
   - 具體的解決步驟
   - 替代的操作方法
   - 預防未來出現同樣問題的建議

4. **繼續協助**
   - 詢問是否需要進一步幫助
   - 提供其他可能有用的功能

保持 FRIDAY 助手的專業和友好語調。
]], error_context, user_input)
end

return M
```

### 3.7 Git 整合模塊 (utils/git.lua)

```lua
local M = {}

-- Git 狀態
M.git_state = {
  is_repo = false,
  hooks_installed = false,
  auto_update_enabled = false,
}

-- 設置 Git 整合
function M.setup(workspace_dir)
  M.workspace_dir = vim.fn.expand(workspace_dir)
  M.check_git_repo()
  
  if M.git_state.is_repo then
    M.install_hooks()
  else
    M.offer_git_init()
  end
end

-- 檢查是否為 Git 倉庫
function M.check_git_repo()
  local git_dir = M.workspace_dir .. "/.git"
  M.git_state.is_repo = vim.fn.isdirectory(git_dir) == 1
end

-- 提供 Git 初始化
function M.offer_git_init()
  local choice = vim.fn.confirm(
    string.format("工作目錄 %s 不是 Git 倉庫，是否初始化？", M.workspace_dir),
    "&是\n&否", 2
  )
  
  if choice == 1 then
    M.init_git_repo()
  end
end

-- 初始化 Git 倉庫
function M.init_git_repo()
  local cmd = string.format("cd '%s' && git init", M.workspace_dir)
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error == 0 then
    M.git_state.is_repo = true
    vim.notify("✅ Git 倉庫初始化成功", vim.log.levels.INFO)
    M.install_hooks()
    
    -- 創建初始 commit
    M.create_initial_commit()
  else
    vim.notify("❌ Git 初始化失敗: " .. result, vim.log.levels.ERROR)
  end
end

-- 創建初始提交
function M.create_initial_commit()
  local commands = {
    string.format("cd '%s'", M.workspace_dir),
    "git add .",
    "git commit -m 'Initial commit: AI companion workspace setup'"
  }
  
  local cmd = table.concat(commands, " && ")
  vim.fn.system(cmd)
end

-- 安裝 Git hooks
function M.install_hooks()
  if M.install_pre_commit_hook() then
    M.git_state.hooks_installed = true
    M.git_state.auto_update_enabled = true
    vim.notify("✅ Git hooks 安裝成功", vim.log.levels.INFO)
  end
end

-- 安裝 pre-commit hook
function M.install_pre_commit_hook()
  local hook_path = M.workspace_dir .. "/.git/hooks/pre-commit"
  local hook_content = M.generate_pre_commit_hook()
  
  -- 備份現有 hook
  if vim.fn.filereadable(hook_path) == 1 then
    local backup_path = hook_path .. ".backup." .. os.date("%Y%m%d_%H%M%S")
    vim.fn.rename(hook_path, backup_path)
    vim.notify("已備份現有 pre-commit hook", vim.log.levels.INFO)
  end
  
  -- 寫入新 hook
  local success = pcall(vim.fn.writefile, vim.split(hook_content, '\n'), hook_path)
  if not success then
    vim.notify("❌ 無法寫入 pre-commit hook", vim.log.levels.ERROR)
    return false
  end
  
  -- 設置執行權限
  local chmod_cmd = string.format("chmod +x '%s'", hook_path)
  vim.fn.system(chmod_cmd)
  
  return vim.v.shell_error == 0
end

-- 生成 pre-commit hook 內容
function M.generate_pre_commit_hook()
  return string.format([[
#!/bin/bash
# AI Companion - Auto-generated pre-commit hook

# 檢查是否有 markdown 文件變化
changed_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|txt|org))

if [ -n "$changed_files" ]; then
    echo "📝 檢測到文檔變化:"
    echo "$changed_files" | sed 's/^/  - /'
    
    echo "🔄 更新 AI 知識庫..."
    
    # 嘗試更新 RAG 索引
    if command -v aichat >/dev/null 2>&1; then
        cd "%s"
        aichat --rag workspace-rag --rebuild >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ AI 知識庫更新完成"
        else
            echo "⚠️ AI 知識庫更新失敗，但不影響提交"
        fi
    else
        echo "⚠️ 未找到 aichat，跳過知識庫更新"
    fi
    
    echo ""
fi

# 繼續正常的提交流程
exit 0
]], M.workspace_dir)
end

-- 檢查 hook 狀態
function M.check_hooks_status()
  local hook_path = M.workspace_dir .. "/.git/hooks/pre-commit"
  
  local status = {
    exists = vim.fn.filereadable(hook_path) == 1,
    executable = false,
    ai_companion = false,
  }
  
  if status.exists then
    -- 檢查執行權限
    local stat = vim.uv.fs_stat(hook_path)
    if stat and stat.mode then
      -- 檢查執行權限 (owner execute bit)
      status.executable = (stat.mode & 64) ~= 0
    end
    
    -- 檢查是否為 AI companion 生成的
    local content = table.concat(vim.fn.readfile(hook_path), '\n')
    status.ai_companion = content:find("AI Companion") ~= nil
  end
  
  return status
end

-- 修復 hooks
function M.repair_hooks()
  if not M.git_state.is_repo then
    vim.notify("❌ 不是 Git 倉庫", vim.log.levels.ERROR)
    return false
  end
  
  local status = M.check_hooks_status()
  
  if not status.exists or not status.ai_companion then
    return M.install_pre_commit_hook()
  elseif not status.executable then
    local hook_path = M.workspace_dir .. "/.git/hooks/pre-commit"
    local chmod_cmd = string.format("chmod +x '%s'", hook_path)
    vim.fn.system(chmod_cmd)
    
    if vim.v.shell_error == 0 then
      vim.notify("✅ Hook 執行權限已修復", vim.log.levels.INFO)
      return true
    else
      vim.notify("❌ 無法修復執行權限", vim.log.levels.ERROR)
      return false
    end
  end
  
  return true
end

-- 手動觸發 RAG 更新
function M.manual_rag_update()
  if not M.git_state.is_repo then
    vim.notify("❌ 不是 Git 倉庫", vim.log.levels.ERROR)
    return
  end
  
  vim.notify("🔄 手動更新 AI 知識庫...", vim.log.levels.INFO)
  
  local cmd = string.format("cd '%s' && aichat --rag workspace-rag --rebuild", M.workspace_dir)
  
  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("✅ AI 知識庫更新完成", vim.log.levels.INFO)
      else
        vim.notify("❌ AI 知識庫更新失敗", vim.log.levels.ERROR)
      end
    end,
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line:match("%S") then
            print("📡 " .. line)
          end
        end
      end
    end,
    stdout_buffered = false,
  })
end

-- Git 狀態報告
function M.get_status_report()
  local status = M.check_hooks_status()
  
  return string.format([[
🔧 **Git 整合狀態**

📁 工作目錄: %s
🗂️ Git 倉庫: %s
🪝 Pre-commit Hook: %s
⚡ 自動更新: %s
🔧 Hook 狀態: %s

%s
]], 
    M.workspace_dir,
    M.git_state.is_repo and "✅ 已初始化" or "❌ 未初始化",
    status.exists and "✅ 已安裝" or "❌ 未安裝",
    M.git_state.auto_update_enabled and "✅ 已啟用" or "❌ 已禁用",
    status.executable and "✅ 可執行" or "⚠️ 權限問題",
    M.get_troubleshooting_tips(status)
  )
end

-- 故障排除提示
function M.get_troubleshooting_tips(status)
  local tips = {}
  
  if not M.git_state.is_repo then
    table.insert(tips, "💡 運行 :lua require('lib.ai-companion.utils.git').init_git_repo() 初始化")
  end
  
  if not status.exists then
    table.insert(tips, "💡 運行 :lua require('lib.ai-companion.utils.git').install_hooks() 安裝 hooks")
  end
  
  if status.exists and not status.executable then
    table.insert(tips, "💡 運行 :lua require('lib.ai-companion.utils.git').repair_hooks() 修復權限")
  end
  
  if #tips == 0 then
    table.insert(tips, "✅ 所有功能正常")
  end
  
  return table.concat(tips, "\n")
end

-- 創建用戶命令
function M.create_commands()
  vim.api.nvim_create_user_command('AiGitStatus', function()
    print(M.get_status_report())
  end, { desc = "顯示 Git 整合狀態" })
  
  vim.api.nvim_create_user_command('AiGitRepair', function()
    M.repair_hooks()
  end, { desc = "修復 Git hooks" })
  
  vim.api.nvim_create_user_command('AiRagUpdate', function()
    M.manual_rag_update()
  end, { desc = "手動更新 AI 知識庫" })
end

return M
```

### 3.8 aichat 配置管理 (utils/aichat.lua)

```lua
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
  
  -- 測試 aichat 基本功能
  local test_cmd = 'aichat "測試連接" 2>&1'
  local result = vim.fn.system(test_cmd)
  
  if vim.v.shell_error == 0 then
    vim.notify("✅ aichat 配置測試通過", vim.log.levels.INFO)
    return true
  else
    vim.notify("❌ aichat 測試失敗: " .. result, vim.log.levels.ERROR)
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
```

## 4. 安裝和使用指南

### 4.1 安裝步驟

1. **安裝依賴工具**
```bash
# 安裝 aichat
cargo install aichat

# 或使用 homebrew (macOS)
brew install aichat

# 確認安裝
aichat --version
```

2. **配置 API 密鑰**
```bash
# 設置 OpenAI API 密鑰（用於 embedding）
export OPENAI_API_KEY="your-api-key"

# 設置 Anthropic API 密鑰（用於 Claude）
export ANTHROPIC_API_KEY="your-api-key"
```

3. **安裝插件**
```lua
-- 在 LazyVim 配置中添加
return {
  {
    "ai-companion.nvim",
    dir = vim.fn.stdpath("config") .. "/lua/lib/ai-companion",
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
      require('lib.ai-companion').setup(opts)
    end
  }
}
```

### 4.2 基本使用

1. **啟動對話**
```
按 <leader><space> 開始與 AI 對話
```

2. **自然語言交互**
```
"明天要開會討論新功能"
"記錄一下今天學的優化技巧"  
"這週工作怎麼樣？"
"幫我分析一下這個問題"
```

3. **查看狀態**
```
:AiStatus    - AI 狀態
:AiGitStatus - Git 整合狀態
:AiConfigStatus - 配置狀態
```

### 4.3 故障排除

**常見問題**:
1. `aichat 命令不存在` - 需要安裝 aichat
2. `API 密鑰錯誤` - 檢查環境變量設置
3. `RAG 初始化失敗` - 確認工作目錄權限
4. `Git hooks 不工作` - 運行 `:AiGitRepair`

## 5. 測試用例

### 5.1 基本功能測試
- [ ] 對話界面正常打開和關閉
- [ ] AI 回應正常生成
- [ ] 任務創建和保存
- [ ] 會議記錄創建
- [ ] 筆記保存和關聯分析

### 5.2 Git 整合測試
- [ ] 自動檢測 Git 倉庫
- [ ] pre-commit hook 正確安裝
- [ ] 文件變更觸發 RAG 更新
- [ ] 手動 RAG 更新功能

### 5.3 AI 功能測試
- [ ] RAG 初始化成功
- [ ] 基於筆記的問答準確
- [ ] 意圖識別正確
- [ ] JSON 解析處理
- [ ] 錯誤恢復機制

### 5.4 配置測試
- [ ] 默認配置正確應用
- [ ] 用戶配置正確合併
- [ ] aichat 配置自動生成
- [ ] 配置驗證功能

## 6. 性能考慮

### 6.1 響應時間優化
- AI 調用使用異步處理
- 本地快速回應優先
- 背景任務不阻塞界面

### 6.2 資源使用
- 會話歷史自動清理
- 大文件分塊處理
- 內存使用監控

### 6.3 錯誤處理
- 網絡錯誤重試機制
- API 限制處理
- 降級功能保證基本可用

---

**這份規格文檔包含了完整的實現細節，Claude Code 可以根據這些精確的規格直接生成高質量的代碼。所有的函數簽名、錯誤處理、用戶交互都已詳細定義，確保實現的 deterministic 性。**
