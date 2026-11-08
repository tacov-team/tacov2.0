-- Phase 9.1: Fraktionen – Stammdaten, Ränge/Rechte, Protokoll, Sperren, Fahrzeuge, Dienstkleidung
CREATE TABLE IF NOT EXISTS factions (
  id VARCHAR(32) NOT NULL PRIMARY KEY,
  label VARCHAR(48) NOT NULL,
  type ENUM('state','crime') NOT NULL DEFAULT 'crime',
  cap SMALLINT UNSIGNED NOT NULL DEFAULT 15,
  channel TINYINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dissolved_at TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO factions (id, label, type, cap, channel) VALUES
  ('lspd', 'LSPD', 'state', 20, 1), ('lsmd', 'LSMD', 'state', 0, 2), ('dmv', 'DMV', 'state', 10, 3),
  ('government', 'Regierung', 'state', 0, 4), ('doj', 'DOJ', 'state', 15, 5);

CREATE TABLE IF NOT EXISTS faction_ranks (
  faction_id VARCHAR(32) NOT NULL,
  rank TINYINT UNSIGNED NOT NULL,
  name VARCHAR(48) NOT NULL,
  rights TEXT NULL,
  PRIMARY KEY (faction_id, rank)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS faction_log (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  faction_id VARCHAR(32) NOT NULL,
  character_id INT UNSIGNED NULL,
  faction_rank TINYINT UNSIGNED NULL,
  action VARCHAR(32) NOT NULL,
  text VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_faction_log (faction_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS faction_blocks (
  character_id INT UNSIGNED NOT NULL PRIMARY KEY,
  from_type ENUM('state','crime') NOT NULL,
  until_at TIMESTAMP NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS faction_vehicles (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  faction_id VARCHAR(32) NOT NULL,
  model VARCHAR(48) NOT NULL,
  label VARCHAR(48) NOT NULL,
  min_rank TINYINT UNSIGNED NOT NULL DEFAULT 3,
  KEY idx_faction_vehicles (faction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS faction_outfits (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  faction_id VARCHAR(32) NOT NULL,
  name VARCHAR(48) NOT NULL,
  gender TINYINT UNSIGNED NOT NULL DEFAULT 0,
  min_rank TINYINT UNSIGNED NOT NULL DEFAULT 1,
  components TEXT NOT NULL,
  props TEXT NOT NULL,
  KEY idx_faction_outfits (faction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tagesverbrauch für Limits (Lager-Entnahme in Gramm, Kasse in $)
CREATE TABLE IF NOT EXISTS faction_daily (
  character_id INT UNSIGNED NOT NULL,
  day DATE NOT NULL,
  storage_grams INT UNSIGNED NOT NULL DEFAULT 0,
  treasury INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (character_id, day)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE characters ADD COLUMN IF NOT EXISTS faction_joined_at TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS civil_clothes TEXT NULL;
