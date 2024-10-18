#ifndef SESSION_H
#define SESSION_H
#include "postgres.h"
#include "multidb.h"
#include "access/parallel.h"

extern int16 get_cur_db_id(void);
extern void set_cur_db(int16 id, const char *name);
extern char *get_cur_db_name(void);
extern const char *get_current_pltsql_db_name(void);
extern void bbf_set_current_user(const char *user_name);
extern void set_session_properties(const char *db_name);
extern void check_session_db_access(const char *dn_name);
extern void set_cur_user_db_and_path(const char *db_name);
extern void restore_session_properties(void);
extern void reset_session_properties(void);
extern void set_cur_db_name_for_parallel_worker(const char* logical_db_name);

/* Hooks for parallel workers for babelfish fixed state */
extern void babelfixedparallelstate_insert(ParallelContext *pcxt, bool estimate);
extern void babelfixedparallelstate_restore(shm_toc *toc);

/* Babelfish Fixed-size parallel state */
typedef struct BabelfishFixedParallelState {
    char logical_db_name[MAX_BBF_NAMEDATALEND + 1]; 
} BabelfishFixedParallelState;

#endif
