source("libraries.R")
source("functions.R")


# parameters --------------------------------------------------------------

# % threshold of missing to drop variable 
k_mis_var = 45

# read tabla --------------------------------------------------------------

# tot
base = readRDS(file="data/working/tabla.rds")
# ids
base_ids = base %>%
  select(starts_with("id_"))
# targets
base_y = base %>%
  select(starts_with("y_"))
# numeric (without id and targets)
base_num = base %>%
  select_if(is.numeric) %>% 
  select(-starts_with("id_")) %>% 
  select(-starts_with("y_")) 
# categorical 
base_cat = base %>%
  select_if(function(x) !is.numeric(x)) 


# missing analysis --------------------------------------------------------

# missing per row
mis_row = base %>% 
  mutate(
    misperc = apply(base, 1, function(x) sum(is.na(x))/length(x)*100 )
    ) %>% 
  select(id_tot, misperc) %>% 
  arrange(-misperc)

# missing per variable
mis_col = skimr::skim_to_wide(base) %>% 
  mutate(misperc = as.numeric(missing)/as.numeric(n)*100) %>% 
  select(variable, misperc) %>% 
  arrange(-misperc)  


# clean data -----------------------------------------------------

# NOTA: NO SE INCLUYE METODO DE IMPUTACION PARA VARIABLES NO NUMERICAS
# (porque luego no se terminan usando)
# (incluir si se usan para outliers y/o gam)

# vars to drop (exceed missing% threshold)
vars_drop_mis = mis_col %>%
  dplyr::filter(misperc>k_mis_var) %$% variable

# clean
base_clean = base_num %>% 
  # drop numeric with high missing%
  select(-one_of(vars_drop_mis)) %>% 
  # impute numeric NA with median polish
  imp_medpol() %>% 
  # bind with categorical and ids
    {bind_cols(base_ids,
               base_cat,
               base_y,
               .)} %>%
  # drop categorical with high missing% (warning message if there are none)
  select(-one_of(vars_drop_mis)) %>%
  # drop obs where targets (y_*) are missing (ninguna por ahora)
  drop_na(starts_with("y_"))


# save tabla --------------------------------------------------------------

saveRDS(base_clean, "data/working/base_clean_01.rds")


# old ---------------------------------------------------------------------

# base_clean = base_num %>% 
#   # impute NAs in numeric with median 
#   mutate_all(
#     function(x) ifelse(is.na(x), median(x, na.rm=T), x)
#   ) %>% 
#   {bind_cols(base_ids,
#              base_cat,
#              .)} %>% 
#   # drop vars with high perc of missing
#   select(-vars_drop_mis)
