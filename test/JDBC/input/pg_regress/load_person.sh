echo "-----copy person table from /data/person.data-----"
PGPASSWORD=12345678 psql -U jdbc_user -d babelfish_db -a << EOF
\getenv pg_src PG_SRC
\set filename :pg_src '/src/test/regress/data/person.data'
COPY master_dbo.person FROM :'filename';
EOF
echo "----- done -----"