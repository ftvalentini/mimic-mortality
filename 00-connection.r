# intro -------------------------------------------------------------------

source("libraries.R")
source("functions.R")


# connection --------------------------------------------------------------


mimic = dbConnect(
  RPostgreSQL::PostgreSQL(),
  dbname = "mimic",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "Boquita93"
)
# default sql path
dbSendQuery(mimic, 'set search_path to mimiciii')

