source("libraries.R")
source("functions.R")

# parameters --------------------------------------------------------------


# read data ---------------------------------------------------------------

# dataframes with outlyingess of each obs in full data
out_ksd = readRDS("data/working/outliers_full_ksd.rds")
out_auto = readRDS("data/working/outliers_full_auto.rds")
out = inner_join(out_ksd, out_auto, by="id_tot", suffix=c("_ksd","_auto")) %>% 
  # apply minmax
  mutate_at(vars(starts_with("out")), list(m=minmax))

# plots --------------------------------------------------------------------

# 1. COMPARED DENSITY (original scale)
gdat_1 = out %>% 
  gather("stat") %>% 
  dplyr::filter(stat %in% c("out_ksd","out_auto"))
(
  g_dens_o = ggplot(gdat_1, aes(x=value, fill=stat)) +
  facet_wrap(vars(stat), nrow=2, scales="free") +
  geom_density() + 
  NULL
)
# 2. COMPARED DENSITY (log scale)
(
  g_dens_l = ggplot(gdat_1, aes(x=log(value), fill=stat)) +
    facet_wrap(vars(stat), nrow=2, scales="free") +
    geom_density() + 
    NULL
)
# 3. SCATTER (log original scale)
(
  g_scat_o = ggplot(out, aes(x=log(out_ksd), y=log(out_auto))) +
    geom_point(size=0.75, alpha=0.5) +
    NULL
)
# 4. SCATTER (log minmax scale)
(
  g_scat_m = ggplot(out, aes(x=log(out_ksd_m), y=log(out_auto_m))) +
    geom_point(size=0.75, alpha=0.5) +
    NULL
)

# save plots
ggsave("output/plots/outliers_dens_orig.png", g_dens_o, width=5, height=5)
ggsave("output/plots/outliers_dens_log.png", g_dens_l, width=5, height=5)
ggsave("output/plots/outliers_scatter_logorig.png", g_scat_o, width=5, height=5)
ggsave("output/plots/outliers_scatter_logminmax.png", g_scat_m, width=5, height=5)


# OLD ---------------------------------------------------------------------

# #original scale
# ggplot(out, aes(x=out_ksd, y=out_auto)) +
#   geom_point(size=0.75)
# #minmax
# ggplot(out, aes(x=out_ksd_m, y=out_auto_m)) +
#   geom_point(size=0.75)

# POR QUE NO DA LO MISMO?
# cor(out$out_ksd, out$out_auto, method="spearman")
# cor(log(out$out_ksd), log(out$out_auto), method="pearson")

