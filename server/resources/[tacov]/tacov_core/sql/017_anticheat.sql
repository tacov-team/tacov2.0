-- TacoV Kern · Migration 017 · Anti-Cheat-Meldungen (Punkt 5.16)
CREATE TABLE IF NOT EXISTS ac_reports (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  discord_id VARCHAR(32) NOT NULL,
  character_id INT UNSIGNED NULL,
  player_name VARCHAR(64) NOT NULL DEFAULT '',
  kind VARCHAR(32) NOT NULL,
  details VARCHAR(500) NOT NULL,
  action VARCHAR(8) NOT NULL DEFAULT 'none',    -- none | kick | ban
  posted_discord TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ac_posted (posted_discord)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
