USE master;
GO

SELECT FORMATMESSAGE('%s', 'Hi')
GO

SELECT FORMATMESSAGE('Hello %s', CAST('World' as VARCHAR(10)))
GO

SELECT FORMATMESSAGE('Testing %s, %s, %s', CAST('one' AS VARCHAR(10)), CAST('two' AS VARCHAR(10)), CAST('three' AS VARCHAR(10)))
GO

SELECT formatmessage('Testing adjacent %d%s%d%s', 1, CAST('two' as VARCHAR(10)), 3, CAST('four' AS VARCHAR(10)))
GO

SELECT formatmessage('d: %d %d %d', 1, 2, 3)
GO

SELECT formatmessage('i: %i, %i, %i', 1, 2, 3)
GO

SELECT formatmessage('Extra params with no format', CAST('asdf' AS VARCHAR(10)), CAST('asdf' AS VARCHAR(10)), CAST('asdf' AS VARCHAR(10)))
GO

select formatmessage('Not enough parameters: %s, %s, %s, %s', CAST('1' AS VARCHAR(10)), CAST('2' AS VARCHAR(10)))
GO

SELECT formatmessage('More parameters than %s', CAST('placeholders' AS VARCHAR(12)), CAST('to' AS VARCHAR(10)), CAST('handle' AS VARCHAR(10)))
GO

SELECT formatmessage('Testing no inputs with placeholder %s')
GO

SELECT FORMATMESSAGE('Unsigned hexadecimal %x, %X, %X, %X, %x', 11, 11, -11, 50, -50)
GO

SELECT FORMATMESSAGE('Unsigned int %u, %u', 50, -50)
GO

SELECT FORMATMESSAGE('Unsigned octal %o, %o', 50, -50)
GO

SELECT FORMATMESSAGE('Nonlatin: 亚马%s', CAST('逊' AS VARCHAR(10)))
GO

SELECT FORMATMESSAGE('Long string tests: \n\n Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla consequat metus sit amet lectus vulputate lacinia. Nam vel auctor enim, quis finibus lorem. Quisque maximus egestas est, et vehicula lectus. Curabitur sodales efficitur nibh, quis varius metus semper vel. Aenean quis rhoncus tortor. Nullam eleifend blandit imperdiet. Donec a gravida ex. Cras ac nulla orci. Fusce ut est ac odio consequat rutrum. Morbi diam erat, blandit ut nunc efficitur, venenatis placerat nunc. Sed laoreet aliquam leo. Quisque vestibulum hendrerit mi, at cursus eros aliquet vitae. Mauris a sem blandit, interdum ligula et, feugiat nulla. Sed quis ipsum at dolor congue vulputate at elementum ex. Integer iaculis, libero nec pulvinar molestie, neque mi vestibulum nisl, in volutpat metus arcu in purus. Praesent ullamcorper mi sit amet consectetur mattis. Sed quis ex placerat, finibus purus dignissim, porttitor nibh. Maecenas dignissim tristique tempus. Proin venenatis sem a orci sagittis, vel consequat sem vestibulum. Donec consectetur cursus tortor, eget volutpat lacus posuere a. Pellentesque eu orci hendrerit sapien dictum fringilla. Morbi rutrum mollis ipsum sit amet hendrerit. Nullam nec felis tortor. Mauris augue turpis, volutpat ac odio in, faucibus venenatis purus. Curabitur scelerisque pharetra nunc non mattis. Nunc sagittis euismod mi sit amet gravida. Integer malesuada pretium nibh. Maecenas sagittis facilisis enim, et hendrerit nulla fringilla in. Nam pulvinar, nibh non mattis hendrerit, arcu velit molestie sem, sed rutrum arcu odio a risus. Pellentesque lorem sem, dictum nec sem nec, congue ornare purus. Mauris id efficitur mi. Phasellus nec tortor lacus. Integer vitae tempus lorem. Suspendisse augue orci, volutpat vitae magna id, venenatis viverra nunc. Sed lobortis faucibus ante, ac porttitor risus. Proin viverra vestibulum enim, sed dignissim erat lobortis scelerisque. Aliquam et diam ut lacus dictum tristique. Sed a sapien quis nulla semper elementum. Ut fringilla laoreet luctus. Vivamus mi ipsum. %s', CAST('Ellipsis' AS VARCHAR(3000)))
GO

