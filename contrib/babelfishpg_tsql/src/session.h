#ifndef SESSION_H
#define SESSION_H
#include "postgres.h"

extern int16 get_cur_db_id(void);
extern void set_cur_db(int16 id, const char *name);
extern char *get_cur_db_name(void);
extern void bbf_set_current_user(const char *user_name);
extern void set_session_properties(const char *db_name);
extern void check_session_db_access(const char *dn_name);
extern void set_cur_user_db_and_path(const char *db_name);
extern void restore_session_properties(void);
extern void reset_session_properties(void);

#endif
