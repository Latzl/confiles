CREATE TABLE IF NOT EXISTS ltz_t_argpass (
	args TEXT
);

INSERT INTO ltz_t_argpass (args) VALUES ('');

CREATE TRIGGER IF NOT EXISTS after_update_ltz_t_argpass
AFTER UPDATE ON ltz_t_argpass
BEGIN
	UPDATE ltz_t_notification SET json = json_set(
		(SELECT json FROM ltz_t_notification),
		'$.argpass', NEW.args
	);
END;