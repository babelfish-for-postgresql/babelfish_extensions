-- The value and value_in_use is set to 1 because SSMS-Babelfish connectivity requires it.
INSERT INTO sys.babelfish_configurations
    VALUES (16387,
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
            );
