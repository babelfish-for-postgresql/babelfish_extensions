#include "mb/pg_wchar.h"

/* Functions in src/encoding/encoding_utils.c */
extern char *server_to_any(const char *s, int len, int encoding, int *encodedByteLen);

/* Functions in src/encoding/mb/conv.c */
extern int TsqlUtfToLocal(const unsigned char *utf, int len,
            unsigned char *iso,
            const pg_mb_radix_tree *map,
            const pg_utf_to_local_combined *cmap, int cmapsize,
            utf_local_conversion_func conv_func,
            int encoding);

/* Functions in src/encoding/mb/conversion_procs */
extern int utf8_to_win(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *result, int len);
extern int utf8_to_big5(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *result, int len);
extern int utf8_to_gbk(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *result, int len);
extern int utf8_to_uhc(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *result, int len);
extern int utf8_to_sjis(int src_encoding, int dest_encoding, const unsigned char *src, unsigned char *result, int len);