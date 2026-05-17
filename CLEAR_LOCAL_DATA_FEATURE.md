# 清空本地数据功能说明

## ✅ 功能已实现

### 📍 按钮位置
在应用左侧边栏底部，"倒计时"区域下方，新增了"🗄️ 数据管理"区域，包含：
- **🗑️ 清空本地数据** 按钮

### 🔧 功能特性

#### 1. 双重确认机制
点击按钮后会弹出两次确认对话框：
- **第一次确认**：告知用户将清空哪些数据
- **第二次确认**：再次警告无法恢复

#### 2. 清空范围
清空以下所有本地 IndexedDB 数据：
- ✅ 日历打卡记录（store）
- ✅ 备注和附件文件
- ✅ 纪念日列表
- ✅ 倒计时列表
- ✅ 天气城市数据
- ✅ 天气设置（当前城市、选中日期）

#### 3. 保留数据
- ⚠️ **云端数据不受影响** - Supabase 中的数据保持不变
- ⚠️ 刷新后会自动从云端重新同步

#### 4. 自动刷新
清空完成后：
- 显示成功提示
- 1.5 秒后自动刷新页面
- 页面重新加载时会从云端同步最新数据

### 💻 技术实现

```javascript
async function clearAllLocalData() {
  // 1. 双重确认
  if (!confirm('⚠️ 警告...')) return;
  if (!confirm('再次确认...')) return;

  try {
    // 2. 清空日历数据
    const calendarRecords = await idbCalendarGetAll();
    await Promise.all(calendarRecords.map(rec => idbCalendarDelete(rec.dateKey)));
    store = {};

    // 3. 清空附件
    const db = await openIdb();
    const tx = db.transaction(IDB_STORE_FILES, 'readwrite');
    await new Promise((resolve, reject) => {
      const req = tx.objectStore(IDB_STORE_FILES).clear();
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });

    // 4. 清空纪念日
    const anniversaryRecords = await idbAnniversaryGetAll();
    await Promise.all(anniversaryRecords.map(a => idbAnniversaryDelete(a.id)));
    anniversaries = [];

    // 5. 清空倒计时
    const countdownRecords = await idbCountdownGetAll();
    await Promise.all(countdownRecords.map(c => idbCountdownDelete(c.id)));
    countdowns = [];

    // 6. 清空天气数据
    const weatherRecords = await idbWeatherGetAll();
    await Promise.all(weatherRecords.map(w => idbWeatherDelete(w.city)));
    weatherCities = [];
    weatherData = null;
    activeWeatherCity = null;
    selectedWeatherDate = null;

    // 7. 刷新界面
    renderMonth();
    renderAnniversaries();
    renderCountdowns();
    renderWeatherCities();
    renderWeatherCurrent();

    // 8. 自动刷新页面
    setTimeout(() => {
      window.location.reload();
    }, 1500);

  } catch (e) {
    console.error('清空本地数据失败:', e);
    alert('❌ 清空失败：' + e.message);
  }
}
```

### 🎨 UI 样式

按钮采用醒目的红色设计：
- **默认状态**：红色边框 + 淡红背景
- **悬停状态**：红色渐变背景 + 白色文字 + 阴影效果
- **点击反馈**：轻微下压动画

提示信息使用小字号灰色文字，提醒用户谨慎操作。

### 📝 使用场景

1. **测试环境清理**：开发测试时快速重置数据
2. **隐私保护**：删除本地敏感数据
3. **故障恢复**：本地数据损坏时重新同步
4. **空间释放**：清除大文件附件释放存储空间

### ⚠️ 注意事项

1. **不可恢复**：清空后本地数据无法恢复
2. **确保同步**：操作前请确认重要数据已同步到云端
3. **网络要求**：刷新后需要网络连接才能从云端同步
4. **浏览器缓存**：硬刷新（Ctrl+F5）可确保完全重置

### 🔍 验证方法

清空后可以检查：
1. 浏览器控制台查看清空日志
2. 打开 DevTools → Application → IndexedDB 确认数据已清空
3. 页面刷新后应显示空白状态（如果云端也无数据）

---

## 🎯 总结

一键清空本地数据功能已完整实现，包括：
- ✅ UI 按钮和样式
- ✅ 双重确认机制
- ✅ 完整的清空逻辑
- ✅ 自动刷新页面
- ✅ 错误处理
- ✅ 详细的日志输出

使用简单安全，适合需要快速重置本地数据的场景！
