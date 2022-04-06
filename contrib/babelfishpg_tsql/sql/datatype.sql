-- Types with different default typmod behavior
SET enable_domain_typmod = TRUE;

CREATE DOMAIN sys.CURSOR AS REFCURSOR;

RESET enable_domain_typmod;

-- At this point, the hooks are loaded, so sys.name will pick up the correct 
-- collation.
CREATE DOMAIN sys._ci_sysname AS sys.sysname;
