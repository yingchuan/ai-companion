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
  
  local workspace_dir = vim.fn.expand(require('ai-companion').config.workspace_dir)
  
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