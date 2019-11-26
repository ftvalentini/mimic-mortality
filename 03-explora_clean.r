source("libraries.R")
source("functions.R")

# parameters --------------------------------------------------------------


# read clean base --------------------------------------------------------------

base = readRDS("data/working/base_clean_01.rds")

# numeric (without id)
base_num = base %>%
  select_if(is.numeric) %>% 
  select(-starts_with("id_")) %>% 
  select(-starts_with("y_")) %>% 
  select(-starts_with("score_"))


# univariate --------------------------------------------------------------

# skimr::skim(base_num)
# inspeccion visual de minimos y maximos
top10 = base_num %>% map(function(x) tail(sort(x),10)) %>% "["(sort(names(.)))
bottom10 = base_num %>% map(function(x) head(sort(x),10)) %>% "["(sort(names(.)))


# clean outliers ----------------------------------------------------------

# por inspeccion visual se detecta que solo en urineoutput hay outliers brutales:
  # 3 registros negativos y 1 con valor demasiado alto
# tambien se elimina el unico registro con bun_min y bun_max negativo por las dudas

base_clean = base %>% 
  dplyr::filter(!(urineoutput<0 | urineoutput>100000)) %>% 
  dplyr::filter(!(bun_min<0 | bun_max<0)) 


# save tabla --------------------------------------------------------------

saveRDS(base_clean, "data/working/base_clean_02.rds")


