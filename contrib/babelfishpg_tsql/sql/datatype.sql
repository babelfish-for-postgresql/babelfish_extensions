-- Types with different default typmod behavior
SET enable_domain_typmod = TRUE;

CREATE DOMAIN sys.CURSOR AS REFCURSOR;

RESET enable_domain_typmod;
