#V3.30.22.1;_safe;_compile_date:_Jan 30 2024;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.1
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:https://vlab.noaa.gov/group/stock-synthesis
#_Source_code_at:_https://github.com/nmfs-ost/ss3-source-code

#C control file for lobster (wales)
#_data_and_control_files: data.ss // control.ss
0  # 0 means do not read wtatage.ss; 1 means read and use wtatage.ss and also read and use growth parameters
1  #_N_Growth_Patterns (Growth Patterns, Morphs, Bio Patterns, GP are terms used interchangeably in SS3)
1 #_N_platoons_Within_GrowthPattern 
#_Cond 1 #_Platoon_within/between_stdev_ratio (no read if N_platoons=1)
#_Cond sd_ratio_rd < 0: platoon_sd_ratio parameter required after movement params.
#_Cond  1 #vector_platoon_dist_(-1_in_first_val_gives_normal_approx)
#
4 # recr_dist_method for parameters:  2=main effects for GP, Area, Settle timing; 3=each Settle entity; 4=none (only when N_GP*Nsettle*pop==1)
1 # not yet implemented; Future usage: Spawner-Recruitment: 1=global; 2=by area
1 #  number of recruitment settlement assignments 
0 # unused option
#GPattern month  area  age (for each settlement assignment)
 1 7.5 1 0
#
#_Cond 0 # N_movement_definitions goes here if Nareas > 1
#_Cond 1.0 # first age that moves (real age at begin of season, not integer) also cond on do_migration>0
#_Cond 1 1 1 2 4 10 # example move definition for seas=1, morph=1, source=1 dest=2, age1=4, age2=10
#
2 #_Nblock_Patterns
 1 2 #_blocks_per_pattern 
# begin and end years of blocks
 1983 1992
 1993 1996 1997 2034
#
# controls for all timevary parameters 
1 #_time-vary parm bound check (1=warn relative to base parm bounds; 3=no bound check); Also see env (3) and dev (5) options to constrain with base bounds
#
# AUTOGEN
 1 1 1 1 1 # autogen: 1st element for biology, 2nd for SR, 3rd for Q, 4th reserved, 5th for selex
# where: 0 = autogen time-varying parms of this category; 1 = read each time-varying parm line; 2 = read then autogen if parm min==-12345
#
#_Available timevary codes
#_Block types: 0: P_block=P_base*exp(TVP); 1: P_block=P_base+TVP; 2: P_block=TVP; 3: P_block=P_block(-1) + TVP
#_Block_trends: -1: trend bounded by base parm min-max and parms in transformed units (beware); -2: endtrend and infl_year direct values; -3: end and infl as fraction of base range
#_EnvLinks:  1: P(y)=P_base*exp(TVP*env(y));  2: P(y)=P_base+TVP*env(y);  3: P(y)=f(TVP,env_Zscore) w/ logit to stay in min-max;  4: P(y)=2.0/(1.0+exp(-TVP1*env(y) - TVP2))
#_DevLinks:  1: P(y)*=exp(dev(y)*dev_se;  2: P(y)+=dev(y)*dev_se;  3: random walk;  4: zero-reverting random walk with rho;  5: like 4 with logit transform to stay in base min-max
#_DevLinks(more):  21-25 keep last dev for rest of years
#
#_Prior_codes:  0=none; 6=normal; 1=symmetric beta; 2=CASAL's beta; 3=lognormal; 4=lognormal with biascorr; 5=gamma
#
# setup for M, growth, wt-len, maturity, fecundity, (hermaphro), recr_distr, cohort_grow, (movement), (age error), (catch_mult), sex ratio 
#_NATMORT
0 #_natM_type:_0=1Parm; 1=N_breakpoints;_2=Lorenzen;_3=agespecific;_4=agespec_withseasinterpolate;_5=BETA:_Maunder_link_to_maturity;_6=Lorenzen_range
  #_no additional input for selected M option; read 1P per morph
#
1 # GrowthModel: 1=vonBert with L1&L2; 2=Richards with L1&L2; 3=age_specific_K_incr; 4=age_specific_K_decr; 5=age_specific_K_each; 6=NA; 7=NA; 8=growth cessation
1 #_Age(post-settlement) for L1 (aka Amin); first growth parameter is size at this age; linear growth below this
999 #_Age(post-settlement) for L2 (aka Amax); 999 to treat as Linf
-999 #_exponential decay for growth above maxage (value should approx initial Z; -999 replicates 3.24; -998 to not allow growth above maxage)
0  #_placeholder for future growth feature
#
0 #_SD_add_to_LAA (set to 0.1 for SS2 V1.x compatibility)
0 #_CV_Growth_Pattern:  0 CV=f(LAA); 1 CV=F(A); 2 SD=F(LAA); 3 SD=F(A); 4 logSD=F(A)
#
1 #_maturity_option:  1=length logistic; 2=age logistic; 3=read age-maturity matrix by growth_pattern; 4=read age-fecundity; 5=disabled; 6=read length-maturity
3 #_First_Mature_Age
2 #_fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
0 #_hermaphroditism option:  0=none; 1=female-to-male age-specific fxn; -1=male-to-female age-specific fxn
1 #_parameter_offset_approach for M, G, CV_G:  1- direct, no offset**; 2- male=fem_parm*exp(male_parm); 3: male=female*exp(parm) then old=young*exp(parm)
#_** in option 1, any male parameter with value = 0.0 and phase <0 is set equal to female parameter
#
#_growth_parms
#_ LO HI INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
# Sex: 1  BioPattern: 1  NatMort
 0.05 2.4 0.211 0.4 99 0 -1 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 1 5 2.22681 2 99 0 -3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 5 70 21.5073 21.23 99 0 -3 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.01 2 0.219148 0.2 99 0 -3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.01 0.4 0.171767 0.17 99 0 -3 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.9 0.152284 0.15 99 0 -3 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 -3 3 0.0005579 0.0005579 99 0 -99 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 -3 4 3.1075 3.1075 99 0 -99 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 1 15 9.06393 9 99 0 -99 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -3 0 -1.50611 -1.5 99 0 -99 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 -3 10 1 1 99 0 -99 0 0 0 0 0 0 0 # Eggs_scalar_Fem_GP_1
 -3 10 0 0 99 0 -99 0 0 0 0 0 0 0 # Eggs_exp_len_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 0.05 2.4 0.211 0.4 99 0 -1 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 1 5 2.23191 2 99 0 -3 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 5 70 20.63 20.63 99 0 -3 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.05 2 0.213052 0.21 99 0 -3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.01 0.4 0.190302 0.18 99 0 -3 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.9 0.131648 0.13 99 0 -3 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
