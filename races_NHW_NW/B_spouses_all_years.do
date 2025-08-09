clear all
set more off

global root "C:\Users\user\OneDrive - Alma Mater Studiorum Università di Bologna\Desktop\LMEC-2nd_year\3rd_period\research_methods\thesis\my_analysis"
global code	"${root}/Code"
do "${code}\my_globals.do"


use "$output_A_all_years", clear

* note: in this dataset there might be heads that do not have a spouse.
//      If I reshape the dataset to wide format, do i automatically drop those
//      heads that do not have a spouse? NO

ds serial relate year, not // selects all variables except serial and relate

local varlist `r(varlist)' // stores those variables in a local

reshape wide `varlist', i(serial year) j(relate) 

sort year serial

/*wide format: a household is obserevd repeatedly through its head and spouse 
(if latter available). If a spouse is not available, the spouse columns are left 
blank. 1 stands for head 2 stands for spouse.
*/

drop if qage1 ~= 0 | qage2 ~= 0  /* drop observations with allocated age for head 
                                    or spouse */

drop if qyrimm1 ~= 0 | qyrimm2 ~= 0 /* drop observations with allocated year of 
                                       immigration for head or spouse */

drop if qbpl1 ~= 0 | qbpl2 ~= 0 /* drop observations with allocated birthplace 
                                   for head or spouse */

/* there are no more heads w/o a spouse. This is because those rows
have "." in qvar2 and thus get dropped
*/

gen age_at_arrival1 = yrimmig1 - birthyr1 //age at arrival of head

gen age_at_arrival2 = yrimmig2 - birthyr2 //age at arrival of spouse

keep if (age_at_arrival1 >= 0 & age_at_arrival1 < 15) | (age_at_arrival2 >= 0 ///
& age_at_arrival2 < 15) 

/* keep only hhs in which at least one between the head and the spouse is a 
childhood immigrant (i.e., arrived in US between 0 and 14). This allows to keep 
couples where both immigrated before 15, couples where one immigrated before 15 
and the other after 15, and couples where one immigrated before 15 and the other 
is a native 
*/

replace age_at_arrival1 = . if age_at_arrival1 < 0 

replace age_at_arrival2 = . if age_at_arrival2 < 0

/* natives have yrimmig == 0, and hence age at arrival < 0. Replace negative 
values with . 
*/

gen partner_of_ch_immig1 = 1 if (age_at_arrival2 <15) /* dummy for
whether head is married to a childhood immigrant */

gen partner_of_ch_immig2 = 1 if (age_at_arrival1 <15) /* dummy for
whether spouse is married to a childhood immigrant */

replace partner_of_ch_immig1 = 0 if partner_of_ch_immig1 == .

replace partner_of_ch_immig2 = 0 if partner_of_ch_immig2 == .

