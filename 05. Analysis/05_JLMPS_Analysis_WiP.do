

cap log close
clear all
set more off, permanently
set mem 100m

log using "$out_analysis/05_JLMPS_Analysis_WiP.log", replace

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
*adoupdate, update 
*ssc inst ivreg2, replace



tab educ1d 
tab fteducst 
tab mteducst
tab ftempst 
tab ln_nb_refugees_bygov 
tab age  // Age
tab age2 // Age square
*tab ln_invdistance_dis_camp //  LOG Inverse Distance (km) between JORD districts and ZAATARI CAMP in 2016
tab gender //  Gender - 1 Male 0 Female
tab hhsize //  Total o. of Individuals in the Household

***********************************************************************
**DEFINING THE SAMPLE *************************************************
***********************************************************************

/*%
[I suggest we partial out both variables (meaning we store 
the residuals from specification where we regress both 
variables on fixed effects and then use scatter plot, 
fitted line, and eventually a non-parametric line). 
I can show you a code].
*/

**************
* JORDANIANS *
**************

tab nationality_cl year , m 
*drop if nationality_cl != 1


***************
* WORKING AGE *
*************** 

*Keep only working age pop? 15-64 ? As defined by the ERF
drop if age > 64 & year == 2016
drop if age > 60 & year == 2010 //60 in 2010 so 64 in 2016

drop if age < 15 & year == 2016 
drop if age < 11 & year == 2010 //11 in 2010 so 15 in 2016

*18744

***************
* EMPLOYED *
*************** 

/*
Number of outcomes among the employed,

[NB: We undertook sensitivity analysis as to whether analyzing these outcomes
unconditional on employment, rather than among the employed, changed our
results; it did not lead to substantive changes (results available from authors on
request).]*/


*EMPLOYED ONLY (EITHER IN 2010 OR IN 2016

drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 
*drop if emp_10_olf_16  == 1 
*drop if emp_16_olf_10  == 1 
*drop if unemp_10_emp_16  == 1 
*drop if unemp_16_emp_10  == 1 
*drop if olf_10_unemp_16 == 1 
*drop if olf_16_unemp_10  == 1 
*/
keep if emp_16_10 == 1 

                                  ************
                                  *   PANEL  *
                                  ************

* SET THE PANEL STRUCTURE
xtset, clear 
*xtset year
destring indid_2010 Findid, replace
mdesc indid_2010
xtset indid_2010 year 



                                  ************
                                  *REGRESSION*
                                  ************

              ***************************************************
                *****         M1: SIMPLE OLS:           *******
              ***************************************************

codebook $dep_var
lab var $dep_var "Work Permits"

**********************
********* OLS ********
**********************


  foreach outcome of global outcome_cond {
    qui xi: reg `outcome' $dep_var ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            [pweight = panel_wt_10_16],  ///
            cluster(district_iid) robust 
    codebook `outcome', c
    estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
    estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
    estimates store m_`outcome', title(Model `outcome')
  }


ereturn list
mat list e(b)
estout m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w m_work_days_pweek_3m /// 
      , cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
        drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _cons $controls)   ///
   legend label varlabels(_cons constant) starlevels(* 0.1 ** 0.05 *** 0.01)  ///
   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

*** (**) [*] indicates significance at the 99%
*(95%) [90%] level. Based

*erase "$out/reg_infra_access.tex"
esttab m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w  m_work_days_pweek_3m /// 
      using "$out_analysis/reg_01_OLS.tex", se label replace booktabs ///
      cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
mtitles("Stable" "Formal" "Industry" "Union" "Skills" "Total W" "Hourly W" "WH pweek" "WD pweek") ///
        drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _cons $controls)   ///
starlevels(* 0.1 ** 0.05 *** 0.01) ///
   title("Results OLS Regression"\label{tab1}) nofloat ///
   stats(N r2_a, labels("Obs" "Adj. R-Squared" "Control Mean")) ///
    nonotes ///
    addnotes("Standard errors clustered at the district level. Significance levels: *p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01") 

estimates drop m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
       m_work_hours_pweek_3m_w m_work_days_pweek_3m 



            ***********************************************************************
              ***** M2: YEAR FE / DISTRICT FE    *****
            ***********************************************************************

