echo "-----copy aggtest table from /data/agg.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d babelfish_db -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/agg.data'
COPY master_dbo.aggtest FROM :'filename';
EOF
echo "----- done -----"