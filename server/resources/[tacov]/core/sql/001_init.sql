-- TacoV Kern · Migration 001 · Grundtabellen
-- Jede Migration ist idempotent; der Kern führt sie beim Start in Reihenfolge aus und merkt sich die Version in `migrations`.

CREATE TABLE IF NOT EXISTS migrations (
  version INT UNSIGNED NOT NULL PRIMARY KEY,
  applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Whitelist: der Discord-Bot schreibt hier, der Kern liest beim Verbinden (Konzept 1, Abschnitt 3)
CREATE TABLE IF NOT EXISTS whitelist (
  discord_id VARCHAR(32) NOT NULL PRIMARY KEY,
  discord_name VARCHAR(64) NOT NULL DEFAULT '',
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  added_by VARCHAR(32) NOT NULL DEFAULT 'bot',
  first_join_at TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Spielerkonto: Kontoanker ist die Discord-ID
CREATE TABLE IF NOT EXISTS players (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  discord_id VARCHAR(32) NOT NULL UNIQUE,
  license VARCHAR(64) NULL,
  hwid_hash VARCHAR(64) NULL,
  role VARCHAR(16) NOT NULL DEFAULT 'player',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_players_license (license)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sperren: Discord-ID ist gesperrt, bis `until_at` (NULL = dauerhaft)
CREATE TABLE IF NOT EXISTS bans (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  discord_id VARCHAR(32) NOT NULL,
  reason VARCHAR(255) NOT NULL,
  issued_by VARCHAR(32) NOT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  until_at TIMESTAMP NULL DEFAULT NULL,
  lifted_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_bans_discord (discord_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Charaktere: bis zu 2 je Spieler (Konzept 1)
CREATE TABLE IF NOT EXISTS characters (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  player_id INT UNSIGNED NOT NULL,
  slot TINYINT UNSIGNED NOT NULL DEFAULT 1,
  first_name VARCHAR(32) NOT NULL,
  last_name VARCHAR(32) NOT NULL,
  birth_date DATE NOT NULL,
  origin VARCHAR(64) NOT NULL DEFAULT '',
  gender TINYINT UNSIGNED NOT NULL DEFAULT 0,
  appearance JSON NULL,
  playtime_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  level_cache SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  noob_protection TINYINT(1) NOT NULL DEFAULT 1,
  immigrated_at TIMESTAMP NULL DEFAULT NULL,
  immigration_retry_at TIMESTAMP NULL DEFAULT NULL,
  position JSON NULL,
  needs JSON NULL,
  faction VARCHAR(32) NULL,
  faction_rank TINYINT UNSIGNED NULL,
  faction_left_at TIMESTAMP NULL DEFAULT NULL,
  faction_left_kind VARCHAR(16) NULL,
  phone_number VARCHAR(16) NULL UNIQUE,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_characters_player_slot (player_id, slot),
  UNIQUE KEY uq_characters_name (first_name, last_name),
  CONSTRAINT fk_characters_player FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Konten: Girokonto je Charakter, Businesskonto je Firma, Fraktionskasse, Staatshaushalt
CREATE TABLE IF NOT EXISTS accounts (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  owner_type ENUM('character','business','faction','state') NOT NULL,
  owner_id INT UNSIGNED NOT NULL DEFAULT 0,
  balance BIGINT NOT NULL DEFAULT 0,
  debt BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_accounts_owner (owner_type, owner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Journal: jede Geldbewegung, egal ob Konto, Bargeld oder Schwarzgeld (Konzept 1, Grundsatz "Der Server entscheidet")
CREATE TABLE IF NOT EXISTS journal (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  kind ENUM('bank','cash','black') NOT NULL,
  from_type VARCHAR(16) NULL,
  from_id INT UNSIGNED NULL,
  to_type VARCHAR(16) NULL,
  to_id INT UNSIGNED NULL,
  amount BIGINT NOT NULL,
  reason VARCHAR(64) NOT NULL,
  note VARCHAR(255) NULL,
  actor_character_id INT UNSIGNED NULL,
  INDEX idx_journal_from (from_type, from_id, at),
  INDEX idx_journal_to (to_type, to_id, at),
  INDEX idx_journal_reason (reason, at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Logs: 11 Kategorien, jede mit Discord-Kanal (bot/)
CREATE TABLE IF NOT EXISTS logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  category VARCHAR(24) NOT NULL,
  character_id INT UNSIGNED NULL,
  discord_id VARCHAR(32) NULL,
  message VARCHAR(512) NOT NULL,
  data JSON NULL,
  INDEX idx_logs_cat (category, at),
  INDEX idx_logs_char (character_id, at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Gesperrte Namen (Konzept 1, Abschnitt 4)
CREATE TABLE IF NOT EXISTS name_blocklist (
  pattern VARCHAR(64) NOT NULL PRIMARY KEY,
  note VARCHAR(128) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Orte: Grundspiel-Koordinaten plus Vorschläge, per /ort setzen verschiebbar (Konzept 5)
CREATE TABLE IF NOT EXISTS locations (
  name VARCHAR(48) NOT NULL PRIMARY KEY,
  kind VARCHAR(24) NOT NULL,
  x DOUBLE NOT NULL,
  y DOUBLE NOT NULL,
  z DOUBLE NOT NULL,
  heading DOUBLE NOT NULL DEFAULT 0,
  label VARCHAR(64) NOT NULL DEFAULT '',
  updated_by VARCHAR(32) NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO accounts (owner_type, owner_id, balance) VALUES ('state', 0, 0);