**********************
********* OLS ********
**********************

  foreach outcome of global outcome_cond {
    qui xi: reg `outcome' $dep_var ///
            i.district_iid i.year ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            [pweight = panel_wt_10_16],  ///
            cluster(district_iid) robust 
    codebook `outcome', c
    estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
    estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
    estimates store m_`outcome', title(Model `outcome')
  }


ereturn list
mat list e(b)
estout m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
       m_work_hours_pweek_3m_w m_work_days_pweek_3m /// 
      , cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
        drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
        _Idistrict__2 _Idistrict__3 ///
        _Idistrict__4 _Idistrict__5 _Idistrict__6 _Idistrict__7 ///
        _Idistrict__8 _Idistrict__9 _Idistrict__10 _Idistrict__11 ///
        _Idistrict__12 _Idistrict__13 _Idistrict__14 _Idistrict__15 ///
        _Idistrict__16  _Idistrict__18 _Idistrict__19 ///
        _Idistrict__20 _Idistrict__21 _Idistrict__22 _Idistrict__23 ///
        _Idistrict__24 _Idistrict__25 _Idistrict__26 _Idistrict__27 ///
        _Idistrict__28 _Idistrict__29 _Idistrict__30 _Idistrict__31 ///
        _Idistrict__32 _Idistrict__33 _Idistrict__34 _Idistrict__35 ///
        _Idistrict__36 _Idistrict__37 _Idistrict__38 _Idistrict__39 ///
        _Idistrict__40 _Idistrict__41 _Idistrict__42 _Idistrict__43 ///
        _Idistrict__44 _Idistrict__45 _Idistrict__46 _Idistrict__47 ///
        _Idistrict__48 _Idistrict__49 _Idistrict__50 _Idistrict__51 ///
        _cons $controls)   ///
   legend label varlabels(_cons constant) starlevels(* 0.1 ** 0.05 *** 0.01)  ///
   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

*** (**) [*] indicates significance at the 99%
*(95%) [90%] level. Based

*erase "$out/reg_infra_access.tex"
esttab m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w  m_work_days_pweek_3m /// 
      using "$out_analysis/reg_02_OLS_FE_district_year.tex", se label replace booktabs ///
      cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
mtitles("Stable" "Formal" "Industry" "Union" "Skills" "Total W"  "Hourly W" "WH pday" "WD pweek") ///
        drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
        _Idistrict__2 _Idistrict__3 ///
        _Idistrict__4 _Idistrict__5 _Idistrict__6 _Idistrict__7 ///
        _Idistrict__8 _Idistrict__9 _Idistrict__10 _Idistrict__11 ///
        _Idistrict__12 _Idistrict__13 _Idistrict__14 _Idistrict__15 ///
        _Idistrict__16 _Idistrict__18 _Idistrict__19 ///
        _Idistrict__20 _Idistrict__21 _Idistrict__22 _Idistrict__23 ///
        _Idistrict__24 _Idistrict__25 _Idistrict__26 _Idistrict__27 ///
        _Idistrict__28 _Idistrict__29 _Idistrict__30 _Idistrict__31 ///
        _Idistrict__32 _Idistrict__33 _Idistrict__34 _Idistrict__35 ///
        _Idistrict__36 _Idistrict__37 _Idistrict__38 _Idistrict__39 ///
        _Idistrict__40 _Idistrict__41 _Idistrict__42 _Idistrict__43 ///
        _Idistrict__44 _Idistrict__45 _Idistrict__46 _Idistrict__47 ///
        _Idistrict__48 _Idistrict__49 _Idistrict__50 _Idistrict__51 ///
        _cons $controls)   ///
starlevels(* 0.1 ** 0.05 *** 0.01) ///
   title("Results OLS Regression with time and district FE"\label{tab1}) nofloat ///
   stats(N r2_a, labels("Obs" "Adj. R-Squared" "Control Mean")) ///
    nonotes ///
    addnotes("Standard errors clustered at the district level. Significance levels: *p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01") 

estimates drop m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
       m_work_hours_pweek_3m_w m_work_days_pweek_3m 


**********************
********* IV *********
**********************

/*
which ivreg2, all
adoupdate ivreg2, update
adoupdate ranktest, update

ado uninstall ivreg2
ssc install ivreg2
*/

**********
*REGRESSION*
************

