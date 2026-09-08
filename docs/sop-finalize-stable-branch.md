# SOP: Finalizing a Babelfish Stable Branch ([OSS-ONLY])

## Overview

After a stable branch is cut from a dev branch (e.g., `BABEL_6_2_STABLE` from `BABEL_6_X_DEV`),
it must be finalized to freeze all references to point to stable branches instead of dev branches.
This ensures CI on the stable branch runs against known-stable code, not moving dev targets.

Reference PRs:
- #4742: [OSS-ONLY] Finalize BABEL_6_1_STABLE (6 files)

## When to Apply

This SOP is applied ONCE per stable branch, immediately after the branch is created.
It targets the **stable branch itself** (not the dev branch).

## Changes Required (6 files)

### 1. Update `DEFAULT_BRANCH` (1 file)

**File**: `.github/scripts/clone_engine_repo.conf`

Change from dev engine branch to stable engine branch:
```
# Before
DEFAULT_BRANCH=BABEL_6_X_DEV__PG_18_X

# After
DEFAULT_BRANCH=BABEL_6_2_STABLE__PG_18_5
```

Pattern: `BABEL_<MAJOR>_<MINOR>_STABLE__PG_<PG_MAJOR>_<PG_MINOR>`

### 2. Freeze `version-branch-template.yml` (1 file, or 0 if no changes needed)

**File**: `.github/template/version-branch-template.yml`

Up to two actions:
1. **Freeze ALL `_X_DEV` entries** to their corresponding stable versions
2. **Conditionally add an entry for this branch's own PG version** — only if that version
   is explicitly referenced in `upgrade-test-configuration.yml` on this branch

> **Key rule**: Only add the branch's own entry (e.g., `18.5` → `BABEL_6_2_STABLE`) if that
> version number appears as an explicit `version:` value in `.github/configuration/upgrade-test-configuration.yml`.
> If the version is only reached via `source.latest` or `target.latest` (which resolve to `latest`
> branches at runtime), no explicit entry is needed.
>
> **Example**: BABEL_6_2_STABLE's upgrade config references `18.4` as a base version to upgrade FROM,
> so `18.4` needs an entry. It does NOT reference `18.5` — that's handled by `target.latest`.
> But BABEL_2_18_STABLE's config never references `14.24` explicitly, so no entry is needed.

For each `_X_DEV` entry, determine what stable branch was released for that PG version.
The mapping comes from the initial commits done on each dev branch:

| Dev entry | Freeze to | How to determine |
|-----------|-----------|-----------------|
| `BABEL_2_X_DEV__PG_14_X` | `BABEL_2_18_STABLE__PG_14_24` | Latest v2.x release targets PG 14.24 |
| `BABEL_3_X_DEV__PG_15_X` | `BABEL_3_15_STABLE__PG_15_19` | Latest v3.x release targets PG 15.19 |
| `BABEL_4_X_DEV__PG_16_X` | `BABEL_4_11_STABLE__PG_16_15` | Latest v4.x release targets PG 16.15 |
| `BABEL_5_X_DEV__PG_17_X` | `BABEL_5_7_STABLE__PG_17_11` | Latest v5.x release targets PG 17.11 |

Then, **only if the version appears in upgrade-test-configuration.yml**, add the branch's own entry:
```yaml
'18.5':
  engine_branch: BABEL_6_2_STABLE__PG_18_5
  extension_branch: BABEL_6_2_STABLE
```

**After finalization**: There should be NO `_X_DEV` references remaining in the file.

### 3. Update Upgrade Workflow Branches (2 files)

**Files**:
- `.github/workflows/major-version-upgrade.yml`
- `.github/workflows/singledb-version-upgrade.yml`

Change `ENGINE_BRANCH_FROM` and `EXTENSION_BRANCH_FROM` from dev to stable:
```yaml
# Before
ENGINE_BRANCH_FROM: BABEL_2_X_DEV__PG_14_X
EXTENSION_BRANCH_FROM: BABEL_2_X_DEV

# After
ENGINE_BRANCH_FROM: BABEL_2_18_STABLE__PG_14_24
EXTENSION_BRANCH_FROM: BABEL_2_18_STABLE
```

These should point to the **lowest PG major track's stable branch** (PG 14.x / BABEL_2_x)
since major-version-upgrade tests upgrade from the oldest supported version.

### 4. Disable TDS Fault Injection (1 file)

**File**: `contrib/babelfishpg_tds/Makefile`

Remove `-DFAULT_INJECTOR` from the `PG_CPPFLAGS` line:
```makefile
# Before
PG_CPPFLAGS += -I$(TSQL_SRC) -I$(PG_SRC) -I$(tds_top_dir) -DFAULT_INJECTOR

# After
PG_CPPFLAGS += -I$(TSQL_SRC) -I$(PG_SRC) -I$(tds_top_dir)
```

> **Why**: The TDS fault injection framework is for internal testing only and should not
> be enabled in stable/release branches.

### 5. Ignore TDS Fault Injection Tests (1 file)

**File**: `test/JDBC/jdbc_schedule`

Append ignore entries at the end of the file:
```
#TDS fault injection framework is meant for internal testing only. So, ignore tds_faultinjection tests in stable branch
ignore#!#tds_faultinjection
ignore#!#babel_tds_fault_injection
```

> **Note**: Only add these if the test files exist (`test/JDBC/input/tds_faultinjection.txt`
> and `test/JDBC/input/babel_tds_fault_injection.sql`). If they don't exist on the branch,
> skip this step.

## Verification Checklist

- [ ] `clone_engine_repo.conf` points to the correct stable engine branch
- [ ] `version-branch-template.yml` has NO `_X_DEV` references remaining
- [ ] `version-branch-template.yml` has an entry for THIS branch's PG version
- [ ] `major-version-upgrade.yml` uses stable branch references
- [ ] `singledb-version-upgrade.yml` uses stable branch references
- [ ] `babelfishpg_tds/Makefile` does NOT contain `-DFAULT_INJECTOR`
- [ ] `jdbc_schedule` has ignore entries for TDS fault injection tests (if applicable)
- [ ] Total: 6 files modified, 0 new files

## Determining Stable Branch Names

To find what stable branch corresponds to each dev track at the time of finalization:

1. Check the **initial commit** on each dev branch — it lists which PG minor version
   was just released (e.g., "Add version info for 14.24")
2. The stable branch name follows the pattern from `version-branch-template.yml` on
   the dev branch — the entry just BEFORE `source.latest` shows the latest stable
3. Alternatively, check the dev branch's template: the last numbered entry before
   `_X_DEV` is the latest stable for that track

## Common Mistakes

1. **Leaving `_X_DEV` references** — grep for `_X_DEV` after changes to verify none remain
2. **Wrong PG version in stable branch name** — cross-check with `babelfish_version.h`
   (`BABELFISH_INTERNAL_VERSION_STR` shows the PG version)
3. **Adding the branch's own template entry when not needed** — only add it if the version
   appears explicitly in `upgrade-test-configuration.yml`; `source.latest`/`target.latest`
   handle the current version without a numbered entry
4. **Forgetting the branch's own entry when it IS needed** — if upgrade config references
   the version number (e.g., `18.4` as a FROM version), the template must resolve it
5. **Not checking if TDS fault tests exist** — older branches may not have these files
6. **Not checking if `singledb-version-upgrade.yml` already uses stable** — some branches
   may already have stable references (e.g., BABEL_2_X branches reference PG 13 stable)