# Sex: 2  BioPattern: 1  WtLen
 -3 2 0.0005579 0.0005579 99 0 -99 0 0 0 0 0 0 0 # Wtlen_1_Mal_GP_1
 -3 5 3.1075 3.1075 99 0 -99 0 0 0 0 0 0 0 # Wtlen_2_Mal_GP_1
# Hermaphroditism
#  Recruitment Distribution 
#  Cohort growth dev base
 0.1 10 1 1 1 0 -1 0 0 0 0 0 0 0 # CohortGrowDev
#  Movement
#  Platoon StDev Ratio 
#  Age Error from parameters
#  catch multiplier
 1e-06 4 0.750489 1 5 1 1 0 1 1950 2005 1 0 0 # Catch_Mult:_2_Pot_fisheries_historical
 1e-06 4.5 2.24753 1 5 1 1 0 1 1950 2005 1 0 0 # Catch_Mult:_6_Bycatch_fisheries_historical
#  fraction female, by GP
 1e-06 0.999999 0.5 0.5 0.5 0 -99 0 0 0 0 0 0 0 # FracFemale_GP_1
#  M2 parameter for each predator fleet
#
# timevary MG parameters 
#_ LO HI INIT PRIOR PR_SD PR_type  PHASE
 1e-06 2 1.51737 0.7 3 1 5 # Catch_Mult:_2_Pot_fisheries_historical_dev_se
 -2 1 -0.5 0.9 1 1 6 # Catch_Mult:_2_Pot_fisheries_historical_dev_autocorr
 1e-06 4 2.00003 0.7 3 1 5 # Catch_Mult:_6_Bycatch_fisheries_historical_dev_se
 -2 1 -0.5 0.9 1 1 6 # Catch_Mult:_6_Bycatch_fisheries_historical_dev_autocorr
# info on dev vectors created for MGparms are reported with other devs after tag parameter section 
#
#_seasonal_effects_on_biology_parms
 0 0 0 0 0 0 0 0 0 0 #_femwtlen1,femwtlen2,mat1,mat2,fec1,fec2,Malewtlen1,malewtlen2,L1,K
#_ LO HI INIT PRIOR PR_SD PR_type PHASE
#_Cond -2 2 0 0 -1 99 -2 #_placeholder when no seasonal MG parameters
#
3 #_Spawner-Recruitment; Options: 1=NA; 2=Ricker; 3=std_B-H; 4=SCAA; 5=Hockey; 6=B-H_flattop; 7=survival_3Parm; 8=Shepherd_3Parm; 9=RickerPower_3parm
0  # 0/1 to use steepness in initial equ recruitment calculation
0  #  future feature:  0/1 to make realized sigmaR a function of SR curvature
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn #  parm_name
             1            14       6.82672           6.9             5             3          1          0          0          0          0          0          0          0 # SR_LN(R0)
           0.2             1      0.864082           0.9             3             1          5          0          0          0          0          0          0          0 # SR_BH_steep
             0             8      0.473583           0.4            99             0         -2          0          0          0          0          0          0          0 # SR_sigmaR
            -5             5             0             0            99             0         -1          0          0          0          0          0          0          0 # SR_regime
             0             1             0         0.456            99             0         -2          0          0          0          0          0          0          0 # SR_autocorr
#_no timevary SR parameters
3 #do_recdev:  0=none; 1=devvector (R=F(SSB)+dev); 2=deviations (R=F(SSB)+dev); 3=deviations (R=R0*dev; dev2=R-f(SSB)); 4=like 3 with sum(dev2) adding penalty
1983 # first year of main recr_devs; early devs can precede this era
2024 # last year of main recr_devs; forecast devs start in following year
3 #_recdev phase 
1 # (0/1) to read 13 advanced options
 1938 #_recdev_early_start (0=none; neg value makes relative to recdev_start)
 4 #_recdev_early_phase
 -1 #_forecast_recruitment phase (incl. late recr) (0 value resets to maxphase+1)
 1 #_lambda for Fcast_recr_like occurring before endyr+1
 1980 #_last_yr_nobias_adj_in_MPD; begin of ramp
 1983 #_first_yr_fullbias_adj_in_MPD; begin of plateau
 2020 #_last_yr_fullbias_adj_in_MPD
 2022 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS3 sets bias_adj to 0.0 for fcast yrs)
 0.9649 #_max_bias_adj_in_MPD (typical ~0.8; -3 sets all years to 0.0; -2 sets all non-forecast yrs w/ estimated recdevs to 1.0; -1 sets biasadj=1.0 for all yrs w/ recdevs)
 0 #_period of cycles in recruitment (N parms read below)
 -5 #min rec_dev
 5 #max rec_dev
 0 #_read_recdevs
