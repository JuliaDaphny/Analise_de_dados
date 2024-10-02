CREATE OR REPLACE FUNCTION search_columns(
    needle text,
    haystack_tables name[] default '{}',
    haystack_schema name[] default '{}'
)
RETURNS table(schemaname text, tablename text, columnname text, rowctid text)
AS $$
begin
  FOR schemaname,tablename,columnname IN
      SELECT c.table_schema,c.table_name,c.column_name
      FROM information_schema.columns c
        JOIN information_schema.tables t ON
          (t.table_name=c.table_name AND t.table_schema=c.table_schema)
        JOIN information_schema.table_privileges p ON
          (t.table_name=p.table_name AND t.table_schema=p.table_schema
              AND p.privilege_type='SELECT')
        JOIN information_schema.schemata s ON
          (s.schema_name=t.table_schema)
      WHERE (c.table_name=ANY(haystack_tables) OR haystack_tables='{}')
        AND (c.table_schema=ANY(haystack_schema) OR haystack_schema='{}')
        AND t.table_type='BASE TABLE'
  LOOP
    FOR rowctid IN
      EXECUTE format('SELECT ctid FROM %I.%I WHERE cast(%I as text) LIKE %L',
       schemaname,
       tablename,
       columnname,
       needle
      )
    LOOP
      -- uncomment next line to get some progress report
      -- RAISE NOTICE 'hit in %.%', schemaname, tablename;
      RETURN NEXT;
    END LOOP;
 END LOOP;
END;
$$ language plpgsql;

-- A busca diferencia maiusculo de minusculo
-- CID nanismo = Q771 e Q343
SELECT * FROM search_columns('%343%',array(select table_name::name from information_schema.tables where table_name like 'dn%'), array['saude_sinasc_2015']);
