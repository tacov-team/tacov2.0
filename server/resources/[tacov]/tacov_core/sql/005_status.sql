-- TacoV Kern · Migration 005 · Serverstatus und Ansagen (Punkte 1.7, 1.9)

-- Eine Zeile (id = 1): der Spielserver schreibt alle 30 s, der Bot liest sie für das Status-Embed
CREATE TABLE IF NOT EXISTS server_status (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
  players INT UNSIGNED NOT NULL DEFAULT 0,
  slots INT UNSIGNED NOT NULL DEFAULT 0,
  started_at TIMESTAMP NULL DEFAULT NULL,
  next_restart_at TIMESTAMP NULL DEFAULT NULL,
  version VARCHAR(64) NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ansagen für Discord (Neustart, Wartung); der Bot postet sie in den Status-Kanal und setzt posted_at
CREATE TABLE IF NOT EXISTS announcements (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  kind VARCHAR(16) NOT NULL DEFAULT 'info',
  text VARCHAR(500) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  posted_at TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Kleiner Schlüssel-Wert-Speicher für den Bot (z. B. ID der Embed-Nachricht)
CREATE TABLE IF NOT EXISTS bot_state (
  k VARCHAR(48) NOT NULL PRIMARY KEY,
  v VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
