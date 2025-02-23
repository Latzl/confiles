CREATE TABLE IF NOT EXISTS ltz_t_search (
	search_table TEXT,
	col TEXT,
	direction TEXT DEFAULT 'next',
	pattern TEXT,
	-- exact, regex
	match_type TEXT DEFAULT 'regex'
);
INSERT INTO ltz_t_search (search_table) VALUES ('');