gen ln_agg_wp_orig = ln(1+agg_wp_orig)
gen IHS_agg_wp_orig = log(agg_wp_orig + ((agg_wp_orig^2 + 1)^0.5))

gen ln_agg_wp = ln(1+agg_wp)
gen IHS_agg_wp = log(agg_wp + ((agg_wp^2 + 1)^0.5))

gen resc_agg_wp_orig = agg_wp_orig*10000
gen resc_IV_SS_5 = IV_SS_5/1000000
global dep_var agg_wp_orig
global IV_var  resc_IV_SS_5

  foreach outcome of global outcome_cond {
    xi: ivreg2  `outcome' ///
                i.district_iid i.year ///
                $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                ($dep_var = $IV_var) ///
                [pweight = panel_wt_10_16], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) ///
                first
    codebook `outcome', c
    estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
    estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
    estimates store m_`outcome', title(Model `outcome')

    * With equivalent first-stage
    gen smpl=0
    replace smpl=1 if e(sample)==1

    xi: reg $dep_var $IV_var ///
            i.year i.district_iid ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            if smpl == 1 [pweight = panel_wt_10_16], ///
            cluster(district_iid) robust
    estimates table, k($IV_var) star(.1 .05 .01)    
    estimates store mIV_`outcome', title(Model `outcome')

    drop smpl 
  }



ereturn list
mat list e(b)
estout m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w m_work_days_pweek_3m ///
      , cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
         $controls)   ///
   legend label varlabels(_cons constant) starlevels(* 0.1 ** 0.05 *** 0.01)           ///
   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

*** (**) [*] indicates significance at the 99%
*(95%) [90%] level. Based

*erase "$out/reg_infra_access.tex"
esttab m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w m_work_days_pweek_3m /// 
      using "$out_analysis/reg_03_IV_FE_district_year.tex", se label replace booktabs ///
      cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
mtitles("Stable" "Formal" "Industry" "Union" "Skills" "Total W"  "Hourly W" "WH pday" "WD pweek") ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
         $controls) starlevels(* 0.1 ** 0.05 *** 0.01) ///
   title("Results IV Regression with District and Year FE"\label{tab1}) nofloat ///
   stats(N r2_a , labels("Obs" "Adj. R-Squared" "Control Mean")) ///
    nonotes ///
    addnotes("Standard errors clustered at the district level. Significance levels: *p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01") 

estimates drop m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
       m_work_hours_pweek_3m_w m_work_days_pweek_3m 
*m2 m3 m4 m5 

ereturn list
mat list e(b)
estout mIV_job_stable_3m mIV_formal mIV_wp_industry_jlmps_3m ///
      mIV_member_union_3m mIV_skills_required_pjob  ///
      mIV_ln_total_rwage_3m  mIV_ln_hourly_rwage ///
       mIV_work_hours_pweek_3m_w mIV_work_days_pweek_3m /// 
       , cells(b(star fmt(%9.1f)) se(par fmt(%9.1f))) ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
        _Idistrict__2 _Idistrict__3 ///
        _Idistrict__4 _Idistrict__5 _Idistrict__6 _Idistrict__7 ///
        _Idistrict__8 _Idistrict__9 _Idistrict__10 _Idistrict__11 ///
        _Idistrict__12 _Idistrict__13 _Idistrict__14 _Idistrict__15 ///
        _Idistrict__16 _Idistrict__18 _Idistrict__19 ///
        _Idistrict__20 _Idistrict__21 _Idistrict__22 _Idistrict__23 ///
        _Idistrict__24 _Idistrict__25 _Idistrict__26 _Idistrict__27 ///
        _Idistrict__28 _Idistrict__29 _Idistrict__30 _Idistrict__31 ///
        _Idistrict__32 _Idistrict__33 _Idistrict__34 _Idistrict__35 ///
        _Idistrict__36 _Idistrict__37 _Idistrict__38 _Idistrict__39 ///
        _Idistrict__40 _Idistrict__41 _Idistrict__42 _Idistrict__43 ///
        _Idistrict__44 _Idistrict__45 _Idistrict__46 _Idistrict__47 ///
        _Idistrict__48 _Idistrict__49 _Idistrict__50 _Idistrict__51 ///
        _cons $controls)   ///
   legend label varlabels(_cons constant) starlevels(* 0.1 ** 0.05 *** 0.01)           ///
   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

