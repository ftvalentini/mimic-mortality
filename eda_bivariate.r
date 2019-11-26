
source("libraries.R")
source("functions.R")


# parameters --------------------------------------------------------------

# dcor threshold to analyse bivariate relationship
k_dcor_imp = 0.1


# read clean base --------------------------------------------------------------

base = readRDS("data/working/base_clean_01.rds")
# sin outliers brutos:
# base = readRDS("data/working/base_clean_02.rds")

# numeric (without id)
base_num = base %>%
  select_if(is.numeric) %>% 
  select(-starts_with("id_"))


# bivariate (distance correlation) ---------------------------------------------

# dcors between every pair of vars (only lower triangle of matrix)
dcors = matrix(NA, nrow=ncol(base_num), ncol=ncol(base_num)) %>% 
  `dimnames<-`(list(names(base_num), names(base_num)) )
dcors[] = lower.tri(dcors)
for (i in rownames(dcors)) {
  for (j in colnames(dcors)) {
    if (dcors[i,j]) dcors[i,j] = energy::dcor2d(base_num[[i]],base_num[[j]])
  }
}
# row cols of important dcor (>0.2)
r_imp = which(dcors>k_dcor_imp, arr.ind=T)[,1]
c_imp = which(dcors>k_dcor_imp, arr.ind=T)[,2]


# plot --------------------------------------------------------------------

dcor_tab = tibble(
  var1 = rownames(dcors)[r_imp],
  var2 = colnames(dcors)[c_imp]
) %>% 
  # solo las variables que no son resumen del mismo item
  dplyr::filter(substr(var1,1,3)!=substr(var2,1,3)) %>% 
  # get cor y create scatterplot
  mutate(
    dcor = map2_dbl(var1, var2, function(a,b) dcors[a,b]),
    scaplot = map2(var1, var2,
                   function(a,b) qplot(base_num[[a]], base_num[[b]], xlab=a, ylab=b,
                                       size=I(0.2), geom="jitter", alpha=I(0.2)))
  ) %>% 
  # ordena por dcor
  arrange(-dcor)

# save plots
ggsave("output/scatter_exploratory.pdf",
       gridExtra::marrangeGrob(grobs=dcor_tab$scaplot, nrow=2, ncol=1))
# save tab
saveRDS(dcor_tab, "data/working/tab_dcor.rds")