#_end of advanced SR options
#
#_placeholder for full parameter lines for recruitment cycles
# read specified recr devs
#_Yr Input_value
#
# all recruitment deviations
#  1938E 1939E 1940E 1941E 1942E 1943E 1944E 1945E 1946E 1947E 1948E 1949E 1950E 1951E 1952E 1953E 1954E 1955E 1956E 1957E 1958E 1959E 1960E 1961E 1962E 1963E 1964E 1965E 1966E 1967E 1968E 1969E 1970E 1971E 1972E 1973E 1974E 1975E 1976E 1977E 1978E 1979E 1980E 1981E 1982E 1983R 1984R 1985R 1986R 1987R 1988R 1989R 1990R 1991R 1992R 1993R 1994R 1995R 1996R 1997R 1998R 1999R 2000R 2001R 2002R 2003R 2004R 2005R 2006R 2007R 2008R 2009R 2010R 2011R 2012R 2013R 2014R 2015R 2016R 2017R 2018R 2019R 2020R 2021R 2022R 2023R 2024R 2025F 2026F 2027F 2028F 2029F 2030F 2031F 2032F 2033F 2034F
#  -1.75706e-07 -2.19029e-07 -2.713e-07 -3.26648e-07 -4.00066e-07 -4.88889e-07 -5.92398e-07 -7.00139e-07 -7.44962e-07 -5.41175e-07 -5.97414e-07 -7.09176e-07 -0.00714418 -0.00611601 -0.00507082 -0.00417978 -0.00352787 -0.00304265 -0.00257877 -0.00227977 -0.00205653 -0.00182908 -0.00253731 -0.00229007 -0.00202809 -0.00273685 -0.0040137 -0.0053638 -0.00623747 -0.0074447 -0.00825462 -0.00863723 -0.00932338 -0.00996319 -0.0101083 -0.00759403 -0.00231353 0.0103025 0.0292856 0.0270756 -0.0770554 -0.315168 0.481144 -0.0973013 -0.823369 -0.0565815 -0.608188 -0.29662 -0.1405 0.128893 0.0987379 -0.159228 0.0534169 0.101541 -0.12267 -0.175512 -0.253336 -0.647018 -0.126011 -0.5002 -0.16144 -0.293098 -0.366609 -0.427026 0.0414325 -1.06636 -0.447451 -0.376897 0.565113 -0.406356 0.280088 0.00614499 0.0525995 0.0499487 0.0147886 -0.209122 -0.310195 -0.0600308 0.229868 -0.221922 -0.226582 -0.148571 0.0217023 0.126994 -0.149055 -0.0904648 -0.076964 0 0 0 0 0 0 0 0 0 0
#
#Fishing Mortality info 
0.4 # F ballpark value in units of annual_F
-2008 # F ballpark year (neg value to disable)
4 # F_Method:  1=Pope midseason rate; 2=F as parameter; 3=F as hybrid; 4=fleet-specific parm/hybrid (#4 is superset of #2 and #3 and is recommended)
9 # max F (methods 2-4) or harvest fraction (method 1)
# read list of fleets that do F as parameter; unlisted fleets stay hybrid, bycatch fleets must be included with start_PH=1, high F fleets should switch early
# (A) fleet, (B) F_starting_value (used if start_PH=1), (C) start_PH for parms (99 to stay in hybrid, <0 to stay at starting value)
# (A) (B) (C)  (terminate list with -9999 for fleet)
 2 0.5 99 # Pot_fisheries_historical
 3 0.5 99 # Pot_fisheries_u10
 4 0.5 99 # Pot_fisheries_10to12
 5 0.5 99 # Pot_fisheries_o12
 6 0.0001 99 # Bycatch_fisheries_historical
 7 0.0001 99 # Bycatch_fisheries_gillnet
 8 0.0001 99 # Bycatch_fisheries_trawl
-9999 1 1 # end of list
7 #_number of loops for hybrid tuning; 4 good; 3 faster; 2 enough if switching to parms is enabled
#
#_initial_F_parms; for each fleet x season that has init_catch; nest season in fleet; count = 1
#_for unconstrained init_F, use an arbitrary initial catch and set lambda=0 for its logL
#_ LO HI INIT PRIOR PR_SD  PR_type  PHASE
 0 5 0.186353 0.5 1 1 1 # InitF_seas_1_flt_2Pot_fisheries_historical
