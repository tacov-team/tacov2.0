-- TacoV Kern · Migration 008 · Verwarnungen (Punkt 5.2)
CREATE TABLE IF NOT EXISTS warnings (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  discord_id VARCHAR(32) NOT NULL,
  character_id INT UNSIGNED NULL,
  reason VARCHAR(255) NOT NULL,
  issued_by VARCHAR(32) NOT NULL,
  issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_warnings_discord (discord_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
