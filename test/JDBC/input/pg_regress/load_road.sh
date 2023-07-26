echo "-----copy road table from /data/streets.data-----"
psql -U jdbc_user -d jdbc_testdb -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/streets.data'
COPY master_dbo.road FROM :'filename';
EOF
echo "----- done -----"