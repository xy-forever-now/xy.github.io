# 🔧 Supabase 实时同步诊断和修复指南

## 📋 问题诊断清单

### ✅ 已修复的问题
1. **防抖函数变量引用错误** - `window.supabase` → `window.mySupabase`
2. **异步时序问题** - 添加 `await load()` 等待数据加载完成
3. **同步函数变量引用错误** - 修复了4个同步函数的变量引用

### 🔍 需要检查的问题

## 🚀 快速诊断步骤

### 步骤1：检查 Supabase 连接状态

打开浏览器控制台，检查是否有这些日志：
```
✅ Supabase 初始化成功
✅ Supabase 实时同步已启动 - 多人协作模式
```

如果看到错误，可能是：
- ❌ Supabase SDK 未正确加载
- ❌ Supabase URL 或密钥配置错误

### 步骤2：使用诊断工具

1. 打开 `D:\software\SVN\xy\debug-supabase.html`
2. 点击"运行完整诊断"
3. 查看诊断报告

### 步骤3：检查云端数据

在 Supabase 控制台检查：
1. 登录 https://supabase.com/dashboard
2. 选择你的项目
3. 打开 Table Editor
4. 检查这些表是否有数据：
   - `calendar`
   - `anniversaries`
   - `countdowns`

## ⚠️ 常见问题和解决方案

### 问题1：实时同步不工作

**可能原因：**
- Supabase 表没有启用实时复制
- RLS (Row Level Security) 策略阻止了访问
- 实时监听器没有正确启动

**解决方案：**

#### 1.1 启用表的实时复制

在 Supabase 控制台：
1. 进入 Database → Replication
2. 找到 `Realtime` 部分
3. 启用这些表的实时复制：
   - ✅ `calendar`
   - ✅ `anniversaries`
   - ✅ `countdowns`

#### 1.2 检查 RLS 策略

在 Supabase 控制台：
1. 进入 Database → Tables
2. 选择表（如 `calendar`）
3. 点击 "RLS Policies"
4. 确保有允许匿名访问的策略：

```sql
-- 允许所有人选择数据
CREATE POLICY "Allow anonymous access"
ON "public"."calendar"
FOR SELECT
TO anon
USING (true);

-- 允许所有人插入数据
CREATE POLICY "Allow anonymous insert"
ON "public"."calendar"
FOR INSERT
TO anon
WITH CHECK (true);

-- 允许所有人更新数据
CREATE POLICY "Allow anonymous update"
ON "public"."calendar"
FOR UPDATE
TO anon
USING (true);

-- 允许所有人删除数据
CREATE POLICY "Allow anonymous delete"
ON "public"."calendar"
FOR DELETE
TO anon
USING (true);
```

对 `anniversaries` 和 `countdowns` 表执行相同操作。

### 问题2：数据没有同步到云端

**检查步骤：**
1. 在浏览器中添加一些数据（纪念日、倒计时等）
2. 打开 Supabase 控制台
3. 查看相应的表是否增加了数据

**如果没有数据：**
- 检查 `SUPABASE_ENABLED` 是否为 `true`
- 检查控制台是否有同步失败的错误
- 检查网络连接

### 问题3：两个浏览器看到的数据不一致

**可能原因：**
1. 实时监听器没有启动
2. 表的实时复制未启用
3. 数据没有成功同步到云端

**解决步骤：**
1. 在浏览器A中添加数据
2. 立即在 Supabase 控制台检查是否看到数据
3. 在浏览器B中刷新页面，检查是否看到数据
4. 如果浏览器B能看到数据，说明云端同步正常
5. 但如果浏览器B需要刷新才能看到，说明实时监听有问题

## 🧪 测试实时同步

### 方法1：使用诊断工具
1. 在浏览器A中打开 `debug-supabase.html`
2. 点击"测试实时同步"
3. 在浏览器B中打开主应用，添加一些数据
4. 观察浏览器A是否收到实时更新

### 方法2：使用两个浏览器窗口
1. 浏览器A：打开主应用
2. 浏览器B：打开主应用（无痕模式）
3. 浏览器A：添加一个纪念日
4. 浏览器B：应该立即看到新增的纪念日（无需刷新）

### 方法3：检查控制台日志
在浏览器B的控制台应该看到：
```
📥 接收到远程纪念日更新
📥 接收到远程倒计时更新
```

## 📊 数据同步流程图

```
用户A操作 → 本地IndexedDB → Supabase云端 → WebSocket推送 → 用户B实时更新
   ↓            ↓                ↓                ↓              ↓
 添加数据    立即保存         后台同步          实时监听        自动渲染
```

## 🔧 高级调试

### 检查实时监听器状态

在浏览器控制台运行：
```javascript
// 检查 Supabase 客户端
console.log('Supabase 客户端:', window.mySupabase);

// 检查实时监听器状态
console.log('Supabase 启用状态:', typeof SUPABASE_ENABLED !== 'undefined' ? SUPABASE_ENABLED : '未定义');

// 手动触发实时监听
if (typeof setupRealtimeListeners === 'function') {
  console.log('手动启动实时监听器...');
  setupRealtimeListeners();
}
```

### 检查本地存储数据

```javascript
// 检查 IndexedDB 中的数据
indexedDB.open('dailyCheckinDB_v2', 2).onsuccess = (e) => {
  const db = e.target.result;

  // 检查纪念日
  const tx = db.transaction('anniversaries', 'readonly');
  const store = tx.objectStore('anniversaries');
  const request = store.getAll();
  request.onsuccess = () => console.log('本地纪念日数据:', request.result);

  // 检查倒计时
  const tx2 = db.transaction('countdowns', 'readonly');
  const store2 = tx2.objectStore('countdowns');
  const request2 = store2.getAll();
  request2.onsuccess = () => console.log('本地倒计时数据:', request2.result);
};
```

## 🎯 验证修复成功的标准

### ✅ 数据持久化正常
- 添加数据后刷新页面，数据仍然存在
- IndexedDB 中有正确保存数据

### ✅ 云端同步正常
- 在 Supabase 控制台能看到所有数据
- 添加数据后立即在 Supabase 控制台显示

### ✅ 实时同步正常
- 两个浏览器同时打开，无需刷新即可看到对方的数据变化
- 控制台显示 "收到远程更新" 日志

### ✅ 错误处理正常
- 网络断开时，数据仍能保存到本地
- 网络恢复后，自动同步到云端

## 📞 需要进一步帮助？

如果以上步骤都完成后仍有问题，请提供：
1. 浏览器控制台的错误日志
2. 诊断工具的报告结果
3. Supabase 控制台的表结构和数据
4. 具体的操作步骤和现象描述

---

**最后更新：** 2026-05-17
**适用版本：** dailyCheckinDB_v2