SELECT FORMATMESSAGE('Long string test parameter: %s', CAST('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla consequat metus sit amet lectus vulputate lacinia. Nam vel auctor enim, quis finibus lorem. Quisque maximus egestas est, et vehicula lectus. Curabitur sodales efficitur nibh, quis varius metus semper vel. Aenean quis rhoncus tortor. Nullam eleifend blandit imperdiet. Donec a gravida ex. Cras ac nulla orci. Fusce ut est ac odio consequat rutrum. Morbi diam erat, blandit ut nunc efficitur, venenatis placerat nunc. Sed laoreet aliquam leo. Quisque vestibulum hendrerit mi, at cursus eros aliquet vitae. Mauris a sem blandit, interdum ligula et, feugiat nulla. Sed quis ipsum at dolor congue vulputate at elementum ex. Integer iaculis, libero nec pulvinar molestie, neque mi vestibulum nisl, in volutpat metus arcu in purus. Praesent ullamcorper mi sit amet consectetur mattis. Sed quis ex placerat, finibus purus dignissim, porttitor nibh. Maecenas dignissim tristique tempus. Proin venenatis sem a orci sagittis, vel consequat sem vestibulum. Donec consectetur cursus tortor, eget volutpat lacus posuere a. Pellentesque eu orci hendrerit sapien dictum fringilla. Morbi rutrum mollis ipsum sit amet hendrerit. Nullam nec felis tortor. Mauris augue turpis, volutpat ac odio in, faucibus venenatis purus. Curabitur scelerisque pharetra nunc non mattis. Nunc sagittis euismod mi sit amet gravida. Integer malesuada pretium nibh. Maecenas sagittis facilisis enim, et hendrerit nulla fringilla in. Nam pulvinar, nibh non mattis hendrerit, arcu velit molestie sem, sed rutrum arcu odio a risus. Pellentesque lorem sem, dictum nec sem nec, congue ornare purus. Mauris id efficitur mi. Phasellus nec tortor lacus. Integer vitae tempus lorem. Suspendisse augue orci, volutpat vitae magna id, venenatis viverra nunc. Sed lobortis faucibus ante, ac porttitor risus. Proin viverra vestibulum enim, sed dignissim erat lobortis scelerisque. Aliquam et diam ut lacus dictum tristique. Sed a sapien quis nulla semper elementum. Ut fringilla laoreet luctus. Vivamus mi ipsum.i' AS VARCHAR(3000)))
GO

SELECT FORMATMESSAGE('21 args: %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s', CAST('one' AS VARCHAR(10)), CAST('two' AS VARCHAR(10)),CAST('three' AS VARCHAR(10)),CAST('four' AS VARCHAR(10)),CAST('five' AS VARCHAR(10)),CAST('six' AS VARCHAR(10)),CAST('seven' AS VARCHAR(10)),CAST('eight' AS VARCHAR(10)),CAST('nine' AS VARCHAR(10)),CAST('ten' AS VARCHAR(10)),CAST('eleven' AS VARCHAR(10)),CAST('twelve' AS VARCHAR(10)),CAST('thirteen' AS VARCHAR(10)),CAST('fourteen' AS VARCHAR(10)),CAST('fifteen' AS VARCHAR(10)),CAST('sixteen' AS VARCHAR(10)),CAST('seventeen' AS VARCHAR(10)),CAST('eighteen' AS VARCHAR(10)),CAST('nineteen' AS VARCHAR(10)),CAST('twenty' AS VARCHAR(10)),CAST('twenty-one' AS VARCHAR(10)))
GO

SELECT FORMATMESSAGE('Invalid parameter example: %s', TRUE)
GO

SELECT FORMATMESSAGE('Invalid placeholder example: %m', 0)
GO

SELECT FORMATMESSAGE(NULL, 0)
GO

SELECT FORMATMESSAGE('Placeholder null: %s', NULL)
GO

SELECT FORMATMESSAGE('Mismatch datatype: %d', 'string')
GO

SELECT FORMATMESSAGE('Mismatch datatype: %o', CAST('string' AS VARCHAR(10)))
GO

SELECT FORMATMESSAGE('Mismatch datatype: %s', 123);
GO
