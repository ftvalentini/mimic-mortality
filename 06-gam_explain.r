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
  # si se usa lamda_seq (lambdas chicos) no hay variables con zero coef!
  # porque el lambda es chico
  # entonces se usan los lambda default para generar los plots que explican
  # y se visualizan rdos con lambda tal que quedan las 30 variables mas importantes
  
# parameters --------------------------------------------------------------

semilla = 1993
# nzero coefs para visualizar
nz = 30

# read prepared train/test ------------------------------------------------

x_train = readRDS("data/working/x_train_gam.rds")
y_train = readRDS("data/working/y_train.rds")

# logistic GAM to explain -------------------------------------------------

# fit en todo training at once (para 100 valores de lambda por default)
set.seed(semilla)
mod = gamsel(x_train, y_train, family="binomial", num_lambda=100)

# extrae info de nonzero coefs
mod_print = capture.output(mod)
h = mod_print[4] %>% str_split(pattern=" ",simplify=T) %>% "["(. != "")
d = mod_print[5:length(mod_print)] %>% str_sub(start=7) %>% str_split(pattern=" ") %>% 
  map(function(x) x[x!=""]) %>% Reduce(f=rbind,.)
mod_print = data.frame(d,stringsAsFactors=F) %>% setNames(h) %>% 
  set_rownames(NULL) %>% mutate_all(as.numeric)

# busca lambda tal que quedan NZ nonzero coefs
lambda_show = mod_print %>% 
  dplyr::filter(abs(NonZero-nz) == min(abs(NonZero-nz))) %>%
  pull(Lambda) %>% head(1)
i_lambda = which(mod_print$Lambda==lambda_show)
nz_final = mod_print[i_lambda, "NonZero"]

# plots -------------------------------------------------------------------

# regularization plot
png("output/plots/gam_regularization.png", width=585, height=390)
par(mfrow=c(1,2),mar=c(5,4,3,1))
summary(mod, label=T)
abline(v=lambda_show)
dev.off()

# fitted effects plot
png("output/plots/gam_vars.png", width=800, height=1400)
par(mfrow=c(8,4))
plot(mod, newx=as.matrix(x_train), index=i_lambda, which="nonzero")
dev.off()

# reference table of vars for plots
tab_vars = tibble(variable="v"%+%1:ncol(x_train), name=names(x_train))
saveRDS(tab_vars, "output/tables/vars_reference.rds")

# table: nonzero vars by lambda
saveRDS(mod_print, "output/tables/gam_nonzero_lambda.rds")
