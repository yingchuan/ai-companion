local M = {}
local ai = require('ai-companion.core.ai')

-- 創建任務
function M.create_task(task_info, original_message)
  local workspace_dir = vim.fn.expand(require('ai-companion').config.workspace_dir)

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
  local workspace_dir = vim.fn.expand(require('ai-companion').config.workspace_dir)

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
  local workspace_dir = vim.fn.expand(require('ai-companion').config.workspace_dir)

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
  local workspace_dir = vim.fn.expand(require('ai-companion').config.workspace_dir)

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
  local workspace_dir = vim.fn.expand(require('ai-companion').config.workspace_dir)
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
function M.calculate_start_date(period, _)
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
