

cap log close
clear all
set more off, permanently
set mem 100m

log using "$out_JLMPS/02_Analysis_select_models.log", replace

   ****************************************************************************
   **                            DATA JLMPS                                  **
   **                 REGRESSION ANALYSIS - V2 FOR TRIALS                    **  
   ** ---------------------------------------------------------------------- **
   ** Type Do  :  DATA JLMPS   REGRESSION ANALYSIS                           **
   **                                                                        **
   ** Authors  : Julie Bousquet                                              **
   ****************************************************************************


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


***************
* EMPLOYED *
*************** 

/*
Number of outcomes among the employed,

[NB: We undertook sensitivity analysis as to whether analyzing these outcomes
unconditional on employment, rather than among the employed, changed our
results; it did not lead to substantive changes (results available from authors on
request).]*/

tab employed_3m, m
codebook employed_3m
keep if employed_3m == 2

*********************************************************************
*********************************************************************

                              ************
                              *  GLOBALS *
                              ************

global    outcome_var_empl ///
              unemployed_3m /// From unempsr1m - mrk def, search req; 3m, empl or unemp, OLF is miss
              unempdurmth  ///  Current unemployment duration (in months)
              employed_3m  ///From uswrkstsr1 - mkt def, search req; 3m, 2 empl - 1 unemp - OLF miss

global    outcome_var_job ///
              job_stability_permanent_3m ///  From usstablp - Stability of employement (3m) - 1 permanent - 0 temp, seas, cas
              informal  /// 1 Informal - 0 Formal - Informal if no contract (uscontrp=0) and no insurance (ussocinsp=0)
              wp_industry_jlmps_3m  /// Industries with work permits for refugees - Economic Activity of prim. job 3m
              member_union_3m /// Member of a syndicate/trade union (ref. 3-mnths)
              skills_required_pjob //  Does primary job require any skill
  
global    outcome_var_wage ///
              IHS_basic_rwage_3m  /// IHS Basic Wage (3-month) - CONDITIONAL - UNEMPLOYED & OLF: WAGE MISSING
              IHS_total_rwage_3m  /// IHS Total Wage (3-month) - CONDITIONAL - UNEMPLOYED & OLF: WAGE MISSING
              IHS_monthly_rwage /// IHS Monthly Wage (Prim.& Second. Jobs)
              IHS_hourly_rwage  /// IHS Hourly Wage (Prim.& Second. Jobs)
              IHS_daily_rwage_irregular // IHS Average Daily Wage (Irregular Workers)

global    outcome_var_hours ///
              work_hours_pday_3m_w  /// Winsorized - No. of Hours/Day (Ref. 3 mnths) Market Work
              work_hours_pweek_3m_w  /// Winsorized - Usual No. of Hours/Week, Market Work, (Ref. 3-month)
              work_days_pweek_3m  /// Avg. num. of wrk. days per week during 3 mnth.
              work_hours_pm_informal_w  //  Winsorized - Average worked hour per month for irregular job
  
global    globals_list ///
            outcome_var_job outcome_var_wage outcome_var_hours

global controls ///
          age  /// Age
          age2 /// Age square
          gender ///  Gender - 1 Male 0 Female
          hhsize //  Total No. of Individuals in the Household
     *     ln_distance_dis_camp //  LOG Distance (km) between JORD districts and ZAATARI CAMP in 2016

/*SPECIAL TREATMENTS
          ln_nb_refugees_bygov /// LOG Number of refugees out of camps by governorate in 2016
          educ1d ///  Education Levels (1-digit)
          fteducst ///  Father's Level of education attained
          mteducst ///  Mother's Level of education attained
          ftempst ///  Father's Employment Status (When Resp. 15)

*/


tab educ1d 
tab fteducst 
tab mteducst
tab ftempst 
tab ln_nb_refugees_bygov 
tab age  // Age
tab age2 // Age square
tab ln_distance_dis_camp //  LOG Distance (km) between JORD districts and ZAATARI CAMP in 2016
tab gender //  Gender - 1 Male 0 Female
tab hhsize //  Total o. of Individuals in the Household



                                  ************
                                  *   PANEL  *
                                  ************

* SET THE PANEL STRUCTURE
xtset, clear 
*xtset year
xtset indid_2010 year 

                                  ************
                                  *REGRESSION*
                                  ************

              ***************************************************
                *****         M1: SIMPLE OLS:           *******
              ***************************************************

**********************
********* OLS ********
**********************

foreach globals of global globals_list {
  foreach outcome of global `globals' {
    qui xi: reg `outcome' agg_wp ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            [pweight = expan_indiv],  ///
            cluster(district_iid) robust 
    codebook `outcome', c
    estimates table, k(agg_wp) star(.05 .01 .001)
  }
}


            ***********************************************************************
              ***** M4: YEAR FE / DISTRICT FE / CONTROL NUMBER OF REFUGEE   *****
            ***********************************************************************

**********************
********* OLS ********
**********************

foreach globals of global globals_list {
  foreach outcome of global `globals' {
    qui xi: reg `outcome' agg_wp ///
            i.district_iid i.year ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            [pweight = expan_indiv],  ///
            cluster(district_iid) robust 
    codebook `outcome', c
    estimates table, k(agg_wp) star(.05 .01 .001)
  }
}

**********************
********* IV *********
**********************