*** (**) [*] indicates significance at the 99%
*(95%) [90%] level. Based

*erase "$out/reg_infra_access.tex"
esttab mIV_job_stable_3m mIV_formal mIV_wp_industry_jlmps_3m ///
      mIV_member_union_3m mIV_skills_required_pjob  ///
      mIV_ln_total_rwage_3m  mIV_ln_hourly_rwage ///
      mIV_work_hours_pweek_3m_w mIV_work_days_pweek_3m /// 
      using "$out_analysis/reg_03_IV_FE_district_year_stage1.tex", se label replace booktabs ///
      cells(b(star fmt(%9.1f)) se(par fmt(%9.1f))) ///
mtitles("Stable" "Formal" "Industry" "Union" "Skills" "Total W"  "Hourly W" "WH pday" "WD pweek") ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
        _Idistrict__2 _Idistrict__3 ///
        _Idistrict__4 _Idistrict__5 _Idistrict__6 _Idistrict__7 ///
        _Idistrict__8 _Idistrict__9 _Idistrict__10 _Idistrict__11 ///
        _Idistrict__12 _Idistrict__13 _Idistrict__14 _Idistrict__15 ///
        _Idistrict__16 _Idistrict__18 _Idistrict__19 ///
        _Idistrict__20 _Idistrict__21 _Idistrict__22 _Idistrict__23 ///
        _Idistrict__24 _Idistrict__25 _Idistrict__26 _Idistrict__27 ///
        _Idistrict__28 _Idistrict__29 _Idistrict__30 _Idistrict__31 ///
        _Idistrict__32 _Idistrict__33 _Idistrict__34 _Idistrict__35 ///
        _Idistrict__36 _Idistrict__37 _Idistrict__38 _Idistrict__39 ///
        _Idistrict__40 _Idistrict__41 _Idistrict__42 _Idistrict__43 ///
        _Idistrict__44 _Idistrict__45 _Idistrict__46 _Idistrict__47 ///
        _Idistrict__48 _Idistrict__49 _Idistrict__50 _Idistrict__51 ///
        _cons $controls) starlevels(* 0.1 ** 0.05 *** 0.01) ///
   title("Results Stage 1 IV Regression with District and Year FE"\label{tab1}) nofloat ///
   stats(N r2_a , labels("Obs" "Adj. R-Squared" "Control Mean")) ///
    nonotes ///
    addnotes("Standard errors clustered at the district level. Significance levels: *p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01") 

estimates drop mIV_job_stable_3m mIV_formal mIV_wp_industry_jlmps_3m ///
      mIV_member_union_3m mIV_skills_required_pjob  ///
      mIV_ln_total_rwage_3m  mIV_ln_hourly_rwage ///
       mIV_work_hours_pweek_3m_w mIV_work_days_pweek_3m 


******************************************************************************************
  *****    M3:  YEAR FE / DISTRICT FE / SECOTRAL FE    ******
******************************************************************************************

**********************
********* OLS ********
**********************
/*
foreach globals of global globals_list {
  foreach outcome of global `globals' {
    qui xi: reg `outcome' $dep_var ///
            i.district_iid i.year i.private ///
             $controls i.educ1d i.fteducst i.mteducst i.ftempst  ///
            [pweight = panel_wt_10_16],  ///
            cluster(district_iid) robust 
    codebook `outcome', c
    estimates table, k($dep_var) star(.1 .05 .01)
  }
}
*/
**********************
********* IV *********
**********************

  foreach outcome of global outcome_cond {
    xi: ivreg2  `outcome' ///
                i.year i.district_iid i.private ///
                $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                ($dep_var = $IV_var) ///
                [pweight = panel_wt_10_16], ///
                cluster(district_iid) ///
                partial(i.district_iid i.private) ///
                first
    codebook `outcome', c
    estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
    estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
    estimates store m_`outcome', title(Model `outcome')

    * With equivalent first-stage
    gen smpl=0
    replace smpl=1 if e(sample)==1

    qui xi: reg $dep_var $IV_var ///
            i.year i.district_iid i.private ///
            $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
            if smpl == 1 [pweight = panel_wt_10_16], ///
            cluster(district_iid) robust
    estimates table,  k($IV_var) star(.1 .05 .01)          
    drop smpl 
  }


