-- TacoV Kern · Migration 018 · Outfits (Punkt 6.2) und Chirurg-Datum (6.3)
CREATE TABLE IF NOT EXISTS outfits (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  character_id INT UNSIGNED NOT NULL,
  name VARCHAR(32) NOT NULL,
  components TEXT NOT NULL,
  props TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_outfits_char (character_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS surgery_at TIMESTAMP NULL DEFAULT NULL;
