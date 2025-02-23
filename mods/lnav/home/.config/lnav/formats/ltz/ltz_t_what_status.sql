CREATE TABLE IF NOT EXISTS ltz_t_what_status (
	what TEXT PRIMARY KEY,
	flag INTERGER DEFAULT 1,
	args TEXT
);
INSERT INTO ltz_t_what_status (what) VALUES ('');

CREATE TRIGGER IF NOT EXISTS after_update_ltz_t_what_status
AFTER UPDATE ON ltz_t_what_status
BEGIN
	UPDATE ltz_t_notification SET json = json_set(
		(SELECT json FROM ltz_t_notification),
		'$.what.what', NEW.what,
		'$.what.flag', NEW.flag,
		'$.what.args', json(NEW.args)
	);
END;