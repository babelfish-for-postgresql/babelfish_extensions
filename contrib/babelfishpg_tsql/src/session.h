#ifndef SESSION_H
#define SESSION_H
#include "postgres.h"

extern int16 get_cur_db_id(void);
extern void set_cur_db(int16 id, const char *name);
extern char *get_cur_db_name(void);
extern void set_session_properties(const char *db_name);
extern void restore_session_properties(void);
extern void reset_session_properties(void);
#endif
