source("libraries.R")
source("functions.R")

# devtools::install_github("rstudio/keras")
library(keras)
# install_keras()

# NOTA:
  # aca se pueden incorporar categoricas/binarias con one-hot
  # hacerlo solo si se logra hacer en KSD y GAM (por ahora no se pudo)
# se entrena:
  # para todo el dataset (para comparar con auto)
  # para train con CV (para meter en stacking) 

# parameters --------------------------------------------------------------

semilla = 2000

# read data --------------------------------------------------------------

# not prepared data
base_train = readRDS("data/working/x_train_raw.rds")
base_test = readRDS("data/working/x_test_raw.rds")
base_full = bind_rows(base_train, base_test)
# prepared data
x_train = readRDS("data/working/x_train_auto.rds") 
x_test = readRDS("data/working/x_test_auto.rds") 
x_full = rbind(x_train, x_test)

# keras model -------------------------------------------------------------

# ncol(x_train): 69

mod = keras_model_sequential()
mod %>%
  layer_dense(units=2**5, activation="relu", input_shape=ncol(x_train), name="latent1") %>%
  layer_dense(units=2**3, activation="relu", name="latent2") %>%
  layer_dense(units=2, activation="relu", name="latent3") %>%
  layer_dense(units=2**3, activation="relu", name="latent4") %>%
  layer_dense(units=2**5, activation="relu", name="latent5") %>%
  layer_dense(ncol(x_train), activation="linear", name="output")

# param de cada layer:
# summary(mod)
# 2**5 * (66 + 1)
# 2**3  * (2**5 + 1)
# 2   * (2**3 + 1)
# 2**3  * (2 + 1)
# 2**5 * (2**3 + 1)
# 66  * (2**5 + 1)

# compile
mod %>% compile(
  loss = "mse", 
  metrics = "mse",
  optimizer = "adam"
)

# train on full data ------------------------------------------------------

set.seed(semilla)
fit_history = mod %>% fit(
  x = x_full, 
  y = x_full, 
  epochs = 20, 
  batch_size = 10
)
saveRDS(fit_history, "data/working/auto_fithistory_full.rds")

# get and save training reconstruction errors (outlyingness)
errors = (x_full - predict(mod, x_full))**2 %>% apply(1, mean)
out_auto = tibble(
  id_tot = base_full$id_tot
  ,out = errors
)
saveRDS(out_auto, "data/working/outliers_full_auto.rds")

# chequeo: model "performance"
# (deben dar igual)
evaluate(mod, x_full, x_full); mean(errors)

# extract and plot the latent space
latent_layer = keras_model(
  inputs = mod$input,
  outputs = get_layer(mod,"latent")$output
)
latent_space = predict(latent_layer, x_full) %>% 
  as_tibble() %>% 
  setNames(c("x1","x2")) %>% 
  mutate(outlyingness = out_auto$out)
(
  g_latent = ggplot(latent_space, aes(x1, x2, color=outlyingness)) +
    geom_point(alpha=0.9, size=0.8) + 
    scale_color_viridis_c() +
    NULL
)

# save plot
# no queda claro lo que se ve...

# train for prediction ------------------------------------------------------

mod2 = clone_model(mod) %>% 
  compile(
    loss = "mse", 
    metrics = "mse",
    optimizer = "adam"
  )

set.seed(semilla)
fit_history = mod2 %>% fit(
  x = x_train, 
  y = x_train, 
  epochs = 20, 
  batch_size = 100,
  validation_data = list(x_test, x_test)
)
saveRDS(fit_history, "data/working/auto_fithistory_train.rds")

# get and save training reconstruction errors (outlyingness)
errors = (x_train - predict(mod2, x_train))**2 %>% apply(1, mean)
out_auto = tibble(
  id_tot = base_train$id_tot
  ,out = errors
)
saveRDS(out_auto, "data/working/outliers_train_auto.rds")

# chequeo: model "performance"
# (deben dar igual)
evaluate(mod2, x_train, x_train); mean(errors)

# ojo que en test el error es distinto...
# esto quiere decir que no representa las caracteristicas de datos no vistos?
evaluate(mod2, x_test, x_test); mean(errors)

# save model
mod2 %>% save_model_hdf5("data/working/model_autoencoder.h5")


# OLD ---------------------------------------------------------------------

# # train y test with minmax and as matrix
# set.seed(800)
# i_train = sample(nrow(base_num), nrow(base_num)*0.8)
# # mins and maxs of training
# minsmaxs_train = base_num[i_train,] %>% 
#   map(function(x) list(min=min(x), max=max(x)))
# # normalize training with its own mins and maxs
# x_train <- base_num[i_train,] %>% 
#   map_df(minmax) %>% 
#   as.matrix()
# # normalize test with trainings' min and maxs
# x_test <- map2_df(.x=base_num[-i_train,], .y=minsmaxs_train,
#                   function(x,y) minmax(x, min=y$min, max=y$max)) %>% 
#   as.matrix()

# train model
# checkpoint <- callback_model_checkpoint(
#   filepath = "output/model1.hdf5", 
#   save_best_only = TRUE, 
#   period = 1,
#   verbose = 1
# )
# early_stopping <- callback_early_stopping(patience = 5)
# 
# fit_history = model1 %>% fit(
#   x = x_train, 
#   y = x_train, 
#   epochs = 100, 
#   batch_size = 500,
#   validation_data = list(x_test, x_test), 
#   # callbacks = list(checkpoint, early_stopping)
# )

# aa = latent_space %>% mutate(r_error = errors)
# ggplot(aa, aes(x=x1, y=x2, color=r_error)) +
#   geom_point(
#     # alpha=0.5, size=0.75
#   )
# ggplot(aa) +
#   geom_boxplot(aes(y=r_error))