#
# F rates by fleet x season
# Yr:  1950 1951 1952 1953 1954 1955 1956 1957 1958 1959 1960 1961 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034
# seas:  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
# Pot_fisheries_historical 0.0429402 0.02382 0.015587 0.0193322 0.0231427 0.0115396 0.0249568 0.0268909 0.019193 0.161887 0.017698 0.0213381 0.168745 0.265848 0.303578 0.277884 0.355635 0.332794 0.327763 0.406052 0.473862 0.527347 0.441442 0.511967 0.374048 0.254295 0.258834 0.174405 0.128518 0.195555 0.097091 0.191621 0.273522 0.187867 0.191098 0.328355 0.197755 1.08856 2.2752 3.65684 3.89034 0.742073 0.698685 1.34918 0.312729 0.284449 0.227964 0.426839 0.303072 0.236197 2.26956 1.1908 1.02558 1.62234 0.726186 8.99996 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# Pot_fisheries_u10 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8.23372 8.45387 8.00101 1.00732 1.0301 1.03864 0.977473 0.687583 0.796733 0.763198 0.836245 1.05216 1.16275 1.1636 0.784837 0.800681 0.787854 0.689728 0.597147 0.913069 0.908718 0.893609 0.885809 0.881485 0.878211 0.875633 0.873682 0.872224 0.871126
# Pot_fisheries_10to12 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.350503 0.14982 0.0813385 0.117742 0.176668 0.154025 0.21101 0.173758 0.153884 0.150629 0.143389 0.112342 0.1783 0.205864 0.177894 0.162754 0.150297 0.129463 0.0823048 0.166653 0.165859 0.163101 0.161678 0.160888 0.160291 0.15982 0.159464 0.159198 0.158998
# Pot_fisheries_o12 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00961748 0.0201219 0.0345249 0.0432486 0.0183867 0.00510293 0.0146678 0.00737197 0.0104531 0.012372 0.040531 0.0267237 0.0158594 0.00768436 0.00952752 0.00950775 0.0118182 0.0178279 0.0154585 0.0153848 0.015129 0.014997 0.0149237 0.0148683 0.0148247 0.0147916 0.014767 0.0147484
# Bycatch_fisheries_historical 0.000216904 0.000214301 0.000211175 0.000207955 0.000204941 0.00020216 0.000199674 0.000197646 0.00019592 0.000195253 0.000195327 0.00019451 0.000194576 0.000196586 0.000199998 0.000203962 0.000208366 0.000213358 0.000218099 0.000223063 0.000228956 0.000235732 0.000242368 0.000248386 0.000253657 0.00025584 0.000255597 0.000253606 0.000249314 0.000244281 0.000239208 0.000235049 0.000234575 0.000229095 0.000225707 0.000228939 0.000232444 0.000243752 0.000269971 0.000312949 0.000367798 0.00041235 0.000433823 0.000451488 0.00045426 0.0004316 0.00040643 0.000386641 0.000378698 0.000366323 0.000381859 0.000415735 0.000436308 0.000465515 0.000495561 0.000599647 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# Bycatch_fisheries_gillnet 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000721888 0.000674292 0.00208134 0.00196876 0.00178819 0.00345629 0.0040457 0.00264631 0.00262847 0.00111531 0.0014759 0.00148462 0.00063046 0.00085034 0.000837113 0.000270461 0.000524594 0.000310952 0.000165758 0.000403841 0.000401917 0.000395234 0.000391784 0.000389872 0.000388424 0.000387284 0.000386421 0.000385776 0.00038529
# Bycatch_fisheries_trawl 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000807536 0.000597668 0.00124881 0.00101051 0.00182325 0.00144643 0.001836 0.00112106 0.000341632 0.000324217 0.000411011 0.00019795 0.000241058 0.000360936 0.000328644 3.68811e-05 3.01491e-05 6.91004e-05 4.27762e-05 5.68108e-05 5.654e-05 5.56e-05 5.51147e-05 5.48456e-05 5.46419e-05 5.44815e-05 5.43601e-05 5.42694e-05 5.42011e-05
#
#_Q_setup for fleets with cpue or survey data
#_1:  fleet number
#_2:  link type: (1=simple q, 1 parm; 2=mirror simple q, 1 mirrored parm; 3=q and power, 2 parm; 4=mirror with offset, 2 parm)
#_3:  extra input for link, i.e. mirror fleet# or dev index number
#_4:  0/1 to select extra sd parameter
#_5:  0/1 for biasadj or not
#_6:  0/1 to float
#_   fleet      link link_info  extra_se   biasadj     float  #  fleetname
         1         1         0         1         1         1  #  Observer_inshore_u10
         3         1         0         1         1         1  #  Pot_fisheries_u10
         4         1         0         1         1         1  #  Pot_fisheries_10to12
         5         1         0         1         1         1  #  Pot_fisheries_o12
         8         1         0         1         1         1  #  Bycatch_fisheries_trawl
         9         1         0         1         1         1  #  Observer_prerecruit_u10
-9999 0 0 0 0 0
#
#_Q_parms(if_any);Qunits_are_ln(q)
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
           -50            50      -4.75561            -1             1             1         -1          0          0          0          0          0          0          0  #  LnQ_base_Observer_inshore_u10(1)
         1e-06           0.2     0.0337811           0.1             3             3          3          0          0          0          0          0          0          0  #  Q_extraSD_Observer_inshore_u10(1)
           -50            50      -7.21388            -5             1             1         -1          0          0          0          0          0          0          0  #  LnQ_base_Pot_fisheries_u10(3)
         1e-06           0.1    0.00490586           0.1             3             3          3          0          0          0          0          0          0          0  #  Q_extraSD_Pot_fisheries_u10(3)
           -50            50      -8.63315            -3             1             1         -1          0          0          0          0          0          0          0  #  LnQ_base_Pot_fisheries_10to12(4)
         1e-06           0.4      0.160899           0.1             3             3          3          0          0          0          0          0          0          0  #  Q_extraSD_Pot_fisheries_10to12(4)
           -50            50      -8.89772            -3             1             1         -1          0          0          0          0          0          0          0  #  LnQ_base_Pot_fisheries_o12(5)
         1e-06           0.4      0.159433           0.1             3             3          3          0          0          0          0          0          0          0  #  Q_extraSD_Pot_fisheries_o12(5)
           -50            99      -10.3897             4             1             1         -1          0          0          0          0          0          0          0  #  LnQ_base_Bycatch_fisheries_trawl(8)
         1e-06           0.2     0.0428628           0.1             3             3          3          0          0          0          0          0          0          0  #  Q_extraSD_Bycatch_fisheries_trawl(8)
           -50            99      -6.63788            10             1             1         -1          0          0          0          0          0          0          0  #  LnQ_base_Observer_prerecruit_u10(9)
         1e-06           0.5     0.0535688           0.1             3             3          3          0          0          0          0          0          0          0  #  Q_extraSD_Observer_prerecruit_u10(9)
