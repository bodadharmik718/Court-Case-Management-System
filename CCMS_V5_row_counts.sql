-- Show exact row counts for every base table in the current V5 database.
-- Run this while connected to the database created with CCMS_V5_schema.sql.
-- This is read-only and does not insert or alter data.

DROP TABLE IF EXISTS pg_temp.ccms_v5_row_counts;
CREATE TEMP TABLE ccms_v5_row_counts (
    table_name TEXT PRIMARY KEY,
    row_count BIGINT NOT NULL
);

DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        EXECUTE format(
            'INSERT INTO pg_temp.ccms_v5_row_counts(table_name, row_count) SELECT %L, COUNT(*) FROM %I.%I',
            table_record.tablename,
            table_record.schemaname,
            table_record.tablename
        );
    END LOOP;
END $$;

SELECT table_name, row_count,
       CASE WHEN row_count BETWEEN 80 AND 110 THEN 'IN RANGE'
            WHEN row_count < 80 THEN 'BELOW 80'
            ELSE 'ABOVE 110'
       END AS target_check
FROM pg_temp.ccms_v5_row_counts
ORDER BY table_name;
