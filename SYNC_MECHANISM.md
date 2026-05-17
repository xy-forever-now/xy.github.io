# 数据同步机制说明

## ✅ 已实现的同步功能

### 1. 日历数据 (Calendar)
- **本地存储**: IndexedDB (`calendar` store)
- **云端表**: `public.calendar`
- **同步方式**: 
  - 写入: `syncCalendarToSupabase(dateKey, data)` - 实时同步
  - 读取: `loadFromSupabase()` - 优先从云端加载
  - 删除: 传入 `null` 数据自动删除云端记录
- **实时更新**: 监听 `calendar_changes` channel

### 2. 纪念日 (Anniversaries)
- **本地存储**: IndexedDB (`anniversaries` store)
- **云端表**: `public.anniversaries`
- **同步方式**:
  - 写入: `syncAnniversaryToSupabase(anniversary)` - 批量同步
  - 读取: `loadAnniversaries()` - 优先从云端加载
  - 删除: `removeAnniversaryFromSupabase(id)`
- **实时更新**: 监听 `anniversary_changes` channel

### 3. 倒计时 (Countdowns)
- **本地存储**: IndexedDB (`countdowns` store)
- **云端表**: `public.countdowns`
- **同步方式**:
  - 写入: `syncCountdownToSupabase(countdown)` - 批量同步
  - 读取: `loadCountdowns()` - 优先从云端加载
  - 删除: `removeCountdownFromSupabase(id)`
- **实时更新**: 监听 `countdown_changes` channel

### 4. 天气数据 (Weather)
#### 4.1 城市天气数据
- **本地存储**: IndexedDB (`weather` store)
- **云端表**: `public.weather`
- **同步方式**: `syncWeatherToSupabase()` - 批量同步所有城市
- **实时更新**: 监听 `weather_changes` channel

#### 4.2 城市列表
- **本地存储**: 内存变量 `weatherCities`
- **云端表**: `public.weather_cities`
- **同步方式**: 包含在 `syncWeatherToSupabase()` 中
- **实时更新**: 监听 `weather_cities_changes` channel

#### 4.3 用户设置
- **本地存储**: 内存变量 `activeWeatherCity`, `selectedWeatherDate`
- **云端表**: `public.weather_settings`
- **同步方式**: 包含在 `syncWeatherToSupabase()` 和 `switchToCity()` 中
- **实时更新**: 监听 `weather_settings_changes` channel

---

## 🔄 同步流程

### 写入流程（以日历为例）
```javascript
// 1. 用户操作触发保存
async function saveDay() {
  // 2. 保存到本地 IndexedDB
  await idbCalendarPut({ dateKey, data });
  
  // 3. 同步到 Supabase
  await syncCalendarToSupabase(dateKey, data);
}

// 4. syncCalendarToSupabase 内部逻辑
async function syncCalendarToSupabase(dateKey, data) {
  if (isRemoteUpdate) return; // 防止循环
  
  isRemoteUpdate = true;
  try {
    if (data === null) {
      // 删除操作
      await window.mySupabase.from('calendar').delete().eq('dateKey', dateKey);
    } else {
      // 插入/更新操作
      await window.mySupabase.from('calendar').upsert({
        dateKey, 
        data, 
        updated_at: new Date().toISOString()
      });
    }
  } finally {
    setTimeout(() => { isRemoteUpdate = false; }, 100);
  }
}
```

### 读取流程
```javascript
async function load() {
  // 1. 先从本地 IndexedDB 加载
  const calendarRecords = await idbCalendarGetAll();
  
  // 2. 如果启用 Supabase，优先从云端加载最新数据
  if (SUPABASE_ENABLED) {
    await loadFromSupabase(); // 云端数据会覆盖本地
    
    // 3. 重新从 IndexedDB 加载（此时已是云端同步后的数据）
    const syncedRecords = await idbCalendarGetAll();
    store = {};
    syncedRecords.forEach(rec => { store[rec.dateKey] = rec.data; });
  }
}
```

