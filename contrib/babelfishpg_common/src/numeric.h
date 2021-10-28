#ifndef NUMERIC_H
#define NUMERIC_H

#include "utils/numeric.h"

extern Numeric tsql_set_var_from_str_wrapper(const char *str);
extern int32_t tsql_numeric_get_typmod(Numeric num);

#endif
