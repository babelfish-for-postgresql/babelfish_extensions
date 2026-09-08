# SOP: Preparing a New Babelfish Minor Version (Initial Commit)

## Overview

When preparing an initial commit for a new Babelfish minor version on any dev branch,
the required changes vary by branch. Older branches (2.x, 3.x) have a simpler process;
newer branches (4.x, 5.x, 6.x) require additional infrastructure changes.

Reference PRs:
- v2.18: #4734 (BABEL_2_X_DEV) — 4 files
- v3.15: #4735 (BABEL_3_X_DEV) — 5 files
- v4.11: #4736 (BABEL_4_X_DEV) — 15 files (no cross-major)
- v5.7: #4737 (BABEL_5_X_DEV) — 18 files (with cross-major)
- v6.3: commit 1450d4d74 (BABEL_6_X_DEV) — 21 files (with cross-major)

## Version Mapping

| Branch | PG Major | Example |
|--------|----------|---------|
| BABEL_2_X_DEV | PG 14.x | 2.18.0 → PG 14.24 |
| BABEL_3_X_DEV | PG 15.x | 3.15.0 → PG 15.19 |
| BABEL_4_X_DEV | PG 16.x | 4.11.0 → PG 16.15 |
| BABEL_5_X_DEV | PG 17.x | 5.7.0 → PG 17.11 |
| BABEL_6_X_DEV | PG 18.x | 6.2.0 → PG 18.5 |

## Quick Reference: What Changes Per Branch

| Step | 2.x | 3.x | 4.x | 5.x | 6.x |
|------|-----|-----|-----|-----|-----|
| Bump `babelfish_version.h` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bump `Version.config` (tsql + common) | ❌ | ❌ | ✅ | ✅ | ✅ |
| Create main upgrade SQL script | ❌ | ❌ | ✅ | ✅ | ✅ |
| Create common helper + spatial stubs | ❌ | ❌ | ✅ | ✅ | ✅ |
| Create cross-major upgrade scripts | ❌ | ❌ | conditional | conditional | conditional |
| Update `Makefile` | ❌ | ❌ | ✅ | ✅ | ✅ |
| Update `upgrade-test-configuration.yml` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Update `version-branch-template.yml` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Update workflow antlr_version lists | ❌ | ❌ | ✅ | ✅ | ✅ |
| Update `expected_drop.out` | ❌ | ❌ | ✅ | ✅ | ✅ |
| Create upgrade test schedules | ✅ | ✅ | ✅ | ✅ | ✅ |

## Branch-Specific Details

### BABEL_2_X_DEV (PG 14.x) — 4 files

1. Bump `babelfish_version.h` (version STR + INTERNAL_VERSION_STR)
2. Bump single entry in `upgrade-test-configuration.yml` (14.x only)
3. Add stable entry in `version-branch-template.yml` (14.x only)
4. Create 1 schedule: `test/JDBC/upgrade/14_<prev>/schedule`

### BABEL_3_X_DEV (PG 15.x) — 5 files

1. Bump `babelfish_version.h`
2. Bump entries in `upgrade-test-configuration.yml` (14.x + 15.x)
3. Add stable entries in `version-branch-template.yml` (14.x + 15.x)
4. Create 2 schedules: `14_<new>/schedule` + `15_<new>/schedule`

### BABEL_4_X_DEV (PG 16.x) — 15-17 files

1. Bump `babelfish_version.h`
2. Bump `Version.config` (tsql + common)
3. Create main upgrade script + common helper stub + spatial stub
4. **Conditionally** create cross-major scripts (see rules below)
5. Update `Makefile` (3 places)
6. Bump entries in `upgrade-test-configuration.yml` (14.x, 15.x, 16.x)
7. Add stable entries in `version-branch-template.yml` (14.x, 15.x, 16.x)
8. Update workflow antlr_version lists (add new PG 16.x version)
9. Update `expected_drop.out`
10. Create 3 schedules

### BABEL_5_X_DEV / BABEL_6_X_DEV — 18-21 files

Same as 4.x but with additional PG major tracks (17.x, 18.x).

## Cross-Major Upgrade Scripts — When to Create

Cross-major scripts (e.g., `babelfishpg_tsql--4.11.0--5.0.0.sql`) provide the upgrade path
from the last minor of the previous PG major to the current major.

**Rule: Only create a cross-major script if the version already exists on the lower branch.**

To determine if a cross-major script is needed:
1. Check the lower branch's **current `PGTSQL_MINOR_VERSION`** in `Version.config`
2. Check what cross-major scripts **already exist** on your branch
3. If the lower branch's version is HIGHER than what's covered, add the new script

**Example for BABEL_5_X_DEV:**
- Lower branch (BABEL_4_X_DEV) has `PGTSQL_MINOR_VERSION=11` (version 4.11.0)
- Existing cross-major: `babelfishpg_tsql--4.10.0--5.0.0.sql`
- Since 4.11.0 exists and isn't covered → create `babelfishpg_tsql--4.11.0--5.0.0.sql`

