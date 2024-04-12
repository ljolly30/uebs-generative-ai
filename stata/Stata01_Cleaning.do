/*##############################################################
Survey GenAI and Two Treatements Dataset Cleaning
Description: This script is designed for cleaning, analyzing, and documenting
             the dataset for reproducibility 
Elaf Basri
15.3.2014
STATA/SE 18.0
##############################################################*/


/*##############################################################
Creation of Matching Code from Survey Responses
This section combines responses from Q55 to Q59 to create a unique identifier
'matchingcodeoriginal' for each respondent then details identifying matches, 
handling mismatches due to naming or entry variations through merging, and ensuring consistency across survey and experiment datasets with special attention to cases where participants may use different names or make entry errors.
##############################################################*/

* Aggregate responses to create the matching code in Survey GenAI dataset
gen matchingcodeoriginal = Q55Surv + Q56Surv + Q57Surv + Q58Surv +Q59Surv

* Aggregate responses to create the matching code in Two treatement dataset
gen matchingcodeoriginal = Q2Exp + Q3Exp + Q4Exp + Q5Exp + Q6Exp


* Merging Datasets to Identify Direct Matches and Mismatches
* Temporarily combine datasets for matching purposes
* Ensure both datasets are saved with 'matchingcodeoriginal' variable

* Merging Dataset 1 (as master) with Dataset 2 (as using)
merge 1:1 matchingcodeoriginal using "experiment_dataset.dta"

* Identify mismatches (_merge != 3 indicates potential mismatch)
* 56 from the Survey and 46 from the experiment that didn't match. After manual inspection a further 30 were matched based on differences in 1-3 letters or case issues
*Survey matchingcodeoriginal was used to replace manual matches in Exp.
* Define the old (exp.) and new (Surv) values as local macros
local oldvalues "AD10sD As4HF BL14HA WG19LO CH4JM JH3HJ JS6JM KT5HN LZ22BJ RS12wS SC24HO SC2HJ SX6MD TT14QJ WJ4QJ XA24LJ TH19YF YS27LJ YS9XJ JW11LJ YZ6SJ YZ14TO SX19sM cd9rn"
local newvalues "AD10SD AE4HF BL14JA CG19LO CH4JA JS3HJ JS6ZM KS5HN LC22BJ RS12YS SC24HS SC2LJ SX6YD TS14QJ WZ4QJ XL24LJ YH19YF YS27HJ YS9HJ YW11LJ YZ12SJ YZ14YO sx19sm CD9RE"

* Ensure 'matchcode' is a string; if it's numeric, convert it to a string first
* tostring matchcode, replace

* Loop over the values to recode
local numvalues = wordcount("`oldvalues'")
forval i = 1/`numvalues' {
    local old = word("`oldvalues'", `i')
    local new = word("`newvalues'", `i')
	replace matchingcodeoriginal = "`new'" if matchingcodeorigi == "`old'"
}

* drop those outside of window or without a match:
*from Survey
local dropvalues "ZW20JJ YJ28SA KD27NJ JL10MN JS16LA 4rrrqr BB18YA CA22JS CG14LF CH26CD CH26YD CL24LJ DB8HO FN29ZM GV15AF HC20GJ HT18pS KC15CM LS30WS LS7MM MS7SM MS9YO SS2HH TY20BM XN23XM XS17ZS cS11WS ddddd ff212 cc3ja rrwrb8 HJ31LO"

* Loop through each value in the list and drop the observations where Matchcode matches the value
foreach value in `dropvalues' {
    drop if matchingcodeoriginal == "`value'"
}

*from Experiment
local dropvalues "ZW20JD YJ28ZA KN27NJ JP10MN LS16LA AP3NN BW7HN CB8QO HS17LS HX20JJ IH26ID KG15MM LS30DA ME8SO ME9CS SY20NM WA19LO WS4SJ YG14YA YN29YM CT18PS"