ereturn list
mat list e(b)
estout m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w m_work_days_pweek_3m ///
      , cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
         $controls)   ///
   legend label varlabels(_cons constant) starlevels(* 0.1 ** 0.05 *** 0.01)           ///
   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

*** (**) [*] indicates significance at the 99%
*(95%) [90%] level. Based

*erase "$out/reg_infra_access.tex"
esttab m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w m_work_days_pweek_3m /// 
      using "$out_analysis/reg_04_IV_FE_district_year_sector.tex", se label replace booktabs ///
      cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
mtitles("Stable" "Formal" "Industry" "Union" "Skills" "Total W"  "Hourly W" "WH pday" "WD pweek") ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        ln_nb_refugees_bygov _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6 _Iyear_2016 ///
         $controls) starlevels(* 0.1 ** 0.05 *** 0.01) ///
   title("Results IV Regression with District, Year and Sector FE"\label{tab1}) nofloat ///
   stats(N r2_a , labels("Obs" "Adj. R-Squared" "Control Mean")) ///
    nonotes ///
    addnotes("Standard errors clustered at the district level. Significance levels: *p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01") 

estimates drop m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
       m_work_hours_pweek_3m_w m_work_days_pweek_3m 


          ***********************************************************************
            *****    M4:  YEAR FE / INDIV FE     *****
          ***********************************************************************

**********************
********* OLS ********
**********************
/*
preserve
foreach globals of global globals_list {
  foreach outcome_l1 of global `globals' {
      foreach outcome_l2 of global  `globals' {
       qui reghdfe `outcome_l2' $dep_var ///
                $controls i.educ1d i.fteducst i.mteducst i.ftempst  ///
                [pw=panel_wt_10_16], ///
                absorb(year indid_2010) ///
                cluster(district_iid) 
      }
        * Then I partial out all variables
      foreach y in `outcome_l1' $dep_var $controls  educ1d fteducst mteducst ftempst  {
        qui reghdfe `y' [pw=panel_wt_10_16], absorb(year indid_2010) residuals(`y'_c2wr)
        rename `y' o_`y'
        rename `y'_c2wr `y'
      }
      drop `outcome_l1' $controls  educ1d fteducst mteducst ftempst  $dep_var  
      foreach y in `outcome_l1' $controls  educ1d fteducst mteducst ftempst  $dep_var  {
        rename o_`y' `y' 
      } 
      qui reg `outcome_l1' $dep_var $controls i.educ1d i.fteducst i.mteducst i.ftempst  [pw=panel_wt_10_16], cluster(district_iid) robust
      codebook `outcome_l1', c
      estimates table,  k($dep_var) star(.1 .05 .01)           
    }
  }
restore
*/

*ivreg2hdfe 

**********************
********* IV *********
**********************

preserve
  foreach outcome of global outcome_cond {     
      codebook `outcome', c
       xi: ivreg2 `outcome' ///
                    i.year i.district_iid ///
                    $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                    ($dep_var = $IV_var) ///
                    [pweight = panel_wt_10_16], ///
                    cluster(district_iid) robust ///
                    partial(i.district_iid) 

        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
        foreach y in `outcome' $controls $dep_var $IV_var educ1d fteducst mteducst ftempst ln_nb_refugees_bygov {
          qui reghdfe `y' [pw=panel_wt_10_16] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
          qui rename `y' o_`y'
          qui rename `y'_c2wr `y'
        }
        ivreg2 `outcome' ///
               $controls educ1d fteducst mteducst ftempst ln_nb_refugees_bygov ///
               ($dep_var = $IV_var) ///
               [pweight = panel_wt_10_16], ///
               cluster(district_iid) robust ///
               first 
      estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
      estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
      estimates store m_`outcome', title(Model `outcome')
        qui drop `outcome' $dep_var $IV_var $controls educ1d fteducst mteducst ftempst smpl ln_nb_refugees_bygov
        foreach y in `outcome' $controls  $dep_var $IV_var educ1d fteducst mteducst ftempst ln_nb_refugees_bygov  {
          qui rename o_`y' `y' 
        }
    }
restore                


