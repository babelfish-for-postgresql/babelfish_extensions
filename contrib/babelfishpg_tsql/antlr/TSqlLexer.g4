/*
T-SQL (Transact-SQL, MSSQL) grammar.
The MIT License (MIT).
Copyright (c) 2017, Mark Adams (madams51703@gmail.com)
Copyright (c) 2015-2017, Ivan Kochurkin (kvanttt@gmail.com), Positive Technologies.
Copyright (c) 2016, Scott Ure (scott@redstormsoftware.com).
Copyright (c) 2016, Rui Zhang (ruizhang.ccs@gmail.com).
Copyright (c) 2016, Marcus Henriksson (kuseman80@gmail.com).
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
/*
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
*/

lexer grammar TSqlLexer;

@header
{
    extern bool pltsql_quoted_identifier;
}

//Keywords
ABORT:                                           A B O R T;
ABORT_AFTER_WAIT:                                A B O R T  UNDERLINE  A F T E R  UNDERLINE  W A I T;
ABSENT:                                          A B S E N T;
ABSOLUTE:                                        A B S O L U T E;
ACCELERATED_DATABASE_RECOVERY:                   A C C E L E R A T E D  UNDERLINE  D A T A B A S E  UNDERLINE  R E C O V E R Y;
ACCENT_SENSITIVITY:                              A C C E N T  UNDERLINE  S E N S I T I V I T Y;
ACCESS:                                          A C C E S S;
ACTION:                                          A C T I O N;
ACTIVATION:                                      A C T I V A T I O N;
ACTIVE:                                          A C T I V E;
ADD:                                             A D D;
ADDRESS:                                         A D D R E S S;
ADMINISTER:                                      A D M I N I S T E R;
AES:                                             A E S;
AES_128:                                         A E S  UNDERLINE  '128';
AES_192:                                         A E S  UNDERLINE  '192';
AES_256:                                         A E S  UNDERLINE  '256';
AFFINITY:                                        A F F I N I T Y;
AFTER:                                           A F T E R;
AGGREGATE:                                       A G G R E G A T E;
ALGORITHM:                                       A L G O R I T H M;
ALL:                                             A L L;
ALL_SPARSE_COLUMNS:                              A L L  UNDERLINE  S P A R S E  UNDERLINE  C O L U M N S;
ALLOWED:                                         A L L O W E D;
ALLOW_CONNECTIONS:                               A L L O W  UNDERLINE  C O N N E C T I O N S;
ALLOW_ENCRYPTED_VALUE_MODIFICATIONS:             A L L O W  UNDERLINE  E N C R Y P T E D  UNDERLINE  V A L U E  UNDERLINE  M O D I F I C A T I O N S;
ALLOW_MULTIPLE_EVENT_LOSS:                       A L L O W  UNDERLINE  M U L T I P L E  UNDERLINE  E V E N T  UNDERLINE  L O S S;
ALLOW_SINGLE_EVENT_LOSS:                         A L L O W  UNDERLINE  S I N G L E  UNDERLINE  E V E N T  UNDERLINE  L O S S;
ALLOW_SNAPSHOT_ISOLATION:                        A L L O W  UNDERLINE  S N A P S H O T  UNDERLINE  I S O L A T I O N;
ALTER:                                           A L T E R;
ALWAYS:                                          A L W A Y S;
AND:                                             A N D;
ANONYMOUS:                                       A N O N Y M O U S;
ANSI_DEFAULTS:                                   A N S I  UNDERLINE  D E F A U L T S;
ANSI_NULLS:                                      A N S I  UNDERLINE  N U L L S;
ANSI_NULL_DEFAULT:                               A N S I  UNDERLINE  N U L L  UNDERLINE  D E F A U L T;
ANSI_NULL_DFLT_OFF:                              A N S I  UNDERLINE  N U L L  UNDERLINE  D F L T  UNDERLINE  O F F;
ANSI_NULL_DFLT_ON:                               A N S I  UNDERLINE  N U L L  UNDERLINE  D F L T  UNDERLINE  O N;
ANSI_PADDING:                                    A N S I  UNDERLINE  P A D D I N G;
ANSI_WARNINGS:                                   A N S I  UNDERLINE  W A R N I N G S;
ANY:                                             A N Y;
APPEND:                                          A P P E N D;
APPLICATION:                                     A P P L I C A T I O N;
APPLICATION_LOG:                                 A P P L I C A T I O N  UNDERLINE  L O G;
APPLY:                                           A P P L Y;
ARITHABORT:                                      A R I T H A B O R T;
ARITHIGNORE:                                     A R I T H I G N O R E;
AS:                                              A S;
ASC:                                             A S C;
ASSEMBLY:                                        A S S E M B L Y;
ASYMMETRIC:                                      A S Y M M E T R I C;
ASYNCHRONOUS_COMMIT:                             A S Y N C H R O N O U S  UNDERLINE  C O M M I T;
ATOMIC:                                          A T O M I C;
AT_KEYWORD:                                      A T;
AUDIT:                                           A U D I T;
AUDIT_GUID:                                      A U D I T  UNDERLINE  G U I D;
AUTHENTICATE:                                    A U T H E N T I C A T E;
AUTHENTICATION:                                  A U T H E N T I C A T I O N;
AUTHORIZATION:                                   A U T H O R I Z A T I O N;
AUTO:                                            A U T O;
AUTOCOMMIT:                                      A U T O C O M M I T;
AUTOGROW_ALL_FILES:                              A U T O G R O W  UNDERLINE  A L L  UNDERLINE  F I L E S;
AUTOGROW_SINGLE_FILE:                            A U T O G R O W  UNDERLINE  S I N G L E  UNDERLINE  F I L E;
AUTOMATED_BACKUP_PREFERENCE:                     A U T O M A T E D  UNDERLINE  B A C K U P  UNDERLINE  P R E F E R E N C E;
AUTOMATIC:                                       A U T O M A T I C;
AUTO_CLEANUP:                                    A U T O  UNDERLINE  C L E A N U P;
AUTO_CLOSE:                                      A U T O  UNDERLINE  C L O S E;
AUTO_CREATE_STATISTICS:                          A U T O  UNDERLINE  C R E A T E  UNDERLINE  S T A T I S T I C S;
AUTO_SHRINK:                                     A U T O  UNDERLINE  S H R I N K;
AUTO_UPDATE_STATISTICS:                          A U T O  UNDERLINE  U P D A T E  UNDERLINE  S T A T I S T I C S;
AUTO_UPDATE_STATISTICS_ASYNC:                    A U T O  UNDERLINE  U P D A T E  UNDERLINE  S T A T I S T I C S  UNDERLINE  A S Y N C;
AVAILABILITY:                                    A V A I L A B I L I T Y;
AVAILABILITY_MODE:                               A V A I L A B I L I T Y  UNDERLINE  M O D E;
AVG:                                             A V G;
BABELFISH_SHOWPLAN_ALL:                          B A B E L F I S H  UNDERLINE  S H O W P L A N  UNDERLINE  A L L;
BABELFISH_STATISTICS:                            B A B E L F I S H  UNDERLINE  S T A T I S T I C S;
BACKUP:                                          B A C K U P;
BACKUP_PRIORITY:                                 B A C K U P  UNDERLINE  P R I O R I T Y;
BEFORE:                                          B E F O R E;
BEGIN:                                           B E G I N;
BEGIN_DIALOG:                                    B E G I N  UNDERLINE  D I A L O G;
BETWEEN:                                         B E T W E E N;
BIGINT:                                          B I G I N T;
BASE64:                                          B A S E '64';
BINARY_CHECKSUM:                                 B I N A R Y  UNDERLINE  C H E C K S U M;
BINARY_KEYWORD:                                  B I N A R Y;
BINDING:                                         B I N D I N G;
BLOB_STORAGE:                                    B L O B  UNDERLINE  S T O R A G E;
BLOCK:                                           B L O C K;
BLOCKERS:                                        B L O C K E R S;
BLOCKING_HIERARCHY:                              B L O C K I N G  UNDERLINE  H I E R A R C H Y;
BLOCKSIZE:                                       B L O C K S I Z E;
BOUNDING_BOX:                                    B O U N D I N G  UNDERLINE  B O X;
BREAK:                                           B R E A K;
BROKER:                                          B R O K E R;
BROKER_INSTANCE:                                 B R O K E R  UNDERLINE  I N S T A N C E;
BROWSE:                                          B R O W S E;
BUFFER:                                          B U F F E R;
BUFFERCOUNT:                                     B U F F E R C O U N T;
BULK:                                            B U L K;
BULK_LOGGED:                                     B U L K  UNDERLINE  L O G G E D;
BY:                                              B Y;
CACHE:                                           C A C H E;
CALLED:                                          C A L L E D;
CALLER:                                          C A L L E R;
CAP_CPU_PERCENT:                                 C A P  UNDERLINE  C P U  UNDERLINE  P E R C E N T;
CASCADE:                                         C A S C A D E;
CASE:                                            C A S E;
CAST:                                            C A S T;
CATALOG:                                         C A T A L O G;
CATALOG_COLLATION:                               C A T A L O G  UNDERLINE  C O L L A T I O N;
CATCH:                                           C A T C H;
CELLS_PER_OBJECT:                                C E L L S  UNDERLINE  P E R  UNDERLINE  O B J E C T;
CERTIFICATE:                                     C E R T I F I C A T E;
CHANGE:                                          C H A N G E;
CHANGES:                                         C H A N G E S;
CHANGETABLE:                                     C H A N G E T A B L E;
CHANGE_RETENTION:                                C H A N G E  UNDERLINE  R E T E N T I O N;
CHANGE_TRACKING:                                 C H A N G E  UNDERLINE  T R A C K I N G;
CHECK:                                           C H E C K;
CHECKPOINT:                                      C H E C K P O I N T;
CHECKSUM:                                        C H E C K S U M;
CHECKSUM_AGG:                                    C H E C K S U M  UNDERLINE  A G G;
CHECK_EXPIRATION:                                C H E C K  UNDERLINE  E X P I R A T I O N;
CHECK_POLICY:                                    C H E C K  UNDERLINE  P O L I C Y;
CLASSIFIER:                                      C L A S S I F I E R;
CLASSIFIER_FUNCTION:                             C L A S S I F I E R  UNDERLINE  F U N C T I O N;
CLEANUP:                                         C L E A N U P;
CLEANUP_POLICY:                                  C L E A N U P  UNDERLINE  P O L I C Y;
CLEAR:                                           C L E A R;
CLOSE:                                           C L O S E;
CLUSTER:                                         C L U S T E R;
CLUSTERED:                                       C L U S T E R E D;
COALESCE:                                        C O A L E S C E;
COLLATE:                                         C O L L A T E;
COLLECTION:                                      C O L L E C T I O N;
COLUMN:                                          C O L U M N;
COLUMN_SET:                                      C O L U M N  UNDERLINE  S E T;
COLUMNS:                                         C O L U M N S;
COLUMNSTORE:                                     C O L U M N S T O R E;
COLUMN_MASTER_KEY:                               C O L U M N  UNDERLINE  M A S T E R  UNDERLINE  K E Y;
COLUMN_ENCRYPTION_KEY:                           C O L U M N  UNDERLINE  E N C R Y P T I O N  UNDERLINE  K E Y;
COMMIT:                                          C O M M I T;
COMMITTED:                                       C O M M I T T E D;
COMPATIBILITY_LEVEL:                             C O M P A T I B I L I T Y  UNDERLINE  L E V E L;
COMPRESSION:                                     C O M P R E S S I O N;
COMPUTE:                                         C O M P U T E;
CONCAT:                                          C O N C A T;
CONCAT_NULL_YIELDS_NULL:                         C O N C A T  UNDERLINE  N U L L  UNDERLINE  Y I E L D S  UNDERLINE  N U L L;
CONFIGURATION:                                   C O N F I G U R A T I O N;
CONNECT:                                         C O N N E C T;
CONNECTION:                                      C O N N E C T I O N;
CONSTRAINT:                                      C O N S T R A I N T;
CONTAINED:                                       C O N T A I N E D;
CONTAINMENT:                                     C O N T A I N M E N T;
CONTAINS:                                        C O N T A I N S;
CONTAINSTABLE:                                   C O N T A I N S T A B L E;
CONTENT:                                         C O N T E N T;
CONTEXT:                                         C O N T E X T;
CONTINUE:                                        C O N T I N U E;
CONTINUE_AFTER_ERROR:                            C O N T I N U E  UNDERLINE  A F T E R  UNDERLINE  E R R O R;
CONTRACT:                                        C O N T R A C T;
CONTRACT_NAME:                                   C O N T R A C T  UNDERLINE  N A M E;
CONTROL:                                         C O N T R O L;
CONVERSATION:                                    C O N V E R S A T I O N;
CONVERT:                                         C O N V E R T;
COOKIE:                                          C O O K I E;
COPY_ONLY:                                       C O P Y  UNDERLINE  O N L Y;
COUNT:                                           C O U N T;
COUNTER:                                         C O U N T E R;
COUNT_BIG:                                       C O U N T  UNDERLINE  B I G;
CPU:                                             C P U;
CREATE:                                          C R E A T E;
CREATE_NEW:                                      C R E A T E  UNDERLINE  N E W;
CREATION_DISPOSITION:                            C R E A T I O N  UNDERLINE  D I S P O S I T I O N;
CREDENTIAL:                                      C R E D E N T I A L;
CROSS:                                           C R O S S;
CRYPTOGRAPHIC:                                   C R Y P T O G R A P H I C;
CUBE:                                            C U B E;
CUME_DIST:                                       C U M E  UNDERLINE  D I S T;
CURRENT:                                         C U R R E N T;
CURRENT_DATE:                                    C U R R E N T  UNDERLINE  D A T E;
CURRENT_TIME:                                    C U R R E N T  UNDERLINE  T I M E;
CURRENT_TIMESTAMP:                               C U R R E N T  UNDERLINE  T I M E S T A M P;
CURRENT_USER:                                    C U R R E N T  UNDERLINE  U S E R;
CURSOR:                                          C U R S O R;
CURSOR_CLOSE_ON_COMMIT:                          C U R S O R  UNDERLINE  C L O S E  UNDERLINE  O N  UNDERLINE  C O M M I T;
CURSOR_DEFAULT:                                  C U R S O R  UNDERLINE  D E F A U L T;
CUSTOM:                                          C U S T O M;
CYCLE:                                           C Y C L E;
D:                                               [Dd];
DATA:                                            D A T A;
DATABASE:                                        D A T A B A S E;
DATABASE_MIRRORING:                              D A T A B A S E  UNDERLINE  M I R R O R I N G;
DATA_COMPRESSION:                                D A T A  UNDERLINE  C O M P R E S S I O N;
DATA_CONSISTENCY_CHECK:                          D A T A  UNDERLINE  C O N S I S T E N C Y  UNDERLINE  C H E C K;
DATA_FLUSH_INTERVAL_SECONDS:                     D A T A  UNDERLINE  F L U S H  UNDERLINE  I N T E R V A L  UNDERLINE  S E C O N D S;
DATA_SOURCE:                                     D A T A  UNDERLINE  S O U R C E;
DATASPACE:                                       D A T A S P A C E;
DATEADD:                                         D A T E A D D;
DATEDIFF:                                        D A T E D I F F;
DATEDIFF_BIG:                                    D A T E D I F F  UNDERLINE  B I G;
DATEFIRST:                                       D A T E F I R S T;
DATEFORMAT:                                      D A T E F O R M A T;
DATE_FORMAT:                                     D A T E  UNDERLINE  F O R M A T;
DATENAME:                                        D A T E N A M E;
DATEPART:                                        D A T E P A R T;
DATE_CORRELATION_OPTIMIZATION:                   D A T E  UNDERLINE  C O R R E L A T I O N  UNDERLINE  O P T I M I Z A T I O N;
DAY:                                             D A Y;
DAYS:                                            D A Y S;
DBCC:                                            D B C C;
DB_CHAINING:                                     D B  UNDERLINE  C H A I N I N G;
DB_FAILOVER:                                     D B  UNDERLINE  F A I L O V E R;
DDL:                                             D D L;
DEALLOCATE:                                      D E A L L O C A T E;
DECLARE:                                         D E C L A R E;
DECRYPTION:                                      D E C R Y P T I O N;
DEFAULT:                                         D E F A U L T;
DEFAULT_DOUBLE_QUOTE:                            ["] D E F A U L T ["];
DEFAULT_DATABASE:                                D E F A U L T  UNDERLINE  D A T A B A S E;
DEFAULT_FULLTEXT_LANGUAGE:                       D E F A U L T  UNDERLINE  F U L L T E X T  UNDERLINE  L A N G U A G E;
DEFAULT_LANGUAGE:                                D E F A U L T  UNDERLINE  L A N G U A G E;
DEFAULT_SCHEMA:                                  D E F A U L T  UNDERLINE  S C H E M A;
DEFINITION:                                      D E F I N I T I O N;
DELAY:                                           D E L A Y;
DELAYED_DURABILITY:                              D E L A Y E D  UNDERLINE  D U R A B I L I T Y;
DELETE:                                          D E L E T E;
DELETED:                                         D E L E T E D;
DENSE_RANK:                                      D E N S E  UNDERLINE  R A N K;
DENY:                                            D E N Y;
DEPENDENTS:                                      D E P E N D E N T S;
DES:                                             D E S;
DESC:                                            D E S C;
DESCRIPTION:                                     D E S C R I P T I O N;
DESX:                                            D E S X;
DETERMINISTIC:                                   D E T E R M I N I S T I C;
DHCP:                                            D H C P;
DIAGNOSTICS:                                     D I A G N O S T I C S;
DIALOG:                                          D I A L O G;
DIFFERENTIAL:                                    D I F F E R E N T I A L;
DIRECTORY_NAME:                                  D I R E C T O R Y  UNDERLINE  N A M E;
DISABLE:                                         D I S A B L E;
DISABLED:                                        D I S A B L E D;
DISABLE_BROKER:                                  D I S A B L E  UNDERLINE  B R O K E R;
DISK:                                            D I S K;
DISK_DRIVE:                                      [A-Z][:];
DISTINCT:                                        D I S T I N C T;
DISTRIBUTED:                                     D I S T R I B U T E D;
DISTRIBUTED_AGG:                                 D I S T R I B U T E D  UNDERLINE  A G G;
DISTRIBUTION:                                    D I S T R I B U T I O N;
DOCUMENT:                                        D O C U M E N T;
DOLLAR_ACTION:                                   DOLLAR A C T I O N;
DOLLAR_EDGE_ID:                                  DOLLAR E D G E  UNDERLINE  I D;    // graph
DOLLAR_FROM_ID:                                  DOLLAR F R O M  UNDERLINE  I D;    // graph
DOLLAR_IDENTITY:                                 DOLLAR I D E N T I T Y;
DOLLAR_NODE_ID:                                  DOLLAR N O D E  UNDERLINE  I D;    // graph
DOLLAR_PARTITION:                                DOLLAR P A R T I T I O N;
DOLLAR_ROWGUID:                                  DOLLAR R O W G U I D;
DOLLAR_TO_ID:                                    DOLLAR T O  UNDERLINE  I D;        // graph
DOUBLE:                                          D O U B L E;
DROP:                                            D R O P;
DTC_SUPPORT:                                     D T C  UNDERLINE  S U P P O R T;
DUMP:                                            D U M P;
DYNAMIC:                                         D Y N A M I C;
EDGE:                                            E D G E;
ELEMENTS:                                        E L E M E N T S;
ELSE:                                            E L S E;
EMERGENCY:                                       E M E R G E N C Y;
EMPTY:                                           E M P T Y;
ENABLE:                                          E N A B L E;
ENABLED:                                         E N A B L E D;
ENABLE_BROKER:                                   E N A B L E  UNDERLINE  B R O K E R;
ENCRYPTED:                                       E N C R Y P T E D;
ENCRYPTED_VALUE:                                 E N C R Y P T E D  UNDERLINE  V A L U E;
ENCRYPTION:                                      E N C R Y P T I O N;
ENCRYPTION_TYPE:                                 E N C R Y P T I O N UNDERLINE T Y P E;
ENCODING:                                        E N C O D I N G;
END:                                             E N D;
ENDPOINT:                                        E N D P O I N T;
ENDPOINT_URL:                                    E N D P O I N T  UNDERLINE  U R L;
ERRLVL:                                          E R R L V L;
ERROR:                                           E R R O R;
ERROR_BROKER_CONVERSATIONS:                      E R R O R  UNDERLINE  B R O K E R  UNDERLINE  C O N V E R S A T I O N S;
ESCAPE:                                          E S C A P E;
EVENT:                                           E V E N T;
EVENTDATA:                                       E V E N T D A T A;
EVENT_RETENTION_MODE:                            E V E N T  UNDERLINE  R E T E N T I O N  UNDERLINE  M O D E;
EXCEPT:                                          E X C E P T;
EXCLUSIVE:                                       E X C L U S I V E;
EXEC:                                            E X E C;
EXECUTE:                                         E X E C U T E;
EXECUTABLE:                                      E X E C U T A B L E;
EXECUTABLE_FILE:                                 E X E C U T A B L E  UNDERLINE  F I L E;
EXECUTION_COUNT:                                 E X E C U T I O N  UNDERLINE  C O U N T;
EXIST:                                           E X I S T;
EXISTS:                                          E X I S T S;
EXIT:                                            E X I T;
EXPAND:                                          E X P A N D;
EXPIREDATE:                                      E X P I R E D A T E;
EXPIRY_DATE:                                     E X P I R Y  UNDERLINE  D A T E;
EXPLICIT:                                        E X P L I C I T;
EXTENSION:                                       E X T E N S I O N;
EXTERNAL:                                        E X T E R N A L;
EXTERNALPUSHDOWN:                                E X T E R N A L P U S H D O W N;
EXTERNAL_ACCESS:                                 E X T E R N A L  UNDERLINE  A C C E S S;
EXTRACT:                                         E X T R A C T;
FAILOVER:                                        F A I L O V E R;
FAILOVER_MODE:                                   F A I L O V E R  UNDERLINE  M O D E;
FAILURE:                                         F A I L U R E;
FAILURECONDITIONLEVEL:                           F A I L U R E C O N D I T I O N L E V E L;
FAILURE_CONDITION_LEVEL:                         F A I L U R E  UNDERLINE  C O N D I T I O N  UNDERLINE  L E V E L;
FAIL_OPERATION:                                  F A I L  UNDERLINE  O P E R A T I O N;
FAIL_UNSUPPORTED:                                F A I L  UNDERLINE  U N S U P P O R T E D;
FAN_IN:                                          F A N  UNDERLINE  I N;
FALSE:                                           F A L S E;
FAST:                                            F A S T;
FAST_FORWARD:                                    F A S T  UNDERLINE  F O R W A R D;
FETCH:                                           F E T C H;
FIELD_TERMINATOR:                                F I E L D  UNDERLINE  T E R M I N A T O R;
FILE:                                            F I L E;
FILEGROUP:                                       F I L E G R O U P;
FILEGROWTH:                                      F I L E G R O W T H;
FILENAME:                                        F I L E N A M E;
FILEPATH:                                        F I L E P A T H;
FILESTREAM:                                      F I L E S T R E A M;
FILESTREAM_ON:                                   F I L E S T R E A M  UNDERLINE  O N;
FILETABLE:                                       F I L E T A B L E;
FILE_SNAPSHOT:                                   F I L E  UNDERLINE  S N A P S H O T;
FILTER:                                          F I L T E R;
FIPS_FLAGGER:                                    F I P S  UNDERLINE  F L A G G E R;
FIRST:                                           F I R S T;
FIRST_ROW:                                       F I R S T  UNDERLINE  R O W;
FIRST_VALUE:                                     F I R S T  UNDERLINE  V A L U E;
FMTONLY:                                         F M T O N L Y;
FN:                                              F N;
FOLLOWING:                                       F O L L O W I N G;
FOR:                                             F O R;
FOR_APPEND:                                      F O R UNDERLINE A P P E N D;
FORCE:                                           F O R C E;
FORCED:                                          F O R C E D;
FORCEPLAN:                                       F O R C E P L A N;
FORCESCAN:                                       F O R C E S C A N;
FORCESEEK:                                       F O R C E S E E K;
FORCE_FAILOVER_ALLOW_DATA_LOSS:                  F O R C E  UNDERLINE  F A I L O V E R  UNDERLINE  A L L O W  UNDERLINE  D A T A  UNDERLINE  L O S S;
FORCE_SERVICE_ALLOW_DATA_LOSS:                   F O R C E  UNDERLINE  S E R V I C E  UNDERLINE  A L L O W  UNDERLINE  D A T A  UNDERLINE  L O S S;
FOREIGN:                                         F O R E I G N;
FORMAT:                                          F O R M A T;
FORWARD_ONLY:                                    F O R W A R D  UNDERLINE  O N L Y;
FORMAT_OPTIONS:                                  F O R M A T  UNDERLINE  O P T I O N S;
FORMAT_TYPE:                                     F O R M A T  UNDERLINE  T Y P E;
FREETEXT:                                        F R E E T E X T;
FREETEXTTABLE:                                   F R E E T E X T T A B L E;
FROM:                                            F R O M;
FULL:                                            F U L L;
FULLSCAN:                                        F U L L S C A N;
FULLTEXT:                                        F U L L T E X T;
FUNCTION:                                        F U N C T I O N;
GB:                                              G B;
GENERATED:                                       G E N E R A T E D;
GEOGRAPHY_AUTO_GRID:                             G E O G R A P H Y  UNDERLINE  A U T O  UNDERLINE  G R I D;
GEOGRAPHY_GRID:                                  G E O G R A P H Y  UNDERLINE  G R I D;
GEOMETRY_AUTO_GRID:                              G E O M E T R Y  UNDERLINE  A U T O  UNDERLINE  G R I D;
GEOMETRY_GRID:                                   G E O M E T R Y  UNDERLINE  G R I D;
GET:                                             G E T;
GETANCESTOR:                                     G E T A N C E S T O R;
GETDATE:                                         G E T D A T E;
GETDESCENDANT:                                   G E T D E S C E N D A N T;
GETLEVEL:                                        G E T L E V E L;
GETREPARENTEDVALUE:                              G E T R E P A R E N T E D V A L U E;
GETROOT:                                         G E T R O O T;
GETUTCDATE:                                      G E T U T C D A T E;
GLOBAL:                                          G L O B A L;
GOTO:                                            G O T O;
GOVERNOR:                                        G O V E R N O R;
GRANT:                                           G R A N T;
GRIDS:                                           G R I D S;
GROUP:                                           G R O U P;
GROUPING:                                        G R O U P I N G;
GROUPING_ID:                                     G R O U P I N G  UNDERLINE  I D;
GROUP_MAX_REQUESTS:                              G R O U P  UNDERLINE  M A X  UNDERLINE  R E Q U E S T S;
GUID:                                            G U I D;
HADR:                                            H A D R;
HASH:                                            H A S H;
HASHED:                                          H A S H E D;
HAVING:                                          H A V I N G;
HEALTHCHECKTIMEOUT:                              H E A L T H C H E C K T I M E O U T;
HEALTH_CHECK_TIMEOUT:                            H E A L T H  UNDERLINE  C H E C K  UNDERLINE  T I M E O U T;
HIDDEN_RENAMED:                                  H I D D E N;
HIGH:                                            H I G H;
HINT:                                            H I N T;
HISTORY_RETENTION_PERIOD:                        H I S T O R Y  UNDERLINE  R E T E N T I O N  UNDERLINE  P E R I O D;
HISTORY_TABLE:                                   H I S T O R Y  UNDERLINE  T A B L E;
HOLDLOCK:                                        H O L D L O C K;
HONOR_BROKER_PRIORITY:                           H O N O R  UNDERLINE  B R O K E R  UNDERLINE  P R I O R I T Y;
HOUR:                                            H O U R;
HOURS:                                           H O U R S;
IDENTITY:                                        I D E N T I T Y;
IDENTITYCOL:                                     I D E N T I T Y C O L;
IDENTITY_INSERT:                                 I D E N T I T Y  UNDERLINE  I N S E R T;
IDENTITY_VALUE:                                  I D E N T I T Y  UNDERLINE  V A L U E;
IF:                                              I F;
IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX:           I G N O R E  UNDERLINE  N O N C L U S T E R E D  UNDERLINE  C O L U M N S T O R E  UNDERLINE  I N D E X;
IIF:                                             I I F;
IMMEDIATE:                                       I M M E D I A T E;
IMPERSONATE:                                     I M P E R S O N A T E;
IMPLICIT_TRANSACTIONS:                           I M P L I C I T  UNDERLINE  T R A N S A C T I O N S;
IMPORTANCE:                                      I M P O R T A N C E;
IN:                                              I N;
INCLUDE:                                         I N C L U D E;
INCLUDE_NULL_VALUES:                             I N C L U D E  UNDERLINE  N U L L  UNDERLINE  V A L U E S;
INCREMENT:                                       I N C R E M E N T;
INCREMENTAL:                                     I N C R E M E N T A L;
INDEX:                                           I N D E X;
INFINITE:                                        I N F I N I T E;
INIT:                                            I N I T;
INITIATOR:                                       I N I T I A T O R;
INNER:                                           I N N E R;
INPUT:                                           I N P U T;
INSENSITIVE:                                     I N S E N S I T I V E;
INSERT:                                          I N S E R T;
INSERTED:                                        I N S E R T E D;
INSTEAD:                                         I N S T E A D;
INT:                                             I N T;
INTERSECT:                                       I N T E R S E C T;
INTERVAL:                                        I N T E R V A L;
INTERVAL_LENGTH_MINUTES:                         I N T E R V A L  UNDERLINE  L E N G T H  UNDERLINE  M I N U T E S;
INTO:                                            I N T O;
IO:                                              I O;
IP:                                              I P;
IS:                                              I S;
ISDESCENDANTOF:                                  I S D E S C E N D A N T O F;
ISNULL:                                          I S N U L L;
ISOLATION:                                       I S O L A T I O N;
JOB:                                             J O B;
JOIN:                                            J O I N;
JSON:                                            J S O N;
KB:                                              K B;
KEEP:                                            K E E P;
KEEPFIXED:                                       K E E P F I X E D;
KEEP_CDC:                                        K E E P  UNDERLINE  C D C;
KEEP_REPLICATION:                                K E E P  UNDERLINE  R E P L I C A T I O N;
KERBEROS:                                        K E R B E R O S;
KEY:                                             K E Y;
KEYS:                                            K E Y S;
KEYSET:                                          K E Y S E T;
KEY_PATH:                                        K E Y  UNDERLINE  P A T H;
KEY_SOURCE:                                      K E Y  UNDERLINE  S O U R C E;
KEY_STORE_PROVIDER_NAME:                         K E Y  UNDERLINE  S T O R E  UNDERLINE  P R O V I D E R  UNDERLINE  N A M E;
KILL:                                            K I L L;
LAG:                                             L A G;
LANGUAGE:                                        L A N G U A G E;
LAST:                                            L A S T;
LAST_VALUE:                                      L A S T  UNDERLINE  V A L U E;
LEAD:                                            L E A D;
LEDGER:                                          L E D G E R;
LEFT:                                            L E F T;
LEVEL:                                           L E V E L;
LIBRARY:                                         L I B R A R Y;
LIFETIME:                                        L I F E T I M E;
LIKE:                                            L I K E;
LINENO:                                          L I N E N O;
LINKED:                                          L I N K E D;
LINUX:                                           L I N U X;
LIST:                                            L I S T;
LISTENER:                                        L I S T E N E R;
LISTENER_IP:                                     L I S T E N E R  UNDERLINE  I P;
LISTENER_PORT:                                   L I S T E N E R  UNDERLINE  P O R T;
LISTENER_URL:                                    L I S T E N E R  UNDERLINE  U R L;
LOAD:                                            L O A D;
LOB_COMPACTION:                                  L O B  UNDERLINE  C O M P A C T I O N;
LOCAL:                                           L O C A L;
LOCAL_SERVICE_NAME:                              L O C A L  UNDERLINE  S E R V I C E  UNDERLINE  N A M E;
LOCATION:                                        L O C A T I O N;
LOCK:                                            L O C K;
LOCK_ESCALATION:                                 L O C K  UNDERLINE  E S C A L A T I O N;
LOG:                                             L O G;
LOGIN:                                           L O G I N;
LOOP:                                            L O O P;
LOW:                                             L O W;
MANUAL:                                          M A N U A L;
MARK:                                            M A R K;
MASK:                                            M A S K;
MASKED:                                          M A S K E D;
MASTER:                                          M A S T E R;
MATCHED:                                         M A T C H E D;
MATERIALIZED:                                    M A T E R I A L I Z E D;
MAX:                                             M A X;
MAXDOP:                                          M A X D O P;
MAXRECURSION:                                    M A X R E C U R S I O N;
MAXSIZE:                                         M A X S I Z E;
MAXTRANSFER:                                     M A X T R A N S F E R;
MAXVALUE:                                        M A X V A L U E;
MAX_CPU_PERCENT:                                 M A X  UNDERLINE  C P U  UNDERLINE  P E R C E N T;
MAX_DISPATCH_LATENCY:                            M A X  UNDERLINE  D I S P A T C H  UNDERLINE  L A T E N C Y;
MAX_DOP:                                         M A X  UNDERLINE  D O P;
MAX_DURATION:                                    M A X  UNDERLINE  D U R A T I O N;
MAX_EVENT_SIZE:                                  M A X  UNDERLINE  E V E N T  UNDERLINE  S I Z E;
MAX_FILES:                                       M A X  UNDERLINE  F I L E S;
MAX_GRANT_PERCENT:                               M A X  UNDERLINE  G R A N T  UNDERLINE  P E R C E N T;
MAX_IOPS_PER_VOLUME:                             M A X  UNDERLINE  I O P S  UNDERLINE  P E R  UNDERLINE  V O L U M E;
MAX_MEMORY:                                      M A X  UNDERLINE  M E M O R Y;
MAX_MEMORY_PERCENT:                              M A X  UNDERLINE  M E M O R Y  UNDERLINE  P E R C E N T;
MAX_OUTSTANDING_IO_PER_VOLUME:                   M A X  UNDERLINE  O U T S T A N D I N G  UNDERLINE  I O  UNDERLINE  P E R  UNDERLINE  V O L U M E;
MAX_PLANS_PER_QUERY:                             M A X  UNDERLINE  P L A N S  UNDERLINE  P E R  UNDERLINE  Q U E R Y;
MAX_PROCESSES:                                   M A X  UNDERLINE  P R O C E S S E S;
MAX_QUEUE_READERS:                               M A X  UNDERLINE  Q U E U E  UNDERLINE  R E A D E R S;
MAX_ROLLOVER_FILES:                              M A X  UNDERLINE  R O L L O V E R  UNDERLINE  F I L E S;
MAX_SIZE:                                        M A X  UNDERLINE  S I Z E;
MAX_SIZE_MB:                                     M A X  UNDERLINE  S I Z E  UNDERLINE  M B;
MAX_STORAGE_SIZE_MB:                             M A X  UNDERLINE  S T O R A G E  UNDERLINE  S I Z E  UNDERLINE  M B;
MB:                                              M B;
MEDIADESCRIPTION:                                M E D I A D E S C R I P T I O N;
MEDIANAME:                                       M E D I A N A M E;
MEDIUM:                                          M E D I U M;
MEMBER:                                          M E M B E R;
MEMORY_OPTIMIZED_DATA:                           M E M O R Y  UNDERLINE  O P T I M I Z E D  UNDERLINE  D A T A;
MEMORY_PARTITION_MODE:                           M E M O R Y  UNDERLINE  P A R T I T I O N  UNDERLINE  M O D E;
MERGE:                                           M E R G E;
MESSAGE:                                         M E S S A G E;
MESSAGE_FORWARDING:                              M E S S A G E  UNDERLINE  F O R W A R D I N G;
MESSAGE_FORWARD_SIZE:                            M E S S A G E  UNDERLINE  F O R W A R D  UNDERLINE  S I Z E;
MIN:                                             M I N;
MINUTE:                                          M I N U T E;
MINUTES:                                         M I N U T E S;
MINVALUE:                                        M I N V A L U E;
MIN_ACTIVE_ROWVERSION:                           M I N  UNDERLINE  A C T I V E  UNDERLINE  R O W V E R S I O N;
MIN_CPU_PERCENT:                                 M I N  UNDERLINE  C P U  UNDERLINE  P E R C E N T;
MIN_GRANT_PERCENT:                               M I N  UNDERLINE  G R A N T  UNDERLINE  P E R C E N T;
MIN_IOPS_PER_VOLUME:                             M I N  UNDERLINE  I O P S  UNDERLINE  P E R  UNDERLINE  V O L U M E;
MIN_MEMORY_PERCENT:                              M I N  UNDERLINE  M E M O R Y  UNDERLINE  P E R C E N T;
MIRROR:                                          M I R R O R;
MIRROR_ADDRESS:                                  M I R R O R  UNDERLINE  A D D R E S S;
MIXED_PAGE_ALLOCATION:                           M I X E D  UNDERLINE  P A G E  UNDERLINE  A L L O C A T I O N;
MODE:                                            M O D E;
MODEL:                                           M O D E L;
MODIFY:                                          M O D I F Y;
MONTH:                                           M O N T H;
MONTHS:                                          M O N T H S;
MOVE:                                            M O V E;
MULTI_USER:                                      M U L T I  UNDERLINE  U S E R;
MUST_CHANGE:                                     M U S T  UNDERLINE  C H A N G E;
NAME:                                            N A M E;
NATIONAL:                                        N A T I O N A L;
NATIVE_COMPILATION:                              N A T I V E  UNDERLINE  C O M P I L A T I O N;
NEGOTIATE:                                       N E G O T I A T E;
NESTED_TRIGGERS:                                 N E S T E D  UNDERLINE  T R I G G E R S;
NEW_ACCOUNT:                                     N E W  UNDERLINE  A C C O U N T;
NEW_BROKER:                                      N E W  UNDERLINE  B R O K E R;
NEW_PASSWORD:                                    N E W  UNDERLINE  P A S S W O R D;
NEXT:                                            N E X T;
NO:                                              N O;
NOCHECK:                                         N O C H E C K;
NOCOMPUTE:                                       N O C O M P U T E;
NOCOUNT:                                         N O C O U N T;
NODE:                                            N O D E;
NODES:                                           N O D E S;
NOEXEC:                                          N O E X E C;
NOEXPAND:                                        N O E X P A N D;
NOFORMAT:                                        N O F O R M A T;
NOINIT:                                          N O I N I T;
NOLOCK:                                          N O L O C K;
NONCLUSTERED:                                    N O N C L U S T E R E D;
NONE:                                            N O N E;
NON_TRANSACTED_ACCESS:                           N O N  UNDERLINE  T R A N S A C T E D  UNDERLINE  A C C E S S;
NORECOMPUTE:                                     N O R E C O M P U T E;
NORECOVERY:                                      N O R E C O V E R Y;
NOREWIND:                                        N O R E W I N D;
NOSKIP:                                          N O S K I P;
NOT:                                             N O T;
NOTIFICATION:                                    N O T I F I C A T I O N;
NOTIFICATIONS:                                   N O T I F I C A T I O N S;
NOUNLOAD:                                        N O U N L O A D;
NOWAIT:                                          N O W A I T;
NO_BROWSETABLE:                                  N O  UNDERLINE  B R O W S E T A B L E;
NO_CHECKSUM:                                     N O  UNDERLINE  C H E C K S U M;
NO_COMPRESSION:                                  N O  UNDERLINE  C O M P R E S S I O N;
NO_EVENT_LOSS:                                   N O  UNDERLINE  E V E N T  UNDERLINE  L O S S;
NO_LOG:                                          N O  UNDERLINE  L O G;
NO_PERFORMANCE_SPOOL:                            N O  UNDERLINE  P E R F O R M A N C E  UNDERLINE  S P O O L;
NO_TRUNCATE:                                     N O  UNDERLINE  T R U N C A T E;
NO_WAIT:                                         N O  UNDERLINE  W A I T;
NTILE:                                           N T I L E;
NTLM:                                            N T L M;
NULL_P:                                          N U L L;
NULLIF:                                          N U L L I F;
NUMANODE:                                        N U M A N O D E;
NUMBER:                                          N U M B E R;
NUMERIC_ROUNDABORT:                              N U M E R I C  UNDERLINE  R O U N D A B O R T;
OBJECT:                                          O B J E C T;
OF:                                              O F;
OFF:                                             O F F;
OFFLINE:                                         O F F L I N E;
OFFSET:                                          O F F S E T;
OFFSETS:                                         O F F S E T S;
OJ:												 O J;
OLD_ACCOUNT:                                     O L D  UNDERLINE  A C C O U N T;
OLD_PASSWORD:                                    O L D  UNDERLINE  P A S S W O R D;
ON:                                              O N;
ONLINE:                                          O N L I N E;
ONLY:                                            O N L Y;
ON_FAILURE:                                      O N  UNDERLINE  F A I L U R E;
OPEN:                                            O P E N;
OPENDATASOURCE:                                  O P E N D A T A S O U R C E;
OPENJSON:                                        O P E N J S O N;
OPENQUERY:                                       O P E N Q U E R Y;
OPENROWSET:                                      O P E N R O W S E T;
OPENXML:                                         O P E N X M L;
OPEN_EXISTING:                                   O P E N  UNDERLINE  E X I S T I N G;
OPERATIONS:                                      O P E R A T I O N S;
OPERATION_MODE:                                  O P E R A T I O N  UNDERLINE  M O D E;
OPTIMISTIC:                                      O P T I M I S T I C;
OPTIMIZE:                                        O P T I M I Z E;
OPTION:                                          O P T I O N;
OR:                                              O R;
ORDER:                                           O R D E R;
OUT:                                             O U T;
OUTER:                                           O U T E R;
OUTPUT:                                          O U T P U T;
OVER:                                            O V E R;
OVERRIDE:                                        O V E R R I D E;
OWNER:                                           O W N E R;
OWNERSHIP:                                       O W N E R S H I P;
PAGE:                                            P A G E;
PAGECOUNT:                                       P A G E C O U N T;
PAGE_VERIFY:                                     P A G E  UNDERLINE  V E R I F Y;
PAGLOCK:                                         P A G L O C K;
PARAM:                                           P A R A M;
PARAMETERIZATION:                                P A R A M E T E R I Z A T I O N;
PARAM_NODE:                                      P A R A M  UNDERLINE  N O D E;
PARSE:                                           P A R S E;
PARSEONLY:                                       P A R S E O N L Y;
PARTIAL:                                         P A R T I A L;
PARTITION:                                       P A R T I T I O N;
PARTITIONS:                                      P A R T I T I O N S;
PARTNER:                                         P A R T N E R;
PASSWORD:                                        P A S S W O R D;
PATH:                                            P A T H;
PAUSE:                                           P A U S E;
PERCENT:                                         P E R C E N T;
PERCENTILE_CONT:                                 P E R C E N T I L E  UNDERLINE  C O N T;
PERCENTILE_DISC:                                 P E R C E N T I L E  UNDERLINE  D I S C;
PERCENT_RANK:                                    P E R C E N T  UNDERLINE  R A N K;
PERIOD:                                          P E R I O D;
PERMISSION_SET:                                  P E R M I S S I O N  UNDERLINE  S E T;
PERSISTED:                                       P E R S I S T E D;
PERSIST_SAMPLE_PERCENT:                          P E R S I S T  UNDERLINE  S A M P L E  UNDERLINE  P E R C E N T;
PERSISTENT_LOG_BUFFER:                           P E R S I S T E N T  UNDERLINE  L O G  UNDERLINE  B U F F E R;
PERSISTENT_VERSION_STORE_FILEGROUP:              P E R S I S T E N T  UNDERLINE  V E R S I O N  UNDERLINE  S T O R E  UNDERLINE  F I L E G R O U P;
PER_CPU:                                         P E R  UNDERLINE  C P U;
PER_DB:                                          P E R  UNDERLINE  D B;
PER_NODE:                                        P E R  UNDERLINE  N O D E;
PIVOT:                                           P I V O T;
PLAN:                                            P L A N;
PLATFORM:                                        P L A T F O R M;
POISON_MESSAGE_HANDLING:                         P O I S O N  UNDERLINE  M E S S A G E  UNDERLINE  H A N D L I N G;
POLICY:                                          P O L I C Y;
POOL:                                            P O O L;
POPULATION:                                      P O P U L A T I O N;
PORT:                                            P O R T;
POSITION:                                        P O S I T I O N;
PRECEDING:                                       P R E C E D I N G;
PRECISION:                                       P R E C I S I O N;
PREDICATE:                                       P R E D I C A T E;
PREDICT:                                         P R E D I C T;
PRIMARY:                                         P R I M A R Y;
PRIMARY_ROLE:                                    P R I M A R Y  UNDERLINE  R O L E;
PRINT:                                           P R I N T;
PRIOR:                                           P R I O R;
PRIORITY:                                        P R I O R I T Y;
PRIORITY_LEVEL:                                  P R I O R I T Y  UNDERLINE  L E V E L;
PRIVATE:                                         P R I V A T E;
PRIVATE_KEY:                                     P R I V A T E  UNDERLINE  K E Y;
PRIVILEGES:                                      P R I V I L E G E S;
PROC:                                            P R O C;
PROCEDURE:                                       P R O C E D U R E;
PROCEDURE_CACHE:                                 P R O C E D U R E  UNDERLINE  C A C H E;
PROCEDURE_NAME:                                  P R O C E D U R E  UNDERLINE  N A M E;
PROCESS:                                         P R O C E S S;
PROFILE:                                         P R O F I L E;
PROPERTY:                                        P R O P E R T Y;
PROVIDER:                                        P R O V I D E R;
PROVIDER_KEY_NAME:                               P R O V I D E R  UNDERLINE  K E Y  UNDERLINE  N A M E;
PUBLIC:                                          P U B L I C;
PYTHON:                                          P Y T H O N;
QUERY:                                           Q U E R Y;
QUERYTRACEON:                                    Q U E R Y T R A C E O N;
QUERY_CAPTURE_MODE:                              Q U E R Y  UNDERLINE  C A P T U R E  UNDERLINE  M O D E;
QUERY_CAPTURE_POLICY:                            Q U E R Y  UNDERLINE  C A P T U R E  UNDERLINE  P O L I C Y;
QUERY_STORE:                                     Q U E R Y  UNDERLINE  S T O R E;
QUEUE:                                           Q U E U E;
QUEUE_DELAY:                                     Q U E U E  UNDERLINE  D E L A Y;
QUOTED_IDENTIFIER:                               Q U O T E D  UNDERLINE  I D E N T I F I E R;
R:                                               [Rr];
RAISERROR:                                       R A I S E R R O R;
RANDOMIZED:                                      R A N D O M I Z E D;
RANGE:                                           R A N G E;
RANK:                                            R A N K;
RAW:                                             R A W;
RC2:                                             R C '2';
RC4:                                             R C '4';
RC4_128:                                         R C '4'  UNDERLINE  '128';
READ:                                            R E A D;
READCOMMITTED:                                   R E A D C O M M I T T E D;
READCOMMITTEDLOCK:                               R E A D C O M M I T T E D L O C K;
READONLY:                                        R E A D O N L Y;
READPAST:                                        R E A D P A S T;
READTEXT:                                        R E A D T E X T;
READUNCOMMITTED:                                 R E A D U N C O M M I T T E D;
READWRITE:                                       R E A D W R I T E;
READ_COMMITTED_SNAPSHOT:                         R E A D  UNDERLINE  C O M M I T T E D  UNDERLINE  S N A P S H O T;
READ_ONLY:                                       R E A D  UNDERLINE  O N L Y;
READ_ONLY_ROUTING_LIST:                          R E A D  UNDERLINE  O N L Y  UNDERLINE  R O U T I N G  UNDERLINE  L I S T;
READ_WRITE:                                      R E A D  UNDERLINE  W R I T E;
READ_WRITE_FILEGROUPS:                           R E A D  UNDERLINE  W R I T E  UNDERLINE  F I L E G R O U P S;
REBUILD:                                         R E B U I L D;
RECEIVE:                                         R E C E I V E;
RECOMPILE:                                       R E C O M P I L E;
RECONFIGURE:                                     R E C O N F I G U R E;
RECOVERY:                                        R E C O V E R Y;
RECURSIVE_TRIGGERS:                              R E C U R S I V E  UNDERLINE  T R I G G E R S;
REDISTRIBUTE:                                    R E D I S T R I B U T E;
REDUCE:                                          R E D U C E;
REFERENCES:                                      R E F E R E N C E S;
REGENERATE:                                      R E G E N E R A T E;
RELATED_CONVERSATION:                            R E L A T E D  UNDERLINE  C O N V E R S A T I O N;
RELATED_CONVERSATION_GROUP:                      R E L A T E D  UNDERLINE  C O N V E R S A T I O N  UNDERLINE  G R O U P;
RELATIVE:                                        R E L A T I V E;
REMOTE:                                          R E M O T E;
REMOTE_PROC_TRANSACTIONS:                        R E M O T E  UNDERLINE  P R O C  UNDERLINE  T R A N S A C T I O N S;
REMOTE_SERVICE_NAME:                             R E M O T E  UNDERLINE  S E R V I C E  UNDERLINE  N A M E;
REMOVE:                                          R E M O V E;
REORGANIZE:                                      R E O R G A N I Z E;
REPEATABLE:                                      R E P E A T A B L E;
REPEATABLEREAD:                                  R E P E A T A B L E R E A D;
REPLACE:                                         R E P L A C E;
REPLICA:                                         R E P L I C A;
REPLICATE:                                       R E P L I C A T E;
REPLICATION:                                     R E P L I C A T I O N;
REQUEST_MAX_CPU_TIME_SEC:                        R E Q U E S T  UNDERLINE  M A X  UNDERLINE  C P U  UNDERLINE  T I M E  UNDERLINE  S E C;
REQUEST_MAX_MEMORY_GRANT_PERCENT:                R E Q U E S T  UNDERLINE  M A X  UNDERLINE  M E M O R Y  UNDERLINE  G R A N T  UNDERLINE  P E R C E N T;
REQUEST_MEMORY_GRANT_TIMEOUT_SEC:                R E Q U E S T  UNDERLINE  M E M O R Y  UNDERLINE  G R A N T  UNDERLINE  T I M E O U T  UNDERLINE  S E C;
REQUIRED:                                        R E Q U I R E D;
REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT:     R E Q U I R E D  UNDERLINE  S Y N C H R O N I Z E D  UNDERLINE  S E C O N D A R I E S  UNDERLINE  T O  UNDERLINE  C O M M I T;
RESAMPLE:                                        R E S A M P L E;
RESERVE_DISK_SPACE:                              R E S E R V E  UNDERLINE  D I S K  UNDERLINE  S P A C E;
RESET:                                           R E S E T;
RESOURCE:                                        R E S O U R C E;
RESOURCES:                                       R E S O U R C E S;
RESOURCE_MANAGER_LOCATION:                       R E S O U R C E  UNDERLINE  M A N A G E R  UNDERLINE  L O C A T I O N;
RESTART:                                         R E S T A R T;
RESTORE:                                         R E S T O R E;
RESTRICT:                                        R E S T R I C T;
RESTRICTED_USER:                                 R E S T R I C T E D  UNDERLINE  U S E R;
RESULT:                                          R E S U L T;
RESUME:                                          R E S U M E;
RETAINDAYS:                                      R E T A I N D A Y S;
RETENTION:                                       R E T E N T I O N;
RETURN:                                          R E T U R N;
RETURNS:                                         R E T U R N S;
REVERT:                                          R E V E R T;
REVOKE:                                          R E V O K E;
REWIND:                                          R E W I N D;
RIGHT:                                           R I G H T;
ROBUST:                                          R O B U S T;
ROLE:                                            R O L E;
ROLLBACK:                                        R O L L B A C K;
ROLLUP:                                          R O L L U P;
ROOT:                                            R O O T;
ROUND_ROBIN:                                     R O U N D UNDERLINE R O B I N;
ROUTE:                                           R O U T E;
ROW:                                             R O W;
ROWCOUNT:                                        R O W C O U N T;
ROWGUID:                                         R O W G U I D;
ROWGUIDCOL:                                      R O W G U I D C O L;
ROWLOCK:                                         R O W L O C K;
ROWS:                                            R O W S;
ROW_NUMBER:                                      R O W  UNDERLINE  N U M B E R;
RSA_1024:                                        R S A  UNDERLINE  '1024';
RSA_2048:                                        R S A  UNDERLINE  '2048';
RSA_3072:                                        R S A  UNDERLINE  '3072';
RSA_4096:                                        R S A  UNDERLINE  '4096';
RSA_512:                                         R S A  UNDERLINE  '512';
RULE:                                            R U L E;
RUNTIME:                                         R U N T I M E;
SAFE:                                            S A F E;
SAFETY:                                          S A F E T Y;
SAMPLE:                                          S A M P L E;
SAVE:                                            S A V E;
SCALEOUTEXECUTION:                               S C A L E O U T E X E C U T I O N;
SCHEDULER:                                       S C H E D U L E R;
SCHEMA:                                          S C H E M A;
SCHEMABINDING:                                   S C H E M A B I N D I N G;
SCHEME:                                          S C H E M E;
SCOPED:                                          S C O P E D;
SCRIPT:                                          S C R I P T;
SCROLL:                                          S C R O L L;
SCROLL_LOCKS:                                    S C R O L L  UNDERLINE  L O C K S;
SEARCH:                                          S E A R C H;
SECOND:                                          S E C O N D;
SECONDARY:                                       S E C O N D A R Y;
SECONDARY_ONLY:                                  S E C O N D A R Y  UNDERLINE  O N L Y;
SECONDARY_ROLE:                                  S E C O N D A R Y  UNDERLINE  R O L E;
SECONDS:                                         S E C O N D S;
SECRET:                                          S E C R E T;
SECURABLES:                                      S E C U R A B L E S;
SECURITY:                                        S E C U R I T Y;
SECURITYAUDIT:                                   S E C U R I T Y A U D I T;
SECURITY_LOG:                                    S E C U R I T Y  UNDERLINE  L O G;
SEEDING_MODE:                                    S E E D I N G  UNDERLINE  M O D E;
SELECT:                                          S E L E C T;
SELECTIVE:                                       S E L E C T I V E;
SELF:                                            S E L F;
SEMANTICKEYPHRASETABLE:                          S E M A N T I C K E Y P H R A S E T A B L E;
SEMANTICSIMILARITYDETAILSTABLE:                  S E M A N T I C S I M I L A R I T Y D E T A I L S T A B L E;
SEMANTICSIMILARITYTABLE:                         S E M A N T I C S I M I L A R I T Y T A B L E;
SEMI_SENSITIVE:                                  S E M I  UNDERLINE  S E N S I T I V E;
SEND:                                            S E N D;
SENT:                                            S E N T;
SEQUENCE:                                        S E Q U E N C E;
SEQUENCE_NUMBER:                                 S E Q U E N C E  UNDERLINE  N U M B E R;
SERIALIZABLE:                                    S E R I A L I Z A B L E;
SERVER:                                          S E R V E R;
SERVICE:                                         S E R V I C E;
SERVICE_BROKER:                                  S E R V I C E  UNDERLINE  B R O K E R;
SERVICE_NAME:                                    S E R V I C E  UNDERLINE  N A M E;
SESSION:                                         S E S S I O N;
SESSION_TIMEOUT:                                 S E S S I O N  UNDERLINE  T I M E O U T;
SESSION_USER:                                    S E S S I O N  UNDERLINE  U S E R;
SET:                                             S E T;
SETERROR:                                        S E T E R R O R;
SETS:                                            S E T S;
SETTINGS:                                        S E T T I N G S;
SETUSER:                                         S E T U S E R;
SHARE:                                           S H A R E;
SHOWPLAN:                                        S H O W P L A N;
SHOWPLAN_ALL:                                    S H O W P L A N  UNDERLINE  A L L;
SHOWPLAN_TEXT:                                   S H O W P L A N  UNDERLINE  T E X T;
SHOWPLAN_XML:                                    S H O W P L A N  UNDERLINE  X M L;
SHRINKLOG:                                       S H R I N K L O G;
SHUTDOWN:                                        S H U T D O W N;
SID:                                             S I D;
SIGNATURE:                                       S I G N A T U R E;
SIMPLE:                                          S I M P L E;
SINGLE_USER:                                     S I N G L E  UNDERLINE  U S E R;
SINGLETON:                                       S I N G L E T O N;
SIZE:                                            S I Z E;
SIZE_BASED_CLEANUP_MODE:                         S I Z E  UNDERLINE  B A S E D  UNDERLINE  C L E A N U P  UNDERLINE  M O D E;
SKIP_KEYWORD:                                    S K I P;
SMALLINT:                                        S M A L L I N T;
SNAPSHOT:                                        S N A P S H O T;
SOFTNUMA:                                        S O F T N U M A;
SOME:                                            S O M E;
SOURCE:                                          S O U R C E;
SPARSE:                                          S P A R S E;
SPATIAL:                                         S P A T I A L;
SPATIAL_WINDOW_MAX_CELLS:                        S P A T I A L  UNDERLINE  W I N D O W  UNDERLINE  M A X  UNDERLINE  C E L L S;
SPECIFICATION:                                   S P E C I F I C A T I O N;
SPLIT:                                           S P L I T;
SQL:                                             S Q L;
SQLDUMPERFLAGS:                                  S Q L D U M P E R F L A G S;
SQLDUMPERPATH:                                   S Q L D U M P E R P A T H;
SQLDUMPERTIMEOUT:                                S Q L D U M P E R T I M E O U T S;
STALE_CAPTURE_POLICY_THRESHOLD:                  S T A L E  UNDERLINE  C A P T U R E  UNDERLINE  P O L I C Y  UNDERLINE  T H R E S H O L D;
STALE_QUERY_THRESHOLD_DAYS:                      S T A L E  UNDERLINE  Q U E R Y  UNDERLINE  T H R E S H O L D  UNDERLINE  D A Y S;
STANDBY:                                         S T A N D B Y;
START:                                           S T A R T;
STARTED:                                         S T A R T E D;
STARTUP_STATE:                                   S T A R T U P  UNDERLINE  S T A T E;
START_DATE:                                      S T A R T  UNDERLINE  D A T E;
STATE:                                           S T A T E;
STATEMENT:                                       S T A T E M E N T;
STATIC:                                          S T A T I C;
STATISTICAL_SEMANTICS:                           S T A T I S T I C A L  UNDERLINE  S E M A N T I C S;
STATISTICS:                                      S T A T I S T I C S;
STATS:                                           S T A T S;
STATS_STREAM:                                    S T A T S  UNDERLINE  S T R E A M;
STATUS:                                          S T A T U S;
STATUSONLY:                                      S T A T U S O N L Y;
STDEV:                                           S T D E V;
STDEVP:                                          S T D E V P;
STOP:                                            S T O P;
STOPAT:                                          S T O P A T;
STOPATMARK:                                      S T O P A T M A R K;
STOPBEFOREMARK:                                  S T O P B E F O R E M A R K;
STOPLIST:                                        S T O P L I S T;
STOPPED:                                         S T O P P E D;
STOP_ON_ERROR:                                   S T O P  UNDERLINE  O N  UNDERLINE  E R R O R;
STRING_AGG:                                      S T R I N G  UNDERLINE  A G G;
STRING_DELIMITER:                                S T R I N G  UNDERLINE  D E L I M I T E R;
STUFF:                                           S T U F F;
SUBJECT:                                         S U B J E C T;
SUBSCRIBE:                                       S U B S C R I B E;
SUBSCRIPTION:                                    S U B S C R I P T I O N;
SUBSTRING:                                       S U B S T R I N G;
SUM:                                             S U M;
SUPPORTED:                                       S U P P O R T E D;
SUSPEND:                                         S U S P E N D;
SWITCH:                                          S W I T C H;
SYMMETRIC:                                       S Y M M E T R I C;
SYNCHRONOUS_COMMIT:                              S Y N C H R O N O U S  UNDERLINE  C O M M I T;
SYNONYM:                                         S Y N O N Y M;
SYSTEM:                                          S Y S T E M;
SYSTEM_TIME:                                     S Y S T E M  UNDERLINE  T I M E;
SYSTEM_USER:                                     S Y S T E M  UNDERLINE  U S E R;
SYSTEM_VERSIONING:                               S Y S T E M  UNDERLINE  V E R S I O N I N G;
TABLE:                                           T A B L E;
TABLESAMPLE:                                     T A B L E S A M P L E;
TABLOCK:                                         T A B L O C K;
TABLOCKX:                                        T A B L O C K X;
TAKE:                                            T A K E;
TAPE:                                            T A P E;
TARGET:                                          T A R G E T;
TARGET_RECOVERY_TIME:                            T A R G E T  UNDERLINE  R E C O V E R Y  UNDERLINE  T I M E;
T:                                               [Tt];
TB:                                              T B;
TCP:                                             T C P;
TEXTIMAGE_ON:                                    T E X T I M A G E  UNDERLINE  O N;
TEXTSIZE:                                        T E X T S I Z E;
THEN:                                            T H E N;
THROW:                                           T H R O W;
TIES:                                            T I E S;
TIME:                                            T I M E;
TIMEOUT:                                         T I M E O U T;
TIMER:                                           T I M E R;
TIMESTAMP:                                       T I M E S T A M P;
TINYINT:                                         T I N Y I N T;
TO:                                              T O;
TOP:                                             T O P;
TORN_PAGE_DETECTION:                             T O R N  UNDERLINE  P A G E  UNDERLINE  D E T E C T I O N;
TOSTRING:                                        T O S T R I N G;
TOTAL_COMPILE_CPU_TIME_MS:                       T O T A L  UNDERLINE  C O M P I L E  UNDERLINE  C P U  UNDERLINE  T I M E  UNDERLINE  M S;
TOTAL_EXECUTION_CPU_TIME_MS:                     T O T A L  UNDERLINE  E X E C U T I O N  UNDERLINE  C P U  UNDERLINE  T I M E  UNDERLINE  M S;
TRACE:                                           T R A C E;
TRACKING:                                        T R A C K I N G;
TRACK_CAUSALITY:                                 T R A C K  UNDERLINE  C A U S A L I T Y;
TRACK_COLUMNS_UPDATED:                           T R A C K  UNDERLINE  C O L U M N S  UNDERLINE  U P D A T E D;
TRAN:                                            T R A N;
TRANSACTION:                                     T R A N S A C T I O N;
TRANSACTION_ID:                                  T R A N S A C T I O N  UNDERLINE  I D;
TRANSFER:                                        T R A N S F E R;
TRANSFORM_NOISE_WORDS:                           T R A N S F O R M  UNDERLINE  N O I S E  UNDERLINE  W O R D S;
TRIGGER:                                         T R I G G E R;
TRIM:                                            T R I M;
TRIPLE_DES:                                      T R I P L E  UNDERLINE  D E S;
TRIPLE_DES_3KEY:                                 T R I P L E  UNDERLINE  D E S  UNDERLINE  '3' K E Y;
TRUE:                                            T R U E;
TRUNCATE:                                        T R U N C A T E;
TRUSTWORTHY:                                     T R U S T W O R T H Y;
TRY:                                             T R Y;
TRY_CAST:                                        T R Y  UNDERLINE  C A S T;
TRY_CONVERT:                                     T R Y  UNDERLINE  C O N V E R T;
TRY_PARSE:                                       T R Y  UNDERLINE  P A R S E;
TS:                                              T S;
TSEQUAL:                                         T S E Q U A L;
TSQL:                                            T S Q L;
TWO_DIGIT_YEAR_CUTOFF:                           T W O  UNDERLINE  D I G I T  UNDERLINE  Y E A R  UNDERLINE  C U T O F F;
TYPE:                                            T Y P E;
TYPE_WARNING:                                    T Y P E  UNDERLINE  W A R N I N G;
UNBOUNDED:                                       U N B O U N D E D;
UNCHECKED:                                       U N C H E C K E D;
UNCOMMITTED:                                     U N C O M M I T T E D;
UNDEFINED:                                       U N D E F I N E D;
UNION:                                           U N I O N;
UNIQUE:                                          U N I Q U E;
UNKNOWN:                                         U N K N O W N;
UNLIMITED:                                       U N L I M I T E D;
UNLOCK:                                          U N L O C K;
UNMASK:                                          U N M A S K;
UNPIVOT:                                         U N P I V O T;
UNSAFE:                                          U N S A F E;
UOW:                                             U O W;
UPDATE:                                          U P D A T E;
UPDATETEXT:                                      U P D A T E T E X T;
UPDLOCK:                                         U P D L O C K;
URL:                                             U R L;
USE:                                             U S E;
USE_TYPE_DEFAULT:                                U S E  UNDERLINE  T Y P E  UNDERLINE  D E F A U L T;
USED:                                            U S E D;
USER:                                            U S E R;
USING:                                           U S I N G;
VALIDATION:                                      V A L I D A T I O N;
VALID_XML:                                       V A L I D  UNDERLINE  X M L;
VALUE:                                           V A L U E;
VALUES:                                          V A L U E S;
VAR:                                             V A R;
VARBINARY_KEYWORD:                               V A R B I N A R Y;
VARP:                                            V A R P;
VARYING:                                         V A R Y I N G;
VERBOSELOGGING:                                  V E R B O S E L O G G I N G;
VERSION:                                         V E R S I O N;
VIEW:                                            V I E W;
VIEWS:                                           V I E W S;
VIEW_METADATA:                                   V I E W  UNDERLINE  M E T A D A T A;
VISIBILITY:                                      V I S I B I L I T Y;
WAIT:                                            W A I T;
WAITFOR:                                         W A I T F O R;
WAIT_AT_LOW_PRIORITY:                            W A I T  UNDERLINE  A T  UNDERLINE  L O W  UNDERLINE  P R I O R I T Y;
WAIT_STATS_CAPTURE_MODE:                         W A I T  UNDERLINE  S T A T S  UNDERLINE  C A P T U R E  UNDERLINE  M O D E;
WEEK:                                            W E E K;
WEEKS:                                           W E E K S;
WELL_FORMED_XML:                                 W E L L  UNDERLINE  F O R M E D  UNDERLINE  X M L;
WHEN:                                            W H E N;
WHEN_SUPPORTED:                                  W H E N  UNDERLINE  S U P P O R T E D;
WHERE:                                           W H E R E;
WHILE:                                           W H I L E;
WINDOWS:                                         W I N D O W S;
WITH:                                            W I T H;
WITHIN:                                          W I T H I N;
WITHOUT:                                         W I T H O U T;
WITHOUT_ARRAY_WRAPPER:                           W I T H O U T  UNDERLINE  A R R A Y  UNDERLINE  W R A P P E R;
WITNESS:                                         W I T N E S S;
WORK:                                            W O R K;
WORKLOAD:                                        W O R K L O A D;
WRITETEXT:                                       W R I T E T E X T;
XACT_ABORT:                                      X A C T  UNDERLINE  A B O R T;
XLOCK:                                           X L O C K;
XMAX:                                            X M A X;
XMIN:                                            X M I N;
XML:                                             X M L;
XMLDATA:                                         X M L D A T A;
XMLNAMESPACES:                                   X M L N A M E S P A C E S;
XMLSCHEMA:                                       X M L S C H E M A;
XSINIL:                                          X S I N I L;
XQUERY:                                          X Q U E R Y;
YEAR:                                            Y E A R;
YEARS:                                           Y E A R S;
YMAX:                                            Y M A X;
YMIN:                                            Y M I N;
ZONE:                                            Z O N E;

//Build-ins:
VARCHAR:                                         V A R C H A R;
NVARCHAR:                                        N V A R C H A R;


SPACE:              [ \t\r\n]+    -> channel(HIDDEN); // Thus error messages have spaces

// the following are ignored by SQL Server
CHAR_XA0_NBSP:      '\u00a0'      -> skip;   // non-breaking space
CHAR_X08_BS:        '\u0008'      -> skip;   // backspace
CHAR_X0B_VT:        '\u000b'      -> skip;   // vertical tab
CHAR_X0C_FF:        '\u000c'      -> skip;   // form feed

// https://en.wikipedia.org/wiki/Whitespace_character
CHAR_ZWSP:          '\u200b'      -> skip;   // zero width space
CHAR_NNNBSP:        '\u202f'      -> skip;   // narrow no-break space
CHAR_IDGSP:         '\u3000'      -> skip;   // ideographic space

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/slash-star-comment-transact-sql
COMMENT:            '/*' (COMMENT | .)*? '*/' -> skip;
LINE_COMMENT:       '--' ~[\r\n]* -> skip;

//LINE_CONTINUATION:  '\\' \r? \n;

// The next two rules are mutually exclusive - which rule we choose depends on the
// value of QUOTED_IDENTIFIER guc, which reflects the SET QUOTED_IDENTFIER statements encountered.
// The first rule chooses to return a DOUBLE_QUOTE_ID if QUOTED_IDENTIFIER guc is true.
// The second rule chooses to return a STRING if QUOTED_IDENTIFIER guc is false
// NB: for performance reasons, put the QUOTED_IDENTIFIER guc condition at the end, not at the start.
DOUBLE_QUOTE_ID:     '"' (~'"' | '""' )* '"' {pltsql_quoted_identifier == true}?;
STRING:              'N'? ('\'' (~'\'' | '\'\'')* '\'' | '"' (~'"' | '""')* '"'  {pltsql_quoted_identifier == false}? );

