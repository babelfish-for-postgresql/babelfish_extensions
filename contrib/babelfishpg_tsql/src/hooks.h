#ifndef PLTSQL_HOOKS_H
#define PLTSQL_HOOKS_H
#include "postgres.h"
#include "catalog/catalog.h"
#include "parser/analyze.h"

extern IsExtendedCatalogHookType PrevIsExtendedCatalogHook;

extern void InstallExtendedHooks(void);
extern void UninstallExtendedHooks(void);

extern bool output_update_transformation;
extern char* extract_identifier(const char *start);
#endif
