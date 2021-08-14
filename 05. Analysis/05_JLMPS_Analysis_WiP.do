use "$data_final/06_IV_JLMPS_Construct_Outcomes.dta", clear

*adoupdate, update
*findfile  ivreg2.ado
*adoupdate, update **
*ssc inst ivreg2, replace


***********************************************************************
**DEFINING THE SAMPLE *************************************************
***********************************************************************

**************
* JORDANIANS *
**************
codebook nationality_cl
lab list Lnationality_cl
/*
                        53,094         1  Jordanian
                         3,003         2  Syrian
                           623         3  Egyptian
                         2,551         4  Other Arab
                           132         5  Other

*/

keep if nationality_cl == 1 //Keep only the jordanians
*keep if nationality_cl != 2 //Keep all but the syrians
tab year 
tab age

***************
* WORKING AGE *
*************** 

*Keep only working age pop? 15-64 ? As defined by the ERF
tab age year 
drop if age < 15 
drop if age > 64
tab year 

**********************************
* PEOPLE SURVEYED IN BOTH ROUNDS *
**********************************

*br indid indid_2010 indid_2016 year
*SAMPLE: SAME INDIVIDUALS WERE SURVEYED IN 2010 AND 2016
*BUT A FEW WERE NOT (ALL REFUGEE WEREN'T SURVEYED IN 2010)
*AND A FEW JORDANIANS. I DECDIE TO KEEP ONLY THE PANEL STRUCTURE 
*FOR FIXED EFFECT AT THE INDIV LEVEL 

*Flag those who were surveyed in both rounds 
gen surveyed_2_rounds = 1 if !mi(indid_2010) & !mi(indid_2016)
*Keep only the surveyed in both round
keep if surveyed_2_rounds == 1 

*Common identifier
sort indid_2010
distinct indid_2010 //28316/2 = 14158 while we have 14306: there is an inbalance
*Even if they have an ID for both few actually did not do one of the round 
duplicates tag indid_2010, gen(dup)
bys year: tab dup //(90 in 2010 and 206 in 2016)
*Dropping those who actually did not the two rounds 
drop if dup == 0 
*28020 indiv surveyed twice in 2010 and 2020
mdesc indid_2010
destring indid_2010, replace 



*********************************************************************
*********************************************************************

************
*REGRESSION*
************
global    outcome_var_empl ///
                unemployed /// From unemp2m - ext def, search not req; 1 week, empl or unemp, OLF is miss
                unempdurmth ///    Current unemployment duration (in months)
                jobless2  ///  Jobless, Extended Definition (Among non-students)
                employed_3m  ///   From uswrkst2 - ext def, search not req; 3 months, empl or unemp, OLF is miss
                employed_1w  ///   From uswrkst1 - ext def, search not req; 1 week, empl or unemp, OLF is miss
                employed_3m_olf  ///   From usemp2 - ext def, 3 months, 1 empl - 0 unemp&OLF
                employed_1w_olf  ///   From cremp2 - ext def, 1 week, 1 empl - 0 unemp&OLF
                job_stability_permanent_1w /// From crstablp - Stability of employement (1w) - 1 permanent - 0 temp, seas, cas
                job_stability_permanent_3m /// From usstablp - Stability of employement (3m) - 1 permanent - 0 temp, seas, cas
                job_regular_1w /// From crirreg - Current job (1w) is regular - 1 Yes - 0 No
                job_regular_3m /// From usirreg - Usual job (3m) is regular - 1 Yes - 0 No
                incidence_soc_insur_1w /// Incidence of wrk social insurance in prim. job (ref. 1-week)
                incidence_soc_insur_3m /// Incidence of wrk social insurance in prim. job (ref. 3-month)
                incidence_wrk_contract_1w ///  Incidence of wrk contract in prim. job (ref. 1-week)
                incidence_wrk_contract_3m ///  Incidence of wrk contract in prim. job (ref. 3-month)
                job_formal_1w  /// Formality of prim. job (ref. 1-Week) - 0 Informal - 1 Formal
                job_formal_3m  /// Formality of prim. job (ref. 3-month) - 0 Informal - 1 Formal
                informal  ///  1 Informal - 0 Formal - Informal if no contract (uscontrp=0) and no insurance (ussocinsp=0)
                wp_industry_jlmps_1w  ///  Industries with work permits for refugees - Economic Activity of prim. job 1w
                wp_industry_jlmps_3m ///   Industries with work permits for refugees - Economic Activity of prim. job 3m
                member_union_3m /// Member of a syndicate/trade union (ref. 3-mnths)
                skills_required_pjob  ///  Does primary job require any skill
                stability_main_job /// From job1_07 : Degree of stability - Job 01 - 1 Stable
                permanent_contract // From job1_08 : Type of work contract - Job 01 - 1 Permanent

global outcome_var_wage ///
                basic_wage_3m  /// Basic Wage (3-month)
                real_basic_wage_3m /// CORRECTED INFLATION - Basic Wage (3-month)
                ln_basic_rwage_3m ///  LOG Basic Wage (3-month)
                IHS_basic_rwage_3m /// IHS Basic Wage (3-month)
                ln_basic_rwage_natives_cond /// CONDITIONAL - UNEMPLOYED & OLF: WAGE MISSING - NATIVES LOG Basic Wage (3m)
                ln_basic_rwage_uncond_unemp_olf /// UNCONDITIONAL - UNEMPLOYED & OLF: WAGE 0 - NATIVES - LOG - Basic Wage (3-month)
                ln_basic_rwage_uncond_unemp /// UNCONDITIONAL - UNEMPLOYED WAGE 0 / OLF WAGE MISSING - NATIVES LOG Basic (3m)
                total_wage_3m  /// Total Wages (3-month)
                real_total_wage_3m /// CORRECTED INFLATION - Total Wage (3-month)
                ln_total_rwage_3m  /// LOG Total Wage (3-month)
                IHS_total_rwage_3m /// IHS Total Wage (3-month)
                ln_total_rwage_natives_cond /// CONDITIONAL - UNEMPLOYED & OLF: WAGE MISSING - NATIVES LOG Total Wage (3m)
                ln_total_rwage_uncond_unemp_olf /// UNCONDITIONAL - UNEMPLOYED & OLF: WAGE 0 - NATIVES - LOG - Total Wage (3-month)
                ln_total_rwage_uncond_unemp /// UNCONDITIONAL - UNEMPLOYED WAGE 0 / OLF WAGE MISSING - NATIVES LOG Total (3m)
                mthly_wage /// Monthly Wage (Prim.& Second. Jobs)
                real_mthly_wage /// CORRECTED INFLATION - Monthly Wage (Prim.& Second. Jobs)
                ln_mthly_rwage /// LOG Monthly Wage (Prim.& Second. Jobs)
                hourly_wage /// Hourly Wage (Prim.& Second. Jobs)
                real_hourly_wage  ///  CORRECTED INFLATION - Hourly Wage (Prim.& Second. Jobs)
                ln_hourly_rwage /// LOG Hourly Wage (Prim.& Second. Jobs)
                daily_wage_irregular   /// Average Daily Wage (Irregular Workers)
                real_daily_wage_irregular  /// CORRECTED INFLATION - Average Daily Wage (Irregular Workers)
                ln_daily_rwage_irregular  //  LOG Average Daily Wage (Irregular Workers)

global outcome_var_hours ///
                work_hours_pday_1w /// No. of Hours/Day (Ref. 1 Week) Market Work
                work_hours_pday_1w_w  ///  Winsorized 
                work_hours_pday_3m /// No. of Hours/Day (Ref. 3 mnths) Market Work
                work_hours_pday_3m_w ///   Winsorized 
                work_hours_pweek_1w /// Crr. No. of Hours/Week, Market & Subsistence Work, (Ref. 1 Week)
                work_hours_pweek_1w_w  /// Winsorized
                work_hours_pweek_3m /// Usual No. of Hours/Week, Market & Subsistence Work, (Ref. 3-month)
                work_hours_pweek_3m_w ///  Winsorized
                work_days_pweek_1w /// No. of Days/Week (Ref. 1 Week) Market Work
                work_days_pweek_3m /// Avg. num. of wrk. days per week during 3 mnth.
                work_hours_pmonth_informal /// Average worked hour per month for irregular job
                work_hours_pmonth_informal_w //   Winsorized
**************
*GLOBALS 
global    controls ///
          age age2 sex hhsize 




************
*REGRESSION*
************

* SET THE PANEL STRUCTURE
xtset, clear 
*xtset year
xtset indid_2010 year 



              ***************************************************
                *****         M1: SIMPLE OLS:           *******
              ***************************************************

**********************
********* OLS ********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: reg `outcome' agg_wp ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_wage {
  qui xi: reg `outcome' agg_wp ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_hours {
  qui xi: reg `outcome' agg_wp ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust
  codebook `outcome', c 
  estimates table, k(agg_wp) star(.05 .01 .001)
}


          ***************************************************
            *****     M2: SIMPLE OLS: DISTRICT FE    ******
          ***************************************************

