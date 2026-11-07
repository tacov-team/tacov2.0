-- TacoV Kern · Migration 007 · Kfz-Steuer (Punkt 4.13)
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS tax_paid_at TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS tax_due INT UNSIGNED NOT NULL DEFAULT 0;
UPDATE vehicles SET tax_paid_at = NOW() WHERE tax_paid_at IS NULL;
