-- TacoV Kern · Migration 004 · Team-Rollen aus Discord (Punkt 0.11)
ALTER TABLE players MODIFY role VARCHAR(32) NOT NULL DEFAULT 'player';