**********************
********* OLS ********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: reg `outcome' agg_wp i.district_iid ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
    codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_wage {
  qui xi: reg `outcome' agg_wp i.district_iid ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_hours {
  qui xi: reg `outcome' agg_wp i.district_iid ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

              ***************************************************
              *****         M3: YEAR FE / DISTRICT FE      ******
              ***************************************************

**********************
********* OLS ********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: reg `outcome' agg_wp i.district_iid i.year  ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
    codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_wage {
  qui xi: reg `outcome' agg_wp i.district_iid i.year  ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_hours {
  qui xi: reg `outcome' agg_wp i.district_iid i.year  ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

**********************
********* IV *********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              $controls i.educ1d i.fteducst i.mteducst  ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) ///
              first 
    codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 
  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
    estimates table, k(IHS_IV_SS)  star(.05 .01 .001) 
    drop smpl 
}

foreach outcome of global outcome_var_wage {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              $controls i.educ1d i.fteducst i.mteducst  ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) ///
              first 
    codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 
  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
    estimates table, k(IHS_IV_SS)  star(.05 .01 .001) 
    drop smpl 
}

foreach outcome of global outcome_var_hours {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              $controls i.educ1d i.fteducst i.mteducst  ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) ///
              first 
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 
  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
    estimates table, k(IHS_IV_SS)  star(.05 .01 .001) 
    drop smpl 
}


            ***********************************************************************
              ***** M4: YEAR FE / DISTRICT FE / CONTROL NUMBER OF REFUGEE   *****
            ***********************************************************************