**Example for BABEL_4_X_DEV:**
- Lower branch (BABEL_3_X_DEV) has `PGTSQL_MINOR_VERSION=13` (version 3.13.0)
- Existing cross-major: `babelfishpg_tsql--3.13.0--4.0.0.sql`
- Since 3.13.0 is already covered → do NOT create `3.14.0--4.0.0.sql`

**For `babelfishpg_common` cross-major scripts:**
- Check `BBFPGCMN_MINOR_VERSION` on the lower branch (NOT `PGTSQL_MINOR_VERSION`)
- These may differ — e.g., BABEL_3_X_DEV might have tsql=3.13 but common=3.12

> **IMPORTANT**: Do NOT create cross-major scripts for versions that don't exist yet.
> The version must already be released (present in the lower branch's Version.config).

## Detailed Steps (for 4.x+ branches)

### 1. Bump Version Strings

**`contrib/babelfishpg_tsql/src/babelfish_version.h`**
- `BABELFISH_VERSION_STR`: e.g., `"4.11.0"` → `"4.12.0"`
- `BABELFISH_INTERNAL_VERSION_STR`: e.g., `"Babelfish 16.15.0.0"` → `"Babelfish 16.16.0.0"`

**`contrib/babelfishpg_tsql/Version.config`**
- `PGTSQL_MINOR_VERSION`: e.g., `11` → `12`

**`contrib/babelfishpg_common/Version.config`**
- `BBFPGCMN_MINOR_VERSION`: e.g., `11` → `12`

### 2. Create Upgrade SQL Scripts

**Main upgrade script** — copy boilerplate from previous version on same branch:
- `contrib/babelfishpg_tsql/sql/upgrades/babelfishpg_tsql--<OLD>--<NEW>.sql`

**Common helper stub**:
- `contrib/babelfishpg_common/sql/upgrades/babelfish_common_helper--<OLD>--<NEW>.sql`

**Spatial types stub**:
- `contrib/babelfishpg_common/sql/upgrades/spatial_types--<OLD>--<NEW>.sql`

**Cross-major scripts** (only if needed per rules above):
- Copy from the previous cross-major file on the same branch (full content, NOT a stub)
- Must create both tsql and common variants

### 3. Update Makefile

`contrib/babelfishpg_common/Makefile` — add new entry in THREE places:
1. `GENERATED_UPGRADES` list
2. Build rule WITHOUT `ENABLE_SPATIAL_TYPES`
3. Build rule WITH `ENABLE_SPATIAL_TYPES`

### 4. Update `upgrade-test-configuration.yml`

**BUMP** existing version entries — do NOT add new entries.

### 5. Update `version-branch-template.yml`

For each PG major track:
- Make the previous dev entry a STABLE entry
- Add the new version pointing to dev

Pattern: `BABEL_<MAJOR>_<MINOR>_STABLE__PG_<PG_MAJOR>_<PG_MINOR>`

### 6. Update Workflow Files

Add the new PG 16.x version to the `contains()` list in:
- `.github/workflows/upgrade-test.yml`
- `.github/workflows/pg_dump-restore-test.yml`

> Only PG 16.x versions need explicit listing due to YAML float parsing issues.

### 7. Create Upgrade Test Schedules

Copy from the previous version's schedule in the same PG major track.

### 8. Update `expected_drop.out`

Add entries for new SQL files containing DROP statements (string sort order).

## Verification Checklist

- [ ] `babelfish_version.h` has correct version and internal version
- [ ] Version.config files bumped (4.x+ only)
- [ ] Upgrade script filenames match version strings
- [ ] Cross-major scripts only exist for versions present on the lower branch
- [ ] Makefile has entry in all 3 locations
- [ ] upgrade-test-configuration bumped (not duplicated)
- [ ] version-branch-template has correct stable + dev entries
- [ ] Workflow files updated with new PG 16.x version
- [ ] Schedule files exist for all bumped versions
- [ ] expected_drop.out has entries for all DROPs (string sort order)

## Common Mistakes

1. **Creating cross-major scripts for versions that don't exist yet** — check the lower branch's
   actual Version.config; do NOT assume future versions
2. **Applying 4.x+ steps to 2.x/3.x branches** — older branches skip Version.config, Makefile,
   upgrade SQL, workflows, and expected_drop
3. **Creating stub cross-major scripts** — they must be full copies of the previous version
4. **Adding a duplicate entry** in upgrade-test-configuration instead of bumping existing
5. **Forgetting Makefile build rules** — there are TWO sections (with/without ENABLE_SPATIAL_TYPES)
6. **Wrong alphabetical order** in expected_drop.out (string sort: `3.14` goes between `3.13` and `3.2`)
7. **Adding tests to upgrade schedules that can't work across versions** (e.g., features that
   don't exist in the old version)
