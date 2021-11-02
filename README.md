## Babelfish for PostgreSQL

[![Build Status](https://github.com/babelfish-for-postgresql/babelfish_extensions/workflows/CI/badge.svg)](https://github.com/babelfish-for-postgresql/babelfish_extensions/actions?query=workflow%3A%22CI%22)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE.Apache2)
[![License: PostgreSQL](https://img.shields.io/badge/license-PostgreSQL-blue.svg)](LICENSE.PostgreSQL)

Babelfish adds additional syntax, functions, data types, and more to PostgreSQL
to help in the migration from SQL Server. This repository contains the four
extensions that comprise Babelfish. Note that these extensions depend on
patches to community PostgreSQL. A repository of those modifications can be
found [here](https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish).

Build instructions can be found [here](https://github.com/babelfish-for-postgresql/babelfish_extensions/blob/BABEL_1_X_DEV/contrib/README.md).
 
More information about Babelfish can be found at [babelfishpg.org](https://babelfishpg.org).

Babelfish would not be possible without the work and dedication of the hundreds
of people who have contributed to creation of PostgreSQL itself.

The `babelfishpg_money` extension is a modified version of EDB / 2ndQuadrant's
[fixeddecimal](https://github.com/2ndQuadrant/fixeddecimal) data type. Everyone
involved in the development of PostgreSQL and fixeddecimal has our gratitude.
 
## Security
 
See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.
 
## License

This project is dual licensed under [Apache-2.0](LICENSE.Apache2) and
[PostgreSQL community](LICENSE.PostgreSQL) licenses. Use is permitted under
either license.
