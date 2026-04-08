# Babelfish Extensions - Development Guide

## Repository Structure

```
babelfish_extensions/
├── contrib/
│   ├── babelfishpg_tsql/     # T-SQL language support
│   ├── babelfishpg_tds/      # TDS protocol support
│   ├── babelfishpg_common/   # Shared data types (geometry, geography, money, etc.)
│   ├── babelfishpg_money/    # money type
│   └── babelfishpg_unit/     # Unit testing framework
├── test/
│   ├── JDBC/input/           # Primary T-SQL test files
│   ├── JDBC/expected/        # Expected output files
│   ├── python/               # Python driver tests + isolation tests (.spec)
│   ├── dotnet/               # .NET driver tests
│   └── odbc/                 # ODBC driver tests
└── dev-tools.sh              # Developer build and test script
```

## Build and Test

All commands run from the workspace root (parent of both `babelfish_extensions` and `postgresql_modified_for_babelfish`).

For detailed prerequisites (ICU, ANTLR, cmake, etc.) and manual build steps, see `contrib/README.md`. The `dev-tools.sh` script automates most of this workflow.

### First-time setup
```bash
./babelfish_extensions/dev-tools.sh initpg    # Build PostgreSQL engine
./babelfish_extensions/dev-tools.sh initdb    # Initialize data directory
./babelfish_extensions/dev-tools.sh initbbf   # Initialize Babelfish
```

### Daily development
```bash
./babelfish_extensions/dev-tools.sh buildbbf  # Build extensions + restart DB
./babelfish_extensions/dev-tools.sh buildall  # Build PG + extensions + restart DB
./babelfish_extensions/dev-tools.sh run_pgindent  # Format code (required before PR)
```

### Running tests
```bash
./babelfish_extensions/dev-tools.sh test normal                          # All JDBC tests (multi-db)
./babelfish_extensions/dev-tools.sh test normal single-db                # Single-db mode
./babelfish_extensions/dev-tools.sh test upgrade multi-db test/JDBC/upgrade/15_11  # Upgrade tests
```

### Upgrade testing
```bash
./babelfish_extensions/dev-tools.sh minor_version_upgrade SOURCE_WS     # ALTER EXTENSION UPDATE
./babelfish_extensions/dev-tools.sh pg_upgrade SOURCE_WS TARGET_WS      # Major version upgrade
```

## PR Checklist

- [ ] `run_pgindent` applied
- [ ] `test normal` passes in both multi-db and single-db modes
- [ ] Upgrade tests pass if DDL or catalog changed
- [ ] `test/python/expected/upgrade_validation/expected_dependency.out` updated if new functions added
- [ ] PR description includes JIRA link, change summary, test scenarios covered, breaking changes
- [ ] Two senior engineer approvals obtained
