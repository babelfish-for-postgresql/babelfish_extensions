-- Simple SET
SET lc_messages ='fr_FR.utf8';
show lc_messages;
reset lc_messages;

-- Inside transaction with commit
BEGIN;
	SET lc_messages = 'fr_FR.utf8';
COMMIT;
show lc_messages;
reset lc_messages;

-- Inside transaction with rollback
BEGIN;
	SET lc_messages = 'fr_FR.utf8';
ROLLBACK;
show lc_messages;
reset lc_messages;

-- Inside transaction with rollback to savepoint
BEGIN;
	SET lc_messages = 'en_GB.utf8';
	SAVEPOINT SP1;
	SET lc_messages = 'fr_FR.utf8';
	show lc_messages;
	ROLLBACK TO SAVEPOINT SP1;
	show lc_messages;
ROLLBACK;
show lc_messages;
reset lc_messages;

-- Inside procedure
CREATE PROCEDURE lc_proc()
AS $$
begin
	SET lc_messages ='fr_FR.utf8';
	commit;
end;
$$ LANGUAGE plpgsql;
CALL lc_proc();
show lc_messages;
drop procedure lc_proc();
reset lc_messages;

CREATE PROCEDURE lc_proc()
AS $$
begin
	SET lc_messages ='fr_FR.utf8';
	rollback;
end;
$$ LANGUAGE plpgsql;
CALL lc_proc();
show lc_messages;

-- Cleanup
drop procedure lc_proc();
reset lc_messages;