#_no timevary Q parameters
#
#_size_selex_patterns
#Pattern:_0;  parm=0; selex=1.0 for all sizes
#Pattern:_1;  parm=2; logistic; with 95% width specification
#Pattern:_5;  parm=2; mirror another size selex; PARMS pick the min-max bin to mirror
#Pattern:_11; parm=2; selex=1.0  for specified min-max population length bin range
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_6;  parm=2+special; non-parm len selex
#Pattern:_43; parm=2+special+2;  like 6, with 2 additional param for scaling (mean over bin range)
#Pattern:_8;  parm=8; double_logistic with smooth transitions and constant above Linf option
#Pattern:_9;  parm=6; simple 4-parm double logistic with starting length; parm 5 is first length; parm 6=1 does desc as offset
#Pattern:_21; parm=2+special; non-parm len selex, read as pairs of size, then selex
#Pattern:_22; parm=4; double_normal as in CASAL
#Pattern:_23; parm=6; double_normal where final value is directly equal to sp(6) so can be >1.0
#Pattern:_24; parm=6; double_normal with sel(minL) and sel(maxL), using joiners
#Pattern:_2;  parm=6; double_normal with sel(minL) and sel(maxL), using joiners, back compatibile version of 24 with 3.30.18 and older
#Pattern:_25; parm=3; exponential-logistic in length
#Pattern:_27; parm=special+3; cubic spline in length; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=special+3+2; cubic spline; like 27, with 2 additional param for scaling (mean over bin range)
#_discard_options:_0=none;_1=define_retention;_2=retention&mortality;_3=all_discarded_dead;_4=define_dome-shaped_retention
#_Pattern Discard Male Special
 24 2 4 0 # 1 Observer_inshore_u10
 24 2 4 0 # 2 Pot_fisheries_historical
 24 2 4 0 # 3 Pot_fisheries_u10
 15 0 0 3 # 4 Pot_fisheries_10to12
 15 0 0 2 # 5 Pot_fisheries_o12
 23 0 0 0 # 6 Bycatch_fisheries_historical
 15 0 0 6 # 7 Bycatch_fisheries_gillnet
 15 0 0 6 # 8 Bycatch_fisheries_trawl
 15 0 0 1 # 9 Observer_prerecruit_u10
#
#_age_selex_patterns
#Pattern:_0; parm=0; selex=1.0 for ages 0 to maxage
#Pattern:_10; parm=0; selex=1.0 for ages 1 to maxage
#Pattern:_11; parm=2; selex=1.0  for specified min-max age
#Pattern:_12; parm=2; age logistic
#Pattern:_13; parm=8; age double logistic. Recommend using pattern 18 instead.
#Pattern:_14; parm=nages+1; age empirical
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_16; parm=2; Coleraine - Gaussian
#Pattern:_17; parm=nages+1; empirical as random walk  N parameters to read can be overridden by setting special to non-zero
#Pattern:_41; parm=2+nages+1; // like 17, with 2 additional param for scaling (mean over bin range)
#Pattern:_18; parm=8; double logistic - smooth transition
#Pattern:_19; parm=6; simple 4-parm double logistic with starting age
#Pattern:_20; parm=6; double_normal,using joiners
#Pattern:_26; parm=3; exponential-logistic in age
#Pattern:_27; parm=3+special; cubic spline in age; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=2+special+3; // cubic spline; with 2 additional param for scaling (mean over bin range)
#Age patterns entered with value >100 create Min_selage from first digit and pattern from remainder
#_Pattern Discard Male Special
 0 0 0 0 # 1 Observer_inshore_u10
 0 0 0 1 # 2 Pot_fisheries_historical
 0 0 0 1 # 3 Pot_fisheries_u10
 0 0 0 1 # 4 Pot_fisheries_10to12
 0 0 0 1 # 5 Pot_fisheries_o12
 0 0 0 1 # 6 Bycatch_fisheries_historical
 0 0 0 1 # 7 Bycatch_fisheries_gillnet
 0 0 0 1 # 8 Bycatch_fisheries_trawl
 0 0 0 1 # 9 Observer_prerecruit_u10
#
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
# 1   Observer_inshore_u10 LenSelex
             5            22       8.96991           9.6            99             6          1          0          0          0          0          0          0          0  #  Size_DblN_peak_Observer_inshore_u10(1)
           -50             9      -11.8256            -8            99             6          3          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Observer_inshore_u10(1)
            -9             9       0.81311           1.2            99             6          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Observer_inshore_u10(1)
            -9             9       1.99332           1.6            99             6          3          0          0          0          0          0          0          0  #  Size_DblN_descend_se_Observer_inshore_u10(1)
           -35            50          -999           -12            99             6        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Observer_inshore_u10(1)
           -90            30      -8.75015           -13            99             6          3          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Observer_inshore_u10(1)
             8             9           8.5           8.5             1             1          2          0          0          0          0          0          2          2  #  Retain_L_infl_Observer_inshore_u10(1)
         1e-06           500           250             5             1             1          2          0          0          0          0          0          2          2  #  Retain_L_width_Observer_inshore_u10(1)
           -50           500       5.15788             5            99             6          3          0          0          0          0          0          2          2  #  Retain_L_asymptote_logit_Observer_inshore_u10(1)
           -50           500      0.275333           0.1            99             6          3          0          0          0          0          0          2          2  #  Retain_L_maleoffset_Observer_inshore_u10(1)
             0            15      0.620556           0.5            99             0         -4          0          0          0          0          0          0          0  #  DiscMort_L_infl_Observer_inshore_u10(1)
             0            10     0.0827097             5            99             0         -4          0          0          0          0          0          0          0  #  DiscMort_L_width_Observer_inshore_u10(1)
             0             1    0.00050554           0.1            99             0         -5          0          0          0          0          0          0          0  #  DiscMort_L_level_old_Observer_inshore_u10(1)
           -50            50       1.00916             1            99             0         -5          0          0          0          0          0          0          0  #  DiscMort_L_male_offset_Observer_inshore_u10(1)
           -20            20     0.0072385            -2           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_Observer_inshore_u10(1)
           -20            20     -0.105646            -1           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_Observer_inshore_u10(1)
           -20            20     -0.655818             0           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_Observer_inshore_u10(1)
           -20            20       2.18501             0           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Final_Observer_inshore_u10(1)
             0             1      0.965153           0.5           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_Observer_inshore_u10(1)