local stubs sample cbserial numprec subsamp hhwt hhtype cluster adjust cpi99 region ///
stateicp statefip countyicp countyfip puma density metro pctmetro met2023 met2023err ///
metpop10 city cityerr citypop homeland strata gq gqtype gqtyped ownershp ownershpd ///
hhincome lingisol cinethh cilaptop cismrtphn citablet ciothcomp cidatapln cihispeed ///
cisat cidial ciothsvc vehicles coupletype ssmc nfams ncouples nmothers nfathers multgen ///
multgend qownersh qcidial qcilaptop qcinethh qciothcomp qciothsvc qcisat qcismrtphn ///
qcitablet qcidatapln qcihispeed qvehicle respmode qhhincome pernum perwt slwt famunit ///
famsize momloc stepmom momrule poploc steppop poprule sploc sprule nchild nchlt5 nsibs ///
eldch yngch related sex age marst birthyr marrno marrinyr yrmarr divinyr widinyr fertyr ///
race raced hispan hispand bpl bpld ancestr1 ancestr1d ancestr2 ancestr2d citizen ///
yrnatur yrimmig yrsusa1 yrsusa2 language languaged speakeng tribe tribed racamind ///
racasian racblk racpacis racwht racother racnum hcovany school educ educd gradeatt ///
gradeattd schltype empstat empstatd labforce classwkr classwkrd occ occ1950 occ1990 ///
occ2010 occsoc ind indnaics wkswork1 wkswork2 uhrswork wrklstwk absent looking availble ///
wrkrecal workedyr inctot ftotinc incwage incbus00 incss incwelfr incinvst incretir ///
incsupp incother incearn poverty occscore sei migrate1 migrate1d migplac1 migcounty1 ///
migpuma1 migmet131 migmet13err migpumanow movedin vetdisab diffrem diffphys diffmob ///
diffcare diffsens diffeye diffhear vetstat vetstatd vet01ltr vet90x01 vet75x90 vetvietn ///
vet55x64 vetkorea vetwwii vetother vetotherd pwstate2 pwcounty pwmet13 pwmet13err ///
pwpuma00 tranwork carpool riders trantime departs arrives gchouse gcmonths gcrespon ///
qage qfertyr qmarrno qmarst qrelate qsex qmarinyr qyrmarr qwidinyr qdivinyr qbpl qcitizen ///
qhispan qlanguag qrace qspeaken qyrimm qyrnatur qhinsemp qhinspur qhinstri qhinscai ///
qhinscar qhinsva qhinsihs qeduc qgradeat qschool qclasswk qempstat qind qocc quhrswor ///
qwkswork1 qwkswork2 qworkedy qincearn qincbus qincinvs qincothe qincreti qincss qincsupp ///
qinctot qftotinc qincwage qincwelf qmigplc1 qmovedin qdifsens qdifphys qdifrem qdifmob ///
qdifcare qdifeye qdifhear qvetdisb qvetper qvetstat qcarpool qdeparts qpwstat2 qriders ///
qtrantim qtranwor qgchouse qgcmonth qgcrespo partner_of_ch_immig age_at_arrival