### 实时更新流程
```javascript
// 监听云端变化
window.mySupabase
  .channel('calendar_changes')
  .on('postgres_changes', 
    { event: '*', schema: 'public', table: 'calendar' },
    async (payload) => {
      if (isRemoteUpdate) return; // 防止处理自己的更新
      
      isRemoteUpdate = true;
      
      // 根据事件类型处理
      if (payload.eventType === 'DELETE') {
        delete store[payload.old.dateKey];
        await idbCalendarDelete(payload.old.dateKey);
      } else if (payload.new) {
        store[payload.new.dateKey] = payload.new.data;
        await idbCalendarPut({ 
          dateKey: payload.new.dateKey, 
          data: payload.new.data 
        });
      }
      
      renderMonth(); // 刷新UI
      
      setTimeout(() => { isRemoteUpdate = false; }, 100);
    }
  )
  .subscribe();
```

---

## 🛡️ 防循环机制

使用全局标志 `isRemoteUpdate` 防止同步死循环：

```javascript
let isRemoteUpdate = false;

// 本地操作 → 同步到云端
async function localOperation() {
  if (isRemoteUpdate) return; // 如果是远程触发的，跳过
  
  isRemoteUpdate = true;
  try {
    // 执行本地操作
    await saveToIndexedDB();
    
    // 同步到云端
    await syncToSupabase();
  } finally {
    setTimeout(() => { isRemoteUpdate = false; }, 100);
  }
}

// 远程更新 → 更新本地
channel.on('postgres_changes', async (payload) => {
  if (isRemoteUpdate) return; // 如果是自己触发的，跳过
  
  isRemoteUpdate = true;
  try {
    // 更新本地数据
    await updateLocalData();
    renderUI();
  } finally {
    setTimeout(() => { isRemoteUpdate = false; }, 100);
  }
});
```

---

## ⚠️ 不同步的数据

### 大文件附件
- **原因**: Supabase 免费套餐存储空间有限（2GB）
- **策略**: 
  - 小文件 (<5MB): Base64 编码后同步到云端
  - 大文件 (>5MB): 仅存储在本地 IndexedDB
- **标记**: 
  - `meta.isSynced = true` - 已同步
  - `meta.isLocalOnly = true` - 仅本地

---

## 📊 检查同步状态

打开 `sync_status_check.html`，复制代码到浏览器控制台执行：

```javascript
async function checkSyncStatus() {
  // 检查各表的本地和云端数据量
  const results = {};
  
  // 日历
  results.calendar = {
    local: Object.keys(store || {}).length,
    cloud: (await window.mySupabase.from('calendar').select('*')).data?.length || 0
  };
  
  // 纪念日、倒计时、天气...
  
  console.table(results);
  return results;
}

checkSyncStatus();
```

---

## 🔧 故障排查

### 问题1: 数据没有同步
**检查清单**:
1. ✅ `SUPABASE_ENABLED === true`
2. ✅ `window.mySupabase` 已初始化
3. ✅ 数据库表已创建
4. ✅ 网络连接正常
5. ✅ 浏览器控制台无错误

### 问题2: 同步冲突
**解决方案**:
- Supabase 使用"最后写入获胜"策略
- 对于日历应用，冲突概率极低
- 如需更强一致性，可添加版本号字段

### 问题3: 实时不更新
**检查**:
1. WebSocket 连接是否正常
2. RLS 策略是否允许订阅
3. 是否启用了 Realtime 功能

---

## 📝 最佳实践

1. **始终先写本地**: 保证离线可用性
2. **异步同步云端**: 不阻塞用户操作
3. **错误容错**: 同步失败不影响本地使用
4. **批量优化**: 多条记录使用批量同步
5. **防循环**: 正确使用 `isRemoteUpdate` 标志

---

## 🎯 总结

当前系统实现了完整的双向数据同步：
- ✅ 本地优先架构
- ✅ 实时双向同步
- ✅ 离线支持
- ✅ 多设备协作
- ✅ 冲突处理
- ✅ 性能优化

所有关键数据（日历、纪念日、倒计时、天气）都能在本地和云端保持一致！

