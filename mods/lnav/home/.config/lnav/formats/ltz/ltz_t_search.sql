CREATE TABLE IF NOT EXISTS ltz_t_search (
	search_table TEXT,
	col TEXT,
	direction TEXT DEFAULT 'next',
	-- exact, regex
	match_type TEXT DEFAULT 'regex',
	pattern TEXT
);
INSERT INTO ltz_t_search (search_table) VALUES ('');