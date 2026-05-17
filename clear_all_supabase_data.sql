-- ⚠️ 警告：此脚本将清空所有数据表！
-- 执行前请确认已备份重要数据

-- 清空日历数据
DELETE FROM "public"."calendar";

-- 清空纪念日数据
DELETE FROM "public"."anniversaries";

-- 清空倒计时数据
DELETE FROM "public"."countdowns";

-- 清空天气数据
DELETE FROM "public"."weather";

-- 清空天气城市列表
DELETE FROM "public"."weather_cities";

-- 清空天气设置
DELETE FROM "public"."weather_settings";

-- 验证清空结果
SELECT 
  'calendar' as table_name, 
  COUNT(*) as row_count 
FROM "public"."calendar"
UNION ALL
SELECT 
  'anniversaries' as table_name, 
  COUNT(*) as row_count 
FROM "public"."anniversaries"
UNION ALL
SELECT 
  'countdowns' as table_name, 
  COUNT(*) as row_count 
FROM "public"."countdowns"
UNION ALL
SELECT 
  'weather' as table_name, 
  COUNT(*) as row_count 
FROM "public"."weather"
UNION ALL
SELECT 
  'weather_cities' as table_name, 
  COUNT(*) as row_count 
FROM "public"."weather_cities"
UNION ALL
SELECT 
  'weather_settings' as table_name, 
  COUNT(*) as row_count 
FROM "public"."weather_settings";

-- ✅ 完成！所有数据已清空
-- 如果上面的查询返回的 row_count 都是 0，说明清空成功
