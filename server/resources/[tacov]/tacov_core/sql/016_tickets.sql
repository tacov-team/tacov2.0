-- TacoV Kern · Migration 016 · Tickets (Punkt 5.15)
CREATE TABLE IF NOT EXISTS tickets (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  discord_id VARCHAR(32) NOT NULL,
  character_id INT UNSIGNED NULL,
  player_name VARCHAR(64) NOT NULL DEFAULT '',
  subject VARCHAR(255) NOT NULL,
  status VARCHAR(10) NOT NULL DEFAULT 'open',    -- open | claimed | closed
  claimed_by VARCHAR(32) NULL,
  closed_by VARCHAR(32) NULL,
  discord_channel_id VARCHAR(32) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  closed_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_tickets_status (status),
  INDEX idx_tickets_discord (discord_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ticket_messages (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  ticket_id INT UNSIGNED NOT NULL,
  source VARCHAR(8) NOT NULL,                    -- game | discord | system
  author VARCHAR(64) NOT NULL,
  text VARCHAR(1000) NOT NULL,
  posted_discord TINYINT(1) NOT NULL DEFAULT 0,  -- vom Bot in den Kanal gestellt
  seen_game TINYINT(1) NOT NULL DEFAULT 0,       -- dem Spieler im Spiel angezeigt
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tm_ticket (ticket_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
