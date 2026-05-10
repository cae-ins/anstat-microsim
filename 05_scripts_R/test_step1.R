setwd("C:/Users/f.migone/Desktop/projects/actif/anstat-microsim")
source("05_scripts_R/00_setup.R")
paths <- list(ROOT=ROOT, DATA=DATA, CODE=CODE,
              SILVER=SILVER, GOLD=GOLD, LOGS=LOGS,
              TABLES=TABLES, FIGS=FIGS)

source("05_scripts_R/02_mapping_tax.R")

tryCatch(
  map_tax(paths),
  error = function(e) {
    message("ERROR in map_tax: ", e$message)
    message(traceback())
  }
)
