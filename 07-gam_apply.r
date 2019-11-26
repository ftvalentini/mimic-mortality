source("libraries.R")
source("functions.R")

library(gamsel)
library(yardstick)

# parameters --------------------------------------------------------------

semilla = 1993

# read model and test data ------------------------------------------------

x_test = readRDS("data/working/x_test_gam.rds")
y_test = readRDS("data/working/y_test.rds")
scores_test = readRDS("data/working/scores_test.rds")
cv_mod = readRDS("data/working/gam_cv.rds")
mod = cv_mod$gamsel.fit
# optimal lambda
  # largest value of lambda such that error is within 1 standard error of the minimum
lambda_opt = cv_mod$lambda.1se
# index of optimal lambda model
i_mod = which(mod$lambdas==lambda_opt)

# predict on test data ----------------------------------------------------

# fitted probs
pred = predict(mod, newdata=x_test, index=i_mod, type="response") %>% as.vector()
# table with truth and probs
dat_p = tibble(
  y = as.factor(y_test)
  ,gam_pred = pred
  ,sofa = minmax(scores_test$score_sofa)
  ,sapsii = scores_test$score_sapsiiprob
  ,oasis = scores_test$score_oasisprob
)

# plots -------------------------------------------------------------------

# ROC curve
roc_dat = list(
  GAM = roc_curve(dat_p, y, gam_pred)
  ,SOFA = roc_curve(dat_p, y, sofa)
  ,SAPSII = roc_curve(dat_p, y, sapsii)
  ,OASIS = roc_curve(dat_p, y, oasis)
) %>% bind_rows(.id="score")
(
  g_roc = ggplot(roc_dat, aes(x=1-specificity, y=sensitivity, color=score)) +
    geom_path(cex = 1) +
    geom_abline(lty = 3) +
    coord_equal() +
    theme_bw() + 
    NULL
)
ggsave("output/plots/gam_roc.png", g_roc, width=6, height=4.5)

# Violin plot
gdat_violin = dat_p %>%
  rename(GAM=gam_pred, SOFA=sofa, SAPSII=sapsii, OASIS=oasis) %>% 
  pivot_longer(names_to="score", values_to="value", -y)
(
  g_violin = ggplot(gdat_violin, aes(x=y, y=value, group=y, fill=y)) +
    facet_wrap(~score) +
    geom_violin() +
    theme_bw() +
    guides(fill=FALSE) +
    labs(x='Mort_7', y="Prob. ajustada") +
    NULL
)
ggsave("output/plots/gam_violin.png", g_violin, width=10, height=6)

# tables ------------------------------------------------------------------

# AUROC
tab_auroc = dat_p %>%
  gather(score, value, -y) %>% 
  split(.$score) %>% 
  map_dfc(function(d) roc_auc(d, truth=y, value)$.estimate)
saveRDS(tab_auroc, "output/tables/gam_auroc.rds")






# OLD 
# # EXPLORATORIO PRE-MODELO
# ggpairs(default,mapping = aes(colour= default)) + 
#   theme_minimal()
# theme(axis.text.x = element_text(angle = 90, hjust = 1)) 