# 2   Pot_fisheries_historical LenSelex
             2            22       6.28556           7.5             1             1          1          0          0          0          0          0          0          0  #  Size_DblN_peak_Pot_fisheries_historical(2)
           -60            10           -25           -25             1             1          3          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Pot_fisheries_historical(2)
           -30             9       1.92377           2.5             1             1          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Pot_fisheries_historical(2)
            -1             9       2.91152             2            99             6          3          0          0          0          0          0          0          0  #  Size_DblN_descend_se_Pot_fisheries_historical(2)
           -35            50          -999            -5            99             6        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Pot_fisheries_historical(2)
           -90            50       -20.007           -13             1             1          3          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Pot_fisheries_historical(2)
           8.2             9       8.31479           8.5             1             1          2          0          0          0          0          0          2          2  #  Retain_L_infl_Pot_fisheries_historical(2)
             0             1      0.109177           0.5             1             1          2          0          0          0          0          0          2          2  #  Retain_L_width_Pot_fisheries_historical(2)
           -10            10       1.76562             1             1             1          3          0          0          0          0          0          2          2  #  Retain_L_asymptote_logit_Pot_fisheries_historical(2)
           -10            10     0.0467574             1            99             6          3          0          0          0          0          0          2          2  #  Retain_L_maleoffset_Pot_fisheries_historical(2)
             0            15      0.620556             3            99             0         -4          0          0          0          0          0          0          0  #  DiscMort_L_infl_Pot_fisheries_historical(2)
             0            10     0.0827097             5            99             0         -4          0          0          0          0          0          0          0  #  DiscMort_L_width_Pot_fisheries_historical(2)
             0             1    0.00050554          0.01            99             0         -5          0          0          0          0          0          0          0  #  DiscMort_L_level_old_Pot_fisheries_historical(2)
           -10            10       1.00916             1            99             0         -5          0          0          0          0          0          0          0  #  DiscMort_L_male_offset_Pot_fisheries_historical(2)
           -20            20       1.34912            -2           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_Pot_fisheries_historical(2)
           -20            20       1.12483            -1           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_Pot_fisheries_historical(2)
           -20            20     -0.218847             0           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_Pot_fisheries_historical(2)
           -20            20   -0.00217568             0           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Final_Pot_fisheries_historical(2)
             0             1      0.990013           0.5           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_Pot_fisheries_historical(2)
# 3   Pot_fisheries_u10 LenSelex
             3            22       6.46157           7.5             1             3          1          0          0          0          0          0          0          0  #  Size_DblN_peak_Pot_fisheries_u10(3)
           -20            10      -1.63616          -1.3             1             1          3          0          0          0          0          0          0          0  #  Size_DblN_top_logit_Pot_fisheries_u10(3)
           -90            10           -40            -5             1             1          3          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_Pot_fisheries_u10(3)
            -5             9       1.81019             2            99             6          3          0          0          0          0          0          0          0  #  Size_DblN_descend_se_Pot_fisheries_u10(3)
           -35             9          -999           -11            99             6        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_Pot_fisheries_u10(3)
           -30             9       -11.439           -13             1             1          3          0          0          0          0          0          0          0  #  Size_DblN_end_logit_Pot_fisheries_u10(3)
           8.2             9           8.6           8.5             1             1          2          0          0          0          0          0          2          2  #  Retain_L_infl_Pot_fisheries_u10(3)
             0           900           450             5             1             1          2          0          0          0          0          0          2          2  #  Retain_L_width_Pot_fisheries_u10(3)
           -90           900       5.09212             5            99             6          3          0          0          0          0          0          2          2  #  Retain_L_asymptote_logit_Pot_fisheries_u10(3)
           -90           500      0.189062           0.1            99             6          3          0          0          0          0          0          2          2  #  Retain_L_maleoffset_Pot_fisheries_u10(3)
             0            15      0.620556             3            99             0         -4          0          0          0          0          0          0          0  #  DiscMort_L_infl_Pot_fisheries_u10(3)
             0            10     0.0827097             0            99             0         -4          0          0          0          0          0          0          0  #  DiscMort_L_width_Pot_fisheries_u10(3)
             0             1    0.00050554          0.01            99             0         -5          0          0          0          0          0          0          0  #  DiscMort_L_level_old_Pot_fisheries_u10(3)
           -50            50       1.00916             1            99             0         -5          0          0          0          0          0          0          0  #  DiscMort_L_male_offset_Pot_fisheries_u10(3)
           -20            20        -0.224            -2           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_Pot_fisheries_u10(3)
           -20            20  -3.53764e-08            -1           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_Pot_fisheries_u10(3)
           -20            20      0.212946             0           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_Pot_fisheries_u10(3)
           -20            20      -1.56453             0           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Final_Pot_fisheries_u10(3)
             0             1      0.977796           0.5           0.1             1          4          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_Pot_fisheries_u10(3)
# 4   Pot_fisheries_10to12 LenSelex
# 5   Pot_fisheries_o12 LenSelex
# 6   Bycatch_fisheries_historical LenSelex
             2            22             8             8            99             0        -99          0          0          0          0          0          0          0  #  SizeSel_P1_Bycatch_fisheries_historical(6)
           -10            10             1             0            99             0        -99          0          0          0          0          0          0          0  #  SizeSel_P2_Bycatch_fisheries_historical(6)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SizeSel_P3_Bycatch_fisheries_historical(6)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  SizeSel_P4_Bycatch_fisheries_historical(6)
           -10            10          -999             0            99             0        -99          0          0          0          0          0          0          0  #  SizeSel_P5_Bycatch_fisheries_historical(6)
           -10            10             1             0            99             0        -99          0          0          0          0          0          0          0  #  SizeSel_P6_Bycatch_fisheries_historical(6)
