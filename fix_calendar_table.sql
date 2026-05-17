-- Supabase 表结构修复脚本
-- 修复 calendar 表结构并设置正确的权限策略

-- ========== 第一步：重建 calendar 表 ==========

-- 删除旧的 calendar 表（如果存在）
DROP TABLE IF EXISTS "public"."calendar" CASCADE;

-- 重新创建 calendar 表，结构正确
CREATE TABLE "public"."calendar" (
  "dateKey" TEXT NOT NULL PRIMARY KEY,
  "data" JSONB NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW(),
  "updated_at" TIMESTAMPTZ DEFAULT NOW()
);

-- ========== 第二步：设置 RLS 策略 ==========

-- 启用 Row Level Security
ALTER TABLE "public"."calendar" ENABLE ROW LEVEL SECURITY;

-- 创建允许匿名访问的策略（不带 IF NOT EXISTS）
CREATE POLICY "Allow anonymous select" ON "public"."calendar"
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert" ON "public"."calendar"
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update" ON "public"."calendar"
  FOR UPDATE TO anon USING (true);

CREATE POLICY "Allow anonymous delete" ON "public"."calendar"
  FOR DELETE TO anon USING (true);

-- ========== 第三步：确保纪念日和倒计时表也有正确的时间戳列 ==========

-- 为纪念日表添加时间戳（如果还没有）
ALTER TABLE "public"."anniversaries"
  ADD COLUMN IF NOT EXISTS "created_at" TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ DEFAULT NOW();

-- 为倒计时表添加时间戳（如果还没有）
ALTER TABLE "public"."countdowns"
  ADD COLUMN IF NOT EXISTS "created_at" TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMPTZ DEFAULT NOW();

-- ========== 第四步：确保纪念日和倒计时表有 RLS 策略 ==========

-- 删除可能存在的旧策略（避免冲突）
DROP POLICY IF EXISTS "Allow anonymous select" ON "public"."anniversaries";
DROP POLICY IF EXISTS "Allow anonymous insert" ON "public"."anniversaries";
DROP POLICY IF EXISTS "Allow anonymous update" ON "public"."anniversaries";
DROP POLICY IF EXISTS "Allow anonymous delete" ON "public"."anniversaries";

DROP POLICY IF EXISTS "Allow anonymous select" ON "public"."countdowns";
DROP POLICY IF EXISTS "Allow anonymous insert" ON "public"."countdowns";
DROP POLICY IF EXISTS "Allow anonymous update" ON "public"."countdowns";
DROP POLICY IF EXISTS "Allow anonymous delete" ON "public"."countdowns";

-- 确保启用了 RLS
ALTER TABLE "public"."anniversaries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."countdowns" ENABLE ROW LEVEL SECURITY;

-- 重新创建策略
CREATE POLICY "Allow anonymous select" ON "public"."anniversaries"
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert" ON "public"."anniversaries"
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update" ON "public"."anniversaries"
  FOR UPDATE TO anon USING (true);

CREATE POLICY "Allow anonymous delete" ON "public"."anniversaries"
  FOR DELETE TO anon USING (true);

CREATE POLICY "Allow anonymous select" ON "public"."countdowns"
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert" ON "public"."countdowns"
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update" ON "public"."countdowns"
  FOR UPDATE TO anon USING (true);

CREATE POLICY "Allow anonymous delete" ON "public"."countdowns"
  FOR DELETE TO anon USING (true);

-- ========== 第五步：验证表结构 ==========

-- 查看表结构
SELECT "table_name", "column_name", "data_type", "is_nullable"
FROM "information_schema"."columns"
WHERE "table_schema" = 'public'
  AND "table_name" IN ('calendar', 'anniversaries', 'countdowns')
ORDER BY "table_name", "ordinal_position";

-- 查看RLS策略
SELECT "schemaname", "tablename", "policyname", "permissive", "roles", "cmd", "qual"
FROM "pg_policies"
WHERE "schemaname" = 'public'
  AND "tablename" IN ('calendar', 'anniversaries', 'countdowns');

-- ========== 完成！ ==========
-- 这将输出：
-- 1. 所有表的列信息
-- 2. 所有表的 RLS 策略信息
-- 确认所有表都有正确的结构和权限策略
