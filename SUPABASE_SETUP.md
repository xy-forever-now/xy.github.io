# Supabase 多人协作配置指南

## 🚀 快速开始(5分钟搞定)

### 1. 注册 Supabase

访问 [https://supabase.com](https://supabase.com) 点击 "Start your project"

- 可用 GitHub 账号登录
- 免费套餐足够使用

### 2. 创建项目

1. 点击 "New Project"
2. 填写:
   - **Name**: xy-calendar (任意)
   - **Database Password**: 设置一个密码(记住它)
   - **Region**: 选择 `Asia Pacific (Singapore)` 或 `Tokyo` (国内访问快)
3. 点击 "Create new project"
4. 等待 1-2 分钟初始化

### 3. 获取 API 密钥

项目创建完成后:

1. 左侧菜单点击 ⚙️ **Settings** → **API**
2. 复制以下两个值:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 4. 创建数据库表

左侧菜单点击 **SQL Editor** → **New query**,执行以下 SQL:

```sql
-- 日历数据表
CREATE TABLE calendar (
  dateKey TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 纪念日表
CREATE TABLE anniversaries (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 倒计时表
CREATE TABLE countdowns (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 天气数据表
CREATE TABLE weather (
  city TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 天气城市列表表
CREATE TABLE weather_cities (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 天气设置表
CREATE TABLE weather_settings (
  id TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 启用实时订阅
ALTER PUBLICATION supabase_realtime ADD TABLE calendar;
ALTER PUBLICATION supabase_realtime ADD TABLE anniversaries;
ALTER PUBLICATION supabase_realtime ADD TABLE countdowns;
ALTER PUBLICATION supabase_realtime ADD TABLE weather;
ALTER PUBLICATION supabase_realtime ADD TABLE weather_cities;
ALTER PUBLICATION supabase_realtime ADD TABLE weather_settings;
```

点击 **Run** 执行。

### 5. 配置权限(允许匿名读写)

在 SQL Editor 中执行:

```sql
-- 允许所有人读取
GRANT SELECT ON calendar TO anon;
GRANT SELECT ON anniversaries TO anon;
GRANT SELECT ON countdowns TO anon;

-- 允许所有人写入
GRANT INSERT, UPDATE, DELETE ON calendar TO anon;
GRANT INSERT, UPDATE, DELETE ON anniversaries TO anon;
GRANT INSERT, UPDATE, DELETE ON countdowns TO anon;
GRANT INSERT, UPDATE, DELETE ON weather TO anon;
GRANT INSERT, UPDATE, DELETE ON weather_cities TO anon;
GRANT INSERT, UPDATE, DELETE ON weather_settings TO anon;
```

点击 **Run**。

⚠️ **注意**: 这是公开模式,适合团队内部。如需权限控制,后续可启用 RLS。

### 6. 修改代码

打开 `index.html`,找到第 12-14 行:

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

替换为:

```javascript
const SUPABASE_URL = 'https://你的项目.supabase.co';
const SUPABASE_ANON_KEY = '你的anon密钥';
```

### 7. 启用实时同步

找到这一行(约第 2100 行):

```javascript
const SUPABASE_ENABLED = false;
```

改为:

```javascript
const SUPABASE_ENABLED = true; // ✅ 已启用
```

### 8. 测试!

1. 浏览器 A 打开 `index.html`
2. 浏览器 B (或手机)打开同一页面
3. 在 A 中添加数据
4. B 应该**自动实时更新**!

---

## 📊 功能说明

### 实时同步的数据
- ✅ 日历打卡记录（含备注、附件元数据）
- ✅ 备注和笔记  
- ✅ 纪念日（添加、修改、删除）
- ✅ 倒计时（添加、修改、删除）
- ✅ 天气数据（城市列表、设置）
- ⚠️ 大文件附件（仅本地 IndexedDB，不同步）

### 数据同步机制

**本地优先架构：**
```
用户操作 → IndexedDB (主存储) → Supabase 云端 (同步)
                                    ↓
其他设备 ← 实时订阅 (WebSocket) ← 云端数据库
```

**同步流程：**
1. **写入操作**：先保存到本地 IndexedDB，然后异步同步到 Supabase
2. **读取操作**：优先从云端加载最新数据，降级到本地 IndexedDB
3. **实时更新**：通过 WebSocket 监听云端变化，自动更新本地数据
4. **防循环机制**：使用 `isRemoteUpdate` 标志避免同步死循环
5. **批量优化**：纪念日、倒计时等使用批量同步提高性能

**关键特性：**
- 🔄 **双向同步**：本地 ↔ 云端实时保持一致
- ⚡ **毫秒级延迟**：WebSocket 实时推送
- 💾 **离线支持**：无网络时使用本地数据，联网后自动同步
- 🛡️ **冲突处理**：最后写入获胜（Last Write Wins）
- 📦 **增量同步**：只同步变化的数据，提高效率

### 优势
- 🇨🇳 **国内速度快** - 新加坡/东京节点
- 💰 **免费额度大** - 500MB 数据库,2GB 文件存储
- 🔥 **实时性好** - WebSocket 推送
- 💾 **离线支持** - 本地优先,联网同步

---

## 🔐 安全加固(可选)

如果需要限制访问,启用 RLS(Row Level Security):

```sql
-- 启用 RLS
ALTER TABLE calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE anniversaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE countdowns ENABLE ROW LEVEL SECURITY;

-- 创建策略:允许所有人读写(简单模式)
CREATE POLICY "Allow all access" ON calendar FOR ALL USING (true);
CREATE POLICY "Allow all access" ON anniversaries FOR ALL USING (true);
CREATE POLICY "Allow all access" ON countdowns FOR ALL USING (true);
```

更严格的控制需要配合 Supabase Auth 使用。

---

## 💰 费用

Supabase 免费套餐:
- **数据库**: 500 MB
- **文件存储**: 2 GB  
- **带宽**: 2 GB/月
- **实时连接**: 200 个并发

小团队(5-20人)完全够用!

---

## ❓ 常见问题

### Q: 为什么没有同步?
检查:
1. `SUPABASE_ENABLED` 是否为 `true`
2. URL 和 Key 是否正确
3. 数据库表是否创建
4. 浏览器控制台是否有错误

### Q: 数据会丢失吗?
不会!数据保存在:
1. 本地 IndexedDB(主要)
2. Supabase 云端(备份+同步)

### Q: 可以关闭同步吗?
可以,将 `SUPABASE_ENABLED` 改为 `false` 即可。

### Q: 多人同时编辑冲突怎么办？
Supabase 使用“最后写入获胜”策略。对于日历应用，冲突概率极低。

### Q: 如何检查数据同步状态？
打开 `sync_status_check.html` 文件，复制检查代码到浏览器控制台执行，即可查看本地和云端数据对比。

### Q: 为什么有些数据没有同步？
1. 检查 `SUPABASE_ENABLED` 是否为 `true`
2. 查看浏览器控制台是否有同步错误
3. 确认网络连接正常
4. 大文件附件（>5MB）仅本地存储，不会同步

---

## 🎉 完成!

现在享受多人实时协作:
- 👥 团队成员同时编辑
- 🔄 毫秒级同步
- 📱 任何设备访问
- 🇨🇳 国内访问流畅

开始协作吧! 🚀
