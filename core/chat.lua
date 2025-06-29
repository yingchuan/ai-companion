local M = {}

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
  vim.cmd('resize ' .. require('ai-companion').config.ui.chat_height)
  
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
    completion = 'customlist,v:lua.require("ai-companion.core.chat").input_completion',
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
  require('ai-companion.core.intent').process_user_message(message, function(response)
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

-- 聚焦對話
function M.focus_chat()
  if M.chat_state.chat_win and vim.api.nvim_win_is_valid(M.chat_state.chat_win) then
    vim.api.nvim_set_current_win(M.chat_state.chat_win)
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

-- 歷史記錄導航
function M.previous_input()
  -- TODO: 實現輸入歷史向上導航
  vim.notify("功能開發中", vim.log.levels.INFO)
end

function M.next_input()
  -- TODO: 實現輸入歷史向下導航
  vim.notify("功能開發中", vim.log.levels.INFO)
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