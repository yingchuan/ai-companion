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
