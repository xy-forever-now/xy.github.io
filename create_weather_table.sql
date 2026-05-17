-- 创建天气数据表
-- 用于同步用户添加的城市天气数据

-- 删除旧的 weather 表（如果存在）
DROP TABLE IF EXISTS "public"."weather" CASCADE;

-- 创建 weather 表
CREATE TABLE "public"."weather" (
  "city" TEXT NOT NULL PRIMARY KEY,
  "data" JSONB NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ DEFAULT NOW()
);

-- 创建城市列表表（用于同步用户的关注城市列表）
CREATE TABLE IF NOT EXISTS "public"."weather_cities" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "data" JSONB NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ DEFAULT NOW()
);

-- 创建天气设置表（用于同步用户选择的城市和日期）
CREATE TABLE IF NOT EXISTS "public"."weather_settings" (
  "id" TEXT NOT NULL PRIMARY KEY,
  "data" JSONB NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ DEFAULT NOW()
);

-- 启用 Row Level Security
ALTER TABLE "public"."weather" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."weather_cities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."weather_settings" ENABLE ROW LEVEL SECURITY;

-- 创建允许匿名访问的策略
-- 天气数据策略
CREATE POLICY "Allow anonymous select" ON "public"."weather"
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert" ON "public"."weather"
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update" ON "public"."weather"
  FOR UPDATE TO anon USING (true);

CREATE POLICY "Allow anonymous delete" ON "public"."weather"
  FOR DELETE TO anon USING (true);

-- 城市列表策略
CREATE POLICY "Allow anonymous select" ON "public"."weather_cities"
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert" ON "public"."weather_cities"
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update" ON "public"."weather_cities"
  FOR UPDATE TO anon USING (true);

CREATE POLICY "Allow anonymous delete" ON "public"."weather_cities"
  FOR DELETE TO anon USING (true);

-- 设置策略
CREATE POLICY "Allow anonymous select" ON "public"."weather_settings"
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert" ON "public"."weather_settings"
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update" ON "public"."weather_settings"
  FOR UPDATE TO anon USING (true);

CREATE POLICY "Allow anonymous delete" ON "public"."weather_settings"
  FOR DELETE TO anon USING (true);

-- 查看表结构验证
SELECT "table_name", "column_name", "data_type", "is_nullable"
FROM "information_schema"."columns"
WHERE "table_schema" = 'public'
  AND "table_name" IN ('weather', 'weather_cities', 'weather_settings')
ORDER BY "table_name", "ordinal_position";

-- 查看 RLS 策略验证
SELECT "schemaname", "tablename", "policyname", "permissive", "roles", "cmd"
FROM "pg_policies"
WHERE "schemaname" = 'public'
  AND "tablename" IN ('weather', 'weather_cities', 'weather_settings');

-- 完成！
-- 现在你有了三个表来同步天气数据：
-- 1. weather - 存储具体城市的天气数据
-- 2. weather_cities - 存储用户关注的城市列表
-- 3. weather_settings - 存储用户的选择（当前城市、选择日期）
