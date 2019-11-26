source("libraries.R")

# operador para concatenar texto:
"%+%" <- function(a,b) paste(a,b,sep="")

# minmax (can input given min and max)
minmax = function(x, min=NULL, max=NULL) {
  if (is.null(min) & is.null(max)) {
    out = (x - min(x)) / (max(x) - min(x))
  } else { 
    out = (x - min) / (max(x) - min)
  }
  return(out) 
}


# impute NA with median polish
imp_medpol = function(df_num, seed=100) {
  
  # df_num: numeric dataframe
  
  # get medians and mads
  meds = apply(df_num, 2, function(x) median(x, na.rm=T))
  mads = apply(df_num, 2, function(x) mad(x, na.rm=T))
  # if any MAD equals 0, add small random deviations to calculate it
  if (any(mads %in% 0)) {
    cat(paste0(names(mads)[mads %in% 0], collapse=" ") %+% " have MAD=0
      => adding small random deviations to get MAD\n\n")
    set.seed(seed)
    mads[mads %in% 0] = apply(df_num[mads %in% 0], 2,
                              function(x) 
                                mad(x + runif(length(x),
                                              -median(x, na.rm=T)/1e6,
                                              median(x, na.rm=T)/1e6),
                                    na.rm=T))
  }
  # scale data with median and mad
  df_sc = scale(df_num, center=meds, scale=mads)
  
  # median polish
  medpol = medpolish(df_sc, na.rm=T,  maxiter=100, trace.iter=F)
  # fixed, row and column effects
  e_fix = medpol$overall
  e_row = medpol$row 
  e_col = medpol$col
  
  # fitted scaled values
  df_fit_sc = outer(e_row, e_col, FUN="+") + e_fix
  # fitted original-scale values
  df_fit = df_fit_sc %*% diag(mads) + rep(1,nrow(df_sc))%*%t(meds)
  
  # impute NA with fitted values
  out = df_num %>% replace(is.na(.), df_fit[is.na(.)])

  return(out)
  
}

# print console output in pdf bookdown
print_output <- function(output, cex = 0.7) {
  tmp <- capture.output(output)
  # dev.off()
  par(mar=c(0,0,0,0))
  plot.new()
  text(0, 1, paste(tmp, collapse='\n'), adj = c(0,1), family = 'mono', cex = cex)
  box()
}
