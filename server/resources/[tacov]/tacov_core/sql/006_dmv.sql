-- TacoV Kern · Migration 006 · Führerscheine und Zulassung (Punkte 4.9, 4.10)

CREATE TABLE IF NOT EXISTS licenses (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  character_id INT UNSIGNED NOT NULL,
  type VARCHAR(16) NOT NULL,          -- A, B, C, boat, air, weapon
  points INT NOT NULL DEFAULT 0,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP NULL DEFAULT NULL,
  UNIQUE KEY uq_license (character_id, type),
  CONSTRAINT fk_licenses_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Zulassung: NULL = noch nicht zugelassen (Kennzeichen TMP ...). Bestehende Fahrzeuge gelten als zugelassen.
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS registered_at TIMESTAMP NULL DEFAULT NULL;
UPDATE vehicles SET registered_at = bought_at WHERE registered_at IS NULL AND plate NOT LIKE 'TMP %';
