

*Drop non-consenting participants
drop if Q7Surv=="Do not use my anonymised activity in the study."

*Drop variable for interviews - this information is not relevant for the survye and the experiment
drop Q8Surv

*Drop incomplete 
drop if completion <87

*Label and rename variables*
label variable Q6Surv "Participation Information"
rename Q6Surv participinfo
label variable Q7Surv "Informed consent"
rename Q7Surv consent
la var Q14Surv "Entrepreneurial experience"
rename Q14Surv entexp
la var Q16Surv "Exposure to entrepreneurship"
rename Q16Surv xposent
la var Q17Surv "Programme"
rename Q17Surv prog
gen busscho=prog
replace busscho=0 if busscho!=1
la var Q18Surv "Courses Ent"
encode Q18Surv, gen(courses)
replace courses=0 if courses==1
replace courses=1 if courses==2
replace courses=2 if courses==3
replace courses=3 if courses==4
la var Q21_1Surv "CSE: I am good at generating novel ideas"
rename Q21_1Surv cse1
la var Q22_1Surv "CSE: Confidence in ability to solve problems creatively"
rename Q22_1Surv cse2
la var Q23_1Surv "Talent for improving ideas of others"
rename Q23_1Surv cse3
la var Q26_1Surv "PI: First when hear about" 
rename Q26_1Surv pinno1
la var Q27_1Surv "PI: First among friends"
rename Q27_1Surv pinno2
la var Q28_1Surv "PI:Like to experiment"
rename Q28_1Surv pinno3
la var Q31_1Surv "Pragmatic legitimacy 1"
rename Q31_1Surv pl1
la var Q32_1Surv "Cognitive legitimacy 1"
rename Q32_1Surv cl1
la var Q33_1Surv "Cognitive legitimacy 2"
rename Q33_1Surv cl2
la var Q34_1Surv "Pragmatic legitimacy 2"
rename Q34_1Surv pl2
la var Q35_1Surv "Cognitive legitimacy 3"
rename Q35_1Surv cl3
la var Q36_1Surv "Moral legitimacy 1"
rename Q36_1Surv ml1
la var Q37_1Surv "Moral legitimacy 2"
rename Q37_1Surv ml2
la var Q38_1Surv "Pragmatic legitimacy 3"
rename Q38_1Surv pl3
la var Q39_1Surv "Moral legitimacy 3"
rename Q39_1Surv ml3
la var Q40Surv "Frequency of GenAI use"
rename Q40Surv frequse
replace frequse=1 if frequse==5
replace frequse=2 if frequse==6
replace frequse=3 if frequse==3
replace frequse=3 if frequse==7
replace frequse=4 if frequse==8
replace frequse=5 if frequse==9
replace frequse=5 if frequse==10
replace frequse=6 if frequse==11
replace frequse=6 if frequse==12
la var Q41Surv "Frequency of Gen AI use: Planning"
rename Q41Surv useplan
la var Q42Surv "Frequency of Gen AI use: Professional"
rename Q42Surv useprof
la var Q43Surv "Frequency of Gen AI use: Academic"
rename Q43Surv useacad
la var Q46_1Surv "SE: Confident to do well"
rename Q46_1Surv se1
la var Q47_1Surv "SE: Expect to do well"
rename Q47_1Surv se2
la var Q48_1Surv "SE: Master skills"
rename Q48_1Surv se3

la var Q50Surv "Gender"
rename Q50Surv gender
gen female=1 if gender=="Female"
replace female=0 if gender=="Male"
la var Q51Surv "Age"
rename Q51Surv ageoriginal
*drop Q52 - Check with Kasia and Raluca
gen uk=1 if country_group=="United Kingdom"
replace uk=0 if uk==.

la var Q9Exp "Comprehension Task 1"
rename Q9Exp compt1
la var Q25Exp "Comprehension Task 2"
rename Q25Exp compt2
encode compt2, gen(compt22)
tab compt22
label drop compt22
replace compt22=0 if compt22==1
replace compt22=1 if compt22==2

/* Note: drop if starting time is equal or greater than 13h27. 
 */



reg time1 i.creativity##c.selfefficacy ageoriginal female courses uk CL ML PL frequse useacad useplan useprof persinno 




/*****

	Stata is not very good with long texts - at least we had trouble dealing with the conversations and we took some shortcuts.
		We exported two variables to Excel: The code and the ChatGPT conversation. 
		On Excel, we replaced line break with "|" using =SUBSTITUTE(A2,CHAR(10),"|"). "A2" being the first cell with conversations. All line breaks will become |. Repeat the operation to all observations.
	Save and import back to Stata
.*/


import excel "C:\Users\jviotto\Downloads\test.xlsx", sheet("Sheet1") firstrow
drop C D E F
gen conv1 = subinstr(conversation ,"|User|","\",.)
gen conv2 = subinstr(conv1 ,"|User:|","\",.)
gen conv3 = subinstr(conv2, "|AM|","\",.)
gen conv4 = subinstr(conv2, "|You|","\",.)

drop conv1
drop conv2
drop conv3
rename conv4 conv
split conv, parse(\)

/*
variables created as string: 
conv1   conv2   conv3   conv4   conv5   conv6   conv7   conv8   conv9   conv10  conv11  conv12  conv13  conv14  conv15
*/

reshape long conv, i(matchingcodeoriginal ) j(chat)
(j = 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)

Data                               Wide   ->   Long
-----------------------------------------------------------------------------
Number of observations              148   ->   2,368       
Number of variables                  18   ->   4           
j variable (16 values)                    ->   chat
xij variables:
                 conv0 conv1 ... conv15   ->   conv
-----------------------------------------------------------------------------

drop if conv==""
drop if chat==0

gen chatgpt = subinstr(conv ,"|ChatGPT|","\",.)
split chatgpt, parse(\)

rename chatgpt1 prompt
rename chatgpt2 output

export excel using "C:\Users\jviotto\Downloads\prompts.xlsx", firstrow(variables)
file C:\Users\jviotto\Downloads\prompts.xlsx saved




/*
We may want to drop the matching code and use another code, Qualtrics code, for example, as there is sensitive information, especially if we share the conversations. 

*/

	

