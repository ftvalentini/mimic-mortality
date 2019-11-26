source("libraries.R")
source("functions.R")

library(gamsel)
library(keras)
source("resources/external/maronna/KurtSDNew.R")


# notas -------------------------------------------------------------------

# VER SI SOBRESAMPLEAR

# parameters --------------------------------------------------------------

semilla = 1993

# load data ----------------------------------------------------

# raw data
x_train_raw = readRDS("data/working/x_train_raw.rds")
x_test_raw = readRDS("data/working/x_test_raw.rds")

# training data for each method
x_train_gam = readRDS("data/working/x_train_gam.rds")
x_train_auto = readRDS("data/working/x_train_auto.rds")

# test data for each method
x_test_gam = readRDS("data/working/x_test_gam.rds")
x_test_auto = readRDS("data/working/x_test_auto.rds")

# target
y_train = readRDS("data/working/y_train.rds")
y_test = readRDS("data/working/y_test.rds")

# scores
scores_train = readRDS("data/working/scores_train.rds")
scores_test = readRDS("data/working/scores_test.rds")

# GAM --------------------------------------------------------------------

# load trained model (GAM with optimal lambda in CV)
cv_mod = readRDS("data/working/gam_cv.rds")
gam_mod = cv_mod$gamsel.fit
i_mod = which(gam_mod$lambdas==cv_mod$lambda.1se)

# get training predictions
pred_train_gam = predict(gam_mod, newdata=as.matrix(x_train_gam), index=i_mod
                         , type="response") %>% as.vector()
# get test predictions
pred_test_gam = predict(gam_mod, newdata=as.matrix(x_test_gam), index=i_mod
                        , type="response") %>% as.vector()

# AUTOENCODER ------------------------------------------------------------

# en un contexto de produccion se aplicaria un modelo ya entrenado a cada batch/caso nuevo

# load model (trained only with training)
auto_mod = load_model_hdf5("data/working/model_autoencoder.h5",compile = FALSE)

# get training outlyingness
outl_train_auto = (x_train_auto - predict(auto_mod, x_train_auto))**2 %>% apply(1, mean)

# get test outlyingness
outl_test_auto = (x_test_auto - predict(auto_mod, x_test_auto))**2 %>% apply(1, mean)

# train stacked logistic -------------------------------------------

# COMO EVALUAR SI LOS TRES INDICES MEJORAN PREDICCION:
  # si el coeficiente es significativo.
  # pero ojo que el test esta sesgado (ver hofling y tibshirani 2007)

# segun hofling y tibshirani hay que entrenar logistic con test data!!!
# (en realidad en varios folds de CV, pero no lo vamos a hacer asi)

# features and logs
dat_test = data.frame(
   pred_gam =   pred_test_gam
  ,outl_auto = outl_test_auto
  ,sofa =      scores_test$score_sofa
  ,sapsii =    scores_test$score_sapsiiprob
  ,oasis =    scores_test$score_oasisprob
  ,mort_7 = y_test
) %>% 
  mutate_all(list("log"=function(x) ifelse(x==0,0,log(x)))) %>% 
  select(-mort_7_log)

# formula for model
log_form = mort_7 ~
  pred_gam +
  outl_auto_log +
  sofa +
  sapsii +
  oasis

# make and save corplot
g_cor_stacked = GGally::ggcorr(dat_test %>% select(labels(terms(log_form)))
                               ,label=T, hjust=1, label_size=4, layout.exp=1
                               ,label_round=2)
ggsave("output/plots/stacked_corplot.png", g_cor_stacked, width=5, height=3)

# train and save binomial glm
log_mod = glm(formula=log_form, family="binomial", data=dat_test)
# save model
saveRDS(log_mod, "output/model_stacked_logistic_test.rds")

# bootstrap
fit_log = function(data) glm(formula=log_form, family="binomial", data=data)
boot = rsample::bootstraps(dat_test, times=500) %>% 
  mutate(log_mod = map(splits, fit_log)) %>% 
  mutate(log_res = map(log_mod, broom::tidy)) 
boot_res = boot %>% unnest(log_res) %>% 
  group_by(term) %>% 
  summarise(
    "Coef. (media)" = mean(estimate)
    ,"Des.Est. Coef." = sd(estimate)
    ,"p-valor (media)" = mean(p.value)
  )
# save bootrstap results
saveRDS(boot_res, "output/tables/boot_stacked_logistic_test.rds")




# plots -------------------------------------------------------------------

# DEFINIR SI ESTO TIENE SENTIDO

# table with observed and fitted
dat_p = dat_test %>% 
  select(labels(terms(log_form)),mort_7) %>% 
  mutate(
    stacked_logistic = predict(log_mod, newdata=dat_test, type="response")
    ,y = as.factor(mort_7)
  ) %>% 
  select(-mort_7)
# ROC curve
library(yardstick)
roc_dat = list(
  GAM = roc_curve(dat_p, y, pred_gam)
  ,SOFA = roc_curve(dat_p, y, sofa)
  ,SAPSII = roc_curve(dat_p, y, sapsii)
  ,OASIS = roc_curve(dat_p, y, oasis)
  ,Autoencoder = roc_curve(dat_p, y, outl_auto_log)
  ,Stacked_Logistic = roc_curve(dat_p, y, stacked_logistic)
) %>% bind_rows(.id="score")
(
  g_roc = ggplot(roc_dat, aes(x=1-specificity, y=sensitivity, color=score)) +
    geom_path(cex = 1) +
    geom_abline(lty = 3) +
    coord_equal() +
    theme_bw() + 
    NULL
)
ggsave("output/plots/roc_stacked.png", g_roc, width=6, height=6)


# tables ------------------------------------------------------------------

# VER SI ESTO TIENE SENTIDO

# AUROC
tab_auroc = dat_p %>%
  pivot_longer(names_to="score", values_to="value", -y) %>% 
  split(.$score) %>% 
  map_dfc(function(d) roc_auc(d, truth=y, value)$.estimate)
saveRDS(tab_auroc, "output/tables/auroc_stacked.rds")


# OLD ---------------------------------------------------------------------

# KSD (se saca porque es dificil de aplicar en casos nuevos)

# x_train_ksd = readRDS("data/working/x_train_ksd.rds")
# x_test_ksd = readRDS("data/working/x_test_ksd.rds")
# # KSD ------------------------------------------------------------
# 
# # se ejecuta para todos los datos (asi funcionaria en un contexto de produccion)
# x_ksd = bind_rows(
#   bind_cols(id_tot = x_train_raw$id_tot, x_train_ksd)
#   ,bind_cols(id_tot = x_test_raw$id_tot, x_test_ksd)
# )
# # apply KSD
# ksd_mod = KurtSDNew(X = x_ksd %>% select(-id_tot))
# out_ksd = tibble(id_tot = x_ksd$id_tot, out = ksd_mod$tl[[1]])
# 
# # get training outlyingness
# outl_train_ksd = out_ksd %>% dplyr::filter(id_tot %in% x_train_raw$id_tot) %>% pull(out)
# # get test outlyingness
# outl_test_ksd = out_ksd %>% dplyr::filter(id_tot %in% x_test_raw$id_tot) %>% pull(out)
