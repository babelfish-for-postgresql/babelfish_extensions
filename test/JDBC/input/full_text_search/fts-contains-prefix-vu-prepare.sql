-- sys.babelfish_fts_rewrite()
CREATE VIEW prefix_rewrite_prepare_v1 AS (SELECT sys.babelfish_fts_rewrite('"one two three*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v2 AS (SELECT sys.babelfish_fts_rewrite(' "one two three*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v3 AS (SELECT sys.babelfish_fts_rewrite('"one two three*" '));
GO
CREATE VIEW prefix_rewrite_prepare_v4 AS (SELECT sys.babelfish_fts_rewrite('"one* two three*"       '));
GO
CREATE VIEW prefix_rewrite_prepare_v5 AS (SELECT sys.babelfish_fts_rewrite(' "one two three*" '));
GO
CREATE VIEW prefix_rewrite_prepare_v6 AS (SELECT sys.babelfish_fts_rewrite(' "one*two*three*" '));
GO
CREATE VIEW prefix_rewrite_prepare_v7 AS (SELECT sys.babelfish_fts_rewrite('"word1   * * ** *"'));
GO

CREATE PROCEDURE prefix_rewrite_prepare_p1 AS (SELECT sys.babelfish_fts_rewrite('"one*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p2 AS (SELECT sys.babelfish_fts_rewrite('"* one*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p3 AS (SELECT sys.babelfish_fts_rewrite('"one * two*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p4 AS (SELECT sys.babelfish_fts_rewrite('" ** one * * * two*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p5 AS (SELECT sys.babelfish_fts_rewrite('"*one*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p6 AS (SELECT sys.babelfish_fts_rewrite('"*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p7 AS (SELECT sys.babelfish_fts_rewrite('"word1   * * ** * word2*"'));
GO

--special characters
-- should throw not supported error
CREATE PROCEDURE prefix_rewrite_prepare_p8 AS (SELECT sys.babelfish_fts_rewrite('"one$*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p9 AS (SELECT sys.babelfish_fts_rewrite('"$$one*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p10 AS (SELECT sys.babelfish_fts_rewrite('" $one *"'));
GO

-- Not a valid prefix term syntax, recognized as simple term
CREATE PROCEDURE prefix_rewrite_prepare_p11 AS (SELECT sys.babelfish_fts_rewrite('"o@ne* "'));
GO

-- Create the table
CREATE TABLE fts_prefix_t (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Content TEXT,
    Category VARCHAR(50),
    ShortDescription NVARCHAR(200),
    Author CHAR(50),
    Tags NCHAR(30),
    Notes TEXT
);

INSERT INTO fts_prefix_t (Content, Category, ShortDescription, Author, Tags, Notes) VALUES
    ('Digital transformation helps businesses grow exponentially', 'Technology', 'Overview of digital transformation impact', 'JSMITH', N'#DIGITAL#TRANSFORM', 'Key focus on enterprise solutions'),
    ('Cloud computing reduces infrastructure costs significantly', 'Technology', 'Cost benefits of cloud adoption', 'EWATSN', N'#CLOUD#COSTS', 'ROI analysis included'),
    ('Data analytics drives better business decisions', 'Business', 'Analytics impact on decision making', 'MBROWN', N'#DATA#ANALYTICS', 'Case studies referenced'),
    ('Machine learning algorithms improve predictive analytics', 'Technology', 'ML in predictive analysis', 'SCLARK', N'#ML#PREDICT', 'Technical implementation details'),
    ('Blockchain technology ensures transaction transparency', 'Finance', 'Blockchain in financial systems', 'HMARTZ', N'#BLOCKCHAIN#FIN', 'Security aspects covered'),
    ('Artificial intelligence transforms customer service', 'Technology', 'AI impact on customer experience', 'ASMITH', N'#AI#SERVICE', 'Implementation success metrics'),
    ('Cloud security protocols enhance data protection', 'Security', 'Advanced cloud security measures', 'RWILSN', N'#SECURITY#CLOUD', 'Best practices documented'),
    ('Data visualization improves decision making process', 'Analytics', 'Visual analytics benefits', 'JBAKER', N'#VIZ#ANALYTICS', 'Tool comparison included'),
    ('Digital marketing strategies boost online presence', 'Marketing', 'Digital marketing effectiveness', 'MTHOMS', N'#DIGITAL#MKTG', 'Campaign performance data'),
    ('Cloud native applications maximize efficiency', 'Technology', 'Benefits of cloud native apps', 'PGREEN', N'#CLOUD#NATIVE', 'Architecture guidelines'),
    ('Internet of Things enables smart manufacturing', 'Manufacturing', 'IoT in industrial settings', 'KWHITE', N'#IOT#INDUSTRY', 'Implementation roadmap'),
    ('Cybersecurity measures prevent data breaches', 'Security', 'Modern security protocols', 'LBLACK', N'#SECURITY#CYBER', 'Threat analysis included'),
    ('Big data analytics reveal customer patterns', 'Analytics', 'Customer behavior analysis', 'RJAMES', N'#BIGDATA#CRM', 'Pattern recognition study'),
    ('Digital payments revolutionize transactions', 'Finance', 'Evolution of payment systems', 'ABROOK', N'#PAYMENT#FIN', 'Market adoption rates'),
    ('Cloud migration strategies simplify transitions', 'Technology', 'Effective migration planning', 'TCLARK', N'#CLOUD#MIGRATE', 'Step-by-step guide'),
    ('Data governance ensures compliance standards', 'Compliance', 'Regulatory compliance guide', 'DSMITH', N'#DATA#GOVERN', 'Regulatory updates included'),
    ('Virtual reality transforms user experiences', 'Technology', 'VR applications overview', 'BWILSN', N'#VR#UX', 'User testing results'),
    ('Edge computing reduces latency issues', 'Technology', 'Edge computing benefits', 'MROGER', N'#EDGE#COMPUTE', 'Performance metrics'),
    ('Quantum computing advances computation speed', 'Technology', 'Quantum computing impact', 'JTHOMS', N'#QUANTUM#TECH', 'Research findings'),
    ('Digital twins optimize manufacturing processes', 'Manufacturing', 'Digital twin applications', 'CGREEN', N'#TWIN#MANUF', 'Case implementation'),
    ('Natural language processing enhances AI', 'Technology', 'NLP in modern AI', 'FWHITE', N'#NLP#AI', 'Language model analysis'),
    ('Cloud automation improves workflow efficiency', 'Technology', 'Workflow automation benefits', 'HBLACK', N'#CLOUD#AUTO', 'Efficiency metrics'),
    ('Data lakes centralize information storage', 'Technology', 'Data lake architecture', 'WJAMES', N'#DATA#STORE', 'Storage optimization'),
    ('Blockchain solutions for supply chain', 'Supply Chain', 'Supply chain transparency', 'NBROOK', N'#BLOCKCHAIN#SCM', 'Implementation guide'),
    ('Machine vision enhances quality control', 'Manufacturing', 'Quality control automation', 'VCLARK', N'#VISION#QC', 'Error reduction stats'),
    ('Cloud-based CRM improves customer relations', 'Business', 'Modern CRM solutions', 'QSMITH', N'#CRM#CLOUD', 'Customer satisfaction data'),
    ('Data mining uncovers business insights', 'Analytics', 'Business intelligence tools', 'UWILSN', N'#DATA#MINE', 'ROI case studies'),
    ('Digital identity verifies online transactions', 'Security', 'Identity verification systems', 'KROGER', N'#IDENTITY#SEC', 'Security protocols'),
    ('Augmented reality enhances training', 'Education', 'AR in corporate training', 'ITHOMS', N'#AR#TRAIN', 'Training effectiveness'),
    ('Cloud telephony revolutionizes communication', 'Communication', 'Modern business communication', 'YGREEN', N'#VOIP#COMM', 'Cost benefit analysis'),
    ('Data encryption secures information transfer', 'Security', 'Modern encryption methods', 'XWHITE', N'#ENCRYPT#SEC', 'Security standards'),
    ('Digital workspace enables remote work', 'Business', 'Remote work solutions', 'OBLACK', N'#REMOTE#WORK', 'Productivity metrics'),
    ('Cloud gaming transforms entertainment', 'Entertainment', 'Gaming industry evolution', 'ZJAMES', N'#GAME#CLOUD', 'Market growth data'),
    ('Data backup ensures business continuity', 'Technology', 'Backup strategy guide', 'GBROOK', N'#BACKUP#BIZ', 'Recovery protocols'),
    ('Artificial neural networks advance AI', 'Technology', 'Neural network applications', 'ESMITH', N'#NEURAL#AI', 'Performance studies'),
    ('Cloud storage optimizes data management', 'Technology', 'Storage solution benefits', 'DWILSN', N'#STORAGE#CLOUD', 'Capacity planning'),
    ('Data analytics predicts market trends', 'Business', 'Predictive analytics use', 'SROGER', N'#PREDICT#BIZ', 'Accuracy metrics'),
    ('Digital advertising targets audiences', 'Marketing', 'Ad targeting strategies', 'ATHOMS', N'#AD#TARGET', 'Campaign results'),
    ('Cloud security prevents cyber attacks', 'Security', 'Security measure overview', 'BGREEN', N'#SECURE#CLOUD', 'Threat prevention'),
    ('Data integration streamlines operations', 'Technology', 'Integration best practices', 'CWHITE', N'#DATA#INTEG', 'Efficiency gains'),
    ('Digital signatures automate approvals', 'Business', 'E-signature solutions', 'DBLACK', N'#SIGN#AUTO', 'Compliance details'),
    ('Cloud monitoring ensures performance', 'Technology', 'Performance monitoring tools', 'EJAMES', N'#MONITOR#PERF', 'Uptime statistics'),
    ('Data quality improves decision making', 'Analytics', 'Quality management guide', 'FBROOK', N'#QUALITY#DATA', 'Impact analysis'),
    ('Digital currency transforms banking', 'Finance', 'Cryptocurrency impact', 'GSMITH', N'#CRYPTO#FIN', 'Market adoption'),
    ('Cloud compliance meets regulations', 'Compliance', 'Regulatory requirements', 'HWILSN', N'#COMPLY#REG', 'Standard updates'),
    ('Data privacy protects user rights', 'Security', 'Privacy protection measures', 'IROGER', N'#PRIVACY#SEC', 'GDPR compliance'),
    ('Digital supply chains optimize logistics', 'Supply Chain', 'Supply chain innovation', 'JGREEN', N'#SUPPLY#CHAIN', 'Efficiency gains'),
    ('Cloud architecture scales systems', 'Technology', 'Scalable system design', 'KWHITE', N'#ARCH#SCALE', 'Design patterns'),
    ('Data visualization tells stories', 'Analytics', 'Visual storytelling guide', 'LBLACK', N'#VIZ#STORY', 'Example cases'),
    ('Digital ethics guides AI development', 'Technology', 'AI ethics framework', 'MJAMES', N'#AI#ETHICS', 'Policy guidelines'),
    ('Cloud solutions enable innovation', 'Technology', 'Innovation enablement', 'NBROOK', N'#INNOVATE#CLOUD', 'Success stories')
GO

-- Create the table
CREATE TABLE fts_multicol_prefix_t (
    id INT NOT NULL,
    daily_updates TEXT,
    industry_news VARCHAR(200),
    local_events CHAR(200),
    tech_innovations NCHAR(200),
    community_highlights NVARCHAR(200)
)

INSERT INTO fts_multicol_prefix_t (id, daily_updates, industry_news, local_events, tech_innovations, community_highlights) VALUES
(1, 'The lighthouse keeper guided our ship', 'Light workload was distributed this week', 'Working with lighter materials today', 'The lighting workshop starts tomorrow', 'Lightweight construction materials arrived recently'),
(2, 'Deep water diving expedition begins', 'The depths were clearly visible', 'Deeply concerned about ocean pollution', 'Deeper understanding of marine life', 'The deepest cave exploration planned'),
(3, 'Fast track program shows promise', 'Faster delivery options are available', 'Moving fastest among all competitors', 'The fast-paced workshop concluded today', 'Racing faster than last season'),
(4, 'Working through complex programming challenges', 'The workshop delivered great results', 'Light work schedule this month', 'Workstation setup needs improvement now', 'Workflow optimization meeting this afternoon'),
(5, 'Building stronger foundations for tomorrow', 'The builder completed ahead schedule', 'Built-in storage solutions needed', 'Building workshop starts next week', 'The rebuilt structure stands strong'),
(6, 'Power tools require proper maintenance', 'Powerful storm approaching the coast', 'The powerhouse team wins again', 'Powerfully written thesis got approved', 'Power-saving mode activated automatically'),
(7, 'Learning to navigate rough waters', 'The learned professor gives lecture', 'Educational learning center opens today', 'Learn from yesterday big mistakes', 'The learner showed great potential'),
(8, 'Fire fighting equipment needs inspection', 'Fired up about new project', 'The fireplace needs maintenance soon', 'Fireworks display amazes local crowd', 'Fire station conducts safety workshop'),
(9, 'Heart surgery went very well', 'Heartfelt message from the team', 'The heartwarming story touches everyone', 'Heart-healthy recipes for beginners', 'Heartbeat monitoring system installed'),
(10, 'Ground breaking ceremony next week', 'The groundwork has been completed', 'Grounded aircraft await clearance now', 'Ground floor renovation in progress', 'Underground parking opens this month'),
(11, 'Water treatment facility needs upgrade', 'Watering schedule for community garden', 'Waterproof coating being applied today', 'Waterworks department issues new guidelines', 'Waterside property development begins'),
(12, 'Smart working solutions for employees', 'The smartwatch tracks your activity', 'Smartphone integration coming next week', 'Smart home devices need configuration', 'Smartly designed office space opens'),
(13, 'High level meeting discusses strategy', 'Higher education becomes more accessible', 'Highest scoring team receives award', 'High-performance vehicles need maintenance', 'Highland expedition starts next month'),
(14, 'Time management workshop starts today', 'Timely delivery of all packages', 'Timed response system works well', 'Timeout procedures need revision now', 'Timekeeping system gets upgraded'),
(15, 'Space exploration mission launches soon', 'Spaceship design gets approved today', 'Spacesuit testing completed successfully', 'Space-saving furniture arrives tomorrow', 'Spacetime concepts explained clearly'),
(16, 'Hand crafted items sell well', 'Handling difficult situations with care', 'Handmade pottery exhibition opens today', 'Hand-picked fruits taste better', 'Handiwork display attracts large crowd'),
(17, 'Book keeping needs more attention', 'Bookshelf organization takes priority', 'Bookworm club meets every week', 'Book-binding workshop starts tomorrow', 'Bookstore renovation nears completion'),
(18, 'Self driving cars need improvement', 'The selfless act inspired many', 'Self-help books line the shelves', 'Self-guided tour starts at noon', 'Self-sufficient community grows stronger'),
(19, 'Life saving techniques being taught', 'Lifetime membership offers great value', 'Life-changing experience shared today', 'Life insurance policies need review', 'Life-sized model arrives next week'),
(20, 'Long distance running competition begins', 'Longer working hours this week', 'The longest bridge needs repair', 'Long-term planning session scheduled', 'Long-lasting batteries finally arrived'),
(21, 'Cloud computing resources being upgraded', 'Cloudy weather affects solar panels', 'The cloudless sky looks beautiful', 'Cloud-based services expand rapidly', 'Cloud storage capacity increases significantly'),
(22, 'Mind mapping techniques prove effective', 'Mindful meditation sessions start tomorrow', 'The mindless chatter disturbs focus', 'Mind-bending puzzles challenge participants', 'Mindset coaching program launches soon'),
(23, 'Play ground equipment needs maintenance', 'Playing cards tournament this weekend', 'Playful dolphins entertain tourists here', 'Play-by-play commentary was excellent', 'Playstation gaming competition begins today'),
(24, 'Sun bathing area closes early', 'Sunlight powers new installation today', 'The sunroom needs fresh paint', 'Sun-dried tomatoes taste amazing', 'Sunshine brightens the entire valley'),
(25, 'Green house plants grow rapidly', 'Greener initiatives launch next month', 'The greenest campus award ceremony', 'Green-technology startup receives funding', 'Greenhouse effect studies continue forward'),
(26, 'Hard working staff deserves recognition', 'Harder challenges lie ahead now', 'The hardest part was deciding', 'Hard-earned success story inspires', 'Hardware upgrade completed successfully'),
(27, 'Air conditioning system needs repair', 'Airborne particles affect visibility today', 'The airport announces new flights', 'Air-quality monitoring shows improvement', 'Airwave transmission requires calibration'),
(28, 'Back country hiking trail opens', 'Background check process starts today', 'The backdrop needs artistic touches', 'Back-to-back meetings tire everyone', 'Backside entrance requires maintenance'),
(29, 'Down town traffic increases significantly', 'Downhill skiing competition starts soon', 'The downside affects profit margin', 'Down-payment options become flexible', 'Downtime scheduled for system maintenance'),
(30, 'Over night success story inspires', 'Overland transport costs rise significantly', 'The overflow parking opens today', 'Over-the-counter medicine needs prescription', 'Overview presentation impresses board members'),
(31, 'Cross country team wins championship', 'Crosswind landing challenges pilots today', 'The crossroads needs traffic signals', 'Cross-platform development shows promise', 'Crosstown traffic delays many commuters'),
(32, 'Under ground cable installation begins', 'Underwater exploration reveals new species', 'The underpass construction starts soon', 'Under-privileged children receive support', 'Undercover operation yields great results'),
(33, 'Out patient clinic opens tomorrow', 'Outside catering service impresses everyone', 'The outbreak concerns health officials', 'Out-of-stock items arrive soon', 'Outbound flights face weather delays'),
(34, 'Black board needs cleaning today', 'Blackberry bushes produce abundantly', 'The blacksmith demonstrates ancient techniques', 'Black-tie event starts at eight', 'Blackout affects downtown area significantly'),
(35, 'Well being program shows results', 'Wellness center opens next month', 'The well-equipped gym attracts members', 'Well-maintained gardens impress visitors', 'Well-documented processes help employees'),
(36, 'School yard renovation nearly complete', 'Schooling fish attract photographers today', 'The schoolhouse needs fresh paint', 'School-aged children learn coding', 'Schoolwide competition encourages participation'),
(37, 'Home made meals taste better', 'Homeless shelter needs more volunteers', 'The homeowner association meets today', 'Home-based business grows rapidly', 'Homecoming celebration exceeds expectations'),
(38, 'Wind powered generators save energy', 'Winding road challenges new drivers', 'The windmill turns very slowly', 'Wind-resistant umbrellas sell well', 'Windshield wipers need replacement soon'),
(39, 'Free standing structure requires inspection', 'Freely flowing river attracts kayakers', 'The freestyle competition starts tomorrow', 'Free-range chickens produce eggs', 'Freedom loving people gather peacefully'),
(40, 'Safe keeping box remains secure', 'Safety measures protect all workers', 'The safeguard system works perfectly', 'Safe-conduct passes help travelers', 'Safehouse location remains confidential'),
(41, 'Snow covered mountains look magnificent', 'Snowboarding competition starts tomorrow', 'The snowstorm approaches from north', 'Snow-white peaks glisten brightly', 'Snowmobile tracks cross the valley'),
(42, 'Wood working class starts monday', 'Wooden furniture needs restoration work', 'The woodpecker damaged the tree', 'Wood-fired pizza tastes amazing', 'Woodland creatures appear at dawn'),
(43, 'Sea food restaurant opens downtown', 'Seashore cleanup needs more volunteers', 'The seaweed wraps taste great', 'Sea-level rise concerns scientists', 'Seaside resort welcomes more guests'),
(44, 'Eye catching display attracts customers', 'Eyewitness testimony helps solve case', 'The eyesight test shows improvement', 'Eye-tracking study reveals patterns', 'Eyeglasses prescription needs updating'),
(45, 'Film making course begins today', 'Filmmaker shares inspiring success story', 'The filming location remains secret', 'Film-noir festival starts tomorrow', 'Filmstrip projector needs repair'),
(46, 'Side walking pedestrians avoid collision', 'Sideways glance reveals hidden door', 'The sidecar needs new paint', 'Side-effect concerns worry patients', 'Sideline reporter interviews coach'),
(47, 'Back pack full of supplies', 'Backing tracks support live performance', 'The backroom deal falls through', 'Back-ordered items arrive tomorrow', 'Background check reveals interesting facts'),
(48, 'Night time security increases significantly', 'Nightclub renovation nears completion', 'The nightshift workers deserve praise', 'Night-vision goggles work perfectly', 'Nightstand delivery arrives late'),
(49, 'Farm house renovation nearly complete', 'Farming equipment needs urgent repair', 'The farmland produces record crop', 'Farm-fresh eggs sell quickly', 'Farmworkers receive better benefits'),
(50, 'Dance floor fills with people', 'Dancing lessons improve coordination significantly', 'The dancers perform magnificently today', 'Dance-off competition starts soon', 'Dancewear shop opens downtown'),
(51, 'Road work delays morning traffic', 'Roadside assistance arrives very quickly', 'The roadmap guides future development', 'Road-tested vehicles perform well', 'Roadworthy certification expires soon'),
(52, 'Sky diving instruction begins today', 'Skyward growth shows great promise', 'The skylark sings at dawn', 'Sky-high prices concern consumers', 'Skyline changes shape dramatically'),
(53, 'Gate keeping duties require attention', 'Gateway project nears final completion', 'The gatepost needs urgent repair', 'Gate-crashed party causes chaos', 'Gatekeeper training starts next week'),
(54, 'Train station undergoes major renovation', 'Training program delivers great results', 'The trainee shows promising skills', 'Train-spotting group meets regularly', 'Trained professionals handle the situation'),
(55, 'Sound proof rooms block noise', 'Sounding board provides valuable feedback', 'The soundscape creates peaceful atmosphere', 'Sound-activated lights work perfectly', 'Soundwave analysis reveals interesting patterns'),
(56, 'Door frame needs immediate replacement', 'Doorway entrance requires better lighting', 'The doorbell chimes need adjustment', 'Door-to-door service starts tomorrow', 'Doorkeeper maintains strict security'),
(57, 'Star gazing event attracts crowds', 'Starlight illuminates mountain path', 'The starship launches next week', 'Star-studded performance receives acclaim', 'Starboard engine requires maintenance'),
(58, 'Fish market opens early morning', 'Fishing expedition returns with catch', 'The fisherman shares amazing stories', 'Fish-farming project shows promise', 'Fishbowl discussion generates new ideas'),
(59, 'Mail room processes incoming packages', 'Mailing list needs urgent update', 'The mailman delivers important documents', 'Mail-order business grows rapidly', 'Mailbox installation completed successfully'),
(60, 'Rock climbing equipment arrives today', 'Rockstar performs benefit concert', 'The rockery needs fresh plants', 'Rock-solid evidence supports claim', 'Rockslide warning issued for area'),
(61, 'Tree house construction begins soon', 'Treetop adventure course opens', 'The treeline marks hiking boundary', 'Tree-dwelling animals fascinate researchers', 'Treeless plateau challenges farmers'),
(62, 'Game changing strategy proves successful', 'Gaming industry continues rapid growth', 'The gameplay mechanics need improvement', 'Game-winning shot thrills crowd', 'Gamekeeper reports wildlife increase'),
(63, 'Snow boarding championship starts tomorrow', 'Snowfall prediction causes travel concerns', 'The snowplow clears mountain roads', 'Snow-capped peaks attract climbers', 'Snowshoe trails open this weekend'),
(64, 'Care giving services expand rapidly', 'Careful planning prevents major problems', 'The caretaker maintains historic building', 'Care-free lifestyle attracts millennials', 'Caregiver support group meets monthly'),
(65, 'Day light saving time begins', 'Daytime programming schedule changes', 'The daycare center needs volunteers', 'Day-to-day operations run smoothly', 'Daybreak brings beautiful sunrise'),
(66, 'Ring tone volume needs adjustment', 'Ringing bells announce special event', 'The ringmaster introduces new act', 'Ring-shaped structure attracts architects', 'Ringside seats sell out quickly'),
(67, 'Cup holder breaks during shipping', 'Cupboard organization improves efficiency', 'The cupcake display attracts children', 'Cup-winning team celebrates victory', 'Cuprite specimens arrive for exhibition'),
(69, 'Brain storming session generates ideas', 'Brainwave activity shows interesting patterns', 'The brainteaser challenges participants', 'Brain-computer interface advances rapidly', 'Brainpower enhancement techniques discussed'),
(70, 'Horse riding lessons start today', 'Horseshoe competition draws crowds', 'The horsepower upgrade improves performance', 'Horse-drawn carriage tours begin', 'Horseback patrol monitors wildlife'),
(71, 'Bank roll funds new project', 'Banking services expand next month', 'The banker discusses investment options', 'Bank-issued cards arrive tomorrow', 'Bankside development project continues'),
(72, 'Fall back position provides security', 'Falling leaves create beautiful scene', 'The fallout shelter needs inspection', 'Fall-prevention measures prove effective', 'Fallbrook residents celebrate festival'),
(73, 'Run time error affects system', 'Running shoes arrive next week', 'The runner breaks previous record', 'Run-down building needs renovation', 'Runoff election scheduled for December'),
(74, 'Blue print reading workshop begins', 'Bluetooth connectivity improves significantly', 'The bluebird sanctuary opens today', 'Blue-ribbon panel releases findings', 'Blueberry harvest exceeds expectations'),
(75, 'Page break formatting needs adjustment', 'Pageant winner receives scholarship', 'The pageboy uniform needs updating', 'Page-turning technology improves accessibility', 'Pagination system works efficiently'),
(76, 'Heat wave affects outdoor activities', 'Heating system requires urgent maintenance', 'The heater installation starts tomorrow', 'Heat-resistant materials arrive today', 'Heatstroke prevention measures implemented'),
(77, 'Sun room renovation nearly complete', 'Sunbathing area opens next week', 'The sunflower field attracts photographers', 'Sun-dried tomatoes taste delicious', 'Sunspot activity affects communications'),
(78, 'Rain forest conservation efforts continue', 'Rainfall measurements show record levels', 'The rainmaker ceremony begins today', 'Rain-soaked ground causes delays', 'Rainbow appears after brief shower'),
(79, 'War time stories inspire audience', 'Warning signs posted near construction', 'The warship docks next week', 'War-torn regions receive aid', 'Wardrobe department needs volunteers'),
(80, 'Line dancing class starts today', 'Linework needs careful attention now', 'The linebacker signs new contract', 'Line-caught fish tastes better', 'Linen service improves hotel rating'),
(81, 'Gold mining operation expands significantly', 'Golden opportunity presents itself today', 'The goldfish pond needs cleaning', 'Gold-plated awards arrive tomorrow', 'Goldsmith creates unique pieces'),
(82, 'Salt water damages metal components', 'Salted caramel flavors new dessert', 'The saltbox house needs restoration', 'Salt-resistant plants grow well', 'Saltmine tours resume next month'),
(83, 'Coal mining town celebrates centennial', 'Coalition building efforts show progress', 'The coastline needs environmental protection', 'Coal-fired plant closes permanently', 'Coaxial cable installation begins'),
(84, 'Milk shake machine needs repair', 'Milking process becomes more automated', 'The milkman delivers fresh products', 'Milk-based products sell well', 'Milkweed attracts monarch butterflies'),
(85, 'Oil painting class begins tomorrow', 'Oiling machine requires maintenance now', 'The oilfield produces record amounts', 'Oil-based paint dries slowly', 'Oilseed crops show promising results'),
(86, 'Web design course starts monday', 'Webmaster updates security protocols', 'The website launches next week', 'Web-based training proves effective', 'Webinar attendance exceeds expectations'),
(87, 'Rest room renovation nearly complete', 'Resting place attracts many visitors', 'The restaurant opens next month', 'Rest-assured guarantee satisfies customers', 'Restless waves pound the shore'),
(88, 'Sea shore cleanup needs volunteers', 'Seabird sanctuary protects endangered species', 'The seaweed harvest begins today', 'Sea-level rise concerns scientists', 'Seaside resort welcomes guests'),
(89, 'Key board replacement arrives tomorrow', 'Keyhole surgery proves very successful', 'The keynote speaker impresses audience', 'Key-cutting service opens downtown', 'Keystone species faces new threats'),
(90, 'Bed room furniture arrives today', 'Bedside manner improves patient satisfaction', 'The bedrock shows interesting formations', 'Bed-and-breakfast receives great reviews', 'Bedding plants need regular water'),
(91, 'Ice cream shop opens downtown', 'Iceberg lettuce supplies run low', 'The icemaker needs urgent repair', 'Ice-skating rink attracts crowds', 'Icebreaker activities encourage participation'),
(92, 'Foot ball match draws record crowd', 'Footpath maintenance begins next week', 'The footbridge needs structural repair', 'Foot-long sandwiches sell quickly', 'Footwear department expands selection'),
(93, 'Car port construction starts tomorrow', 'Carpet cleaning service arrives today', 'The carnival attracts huge crowds', 'Car-sharing program launches soon', 'Carwash equipment needs maintenance'),
(94, 'Light house guide explains history', 'Lightning protection system works perfectly', 'The lightbulb invention changed everything', 'Light-sensitive materials require care', 'Lighter fluid sales increase seasonally'),
(95, 'Back yard garden produces abundantly', 'Background music plays too loudly', 'The backbone shows slight curvature', 'Back-to-school shopping starts soon', 'Backlog clearance requires overtime'),
(96, 'Row boat rental opens seasonally', 'Rowing competition starts next week', 'The rowhouse needs exterior painting', 'Row-by-row instructions seem clear', 'Rowdy crowd disperses quickly'),
(97, 'Pine tree plantation expands significantly', 'Pinewood derby excites young racers', 'The pineapple harvest looks promising', 'Pine-scented candles sell well', 'Pinecone crafts attract buyers'),
(98, 'Stream lined process improves efficiency', 'Streaming service launches new features', 'The streambed needs erosion control', 'Stream-of-consciousness writing workshop begins', 'Streamside trail opens tomorrow'),
(99, 'News paper delivery arrives early', 'Newsroom staff works overtime today', 'The newsstand opens next week', 'News-worthy stories attract attention', 'Newsreel footage shows historical events'),
(100, 'Top side entrance needs repair', 'Topsoil delivery arrives this morning', 'The topknot hairstyle becomes popular', 'Top-rated show wins award', 'Topographical survey reveals details')
GO