reshape long `stubs', i(serial year) j(relate) // reshape to a long format                                     

sort year serial

gen child_immig = (age_at_arrival < 15 & age_at_arrival ~= .)

compress

save "$data_clean_spouses/output_B_long_all_years.dta", replace

********************************************************************************
/* Generate dataset of childhood immigrants */ 
********************************************************************************

use "$output_B_long_all_years", clear

keep if child_immig == 1 /* if a hh appers twice, then both head and spouse are 
                            childhood immigrants */

/* Generate a dummy for english-speaking countries of birth. These are countries 
where English is an official language (accoridng to World Almanac 1999).

This part is a copy and paste of the authors' code. However, I may need to check
that the classification below is still valid
*/ 

* Anguilla
gen engoff = bpld == 26041, 
label variable engoff "dummy =1 if country has English as an official language"

* Antarctica
replace engoff = 1 if bpl == 800

* Antigua and Barbuda 
replace engoff = 1 if bpld == 26042

* Australia and New Zealand
replace engoff = 1 if bpl == 700

* Bahamas
replace engoff = 1 if bpld == 26043

* Barbados
replace engoff = 1 if bpld == 26044

* Belize
replace engoff = 1 if bpld == 21010

* Bermuda
replace engoff = 1 if bpld == 16010

* Botswana
replace engoff = 1 if bpld == 60091

* British Indian Ocean Terr.
replace engoff = 1 if bpld == 60040

* British Virgin Islands
replace engoff = 1 if bpld == 26045

* British Virgin Islands, not specified
replace engoff = 1 if bpld == 26052

* British West Indies, not specified
replace engoff = 1 if bpld == 26069

* Canada (excluding French Canada)
replace engoff = 1 if bpld >= 15000 & bpld <= 15070

* Cayman Islands
replace engoff = 1 if bpld == 26053

* Channel Islands
* included in Ireland and UK (41010)

* Ciskei
* MISSING IN CENSUS CODES

* Dominica
replace engoff = 1 if bpld == 26054

* Falkland Islands (Islas Malvinas)
replace engoff = 1 if bpld == 16030

* Fiji
replace engoff = 1 if bpld == 71021

* Gambia
replace engoff = 1 if bpld == 60022

* Ghana
replace engoff = 1 if bpld == 60023

* Gibraltar
replace engoff = 1 if bpl == 432

* Grenada
replace engoff = 1 if bpld == 26055

* Guam
replace engoff = 1 if bpl == 105

* Guyana
replace engoff = 1 if bpld == 30040

* Hong Kong
replace engoff = 1 if bpld == 50010

* India
replace engoff = 1 if bpld == 52100

* Ireland and UK
replace engoff = 1 if (bpl> = 410 & bpl <= 414)

* Jamaica
replace engoff = 1 if bpld == 26030

* Kenya
replace engoff = 1 if bpld == 60045

* Kiribati
replace engoff = 1 if bpld == 71032

* Lesotho
replace engoff = 1 if bpld == 60092

* Liberia
replace engoff = 1 if bpld == 60027

* Malawi
replace engoff = 1 if bpld == 60047

* Malta
replace engoff = 1 if bpl == 435

* Marshall Islands
replace engoff = 1 if bpld == 71041

* Mauritius
replace engoff = 1 if bpld == 60048

* Micronesia
replace engoff = 1 if bpld == 71042

* Namibia
replace engoff = 1 if bpld == 60093

* Nauru
replace engoff = 1 if bpld == 71034

* Nigeria
replace engoff = 1 if bpld == 60031

* Pakistan
replace engoff = 1 if bpld == 52140

* Palau
replace engoff = 1 if bpld == 71048

* Papua New Guinea
replace engoff = 1 if bpld == 71012

* Philippines
replace engoff = 1 if bpl == 515

* Rhodesia
* MISSING IN CENSUS CODES

* Samoa
replace engoff = 1 if bpl == 100

* Senegal
replace engoff = 1 if bpld == 60032

* Seychelles
replace engoff = 1 if bpld == 60052

* Sierra Leone
replace engoff = 1 if bpld == 60033

* Singapore
replace engoff = 1 if bpl == 516

* Solomon Islands
replace engoff = 1 if bpld == 71013

* South Africa
replace engoff = 1 if bpld == 60094

* St. Christopher
* MISSING IN CENSUS CODES

* St. Kitts and Nevis
replace engoff = 1 if bpld == 26057

* St. Lucia
replace engoff = 1 if bpld == 26058

* St. Vincent & the Grenadines
replace engoff = 1 if bpld == 26059

* Swaziland
replace engoff = 1 if bpld == 60095

* Tanzania
replace engoff = 1 if bpld == 60054

* Tonga
replace engoff = 1 if bpld == 71023

* Transkei
* MISSING IN CENSUS CODES

* Trinidad & Tobago
replace engoff = 1 if bpld == 26060

* Tuvalu
replace engoff = 1 if bpld == 71038

* Uganda
replace engoff = 1 if bpld == 60055

* U.S. outlying areas, possessions and territories, not specified
replace engoff = 1 if (bpld == 12090 | bpld == 12091 | bpld == 12092)

* U.S. Virgin Islands
replace engoff = 1 if bpl == 115

* Vanuatu
replace engoff = 1 if bpld == 71014

* Vatican City
replace engoff = 1 if bpl == 439

* Venda
* MISSING IN CENSUS CODES

* Zambia
replace engoff = 1 if bpld == 60056

* Zimbabwe
replace engoff = 1 if bpld == 60057

/* Generate a dummy for countries with English as dominant language (among the 
countries with it as an official language).

To establish domiannce of the english language in a given country, the authors 
use adult immigrants from the 1980 IPUMS data. Namely, they classify as 
countries where English is a dominant language only those in which more than 
half the adult immigrants do not speak a language other than ENglish at home.
*/ 

* Anguilla
gen engdom = bpld == 26041, 
label variable engdom "dummy =1 if country has English as a dominant language"

* Antarctica
replace engdom = 1 if bpl == 800

* Antigua and Barbuda
replace engdom = 1 if bpld == 26042

* Australia and New Zealand
replace engdom = 1 if bpl == 700

* Bahamas
replace engdom = 1 if bpld == 26043

* Barbados
replace engdom = 1 if bpld == 26044

* Belize
replace engdom = 1 if bpld == 21010

* Bermuda
replace engdom = 1 if bpld == 16010

* British Indian Ocean Terr.
replace engdom = 1 if bpld == 60040

* British Virgin Islands
replace engdom = 1 if bpld == 26045

* British Virgin Islands, not specified
replace engdom = 1 if bpld == 26052

* British West Indies, not specified
replace engdom = 1 if bpld == 26069

* Canada (excluding French Canada)
replace engdom = 1 if bpld >= 15000 & bpld <= 15070

* Cayman Islands
replace engdom = 1 if bpld == 26053

* Grenada
replace engdom = 1 if bpld == 26055

* Guyana
replace engdom = 1 if bpld == 30040

* Jamaica
replace engdom = 1 if bpld == 26030

* Ireland and UK
replace engdom = 1 if (bpl> = 410 & bpl <= 414)

* Liberia
replace engdom = 1 if bpld == 60027

* South Africa
replace engdom = 1 if bpld == 60094

* St. Kitts and Nevis
replace engdom = 1 if bpld == 26057

* St. Lucia
replace engdom = 1 if bpld == 26058

* St. Vincent & the Grenadines
replace engdom = 1 if bpld == 26059

* Trinidad & Tobago
replace engdom = 1 if bpld == 26060

* U.S. Virgin Islands
replace engdom = 1 if bpl == 115

* Zimbabwe
replace engdom = 1 if bpld == 60057

/* drop countries that  have English as an official, but not dominant, language */

drop if engoff == 1 & engdom == 0

generate byte nengdom = 1 - engdom, after (engdom)

lab var nengdom "dummy for non-English-speaking country"

drop engoff

// reminder: check for shares of engom and nengdom
summarize engdom 
scalar mean_engdom = r(mean) // ~ 10%

summarize nengdom 
scalar mean_nengdom = r(mean) // ~ 90%

scalar drop mean_engdom mean_nengdom

/* Code the following control variables (TO REVIEW)
- age
- sex
- race
- hispanic origin
*/ 

* age: already present

* sex
gen female = sex == 2
label var female "female dummy"

* race (general)
gen white = race == 1
gen black = race == 2
gen asianpi = (race == 4 | race == 5 | race == 6)
gen other   = (race == 7|race == 3)
gen multi	= (race == 8 | race == 9)

label var white "race: white"
label var black "race: black"
label var asianpi "race: asian (Chinese, Japanese), pacific islander"
label var other "race: other (American  Indian or Alaska Native, Other race)"
label var multi "race: multiracial (two major races, three or more major races )"

* hispanic origin
gen hispdum = hispand ~= 0
label var hispdum "hispanic dummy"

* categories to investigate heterogeneity by ethnicity
/*gen race_eth = .
replace race_eth = 1 if white == 1 & hispdum == 0
replace race_eth = 2 if black == 1 & hispdum == 0
replace race_eth = 3 if hispdum == 1
replace race_eth = 4 if race_eth == . & hispdum == 0

label define raceeth_lbl ///
    1 "Non-Hispanic White" ///
    2 "Non-Hispanic Black" ///
    3 "Hispanic (any race)" ///
    4 "Other Non-Hispanic"

label values race_eth raceeth_lbl
label var race_eth "Ethnicity Category"
*/

gen race_eth = .
replace race_eth = 1 if white == 1 & hispdum == 0
replace race_eth = 2 if race_eth == .

label define raceeth_lbl ///
    1 "Non-Hispanic White" ///
    2 "Non-White"

label values race_eth raceeth_lbl
label var race_eth "Race Category"

/* Code the following outcome variables in the fields of
- education
- labour market
- english proficiency
- marital status
- hispanic origin

those marked with "- //" are coded differently wrt Bleakley and Chin's
(TO REVIEW)
*/ 

* years of schooling (starting from elementary school) - // (to revise)
gen yrssch = 0
replace yrssch = 1 if educd == 14
replace yrssch = 2 if educd == 15
replace yrssch = 3 if educd == 16
replace yrssch = 4 if educd == 17
replace yrssch = 5 if educd == 22
replace yrssch = 6 if educd == 23
replace yrssch = 7 if educd == 25
replace yrssch = 8 if educd == 26
replace yrssch = 9 if educd == 30
replace yrssch = 10 if educd == 40
replace yrssch = 11 if (educd == 50 | educd == 61)
replace yrssch = 12 if (educd == 63 | educd == 64)
replace yrssch = 14 if (educd == 71 | educd == 81)
replace yrssch = 16 if educd == 101
replace yrssch = 19 if (educd == 114 | educd == 115) 
// I tried to follow B and C as much as possible. But how can it be that master 
// degree = 19 yrssch and phd = 20 yrssch? I coudld put 19 + 5 = 24 for a phd (instesd of 20), since in
// the US a phd takes 4 to 6 years to complete
replace yrssch = 20 if educd == 116
replace yrssch = . if qeduc ~= 0

//gen hsdipl   = educ99 >= 10 if qeduc == 0
//gen somecoll = educ99 >  10 if qeduc == 0
//gen colldipl = educ99 >= 14 if qeduc == 0

label variable yrssch "years of schooling"
//label var hsdipl "high school grad"
//label var somecoll "has some college"
//label var colldipl "college grad"

* LABOR MARKET OUTCOMES

* wage and salary income last year

gen wagely = incwage if incwage > 0 & incwage ~= 999999 & qincwage == 0
gen lnwagely = ln(wagely)

label var wagely "wage last year conditional on pos earnings"
label var lnwagely "ln(wagely)"

* worked last year
gen workedly = workedyr == 3 if workedyr ~= 0 & qworkedy == 0
label var workedly "worked last year"

* speaks English
gen engspkvw = (speakeng == 3 | speakeng == 4)
* if qspeaken == 0

gen engspkw  = engspkvw
* replace engspkw = 1 if speakeng == 5 & qspeaken == 0

gen engspknw = engspkw
* replace engspknw = 1 if speakeng == 6 & qspeaken == 0

gen eng = 0 if speakeng == 1
replace eng = 1 if speakeng == 6
replace eng = 2 if speakeng == 5
replace eng = 3 if (speakeng == 4 | speakeng == 3)
replace eng = . if qspeaken ~= 0

label var engspkvw "speaks english very well"
label var engspkw "speaks english well or very well"
label var engspknw "speak at least some english"
label var eng "english ability, ordinal measure 0 to 3"


* MARITAL STATUS AND NUMBER OF CHILDREN 
* marriage
gen marriedpresent = (marst == 1) if qmarst == 0
gen divorced = (marst == 4) if qmarst == 0
gen evermarried = (marst ~= 6) if qmarst == 0

label var marriedpresent "currently married with spouse present"
label var divorced "currently divorced"
label var evermarried "has ever married (never married = 0)"


* number of kids in same hh
* nchild

gen haskid = (nchild > 0)
lab var haskid "has at least one child in HH"

* single parent
gen singleparent = (1-marriedpresent)*haskid if qmarst == 0 
gen nevermarried_haskid = (1-evermarried)*haskid if qmarst == 0

lab var  singleparent "dummy for nchild>=1 but not currently married with spouse present"
lab var   nevermarried_haskid " dummy for nchild>=1 but never married"

compress

save "$data_clean_spouses/output_B_child_immigs_all_years.dta", replace

********************************************************************************
/* Generate dataset of partners of childhood immigrants */ 
********************************************************************************

use "$output_B_long_all_years", clear

keep if partner_of_ch_immig == 1

/* code spouse's outcome variables */

* age: already present

* sex
gen female = sex == 2
label var female "female dummy"

* race (general)
gen white = race == 1
gen black = race == 2
gen asianpi = (race == 4 | race == 5 | race == 6)
gen other   = (race == 7|race == 3)
gen multi	= (race == 8 | race == 9)

label var white "race: white"
label var black "race: black"
label var asianpi "race: asian (Chinese, Japanese), pacific islander"
label var other "race: other (American  Indian or Alaska Native, Other race)"
label var multi "race: multiracial (two major races, three or more major races )"

* hispanic origin
gen hispdum = hispand ~= 0
label var hispdum "hispanic dummy"

* years of schooling (starting from elementary school) - // (to revise)
gen yrssch = 0
replace yrssch = 1 if educd == 14
replace yrssch = 2 if educd == 15
replace yrssch = 3 if educd == 16
replace yrssch = 4 if educd == 17
replace yrssch = 5 if educd == 22
replace yrssch = 6 if educd == 23
replace yrssch = 7 if educd == 25
replace yrssch = 8 if educd == 26
replace yrssch = 9 if educd == 30
replace yrssch = 10 if educd == 40
replace yrssch = 11 if (educd == 50 | educd == 61)
replace yrssch = 12 if (educd == 63 | educd == 64)
replace yrssch = 14 if (educd == 71 | educd == 81)
replace yrssch = 16 if educd == 101
replace yrssch = 19 if (educd == 114 | educd == 115) 
/* 
I tried to follow B and C as much as possible. But how can it be that master 
degree = 19 yrssch and phd = 20 yrssch? I coudld put 19 + 5 = 24 for a phd 
(instesd of 20), since in the US a phd takes 4 to 6 years to complete
*/

replace yrssch = 20 if educd == 116
replace yrssch = . if qeduc ~= 0

//gen hsdipl   = educ99 >= 10 if qeduc == 0
//gen somecoll = educ99 >  10 if qeduc == 0
//gen colldipl = educ99 >= 14 if qeduc == 0

label variable yrssch "years of schooling"
//label var hsdipl "high school grad"
//label var somecoll "has some college"
//label var colldipl "college grad"

* LABOR MARKET OUTCOMES

* wage and salary income last year

gen wagely = incwage if incwage > 0 & incwage ~= 999999 & qincwage == 0
gen lnwagely = ln(wagely)

label var wagely "wage last year conditional on pos earnings"
label var lnwagely "ln(wagely)"

* worked last year
gen workedly = workedyr == 3 if workedyr ~= 0 & qworkedy == 0
label var workedly "worked last year"

* speaks English
gen engspkvw = (speakeng == 3 | speakeng == 4)
* if qspeaken == 0

gen engspkw  = engspkvw
* replace engspkw = 1 if speakeng == 5 & qspeaken == 0

gen engspknw = engspkw
* replace engspknw = 1 if speakeng == 6 & qspeaken == 0

gen eng = 0 if speakeng == 1
replace eng = 1 if speakeng == 6
replace eng = 2 if speakeng == 5
replace eng = 3 if (speakeng == 4 | speakeng == 3)
replace eng = . if qspeaken ~= 0

label var engspkvw "speaks english very well"
label var engspkw "speaks english well or very well"
label var engspknw "speak at least some english"
label var eng "english ability, ordinal measure 0 to 3"

* MARITAL STATUS AND NUMBER OF CHILDREN
* marriage
gen marriedpresent = (marst == 1) if qmarst == 0
gen divorced = (marst == 4) if qmarst == 0
gen evermarried = (marst ~= 6) if qmarst == 0

label var marriedpresent "currently married with spouse present"
label var divorced "currently divorced"
label var evermarried "has ever married (never married = 0)"


* number of kids in same hh
* nchild

gen haskid = (nchild > 0)
lab var haskid "has at least one child in HH"

rename female     souse_female
rename sex        spouse_sex
rename age        spouse_age
rename white      spouse_white
rename black      spouse_black
rename asianpi    spouse_asianpi
rename other      spouse_other
rename multi      spouse_multi
rename hispdum    spouse_hispdum
rename yrssch     spouse_yrssch
//rename hsdipl   spousehsdipl
rename speakeng   spouse_speakeng
rename qspeaken   spouse_qspeaken
rename eng        spouse_eng
rename engspkvw   spouse_engspkvw
rename engspkw    spouse_engspkw
rename engspknw   spouse_engspknw
rename lnwage     spouse_lnwage
rename workedly   spouse_workedly
rename yrimmig    spouse_yrimmig
rename bpld       spouse_bpld
rename languaged  spouse_languaged
rename ancestr1d  spouse_ancestr1d
rename ancestr2d  spouse_ancestr2d

/* Rename partner variables to differentiate them
local vars year sample cbserial numprec subsamp hhwt hhtype cluster adjust cpi99 region ///
stateicp statefip countyicp countyfip puma density metro pctmetro met2023 met2023err ///
metpop10 city cityerr citypop homeland strata gq gqtype gqtyped ownershp ownershpd ///
hhincome lingisol cinethh cilaptop cismrtphn citablet ciothcomp cidatapln cihispeed ///
cisat cidial ciothsvc vehicles coupletype ssmc nfams ncouples nmothers nfathers multgen ///
multgend qownersh qcidial qcilaptop qcinethh qciothcomp qciothsvc qcisat qcismrtphn ///
qcitablet qcidatapln qcihispeed qvehicle respmode qhhincome pernum perwt slwt famunit ///
famsize momloc stepmom momrule poploc steppop poprule sploc sprule nchild nchlt5 nsibs ///
eldch yngch related sex age marst birthyr marrno marrinyr yrmarr divinyr widinyr fertyr ///
race raced hispan hispand bpl bpld ancestr1 ancestr1d ancestr2 ancestr2d citizen ///
yrnatur yrimmig yrsusa1 yrsusa2 language languaged speakeng tribe tribed racamind ///
racasian racblk racpacis racwht racother racnum hcovany school educ educd gradeatt ///
gradeattd schltype empstat empstatd labforce classwkr classwkrd occ occ1950 occ1990 ///
occ2010 occsoc ind indnaics wkswork1 wkswork2 uhrswork wrklstwk absent looking availble ///
wrkrecal workedyr inctot ftotinc incwage incbus00 incss incwelfr incinvst incretir ///
incsupp incother incearn poverty occscore sei migrate1 migrate1d migplac1 migcounty1 ///
migpuma1 migmet131 migmet13err migpumanow movedin vetdisab diffrem diffphys diffmob ///
diffcare diffsens diffeye diffhear vetstat vetstatd vet01ltr vet90x01 vet75x90 vetvietn ///
vet55x64 vetkorea vetwwii vetother vetotherd pwstate2 pwcounty pwmet13 pwmet13err ///
pwpuma00 tranwork carpool riders trantime departs arrives gchouse gcmonths gcrespon ///
qage qfertyr qmarrno qmarst qrelate qsex qmarinyr qyrmarr qwidinyr qdivinyr qbpl qcitizen ///
qhispan qlanguag qrace qspeaken qyrimm qyrnatur qhinsemp qhinspur qhinstri qhinscai ///
qhinscar qhinsva qhinsihs qeduc qgradeat qschool qclasswk qempstat qind qocc quhrswor ///
qwkswork1 qwkswork2 qworkedy qincearn qincbus qincinvs qincothe qincreti qincss qincsupp ///
qinctot qftotinc qincwage qincwelf qmigplc1 qmovedin qdifsens qdifphys qdifrem qdifmob ///
qdifcare qdifeye qdifhear qvetdisb qvetper qvetstat qcarpool qdeparts qpwstat2 qriders ///
qtrantim qtranwor qgchouse qgcmonth qgcrespo partner_of_ch_immig age_at_arrival


foreach x of local vars {
    rename `x' partner_`x'
}
*/

