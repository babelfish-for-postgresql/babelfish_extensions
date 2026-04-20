# Babelfish Extensions - Development Guide

## Repository Structure

```
babelfish_extensions/
├── contrib/
│   ├── babelfishpg_tsql/     # T-SQL language support
│   │   └── src/              # Core: pl_exec.c, pl_comp.c, hooks.c, tsqlIface.cpp
│   ├── babelfishpg_tds/      # TDS protocol support
│   │   └── src/backend/tds/  # TDS protocol handlers
│   ├── babelfishpg_common/   # Shared data types (geometry, geography, etc.)
│   ├── babelfishpg_money/    # money type
│   └── babelfishpg_unit/     # Unit testing framework
├── test/
│   ├── JDBC/input/           # Primary T-SQL test files
│   ├── JDBC/expected/        # Expected output files
│   ├── python/               # Python driver tests + isolation tests (.spec)
│   ├── dotnet/               # .NET driver tests
│   └── odbc/                 # ODBC driver tests
├── .github/
│   ├── scripts/
│   │   └── install-deps.sh        # First-time dependency installer
│   └── pull_request_template.md   # PR description template
└── dev-tools.sh              # Developer build and test script
```

## Workspace Setup

Both repos must be in the same parent directory (the workspace root):
```
<workspace>/
├── postgresql_modified_for_babelfish/   # Engine source
├── babelfish_extensions/                # Extensions source
└── postgres/                            # Built PostgreSQL (created by initpg)
```

All commands below run from the workspace root.

## Branch Naming

| Type | Extensions | Engine |
|---|---|---|
| Dev | `BABEL_{major}_X_DEV` | `BABEL_{major}_X_DEV__PG_{pg_major}_X` |
| Stable | `BABEL_{major}_{minor}_STABLE` | `BABEL_{major}_{minor}_STABLE__PG_{pg_major}_{pg_minor}` |

Both repos must be on matching branches. List branches from GitHub to find the latest stable for a given version.

## Build and Test

### First-time setup

Install dependencies (or see `contrib/README.md` for manual steps):
```bash
./.github/scripts/install-deps.sh
```

Build and initialize:
```bash
./babelfish_extensions/dev-tools.sh initpg      # Build PostgreSQL engine
./babelfish_extensions/dev-tools.sh initdb       # Init data directory (restart may fail — expected)
./babelfish_extensions/dev-tools.sh buildbbf     # Build extensions + restart
./babelfish_extensions/dev-tools.sh initbbf      # Initialize Babelfish (creates jdbc_user / babelfish_db)
```

### Verify setup

Verify both PostgreSQL and TDS endpoints:
```bash
# PostgreSQL endpoint
psql -U jdbc_user -d babelfish_db -c "SELECT 1"

# TDS endpoint (sqlcmd or Python)
sqlcmd -S localhost -U jdbc_user -P 12345678 -Q "SELECT 1"
# or
python3 -c "import pymssql; c = pymssql.connect('localhost','jdbc_user','12345678','master'); c.cursor().execute('SELECT 1'); print('OK')"
```

### Daily development
```bash
./babelfish_extensions/dev-tools.sh buildbbf      # Build extensions + restart DB
./babelfish_extensions/dev-tools.sh buildall      # Build PG + extensions + restart DB
./babelfish_extensions/dev-tools.sh run_pgindent "" path/to/file.c  # Format a single file
./babelfish_extensions/dev-tools.sh run_pgindent                    # Format all extensions
```

### Running tests

`dev-tools.sh` supports JDBC tests:
```bash
./babelfish_extensions/dev-tools.sh test normal                  # Full run (multi-db)
./babelfish_extensions/dev-tools.sh test normal single-db        # Full run (single-db)
./babelfish_extensions/dev-tools.sh test prepare multi-db <dir>  # Schedule-based vu-prepare
./babelfish_extensions/dev-tools.sh test verify multi-db <dir>   # Schedule-based vu-verify
```

For running a single test, see `test/JDBC/README.md`.

For other frameworks (Python, .NET, ODBC), see their respective directories under `test/`.

### Upgrade testing
```bash
./babelfish_extensions/dev-tools.sh minor_version_upgrade <source_ws>
./babelfish_extensions/dev-tools.sh pg_upgrade <source_ws>
```

## Feature Branch

Create a feature branch from the target dev branch. Never commit directly to dev branches.
```bash
git checkout -b <JIRA-ID>-short-description BABEL_{major}_X_DEV
```

## Pre-Commit Checklist

- [ ] `buildbbf` succeeds
- [ ] Modified/added tests pass locally
- [ ] `run_pgindent` applied on modified `.c` and `.h` files; only commit pgindent changes on lines you modified, discard unrelated formatting changes from pre-existing code
- [ ] `expected_dependency.out` updated if new functions added

## Commit

- [ ] `git commit --signoff`

## Pre-PR Checklist

- [ ] GitHub Actions pass after push

## PR

- [ ] Fill `.github/pull_request_template.md` accordingly
