echo "-----copy road table from /data/streets.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d babelfish_db -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/streets.data'
COPY master_dbo.road FROM :'filename';
EOF
echo "----- done -----"