**********************
********* OLS ********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_wage {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_hours {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

**********************
********* IV *********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              ln_ref $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table, k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
}

foreach outcome of global outcome_var_wage {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              ln_ref $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table, k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
}

foreach outcome of global outcome_var_hours {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              ln_ref $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table, k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
}



            *****************************************************************
              ******     M5:  YEAR FE / DISTRICT FE / SECOTRAL FE    ******
            *****************************************************************

**********************
********* OLS ********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year i.crsectrp ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_wage {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year i.crsectrp ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_hours {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year i.crsectrp ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

**********************
********* IV *********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid i.crsectrp ///
              $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid i.crsectrp) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid i.crsectrp ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table,  k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
}

foreach outcome of global outcome_var_wage {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid i.crsectrp ///
              $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid i.crsectrp) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid i.crsectrp ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table,  k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
}

foreach outcome of global outcome_var_hours {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid i.crsectrp ///
              $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid i.crsectrp) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid i.crsectrp ///
          $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table,  k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
}


******************************************************************************************
  *****    M6:  YEAR FE / DISTRICT FE / SECOTRAL FE / CONTROL NUMBER OF REFUGEE   ******
******************************************************************************************

**********************
********* OLS ********
**********************

foreach outcome of global outcome_var_empl {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year i.crsectrp ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_wage {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year i.crsectrp ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}

foreach outcome of global outcome_var_hours {
  qui xi: reg `outcome' agg_wp ///
          i.district_iid i.year i.crsectrp ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          [pweight = expan_indiv],  ///
          cluster(district_iid) robust 
  codebook `outcome', c
  estimates table, k(agg_wp) star(.05 .01 .001)
}


**********************
********* IV *********
**********************

*** something wrong with one variable : unempdurmth : redifine the alternative loop here
global    outcome_var_empl_alt ///
                unemployed jobless2  employed_3m  employed_1w  employed_3m_olf employed_1w_olf  ///   
                job_stability_permanent_1w job_stability_permanent_3m job_regular_1w job_regular_3m /// 
                incidence_soc_insur_1w  incidence_soc_insur_3m  incidence_wrk_contract_1w incidence_wrk_contract_3m /// 
                job_formal_1w job_formal_3m informal wp_industry_jlmps_1w wp_industry_jlmps_3m member_union_3m ///
                stability_main_job permanent_contract 

foreach outcome of global outcome_var_empl_alt {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid i.crsectrp ///
              ln_ref $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) ///
              partial(i.district_iid i.crsectrp) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid i.crsectrp ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table,  k(IHS_IV_SS) star(.05 .01 .001)           
  drop smpl 
}

foreach outcome of global outcome_var_wage {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid i.crsectrp ///
              ln_ref $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) ///
              partial(i.district_iid i.crsectrp) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid i.crsectrp ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table,  k(IHS_IV_SS) star(.05 .01 .001)           
  drop smpl 
}

