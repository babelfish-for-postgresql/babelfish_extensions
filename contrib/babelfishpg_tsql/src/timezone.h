#ifndef TSQL_TIMEZONE_H
#define TSQL_TIMEZONE_H

static const struct
{
    	const char *stdname;		/* Windows name of standard timezone */
	const char *dstname;		/* Windows name of daylight timezone */
	const char *pgtzname;		/* Name of pgsql timezone to map to */
}	win32_tzmap[] =
	
	{
	/*
	 * This list was built from the contents of the registry at
	 * HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time
	 * Zones on Windows 7, Windows 10, and Windows Server 2019.  Some recent
	 * additions have been made by comparing to the CLDR project's
	 * windowsZones.xml file.
	 *
	 * The zones have been matched to IANA timezones based on CLDR's mapping
	 * for "territory 001".
	 */
	{
		/* (UTC+04:30) Kabul */
		"afghanistan standard time", "Afghanistan Daylight Time",
		"Asia/Kabul"
	},
	{
		/* (UTC-09:00) Alaska */
		"alaskan standard time", "Alaskan Daylight Time",
		"America/Anchorage"
	},
	{
		/* (UTC-10:00) Aleutian Islands */
		"aleutian standard time", "Aleutian Daylight Time",
		"America/Adak"
	},
	{
		/* (UTC+07:00) Barnaul, Gorno-Altaysk */
		"altai standard time", "Altai Daylight Time",
		"Asia/Barnaul"
	},
	{
		/* (UTC+03:00) Kuwait, Riyadh */
		"arab standard time", "Arab Daylight Time",
		"Asia/Riyadh"
	},
	{
		/* (UTC+04:00) Abu Dhabi, Muscat */
		"arabian standard time", "Arabian Daylight Time",
		"Asia/Dubai"
	},
	{
		/* (UTC+03:00) Baghdad */
		"arabic standard time", "Arabic Daylight Time",
		"Asia/Baghdad"
	},
	{
		/* (UTC-03:00) City of Buenos Aires */
		"argentina standard time", "Argentina Daylight Time",
		"America/Buenos_Aires"
	},
	{
		/* (UTC+04:00) Astrakhan, Ulyanovsk */
		"astrakhan standard time", "Astrakhan Daylight Time",
		"Europe/Astrakhan"
	},
	{
		/* (UTC-04:00) Atlantic Time (Canada) */
		"atlantic standard time", "Atlantic Daylight Time",
		"America/Halifax"
	},
	{
		/* (UTC+09:30) Darwin */
		"aus central standard time", "AUS Central Daylight Time",
		"Australia/Darwin"
	},
	{
		/* (UTC+08:45) Eucla */
		"aus central w. standard time", "Aus Central W. Daylight Time",
		"Australia/Eucla"
	},
	{
		/* (UTC+10:00) Canberra, Melbourne, Sydney */
		"aus eastern standard time", "AUS Eastern Daylight Time",
		"Australia/Sydney"
	},
	{
		/* (UTC+04:00) Baku */
		"azerbaijan standard time", "Azerbaijan Daylight Time",
		"Asia/Baku"
	},
	{
		/* (UTC-01:00) Azores */
		"azores standard time", "Azores Daylight Time",
		"Atlantic/Azores"
	},
	{
		/* (UTC-03:00) Salvador */
		"bahia standard time", "Bahia Daylight Time",
		"America/Bahia"
	},
	{
		/* (UTC+06:00) Dhaka */
		"bangladesh standard time", "Bangladesh Daylight Time",
		"Asia/Dhaka"
	},
	{
		/* (UTC+03:00) Minsk */
		"belarus standard time", "Belarus Daylight Time",
		"Europe/Minsk"
	},
	{
		/* (UTC+11:00) Bougainville Island */
		"bougainville standard time", "Bougainville Daylight Time",
		"Pacific/Bougainville"
	},
	{
		/* (UTC-06:00) Saskatchewan */
		"canada central standard time", "Canada Central Daylight Time",
		"America/Regina"
	},
	{
		/* (UTC-01:00) Cape Verde Is. */
		"cape verde standard time", "Cape Verde Daylight Time",
		"Atlantic/Cape_Verde"
	},
	{
		/* (UTC+04:00) Yerevan */
		"caucasus standard time", "Caucasus Daylight Time",
		"Asia/Yerevan"
	},
	{
		/* (UTC+09:30) Adelaide */
		"cen. australia standard time", "Cen. Australia Daylight Time",
		"Australia/Adelaide"
	},
	{
		/* (UTC-06:00) Central America */
		"central america standard time", "Central America Daylight Time",
		"America/Guatemala"
	},
	{
		/* (UTC+06:00) Astana */
		"central asia standard time", "Central Asia Daylight Time",
		"Asia/Almaty"
	},
	{
		/* (UTC-04:00) Cuiaba */
		"central brazilian standard time", "Central Brazilian Daylight Time",
		"America/Cuiaba"
	},
	{
		/* (UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague */
		"central europe standard time", "Central Europe Daylight Time",
		"Europe/Budapest"
	},
	{
		/* (UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb */
		"central european standard time", "Central European Daylight Time",
		"Europe/Warsaw"
	},
	{
		/* (UTC+11:00) Solomon Is., New Caledonia */
		"central pacific standard time", "Central Pacific Daylight Time",
		"Pacific/Guadalcanal"
	},
	{
		/* (UTC-06:00) Central Time (US & Canada) */
		"central standard time", "Central Daylight Time",
		"America/Chicago"
	},
	{
		/* (UTC-06:00) Guadalajara, Mexico City, Monterrey */
		"central standard time (mexico)", "Central Daylight Time (Mexico)",
		"America/Mexico_City"
	},
	{
		/* (UTC+12:45) Chatham Islands */
		"chatham islands standard time", "Chatham Islands Daylight Time",
		"Pacific/Chatham"
	},
	{
		/* (UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi */
		"china standard time", "China Daylight Time",
		"Asia/Shanghai"
	},
	{
		/* (UTC-05:00) Havana */
		"Cuba standard time", "Cuba Daylight Time",
		"America/Havana"
	},
	{
		/* (UTC-12:00) International Date Line West */
		"dateline standard time", "Dateline Daylight Time",
		"Etc/GMT+12"
	},
	{
		/* (UTC+03:00) Nairobi */
		"e. africa standard time", "E. Africa Daylight Time",
		"Africa/Nairobi"
	},
	{
		/* (UTC+10:00) Brisbane */
		"e. australia standard time", "E. Australia Daylight Time",
		"Australia/Brisbane"
	},
	{
		/* (UTC+02:00) Chisinau */
		"e. europe standard time", "E. Europe Daylight Time",
		"Europe/Chisinau"
	},
	{
		/* (UTC-03:00) Brasilia */
		"e. south america standard time", "E. South America Daylight Time",
		"America/Sao_Paulo"
	},
	{
		/* (UTC-06:00) Easter Island */
		"easter island standard time", "Easter Island Daylight Time",
		"Pacific/Easter"
	},
	{
		/* (UTC-05:00) Eastern Time (US & Canada) */
		"eastern standard time", "Eastern Daylight Time",
		"America/New_York"
	},
	{
		/* (UTC-05:00) Chetumal */
		"eastern standard time (mexico)", "Eastern Daylight Time (Mexico)",
		"America/Cancun"
	},
	{
		/* (UTC+02:00) Cairo */
		"egypt standard time", "Egypt Daylight Time",
		"Africa/Cairo"
	},
	{
		/* (UTC+05:00) Ekaterinburg */
		"ekaterinburg standard time", "Ekaterinburg Daylight Time",
		"Asia/Yekaterinburg"
	},
	{
		/* (UTC+12:00) Fiji */
		"fiji standard time", "Fiji Daylight Time",
		"Pacific/Fiji"
	},
	{
		/* (UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius */
		"fle standard time", "FLE Daylight Time",
		"Europe/Kiev"
	},
	{
		/* (UTC+04:00) Tbilisi */
		"georgian standard time", "Georgian Daylight Time",
		"Asia/Tbilisi"
	},
	{
		/* (UTC+00:00) Dublin, Edinburgh, Lisbon, London */
		"gmt standard time", "GMT Daylight Time",
		"Europe/London"
	},
	{
		/* (UTC-03:00) Greenland */
		"greenland standard time", "Greenland Daylight Time",
		"America/Godthab"
	},
	{
		/*
		 * Windows uses this zone name in various places that lie near the
		 * prime meridian, but are not in the UK.  However, most people
		 * probably think that "Greenwich" means UK civil time, or maybe even
		 * straight-up UTC.  Atlantic/Reykjavik is a decent match for that
		 * interpretation because Iceland hasn't observed DST since 1968.
		 */
		/* (UTC+00:00) Monrovia, Reykjavik */
		"greenwich standard time", "Greenwich Daylight Time",
		"Atlantic/Reykjavik"
	},
	{
		/* (UTC+02:00) Athens, Bucharest */
		"gtb standard time", "GTB Daylight Time",
		"Europe/Bucharest"
	},
	{
		/* (UTC-05:00) Haiti */
		"haiti standard time", "Haiti Daylight Time",
		"America/Port-au-Prince"
	},
	{
		/* (UTC-10:00) Hawaii */
		"hawaiian standard time", "Hawaiian Daylight Time",
		"Pacific/Honolulu"
	},
	{
		/* (UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi */
		"india standard time", "India Daylight Time",
		"Asia/Calcutta"
	},
	{
		/* (UTC+03:30) Tehran */
		"iran standard time", "Iran Daylight Time",
		"Asia/Tehran"
	},
	{
		/* (UTC+02:00) Jerusalem */
		"israel standard time", "Israel Daylight Time",
		"Asia/Jerusalem"
	},
	{
		/* (UTC+02:00) Amman */
		"jordan standard time", "Jordan Daylight Time",
		"Asia/Amman"
	},
	{
		/* (UTC+02:00) Kaliningrad */
		"kaliningrad standard time", "Kaliningrad Daylight Time",
		"Europe/Kaliningrad"
	},
	{
		/* (UTC+12:00) Petropavlovsk-Kamchatsky - Old */
		"kamchatka standard time", "Kamchatka Daylight Time",
		"Asia/Kamchatka"
	},
	{
		/* (UTC+09:00) Seoul */
		"korea standard time", "Korea Daylight Time",
		"Asia/Seoul"
	},
	{
		/* (UTC+02:00) Tripoli */
		"libya standard time", "Libya Daylight Time",
		"Africa/Tripoli"
	},
	{
		/* (UTC+14:00) Kiritimati Island */
		"line islands standard time", "Line Islands Daylight Time",
		"Pacific/Kiritimati"
	},
	{
		/* (UTC+10:30) Lord Howe Island */
		"lord howe standard time", "Lord Howe Daylight Time",
		"Australia/Lord_Howe"
	},
	{
		/* (UTC+11:00) Magadan */
		"magadan standard time", "Magadan Daylight Time",
		"Asia/Magadan"
	},
	{
		/* (UTC-03:00) Punta Arenas */
		"magallanes standard time", "Magallanes Daylight Time",
		"America/Punta_Arenas"
	},
	{
		/* (UTC-09:30) Marquesas Islands */
		"marquesas standard time", "Marquesas Daylight Time",
		"Pacific/Marquesas"
	},
	{
		/* (UTC+04:00) Port Louis */
		"mauritius standard time", "Mauritius Daylight Time",
		"Indian/Mauritius"
	},
	{
		/* (UTC-02:00) Mid-Atlantic - Old */
		"mid-atlantic standard time", "Mid-Atlantic Daylight Time",
		"Atlantic/South_Georgia"
	},
	{
		/* (UTC+02:00) Beirut */
		"middle east standard time", "Middle East Daylight Time",
		"Asia/Beirut"
	},
	{
		/* (UTC-03:00) Montevideo */
		"montevideo standard time", "Montevideo Daylight Time",
		"America/Montevideo"
	},
	{
		/* (UTC+01:00) Casablanca */
		"morocco standard time", "Morocco Daylight Time",
		"Africa/Casablanca"
	},
	{
		/* (UTC-07:00) Mountain Time (US & Canada) */
		"mountain standard time", "Mountain Daylight Time",
		"America/Denver"
	},
	{
		/* (UTC-07:00) Chihuahua, La Paz, Mazatlan */
		"mountain standard time (mexico)", "Mountain Daylight Time (Mexico)",
		"America/Chihuahua"
	},
	{
		/* (UTC+06:30) Yangon (Rangoon) */
		"myanmar standard time", "Myanmar Daylight Time",
		"Asia/Rangoon"
	},
	{
		/* (UTC+07:00) Novosibirsk */
		"n. central asia standard time", "N. Central Asia Daylight Time",
		"Asia/Novosibirsk"
	},
	{
		/* (UTC+02:00) Windhoek */
		"namibia standard time", "Namibia Daylight Time",
		"Africa/Windhoek"
	},
	{
		/* (UTC+05:45) Kathmandu */
		"nepal standard time", "Nepal Daylight Time",
		"Asia/Katmandu"
	},
	{
		/* (UTC+12:00) Auckland, Wellington */
		"new zealand standard time", "New Zealand Daylight Time",
		"Pacific/Auckland"
	},
	{
		/* (UTC-03:30) Newfoundland */
		"newfoundland standard time", "Newfoundland Daylight Time",
		"America/St_Johns"
	},
	{
		/* (UTC+11:00) Norfolk Island */
		"norfolk standard time", "Norfolk Daylight Time",
		"Pacific/Norfolk"
	},
	{
		/* (UTC+08:00) Irkutsk */
		"north asia east standard time", "North Asia East Daylight Time",
		"Asia/Irkutsk"
	},
	{
		/* (UTC+07:00) Krasnoyarsk */
		"north asia standard time", "North Asia Daylight Time",
		"Asia/Krasnoyarsk"
	},
	{
		/* (UTC+09:00) Pyongyang */
		"north korea standard time", "North Korea Daylight Time",
		"Asia/Pyongyang"
	},
	{
		/* (UTC+06:00) Omsk */
		"omsk standard time", "Omsk Daylight Time",
		"Asia/Omsk"
	},
	{
		/* (UTC-04:00) Santiago */
		"pacific sa standard time", "Pacific SA Daylight Time",
		"America/Santiago"
	},
	{
		/* (UTC-08:00) Pacific Time (US & Canada) */
		"pacific standard time", "Pacific Daylight Time",
		"America/Los_Angeles"
	},
	{
		/* (UTC-08:00) Baja California */
		"pacific standard time (mexico)", "Pacific Daylight Time (Mexico)",
		"America/Tijuana"
	},
	{
		/* (UTC+05:00) Islamabad, Karachi */
		"pakistan standard time", "Pakistan Daylight Time",
		"Asia/Karachi"
	},
	{
		/* (UTC-04:00) Asuncion */
		"paraguay standard time", "Paraguay Daylight Time",
		"America/Asuncion"
	},
	{
		/* (UTC+05:00) Qyzylorda */
		"qyzylorda standard time", "Qyzylorda Daylight Time",
		"Asia/Qyzylorda"
	},
	{
		/* (UTC+01:00) Brussels, Copenhagen, Madrid, Paris */
		"romance standard time", "Romance Daylight Time",
		"Europe/Paris"
	},
	{
		/* (UTC+04:00) Izhevsk, Samara */
		"russia time zone 3", "Russia time zone 3",
		"Europe/Samara"
	},
	{
		/* (UTC+11:00) Chokurdakh */
		"russia time zone 10", "Russia time zone 10",
		"Asia/Srednekolymsk"
	},
	{
		/* (UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky */
		"russia time zone 11", "Russia time zone 11",
		"Asia/Kamchatka"
	},
	{
		/* (UTC+03:00) Moscow, St. Petersburg */
		"Russian standard time", "Russian Daylight Time",
		"Europe/Moscow"
	},
	{
		/* (UTC-03:00) Cayenne, Fortaleza */
		"sa eastern standard time", "SA Eastern Daylight Time",
		"America/Cayenne"
	},
	{
		/* (UTC-05:00) Bogota, Lima, Quito, Rio Branco */
		"sa pacific standard time", "SA Pacific Daylight Time",
		"America/Bogota"
	},
	{
		/* (UTC-04:00) Georgetown, La Paz, Manaus, San Juan */
		"sa western standard time", "SA Western Daylight Time",
		"America/La_Paz"
	},
	{
		/* (UTC-03:00) Saint Pierre and Miquelon */
		"saint pierre standard time", "Saint Pierre Daylight Time",
		"America/Miquelon"
	},
	{
		/* (UTC+11:00) Sakhalin */
		"sakhalin standard time", "Sakhalin Daylight Time",
		"Asia/Sakhalin"
	},
	{
		/* (UTC+13:00) Samoa */
		"samoa standard time", "Samoa Daylight Time",
		"Pacific/Apia"
	},
	{
		/* (UTC+00:00) Sao Tome */
		"sao tome standard time", "Sao Tome Daylight Time",
		"Africa/Sao_Tome"
	},
	{
		/* (UTC+04:00) Saratov */
		"saratov standard time", "Saratov Daylight Time",
		"Europe/Saratov"
	},
	{
		/* (UTC+07:00) Bangkok, Hanoi, Jakarta */
		"se asia standard time", "SE Asia Daylight Time",
		"Asia/Bangkok"
	},
	{
		/* (UTC+08:00) Kuala Lumpur, Singapore */
		"singapore standard time", "Singapore Daylight Time",
		"Asia/Singapore"
	},
	{
		/* (UTC+02:00) Harare, Pretoria */
		"south africa standard time", "South Africa Daylight Time",
		"Africa/Johannesburg"
	},
	{
		/* (UTC+02:00) Juba */
		"south sudan standard time", "South Sudan Daylight Time",
		"Africa/Juba"
	},
	{
		/* (UTC+05:30) Sri Jayawardenepura */
		"sri Lanka standard time", "Sri Lanka Daylight Time",
		"Asia/Colombo"
	},
	{
		/* (UTC+02:00) Khartoum */
		"sudan standard time", "Sudan Daylight Time",
		"Africa/Khartoum"
	},
	{
		/* (UTC+02:00) Damascus */
		"syria standard time", "Syria Daylight Time",
		"Asia/Damascus"
	},
	{
		/* (UTC+08:00) Taipei */
		"taipei standard time", "Taipei Daylight Time",
		"Asia/Taipei"
	},
	{
		/* (UTC+10:00) Hobart */
		"tasmania standard time", "Tasmania Daylight Time",
		"Australia/Hobart"
	},
	{
		/* (UTC-03:00) Araguaina */
		"tocantins standard time", "Tocantins Daylight Time",
		"America/Araguaina"
	},
	{
		/* (UTC+09:00) Osaka, Sapporo, Tokyo */
		"tokyo standard time", "Tokyo Daylight Time",
		"Asia/Tokyo"
	},
	{
		/* (UTC+07:00) Tomsk */
		"tomsk standard time", "Tomsk Daylight Time",
		"Asia/Tomsk"
	},
	{
		/* (UTC+13:00) Nuku'alofa */
		"tonga standard time", "Tonga Daylight Time",
		"Pacific/Tongatapu"
	},
	{
		/* (UTC+09:00) Chita */
		"transbaikal standard time", "Transbaikal Daylight Time",
		"Asia/Chita"
	},
	{
		/* (UTC+03:00) Istanbul */
		"turkey standard time", "Turkey Daylight Time",
		"Europe/Istanbul"
	},
	{
		/* (UTC-05:00) Turks and Caicos */
		"turks and caicos standard time", "Turks And Caicos Daylight Time",
		"America/Grand_Turk"
	},
	{
		/* (UTC+08:00) Ulaanbaatar */
		"ulaanbaatar standard time", "Ulaanbaatar Daylight Time",
		"Asia/Ulaanbaatar"
	},
	{
		/* (UTC-05:00) Indiana (East) */
		"us eastern standard time", "US Eastern Daylight Time",
		"America/Indianapolis"
	},
	{
		/* (UTC-07:00) Arizona */
		"us mountain standard time", "US Mountain Daylight Time",
		"America/Phoenix"
	},
	{
		/* (UTC) Coordinated Universal Time */
		"utc", "UTC",
		"UTC"
	},
	{
		/* (UTC+12:00) Coordinated Universal Time+12 */
		"utc+12", "UTC+12",
		"Etc/GMT-12"
	},
	{
		/* (UTC+13:00) Coordinated Universal Time+13 */
		"utc+13", "UTC+13",
		"Etc/GMT-13"
	},
	{
		/* (UTC-02:00) Coordinated Universal Time-02 */
		"utc-02", "UTC-02",
		"Etc/GMT+2"
	},
	{
		/* (UTC-08:00) Coordinated Universal Time-08 */
		"utc-08", "UTC-08",
		"Etc/GMT+8"
	},
	{
		/* (UTC-09:00) Coordinated Universal Time-09 */
		"utc-09", "UTC-09",
		"Etc/GMT+9"
	},
	{
		/* (UTC-11:00) Coordinated Universal Time-11 */
		"utc-11", "UTC-11",
		"Etc/GMT+11"
	},
	{
		/* (UTC-04:00) Caracas */
		"venezuela standard time", "Venezuela Daylight Time",
		"America/Caracas"
	},
	{
		/* (UTC+10:00) Vladivostok */
		"vladivostok standard time", "Vladivostok Daylight Time",
		"Asia/Vladivostok"
	},
	{
		/* (UTC+04:00) Volgograd */
		"volgograd standard time", "Volgograd Daylight Time",
		"Europe/Volgograd"
	},
	{
		/* (UTC+08:00) Perth */
		"w. australia standard time", "W. Australia Daylight Time",
		"Australia/Perth"
	},
	{
		/* (UTC+01:00) West Central Africa */
		"w. central africa standard time", "W. Central Africa Daylight Time",
		"Africa/Lagos"
	},
	{
		/* (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna */
		"w. europe standard time", "W. Europe Daylight Time",
		"Europe/Berlin"
	},
	{
		/* (UTC+07:00) Hovd */
		"w. mongolia standard time", "W. Mongolia Daylight Time",
		"Asia/Hovd"
	},
	{
		/* (UTC+05:00) Ashgabat, Tashkent */
		"west asia standard time", "West Asia Daylight Time",
		"Asia/Tashkent"
	},
	{
		/* (UTC+02:00) Gaza, Hebron */
		"west bank standard time", "West Bank Daylight Time",
		"Asia/Hebron"
	},
	{
		/* (UTC+10:00) Guam, Port Moresby */
		"west pacific standard time", "West Pacific Daylight Time",
		"Pacific/Port_Moresby"
	},
	{
		/* (UTC+09:00) Yakutsk */
		"yakutsk standard time", "Yakutsk Daylight Time",
		"Asia/Yakutsk"
	},
	{
		/* (UTC-07:00) Yukon */
		"yukon standard time", "Yukon Daylight Time",
		"America/Whitehorse"
	}
};

#endif							/* TSQL_TIMEZONE_H */
