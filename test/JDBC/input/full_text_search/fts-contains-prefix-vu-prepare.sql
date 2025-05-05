SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- sys.babelfish_fts_rewrite()
-- 1. rewriting single prefix term
CREATE VIEW prefix_rewrite_prepare_v1 AS (SELECT sys.babelfish_fts_rewrite('"one*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v2 AS (SELECT sys.babelfish_fts_rewrite(' "one*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p1 AS (SELECT sys.babelfish_fts_rewrite('"one*" '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p2 AS (SELECT sys.babelfish_fts_rewrite(' "one*" '));
GO

-- 2. rewriting prefix term phrase
CREATE VIEW prefix_rewrite_prepare_v3 AS (SELECT sys.babelfish_fts_rewrite('"one two three*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v4 AS (SELECT sys.babelfish_fts_rewrite(' "one two three*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v5 AS (SELECT sys.babelfish_fts_rewrite('"one two three*" '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p3 AS (SELECT sys.babelfish_fts_rewrite('"one* two three*"  '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p4 AS (SELECT sys.babelfish_fts_rewrite(' "one two three*" '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p5 AS (SELECT sys.babelfish_fts_rewrite(' "one*two*three*" '));
GO

-- 3. Leading occurrences of asterisk
CREATE VIEW prefix_rewrite_prepare_v6 AS (SELECT sys.babelfish_fts_rewrite('"*one*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v7 AS (SELECT sys.babelfish_fts_rewrite(' "*one*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v8 AS (SELECT sys.babelfish_fts_rewrite('"***one*"  '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p6 AS (SELECT sys.babelfish_fts_rewrite('"*one*two*three*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p7 AS (SELECT sys.babelfish_fts_rewrite('"*one* *two* **three*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p8 AS (SELECT sys.babelfish_fts_rewrite('  "***one* **two*three*"'));
GO

-- 4. Trailing occurrences of asterisk
CREATE VIEW prefix_rewrite_prepare_v9 AS (SELECT sys.babelfish_fts_rewrite('"one**"'));
GO
CREATE VIEW prefix_rewrite_prepare_v10 AS (SELECT sys.babelfish_fts_rewrite('"one******"'));
GO
CREATE VIEW prefix_rewrite_prepare_v11 AS (SELECT sys.babelfish_fts_rewrite('"one ***"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p9 AS (SELECT sys.babelfish_fts_rewrite('"one two***"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p10 AS (SELECT sys.babelfish_fts_rewrite('  "one*** two*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p11 AS (SELECT sys.babelfish_fts_rewrite(' "one** two****"  '));
GO

--5. Multiple occurrences of asterisk in prefix phrase
CREATE VIEW prefix_rewrite_prepare_v12 AS (SELECT sys.babelfish_fts_rewrite('" **one***two*three***"'));
GO
CREATE VIEW prefix_rewrite_prepare_v13 AS (SELECT sys.babelfish_fts_rewrite('" **one*** *two ***three**"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p12 AS (SELECT sys.babelfish_fts_rewrite('" *one* **two* **three*"  '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p13 AS (SELECT sys.babelfish_fts_rewrite('" *one* ***two * **three *"  '));
GO

-- 6. Multiple occurrences of spaces in prefix phrase
CREATE VIEW prefix_rewrite_prepare_v14 AS (SELECT sys.babelfish_fts_rewrite(' "*one *two*"  '));
GO
CREATE VIEW prefix_rewrite_prepare_v15 AS (SELECT sys.babelfish_fts_rewrite(' "*  one *two *"  '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p14 AS (SELECT sys.babelfish_fts_rewrite(' "*    one *     two      *"  '));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p15 AS (SELECT sys.babelfish_fts_rewrite(' "      *one*     two   *"  '));
GO

-- 7. Combination of multiple occurrences of spaces and asterisk and tab spaces in prefix phrase
CREATE VIEW prefix_rewrite_prepare_v16 AS (SELECT sys.babelfish_fts_rewrite('" *    * one * * * two*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v17 AS (SELECT sys.babelfish_fts_rewrite('"one   * * *       * * two     *"'));
GO
CREATE VIEW prefix_rewrite_prepare_v18 AS (SELECT sys.babelfish_fts_rewrite('"  one*  two * *   ** three* ** *"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p16 AS (SELECT sys.babelfish_fts_rewrite('" * ** one * two* three   **"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p17 AS (SELECT sys.babelfish_fts_rewrite('"one  * two  *  three ** **"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p18 AS (SELECT sys.babelfish_fts_rewrite('"one* two  *  three * * **"'));
GO

-- 8. special characters
-- should throw not supported error
CREATE VIEW prefix_rewrite_prepare_v19 AS (SELECT sys.babelfish_fts_rewrite('"one$*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v20 AS (SELECT sys.babelfish_fts_rewrite('"$$one*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p19 AS (SELECT sys.babelfish_fts_rewrite('" $one *"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p20 AS (SELECT sys.babelfish_fts_rewrite('" one@*"'));
GO

-- 9. support for emojis
-- should throw languages other than english are not supported
CREATE VIEW prefix_rewrite_prepare_v21 AS (SELECT sys.babelfish_fts_rewrite(N'"one👋*"'));
GO
CREATE VIEW prefix_rewrite_prepare_v22 AS (SELECT sys.babelfish_fts_rewrite(N'"🙂one*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p21 AS (SELECT sys.babelfish_fts_rewrite(N'"✅🆗*"'));
GO
CREATE PROCEDURE prefix_rewrite_prepare_p22 AS (SELECT sys.babelfish_fts_rewrite(N'"one 👍*"'));
GO

-- Negative test
-- should warn about noise words, but does not
CREATE VIEW prefix_rewrite_prepare_v23 AS (SELECT sys.babelfish_fts_rewrite('"*"'));
GO

-- Not a valid prefix term syntax, recognized as simple term
CREATE PROCEDURE prefix_rewrite_prepare_p23 AS (SELECT sys.babelfish_fts_rewrite('"o@ne* "'));
GO

-- create the table
CREATE TABLE fts_char_prefix_t (
    id INT NOT NULL,
    main_story TEXT,
    industry_update VARCHAR(500),
    local_news CHAR(500),
    tech_highlight NCHAR(500),
    community_event NVARCHAR(500),
)

DECLARE @a VARCHAR(100)
SET @a = 'Mountain'+CHAR(10)+'climbing expedition begins'
INSERT INTO fts_char_prefix_t values(1, @a, 'Elevated peaks attract tourists', 'Climbing gear sales increase', 'Mountain rescue team trains regularly', 'Alpine flora study concludes')
GO

DECLARE @b VARCHAR(100)
SET @b = 'Ocean'+CHAR(9)+'depths explored today'
INSERT INTO fts_char_prefix_t values(2, 'Marine biology course opens', @b, 'Diving equipment needs maintenance', 'Submarine launch delayed slightly', 'Coral reef preservation efforts continue')
GO

DECLARE @c VARCHAR(100)
SET @c = 'Urban'+CHAR(10)+'planning meeting'+CHAR(9)+'scheduled'
INSERT INTO fts_char_prefix_t values(3, 'City development plans finalized', 'Downtown revitalization project starts', @c, 'Traffic flow study completed', 'Green spaces increase in neighborhoods')
GO

DECLARE @d VARCHAR(100)
SET @d = 'Forest'+CHAR(9)+'conservation efforts'+CHAR(10)+'expand'
INSERT INTO fts_char_prefix_t values(4, @d, 'Timber industry seeks sustainable practices', 'Wildlife corridors established', 'Reforestation project shows promise', 'Biodiversity study reveals new species')
GO

DECLARE @e VARCHAR(100)
SET @e = 'Desert'+CHAR(10)+'expedition faces'+CHAR(9)+'challenges'
INSERT INTO fts_char_prefix_t values(5, 'Oasis discovery excites researchers', @e, 'Sand dune stabilization begins', 'Camel caravan arrives safely', 'Ancient artifacts unearthed recently')
GO

DECLARE @f VARCHAR(100)
SET @f = 'Arctic'+CHAR(9)+'research station'+CHAR(10)+'expands'
INSERT INTO fts_char_prefix_t values(6, 'Polar bear population monitored closely', 'Ice core samples reveal climate history', @f, 'Northern lights attract tourists', 'Inuit cultural preservation efforts continue')
GO

DECLARE @g VARCHAR(100)
SET @g = 'Volcanic'+CHAR(10)+'activity'+CHAR(9)+'increases'
INSERT INTO fts_char_prefix_t values(7, @g, 'Lava flow redirected successfully', 'Ash cloud disrupts air travel', 'Geothermal energy potential explored', 'Evacuation procedures reviewed thoroughly')
GO

DECLARE @h VARCHAR(100)
SET @h = 'Rainforest'+CHAR(9)+'canopy study'+CHAR(10)+'begins'
INSERT INTO fts_char_prefix_t values(8, 'Deforestation rates decrease slightly', @h, 'Indigenous tribes protect sacred lands', 'Medicinal plant discovery excites scientists', 'Ecotourism provides alternative income')
GO

DECLARE @i VARCHAR(100)
SET @i = 'Coral'+CHAR(10)+'reef'+CHAR(9)+'restoration project launches'
INSERT INTO fts_char_prefix_t values(9, 'Marine protected areas expand', 'Sustainable fishing practices promoted', @i, 'Scuba diving tourism increases', 'Ocean acidification threatens ecosystems')
GO

DECLARE @j VARCHAR(100)
SET @j = 'Tundra'+CHAR(9)+'ecosystem faces'+CHAR(10)+'challenges'
INSERT INTO fts_char_prefix_t values(10, @j, 'Permafrost thaw accelerates', 'Arctic fox population declines', 'Climate change impacts studied', 'Native plant species adapt slowly')
GO

DECLARE @k VARCHAR(100)
SET @k = 'Grassland'+CHAR(10)+'conservation efforts'+CHAR(9)+'intensify'
INSERT INTO fts_char_prefix_t values(11, 'Prairie dog colonies expand', @k, 'Wildflower diversity increases', 'Bison herds roam freely', 'Sustainable ranching practices implemented')
GO

DECLARE @l VARCHAR(100)
SET @l = 'Wetland'+CHAR(9)+'restoration project'+CHAR(10)+'succeeds'
INSERT INTO fts_char_prefix_t values(12, 'Migratory bird populations recover', 'Water quality improves significantly', @l, 'Flood mitigation efforts show results', 'Invasive species removal continues')
GO

DECLARE @m VARCHAR(100)
SET @m = 'Savanna'+CHAR(10)+'wildlife'+CHAR(9)+'census completed'
INSERT INTO fts_char_prefix_t values(13, @m, 'Elephant poaching incidents decrease', 'Drought resistant crops introduced', 'Lion conservation efforts expand', 'Traditional land management practices revived')
GO

DECLARE @n VARCHAR(100)
SET @n = 'Alpine'+CHAR(9)+'glacier retreat'+CHAR(10)+'accelerates'
INSERT INTO fts_char_prefix_t values(14, 'Mountain goat habitat shrinks', @n, 'Ski industry adapts to changes', 'Avalanche risk increases seasonally', 'High altitude vegetation shifts observed')
GO

DECLARE @o VARCHAR(100)
SET @o = 'Mangrove'+CHAR(10)+'forest protection'+CHAR(9)+'expands'
INSERT INTO fts_char_prefix_t values(15, 'Coastal erosion rates decrease', 'Fish nursery habitats improve', @o, 'Carbon sequestration potential studied', 'Local communities benefit from conservation')
GO

DECLARE @p VARCHAR(100)
SET @p = 'River'+CHAR(9)+'delta restoration'+CHAR(10)+'project begins'
INSERT INTO fts_char_prefix_t values(16, @p, 'Sediment flow patterns change', 'Freshwater fish populations recover', 'Flood risk management improves', 'Wetland bird species diversity increases')
GO

DECLARE @q VARCHAR(100)
SET @q = 'Boreal'+CHAR(10)+'forest fire'+CHAR(9)+'management improves'
INSERT INTO fts_char_prefix_t values(17, 'Timber industry adopts sustainable practices', @q, 'Wildlife corridors established', 'Carbon storage capacity increases', 'Indigenous fire management techniques integrated')
GO

DECLARE @r VARCHAR(100)
SET @r = 'Coral'+CHAR(9)+'bleaching event'+CHAR(10)+'monitored closely'
INSERT INTO fts_char_prefix_t values(18, 'Ocean temperature rise concerns scientists', 'Reef resilience studies continue', @r, 'Marine protected areas expand', 'Sustainable tourism practices promoted')
GO

DECLARE @s VARCHAR(100)
SET @s = 'Desert'+CHAR(10)+'oasis'+CHAR(9)+'conservation efforts intensify'
INSERT INTO fts_char_prefix_t values(19, @s, 'Groundwater depletion slows', 'Unique ecosystems protected', 'Sustainable agriculture practices implemented', 'Ecotourism provides alternative livelihoods')
GO

DECLARE @t VARCHAR(100)
SET @t = 'Arctic'+CHAR(9)+'sea ice'+CHAR(10)+'extent decreases'
INSERT INTO fts_char_prefix_t values(20, 'Polar bear habitat shrinks', @t, 'Northern shipping routes open', 'Indigenous communities adapt to changes', 'Climate models updated regularly')
GO

DECLARE @u VARCHAR(100)
SET @u = 'Tropical'+CHAR(10)+'cyclone'+CHAR(9)+'patterns shift'
INSERT INTO fts_char_prefix_t values(21, @u, 'Coastal communities prepare for changes', 'Early warning systems improve', 'Insurance industry reassesses risks', 'Climate change link studied extensively')
GO

DECLARE @v VARCHAR(100)
SET @v = 'Grassland'+CHAR(9)+'ecosystem'+CHAR(10)+'restoration begins'
INSERT INTO fts_char_prefix_t values(22, 'Native plant species reintroduced', @v, 'Soil carbon sequestration increases', 'Grazing management practices improve', 'Biodiversity monitoring continues')
GO

DECLARE @w VARCHAR(100)
SET @w = 'Coral'+CHAR(10)+'reef'+CHAR(9)+'restoration project expands'
INSERT INTO fts_char_prefix_t values(23, 'Marine biodiversity hotspots protected', 'Sustainable fishing practices promoted', @w, 'Ecotourism provides alternative livelihoods', 'Ocean acidification impacts studied')
GO

DECLARE @x VARCHAR(100)
SET @x = 'Tundra'+CHAR(9)+'permafrost'+CHAR(10)+'thaw accelerates'
INSERT INTO fts_char_prefix_t values(24, @x, 'Carbon release concerns scientists', 'Arctic infrastructure faces challenges', 'Vegetation changes observed regularly', 'Indigenous communities adapt to shifts')
GO

DECLARE @y VARCHAR(100)
SET @y = 'Savanna'+CHAR(10)+'fire'+CHAR(9)+'management improves'
INSERT INTO fts_char_prefix_t values(25, 'Wildlife populations recover slowly', @y, 'Traditional ecological knowledge integrated', 'Carbon storage potential increases', 'Sustainable grazing practices implemented')
GO

DECLARE @z VARCHAR(100)
SET @z = 'Alpine'+CHAR(9)+'ecosystem'+CHAR(10)+'faces climate pressures'
INSERT INTO fts_char_prefix_t values(26, 'Mountain species migrate upslope', 'Glacial retreat accelerates notably', @z, 'Ski industry adapts to changes', 'High-altitude research station expands')
GO

DECLARE @aa VARCHAR(100)
SET @aa = 'Wetland'+CHAR(10)+'bird'+CHAR(9)+'populations recover'
INSERT INTO fts_char_prefix_t values(27, @aa, 'Water quality improves significantly', 'Invasive plant removal continues', 'Flood mitigation benefits observed', 'Ecosystem services valuation completed')
GO

DECLARE @ab VARCHAR(100)
SET @ab = 'Mangrove'+CHAR(9)+'reforestation'+CHAR(10)+'project succeeds'
INSERT INTO fts_char_prefix_t values(28, 'Coastal protection improves noticeably', @ab, 'Fish nursery habitats expand', 'Carbon sequestration increases', 'Local communities benefit economically')
GO

DECLARE @ac VARCHAR(100)
SET @ac = 'River'+CHAR(10)+'ecosystem'+CHAR(9)+'health improves'
INSERT INTO fts_char_prefix_t values(29, 'Water quality standards met', 'Fish populations show recovery', @ac, 'Riparian buffer zones expanded', 'Sustainable water use practices implemented')
GO

DECLARE @ad VARCHAR(100)
SET @ad = 'Boreal'+CHAR(9)+'forest'+CHAR(10)+'management plan updated'
INSERT INTO fts_char_prefix_t values(30, @ad, 'Sustainable logging practices adopted', 'Wildlife corridors established successfully', 'Carbon storage capacity increases', 'Indigenous land rights strengthened')
GO

DECLARE @ae VARCHAR(100)
SET @ae = 'Coral'+CHAR(10)+'reef'+CHAR(9)+'resilience study concludes'
INSERT INTO fts_char_prefix_t values(31, 'Ocean warming impacts assessed', 'Marine protected areas prove effective', @ae, 'Sustainable tourism guidelines implemented', 'Coral restoration techniques improved')
GO

DECLARE @af VARCHAR(100)
SET @af = 'Desert'+CHAR(9)+'ecosystem'+CHAR(10)+'restoration project launches'
INSERT INTO fts_char_prefix_t values(32, @af, 'Native plant species reintroduced', 'Water conservation methods improved', 'Sand dune stabilization efforts continue', 'Sustainable agriculture practices promoted')
GO

DECLARE @ag VARCHAR(100)
SET @ag = 'Arctic'+CHAR(10)+'wildlife'+CHAR(9)+'adaptation observed'
INSERT INTO fts_char_prefix_t values(33, 'Polar bear behavior changes noted', @ag, 'Sea ice extent monitoring continues', 'Tundra vegetation shifts documented', 'Indigenous knowledge informs research')
GO

DECLARE @ah VARCHAR(100)
SET @ah = 'Tropical'+CHAR(9)+'forest'+CHAR(10)+'canopy study begins'
INSERT INTO fts_char_prefix_t values(34, 'Biodiversity hotspots identified', 'Deforestation rates decrease slightly', @ah, 'Carbon sequestration potential assessed', 'Sustainable forestry practices implemented')
GO

DECLARE @ai VARCHAR(100)
SET @ai = 'Grassland'+CHAR(10)+'soil'+CHAR(9)+'health improves'
INSERT INTO fts_char_prefix_t values(35, @ai, 'Native grass species thrive', 'Sustainable grazing practices adopted', 'Carbon sequestration increases notably', 'Erosion control measures prove effective')
GO

DECLARE @aj VARCHAR(100)
SET @aj = 'Wetland'+CHAR(9)+'ecosystem'+CHAR(10)+'services valued'
INSERT INTO fts_char_prefix_t values(36, 'Water filtration benefits quantified', @aj, 'Flood mitigation potential assessed', 'Biodiversity support role recognized', 'Carbon storage capacity measured')
GO

DECLARE @ak VARCHAR(100)
SET @ak = 'Savanna'+CHAR(10)+'elephant'+CHAR(9)+'population stabilizes'
INSERT INTO fts_char_prefix_t values(37, @ak, 'Anti-poaching efforts show results', 'Habitat connectivity improves', 'Human-wildlife conflict decreases', 'Ecosystem engineer role highlighted')
GO

DECLARE @al VARCHAR(100)
SET @al = 'Alpine'+CHAR(9)+'plant'+CHAR(10)+'species shift upslope'
INSERT INTO fts_char_prefix_t values(38, 'Treeline advances slowly', @al, 'Rare species face extinction risk', 'Habitat fragmentation concerns scientists', 'Long-term monitoring project continues')
GO

DECLARE @am VARCHAR(100)
SET @am = 'Mangrove'+CHAR(10)+'forest'+CHAR(9)+'carbon storage assessed'
INSERT INTO fts_char_prefix_t values(39, 'Blue carbon potential quantified', 'Coastal protection role valued', @am, 'Sustainable harvesting practices promoted', 'Ecosystem restoration efforts expand')
GO

DECLARE @an VARCHAR(100)
SET @an = 'River'+CHAR(9)+'basin'+CHAR(10)+'management plan updated'
INSERT INTO fts_char_prefix_t values(40, @an, 'Water allocation conflicts resolved', 'Flood risk assessment completed', 'Riparian habitat restoration continues', 'Sustainable agriculture practices adopted')
GO

DECLARE @ao VARCHAR(100)
SET @ao = 'Boreal'+CHAR(10)+'forest'+CHAR(9)+'fire regime changes'
INSERT INTO fts_char_prefix_t values(41, 'Wildfire frequency increases notably', @ao, 'Forest composition shifts observed', 'Carbon release concerns scientists', 'Fire management strategies adapted')
GO

DECLARE @ap VARCHAR(100)
SET @ap = 'Coral'+CHAR(9)+'reef'+CHAR(10)+'fish populations recover'
INSERT INTO fts_char_prefix_t values(42, 'Marine protected areas prove effective', 'Sustainable fishing practices adopted', @ap, 'Ecosystem balance improves slowly', 'Tourism industry benefits observed')
GO

DECLARE @aq VARCHAR(100)
SET @aq = 'Desert'+CHAR(10)+'dust'+CHAR(9)+'storms intensify'
INSERT INTO fts_char_prefix_t values(43, @aq, 'Air quality concerns increase', 'Soil erosion accelerates notably', 'Climate change link studied', 'Mitigation strategies developed')
GO

DECLARE @ar VARCHAR(100)
SET @ar = 'Arctic'+CHAR(9)+'marine'+CHAR(10)+'ecosystem changes observed'
INSERT INTO fts_char_prefix_t values(44, 'Sea ice decline impacts assessed', @ar, 'Plankton bloom patterns shift', 'Fish species distribution changes', 'Indigenous communities adapt practices')
GO

DECLARE @as VARCHAR(100)
SET @as = 'Tropical'+CHAR(10)+'rainforest'+CHAR(9)+'restoration succeeds'
INSERT INTO fts_char_prefix_t values(45, 'Biodiversity levels increase notably', 'Carbon sequestration improves significantly', @as, 'Local communities benefit economically', 'Sustainable management practices implemented')
GO

DECLARE @at VARCHAR(100)
SET @at = 'Grassland'+CHAR(9)+'bird'+CHAR(10)+'species diversity increases'
INSERT INTO fts_char_prefix_t values(46, @at, 'Native plant restoration continues', 'Sustainable grazing practices adopted', 'Habitat connectivity improves', 'Long-term monitoring project expands')
GO

DECLARE @au VARCHAR(100)
SET @au = 'Wetland'+CHAR(10)+'water'+CHAR(9)+'quality improves'
INSERT INTO fts_char_prefix_t values(47, 'Pollution levels decrease significantly', @au, 'Aquatic species diversity increases', 'Ecosystem services expand', 'Community involvement strengthens')
GO

DECLARE @av VARCHAR(100)
SET @av = 'Mountain'+CHAR(9)+'goat'+CHAR(10)+'population thrives'
INSERT INTO fts_char_prefix_t values(48, @av, 'Alpine meadows recover slowly', 'Wildlife corridors prove effective', 'Conservation efforts show results', 'Research project continues successfully')
GO

DECLARE @aw VARCHAR(100)
SET @aw = 'Forest'+CHAR(10)+'canopy'+CHAR(9)+'study reveals patterns'
INSERT INTO fts_char_prefix_t values(49, 'Biodiversity assessment completed', 'Species interaction mapped thoroughly', @aw, 'Ecosystem dynamics understood better', 'Conservation strategies updated accordingly')
GO

DECLARE @ax VARCHAR(100)
SET @ax = 'Lake'+CHAR(9)+'ecosystem'+CHAR(10)+'health improves'
INSERT INTO fts_char_prefix_t values(50, @ax, 'Fish populations recover steadily', 'Water quality meets standards', 'Recreational activities resume safely', 'Monitoring programs continue regularly')
GO

DECLARE @ay VARCHAR(100)
SET @ay = 'Coastal'+CHAR(10)+'erosion'+CHAR(9)+'control succeeds'
INSERT INTO fts_char_prefix_t values(51, 'Beach restoration shows progress', @ay, 'Dune vegetation establishes well', 'Storm protection improves significantly', 'Community support increases steadily')
GO

DECLARE @az VARCHAR(100)
SET @az = 'Valley'+CHAR(9)+'farming'+CHAR(10)+'practices change'
INSERT INTO fts_char_prefix_t values(52, 'Sustainable agriculture expands', 'Water conservation improves notably', @az, 'Soil health recovers gradually', 'Crop diversity increases substantially')
GO

DECLARE @ba VARCHAR(100)
SET @ba = 'Stream'+CHAR(10)+'restoration'+CHAR(9)+'project completed'
INSERT INTO fts_char_prefix_t values(53, @ba, 'Fish passage improves significantly', 'Water quality meets standards', 'Riparian habitat recovers well', 'Community benefits observed clearly')
GO

DECLARE @bb VARCHAR(100)
SET @bb = 'Desert'+CHAR(9)+'research'+CHAR(10)+'station expands'
INSERT INTO fts_char_prefix_t values(54, 'Climate studies advance rapidly', @bb, 'Species adaptation documented carefully', 'Conservation efforts show promise', 'International collaboration strengthens')
GO

DECLARE @bc VARCHAR(100)
SET @bc = 'Canyon'+CHAR(10)+'wildlife'+CHAR(9)+'survey completed'
INSERT INTO fts_char_prefix_t values(55, @bc, 'Species diversity increases notably', 'Habitat restoration succeeds', 'Research findings encourage conservation', 'Local support grows steadily')
GO

DECLARE @bd VARCHAR(100)
SET @bd = 'Marsh'+CHAR(9)+'bird'+CHAR(10)+'population recovers'
INSERT INTO fts_char_prefix_t values(56, 'Wetland restoration continues', @bd, 'Water quality improves significantly', 'Native plants thrive naturally', 'Conservation efforts show results')
GO

DECLARE @be VARCHAR(100)
SET @be = 'Prairie'+CHAR(10)+'dog'+CHAR(9)+'colonies expand'
INSERT INTO fts_char_prefix_t values(57, 'Grassland ecosystem improves', 'Native vegetation returns slowly', @be, 'Predator populations stabilize', 'Research project yields insights')
GO

DECLARE @bf VARCHAR(100)
SET @bf = 'Ridge'+CHAR(9)+'trail'+CHAR(10)+'construction begins'
INSERT INTO fts_char_prefix_t values(58, 'Mountain access improves safely', @bf, 'Wildlife corridors remain protected', 'Tourist numbers increase steadily', 'Local economy benefits significantly')
GO

DECLARE @bg VARCHAR(100)
SET @bg = 'Basin'+CHAR(10)+'water'+CHAR(9)+'quality improves'
INSERT INTO fts_char_prefix_t values(59, @bg, 'Fish populations recover well', 'Pollution levels decrease notably', 'Ecosystem health strengthens daily', 'Community engagement increases substantially')
GO

DECLARE @bh VARCHAR(100)
SET @bh = 'Plateau'+CHAR(9)+'research'+CHAR(10)+'project launches'
INSERT INTO fts_char_prefix_t values(60, 'High altitude studies begin', @bh, 'Climate impact assessment starts', 'Species adaptation documented carefully', 'International collaboration grows')
GO

DECLARE @bi VARCHAR(100)
SET @bi = 'Summit'+CHAR(10)+'weather'+CHAR(9)+'station upgraded'
INSERT INTO fts_char_prefix_t values(61, 'Climate monitoring improves', 'Research capabilities expand', @bi, 'Data collection becomes automated', 'Scientific understanding advances significantly')
GO

DECLARE @bj VARCHAR(100)
SET @bj = 'Delta'+CHAR(9)+'ecosystem'+CHAR(10)+'study continues'
INSERT INTO fts_char_prefix_t values(62, 'River health improves steadily', @bj, 'Sediment patterns change naturally', 'Wildlife populations recover gradually', 'Conservation efforts show success')
GO

DECLARE @bk VARCHAR(100)
SET @bk = 'Jungle'+CHAR(10)+'canopy'+CHAR(9)+'research expands'
INSERT INTO fts_char_prefix_t values(63, @bk, 'Biodiversity assessment completed', 'Species interactions documented thoroughly', 'Conservation strategies updated regularly', 'Local communities participate actively')
GO

DECLARE @bl VARCHAR(100)
SET @bl = 'Lagoon'+CHAR(9)+'health'+CHAR(10)+'improves significantly'
INSERT INTO fts_char_prefix_t values(64, 'Water quality meets standards', @bl, 'Marine life returns steadily', 'Tourism industry benefits greatly', 'Research continues successfully')
GO

DECLARE @bm VARCHAR(100)
SET @bm = 'Peninsula'+CHAR(10)+'conservation'+CHAR(9)+'effort succeeds'
INSERT INTO fts_char_prefix_t values(65, 'Coastal protection improves', 'Wildlife corridors established', @bm, 'Local support grows stronger', 'Research findings encourage continuation')
GO

DECLARE @bn VARCHAR(100)
SET @bn = 'Plains'+CHAR(9)+'bison'+CHAR(10)+'herd expands'
INSERT INTO fts_char_prefix_t values(66, 'Grassland restoration continues', @bn, 'Ecosystem health improves notably', 'Traditional management practices resume', 'Research project documents success')
GO

DECLARE @bo VARCHAR(100)
SET @bo = 'Cliff'+CHAR(10)+'nesting'+CHAR(9)+'birds return'
INSERT INTO fts_char_prefix_t values(67, 'Habitat protection succeeds', 'Conservation efforts continue', @bo, 'Species recovery documented carefully', 'Local community celebrates success')
GO

DECLARE @bp VARCHAR(100)
SET @bp = 'Bay'+CHAR(9)+'water'+CHAR(10)+'quality improves'
INSERT INTO fts_char_prefix_t values(68, 'Marine life thrives again', @bp, 'Pollution levels decrease significantly', 'Ecosystem recovery continues steadily', 'Research findings encourage action')
GO

DECLARE @bq VARCHAR(100)
SET @bq = 'Forest'+CHAR(10)+'stream'+CHAR(9)+'restoration succeeds'
INSERT INTO fts_char_prefix_t values(69, @bq, 'Aquatic life returns quickly', 'Water quality meets standards', 'Habitat connectivity improves notably', 'Monitoring continues regularly')
GO

DECLARE @br VARCHAR(100)
SET @br = 'Dune'+CHAR(9)+'vegetation'+CHAR(10)+'establishes successfully'
INSERT INTO fts_char_prefix_t values(70, 'Coastal protection improves', @br, 'Sand stabilization succeeds', 'Native species thrive naturally', 'Research documents progress')
GO

DECLARE @bs VARCHAR(100)
SET @bs = 'Meadow'+CHAR(10)+'flowers'+CHAR(9)+'bloom abundantly'
INSERT INTO fts_char_prefix_t values(71, @bs, 'Pollinator populations increase', 'Biodiversity improves significantly', 'Research continues successfully', 'Conservation efforts show results')
GO

DECLARE @bt VARCHAR(100)
SET @bt = 'Shore'+CHAR(9)+'bird'+CHAR(10)+'sanctuary expands'
INSERT INTO fts_char_prefix_t values(72, 'Habitat protection improves', @bt, 'Migration patterns stabilize', 'Research project documents success', 'Community support grows stronger')
GO

DECLARE @bu VARCHAR(100)
SET @bu = 'Peak'+CHAR(10)+'snow'+CHAR(9)+'patterns change'
INSERT INTO fts_char_prefix_t values(73, 'Climate research continues', 'Mountain ecosystems adapt', @bu, 'Watershed impact studied carefully', 'Long-term monitoring proceeds')
GO

DECLARE @bv VARCHAR(100)
SET @bv = 'Valley'+CHAR(9)+'fog'+CHAR(10)+'patterns shift'
INSERT INTO fts_char_prefix_t values(74, 'Microclimate changes documented', @bv, 'Plant communities adjust gradually', 'Research findings intrigue scientists', 'Adaptation strategies developed')
GO

DECLARE @bw VARCHAR(100)
SET @bw = 'Island'+CHAR(10)+'species'+CHAR(9)+'recovery succeeds'
INSERT INTO fts_char_prefix_t values(75, @bw, 'Endemic populations stabilize', 'Habitat restoration continues', 'Conservation efforts show promise', 'Research documents progress')
GO

DECLARE @bx VARCHAR(100)
SET @bx = 'Basin'+CHAR(9)+'watershed'+CHAR(10)+'study expands'
INSERT INTO fts_char_prefix_t values(76, 'Water quality improves', @bx, 'Ecosystem health strengthens', 'Research findings guide policy', 'Community engagement increases')
GO

DECLARE @by VARCHAR(100)
SET @by = 'Canyon'+CHAR(10)+'rim'+CHAR(9)+'trail opens'
INSERT INTO fts_char_prefix_t values(77, 'Access improves significantly', 'Conservation measures continue', @by, 'Tourism increases sustainably', 'Local economy benefits notably')
GO

DECLARE @bz VARCHAR(100)
SET @bz = 'Marsh'+CHAR(9)+'restoration'+CHAR(10)+'project succeeds'
INSERT INTO fts_char_prefix_t values(78, 'Wetland health improves', @bz, 'Wildlife returns steadily', 'Water quality meets standards', 'Research continues successfully')
GO

DECLARE @ca VARCHAR(100)
SET @ca = 'Ridge'+CHAR(10)+'habitat'+CHAR(9)+'protection expands'
INSERT INTO fts_char_prefix_t values(79, @ca, 'Species diversity increases', 'Conservation efforts continue', 'Research documents changes', 'Community support strengthens')
GO

DECLARE @cb VARCHAR(100)
SET @cb = 'Delta'+CHAR(9)+'sediment'+CHAR(10)+'patterns shift'
INSERT INTO fts_char_prefix_t values(80, 'River flow changes', @cb, 'Ecosystem adapts gradually', 'Research project expands scope', 'Management strategies updated')
GO

DECLARE @cc VARCHAR(100)
SET @cc = 'Prairie'+CHAR(10)+'grass'+CHAR(9)+'restoration succeeds'
INSERT INTO fts_char_prefix_t values(81, 'Native species return', 'Biodiversity improves significantly', @cc, 'Research documents progress', 'Conservation efforts continue')
GO

DECLARE @cd VARCHAR(100)
SET @cd = 'Forest'+CHAR(9)+'canopy'+CHAR(10)+'study reveals'
INSERT INTO fts_char_prefix_t values(82, 'Tree species interact', @cd, 'Ecosystem dynamics documented', 'Research findings published', 'Conservation strategies updated')
GO

DECLARE @ce VARCHAR(100)
SET @ce = 'Lake'+CHAR(10)+'shore'+CHAR(9)+'habitat improves'
INSERT INTO fts_char_prefix_t values(83, @ce, 'Water quality stabilizes', 'Wildlife returns steadily', 'Research continues successfully', 'Community engagement grows')
GO

DECLARE @cf VARCHAR(100)
SET @cf = 'Stream'+CHAR(9)+'bank'+CHAR(10)+'restoration continues'
INSERT INTO fts_char_prefix_t values(84, 'Erosion control succeeds', @cf, 'Native plants establish well', 'Water quality improves notably', 'Research documents success')
GO

DECLARE @cg VARCHAR(100)
SET @cg = 'Cliff'+CHAR(10)+'face'+CHAR(9)+'study begins'
INSERT INTO fts_char_prefix_t values(85, 'Geological research expands', 'Rock formation documented', @cg, 'Safety measures implemented', 'Scientific understanding advances')
GO

DECLARE @ch VARCHAR(100)
SET @ch = 'Bay'+CHAR(9)+'ecosystem'+CHAR(10)+'health improves'
INSERT INTO fts_char_prefix_t values(86, 'Marine life flourishes', @ch, 'Water quality stabilizes', 'Research continues actively', 'Conservation efforts succeed')
GO

DECLARE @ci VARCHAR(100)
SET @ci = 'Dune'+CHAR(10)+'system'+CHAR(9)+'stabilizes naturally'
INSERT INTO fts_char_prefix_t values(87, @ci, 'Sand movement decreases', 'Native plants establish', 'Research documents changes', 'Coastal protection improves')
GO

DECLARE @cj VARCHAR(100)
SET @cj = 'Summit'+CHAR(9)+'research'+CHAR(10)+'station expands'
INSERT INTO fts_char_prefix_t values(88, 'High altitude studies', @cj, 'Climate data collected', 'Scientific equipment upgraded', 'International collaboration grows')
GO

DECLARE @ck VARCHAR(100)
SET @ck = 'Plains'+CHAR(10)+'wildlife'+CHAR(9)+'corridor opens'
INSERT INTO fts_char_prefix_t values(89, 'Migration routes restored', 'Habitat connectivity improves', @ck, 'Research monitoring continues', 'Conservation success documented')
GO

DECLARE @cl VARCHAR(100)
SET @cl = 'Basin'+CHAR(9)+'flood'+CHAR(10)+'control improves'
INSERT INTO fts_char_prefix_t values(90, 'Water management succeeds', @cl, 'Ecosystem resilience increases', 'Research guides policy', 'Community safety enhanced')
GO

DECLARE @cm VARCHAR(100)
SET @cm = 'Ridge'+CHAR(10)+'line'+CHAR(9)+'study reveals'
INSERT INTO fts_char_prefix_t values(91, 'Geological patterns emerge', 'Mountain formation documented', @cm, 'Research findings published', 'Scientific understanding advances')
GO

DECLARE @cn VARCHAR(100)
SET @cn = 'Valley'+CHAR(9)+'stream'+CHAR(10)+'restoration continues'
INSERT INTO fts_char_prefix_t values(92, 'Water quality improves', @cn, 'Fish populations recover', 'Research documents progress', 'Ecosystem health strengthens')
GO

DECLARE @co VARCHAR(100)
SET @co = 'Shore'+CHAR(10)+'habitat'+CHAR(9)+'protection expands'
INSERT INTO fts_char_prefix_t values(93, @co, 'Coastal species return', 'Conservation efforts succeed', 'Research continues actively', 'Community support grows')
GO

DECLARE @cp VARCHAR(100)
SET @cp = 'Canyon'+CHAR(9)+'echo'+CHAR(10)+'study begins'
INSERT INTO fts_char_prefix_t values(94, 'Acoustic research launches', @cp, 'Sound patterns mapped', 'Scientific equipment installed', 'Data collection proceeds')
GO

DECLARE @cq VARCHAR(100)
SET @cq = 'Peak'+CHAR(10)+'glacier'+CHAR(9)+'monitoring continues'
INSERT INTO fts_char_prefix_t values(95, 'Ice mass measured', 'Climate impact studied', @cq, 'Research findings concern', 'Long-term changes documented')
GO

DECLARE @cr VARCHAR(100)
SET @cr = 'Island'+CHAR(9)+'reef'+CHAR(10)+'health improves'
INSERT INTO fts_char_prefix_t values(96, 'Coral recovery observed', @cr, 'Marine life returns', 'Conservation succeeds gradually', 'Research continues actively')
GO

DECLARE @cs VARCHAR(100)
SET @cs = 'Forest'+CHAR(10)+'canopy'+CHAR(9)+'bridge opens'
INSERT INTO fts_char_prefix_t values(97, @cs, 'Wildlife crossing succeeds', 'Habitat connectivity improves', 'Research documents usage', 'Conservation goals achieved')
GO

DECLARE @ct VARCHAR(100)
SET @ct = 'Lake'+CHAR(9)+'level'+CHAR(10)+'stabilizes naturally'
INSERT INTO fts_char_prefix_t values(98, 'Water balance improves', @ct, 'Ecosystem adapts well', 'Research continues monthly', 'Management plans updated')
GO

DECLARE @cu VARCHAR(100)
SET @cu = 'Marsh'+CHAR(10)+'bird'+CHAR(9)+'sanctuary expands'
INSERT INTO fts_char_prefix_t values(99, 'Wetland protection increases', 'Migration patterns stabilize', @cu, 'Research documents success', 'Conservation efforts continue')
GO

DECLARE @cv VARCHAR(100)
SET @cv = 'Delta'+CHAR(9)+'flow'+CHAR(10)+'patterns shift'
INSERT INTO fts_char_prefix_t values(100, 'River dynamics change', @cv, 'Sediment distribution varies', 'Research project expands', 'Management adapts accordingly')
GO

DECLARE @cw VARCHAR(100)
SET @cw = 'Boreal'+CHAR(10)+CHAR(10)+'forest'
INSERT INTO fts_char_prefix_t values(101, 'River dynamics change', @cw, 'Sediment distribution varies', 'Research project expands', 'Management adapts accordingly')
GO

DECLARE @cx VARCHAR(100)
SET @cx = 'Boreal'+CHAR(10)+CHAR(10)+CHAR(10)+'forest'
INSERT INTO fts_char_prefix_t values(102, 'River dynamics change', @cx, 'Sediment distribution varies', 'Research project expands', 'Management adapts accordingly')
GO

-- Create a unique index
CREATE UNIQUE INDEX uid ON fts_char_prefix_t(id)
GO

-- Create a full-text index
CREATE FULLTEXT INDEX ON fts_char_prefix_t(
        main_story,
        industry_update,
        local_news,
        tech_highlight,
        community_event) KEY INDEX uid
GO

CREATE VIEW fts_char_prefix_t_v1 AS (SELECT * FROM fts_char_prefix_t)
GO

CREATE VIEW fts_char_prefix_t_v2 AS (SELECT * FROM fts_char_prefix_t WHERE CONTAINS((main_story, industry_update, local_news), '"deforest*"'))
GO

CREATE PROCEDURE fts_char_prefix_t_p1 AS (SELECT * FROM fts_char_prefix_t WHERE CONTAINS((main_story,
                                                                                                  industry_update,
                                                                                                  local_news,
                                                                                                  tech_highlight,
                                                                                                  community_event), ' "coast  *" '))
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO