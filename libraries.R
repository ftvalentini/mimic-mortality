
# escribir paquetes "desiempre" y "proj" ---------------------------------------
# las desiempre no se llaman explicitamente en los Scripts, las proj sí
paq_desiempre <- c("magrittr",
                   "purrr",
                   "conflicted",
                   "ggplot2",
                   "dplyr",
                   "broom",
                   "knitr",
                   "readr",
                   "stringr",
                   "tidyr",
                   "lubridate",
                   "bookdown",
                   "kableExtra",
                   "DBI"
                   )
paq_proj <- c(
              "dbplyr"
              ,"forcats"
              ,"gamsel"
              ,"rsample"
              ,"yardstick"
              ,"GGally"
              )

# no tocar ----------------------------------------------------------------
paq <- c(paq_desiempre,paq_proj)
for (i in seq_along(paq)) {
  if (!(paq[i] %in% installed.packages()[,1])) {
    install.packages(paq[i])
  }
  if (paq[i] %in% paq_desiempre) library(paq[i],character.only=T, warn.conflicts=F,quietly=T,verbose=F)
}
rm(paq,paq_desiempre,paq_proj)