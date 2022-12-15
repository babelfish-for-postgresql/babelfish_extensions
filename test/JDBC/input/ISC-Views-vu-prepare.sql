create table var(a char(10), b nchar(9), c nvarchar(8), d varchar(7), e text, f ntext, g varbinary(10), h binary(9), i image, j xml)
go

create table dates(a date, b time(5), c datetime, d datetime2(5), e smalldatetime, f sql_variant)
go

create table nums(a int, b smallint, c tinyint, d bigint, e bit, f float, g real, h numeric(5,3), i money, j smallmoney)
go

create schema [CUSTOM\schema];
go

create table [CUSTOM\schema].[CUSTOM.[CustomTable](a varchar(10));
go

create type int_a from int
create type varchar_a from varchar(10)
go

create table isc_udt_1(a int_a, b varchar_a)
go

create database isc_db
go

-- Testing information_schema.views
create view vnums as select * from nums;
go

create view vcnums as select * from nums with check option;
go

-- create view with definition length more than 4000 char
create view lview as select 'provvwstdjtlyzygsxcnqlkyukpjlseachjalbtttvujvdnhooy
ursfkalzuixjyhogeijfpyidmrjciefitzurwxrazaqbmpljryfhmraftlwmktxqzsrhnbfgftqdxpxs
acoeyzmmrfptpuorfbsyaiumgwumeejdpgfkhekumxqqzplnpojlzwpeoznospniqdyfmgyifgrqjpia
pjszcykssdgfnzjsgsbzjfcebtlxytwtczrufccrpcufzitbvpgdhyishwlkatimhxkzvsgqxdrqdiie
glnizryhllxlqhfnxeyjofmopglwczssmrocmkqdstpmldifjwvdzwebyruaxlcaxqyiljfmmmohealr
zerdjymvoetanchzpfpfxtnkenlsxolaoibfdqkhvwpvcvnovvzmgmjbxowimunqmqqlrvvdhlvdvoku
vwbdurvxzonhmdnqxejtwraxtkmtzsvgawpsvtscmcnevslmantvrvbcaeotvhqbfukdadxxiwvumrya
asyerhdnexyztbjdlpourvdnfmkxysjysksivurxowjjsizcxyhrkciwhutpnxxqknjgkuvbmxywpbdl
eydsfyahzhhjzmadkjizjvnqweqdztdepjnaowwhqdixrwhkqnhpeyujpbczsimjfxtdfmtlqvlkxpmh
gcpgnvqiwgxigliotyfyfdumuxrrxpyaepflxwvnxrneyladslmmkrvapylaezrczkykiwtgiuxjgbkg
pshlptwxzmefdjqpbjaxszrqkcujxhkdksbbskiuazijfoivmskwqtbnglqedoknyofvvjiyowjsunsw
yukjypmejicaivpxslbrfsmbostwmdoypilvjsqucymywzqbzyicyyjsqslnqfbqegoejxivmrffvpum
hjouhgvzfgyajrhjilxcckznwbmpehsmztlwuvthgqtghlghdydgoxxatxmtwrwnelmpolxytoibraal
dzbdndccayqsqwqumcifenspaxztpqaxdcotbgsrnlriwkkvzgdextdivauvzpipgaodgsoqnutzklki
ebpbmygeguartyqxascsaepwwdrdxdxbfgzjypmwisibntyckagqpseqoqbrzgxtpxbtwsxogyvszsoc
vurmfyhyvrzwwsoiglyoyuwbimbdfuuxjkhubgvrfodfbmsafvuzbhqavujwifvlpswykpgcjvywpvuw
qcqmqtjwsezttpjqcbghrhprxmplsqafbomdipbyhdsendkokartnklgggprtjdoegrjrmvaudgahzfm
eljseivxkflgkfatfgogmcnbgsnyhvzstelyxfzcufotrjjodijlkdusbrcnkubbfgjtgbzymwgwbfpa
xdhrchgnipfomyyiikhbconzphustwlpbkgvcpctczctgmzohcjfcccbjycehksregjffvfoymcbrsxg
jqfjnfjfhvskohydaoxjpiunoflvwwgtjdilntlxruztsfizglsxzihqtvznczxvpbygqpaxxoienkgy
dytnfzmtzdhtakoikhneaapanhbcshvdxganertfbjtmbaioxiacmfguopzdaswgvzvzwyimbvkjivhd
deyaijgjcezpyprnuhzrrefrnxsbcsodhpawjepsngcbyftltqvmdlmoifeffzarkkabglekkxnanpue
ylybjllbkjwpplxqyympjnsyitqpubftpeiacohxrogjkdcpqepcwebvsqsuenkprjrkvakazbneqwfr
khaiuuekrhdvdmdeftofrnihzrsnbalqjlzzxuhcmluhbqhsnnnrwywyzhyrimnojsynssscxdmmpyqo
yqqerfvjwbpzcrvjqksampppyffoktbvnlejekvhivdgrbhnfbxekanpylutuwvvayysnrqajxvcsjaq
wgzbnsljgzhapkkorsfwyiftfrhllcjwkzpbphiliiwnpsfiofiwioniousqmyfabldkogeahufsorgc
daulusynkcowzkgzwnclzycxmtxtiqmkxebrwpiwnvvxxmitrclpmfsslwboswpnyjncpyfllllhbzau
hrztubiriulxedzqduzvygomolxssbbvyrevgiirzkjchteyimchgqfzdzwbubdcptwamyegsncyhxng
qyhlnninraksjbfwthlgsehhukjqfspnttatpqnwryohzhfldfhfxmvgnxbzerwnmmceaokxgongbxlg
twwwlyuwejrhvbnnsqalbsnzmaorwrdrfyjklkcyxxzatfzajwkoryfalpirewqmwvtxttuvsyftuvil
nnmjagxhajnspfiywchskgvairrexlrayyrkbwsgxxaoxcjuslgnwrotofwvyqbdrvfgdsjuslsfwrvg
soghflwjyivumqiauuqktdsgeecqktsfqcgpnpqypoevoeuxtliqcvrioednzxsygdklfufcdqkkfiys
biqdbrlsgiznbxdpjbkeqhawyuzwkfxgmykmqrqyuwnzcbmpthnuknmkgrnlzcfutcnvthoejiiinmug
idsyogvcsiwfwvdzauwenxonrdudwfsmocsfhqdanzrdyiafnztshpwaivbxnihtaornxujdjgdrirfo
ghvaniejkboptmxjzsmmbmxzirnsvejpdmjrgknbqhovuioofmyyaylrscvhyilbihpcimebumipsefb
cpkbboajblaemlgbdhziuoewdahiyomgdvyijtdqwvgrpmrntyfdsrlyvqxrqlrepyjnswysanekarpz
koeonordbcueojxcsdawbwbpyxhnikfgodsgqnawwbjfynaorgkaltsiciptjeadqijiawcvvcdjxwfm
ftgsqthdjkwletsknosrflsexbumdhrptkzkckfvlxaooansrylwdgazzoofvwaoifwogthkrthrywfd
azakaeqemgtepmpjpimcqrcqwqozgmymbavbziztmdeothaxljdvvjxldjczjwtouedwzewwwnbugjou
htytwbjosbvbhwhgjzmvunvhuftajlzxtedauvudznbdznfdsegoiwaewshchsuprvbgcyxuvvphmync
fucszaioeqbtrdhpatnwinbenkxsfchuagcqpkepkktcujnazepbcujcjoopsyidlggxhyerkgqhxozu
xlexrjexjkeocvhbsgefwrxtcvrunsdsqkivgfbveuwbkdpuqykckjjzkyiurviccyhkigqgwauqfudx
hfqehcsidgrdeqveqicqnlubecuhihchrgscrmtvromvklfmcgckvdlljqybumgzqdtirizlithvtjgh
xsvdpwhqhmlntqpugtslhtebznfkbvuihtrgwymxbfamykqqjnaosueenotsnmvwpwzbzjkdspesibon
iokannleitpjuvqxteiioozzymvmnohcksmqtigmeamguheqbiesnxuwhfrobdveiwqykxcfxfgiojmd
hdoyhwwcdietkrtwclibdwftbafyioskcmzdozabrvzofsoanzpmolpyhsnyquihpzdquksylxbpbyog
zdlrfazfvefoyavralxogzicjoxgmsjqcznyiuwaizwpwfxdtlhxiyadgurhwmnjdliymurukkxugdtp
zsyqtrxrcmxihounkkrqpnirputcjynozfopvrjymupchfjcbgebiwhbejmsrhlonbjxadmxekwwmbsf
cgikmgfvzwyrbunlxcwmihykwywozqdyfdvjjpiammriimvcxemadanokpgmcspgohxonrdaylklymiu
gkqfabhrgyfcjaylrehyzwwddvhmcfhikodhoifqfffvuaoqfwvrjmdcmxrifwgvuwzyipiraayhxdfb
zyefbktrlulbapwfjbhypdvumdpxv';
go

-- create view with definition length equal to 4000 char
create view nlview as select 'prtdjtlyzygsxcnqlkyukpjlseachjalbtttvujvdnhooy
ursfkalzuixjyhogeijfpyidmrjciefizurwxrazaqbmpljryfhmraftlwmktxqzsrhnbfgftqdxpxs
acoeyzmmrfptpuorfbsyaiumgwumeejdgfkhekumxqqzplnpojlzwpeoznospniqdyfmgyifgrqjpia
pjszcykssdgfnzjsgsbzjfcebtlxytwtzrufccrpcufzitbvpgdhyishwlkatimhxkzvsgqxdrqdiie
glnizryhllxlqhfnxeyjofmopglwczssrocmkqdstpmldifjwvdzwebyruaxlcaxqyiljfmmmohealr
zerdjymvoetanchzpfpfxtnkenlsxolaibfdqkhvwpvcvnovvzmgmjbxowimunqmqqlrvvdhlvdvoku
vwbdurvxzonhmdnqxejtwraxtkmtzsvgawpsvtscmcnevslmantvrvbcaeotvhqbfukdadxxiwvumrya
asyerhdnexyztbjdlpourvdnfmkxysjysksivurxowjjsizcxyhrkciwhutpnxxqknjgkuvbmxywpbdl
eydsfyahzhhjzmadkjizjvnqweqdztdepjnaowwhqdixrwhkqnhpeyujpbczsimjfxtdfmtlqvlkxpmh
gcpgnvqiwgxigliotyfyfdumuxrrxpyaepflxwvnxrneyladslmmkrvapylaezrczkykiwtgiuxjgbkg
pshlptwxzmefdjqpbjaxszrqkcujxhkdksbbskiuazijfoivmskwqtbnglqedoknyofvvjiyowjsunsw
yukjypmejicaivpxslbrfsmbostwmdoypilvjsqucymywzqbzyicyyjsqslnqfbqegoejxivmrffvpum
hjouhgvzfgyajrhjilxcckznwbmpehsmztlwuvthgqtghlghdydgoxxatxmtwrwnelmpolxytoibraal
dzbdndccayqsqwqumcifenspaxztpqaxdcotbgsrnlriwkkvzgdextdivauvzpipgaodgsoqnutzklki
ebpbmygeguartyqxascsaepwwdrdxdxbfgzjypmwisibntyckagqpseqoqbrzgxtpxbtwsxogyvszsoc
vurmfyhyvrzwwsoiglyoyuwbimbdfuuxjkhubgvrfodfbmsafvuzbhqavujwifvlpswykpgcjvywpvuw
qcqmqtjwsezttpjqcbghrhprxmplsqafbomdipbyhdsendkokartnklgggprtjdoegrjrmvaudgahzfm
eljseivxkflgkfatfgogmcnbgsnyhvzstelyxfzcufotrjjodijlkdusbrcnkubbfgjtgbzymwgwbfpa
xdhrchgnipfomyyiikhbconzphustwlpbkgvcpctczctgmzohcjfcccbjycehksregjffvfoymcbrsxg
jqfjnfjfhvskohydaoxjpiunoflvwwgtjdilntlxruztsfizglsxzihqtvznczxvpbygqpaxxoienkgy
dytnfzmtzdhtakoikhneaapanhbcshvdxganertfbjtmbaioxiacmfguopzdaswgvzvzwyimbvkjivhd
deyaijgjcezpyprnuhzrrefrnxsbcsodhpawjepsngcbyftltqvmdlmoifeffzarkkabglekkxnanpue
ylybjllbkjwpplxqyympjnsyitqpubftpeiacohxrogjkdcpqepcwebvsqsuenkprjrkvakazbneqwfr
khaiuuekrhdvdmdeftofrnihzrsnbalqjlzzxuhcmluhbqhsnnnrwywyzhyrimnojsynssscxdmmpyqo
yqqerfvjwbpzcrvjqksampppyffoktbvnlejekvhivdgrbhnfbxekanpylutuwvvayysnrqajxvcsjaq
wgzbnsljgzhapkkorsfwyiftfrhllcjwkzpbphiliiwnpsfiofiwioniousqmyfabldkogeahufsorgc
daulusynkcowzkgzwnclzycxmtxtiqmkxebrwpiwnvvxxmitrclpmfsslwboswpnyjncpyfllllhbzau
hrztubiriulxedzqduzvygomolxssbbvyrevgiirzkjchteyimchgqfzdzwbubdcptwamyegsncyhxng
qyhlnninraksjbfwthlgsehhukjqfspnttatpqnwryohzhfldfhfxmvgnxbzerwnmmceaokxgongbxlg
twwwlyuwejrhvbnnsqalbsnzmaorwrdrfyjklkcyxxzatfzajwkoryfalpirewqmwvtxttuvsyftuvil
nnmjagxhajnspfiywchskgvairrexlrayyrkbwsgxxaoxcjuslgnwrotofwvyqbdrvfgdsjuslsfwrvg
soghflwjyivumqiauuqktdsgeecqktsfqcgpnpqypoevoeuxtliqcvrioednzxsygdklfufcdqkkfiys
biqdbrlsgiznbxdpjbkeqhawyuzwkfxgmykmqrqyuwnzcbmpthnuknmkgrnlzcfutcnvthoejiiinmug
idsyogvcsiwfwvdzauwenxonrdudwfsmocsfhqdanzrdyiafnztshpwaivbxnihtaornxujdjgdrirfo
ghvaniejkboptmxjzsmmbmxzirnsvejpdmjrgknbqhovuioofmyyaylrscvhyilbihpcimebumipsefb
cpkbboajblaemlgbdhziuoewdahiyomgdvyijtdqwvgrpmrntyfdsrlyvqxrqlrepyjnswysanekarpz
koeonordbcueojxcsdawbwbpyxhnikfgodsgqnawwbjfynaorgkaltsiciptjeadqijiawcvvcdjxwfm
ftgsqthdjkwletsknosrflsexbumdhrptkzkckfvlxaooansrylwdgazzoofvwaoifwogthkrthrywfd
azakaeqemgtepmpjpimcqrcqwqozgmymbavbziztmdeothaxljdvvjxldjczjwtouedwzewwwnbugjou
htytwbjosbvbhwhgjzmvunvhuftajlzxtedauvudznbdznfdsegoiwaewshchsuprvbgcyxuvvphmync
fucszaioeqbtrdhpatnwinbenkxsfchuagcqpkepkktcujnazepbcujcjoopsyidlggxhyerkgqhxozu
xlexrjexjkeocvhbsgefwrxtcvrunsdsqkivgfbveuwbkdpuqykckjjzkyiurviccyhkigqgwauqfudx
hfqehcsidgrdeqveqicqnlubecuhihchrgscrmtvromvklfmcgckvdlljqybumgzqdtirizlithvtjgh
xsvdpwhqhmlntqpugtslhtebznfkbvuihtrgwymxbfamykqqjnaosueenotsnmvwpwzbzjkdspesibon
iokannleitpjuvqxteiioozzymvmnohcksmqtigmeamguheqbiesnxuwhfrobdveiwqykxcfxfgiojmd
hdoyhwwcdietkrtwclibdwftbafyioskcmzdozabrvzofsoanzpmolpyhsnyquihpzdquksylxbpbyog
zdlrfazfvefoyavralxogzicjoxgmsjqcznyiuwaizwpwfxdtlhxiyadgurhwmnjdliymurukkxugdtp
zsyqtrxrcmxihounkkrqpnirputcjynozfopvrjymupchfjcbgebiwhbejmsrhlonbjxadmxekwwmbsf
cgikmgfvzwyrbunlxcwmihykwywozqdyfdvjjpiammriimvcxemadanokpgmcspgohxonrdaylklymiu
asdfghjklqwertyuiopasdfghjklasdfghjklz';
go

create schema sch1;
go

create view sch1.v1 as select 1;
go

create type numeric_test from numeric(15,6)
go

create type decimal_test from decimal(15,6)
go

create table babel_2863(_numcol_bbf_13d0 decimal(13), _numcol_bbf_13n0 numeric(13), _numcol_bbf_15d6 decimal(15,6), _numcol_bbf_15n6 numeric(15,6), _numcol_numeric_test numeric_test, _numcol_decimal_test decimal_test)
go