SINGLE_QUOTE:       '\'';
SQUARE_BRACKET_ID:  '[' (~']' | ']' ']')* ']';
LOCAL_ID:           '@' ([_$@#0-9] | LETTER )*;

DECIMAL:             DEC_DIGIT+;
ID:                  ( [_#] | LETTER) ( [_#$@0-9] | LETTER)*;
BINARY:              '0' [Xx] ( HEX_DIGIT | '\\' [\r]? [\n] )*;
FLOAT:               DEC_DOT_DEC;
REAL:                (DECIMAL | DEC_DOT_DEC) ([Ee] ([+-]? DEC_DIGIT+)?);

MONEY:               CURRENCY_SYMBOL [ ]* ('+'|'-')? (DECIMAL | DEC_DOT_DEC);

IPV4_ADDR:           DECIMAL DOT DECIMAL DOT DECIMAL DOT DECIMAL;

EQUAL:               '=';

GREATER:             '>';
LESS:                '<';
EXCLAMATION:         '!';

PLUS_ASSIGN:         '+=';
MINUS_ASSIGN:        '-=';
MULT_ASSIGN:         '*=';
EQUAL_STAR_OJ:       '=*';
DIV_ASSIGN:          '/=';
MOD_ASSIGN:          '%=';
AND_ASSIGN:          '&=';
XOR_ASSIGN:          '^=';
OR_ASSIGN:           '|=';

DOT:                 '.';
UNDERLINE:           '_';
AT:                  '@';
SHARP:               '#';
DOLLAR:              '$';
LR_BRACKET:          '(';
RR_BRACKET:          ')';
L_CURLY:             '{';
R_CURLY:             '}';
COMMA:               ',';
SEMI:                ';';
COLON:               ':';
STAR:                '*';
DIVIDE:              '/';
PERCENT_SIGN:        '%';
PLUS:                '+';
MINUS:               '-';
BIT_NOT:             '~';
BIT_OR:              '|';
BIT_AND:             '&';
BIT_XOR:             '^';

BACKSLASH:            '\\';
DOUBLE_BACK_SLASH:    '\\\\';
DOUBLE_FORWARD_SLASH: '//';

fragment DEC_DOT_DEC:  (DEC_DIGIT+ '.' DEC_DIGIT+ |  DEC_DIGIT+ '.' | '.' DEC_DIGIT+);
fragment HEX_DIGIT:    [0-9A-Fa-f];
fragment DEC_DIGIT:    [0-9];

// case-insensitive letters
fragment A: ('A'|'a');
fragment B: ('B'|'b');
fragment C: ('C'|'c');
// fragment D: ('D'|'d');  // redundant, since already defined as token above
fragment E: ('E'|'e');
fragment F: ('F'|'f');
fragment G: ('G'|'g');
fragment H: ('H'|'h');
fragment I: ('I'|'i');
fragment J: ('J'|'j');
fragment K: ('K'|'k');
fragment L: ('L'|'l');
fragment M: ('M'|'m');
fragment N: ('N'|'n');
fragment O: ('O'|'o');
fragment P: ('P'|'p');
fragment Q: ('Q'|'q');
// fragment R: ('R'|'r');  // redundant, since already defined as token above
fragment S: ('S'|'s');
// fragment T: ('T'|'t');  // redundant, since already defined as token above
fragment U: ('U'|'u');
fragment V: ('V'|'v');
fragment W: ('W'|'w');
fragment X: ('X'|'x');
fragment Y: ('Y'|'y');
fragment Z: ('Z'|'z');

fragment CURRENCY_SYMBOL
    : '$'       // Dollar
    | '\u20AC'  // Euro
    | '\u00A2'  // Cent
    | '\u00A3'  // Pound
    | '\u00A4'  // Currency Sign
    | '\u00A5'  // Yen / Yuan
    | '\u09f2'  // Bengali Rupee Mark
    | '\u09f3'  // Bengali Rupee Sign
    | '\u20a8'  // Rupee
    | '\u0e3f'  // Thai Baht
    | '\u17db'  // Khmer Riel
    | '\u20a0'  // Euro Currency Sign
    | '\u20a1'  // Colon
    | '\u20a2'  // Cruzeiro
    | '\u20a3'  // French Franc
    | '\u20a4'  // Lira
    | '\u20a5'  // Mill
    | '\u20a6'  // Naira
    | '\u20a7'  // Peseta
    | '\u20a9'  // Won
    | '\u20aa'  // New Sheqel
    | '\u20ab'  // Dong
    | '\u20ad'  // Kip
    | '\u20ae'  // Tugrik
    | '\u20af'  // Drachma
    | '\u20b0'  // German Penny
    | '\u20b1'  // Peso
    | '\ufdfc'  // Rial
    | '\ufe69'  // Small Dollar
    | '\uff04'  // Fullwidth Dollar
    | '\uffe0'  // Fullwidth Cent
    | '\uffe1'  // Fullwidth Pound
    | '\uffe5'  // Fullwidth Yen
    | '\uffe6'  // Fullwidth Won
    ;

// use standard alphabet + extended Latin + Greek only; add more later if desired.
fragment LETTER
    : '\u0041'..'\u005a'  // A-Z
    | '\u0061'..'\u007a'  // a-z
    | '\u00c0'..'\u00d6'  // Latin-1 Supplement
    | '\u00d8'..'\u00f6'
    | '\u00f8'..'\u00ff'
    | '\u0100'..'\u017f'  // Latin Extended-A
    | '\u0180'..'\u024f'  // Latin Extended-B
    | '\u0250'..'\u02ad'  // IPA extensions
    | '\u0386'            // Greek
    | '\u0388'..'\u038a'
    | '\u038c'
    | '\u038e'..'\u03a1'
    | '\u03a3'..'\u03ce'
    | '\u03d0'..'\u03d7'
    | '\u03da'..'\u03f3'
//    | '\u0400'..'\u0481'  // Cyrillic
//    | '\u048c'..'\u04c4'
//    | '\u04c7'..'\u04c8'
//    | '\u04cb'..'\u04cc'
//    | '\u04d0'..'\u04f5'
//    | '\u04f8'..'\u04f9'
//    | '\u05d0'..'\u05ea'  // Hebrew
//    | '\u0621'..'\u063a'  // Arabic
//    | '\u0641'..'\u064a'
//    | '\u0660'..'\u0669'
//    | '\u0671'..'\u06d3'
//    | '\u06d5'
//    | '\u06f0'..'\u06f9'
//    | '\u06fa'..'\u06fc'
//    | '\u0e01'..'\u0e5b'  // Thai
//    | '\u1100'..'\u1159'  // Hangul/Korean
//    | '\u1161'..'\u11a2'
//    | '\u11a8'..'\u11f9'
//    | '\u1e00'..'\u1e9b'  // Latin Extended Additional
//    | '\u1ea0'..'\u1ef9'
//    | '\u1f00'..'\u1f15'  // Greek Extended
//    | '\u1f18'..'\u1f1d'
//    | '\u1f20'..'\u1f45'
//    | '\u1f48'..'\u1f4d'
//    | '\u1f50'..'\u1f57'
//    | '\u1f59'
//    | '\u1f5b'
//    | '\u1f5d'
//    | '\u1f5f'..'\u1f7d'
//    | '\u1f80'..'\u1fb4'
//    | '\u1fb6'..'\u1fbc'
//    | '\u1fc2'..'\u1fc4'
//    | '\u1fc6'..'\u1fcc'
//    | '\u1fd0'..'\u1fd3'
//    | '\u1fd6'..'\u1fdb'
//    | '\u1fe0'..'\u1fec'
//    | '\u1ff2'..'\u1ff4'
//    | '\u1ff6'..'\u1ffc'
//    | '\u210a'..'\u2113' // Letter-like symbols
//    | '\u2118'..'\u211d'
//    | '\u212a'..'\u212d'
//    | '\u212f'..'\u2131'
//    | '\u2133'..'\u2138'
//    | '\u2160'..'\u2183' // Roman Numeral
//    | '\u2460'..'\u24ea' // Enclosed Alphanumerics
//    | '\u2e80'..'\u2ef3' // CJK Radicals Supplement
//    | '\u2f00'..'\u2fd5' // Kangxi Radicals
//    | '\u3021'..'\u3029' // CJK
//    | '\u3031'..'\u3035'
//    | '\u3038'..'\u303a'
//    | '\u3041'..'\u3094' // Hiragana
//    | '\u309d'..'\u309e'
//    | '\u30a1'..'\u30fa' // Katakana
//    | '\u30fc'..'\u30fe'
//    | '\u3105'..'\u312c' // Bopomofo
//    | '\u3131'..'\u318e' // Hangul Compatability Jamo
//    | '\u31a0'..'\u31b7' // Bopomofo Extended
//    | '\ua000'..'\ua48c' // Yi Syllables
//    | '\uac00'           // Hangul Syllables
//    | '\ud7a3'
//    | '\uf900'..'\ufa2d' // CJK Compatibility Ideographs
//    | '\ufb00'..'\ufb06' // Alphabetic Presentation Forms
//    | '\ufb13'..'\ufb17'
//    | '\ufb1d'
//    | '\ufb1f'..'\ufb28'
//    | '\ufb2a'..'\ufb36'
//    | '\ufb38'..'\ufb3c'
//    | '\ufb3e'
//    | '\ufb40'..'\ufb41'
//    | '\ufb43'..'\ufb44'
//    | '\ufb46'..'\ufb4f'
//    | '\ufb50'..'\ufbb1' // Arabic Presentation Forms-A
//    | '\ufbd3'..'\ufd3d'
//    | '\ufd50'..'\ufd8f'
//    | '\ufd92'..'\ufdc7'
//    | '\ufdf0'..'\ufdfb'
//    | '\ufe70'..'\ufe72' // Arabic Presentation Forms-B
//    | '\ufe74'
//    | '\ufe76'..'\ufefc'
//    | '\uff21'..'\uff3a' // Halfwidth and Fullwidth Forms
//    | '\uff41'..'\uff5a'
//    | '\uff66'..'\uffbe'
//    | '\uffc2'..'\uffc7'
//    | '\uffca'..'\uffcf'
//    | '\uffd2'..'\uffd7'
//    | '\uffda'..'\uffdc'
//    | '\u10000'..'\u1F9FF'  //not supporting 4-byte chars
//    | '\u20000'..'\u2FA1F'
    ;


UNMATCHED_CHARACTER: .+?
    ;