foreach outcome of global outcome_var_hours {
  qui xi: ivreg2  `outcome' ///
              i.year i.district_iid i.crsectrp ///
              ln_ref $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) ///
              partial(i.district_iid i.crsectrp) ///
              first
  codebook `outcome', c
  estimates table, k(agg_wp)  star(.05 .01 .001) 

  * With equivalent first-stage
  gen smpl=0
  replace smpl=1 if e(sample)==1

  qui xi: reg agg_wp IHS_IV_SS ///
          i.year i.district_iid i.crsectrp ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst  ///
          if smpl == 1 [pweight = expan_indiv], ///
          cluster(district_iid) robust
  estimates table,  k(IHS_IV_SS) star(.05 .01 .001)           
  drop smpl 
}

                  *************************************************
                    *****     M7: YEAR FE / INDIV FE        *****
                  *************************************************



**********************
********* OLS ********
**********************

global    lm_out   unemployed

foreach outcome of global lm_out {
  reghdfe `outcome' agg_wp ///
          $controls i.educ1d i.fteducst i.mteducst ///
          [pw=expan_indiv], ///
          absorb(year indid_2010) ///
          cluster(district_iid) 
}
  
  * Then I partial out all variables
  foreach y in unemployed agg_wp $controls educ1d fteducst mteducst   {
    reghdfe `y' [pw=expan_indiv], absorb(year indid_2010) residuals(`y'_c2wr)
    rename `y' o_`y'
    rename `y'_c2wr `y'
  }

  drop unemployed $controls educ1d fteducst mteducst  agg_wp  
  
  foreach y in unemployed $controls educ1d fteducst mteducst  agg_wp  {
    rename o_`y' `y' 
  } 

  reg unemployed agg_wp  $controls [pw=expan_indiv], cluster(district_iid) robust
  
 
**********************
********* IV *********
**********************

 foreach outcome of global lm_out {
 preserve
  xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) 

  gen smpl=0
  replace smpl=1 if e(sample)==1
  * Then I partial out all variables
  foreach y in `outcome' $controls agg_wp IHS_IV_SS educ1d fteducst mteducst  {
    reghdfe `y' [pw=expan_indiv] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
    rename `y' o_`y'
    rename `y'_c2wr `y'
  }
  ivreg2 `outcome' ///
         $controls educ1d fteducst mteducst ///
         (agg_wp = IHS_IV_SS) ///
         [pweight = expan_indiv], ///
         cluster(district_iid) robust ///
         first
  drop `outcome' agg_wp IHS_IV_SS $controls educ1d fteducst mteducst smpl
  foreach y in `outcome' $controls  agg_wp IHS_IV_SS {
    rename o_`y' `y' 
  }
  restore
}



          ***********************************************************************
            *****    M8:  YEAR FE / INDIV FE / CONTROL NUMBER OF REFUGEE    *****
          ***********************************************************************

/*

**********************
********* OLS ********
**********************

foreach outcome of global lm_out {
  reghdfe `outcome' agg_wp ///
          ln_ref $controls i.educ1d i.fteducst i.mteducst ///
          [pw=expan_indiv], ///
          absorb(year indid_2010) ///
          cluster(district_iid) 
  }
  foreach outcome of global lm_out {

**********************
********* IV *********
**********************

  preserve
  xi: ivreg2  `outcome' ///
              i.year i.district_iid ///
              ln_ref $controls i.educ1d i.fteducst i.mteducst ///
              (agg_wp = IHS_IV_SS) ///
              [pweight = expan_indiv], ///
              cluster(district_iid) robust ///
              partial(i.district_iid) 

  gen smpl=0
  replace smpl=1 if e(sample)==1

  * Then I partial out all variables
  foreach y in `outcome' agg_wp IHS_IV_SS $controls ln_ref educ1d fteducst mteducst  {
    reghdfe `y' [pw=expan_indiv] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
    rename `y' o_`y'
    rename `y'_c2wr `y'
  }
  ivreg2  `outcome' ///
          ln_ref $controls educ1d fteducst mteducst ///
          (agg_wp = IHS_IV_SS) ///
          [pweight = expan_indiv], ///
          cluster(district_iid) robust ///
          first
  drop `outcome' agg_wp IHS_IV_SS $controls ln_ref educ1d fteducst mteducst smpl
  foreach y in `outcome' agg_wp IHS_IV_SS $controls ln_ref educ1d fteducst mteducst  {
    rename o_`y' `y' 
  }
  restore
}
*/


