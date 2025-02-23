CREATE TABLE IF NOT EXISTS ltz_t_notification (
	json TEXT
);
INSERT INTO ltz_t_notification (json) VALUES (json('{}'));

CREATE TRIGGER IF NOT EXISTS after_update_ltz_t_notification
AFTER UPDATE ON ltz_t_notification
BEGIN
	REPLACE INTO lnav_user_notifications (message) VALUES (
		(SELECT json FROM ltz_t_notification)
	);
END;