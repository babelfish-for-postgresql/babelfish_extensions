#ifndef ERR_HANDLER_H
#define ERR_HANDLER_H

#include "pltsql.h"
#include "postgres.h"

/* 
 * Below macros are useful in building flag to override the behaviour of certain tsql
 * error code for certain situation.
 */
#define IGNORABLE_ERROR	0x01	//statement terminating
#define CUR_BATCH_ABORTING_ERROR	0x02	//current batch terminating
#define TXN_ABORTING_ERROR	0x04	//transaction aborting
#define IGNORE_XACT_ERROR	0x08	//ignore xact_abort flag

extern int CurrentLineNumber; /* Holds the Line No. of the current query being executed. */
bool is_ignorable_error(int pg_error_code, uint8_t override_flag);
bool  get_tsql_error_code(ErrorData *edata, int *last_error);
bool is_current_batch_aborting_error(int pg_error_code, uint8_t override_flag);
bool is_batch_txn_aborting_error(int pg_error_code, uint8_t override_flag);
bool ignore_xact_abort_error(int pg_error_code, uint8_t override_flag);
bool is_txn_aborting_compilation_error(int sql_error_code);
bool is_xact_abort_txn_compilation_error(int sql_error_code);

/* Function to override behaviour of any error code for different situation.*/
uint8_t override_txn_behaviour(PLtsql_stmt *stmt);

#endif

/* Macros for tsql error code */
#define SQL_ERROR_129 129
#define SQL_ERROR_132 132
#define SQL_ERROR_133 133
#define SQL_ERROR_134 134
#define SQL_ERROR_135 135
#define SQL_ERROR_136 136
#define SQL_ERROR_141 141
#define SQL_ERROR_142 142
#define SQL_ERROR_153 153
#define SQL_ERROR_180 180
#define SQL_ERROR_201 201
#define SQL_ERROR_206 206
#define SQL_ERROR_213 213
#define SQL_ERROR_217 217
#define SQL_ERROR_219 219
#define SQL_ERROR_220 220
#define SQL_ERROR_232 232
#define SQL_ERROR_266 266
#define SQL_ERROR_289 289
#define SQL_ERROR_293 293
#define SQL_ERROR_306 306
#define SQL_ERROR_346 346
#define SQL_ERROR_352 352
#define SQL_ERROR_477 477
#define SQL_ERROR_487 487
#define SQL_ERROR_506 506
#define SQL_ERROR_512 512
#define SQL_ERROR_515 515
#define SQL_ERROR_517 517
#define SQL_ERROR_545 545
#define SQL_ERROR_547 547
#define SQL_ERROR_550 550
#define SQL_ERROR_556 556
#define SQL_ERROR_574 574
#define SQL_ERROR_628 628
#define SQL_ERROR_1034 1034
#define SQL_ERROR_1049 1049
#define SQL_ERROR_1051 1051
#define SQL_ERROR_1205 1205
#define SQL_ERROR_1505 1505
#define SQL_ERROR_1715 1715
#define SQL_ERROR_1752 1752
#define SQL_ERROR_1765 1765
#define SQL_ERROR_1768 1768
#define SQL_ERROR_1776 1776
#define SQL_ERROR_1778 1778
#define SQL_ERROR_1801 1801
#define SQL_ERROR_1946 1946
#define SQL_ERROR_2627 2627
#define SQL_ERROR_2714 2714
#define SQL_ERROR_2732 2732
#define SQL_ERROR_2747 2747
#define SQL_ERROR_2787 2787
#define SQL_ERROR_3609 3609
#define SQL_ERROR_3616 3616
#define SQL_ERROR_3623 3623
#define SQL_ERROR_3701 3701
#define SQL_ERROR_3723 3723
#define SQL_ERROR_3726 3726
#define SQL_ERROR_3728 3728
#define SQL_ERROR_3729 3729
#define SQL_ERROR_3732 3732
#define SQL_ERROR_3902 3902
#define SQL_ERROR_3903 3903
#define SQL_ERROR_3914 3914
#define SQL_ERROR_3930 3930
#define SQL_ERROR_4514 4514
#define SQL_ERROR_4708 4708
#define SQL_ERROR_4712 4712
#define SQL_ERROR_4901 4901
#define SQL_ERROR_4920 4920
#define SQL_ERROR_6401 6401
#define SQL_ERROR_8003 8003
#define SQL_ERROR_8004 8004
#define SQL_ERROR_8007 8007
#define SQL_ERROR_8009 8009
#define SQL_ERROR_8011 8011
#define SQL_ERROR_8016 8016
#define SQL_ERROR_8018 8018
#define SQL_ERROR_8023 8023
#define SQL_ERROR_8028 8028
#define SQL_ERROR_8029 8029
#define SQL_ERROR_8031 8031
#define SQL_ERROR_8032 8032
#define SQL_ERROR_8037 8037
#define SQL_ERROR_8043 8043
#define SQL_ERROR_8047 8047
#define SQL_ERROR_8050 8050
#define SQL_ERROR_8057 8057
#define SQL_ERROR_8058 8058
#define SQL_ERROR_8106 8106
#define SQL_ERROR_8107 8107
#define SQL_ERROR_8115 8115
#define SQL_ERROR_8134 8134
#define SQL_ERROR_8143 8143
#define SQL_ERROR_8144 8144
#define SQL_ERROR_8145 8145
#define SQL_ERROR_8146 8146
#define SQL_ERROR_8152 8152
#define SQL_ERROR_8159 8159
#define SQL_ERROR_8179 8179
#define SQL_ERROR_9441 9441
#define SQL_ERROR_9451 9451
#define SQL_ERROR_9809 9809
#define SQL_ERROR_10610 10610
#define SQL_ERROR_10727 10727
#define SQL_ERROR_10733 10733
#define SQL_ERROR_10793 10793
#define SQL_ERROR_11555 11555
#define SQL_ERROR_11700 11700
#define SQL_ERROR_11701 11701
#define SQL_ERROR_11702 11702
#define SQL_ERROR_11703 11703
#define SQL_ERROR_11705 11705
#define SQL_ERROR_11706 11706
#define SQL_ERROR_11708 11708
#define SQL_ERROR_11709 11709
#define SQL_ERROR_11717 11717
#define SQL_ERROR_16915 16915
#define SQL_ERROR_16948 16948
#define SQL_ERROR_16950 16950
#define SQL_ERROR_18456 18456