* Loop through each value in the list and drop the observations where Matchcode matches the value
foreach value in `dropvalues' {
    drop if matchingcodeoriginal == "`value'"
}

*Merge new files: 175 final matches

* Drop _merge to clean up post-merge
drop _merge

* Document Final Matching Codes (excel) and Save Adjusted Dataset
save "adjusted_survey_dataset.dta", replace


/*##############################################################
Handling Duplicates in the Survey Dataset
This script identifies and resolves duplicate entries in the survey dataset, prioritizing
the last attempt and attempts with complete responses for retention.

Duplicates in Survey terms of matchingcodeoriginal after running:

duplicates report matchingcodeoriginal
duplicates list matchingcodeoriginal

--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |          197             0
        2 |           20            10
       23 |           23            22
--------------------------------------

Duplicates in Experiment terms of matchingcodeoriginal after running:

duplicates report matchingcodeoriginal
duplicates list matchingcodeoriginal

--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |          184             0
        2 |           24            12
        3 |            3             2
       37 |           37            36
--------------------------------------
##############################################################*/


* Step 1: Sort by the unique identifier, Finished (completion) and RecordedDate
sort matchingcodeoriginal Finished RecordedDate

* Step 2: Mark the last attempt for each unique identifier
by matchingcodeoriginal: gen tokeep = _n == _N

* Step 3: Keep only the last attempts and drop the marker variable
keep if tokeep
drop tokeep

* Note: This approach assumes 'matchingcodeoriginal' is your unique identifier and 'RecordedDate'
* is correctly formatted to reflect the chronological order of survey attempts.


/*##############################################################
***Survey - GenAI***
##############################################################*/

/*##############################################################
Direct Recoding of String Responses to Numerical Likert Scale
This script recodes string responses for specified variables directly into numerical
values based on the Likert scale.
##############################################################*/

