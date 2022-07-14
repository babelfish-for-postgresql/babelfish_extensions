-- The value and value_in_use is set to 1 because SSMS-Babelfish connectivity requires it.
INSERT INTO sys.babelfish_configurations
    VALUES (
            16387,
            'SMO and DMO XPs',
            1,
            0,
            1,
            1,
            'Enable or disable SMO and DMO XPs',
            sys.bitin('1'),
            sys.bitin('1'),
            'Enable or disable SMO and DMO XPs',
            'Enable or disable SMO and DMO XPs'
            ),
            (
            1534,
            'user options',
            0,
            0,
            32767,
            0,
            'user options',
            sys.bitin('1'),
            sys.bitin('0'),
            'user options',
            'user options'
            ),
            (
            115,
            'nested triggers',
            1,
            0,
            1,
            1,
            'Allow triggers to be invoked within triggers',
            sys.bitin('1'),
            sys.bitin('0'),
            'Allow triggers to be invoked within triggers',
            'Allow triggers to be invoked within triggers'
            ),
            (
            124,
            'default language',
            0,
            0,
            9999,
            0,
            'default language',
            sys.bitin('1'),
            sys.bitin('0'),
            'default language',
            'default language'
            ),
            (
            1126,               
            'default full-text language',
            1033,
            0,
            2147483647,
            1033,
            'default full-text language',
            sys.bitin('1'),
            sys.bitin('1'),
            'default full-text language',
            'default full-text language'
            ),

            (
            1127,
            'two digit year cutoff',
            2049,
            1753,
            9999,
            2049,
            'two digit year cutoff',
            sys.bitin('1'),
            sys.bitin('1'),
            'two digit year cutoff',
            'two digit year cutoff'
            ),
            (
            1555,
            'transform noise words',
            0,
            0,
            1,
            0,
            'Transform noise words for full-text query',
            sys.bitin('1'),
            sys.bitin('1'),
            'Transform noise words for full-text query',
            'Transform noise words for full-text query'
            );
