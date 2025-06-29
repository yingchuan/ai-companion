local M = {}
local ai = require('ai-companion.core.ai')
local content = require('ai-companion.core.content')
local prompts = require('ai-companion.templates.prompts')

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
function M.process_review(_, intent_result, callback)
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
function M.process_general(message, _, callback)
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
  local workspace_dir = vim.fn.expand(require('ai-companion').config.workspace_dir)
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
