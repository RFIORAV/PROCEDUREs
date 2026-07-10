/*
rf 10.08.2024
[jueves 20:43] Paulo Horna
Serían estos
Nombre de la Configuración	appLandingPage
EuroAffiliati	      https://www.bonuswelcome.com/
AffiliateRevolution	https://comparatore.affiliaterevolution.network/
MiTipster	         https://www.bonuswelcome.com/
Deally	            https://www.comparatore-deally.eu/
GamingAffiliation 	https://comparabonus-ga.com/
BrasiliaConnect	   https://www.bonuswelcome.com/
TipsterUtility	      https://www.bonuswelcome.com/
AffiliateAccess	   https://www.bonuswelcome.com/
MyMonsterAffiliates	https://www.playnow.games/
XyzNet	            https://www.bonuswelcome.com/
FreedomLegacy	      https://www.bonuswelcome.com/
 
[jueves 20:45] Paulo Horna
Aunque realmente las únicas activas ahora serían:

Marca	               appLandingPage
EuroAffiliati	      https://www.bonuswelcome.com/
AffiliateRevolution	https://comparatore.affiliaterevolution.network/
Betmedia	            https://www.bonuswelcome.com/
Deally	            https://www.comparatore-deally.eu/
BrasiliaConnect	   https://www.bonuswelcome.com/
AffiliateAccess	   https://www.bonuswelcome.com/
*/
 
use affiliateaccess       ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use affiliaterevolution   ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://comparatore.affiliaterevolution.network/', NULL, NULL, now(), now(), 'SysOp');
use betmedia              ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use deally                ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.comparatore-deally.eu/', NULL, NULL, now(), now(), 'SysOp');
use brasiliacon           ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use brasiliacon_dev       ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use euroaffiliati2        ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use euroaffiliati_dev     ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use freedom_legacy        ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use gamingaffiliation     ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://comparabonus-ga.com/', NULL, NULL, now(), now(), 'SysOp');
use marca_blanca          ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');
use mymonsteraffiliates   ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.playnow.games/', NULL, NULL, now(), now(), 'SysOp');
use xyznet                ;
REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`, `Value_02`, `Value_03`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Comparator', 'https://www.bonuswelcome.com/', NULL, NULL, now(), now(), 'SysOp');

 