ereturn list
mat list e(b)
estout m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w m_work_days_pweek_3m  ///
      , cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
  drop(age age2 gender hhsize educ1d fteducst mteducst ftempst _cons ///
       ln_nb_refugees_bygov  $controls)   ///
   legend label varlabels(_cons constant) starlevels(* 0.1 ** 0.05 *** 0.01)           ///
   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

*** (**) [*] indicates significance at the 99%
*(95%) [90%] level. Based

esttab m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
      m_work_hours_pweek_3m_w m_work_days_pweek_3m  ///
      using "$out_analysis/reg_05_IV_FE_year_indiv.tex", se label replace booktabs ///
      cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
mtitles("Stable" "Formal" "Industry" "Union" "Skills" "Total W"  "Hourly W" "WH pday" "WD pweek") ///
 drop(age age2 gender hhsize  educ1d fteducst mteducst ftempst ///
     _cons ///
       ln_nb_refugees_bygov  $controls) starlevels(* 0.1 ** 0.05 *** 0.01) ///
   title("Results IV Regression with Year and Individual FE"\label{tab1}) nofloat ///
   stats(N r2_a, labels("Obs" "Adj. R-Squared" "Control Mean")) ///
    nonotes ///
    addnotes("Standard errors clustered at the district level. Significance levels: *p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01") 

estimates drop m_job_stable_3m m_formal m_wp_industry_jlmps_3m ///
      m_member_union_3m m_skills_required_pjob  ///
      m_ln_total_rwage_3m  m_ln_hourly_rwage ///
       m_work_hours_pweek_3m_w m_work_days_pweek_3m 








/*
************************************************
// ANALYSIS EMPLOYED / UNEMPLOYED USING MODEL 4 
************************************************

            ***********************************************************************
              ***** M2: YEAR FE / DISTRICT FE /   *****
            ***********************************************************************

use "$data_final/06_IV_JLMPS_Construct_Outcomes.dta", clear

tab nationality_cl year 
*drop if nationality_cl != 1

drop if age > 64 & year == 2016
drop if age > 60 & year == 2010 //60 in 2010 so 64 in 2016

drop if age < 15 & year == 2016 
drop if age < 11 & year == 2010 //11 in 2010 so 15 in 2016


*drop if miss_16_10 == 1
*drop if unemp_16_10 == 1
*drop if olf_16_10 == 1
*drop if emp_16_miss_10 == 1
*drop if emp_10_miss_16 == 1
*drop if unemp_16_miss_10 == 1
*drop if unemp_10_miss_16 == 1
*drop if olf_16_miss_10 == 1
*drop if olf_10_miss_16 == 1 
*drop if emp_10_olf_16  == 1 
*drop if emp_16_olf_10  == 1 
*drop if unemp_10_emp_16  == 1 
*drop if unemp_16_emp_10  == 1 
*drop if olf_10_unemp_16 == 1 
*drop if olf_16_unemp_10  == 1 


            ***********************************************************************
              ***** M2: YEAR FE / DISTRICT FE /   *****
            ***********************************************************************


**********************
********* IV *********
**********************

  foreach outcome of global outcome_uncond {
    qui xi: ivreg2  `outcome' ///
                i.year i.district_iid ///
                $controls i.educ1d i.fteducst i.mteducst i.ftempst  ///
                ($dep_var = IV_SS_5) ///
                [pweight = panel_wt_10_16], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) ///
                first
    codebook `outcome', c
    estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
    estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
    estimates store m_`outcome', title(Model `outcome')
  }

ereturn list
mat list e(b)
estout m_employed_3m m_unemployed_3m m_unempdurmth  ///
    m_ln_b_rwage_unolf m_ln_b_rwage_unemp m_ln_t_rwage_unolf ///
    m_ln_t_rwage_unemp ///
      , cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6  _Iyear_2016 ///
         $controls)   ///
   legend label varlabels(_cons constant) starlevels(* 0.1 ** 0.05 *** 0.01)           ///
   stats(r2 df_r bic, fmt(3 0 1) label(R-sqr dfres BIC))

*** (**) [*] indicates significance at the 99%
*(95%) [90%] level. Based

*erase "$out/reg_infra_access.tex"
esttab m_employed_3m m_unemployed_3m m_unempdurmth  ///
    m_ln_b_rwage_unolf m_ln_b_rwage_unemp m_ln_t_rwage_unolf ///
    m_ln_t_rwage_unemp ///
      using "$out_analysis/reg_03_IV_FE_district_year_empl.tex", se label replace booktabs ///
      cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
mtitles("Employed" "Unemployed" "Duration Unemp" "Basic W OLF" "Basic W" "Total W OLF" "Total W") ///
  drop(age age2 gender hhsize _Ieduc1d_2 _Ieduc1d_3 _Ieduc1d_4 _Ieduc1d_5 ///
        _Ieduc1d_6 _Ieduc1d_7 _Ifteducst_2 ///
        _Ifteducst_3 _Ifteducst_4 _Ifteducst_5 _Ifteducst_6 ///
        _Imteducst_2 _Imteducst_3 _Imteducst_4 _Imteducst_5 ///
        _Imteducst_6 _Iftempst_2 _Iftempst_3 _Iftempst_4 _Iftempst_5 ///
        _Iftempst_6  _Iyear_2016 ///
         $controls) starlevels(* 0.1 ** 0.05 *** 0.01) ///
   title("Results IV Regression with District and Year FE"\label{tab1}) nofloat ///
   stats(N r2_a , labels("Obs" "Adj. R-Squared" "Control Mean")) ///
    nonotes ///
    addnotes("Standard errors clustered at the district level. Significance levels: *p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01") 

estimates drop m_employed_3m m_unemployed_3m m_unempdurmth  ///
    m_ln_b_rwage_unolf m_ln_b_rwage_unemp m_ln_t_rwage_unolf ///
    m_ln_t_rwage_unemp 


*/