# 7   Bycatch_fisheries_gillnet LenSelex
# 8   Bycatch_fisheries_trawl LenSelex
# 9   Observer_prerecruit_u10 LenSelex
# 1   Observer_inshore_u10 AgeSelex
# 2   Pot_fisheries_historical AgeSelex
# 3   Pot_fisheries_u10 AgeSelex
# 4   Pot_fisheries_10to12 AgeSelex
# 5   Pot_fisheries_o12 AgeSelex
# 6   Bycatch_fisheries_historical AgeSelex
# 7   Bycatch_fisheries_gillnet AgeSelex
# 8   Bycatch_fisheries_trawl AgeSelex
# 9   Observer_prerecruit_u10 AgeSelex
#_No_Dirichlet parameters
# timevary selex parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type    PHASE  #  parm_name
           8.5             9          8.75           8.7             1             1      2  # Retain_L_infl_Observer_inshore_u10(1)_BLK2repl_1993
           8.7           9.2       8.84659             9             1             1      2  # Retain_L_infl_Observer_inshore_u10(1)_BLK2repl_1997
         1e-06           900           450            10             1             1      2  # Retain_L_width_Observer_inshore_u10(1)_BLK2repl_1993
             0             2      0.113857           0.1             1             1      2  # Retain_L_width_Observer_inshore_u10(1)_BLK2repl_1997
           -10           900           445            10             1             1      3  # Retain_L_asymptote_logit_Observer_inshore_u10(1)_BLK2repl_1993
           -10            10       1.21478             1             1             1      3  # Retain_L_asymptote_logit_Observer_inshore_u10(1)_BLK2repl_1997
           -10           900           445            10             1             1      3  # Retain_L_maleoffset_Observer_inshore_u10(1)_BLK2repl_1993
           -10            10      0.031412          0.05             1             1      3  # Retain_L_maleoffset_Observer_inshore_u10(1)_BLK2repl_1997
           8.5             9       8.59601           8.7             1             1      2  # Retain_L_infl_Pot_fisheries_historical(2)_BLK2repl_1993
           8.7           9.3       8.76866             9             1             1      2  # Retain_L_infl_Pot_fisheries_historical(2)_BLK2repl_1997
             0             2      0.100062             1             1             1      2  # Retain_L_width_Pot_fisheries_historical(2)_BLK2repl_1993
             0             1      0.138904             1             1             1      2  # Retain_L_width_Pot_fisheries_historical(2)_BLK2repl_1997
           -10            10       2.09235             1             1             1      3  # Retain_L_asymptote_logit_Pot_fisheries_historical(2)_BLK2repl_1993
           -10            10       2.71124             1             1             1      3  # Retain_L_asymptote_logit_Pot_fisheries_historical(2)_BLK2repl_1997
           -10            10     0.0155982             0             1             1      3  # Retain_L_maleoffset_Pot_fisheries_historical(2)_BLK2repl_1993
           -10            10     0.0232465             0             1             1      3  # Retain_L_maleoffset_Pot_fisheries_historical(2)_BLK2repl_1997
           8.5             9          8.75           8.7             1             1      2  # Retain_L_infl_Pot_fisheries_u10(3)_BLK2repl_1993
           8.7           9.3       8.79854             9             1             1      2  # Retain_L_infl_Pot_fisheries_u10(3)_BLK2repl_1997
         1e-06           900           450            10             1             1      2  # Retain_L_width_Pot_fisheries_u10(3)_BLK2repl_1993
             0             1     0.0946603           0.3             1             1      2  # Retain_L_width_Pot_fisheries_u10(3)_BLK2repl_1997
           -10           900           445             5             1             1      3  # Retain_L_asymptote_logit_Pot_fisheries_u10(3)_BLK2repl_1993
           -10            10       3.10588             2             1             1      3  # Retain_L_asymptote_logit_Pot_fisheries_u10(3)_BLK2repl_1997
           -10           900           445            10             1             1      3  # Retain_L_maleoffset_Pot_fisheries_u10(3)_BLK2repl_1993
           -10            10    -0.0384866             0             1             1      3  # Retain_L_maleoffset_Pot_fisheries_u10(3)_BLK2repl_1997
# info on dev vectors created for selex parms are reported with other devs after tag parameter section 
#
0   #  use 2D_AR1 selectivity? (0/1)
#_no 2D_AR1 selex offset used
#_specs:  fleet, ymin, ymax, amin, amax, sigma_amax, use_rho, len1/age2, devphase, before_range, after_range
#_sigma_amax>amin means create sigma parm for each bin from min to sigma_amax; sigma_amax<0 means just one sigma parm is read and used for all bins
#_needed parameters follow each fleet's specifications
# -9999  0 0 0 0 0 0 0 0 0 0 # terminator
#
# Tag loss and Tag reporting parameters go next
0  # TG_custom:  0=no read and autogen if tag data exist; 1=read
#_Cond -6 6 1 1 2 0.01 -4 0 0 0 0 0 0 0  #_placeholder if no parameters
#
# deviation vectors for timevary parameters
#  base   base first block   block  env  env   dev   dev   dev   dev   dev
#  type  index  parm trend pattern link  var  vectr link _mnyr  mxyr phase  dev_vector
#      1    22     1     0     0     0     0     1     1  1950  2005     1 7.61182e-07 5.63162e-07 4.6813e-07 7.35176e-07 1.08551e-06 6.68688e-07 1.82194e-06 2.38275e-06 2.09316e-06 2.09916e-05 2.95804e-06 4.39558e-06 3.92074e-05 6.8678e-05 9.22831e-05 0.000106423 0.000171521 0.000204905 0.000270722 0.000548457 0.00102772 0.00175159 0.00233763 0.0041781 0.00478437 0.00522372 0.0089167 0.0106449 0.013792 0.0326875 0.0159723 -0.0529843 -0.295494 0.0580131 0.0917547 -0.272905 0.170467 -0.630003 -0.969378 -0.710088 -0.747275 -0.0165375 -0.0756238 -0.427454 -0.0826486 -0.0719478 -0.148799 0.119602 0.509666 0.569645 -0.705002 -0.155494 -0.0421618 -0.380739 -0.150762 -1.52041
#      1    23     3     0     0     0     0     2     1  1950  2005     1 2.84569e-10 -5.87078e-09 1.1712e-08 -2.49284e-09 -1.28738e-08 6.68492e-09 -1.24488e-08 -1.43066e-08 -3.45624e-09 -1.69363e-09 1.29349e-09 -1.45461e-08 -2.99958e-08 -3.01809e-08 -2.7248e-08 -8.27021e-08 -8.47736e-08 -1.00135e-07 -1.36198e-07 1.00275e-07 4.81091e-07 1.15282e-06 2.42173e-06 4.32509e-06 7.3342e-06 1.25292e-05 2.25445e-05 4.65762e-05 0.000106776 0.000215259 0.000207053 4.45812e-05 -0.000192454 0.000760369 0.000654944 -0.000704284 -0.000729993 -0.00167413 -0.00196232 -0.00195494 -0.00130166 -0.000782132 -0.000982174 -0.000249828 0.000955577 0.00143217 0.00161467 0.00169528 0.000131741 -0.000640416 -0.00218938 -0.00213144 -0.00281549 -0.00325906 -0.00391851 -0.00439952
#      5     7     5     2     2     0     0     0     0     0     0     0
#      5     8     7     2     2     0     0     0     0     0     0     0
#      5     9     9     2     2     0     0     0     0     0     0     0
#      5    10    11     2     2     0     0     0     0     0     0     0
#      5    26    13     2     2     0     0     0     0     0     0     0
#      5    27    15     2     2     0     0     0     0     0     0     0
#      5    28    17     2     2     0     0     0     0     0     0     0
#      5    29    19     2     2     0     0     0     0     0     0     0
#      5    45    21     2     2     0     0     0     0     0     0     0
#      5    46    23     2     2     0     0     0     0     0     0     0
#      5    47    25     2     2     0     0     0     0     0     0     0
#      5    48    27     2     2     0     0     0     0     0     0     0
     #
