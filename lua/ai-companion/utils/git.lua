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
changed_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|txt|org)$')

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
      status.executable = (bit.band(stat.mode, 64) ~= 0)
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
    table.insert(tips, "💡 運行 :lua require('ai-companion.utils.git').init_git_repo() 初始化")
  end

  if not status.exists then
    table.insert(tips, "💡 運行 :lua require('ai-companion.utils.git').install_hooks() 安裝 hooks")
  end

  if status.exists and not status.executable then
    table.insert(tips, "💡 運行 :lua require('ai-companion.utils.git').repair_hooks() 修復權限")
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