* Recode string responses to numerical values for each variable
foreach var in Q21_1Surv Q22_1Surv Q23_1Surv Q26_1Surv Q27_1Surv Q28_1Surv Q31_1Surv Q32_1Surv Q33_1Surv Q34_1Surv Q35_1Surv Q36_1Surv Q37_1Surv Q38_1Surv Q39_1Surv {
    replace `var' = "1" if `var' == "Totally disagree"
    replace `var' = "2" if `var' == "Mostly disagree"
    replace `var' = "3" if `var' == "Slightly disagree"
    replace `var' = "4" if `var' == "Neutral" | `var' == "Neither agree nor disagree"
    replace `var' = "5" if `var' == "Slightly agree"
    replace `var' = "6" if `var' == "Mostly agree"
    replace `var' = "7" if `var' == "Totally agree"
    destring `var', replace
}			

/*##############################################################
Q14: Recode Q14_Surv to create binary variables for entrepreneurial experience
First, ensure Q14 is numeric. If Q14 is stored as string due to survey coding, convert it to numeric
Uncomment and modify the next line if Q14 is a string variable
encode Q14, gen(Q14_numeric) // Replace Q14 with the new numeric variable if necessary 
##############################################################*/

* Convert Q14_Surv to numeric values
replace Q14Surv = "10" if Q14Surv == "I have experience as an entrepreneur."
replace Q14Surv = "11" if Q14Surv == "I have experience as a business owner."
replace Q14Surv = "12" if Q14Surv == "I have experience as a self-employed person."
replace Q14Surv = "13" if Q14Surv == "None of the above."
destring Q14Surv, replace

* Generate "entrepreneurial experience - narrower" variable (entxn)
generate entxn = (Q14Surv == 10 | Q14Surv == 11)

* Label the entxn variable
label variable entxn "entrepreneurial experience - narrower"

* Generate "entrepreneurial experience - broader" variable (entxb)
generate entxb = (Q14Surv == 10 | Q14Surv == 11 | Q14Surv == 12)

* Label the entxb variable
label variable entxb "entrepreneurial experience - broader"


/*##############################################################
Recode Q16Surv to create binary variables for parental entrepreneurial exposure
##############################################################*/

* Convert Q16 to numeric values
replace Q16Surv = "1" if Q16Surv == "At least one of my parents has experience as entrepreneur."
replace Q16Surv = "2" if Q16Surv == "At least one of my parents has experience as business owner."
replace Q16Surv = "3" if Q16Surv == "At least one of my parents has experience as a self-employed person."
replace Q16Surv = "4" if Q16Surv == "None of the above."
destring Q16Surv, replace

* Generate "entrepreneurial exposure - narrower" variable (xposen)
generate xposen = (Q16Surv == 1 | Q16Surv == 2)
* Label the xposen variable
label variable xposen "entrepreneurial exposure - narrower"

* Generate "entrepreneurial exposure - broader" variable (xposeb)
* Adjusted to include all options that imply entrepreneurial experience
generate xposeb = (Q16Surv == 1 | Q16Surv == 2 | Q16Surv == 3)

* Label the xposeb variable
label variable xposeb "entrepreneurial exposure - broader"

/*##############################################################
Q17Surv: Recode Q17Surv to categorize programmes based on their relationship to business studies
##############################################################*/
* Convert Q17Surv to numeric values
replace Q17Surv = "1" if Q17Surv == "A programme at the Business School."
replace Q17Surv = "12" if Q17Surv == "Law and Business / Psychology and Business / Economics and Management."
replace Q17Surv = "13" if Q17Surv == "Language and Business (for example, French and Business, German and Business)."
replace Q17Surv = "5" if Q17Surv == "Mathematics and Business."
replace Q17Surv = "10" if Q17Surv == "Mathematics / Mathematics and Statistics / Applied Mathematics."
replace Q17Surv = "11" if Q17Surv == "Computer Science / Data Science / Informatics."
replace Q17Surv = "6" if Q17Surv == "I am an exchange student, but I study business in my home university."
replace Q17Surv = "7" if Q17Surv == "I am an exchange student, and I do not study business in my home university."
replace Q17Surv = "8" if Q17Surv == "I am in another programme at the University of Edinburgh."
destring Q17Surv, replace

* Generate the 'programme' variable based on Q17 responses 
* Initialize 'programme' variable
gen programme = .

* Business programme at the Business School
replace programme = 1 if Q17Surv == 1

* Another programme with a business component
replace programme = 2 if Q17Surv == 12 | Q17Surv == 13 | Q17Surv == 5 | Q17Surv == 6

* A programme without a business component
replace programme = 3 if Q17Surv == 10 | Q17Surv == 11 | Q17Surv == 7 | Q17Surv == 8

/*##############################################################
Q21 to Q23: Calculate average score for creative self-efficacy
This section generates a variable 'creativese' representing the average
score of responses to Q21, Q22, and Q23, which measure aspects of creativity.
##############################################################*/

* Calculate the average score for creative self-efficacy
gen creativese = (Q21_1Surv + Q22_1Surv + Q23_1Surv) / 3

* Label the 'creativese' variable
label variable creativese "Creative Self-Efficacy"


/*##############################################################
Q26 to Q28: Calculate average score for personal innovativeness
This section generates a variable 'persinno' by averaging the scores
of responses to Q26, Q27, and Q28, which assess attitudes toward adopting
new information technologies.
##############################################################*/

* Calculate the average score for personal innovativeness
gen persinno = (Q26_1Surv + Q27_1Surv + Q28_1Surv) / 3

* Label the 'persinno' variable
label variable persinno "Personal Innovativeness"

/*##############################################################
Q31-Q39: AI legitimacy
This section generates generate three variables, each variable is the average of the answers to three corresponding questions.
PL (Pragmatic legitimacy)
Average of 
1. I believe that Generative AI tools perform satisfactorily. (PL)
4. The way Generative AI tools function serve the interests of users. (PL)
8. I believe that the use of Generative AI tools benefits users. (PL)
CL (Cognitive legitimacy)
Average of
2. I believe that Generative AI tools are necessary. (CL)
3. I believe that Generative AI tools provide an essential function. (CL)
5. It is difficult to imagine now a world in which Generative AI tools did not exist. (CL)

ML (Moral legitimacy)
Average of
6. I believe that Generative AI tools are consistent with broader industry and social norms. (ML)
7. The general public would approve of the use of Generative AI tools. (ML)
9. Most people would consider the use of Generative AI tools to be ethical and moral. (ML)

##############################################################*/

* Pragmatic Legitimacy (PL)
* Average of Q31_1, Q34_1, Q38_1
gen PL = (Q31_1Surv + Q34_1Surv + Q38_1Surv)/3
label var PL "Pragmatic Legitimacy"

* Cognitive Legitimacy (CL)
* Average of Q32_1, Q33_1, Q35_1
gen CL = (Q32_1Surv + Q33_1Surv + Q35_1Surv)/3
label var CL "Cognitive Legitimacy"

* Moral Legitimacy (ML)
* Average of Q36_1, Q37_1, Q39_1
gen ML = (Q36_1Surv + Q37_1Surv + Q39_1Surv)/3
label var ML "Moral Legitimacy"


/*##############################################################
Q40: Identify frequent users of Generative AI
This section generates a binary variable 'frequentuser' to categorize respondents
as frequent users of Generative AI based on their self-reported usage frequency.
Frequent users are defined as those using Generative AI once or more each day or
several times each week.
##############################################################*/

* Convert Q40 to numeric values
replace Q40Surv = "5" if Q40Surv == "Once or more each day."
replace Q40Surv = "6" if Q40Surv == "Several times each week."
replace Q40Surv = "7" if Q40Surv == "About once each week."
replace Q40Surv = "8" if Q40Surv == "Twice or three times a month."
replace Q40Surv = "10" if Q40Surv == "About once a month."
replace Q40Surv = "11" if Q40Surv == "Less than once a month."
replace Q40Surv = "12" if Q40Surv == "I have heard of, but never used any form of Generative AI."
destring Q40Surv, replace

* Generate 'frequentuser' variable based on Q40 responses
gen frequentuser = (Q40Surv == 5 | Q40Surv == 6)

* Label the 'frequentuser' variable
label variable frequentuser "Frequent Generative AI User"

/*##############################################################
Q41 to Q43: Recode for Generative AI use in different contexts and compute average
This section recodes the responses to Q41, Q42, and Q43 into a 1 to 3 scale,
replacing the original codes of 4, 7, 8. Then, it calculates the average of these
recoded values to generate a new variable 'usecontext' representing the average use
of Generative AI tools across social, professional, and university-related activities.
##############################################################*/

* Recode Q41, Q42, and Q43 from 4, 7, 8 to 1, 2, 3
* Recode Q41
replace Q41Surv = "1" if Q41Surv == "I use Generative AI quite often for this type of purpose."
replace Q41Surv = "2" if Q41Surv == "I have used Generative AI occasionally for this type of purpose."
replace Q41Surv = "3" if Q41Surv == "I have never used Generative AI for this type of purpose."
destring Q41Surv, replace

* Recode Q42
replace Q42Surv = "1" if Q42Surv == "I use Generative AI quite often for this type of purpose."
replace Q42Surv = "2" if Q42Surv == "I have used Generative AI occasionally for this type of purpose."
replace Q42Surv = "3" if Q42Surv == "I have never used Generative AI for this type of purpose."
destring Q42Surv, replace

* Recode Q43
replace Q43Surv = "1" if Q43Surv == "I use Generative AI quite often for this type of purpose."
replace Q43Surv = "2" if Q43Surv == "I have used Generative AI occasionally for this type of purpose."
replace Q43Surv = "3" if Q43Surv == "I have never used Generative AI for this type of purpose."
destring Q43Surv, replace

* Calculate the average use context score
gen usecontext = (Q41Surv + Q42Surv + Q43Surv) / 3

* Label the 'usecontext' variable
label variable usecontext "Use In Context"


/*##############################################################
Q46 to Q48: Calculate average score for self-efficacy
This section computes an average of the responses to Q46, Q47, and Q48 to
create a new variable 'selfefficacy', representing the respondent's self-perceived
efficacy in handling course assignments, expectations, and mastering skills.
##############################################################*/

* Assuming Q46, Q47, and Q48 the coding was a type and the right code is1=1, 2=3, 3=4, 4=5, 5=6, 6=7, 7=9 

* Calculate the average score for self-efficacy
gen selfefficacy = (Q46_1Surv +Q47_1Surv + Q48_1Surv) / 3

* Label the 'selfefficacy' variable
label variable selfefficacy "Self-Efficacy"


/*##############################################################
Q51: Handling Age Data for Privacy
This section creates a new variable 'age' from Q51, identifies ages with 5 or fewer observations with recoding strategies to prevent de-identification
##############################################################*/

* Step 1: Create a new variable "age"
gen age = Q51Surv
label variable age "Age"

* Step 2: Determine the number of observations for each age to identify sparse data
bysort age: gen age_count = _N

* Step 3: Listing ages with 5 or fewer observations to consider for recoding
list age if age_count <= 5

/*##############################################################

        Age |      Freq.     Percent        Cum.
------------+-----------------------------------
         18 |          3       17.65       17.65
         19 |          2       11.76       29.41
         25 |          2       11.76       41.18
         28 |          1        5.88       47.06
         29 |          1        5.88       52.94
         30 |          2       11.76       64.71
         33 |          1        5.88       70.59
         34 |          2       11.76       82.35
         44 |          3       17.65      100.00
------------+-----------------------------------
      Total |         17      100.00

For ages identified with 5 or fewer observations, we could consider grouping them into broader categories to prevent de-identification:
Under 20: Combine all respondents younger than 20.
20-24: This is our most well-represented group, so can keep it as is.
25-30: Include all respondents from 25 to 30 years .
30+: Group everyone older than 30 together. 
##############################################################*/

* Recoding age into broader categories
recode age (min/19=1) (20/24=2) (25/30=3) (31/max=4), generate(age_group)

* Define value labels age_group variable
label define age_group 1 "Under 20" 2 "20-24" 3 "25-30" 4 "30+"


/*##############################################################
Q52: Handling High School Country Data for Privacy
This section creates a new variable 'hscountry' from Q52, identifies countries with 5 or fewer observations to assess de-identification risks
##############################################################*/

* Step 1: Create a new variable "hscountry"
gen hscountry = Q52Surv
label variable hscountry "Country (high school years)"

* Step 2: Determine the number of observations for each country to identify those with sparse data
bysort hscountry: gen country_count = _N

* Step 3: Listing countries with 5 or fewer observations to consider for recoding
list hscountry if country_count <= 5

/*##############################################################
           Country (high school years) |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                              Australia |          3        6.98        6.98
                             Azerbaijan |          1        2.33        9.30
                             Bangladesh |          1        2.33       11.63
                                 Brazil |          5       11.63       23.26
                               Cambodia |          1        2.33       25.58
                                 Canada |          2        4.65       30.23
                                  Chile |          2        4.65       34.88
                         Czech Republic |          1        2.33       37.21
                                 France |          1        2.33       39.53
                     Hong Kong (S.A.R.) |          3        6.98       46.51
                                  India |          4        9.30       55.81
                                Ireland |          1        2.33       58.14
                                  Italy |          1        2.33       60.47
                                  Kenya |          1        2.33       62.79
                                Myanmar |          2        4.65       67.44
                                 Norway |          2        4.65       72.09
                                   Peru |          1        2.33       74.42
                     Russian Federation |          1        2.33       76.74
                               Slovakia |          1        2.33       79.07
                           South Africa |          2        4.65       83.72
                            South Korea |          1        2.33       86.05
                                  Spain |          1        2.33       88.37
                                 Sweden |          1        2.33       90.70
                            Switzerland |          1        2.33       93.02
                               Thailand |          1        2.33       95.35
                   United Arab Emirates |          1        2.33       97.67
                               Viet Nam |          1        2.33      100.00
----------------------------------------+-----------------------------------
                                  Total |         43      100.00
Recoding Strategy:
For countries identified with 5 or fewer observations, we can consider grouping them into broader regions
Major  Countries: Keep major countries (China, United Kingdom, United States) as separate categories since they have a significant number of observations.
Geographical Regions: Group other countries into broader geographical regions.(e.g., East Asia, South Asia, Europe, Americas, Africa).
##############################################################*/

* Create a new variable for the recoded country groups
gen country_group = ""

* Assign observations from major countries to specific categories
replace country_group = "China" if hscountry == "China"
replace country_group = "United Kingdom" if hscountry == "United Kingdom of Great Britain and Northern Ireland"
replace country_group = "United States" if hscountry == "United States of America"

* Assign observations from other countries to broader geographical regions
replace country_group = "East Asia" if hscountry == "Hong Kong (S.A.R.)" | hscountry == "South Korea" | hscountry == "Japan" | hscountry == "Thailand" | hscountry == "Viet Nam"
replace country_group = "South Asia" if hscountry == "India" | hscountry == "Bangladesh" | hscountry == "Myanmar"
replace country_group = "Europe" if hscountry == "France" | hscountry == "Germany" | hscountry == "Italy" | hscountry == "Norway" | hscountry == "Sweden" | hscountry == "Switzerland" | hscountry == "Czech Republic" | hscountry == "Slovakia" | hscountry == "Russian Federation"
replace country_group = "Americas" if hscountry == "Canada" | hscountry == "Brazil" | hscountry == "Chile" | hscountry == "Peru"
replace country_group = "Africa" if hscountry == "Kenya" | hscountry == "South Africa"
replace country_group = "Middle East" if hscountry == "United Arab Emirates"
replace country_group = "Australia" if hscountry == "Australia"
replace country_group = "Other" if country_group == ""

/*##############################################################
***Submission - Two treatments - Original***
##############################################################*/

/*##############################################################
Creating Variables for Condition, Manipulation Check, and Task Submissions
This script outlines the process for identifying participants in the "creativity condition" versus the "neutral condition", and combines responses to create variables for a manipulation check,submission task 1, and time spent on task 1.
 'Manipcheck' and 'sub1' are generated by combining responses from the creativity and neutral conditions.
- 'Time1' consolidates timing information from both conditions into one variable.
##############################################################*/

* Step 1: Identify participants in the "creativity condition"
* Initialize the 'creativity' variable with 0 for all observations
gen creativity = 0
* Update 'creativity' to 1 only if all specified conditions are met
replace creativity = 1 if Q13Exp != "" & Q14Exp != "" & Q15_FirstClickExp != . & Q15_LastClickExp != . & Q15_PageSubmitExp != . & Q15_ClickCountExp > 0

* Step 2: Create 'manipcheck' variable combining Q13 and Q18
gen manipcheck = ""
replace manipcheck = Q13Exp if Q13Exp != ""
replace manipcheck = Q18Exp if Q18Exp != "" & manipcheck == ""

* Label 'manipcheck'
label variable manipcheck "Manipulation Check"

* Step 3: Create 'sub1' variable combining Q14 and Q19
gen sub1 = ""
replace sub1 = Q14Exp if Q14Exp != ""
replace sub1 = Q19Exp if Q19Exp != "" & sub1 == ""

* Label 'sub1'
label variable sub1 "Submission Task 1"

* Step 4: Create 'time1' variable combining Q15 (Page Submit) and Q20 (Page Submit)
gen time1 = .
replace time1 = Q15_PageSubmitExp if Q20_PageSubmitExp > 0
replace time1 = Q20_PageSubmitExp if Q20_PageSubmitExp > 0 & time1 == .

* Label 'time1'
label variable time1 "Time Spent on Task 1"


/*##############################################################
Creating Variables for Task 2 Submission and Timing
This script sets up variables for storing the final proposal submitted in Task 2 (Q108) and the time spent on Task 2 as recorded in Q109.
##############################################################*/

* Step 1: Create 'sub2' variable for Q108 (Submission Task 2)
gen sub2 = Q108Exp

* Label 'sub2'
label variable sub2 "Submission Task 2"

* Step 2: Create 'time2' variable for Q109 (Time Spent on Task 2) with (3, Page Submit). 
gen time2 = Q109_PageSubmitExp

* Label 'time2'
label variable time2 "Time Spent on Task 2"



/*##############################################################
Creating Variables for Evaluation of ChatGPT Support on Task 3
##############################################################*/

* Step 1: Create variables for each evaluation aspect of ChatGPT support
gen moreideas = Q28_1Exp
label variable moreideas "Support with more ideas"

gen betterideas = Q28_2Exp
label variable betterideas "Support with better ideas"

gen diffideas = Q28_3Exp
label variable diffideas "Support with different ideas"

gen quickideas = Q28_4Exp
label variable quickideas "Support with quicker completion"
		
* Step 2: Convert variables to numeric values
foreach var in moreideas betterideas diffideas quickideas {
    replace `var' = "1" if `var' == "Totally disagree"
    replace `var' = "2" if `var' == "Mostly disagree"
    replace `var' = "3" if `var' == "Slightly disagree"
    replace `var' = "4" if `var' == "Neutral" | `var' == "Neither agree nor disagree"
    replace `var' = "5" if `var' == "Slightly agree"
    replace `var' = "6" if `var' == "Mostly agree"
    replace `var' = "7" if `var' == "Totally agree"
    destring `var', replace
}
* Step 3: Calculate the average satisfaction with ChatGPT's support
gen aisatisfaction = (moreideas + betterideas + diffideas + quickideas)/4

* Label the 'aisatisfaction' variable
label variable aisatisfaction "Average satisfaction with AI"


/*##############################################################
Recode ChatGPT Version and Task Strategy Variables
This section creates variables 'freegpt' to capture usage of the ChatGPT free version based on Q32, 
and 'aireliance' to reflect the degree of reliance on AI for Task 3 strategy based on Q31.
##############################################################*/

* Step 1: Recode Q32 for ChatGPT version usage
gen freegpt = Q32Exp
label variable freegpt "ChatGPT free version"
replace freegpt = "1" if freegpt == "ChatGPT 3.5"
replace freegpt = "0" if freegpt == "ChatGPT 4"
destring freegpt, replace


* Step 2: Recode Q88 (noted as Q31 but assuming Q88 is correct based on context) for strategy on Task 2
gen aireliance = Q88Exp
label variable aireliance "AI Reliance"
replace aireliance = 1 if Q88Exp == 3
replace aireliance = 0 if Q88Exp != 3



/*##############################################################
Generative AI Conversation & Cleaning. This section: 
•	Create a separate dataset for the prompts. 
•	Use the identifiers that students created (e.g., TE8MS) to identify where the prompt goes. 
•	Identify the order of the prompts at the code level (i.e., a variable indicating 1 for the first prompt, 2 for the second prompt, etc.).
•	Create a new column with the corresponding ChatGPT output. 
##############################################################*/
* TBD


/* Output: Saving results */
* Save the cleaned and processed dataset
save processed_data.dta, replace



/* Closing log */
log close

/*##############################################################
End of script
##############################################################*/
