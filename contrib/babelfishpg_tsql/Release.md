How to release

Date: 2020-12-23

Versioning Scheme
-----------------

Goals
====
* Provide frequent (weekly/bi-weekly) extension patches for pre-prod instances when we want to alter the existing database without loosing the data
* Test upgrades between patches

Notes
====
PgTsql release version is composed by PGTSQL_MAJOR_VERSION,
PGTSQL_MINOR_VERSION and PGTSQL_MICRO_VERSION components, all
set in Version.config.

By default only *PGTSQL_MICRO_VERSION* is incremented between internal releases.


Internal release procedure by example
====

#### Preconditions
- Latest released version is `3.0.0`, i.e `PREV_EXTVERSION` is set  to 3.0.0
- Current development version is `3.0.1` i.e `Version.config` contains `PGTSQL_MAJOR_VERSION=3, PGTSQL_MINOR_VERSION=0 PGTSQL_MICRO_VERSION=1`
- There is an upgrade path `sql/upgrades/pgtsql--3.0.0--3.0.1.sql`
- There is an install script `sql/pgtsql--$(PREV_EXTVERSION).sql` to test upgrade path script
- babel_upgrade test is at the top of src/test/regress/babel_schedule
- `src/test/regress/sql/babel_upgrade.sql` is modified to include the `PREV_EXTVERSION` to test the upgrade path

#### Development Procedure
- Developers alter `sql/upgrades/pgtsql--3.0.0--3.0.1.sql` with upgrade scripts.

#### Release Procedure
- Release existing build
- set `PREV_EXTVERSION` to 3.0.1
- Copy sql install script to sql/pgtsql--3.0.1.sql
- Alter `src/test/regress/sql/babel_upgrade.sql` with a new upgrade path test from `3.0.1` to `3.0.2`
- Increment PGTSQL_MICRO_VERSION to 2
- Create an empty upgrade path in `sql/upgrades` from a previously released minor to a new development minor `sql/upgrades/pgtsql--3.0.1--3.0.2.sql`


Testing
====

bb installcheck-babel
* Extension upgrade test in `src/test/regress/sql/babel_upgrade.sql`