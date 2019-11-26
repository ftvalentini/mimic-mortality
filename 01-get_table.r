
# intro -------------------------------------------------------------------

source("libraries.R")
source("functions.R")

# connection --------------------------------------------------------------

source("00-connection.r")

# input tables or views ---------------------------------------------------

# sacar "fv" de "vitalsfirstdayfv" si no se usan trends que puse
t_firstday = c(
  "icustays"
  ,"gcsfirstday", "heightfirstday", "labsfirstday", "rrtfirstday"            
  ,"uofirstday", "ventfirstday", "vitalsfirstdayfv", "weightfirstday"
  ,"icustay_detail"
  ,"sofa","sapsii","oasis"
  ,"martin_sepsis"
)
for (t in t_firstday) assign(t, tbl(mimic,t))


# make query ---------------------------------------------------------------------
library(dbplyr)

stays = icustays %>% 
  # remove stays with transfers (seguro?)
  dplyr::filter((first_wardid == last_wardid) & (first_careunit == last_careunit)) %>% 
  # only admissions to MICU (seguro? CAMBIA NROW POR MUCHO 30K vs 10K)
  dplyr::filter(first_careunit=='MICU') %>%
  # only metavision (or carevue) dbsource (seguro? usarlo si hace falta bajar el n) %>% 
  # dplyr::filter(dbsource=='carevue') %>% 
  # get stays details (data from admits and pats)
  select(subject_id,hadm_id,icustay_id) %>% 
  inner_join(icustay_detail, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  # only first hospital stays AND first icu stays
  dplyr::filter(first_hosp_stay==T & first_icu_stay==T) %>% 
  # only records without outlier ages (6% tienen age aprox 300!!!)
  dplyr::filter(admission_age<110)

# remove multiple stays per admit
keep_admits = stays %>%
  group_by(hadm_id) %>% 
  summarise(n=count(icustay_id)) %>% 
  dplyr::filter(n>=1 & n<=1) %>% 
  select(hadm_id)

# join stays-admits
stays = stays %>% 
  inner_join(keep_admits, by='hadm_id') %>% 
  mutate(
    # create mortality in hospital
    mortality_inhospital = ( (!is.na(dod)) & (admittime <= dod) & (dischtime >= dod) ),
    # create mortality in unit
    mortality_inunit = ( (!is.na(dod)) & (intime <= dod) & (outtime >= dod) ),
    # create 30-day mortality
    mortality_30 = ( (!is.na(dod)) & (DATE_PART('day',dod-admittime) < 30) ),
    # create 7-day mortality
    mortality_7 = ( (!is.na(dod)) & (DATE_PART('day',dod-admittime) < 7) )
  ) 

# get data from first 24hs, scores and sepsis flag
base = stays %>% 
  inner_join(gcsfirstday, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  inner_join(heightfirstday, by=c('icustay_id')) %>% 
  inner_join(rrtfirstday, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  inner_join(uofirstday, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  inner_join(ventfirstday, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  inner_join(labsfirstday, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  # aca usa fv, version modificada que agrega trend
  # glucose_min y glucose_max are also in labs -> agrega suffix
  inner_join(vitalsfirstdayfv, by=c('subject_id', 'hadm_id', 'icustay_id'),
             suffix=c("_labs","_vitals")) %>% 
  inner_join(weightfirstday, by=c('icustay_id')) %>% 
  inner_join(sofa, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  inner_join(sapsii, by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  inner_join(oasis %>% select(subject_id, hadm_id, icustay_id
                              ,mechvent ,electivesurgery
                              , oasis,oasis_prob)
             , by=c('subject_id', 'hadm_id', 'icustay_id')) %>% 
  inner_join(martin_sepsis, by=c('subject_id', 'hadm_id'))


# collect query -----------------------------------------------------------

tabla = collect(base)

# mutate vars -------------------------------------------------------------

# not useful vars
k_remove = c(
  "dod","admittime","dischtime","intime", "outtime","hospital_expire_flag"
  ,"hospstay_seq", "icustay_seq","first_hosp_stay", "first_icu_stay"
  # usamos weight a secas que combina todas
  ,"weight_admit","weight_daily","weight_echoinhosp","weight_echoprehosp"
  #vars de tabla sofa
  ,"respiration","coagulation","liver","cardiovascular.x","cns","renal.x"
  #vars de tabla sapsii
  ,"age_score","hr_score","sysbp_score","temp_score","pao2fio2_score","uo_score"
  ,"bun_score","wbc_score","potassium_score","sodium_score","bicarbonate_score"
  ,"bilirubin_score","gcs_score","comorbidity_score","admissiontype_score"
  #vars de tabla martin_sepsis
  ,"organ_failure","respiratory","cardiovascular.y","renal.y","hepatic"
  ,"hematologic","metabolic","neurologic"
)
tabla = tabla %>% 
  # remove not useful vars
  select(-k_remove) %>% 
  # rename targets as y_*
  rename(y_morh = mortality_inhospital,
         y_moru = mortality_inunit,
         y_mor30 = mortality_30,
         y_mor7 = mortality_7,
         y_seps = sepsis,
         y_losh = los_hospital,
         y_losu = los_icu) %>% 
  # rename scores as score_*
  rename(
    score_sofa = sofa
    ,score_sapsii = sapsii
    ,score_sapsiiprob = sapsii_prob
    ,score_oasis = oasis
    ,score_oasisprob = oasis_prob
         ) %>% 
  # rename ids as id_*
  rename(id_subject = subject_id,
         id_hadm = hadm_id,
         id_icustay = icustay_id) %>% 
  # create id unico as 1:nrow
  mutate(id_tot = 1:nrow(.)) %>% 
  # binarias as logical
  mutate(
    endotrachflag = as.logical(endotrachflag)
    ,vent = as.logical(vent)
    ,rrt = as.logical(rrt)
    ,mechvent = as.logical(mechvent)
    ,electivesurgery = as.logical(electivesurgery)
  ) %>% 
  mutate_at(vars(y_morh, y_moru, y_mor30, y_mor7, y_seps), as.logical)

# transform ethnicity
tabla$ethnicity = tabla$ethnicity %>%
  stringr::str_replace_all(' OR ','/') %>% 
  stringr::str_split(" - ", simplify=T) %>% "["(,1) %>% 
  stringr::str_split("/", simplify=T) %>% "["(,1) %>% 
  {case_when(
    . %in% c("UNKNOWN","PATIENT DECLINED TO ANSWER","UNABLE TO OBTAIN") ~ NA_character_,
    . %in% c("SOUTH AMERICAN") ~ "HISPANIC",
    . %in% c("PORTUGUESE") ~ "WHITE",
    . %in% c("AMERICAN INDIAN","CARIBBEAN ISLAND","NATIVE HAWAIIAN","OTHER",
             "MULTI RACE ETHNICITY","MIDDLE EASTERN") ~ "OTHER",
    T ~ .)}

# glasgow coma scale (gcs) as ordered factor
tabla = tabla %>% 
  mutate_at(vars(gcsmotor, gcsverbal, gcseyes, mingcs),
            function(x) forcats::fct_inseq(factor(x), ordered=T))

# save tabla --------------------------------------------------------------

saveRDS(tabla, "data/working/tabla.rds")

# end connection --------------------------------------------------------------

dbDisconnect(mimic)



