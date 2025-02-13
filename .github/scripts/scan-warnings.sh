#!/usr/bin/bash
LOG_FILE=~/psql/data/logfile
# File to store the current warnings
CURRENT_WARNINGS="actual-leak-warnings.out"

# Function to extract and classify warnings
extract_and_classify_warnings() {
    grep "WARNING:" "$LOG_FILE" | 
    awk -F"WARNING: " '{print $2}' | 
    sort | 
    while read -r line; do
        case "$line" in
            *"snapshot"*"still active"*)
                echo "SNAPSHOT_ACTIVE_WARNING: $line"
                ;;
            *"leak"*)
                echo "LEAK_WARNING: $line"
                ;;
            *"role"*"has not been granted membership"*|*"permission denied"*|*"transaction left non-empty SPI stack"*|*"cast will be ignored because the source data type is a domain"*|*"Query parsing failed using SLL parser mode but succeeded with LL mode"*|*"Using the TDS Foreign data wrapper (tds_fdw) as provider"*|*"Ignoring @provstr argument value"*|*"Product version setting by babelfishpg_tds.product_version GUC will have no effect on @@VERSION"*|*"no privileges could be revoked for"*|*"could not convert locale name"*|*"you don't own a lock of type"*|*"precision reduced to maximum allowed"*|*"WITH TIME ZONE precision reduced to maximum allowed"*|*"no privileges were granted for"*|*"parameter cannot be null"*|*"babelfishpg_tds.product_version cannot be set"*|*"could not convert locale name"*|*"This function has been deprecated and will no longer drop all users."*|*"cannot add relations to publication:"*|*"NUMERIC or DECIMAL type is cast to BIGINT"*)
                # These warnings are expected and will be ignored
                ;;
            *)
                echo "OTHER_WARNING: $line"
                ;;
        esac
    done
}

# Extract and classify warnings
extract_and_classify_warnings > "$CURRENT_WARNINGS"
ERROR_FOUND=false
# Check for other warning
OTHER_WARNING_COUNT=$(grep -c "OTHER_WARNING:" "$CURRENT_WARNINGS" || echo 0)

if [[ "$OTHER_WARNING_COUNT" -ge 1 ]]; then
    echo "Error: $OTHER_WARNING_COUNT unexpected warning type(s) detected."
    grep "OTHER_WARNING:" "$CURRENT_WARNINGS"
    ERROR_FOUND=true
fi
# Count warnings
SNAPSHOT_ACTIVE_COUNT=$(grep -c "SNAPSHOT_ACTIVE_WARNING:" "$CURRENT_WARNINGS")
LEAK_COUNT=$(grep -c "LEAK_WARNING:" "$CURRENT_WARNINGS")

if [[ "$SNAPSHOT_ACTIVE_COUNT" -ne 44 ]]; then
    echo "Error: Expected 44 'snapshot ... still active' warnings, but found $SNAPSHOT_ACTIVE_COUNT"
    ERROR_FOUND=true
fi

if [[ "$LEAK_COUNT" -ne 380 ]]; then
    echo "Error: Expected 380 leak warnings, but found $LEAK_COUNT"
    ERROR_FOUND=true
fi

if [[ "$ERROR_FOUND" = true ]]; then
    echo "Unexpected warning counts detected. Please investigate."
    echo "Snapshot 'still active' warnings: $SNAPSHOT_ACTIVE_COUNT"
    echo "Leak warnings: $LEAK_COUNT"
    exit 1
fi
echo "Warning counts are as expected:"
echo "Snapshot 'still active' warnings: $SNAPSHOT_ACTIVE_COUNT"
echo "Leak warnings: $LEAK_COUNT"