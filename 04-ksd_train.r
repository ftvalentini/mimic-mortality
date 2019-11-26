source("libraries.R")
source("functions.R")

# outlier detection function
source("resources/external/maronna/KurtSDNew.R")

# NOTAS:
  # AVERIGUAR SI SE PUEDEN INCLUIR VARIABLES BINARIAS/CATEGORICAS (COMO DUMMIES)
  # si se puede, incluir:
    # binarias: endotrachflag, rrt, vent
    # categoricas: admission_type, gender, ethnicity
    # categoricas ordinales: gcseyes, gcsmotor, gcsverbal
  # NO ES UN ALGORITMO A ENTRENAR:
    # solo se aplica en training para que sea comparable con autoencoder
    # se calcula entonces:
        # para todo el dataset (para comparar con auto)
        # para todo el train (para meter en stacking)

# parameters --------------------------------------------------------------

# read data --------------------------------------------------------------

# raw data
base_train = readRDS("data/working/x_train_raw.rds")
base_test = readRDS("data/working/x_test_raw.rds")
# prepared data
x_train = readRDS("data/working/x_train_ksd.rds")
x_test = readRDS("data/working/x_test_ksd.rds")

# full data -------------------------------------------------------

x_full = bind_rows(x_train,x_test)
# nota: estandarizacion is done in the function
outk_full = KurtSDNew(X=x_full)
# get and save outlyingness of each obs
out_ksd_full = tibble(
  id_tot = c(base_train$id_tot,base_test$id_tot)
  ,out = outk_full$tl[[1]]
)
saveRDS(out_ksd_full, "data/working/outliers_full_ksd.rds")

# training data -------------------------------------------------------

# nota: estandarizacion is done in the function
outk_train = KurtSDNew(X=x_train)
# get and save outlyingness of each obs
out_ksd_train = tibble(
  id_tot = c(base_train$id_tot)
  ,out = outk_train$tl[[1]]
)
saveRDS(out_ksd_train, "data/working/outliers_train_ksd.rds")