************************************************
//  SUMMARY STATISTICS
************************************************




use "$data_final/06_IV_JLMPS_Construct_Outcomes.dta", clear


bys year: su $dep_var 
bys year: su IV_SS_5

drop if nationality_cl != 1
drop if age > 64 & year == 2016
drop if age > 60 & year == 2010 //60 in 2010 so 64 in 2016
drop if age < 15 & year == 2016 
drop if age < 11 & year == 2010 //11 in 2010 so 15 in 2016

drop if miss_16_10 == 1
*drop if emp_16_miss_10 == 1
*drop if emp_10_miss_16 == 1
*drop if unemp_16_miss_10 == 1
*drop if unemp_10_miss_16 == 1
*drop if olf_16_miss_10 == 1
*drop if olf_10_miss_16 == 1 

bys year: su unempdurmth  // Current unemployment duration (in months)
bys year: tab unempdurmth  // Current unemployment duration (in months)

codebook employed_3m
recode employed_3m (1=0) (2=1)
lab def employed_3m 0 "Unemployed" 1 "Employed", modify
lab val employed_3m employed_3m
tab employed_3m
bys year: su employed_3m  // From uswrkstsr1 - mkt def, search req; 3m, 2 empl - 1 unemp - OLF miss

/*
drop if unemp_16_10 == 1
drop if olf_16_10 == 1

drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 
*/

keep if emp_16_10 == 1 


bys year: su job_stable_3m //  From usstablp - Stability of employement (3m) - 1 permanent - 0 temp, seas, cas
bys year: su formal  // 0 Informal - 1 Formal - Informal if no contract (uscontrp=0) OR no insurance (ussocinsp=0)
bys year: su wp_industry_jlmps_3m  // Industries with work permits for refugees - Economic Activity of prim. job 3m
bys year: su member_union_3m // Member of a syndicate/trade union (ref. 3-mnths)
bys year: su skills_required_pjob //  Does primary job require any skill
  
bys year: su real_basic_wage_3m  //  Basic Wage (3-month) - CONDITIONAL - UNEMPLOYED & OLF: WAGE MISSING
bys year: su real_total_wage_3m  //  Total Wage (3-month) - CONDITIONAL - UNEMPLOYED & OLF: WAGE MISSING
bys year: su real_monthly_wage //  Monthly Wage (Prim.& Second. Jobs)
bys year: su real_hourly_wage  //  Hourly Wage (Prim.& Second. Jobs)

bys year: su work_hours_pday_3m_w  // Winsorized - No. of Hours/Day (Ref. 3 mnths) Market Work
bys year: su work_hours_pweek_3m_w  // Winsorized - Usual No. of Hours/Week, Market Work, (Ref. 3-month)
bys year: su work_days_pweek_3m  // Avg. num. of wrk. days per week during 3 mnth.
  