foreach globals of global globals_list {
  foreach outcome of global `globals' {
    qui xi: ivreg2  `outcome' ///
                i.year i.district_iid ///
                $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                (agg_wp = IHS_IV_SS) ///
                [pweight = expan_indiv], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) ///
                first
    codebook `outcome', c
    estimates table,  k(agg_wp) star(.05 .01 .001) 

    * With equivalent first-stage
    gen smpl=0
    replace smpl=1 if e(sample)==1

    qui xi: reg agg_wp IHS_IV_SS ///
            i.year i.district_iid ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            if smpl == 1 [pweight = expan_indiv], ///
            cluster(district_iid) robust
    estimates table, k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
  }
}

******************************************************************************************
  *****    M6:  YEAR FE / DISTRICT FE / SECOTRAL FE / CONTROL NUMBER OF REFUGEE   ******
******************************************************************************************

**********************
********* OLS ********
**********************

foreach globals of global globals_list {
  foreach outcome of global `globals' {
    qui xi: reg `outcome' agg_wp ///
            i.district_iid i.year i.crsectrp ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            [pweight = expan_indiv],  ///
            cluster(district_iid) robust 
    codebook `outcome', c
    estimates table, k(agg_wp) star(.05 .01 .001)
  }
}

**********************
********* IV *********
**********************

foreach globals of global globals_list {
  foreach outcome of global `globals' {
    qui xi: ivreg2  `outcome' ///
                i.year i.district_iid i.crsectrp ///
                $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
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
            $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            if smpl == 1 [pweight = expan_indiv], ///
            cluster(district_iid) robust
    estimates table,  k(IHS_IV_SS) star(.05 .01 .001)           
    drop smpl 
  }
}

          ***********************************************************************
            *****    M8:  YEAR FE / INDIV FE / CONTROL NUMBER OF REFUGEE    *****
          ***********************************************************************

**********************
********* OLS ********
**********************

preserve
foreach globals of global globals_list {
  foreach outcome_l1 of global `globals' {
      foreach outcome_l2 of global  `globals' {
       qui reghdfe `outcome_l2' agg_wp ///
                $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                [pw=expan_indiv], ///
                absorb(year indid_2010) ///
                cluster(district_iid) 
      }
        * Then I partial out all variables
      foreach y in `outcome_l1' agg_wp $controls  educ1d fteducst mteducst ftempst ln_nb_refugees_bygov {
        qui reghdfe `y' [pw=expan_indiv], absorb(year indid_2010) residuals(`y'_c2wr)
        rename `y' o_`y'
        rename `y'_c2wr `y'
      }
      drop `outcome_l1' $controls  educ1d fteducst mteducst ftempst ln_nb_refugees_bygov agg_wp  
      foreach y in `outcome_l1' $controls  educ1d fteducst mteducst ftempst ln_nb_refugees_bygov agg_wp  {
        rename o_`y' `y' 
      } 
      qui reg `outcome_l1' agg_wp $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov [pw=expan_indiv], cluster(district_iid) robust
      codebook `outcome_l1', c
      estimates table,  k(agg_wp) star(.05 .01 .001)           
    }
  }
restore


**********************
********* IV *********
**********************

preserve
foreach globals of global globals_list {
  foreach outcome_l1 of global `globals'  {     
      codebook `outcome_l1', c
      qui xi: ivreg2 `outcome_l1' ///
                    i.year i.district_iid ///
                    $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                    (agg_wp = IHS_IV_SS) ///
                    [pweight = expan_indiv], ///
                    cluster(district_iid) robust ///
                    partial(i.district_iid) 

        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
        foreach y in `outcome_l1' $controls agg_wp IHS_IV_SS educ1d fteducst mteducst ftempst ln_nb_refugees_bygov {
          qui reghdfe `y' [pw=expan_indiv] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
          qui rename `y' o_`y'
          qui rename `y'_c2wr `y'
        }
        qui ivreg2 `outcome_l1' ///
               $controls educ1d fteducst mteducst ftempst ln_nb_refugees_bygov ///
               (agg_wp = IHS_IV_SS) ///
               [pweight = expan_indiv], ///
               cluster(district_iid) robust ///
               first
        estimates table, k(agg_wp)  star(.05 .01 .001) 
        qui drop `outcome_l1' agg_wp IHS_IV_SS $controls educ1d fteducst mteducst ftempst smpl ln_nb_refugees_bygov
        foreach y in `outcome_l1' $controls  agg_wp IHS_IV_SS educ1d fteducst mteducst ftempst ln_nb_refugees_bygov  {
          qui rename o_`y' `y' 
        }
    }
  }
restore                



log close


** HETEROG 

codebook employed_3cat_3m
foreach globals of global globals_list {
  foreach outcome of global `globals'  {  
    gen cons=1
    qui xi: ivreg2  `outcome'  ///
       i.year i.district_iid ///
       $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
       (c.agg_wp#i.wp_industry_jlmps_3m = c.IHS_IV_SS#i.wp_industry_jlmps_3m) ///
       c.cons#i.wp_industry_jlmps_3m ///       
       [pweight = expan_indiv], ///
       cluster(district_iid) robust ///
       partial(i.district_iid) ///
       first
    codebook `outcome', c
    estimates table,  k(wp_industry_jlmps_3m#c.agg_wp) star(.05 .01 .001) 
    drop cons
  } 
}
