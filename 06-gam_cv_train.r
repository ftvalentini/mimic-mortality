source("libraries.R")
source("functions.R")

library(gamsel)

# NOTA:
  # NO USAR Y_SEPSIS COMO TARGET
  # PORQUE DEPENDE DE DIAGNOSES Y PROCEDURES (Y NO ESTAN INDEXADOS EN EL TIEMPO) 
  # ENTONCES NO SE PUEDE GARANTIZAR QUE EL EVENTO/DIAGNOS DE SEPSIS SEA POSTERIOR
    # A LAS PRIMERAS 24 HS
# NOTA:
  # usar variables binarias genero problemas porque salta error de pocos valores unicos
# NOTA:
  # si se usa lamda_seq (lambdas chicos) no hay variables con zero coef
  # pero la usamos xq hacemos CV para GAM to predict (not explain)
# NOTA:
  # LOS VALORES DE PERFORMANCE DE CV ESTAN SUBESTIMADOS
  # PORQUE EL PREPROCESAMIENTO (MEDIAN POLISH MAS QUE NADA) NO SE HACE EN CADA FOLD
  # SE HACE AL PRINCIPIO Y ENTONCES USA INFORMACION DE VALIDACION
  # SIN EMBARGO SIRVE PARA ENCONTRAR EL LAMBDA
# VER SI SOBRESAMPLEAR


# parameters --------------------------------------------------------------

semilla = 1993
cv_folds = 10
n_lambda = 50

# read prepared train ------------------------------------------------

x_train = readRDS("data/working/x_train_gam.rds")
y_train = readRDS("data/working/y_train.rds")

# cross-validate GAM lambda -----------------------------------------------

# seq de lambdas hallada probando:
lambda_seq = exp(seq(0,-2,length.out=n_lambda))
set.seed(semilla)
cv_mod = cv.gamsel(as.matrix(x_train), y_train, family="binomial", type.measure="class"
                   ,nfolds=cv_folds, lambda=lambda_seq)

# largest value of lambda such that error is within 1 standard error of the minimum
(lambda_opt = cv_mod$lambda.1se)

# save --------------------------------------------------------------------

saveRDS(cv_mod, "data/working/gam_cv.rds")

# plots -------------------------------------------------------------------

# plot
png("output/plots/gam_cv.png", width=450, height=300)
par(mfrow=c(1,1))
plot(cv_mod)
dev.off()