bys year: su age 
bys year: su gender
bys year: su hhsize 
bys year: su distance_dis_camp //  LOG Distance (km) between JORD districts and ZAATARI CAMP in 2016
bys year: su nb_refugees_bygov // LOG Number of refugees out of camps by governorate in 2016
bys year: su educ1d //  Education Levels (1-digit)
bys year: su fteducst //  Father's Level of education attained
bys year: su mteducst //  Mother's Level of education attained
bys year: su ftempst //  Father's Employment Status (When Resp. 15)


*restore









************************************************
// ALL THE IVS
************************************************

use "$data_final/06_IV_JLMPS_Construct_Outcomes.dta", clear


xtset, clear 
destring indid_2010 Findid, replace
mdesc indid_2010
xtset indid_2010 year 

codebook $dep_var
lab var $dep_var "Work Permits"

global iv_check_uncond  employed_3m unemployed_olf_3m ///
                        ln_t_rwage_unemp ln_hourly_rwage_unemp work_hours_pday_3m_w_unemp

gen ln_work_hours_pweek_3m_w = ln(1+ work_hours_pweek_3m_w)
gen ln_work_hours_pday_3m_w = ln(1+ work_hours_pday_3m_w)

global iv_check_cond    formal ln_total_rwage_3m ln_hourly_rwage ///
                        work_hours_pweek_3m_w ///
                        work_hours_pday_3m_w 

global IVs IV_SS_1 IV_SS_2 IV_SS_3 IV_SS_4 IV_SS_5

***************
*   SAMPLE *
*************** 

tab nationality_cl year 
*drop if nationality_cl != 1

*Keep only working age pop? 15-64 ? As defined by the ERF
drop if age > 64 & year == 2016
drop if age > 60 & year == 2010 //60 in 2010 so 64 in 2016

drop if age < 15 & year == 2016 
drop if age < 11 & year == 2010 //11 in 2010 so 15 in 2016

drop if miss_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 


cls 

foreach IV of global IVs {
    codebook `IV', c
        xi: ivreg2  ln_t_rwage_unemp ///
                    i.district_iid i.year ///
                    $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                    ($dep_var = `IV') ///
                    [pweight = panel_wt_10_16], ///
                    cluster(district_iid) robust ///
                    partial(i.district_iid) 
      }


***************************
* UNCONDITIONAL VARIABLES *
***************************

cls 

foreach IV of global IVs {
    codebook `IV', c
      foreach outcome of global iv_check_uncond {
        qui xi: ivreg2  `outcome' ///
                    i.district_iid i.year ///
                    $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                    ($dep_var = `IV') ///
                    [pweight = panel_wt_10_16], ///
                    cluster(district_iid) robust ///
                    partial(i.district_iid) 
        codebook `outcome', c
        estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
        estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
      }
    }


***************************
* CONDITIONAL VARIABLES *
***************************

*drop if miss_16_10 == 1
*drop if unemp_16_10 == 1
*drop if olf_16_10 == 1
*drop if emp_16_miss_10 == 1
*drop if emp_10_miss_16 == 1
*drop if unemp_16_miss_10 == 1
*drop if unemp_10_miss_16 == 1
*drop if olf_16_miss_10 == 1
*drop if olf_10_miss_16 == 1 
*drop if olf_16_10  == 1 
*drop if olf_10_unemp_16 == 1 
*drop if olf_16_unemp_10  == 1 

drop if emp_16_olf_10  == 1 //971
drop if unemp_10_emp_16  == 1 //246
drop if unemp_16_emp_10  == 1 //233


cls 

foreach IV of global IVs {
    codebook `IV', c
      foreach outcome of global iv_check_cond {
        qui xi: ivreg2  `outcome' ///
                    i.district_iid i.year ///
                    $controls i.educ1d i.fteducst i.mteducst i.ftempst ln_nb_refugees_bygov ///
                    ($dep_var = `IV') ///
                    [pweight = panel_wt_10_16], ///
                    cluster(district_iid) robust ///
                    partial(i.district_iid) 
        codebook `outcome', c
        estimates table, k($dep_var) star(.1 .05 .01) b(%7.4f) 
        estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var) 
      }
    }

 


log close


