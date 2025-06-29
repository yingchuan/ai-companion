local M = {}

-- 字符串工具
function M.trim(str)
  return str:match("^%s*(.-)%s*$")
end

function M.split(str, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  for part in str:gmatch(pattern) do
    table.insert(result, part)
  end
  return result
end

function M.starts_with(str, prefix)
  return str:sub(1, #prefix) == prefix
end

function M.ends_with(str, suffix)
  return suffix == "" or str:sub(-#suffix) == suffix
end

-- 表工具
function M.table_merge(t1, t2)
  local result = {}
  for k, v in pairs(t1) do
    result[k] = v
  end
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

function M.table_contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function M.table_keys(table)
  local keys = {}
  for key, _ in pairs(table) do
    table.insert(keys, key)
  end
  return keys
end

-- 文件系統工具
function M.file_exists(path)
  return vim.fn.filereadable(path) == 1
end

function M.dir_exists(path)
  return vim.fn.isdirectory(path) == 1
end

function M.ensure_dir(path)
  if not M.dir_exists(path) then
    vim.fn.mkdir(path, "p")
  end
end

function M.get_file_extension(path)
  return vim.fn.fnamemodify(path, ":e")
end

function M.get_filename(path)
  return vim.fn.fnamemodify(path, ":t")
end

function M.get_dirname(path)
  return vim.fn.fnamemodify(path, ":h")
end

-- 時間工具
function M.format_timestamp(timestamp)
  return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

function M.format_date(timestamp)
  return os.date("%Y-%m-%d", timestamp)
end

function M.get_relative_time(timestamp)
  local now = os.time()
  local diff = now - timestamp
  
  if diff < 60 then
    return "剛才"
  elseif diff < 3600 then
    return math.floor(diff / 60) .. " 分鐘前"
  elseif diff < 86400 then
    return math.floor(diff / 3600) .. " 小時前"
  elseif diff < 2592000 then
    return math.floor(diff / 86400) .. " 天前"
  else
    return M.format_date(timestamp)
  end
end

-- 文本處理工具
function M.extract_keywords(text)
  local keywords = {}
  local common_words = {
    ["的"] = true, ["是"] = true, ["在"] = true, ["有"] = true, ["和"] = true,
    ["了"] = true, ["要"] = true, ["我"] = true, ["你"] = true, ["他"] = true,
    ["她"] = true, ["它"] = true, ["我們"] = true, ["你們"] = true, ["他們"] = true,
    ["這"] = true, ["那"] = true, ["這個"] = true, ["那個"] = true, ["可以"] = true,
    ["能夠"] = true, ["應該"] = true, ["需要"] = true, ["想要"] = true, ["希望"] = true,
  }
  
  for word in text:gmatch("[%w]+") do
    if #word > 1 and not common_words[word] then
      table.insert(keywords, word)
    end
  end
  
  return keywords
end

function M.summarize_text(text, max_length)
  max_length = max_length or 100
  if #text <= max_length then
    return text
  end
  
  local summary = text:sub(1, max_length)
  local last_space = summary:find(" [^ ]*$")
  if last_space then
    summary = summary:sub(1, last_space - 1)
  end
  
  return summary .. "..."
end

function M.count_words(text)
  local count = 0
  for _ in text:gmatch("[%w]+") do
    count = count + 1
  end
  return count
end

-- 路徑工具
function M.normalize_path(path)
  -- 展開 ~ 為用戶主目錄
  if M.starts_with(path, "~/") then
    path = vim.fn.expand("~") .. path:sub(2)
  end
  
  -- 移除重複的斜杠
  path = path:gsub("//+", "/")
  
  -- 移除尾部斜杠（除非是根目錄）
  if path ~= "/" and M.ends_with(path, "/") then
    path = path:sub(1, -2)
  end
  
  return path
end

function M.join_paths(...)
  local paths = {...}
  local result = paths[1] or ""
  
  for i = 2, #paths do
    local path = paths[i]
    if path and path ~= "" then
      if not M.ends_with(result, "/") then
        result = result .. "/"
      end
      if M.starts_with(path, "/") then
        path = path:sub(2)
      end
      result = result .. path
    end
  end
  
  return M.normalize_path(result)
end

-- ID 生成工具
function M.generate_uuid()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format('%x', v)
  end)
end

function M.generate_short_id(length)
  length = length or 8
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local result = ""
  
  for i = 1, length do
    local index = math.random(1, #chars)
    result = result .. chars:sub(index, index)
  end
  
  return result
end

-- 錯誤處理工具
function M.safe_call(func, ...)
  local ok, result = pcall(func, ...)
  if ok then
    return result
  else
    vim.notify("錯誤: " .. tostring(result), vim.log.levels.ERROR)
    return nil
  end
end

function M.with_timeout(func, timeout_ms, callback)
  local timer = vim.loop.new_timer()
  local completed = false
  
  timer:start(timeout_ms, 0, function()
    if not completed then
      completed = true
      timer:close()
      callback("timeout")
    end
  end)
  
  M.safe_call(function()
    local result = func()
    if not completed then
      completed = true
      timer:close()
      callback(nil, result)
    end
  end)
end

-- 配置工具
function M.deep_merge(base, override)
  local result = vim.deepcopy(base)
  
  for key, value in pairs(override) do
    if type(value) == "table" and type(result[key]) == "table" then
      result[key] = M.deep_merge(result[key], value)
    else
      result[key] = value
    end
  end
  
  return result
end

function M.validate_config(config, schema)
  local errors = {}
  
  for key, spec in pairs(schema) do
    local value = config[key]
    
    if spec.required and value == nil then
      table.insert(errors, string.format("缺少必需配置項: %s", key))
    elseif value ~= nil then
      if spec.type and type(value) ~= spec.type then
        table.insert(errors, string.format("配置項 %s 類型錯誤，期望 %s，實際 %s", 
          key, spec.type, type(value)))
      end
      
      if spec.validator and not spec.validator(value) then
        table.insert(errors, string.format("配置項 %s 驗證失敗", key))
      end
    end
  end
  
  return #errors == 0, errors
end

-- 調試工具
function M.dump(obj, name)
  name = name or "object"
  print(string.format("=== %s ===", name))
  print(vim.inspect(obj))
  print("==================")
end

function M.measure_time(func, name)
  name = name or "function"
  local start_time = vim.loop.hrtime()
  local result = func()
  local end_time = vim.loop.hrtime()
  local duration = (end_time - start_time) / 1000000 -- 轉換為毫秒
  
  print(string.format("%s 執行時間: %.2f ms", name, duration))
  return result
end

-- 緩存工具
function M.create_cache(max_size)
  max_size = max_size or 100
  local cache = {
    data = {},
    access_order = {},
    max_size = max_size
  }
  
  function cache:get(key)
    local value = self.data[key]
    if value then
      -- 更新訪問順序
      self:_update_access(key)
      return value
    end
    return nil
  end
  
  function cache:set(key, value)
    self.data[key] = value
    self:_update_access(key)
    self:_cleanup()
  end
  
  function cache:_update_access(key)
    -- 移除舊的訪問記錄
    for i, k in ipairs(self.access_order) do
      if k == key then
        table.remove(self.access_order, i)
        break
      end
    end
    -- 添加到末尾（最新訪問）
    table.insert(self.access_order, key)
  end
  
  function cache:_cleanup()
    while #self.access_order > self.max_size do
      local old_key = table.remove(self.access_order, 1)
      self.data[old_key] = nil
    end
  end
  
  return cache
end

return M