

cap log close
clear all
set more off, permanently
set mem 100m

*log using "$out_analysis/14_IVWP_Analysis.log", replace

   ****************************************************************************
   **                            DATA IV WP                                  **
   **                          MERGING RESULTS                               **  
   ** ---------------------------------------------------------------------- **
   ** Type Do  :  DATA JLMPS - FALLAH ET AL INSTRU                           **
   **                                                                        **
   ** Authors  : Julie Bousquet                                              **
   ****************************************************************************


                  ******************
                  ** WORK PERMITS **
                  ******************

                  

use "$data_final/07_IV_Ref_WP.dta", clear

tab nationality_cl year 
drop if nationality_cl != 1
*keep if gender == 1 

drop if age > 64 & year == 2016
drop if age > 60 & year == 2010 //60 in 2010 so 64 in 2016

drop if age < 15 & year == 2016 
drop if age < 11 & year == 2010 //11 in 2010 so 15 in 2016


/*ONLY THOSE WHO WERE SURVEYED IN BOTH PERIODS?*/

/*
distinct indid_2010 
duplicates tag indid_2010, gen(dup)
bys year: tab dup
drop if dup == 0
drop dup
tab year
*/

xtset, clear 
xtset indid_2010 year 



**** OTHER TRIES WITH TWO MODELS 

******* REFUGEE INFLOW ********

*OLS_Y_D
foreach outcome of global outcomes_uncond {
    qui xi: reg `outcome' $dep_var_ref ///
            i.district_iid i.year $controls_SR  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFOLS_YD_`outcome'
} 

preserve


drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

foreach outcome of global outcomes_cond {
    qui xi: reg `outcome' $dep_var_ref ///
            i.district_iid i.year $controls_SR  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFOLS_YD_`outcome'
} 
restore

*OLS_Y_I
preserve
  foreach outcome of global outcomes_uncond {
       qui reghdfe `outcome' $dep_var_ref $controls_SR  ///
                [pw = $weight], ///
                absorb(year indid_2010) ///
                cluster(district_iid) 
      
        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
      foreach y in `outcome' $dep_var_ref  $controls_SR {
        qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
        rename `y' o_`y'
        rename `y'_c2wr `y'
      }
      
      qui reg `outcome' $dep_var_ref $controls_SR [pw = $weight], cluster(district_iid) robust
      estimates store REFOLS_YI_`outcome', title(Model `outcome')

      drop `outcome' $controls_SR $dep_var_ref smpl
      
      foreach y in `outcome' $controls_SR $dep_var_ref  {
        rename o_`y' `y' 
      } 
    }
restore

preserve

drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

  foreach outcome of global outcomes_cond {
       qui reghdfe `outcome' $dep_var_ref $controls_SR  ///
                [pw = $weight], ///
                absorb(year indid_2010) ///
                cluster(district_iid) 
      
        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
      foreach y in `outcome' $dep_var_ref  $controls_SR {
        qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
        rename `y' o_`y'
        rename `y'_c2wr `y'
      }
      
      qui reg `outcome' $dep_var_ref $controls_SR [pw = $weight], cluster(district_iid) robust
      estimates store REFOLS_YI_`outcome', title(Model `outcome')

      drop `outcome' $controls_SR $dep_var_ref smpl
      
      foreach y in `outcome' $controls_SR $dep_var_ref  {
        rename o_`y' `y' 
      } 
    }
restore

*IV Y D 
foreach outcome of global outcomes_uncond {
    qui xi: ivreg2  `outcome' i.year i.district_iid $controls_SR ///
                ($dep_var_ref = $iv_ref) ///
                [pw = $weight], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) ///
                first
    estimates store REFIV_YD_`outcome', title(Model `outcome')
  }

preserve


drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

 foreach outcome of global outcomes_cond {
    qui xi: ivreg2  `outcome' i.year i.district_iid $controls_SR ///
                ($dep_var_ref = $iv_ref) ///
                [pw = $weight], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) ///
                first
    estimates store REFIV_YD_`outcome', title(Model `outcome')
  }
restore 

*IV Y I
preserve
  foreach outcome of global outcomes_uncond {     
       qui xi: ivreghdfe `outcome' ///
                    $controls_SR  ///
                    ($dep_var_ref = $iv_ref) ///
                    [pw = $weight], ///
                    absorb(year indid_2010) ///
                    cluster(district_iid) 

        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
        foreach y in `outcome' $controls_SR $dep_var_ref $iv_ref { 
          qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
          qui rename `y' o_`y'
          qui rename `y'_c2wr `y'
        }
        qui ivreg2 `outcome' ///
               $controls_SR  ///
               ($dep_var_ref = $iv_ref) ///
               [pw = $weight], ///
               cluster(district_iid) robust ///
               first 
      estimates store REFIV_YI_`outcome', title(Model `outcome')
        qui drop `outcome' $dep_var_ref $iv_ref $controls_SR smpl
        foreach y in `outcome' $dep_var_ref $iv_ref $controls_SR {
          qui rename o_`y' `y' 
        }
    }
restore             

preserve


drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

  foreach outcome of global outcomes_cond {     
       qui xi: ivreghdfe `outcome' ///
                    $controls_SR  ///
                    ($dep_var_ref = $iv_ref) ///
                    [pw = $weight], ///
                    absorb(year indid_2010) ///
                    cluster(district_iid) 

        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
        foreach y in `outcome' $controls_SR $dep_var_ref $iv_ref { 
          qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
          qui rename `y' o_`y'
          qui rename `y'_c2wr `y'
        }
        qui ivreg2 `outcome' ///
               $controls_SR  ///
               ($dep_var_ref = $iv_ref) ///
               [pw = $weight], ///
               cluster(district_iid) robust ///
               first 
      estimates store REFIV_YI_`outcome', title(Model `outcome')
        qui drop `outcome' $dep_var_ref $iv_ref $controls_SR smpl
        foreach y in `outcome' $dep_var_ref $iv_ref $controls_SR {
          qui rename o_`y' `y' 
        }
    }
restore                
    

    coefplot (REFOLS_YD_employed_olf_$rp, label(Employed))  ///
             (REFOLS_YD_unemployed_olf_$rp, label(Unemployed))  ///
             (REFOLS_YD_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (REFOLS_YD_lfp_temp_$rp, label(Type: Temporary))  ///
             (REFOLS_YD_lfp_employer_$rp, label(Type: Employer))  ///
             (REFOLS_YD_lfp_se_$rp, label(Type: SE))  ///
             (REFOLS_YD_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (REFOLS_YD_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (REFOLS_YD_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (REFOLS_YD_formal, label(Formal)) , bylabel("OLS District Year") ///
             || (REFIV_YD_employed_olf_$rp, label(Employed)) ///
             (REFIV_YD_unemployed_olf_$rp, label(Unemployed))  ///
             (REFIV_YD_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (REFIV_YD_lfp_temp_$rp, label(Type: Temporary))  ///
             (REFIV_YD_lfp_employer_$rp, label(Type: Employer))  ///
             (REFIV_YD_lfp_se_$rp, label(Type: SE))  ///
             (REFIV_YD_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (REFIV_YD_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (REFIV_YD_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (REFIV_YD_formal, label(Formal)) , bylabel("IV District Year") ///
             || (REFOLS_YI_employed_olf_$rp, label(Employed))  ///
             (REFOLS_YI_unemployed_olf_$rp, label(Unemployed))  ///
             (REFOLS_YI_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (REFOLS_YI_lfp_temp_$rp, label(Type: Temporary))  ///
             (REFOLS_YI_lfp_employer_$rp, label(Type: Employer))  ///
             (REFOLS_YI_lfp_se_$rp, label(Type: SE))  ///
             (REFOLS_YI_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (REFOLS_YI_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (REFOLS_YI_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (REFOLS_YI_formal, label(Formal)) , bylabel("OLS Indiv Year") ///
             || (REFIV_YI_employed_olf_$rp, label(Employed)) ///
             (REFIV_YI_unemployed_olf_$rp, label(Unemployed))  ///
             (REFIV_YI_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (REFIV_YI_lfp_temp_$rp, label(Type: Temporary))  ///
             (REFIV_YI_lfp_employer_$rp, label(Type: Employer))  ///
             (REFIV_YI_lfp_se_$rp, label(Type: SE))  ///
             (REFIV_YI_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (REFIV_YI_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (REFIV_YI_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (REFIV_YI_formal, label(Formal)) , bylabel("IV Indiv Year") ///
             || , drop(_Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
              label subtitle(, size(vsmall) fcolor(white) nobox ) ///
             xlabel("") ylabel("") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(tiny) ///
             byopts(graphregion(color(white)) bgcolor(white) ///
              title("Effect Sizes", size(small))) ///
                yscale(noline alt)  xscale(noline alt) legend(nobox ///
                region(lstyle(none)) size(vsmall) cols(4) ring(0) )  ///
            levels(99.9 99 95) ciopts(lwidth(*1) lcolor(*.6)) xla(none) xtitle("") xsc(noline)


graph export "$out_analysis\SR_Combined_Graph_REF.pdf", as(pdf) replace

******* WORK PERMITS *******

*OLS_Y_D
foreach outcome of global outcomes_uncond {
    qui xi: reg `outcome' $dep_var_wp ///
             i.district_iid i.year $controls_SR ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store WPOLS_YD_`outcome'
} 

preserve


drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 
 
foreach outcome of global outcomes_cond {
    qui xi: reg `outcome' $dep_var_wp ///
            i.district_iid i.year $controls_SR  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store WPOLS_YD_`outcome'
} 
restore

*OLS_Y_I
preserve
  foreach outcome of global outcomes_uncond {
       qui reghdfe `outcome' $dep_var_wp   ///
                $controls_SR  ///
                [pw = $weight], ///
                absorb(year indid_2010) ///
                cluster(district_iid) 
      
        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
      foreach y in `outcome' $dep_var_wp  $controls_SR {
        qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
        rename `y' o_`y'
        rename `y'_c2wr `y'
      }
      
      qui reg `outcome' $dep_var_wp $controls_SR [pw = $weight], cluster(district_iid) robust
      estimates store WPOLS_YI_`outcome', title(Model `outcome')

      drop `outcome' $controls_SR $dep_var_wp smpl
      
      foreach y in `outcome' $controls_SR $dep_var_wp  {
        rename o_`y' `y' 
      } 
    }
restore

preserve



drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

  foreach outcome of global outcomes_cond {
       qui reghdfe `outcome' $dep_var_wp $controls_SR  ///
                [pw = $weight], ///
                absorb(year indid_2010) ///
                cluster(district_iid) 
      
        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
      foreach y in `outcome' $dep_var_wp  $controls_SR {
        qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
        rename `y' o_`y'
        rename `y'_c2wr `y'
      }
      
      qui reg `outcome' $dep_var_wp $controls_SR [pw = $weight], cluster(district_iid) robust
      estimates store WPOLS_YI_`outcome', title(Model `outcome')

      drop `outcome' $controls_SR $dep_var_wp smpl
      
      foreach y in `outcome' $controls_SR $dep_var_wp  {
        rename o_`y' `y' 
      } 
    }
restore

*IV Y D 
foreach outcome of global outcomes_uncond {
    qui xi: ivreg2  `outcome' i.year i.district_iid $controls_SR ///
                ($dep_var_wp = $iv_wp) ///
                [pw = $weight], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) ///
                first
    estimates store WPIV_YD_`outcome', title(Model `outcome')
  }

preserve


drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

 foreach outcome of global outcomes_cond {
    qui xi: ivreg2  `outcome' i.year i.district_iid $controls_SR ///
                ($dep_var_wp = $iv_wp) ///
                [pw = $weight], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) ///
                first
    estimates store WPIV_YD_`outcome', title(Model `outcome')
  }
restore 

*IV Y I
preserve
  foreach outcome of global outcomes_uncond {     
       qui xi: ivreghdfe `outcome' ///
                    $controls_SR  ///
                    ($dep_var_wp = $iv_wp) ///
                    [pw = $weight], ///
                    absorb(year indid_2010) ///
                    cluster(district_iid) 

        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
        foreach y in `outcome' $controls_SR $dep_var_wp $iv_wp { 
          qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
          qui rename `y' o_`y'
          qui rename `y'_c2wr `y'
        }
        qui ivreg2 `outcome' ///
               $controls_SR  ///
               ($dep_var_wp = $iv_wp) ///
               [pw = $weight], ///
               cluster(district_iid) robust ///
               first 
      estimates store WPIV_YI_`outcome', title(Model `outcome')
        qui drop `outcome' $dep_var_wp $iv_wp $controls_SR smpl
        foreach y in `outcome' $dep_var_wp $iv_wp $controls_SR {
          qui rename o_`y' `y' 
        }
    }
restore             

preserve


drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

  foreach outcome of global outcomes_cond {     
       qui xi: ivreghdfe `outcome' ///
                    $controls_SR  ///
                    ($dep_var_wp = $iv_wp) ///
                    [pw = $weight], ///
                    absorb(year indid_2010) ///
                    cluster(district_iid) 

        qui gen smpl=0
        qui replace smpl=1 if e(sample)==1
        * Then I partial out all variables
        foreach y in `outcome' $controls_SR $dep_var_wp $iv_wp { 
          qui reghdfe `y' [pw = $weight] if smpl==1, absorb(year indid_2010) residuals(`y'_c2wr)
          qui rename `y' o_`y'
          qui rename `y'_c2wr `y'
        }
        qui ivreg2 `outcome' ///
               $controls_SR  ///
               ($dep_var_wp = $iv_wp) ///
               [pw = $weight], ///
               cluster(district_iid) robust ///
               first 
      estimates store WPIV_YI_`outcome', title(Model `outcome')
        qui drop `outcome' $dep_var_wp $iv_wp $controls_SR smpl
        foreach y in `outcome' $dep_var_wp $iv_wp $controls_SR {
          qui rename o_`y' `y' 
        }
    }
restore                
    
    coefplot (WPOLS_YD_employed_olf_$rp, label(Employed))  ///
             (WPOLS_YD_unemployed_olf_$rp, label(Unemployed))  ///
             (WPOLS_YD_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (WPOLS_YD_lfp_temp_$rp, label(Type: Temporary))  ///
             (WPOLS_YD_lfp_employer_$rp, label(Type: Employer))  ///
             (WPOLS_YD_lfp_se_$rp, label(Type: SE))  ///
             (WPOLS_YD_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (WPOLS_YD_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (WPOLS_YD_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (WPOLS_YD_formal, label(Formal)) , bylabel("OLS District Year") ///
             || (WPIV_YD_employed_olf_$rp, label(Employed)) ///
             (WPIV_YD_unemployed_olf_$rp, label(Unemployed))  ///
             (WPIV_YD_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (WPIV_YD_lfp_temp_$rp, label(Type: Temporary))  ///
             (WPIV_YD_lfp_employer_$rp, label(Type: Employer))  ///
             (WPIV_YD_lfp_se_$rp, label(Type: SE))  ///
             (WPIV_YD_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (WPIV_YD_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (WPIV_YD_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (WPIV_YD_formal, label(Formal)) , bylabel("IV District Year") ///
             || (WPOLS_YI_employed_olf_$rp, label(Employed))  ///
             (WPOLS_YI_unemployed_olf_$rp, label(Unemployed))  ///
             (WPOLS_YI_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (WPOLS_YI_lfp_temp_$rp, label(Type: Temporary))  ///
             (WPOLS_YI_lfp_employer_$rp, label(Type: Employer))  ///
             (WPOLS_YI_lfp_se_$rp, label(Type: SE))  ///
             (WPOLS_YI_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (WPOLS_YI_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (WPOLS_YI_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (WPOLS_YI_formal, label(Formal)) , bylabel("OLS Indiv Year") ///
             || (WPIV_YI_employed_olf_$rp, label(Employed)) ///
             (WPIV_YI_unemployed_olf_$rp, label(Unemployed))  ///
             (WPIV_YI_lfp_empl_$rp, label(Type: Wage Worker))  ///
             (WPIV_YI_lfp_temp_$rp, label(Type: Temporary))  ///
             (WPIV_YI_lfp_employer_$rp, label(Type: Employer))  ///
             (WPIV_YI_lfp_se_$rp, label(Type: SE))  ///
             (WPIV_YI_ln_total_rwage_$rp, label(Total Wage (ln))) ///
             (WPIV_YI_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (WPIV_YI_ln_whpw_$rp, label(Work Hours p.w.)) ///
             (WPIV_YI_formal, label(Formal)) , bylabel("IV Indiv Year") ///
             || , drop(_Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
              label subtitle(, size(vsmall) fcolor(white) nobox ) ///
             xlabel("") ylabel("") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(tiny) ///
             byopts(graphregion(color(white)) bgcolor(white) ///
              title("Effect Sizes", size(small))) ///
                yscale(noline alt)  xscale(noline alt) legend( nobox ///
                region(lstyle(none)) size(vsmall) cols(4) ring(0) )  ///
            levels(99.9 99 95) ciopts(lwidth(*1) lcolor(*.6)) xla(none) xtitle("") xsc(noline)


graph export "$out_analysis\SR_Combined_Graph_WP.pdf", as(pdf) replace


          *    note("* p<0.1, ** p<0.05, *** p<0.01", size(vsmall)) ///






**********************************************
**********************************************

        ****** GRAPH FOR HETERO ******

**********************************************
**********************************************

use "$data_final/07_IV_Ref_WP.dta", clear

tab nationality_cl year 
drop if nationality_cl != 1
*keep if gender == 1 

drop if age > 64 & year == 2016
drop if age > 60 & year == 2010 //60 in 2010 so 64 in 2016

drop if age < 15 & year == 2016 
drop if age < 11 & year == 2010 //11 in 2010 so 15 in 2016


/*ONLY THOSE WHO WERE SURVEYED IN BOTH PERIODS?*/

/*
distinct indid_2010 
duplicates tag indid_2010, gen(dup)
bys year: tab dup
drop if dup == 0
drop dup
tab year
*/

xtset, clear 
xtset indid_2010 year 



**** OTHER TRIES WITH TWO MODELS 

******* REFUGEE INFLOW ********




 ***************
 ** GENDER **
 ***************

codebook gender
tab gender
lab var gender "Gender"

gen inter_gender = gender*$dep_var_ref
*gen inter_formal_IV = gender*$IV_var_ref
lab var inter_gender "Nbr Ref x Gender"


**** OLS *****
  foreach outcome of global outcomes_uncond {
    qui xi: reg `outcome' $dep_var_ref inter_gender gender ///
                age age2 ///
                i.district_iid i.year  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFGEN_YD_`outcome', title(Model `outcome')
  }

preserve

drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

  foreach outcome of global outcomes_cond {
    qui xi: reg `outcome' $dep_var_ref inter_gender gender ///
                age age2 ///
                i.district_iid i.year  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFGEN_YD_`outcome', title(Model `outcome')
  }
restore 


     coefplot (REFGEN_YD_employed_olf_$rp), bylabel(Employed)  ///
             || (REFGEN_YD_unemployed_olf_$rp), bylabel(Unemployed)  ///
             || (REFGEN_YD_lfp_empl_$rp), bylabel(Type: Wage Worker)  ///
             || (REFGEN_YD_lfp_temp_$rp), bylabel(Type: Temporary)  ///
             || (REFGEN_YD_lfp_employer_$rp), bylabel(Type: Employer)  ///
             || (REFGEN_YD_lfp_se_$rp), bylabel(Type: SE) ///
             || (REFGEN_YD_ln_total_rwage_$rp), bylabel(Total Wage (ln)) ///
             || (REFGEN_YD_ln_hourly_rwage), bylabel(Hourly Wage (ln)) ///
             || (REFGEN_YD_ln_whpw_$rp), bylabel(Work Hours p.w.) ///
             || (REFGEN_YD_formal), bylabel(Formal) ///
             || , drop( _Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
              label subtitle(, size(vsmall) fcolor(white) nobox ) ///
             xlabel("") ylabel(1 "Treat" 2 "Inter") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(tiny) ///
             byopts(graphregion(color(white)) bgcolor(white) ///
              title("Effect Sizes: Gender", size(small))) ///
                yscale(noline alt)  xscale(noline alt) legend(nobox ///
                region(lstyle(none)) size(vsmall) cols(4) ring(0) )  ///
            levels(99.9 99 95) ciopts(lwidth(*1) lcolor(*.6)) xla(none) xtitle("") xsc(noline) ///
            keep($dep_var_ref inter_gender)


graph export "$out_analysis\SR_HET_GENDER_Combined_Graph_REF.pdf", as(pdf) replace





 ***************
 ** RURAL **
 ***************

replace urban = 0 if urban == 2  
lab def urban 0 "Rural" 1 "Urban", modify
lab val urban urban 

tab urban, m 
codebook urban  


codebook urban
tab urban
lab var urban "Urban"

gen inter_urban = urban*$dep_var_ref
*gen inter_formal_IV = urban*$IV_var_ref
lab var inter_urban "Nbr Ref x urban"


**** OLS *****
  foreach outcome of global outcomes_uncond {
    qui xi: reg `outcome' $dep_var_ref inter_urban urban ///
                age age2 ///
                i.district_iid i.year  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFURB_YD_`outcome', title(Model `outcome')
  }

preserve

drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

  foreach outcome of global outcomes_cond {
    qui xi: reg `outcome' $dep_var_ref inter_urban urban ///
                age age2 ///
                i.district_iid i.year  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFURB_YD_`outcome', title(Model `outcome')
  }
restore 


     coefplot (REFURB_YD_employed_olf_$rp), bylabel(Employed)  ///
             || (REFURB_YD_unemployed_olf_$rp), bylabel(Unemployed)  ///
             || (REFURB_YD_lfp_empl_$rp), bylabel(Type: Wage Worker)  ///
             || (REFURB_YD_lfp_temp_$rp), bylabel(Type: Temporary)  ///
             || (REFURB_YD_lfp_employer_$rp), bylabel(Type: Employer)  ///
             || (REFURB_YD_lfp_se_$rp), bylabel(Type: SE) ///
             || (REFURB_YD_ln_total_rwage_$rp), bylabel(Total Wage (ln)) ///
             || (REFURB_YD_ln_hourly_rwage), bylabel(Hourly Wage (ln)) ///
             || (REFURB_YD_ln_whpw_$rp), bylabel(Work Hours p.w.) ///
             || (REFURB_YD_formal), bylabel(Formal) ///
             || , drop( _Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
              label subtitle(, size(vsmall) fcolor(white) nobox ) ///
             xlabel("") ylabel(1 "Treat" 2 "Inter") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(tiny) ///
             byopts(graphregion(color(white)) bgcolor(white) ///
              title("Effect Sizes: Urban", size(small))) ///
                yscale(noline alt)  xscale(noline alt) legend(nobox ///
                region(lstyle(none)) size(vsmall) cols(4) ring(0) )  ///
            levels(99.9 99 95) ciopts(lwidth(*1) lcolor(*.6)) xla(none) xtitle("") xsc(noline) ///
            keep($dep_var_ref inter_urban)


graph export "$out_analysis\SR_HET_URBAN_Combined_Graph_REF.pdf", as(pdf) replace






 ***************
 ** EDUCATION **
 ***************

tab bi_education, m 
codebook bi_education  


codebook bi_education
tab bi_education
lab var bi_education "Education"

gen inter_educ = bi_education*$dep_var_ref
*gen inter_formal_IV = bi_education*$IV_var_ref
lab var inter_educ "Nbr Ref x education"






**** OLS *****
  foreach outcome of global outcomes_uncond {
    qui xi: reg `outcome' $dep_var_ref inter_educ bi_education ///
                age age2 ///
                i.district_iid i.year  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFEDU_YD_`outcome', title(Model `outcome')
  }

preserve

drop if miss_16_10 == 1
drop if unemp_16_10 == 1
drop if olf_16_10 == 1
drop if emp_16_miss_10 == 1
drop if emp_10_miss_16 == 1
drop if unemp_16_miss_10 == 1
drop if unemp_10_miss_16 == 1
drop if olf_16_miss_10 == 1
drop if olf_10_miss_16 == 1 

  foreach outcome of global outcomes_cond {
    qui xi: reg `outcome' $dep_var_ref inter_educ bi_education ///
                age age2 ///
                i.district_iid i.year  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store REFEDU_YD_`outcome', title(Model `outcome')
  }
restore 


     coefplot (REFEDU_YD_employed_olf_$rp), bylabel(Employed)  ///
             || (REFEDU_YD_unemployed_olf_$rp), bylabel(Unemployed)  ///
             || (REFEDU_YD_lfp_empl_$rp), bylabel(Type: Wage Worker)  ///
             || (REFEDU_YD_lfp_temp_$rp), bylabel(Type: Temporary)  ///
             || (REFEDU_YD_lfp_employer_$rp), bylabel(Type: Employer)  ///
             || (REFEDU_YD_lfp_se_$rp), bylabel(Type: SE) ///
             || (REFEDU_YD_ln_total_rwage_$rp), bylabel(Total Wage (ln)) ///
             || (REFEDU_YD_ln_hourly_rwage), bylabel(Hourly Wage (ln)) ///
             || (REFEDU_YD_ln_whpw_$rp), bylabel(Work Hours p.w.) ///
             || (REFEDU_YD_formal), bylabel(Formal) ///
             || , drop(_Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
              label subtitle(, size(vsmall) fcolor(white) nobox ) ///
             xlabel("") ylabel(1 "Treat" 2 "Inter") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(tiny) ///
             byopts(graphregion(color(white)) bgcolor(white) ///
              title("Effect Sizes: Education", size(small))) ///
                yscale(noline alt)  xscale(noline alt) legend(nobox ///
                region(lstyle(none)) size(vsmall) cols(4) ring(0) )  ///
            levels(99.9 99 95) ciopts(lwidth(*1) lcolor(*.6)) xla(none) xtitle("") xsc(noline) ///
            keep($dep_var_ref inter_educ)


graph export "$out_analysis\SR_HET_EDUC_Combined_Graph_REF.pdf", as(pdf) replace







































**********************************
**********************************

            /* ELSE */

**********************************
**********************************

    coefplot (m_OLS_Y_D_employed_olf_3m, label(Employed))  ///
             (m_OLS_Y_D_unemployed_olf_3m, label(Unemployed))  ///
             (m_OLS_Y_D_lfp_3m_empl, label(Type: Wage Worker))  ///
             (m_OLS_Y_D_lfp_3m_temp, label(Type: Temporary))  ///
             (m_OLS_Y_D_lfp_3m_employer, label(Type: Employer))  ///
             (m_OLS_Y_D_lfp_3m_se, label(Type: SE))  ///
             (m_OLS_Y_D_lfp_3m_unpaid, label(Type: Unpaid)) ///
             (m_OLS_Y_D_ln_total_rwage_3m, label(Total Wage (ln))) ///
             (m_OLS_Y_D_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (m_OLS_Y_D_ln_whpw_3m, label(Work Hours p.w.)) ///
             (m_OLS_Y_D_formal, label(Formal)) , bylabel("OLS District Year") ///
             || (m_IV_Y_D_employed_olf_3m, label(Employed)) ///
             (m_IV_Y_D_unemployed_olf_3m, label(Unemployed))  ///
             (m_IV_Y_D_lfp_3m_empl, label(Type: Wage Worker))  ///
             (m_IV_Y_D_lfp_3m_temp, label(Type: Temporary))  ///
             (m_IV_Y_D_lfp_3m_employer, label(Type: Employer))  ///
             (m_IV_Y_D_lfp_3m_se, label(Type: SE))  ///
             (m_IV_Y_D_lfp_3m_unpaid, label(Type: Unpaid)) ///
             (m_IV_Y_D_ln_total_rwage_3m, label(Total Wage (ln))) ///
             (m_IV_Y_D_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (m_IV_Y_D_ln_whpw_3m, label(Work Hours p.w.)) ///
             (m_IV_Y_D_formal, label(Formal)) , bylabel("IV District Year") ///
             || , drop(_Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
              label subtitle(, size(small) fcolor(white)) ///
             xlabel("") ylabel("") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(vsmall) ///
             byopts(graphregion(color(white)) bgcolor(white) ///
              note("p-values shown alongside markers" "* p<0.1, ** p<0.05, *** p<0.01") ///
              title("Effect Sizes")) ///
                yscale(noline alt)  xscale(noline alt) legend( nobox ///
                region(lstyle(none)) size(vsmall) )  ///
            levels(99.9 99 95) ciopts(lwidth(*3) lcolor(*.6)) xla(none) xtitle("") xsc(noline)
graph export "$out_analysis\SR_Combined_Graph.pdf", as(pdf) replace









******* graph combine 



foreach outcome of global outcomes_uncond {
    qui xi: reg `outcome' $dep_var_wp ///
            i.district_iid i.year $controls_SR  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store m_OLS_Y_D_`outcome'
} 

preserve
keep if emp_16_10 == 1 
foreach outcome of global outcomes_cond {
    qui xi: reg `outcome' $dep_var_wp ///
            i.district_iid i.year $controls_SR  ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    estimates store m_OLS_Y_D_`outcome'
} 
restore 

    coefplot (m_OLS_Y_D_employed_olf_3m, label(Employed)) ///
             (m_OLS_Y_D_unemployed_olf_3m, label(Unemployed))  ///
             (m_OLS_Y_D_lfp_3m_empl, label(Type: Wage Worker))  ///
             (m_OLS_Y_D_lfp_3m_temp, label(Type: Temporary))  ///
             (m_OLS_Y_D_lfp_3m_employer, label(Type: Employer))  ///
             (m_OLS_Y_D_lfp_3m_se, label(Type: SE))  ///
             (m_OLS_Y_D_lfp_3m_unpaid, label(Type: Unpaid)) ///
             (m_OLS_Y_D_ln_total_rwage_3m, label(Total Wage (ln))) ///
             (m_OLS_Y_D_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (m_OLS_Y_D_ln_whpw_3m, label(Work Hours p.w.)) ///
             (m_OLS_Y_D_formal, label(Formal)) ///
             , drop(_Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(D) ///
             graphregion(color(white)) bgcolor(white) label ///
             xlabel("") ylabel("") ///
             title("Effect Sizes OLS, FE District and Year") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(vsmall) ///
             note("p-values shown alongside markers" "* p<0.1, ** p<0.05, *** p<0.01") ///
             yscale(noline alt)  xscale(noline alt) legend(nobox ///
             region(lstyle(none)) size(small) cols(1) ring(0) bplacement(nw)) ///
             levels(99.9 99 95) ciopts(lwidth(*3) lcolor(*.6)) ///
             name(a, replace)


 foreach outcome of global outcomes_uncond {
    qui xi: ivreg2  `outcome' i.year i.district_iid $controls_SR ///
                ($dep_var_wp = $iv_wp) ///
                [pw = $weight], ///
                cluster(district_iid) robust ///
                partial(i.district_iid)
    estimates store m_IV_Y_D_`outcome', title(Model `outcome')
  }

preserve
keep if emp_16_10 == 1 
 foreach outcome of global outcomes_cond {
    qui xi: ivreg2  `outcome' i.year i.district_iid $controls_SR ///
                ($dep_var_wp = $iv_wp) ///
                [pw = $weight], ///
                cluster(district_iid) robust ///
                partial(i.district_iid) 
    estimates store m_IV_Y_D_`outcome', title(Model `outcome')
  }
restore

/*    coefplot (m_IV_Y_D_employed_olf_3m, label(Employed)) ///
             (m_IV_Y_D_unemployed_olf_3m, label(Unemployed))  ///
             (m_IV_Y_D_lfp_3m_empl, label(Type: Wage Worker))  ///
             (m_IV_Y_D_lfp_3m_temp, label(Type: Temporary))  ///
             (m_IV_Y_D_lfp_3m_employer, label(Type: Employer))  ///
             (m_IV_Y_D_lfp_3m_se, label(Type: SE))  ///
             (m_IV_Y_D_lfp_3m_unpaid, label(Type: Unpaid)) ///
             (m_IV_Y_D_ln_total_rwage_3m, label(Total Wage (ln))) ///
             (m_IV_Y_D_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (m_IV_Y_D_ln_whpw_3m, label(Work Hours p.w.)) ///
             (m_IV_Y_D_formal, label(Formal)) ///
             , drop(_Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
             graphregion(color(white)) bgcolor(white) label ///
             xlabel("") ylabel("") ///
             title("Effect Sizes IV, FE District and Year") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(vsmall) ///
             note("p-values shown alongside markers" "* p<0.1, ** p<0.05, *** p<0.01") ///
             yscale(noline alt)  xscale(noline alt) legend( nobox ///
             region(lstyle(none)) size(small))  ///
             levels(99.9 99 95) ciopts(lwidth(*3) lcolor(*.6)) ///
             name(b, replace) nolabels
*/
    coefplot (m_IV_Y_D_employed_olf_3m, label(Employed)) ///
             (m_IV_Y_D_unemployed_olf_3m, label(Unemployed))  ///
             (m_IV_Y_D_lfp_3m_empl, label(Type: Wage Worker))  ///
             (m_IV_Y_D_lfp_3m_temp, label(Type: Temporary))  ///
             (m_IV_Y_D_lfp_3m_employer, label(Type: Employer))  ///
             (m_IV_Y_D_lfp_3m_se, label(Type: SE))  ///
             (m_IV_Y_D_lfp_3m_unpaid, label(Type: Unpaid)) ///
             (m_IV_Y_D_ln_total_rwage_3m, label(Total Wage (ln))) ///
             (m_IV_Y_D_ln_hourly_rwage, label(Hourly Wage (ln))) ///
             (m_IV_Y_D_ln_whpw_3m, label(Work Hours p.w.)) ///
             (m_IV_Y_D_formal, label(Formal)) ///
             , drop(_Iyear_2016 $district _cons $controls_SR) ///
              xline(0) msymbol(d) ///
             graphregion(color(white)) bgcolor(white) label ///
             xlabel("") ylabel("") ///
             title("Effect Sizes IV, FE District and Year") ///
             mlabel(cond(@pval<.01, string(@b,"%9.3f") + "***", ///
             cond(@pval<.05, string(@b,"%9.3f") + "**", ///
             cond(@pval<.1, string(@b,"%9.3f") + "*", ///
             string(@b, "%5.3f")  ) ) ) ) mlabposition(10) mlabsize(vsmall) ///
             yscale(noline alt)  xscale(noline alt)  legend(off) ///
             levels(99.9 99 95) ciopts(lwidth(*3) lcolor(*.6)) ///
             name(b, replace) 


graph combine a b, xsize(6)


/*
legend position
ompassdirstyle First Second Third Fourth
north n 12 top
neast ne 1 2
east e 3 right
seast se 4 5
south s 6 bottom
swest sw 7 8
west w 9 left
nwest nw 10 11
center c 0
*/





**** GRAAPH WITH MANY COUNTRIES 

  foreach outcome of global outcomes_uncond {

    xi: reg `outcome' $dep_var_wp ///
            [pw = $weight],  ///
            cluster(district_iid) robust 
    codebook employed_olf_3m, c
    estimates table, k($dep_var_wp) star(.1 .05 .01) b(%7.4f) 
    estimates table, b(%7.4f) se(%7.4f) stats(N r2_a) k($dep_var_wp) 
    estimates store m_`outcome'

} 
    coefplot (m_employed_olf_3m, label(Employed)) ///
             (m_unemployed_olf_3m, label(Unemployed))  ///
             (m_lfp_3m_empl, label(Type: Wage Worker))  ///
             (m_lfp_3m_temp, label(Type: Temporary))  ///
             (m_lfp_3m_employer, label(Type: Employer))  ///
             (m_lfp_3m_se, label(Type: SE))  ///
             (m_lfp_3m_unpaid, label(Type: Unpaid)) , bylabel(Jordan) ///
             mlabposition(12) mlabsize(vsmall)  mlabel(string(@b, "%5.3f"))  ///
             || , bylabel(Uganda)  ///
         || ,  drop(age age2 gender _Iyear_2016 ///
        $district ///
        _cons $controls_SR) xline(0)  msymbol(S) 




  foreach outcome of global outcomes_uncond {
       qui xi: reg `outcome' $dep_var_wp i.district_iid i.year $controls_SR ///
              [pw = $weight],  ///
               cluster(district_iid) robust 
       estimates store Jordan_`outcome'
   }

  foreach outcome of global outcomes_uncond {
       qui xi: reg `outcome' $dep_var_wp i.district_iid i.year $controls_SR  ///
              [pw = $weight],  ///
               cluster(district_iid) robust 
       estimates store Uganda_`outcome'
   }


coefplot    (Jordan_employed_olf_3m), bylabel(Jordan) ///
         || (Uganda_employed_olf_3m ), bylabel(Uganda) ///
         || (Jordan_unemployed_olf_3m, offset(-0.15)), bylabel(Jordan)  ///
         || (Uganda_unemployed_olf_3m), bylabel(Uganda)  ///
         || (Jordan_lfp_3m_empl), bylabel(Jordan) ///
         || (Uganda_lfp_3m_empl), bylabel(Uganda)   ///
         || (Jordan_lfp_3m_temp), bylabel(Jordan)  ///
         || (Uganda_lfp_3m_temp), bylabel(Uganda)   ///
         || (Jordan_lfp_3m_employer), bylabel(Jordan)  ///
         || (Uganda_lfp_3m_employer), bylabel(Uganda)  ///
         || (Jordan_lfp_3m_se), bylabel(Jordan) ///
         || (Uganda_lfp_3m_se), bylabel(Uganda)   ///
         || (Jordan_lfp_3m_unpaid), bylabel(Jordan)  ///
         || (Uganda_lfp_3m_unpaid), bylabel(Uganda)  ///
         ||   , drop($controls_SR _Iyear_2016 $district _cons) xline(0) ///
     bycoefs  ///
     ytick( 2.5 4.5 6.5 8.5 10.5 12.5,  glpattern(dash) glwidth(*0.5) glcolor(gray)) ///
     grid(glpattern(dash) glwidth(*2) glcolor(gray)) ///
     group(1 2 = "{bf:Employed}" 3 4 = "{bf:Unemployed}" ///
      5 6 = "{bf: Type: Wage Empl}" 7 8 = "{bf:Type: Temp}"   ///
      9 10 = "{bf:Type: Employer}" 11 12 = "{bf:Type: SE}" ///
      13 14= "{bf:Type: Unpaid}", nogap  angle(horizontal))   ///
      graphregion(color(white)) bgcolor(white) legend(off) label ///
      yscale(range(-0.01 0.03)) ymtick(-0.01(0.005)0.03) ///
      mlabposition(2) mlabsize(vsmall) mlabel(string(@b, "%5.3f"))
  









*** COMBINED WITH ug and jor



   coefplot  (m_employed_olf_3m, label("Employed") ) ///
               ,  bylabel(Jordan) ///
                mlabel(string(@b, "%5.2f")) mlabposition(12) mlabsize(vsmall) ///
             || (m_employed_olf_3m, label("Employed")) ///
             , bylabel(Uganda)  ///
                 mlabel(string(@b, "%5.2f")) mlabposition(12) mlabsize(vsmall) ///
             || (m_unemployed_olf_3m, label("Unemployed"))  ///
              ,  bylabel(Jordan)  mlabel(string(@b, "%5.2f")) mlabposition(12) mlabsize(vsmall) ///
             || (m_unemployed_olf_3m, label("Unemployed"))  ///
             , bylabel(Uganda)  ///
            ||  ,  drop(age age2 _Iyear_2016   $district ///
        _cons ) xline(0) keep($dep_var_ref inter_gender)

  coefplot  (m_employed_olf_3m, label("Employed") ) ///
               , bylabel(Jordan) mlabel(string(@b, "%5.2f")) mlabposition(12) mlabsize(vsmall) ///
             || (m_employed_olf_3m, label("Employed")) ///
             , bylabel(Uganda)  ///
           ||  ,  drop(age age2 _Iyear_2016  $district ///
        _cons ) xline(0)    ytitle("Employed")


      coefplot  (m_unemployed_olf_3m, label("Unemployed"))  ///
              , bylabel(Jordan)  mlabel(string(@b, "%5.2f")) mlabposition(12) mlabsize(vsmall) ///
             || (m_unemployed_olf_3m, label("Unemployed"))  ///
             , bylabel(Uganda)  ///
            ||  ,  drop(age age2 _Iyear_2016  $district ///
        _cons ) xline(0) 