/* Generate a variable that converts values of relate in the following way (1 to 2 
and 2 to 1) for effective matching (i.e., so that each childhood immigrant is 
matched to his / her partner)
*/

gen relate_swapped = 3 - relate, after(serial) 
drop relate
rename relate_swapped relate

keep serial relate year spouse* 

compress

save "$data_clean_spouses/output_B_partners_all_years.dta", replace

/* if a hh appers twice, then both head and spouse are childhood immigrants */

/* motivation: When I merge the two datasets I want to have a resulting dataset
which has:

- on the left: childhood immigrants (and all their features)
- on the right: partners of childhood immigrants (and all their features). These
  variables need to be renamed (e.g., spouse_speakeng, spouse_incwage, etc.)

if two childhood immigrants are married, then the household should appear twice
in the final dataset

potential issue: if I use serial as the key for the merge, then the couple may 
be incorrectly identified if both partners are childhood immigrants. For instance, 
a childhood immigrant may appear as being married to him/herself
*/

********************************************************************************
/* merge the dataset of childhood immigrants with the dataset of partners of 
                         childhood immigrants */ 
********************************************************************************
use "$output_B_child_immigs_all_years", clear

* Merge with partners dataset using the household serial as the key
merge 1:1 year serial relate using "$output_B_partners_all_years"

keep if _m == 3

drop _m 

sort year serial

gen marriednative = spouse_bpld < 1000
gen couplesamebpld = bpld == spouse_bpld
gen couplesameancestry1 = ancestr1d == spouse_ancestr1d
gen bothworked = 1 if (workedly ==1 & spouse_workedly == 1)
replace bothworked = 0 if bothworked == .

// reminder: check for shares of engom and nengdom
summarize engdom 
scalar mean_engdom = r(mean) // ~ 11.4%

summarize nengdom 
scalar mean_nengdom = r(mean) // ~ 88.6%

count if nengdom == 1 // 379,988
count if nengdom == 0 // 48,870

save "$data_clean_spouses/output_B_matched_all_years.dta", replace

/* check: 

serial == 6930 in 2023. It should and does appear twice in final dataset

*/