# Input variance adjustments factors: 
 #_1=add_to_survey_CV
 #_2=add_to_discard_stddev
 #_3=add_to_bodywt_CV
 #_4=mult_by_lencomp_N
 #_5=mult_by_agecomp_N
 #_6=mult_by_size-at-age_N
 #_7=mult_by_generalized_sizecomp
#_Factor  Fleet  Value
      1      1         0
      4      1   5.63831
      1      2         0
      4      2   46.5813
      1      3         0
      4      3   2.83373
      1      4         0
      1      5         0
      1      7         0
      1      8         0
 -9999   1    0  # terminator
#
4 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 7 changes to default Lambdas (default value is 1.0)
# Like_comp codes:  1=surv; 2=disc; 3=mnwt; 4=length; 5=age; 6=SizeFreq; 7=sizeage; 8=catch; 9=init_equ_catch; 
# 10=recrdev; 11=parm_prior; 12=parm_dev; 13=CrashPen; 14=Morphcomp; 15=Tag-comp; 16=Tag-negbin; 17=F_ballpark; 18=initEQregime
#like_comp fleet  phase  value  sizefreq_method
 1 1 2 1 1
 1 4 2 1 1
 4 1 2 1 1
 8 2 2 1 1
 4 2 2 1 1
 8 3 2 1 1
 4 3 2 1 1
-9999  1  1  1  1  #  terminator
#
# lambdas (for info only; columns are phases)
#  1 1 1 1 #_CPUE/survey:_1
#  0 0 0 0 #_CPUE/survey:_2
#  1 1 1 1 #_CPUE/survey:_3
#  1 1 1 1 #_CPUE/survey:_4
#  1 1 1 1 #_CPUE/survey:_5
#  0 0 0 0 #_CPUE/survey:_6
#  0 0 0 0 #_CPUE/survey:_7
#  1 1 1 1 #_CPUE/survey:_8
#  1 1 1 1 #_CPUE/survey:_9
#  1 1 1 1 #_discard:_1
#  1 1 1 1 #_discard:_2
#  1 1 1 1 #_discard:_3
#  0 0 0 0 #_discard:_4
#  0 0 0 0 #_discard:_5
#  0 0 0 0 #_discard:_6
#  0 0 0 0 #_discard:_7
#  0 0 0 0 #_discard:_8
#  0 0 0 0 #_discard:_9
#  1 1 1 1 #_lencomp:_1
#  1 1 1 1 #_lencomp:_2
#  1 1 1 1 #_lencomp:_3
#  0 0 0 0 #_lencomp:_4
#  0 0 0 0 #_lencomp:_5
#  0 0 0 0 #_lencomp:_6
#  0 0 0 0 #_lencomp:_7
#  0 0 0 0 #_lencomp:_8
#  0 0 0 0 #_lencomp:_9
#  1 1 1 1 #_init_equ_catch1
#  1 1 1 1 #_init_equ_catch2
#  1 1 1 1 #_init_equ_catch3
#  1 1 1 1 #_init_equ_catch4
#  1 1 1 1 #_init_equ_catch5
#  1 1 1 1 #_init_equ_catch6
#  1 1 1 1 #_init_equ_catch7
#  1 1 1 1 #_init_equ_catch8
#  1 1 1 1 #_init_equ_catch9
#  1 1 1 1 #_recruitments
#  1 1 1 1 #_parameter-priors
#  1 1 1 1 #_parameter-dev-vectors
#  1 1 1 1 #_crashPenLambda
#  0 0 0 0 # F_ballpark_lambda
0 # (0/1/2) read specs for more stddev reporting: 0 = skip, 1 = read specs for reporting stdev for selectivity, size, and numbers, 2 = add options for M,Dyn. Bzero, SmryBio
 # 0 2 0 0 # Selectivity: (1) fleet, (2) 1=len/2=age/3=both, (3) year, (4) N selex bins
 # 0 0 # Growth: (1) growth pattern, (2) growth ages
 # 0 0 0 # Numbers-at-age: (1) area(-1 for all), (2) year, (3) N ages
 # -1 # list of bin #'s for selex std (-1 in first bin to self-generate)
 # -1 # list of ages for growth std (-1 in first bin to self-generate)
 # -1 # list of ages for NatAge std (-1 in first bin to self-generate)
999

