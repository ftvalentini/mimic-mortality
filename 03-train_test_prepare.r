source("libraries.R")
source("functions.R")

# NOTA:
# usar variables binarias genera problemas en gamsel
# salta error de pocos valores unicos

# parameters --------------------------------------------------------------

semilla = 1993
perc_train = 0.85

target = "y_mor7"

# read clean base --------------------------------------------------------------

base = readRDS("data/working/base_clean_02.rds")

# split train-test --------------------------------------------------------

set.seed(seed = semilla) 
train_test_split = rsample::initial_split(data=base, prop=perc_train) 
base_train = train_test_split %>% rsample::training() 
base_test = train_test_split %>% rsample::testing()

# prepare training data for GAM -------------------------------------------

# 1. only numeric features
base_num_train = base_train %>%
  select_if(is.numeric) %>%
  select(-starts_with("id_")) %>% 
  select(-starts_with("score_")) %>%
  select(-starts_with("y_")) 

# 2. standardized with training mean and SD
# means and sds of training data
stats_train = base_num_train %>%
  map(function(x) list(mean=mean(x), sd=sd(x)))
x0_train = base_num_train %>%
  mutate_if(is.numeric, function(x) scale(x, center=T, scale=T)) %>% 
  as.data.frame()

# get target  
y_train = base_train[[target]] %>% as.numeric()

# APPENDIX: 3.Remove vars conflictivas (falta entender por qué)
# (al parecer es por poca variabilidad -- aunque el warning dice valores unicos)
# SE IDENTIFICARON CON:
# A.
# X %>% map(minmax) %>% map_dbl(sd) %>% sort() %>% head()
# o B.
# encontrando las vars que hacen que pseudo.bases(as.matrix(X)) no corra
# y luego las que hacen que cv.gamsel no corra (no es lo mismo porque parte en folds)
varsc = c(
  "respratebp_trend"
  ,"heartrate_trend"
  ,"sysbp_trend"
)
x_train_gam = x0_train %>% select(-varsc)

# prepare test data for GAM ----------------------------------------------------

# 1. only numeric features
base_num_test = base_test %>%
  select_if(is.numeric) %>%
  select(-starts_with("id_")) %>% 
  select(-starts_with("score_")) %>%
  select(-starts_with("y_")) 

# 2. standardized with training mean and SD
# means and sds of training data
x0_test = map2_df(.x=base_num_test, .y=stats_train,
                  function(x,y) scale(x, center=y$mean, scale=y$sd)) %>% 
  as.data.frame()

# 3.Remove vars conflictivas
x_test_gam = x0_test %>% select(-varsc)

# prepare training data for AUTOENCODER -------------------------------------

# 1. only numeric features
# USE base_num_train 

# 2. normalize with minmax
# mins and maxs of training data
minmax_train = base_num_train %>%
  map(function(x) list(min=min(x), max=max(x)))
x0_train = base_num_train %>%
  mutate_if(is.numeric, minmax) %>% 
  as.data.frame()

# 3. Remove vars conflictivas de GAM 
# not done because capa interna queda con una dimension
# x_train_auto = x0_train %>% select(-varsc)
x_train_auto = x0_train %>% as.matrix()

# prepare test data for AUTOENCODER ----------------------------------------

# 1. only numeric features
# use base_num_test

# 2. normalize with trainings' mins and maxs
x0_test = map2_df(.x=base_num_test, .y=minmax_train,
                  function(x,y) minmax(x, min=y$min, max=y$max)) %>% 
  as.data.frame()

# 3.Remove vars conflictivas de GAM
# not done
# x_test_auto = x0_test %>% select(-varsc)
x_test_auto = x0_test %>% as.matrix()


# prepare training data for KSD -------------------------------------

# 1. only numeric features
# USE base_num_train 
x0_train = base_num_train

# 2. Remove vars conflictivas de GAM
# not done
# x_train_ksd = x0_train %>% select(-varsc)
x_train_ksd = x0_train

# scaling is done in the function

# prepare test data for KSD -------------------------------------------

# 1. only numeric features
# use base_num_test
x0_test = base_num_test

# 2. Remove vars conflictivas de GAM
# not done
# x_test_ksd = x0_test %>% select(-varsc)
x_test_ksd = x0_test

# scaling is donde in the function

# keep  scores and target ---------------------------------------------

# scores
scores_test = base_test %>% select(starts_with("score_"))
scores_train = base_train %>% select(starts_with("score_"))
# target 
y_train = base_train[[target]] %>% as.numeric()
y_test = base_test[[target]] %>% as.numeric()


# save --------------------------------------------------------------------

# not prepared data
saveRDS(base_train, "data/working/x_train_raw.rds")
saveRDS(base_test, "data/working/x_test_raw.rds")
# target
saveRDS(y_train, "data/working/y_train.rds")
saveRDS(y_test, "data/working/y_test.rds")
# scores
saveRDS(scores_test, "data/working/scores_test.rds")
saveRDS(scores_train, "data/working/scores_train.rds")

# prepared data for GAM
saveRDS(x_train_gam, "data/working/x_train_gam.rds")
saveRDS(x_test_gam, "data/working/x_test_gam.rds")

# prepared data for AUTOENCODER
saveRDS(x_train_auto, "data/working/x_train_auto.rds")
saveRDS(x_test_auto, "data/working/x_test_auto.rds")

# prepared data for KSD
saveRDS(x_train_ksd, "data/working/x_train_ksd.rds")
saveRDS(x_test_ksd, "data/working/x_test_ksd.rds")
