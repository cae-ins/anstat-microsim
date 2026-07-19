find_root <- function(start = getwd()) {
  p <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(p, "05_scripts_R", "00_master.R"))) return(p)
    parent <- dirname(p)
    if (identical(parent, p)) stop("Racine du dépôt introuvable.", call. = FALSE)
    p <- parent
  }
}

root <- find_root(); setwd(root)
source("replication_package/code/00_preflight.R")
replication_library <- activate_replication_library(root)
if (is.na(replication_library)) {
  stop("Bibliothèque renv absente. Exécuter 00_restore_environment.R.", call. = FALSE)
}
source("replication_package/code/01_verify_outputs.R")
tryCatch({
  preflight_main(TRUE)
  Sys.setenv(CEQ_REPLICATION_STRICT = "1")
  log_dir <- file.path(root, "replication_package", "output", "logs")
  dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
  stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  log_file <- file.path(log_dir, paste0("full_run_", stamp, ".log"))
  con <- file(log_file, open = "wt", encoding = "UTF-8")
  sink(con, split = TRUE); sink(con, type = "message")
  on.exit({try(sink(type = "message"), silent = TRUE); try(sink(), silent = TRUE); try(close(con), silent = TRUE)}, add = TRUE)
  cat("Commit : ", tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), error = function(e) "indisponible"), "\n", sep = "")
  cat("R : ", R.version.string, "\n", sep = "")
  cat("RNG : ", paste(RNGkind(), collapse = "; "), "\n", sep = "")
  t <- system.time({source("05_scripts_R/00_master.R"); lance_pipeline(1, 26)})
  verify_main(TRUE)
  runtime <- sprintf("elapsed_seconds=%.3f\nuser_seconds=%.3f\nsystem_seconds=%.3f\nfinished=%s\n",
                     unname(t[["elapsed"]]), unname(t[["user.self"]]), unname(t[["sys.self"]]),
                     format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
  writeLines(runtime, "replication_package/output/runtime.txt", useBytes = TRUE)
  message("Réplication terminée et contrôles conformes. Journal : ", log_file)
}, error = function(e) {
  message("ÉCHEC DE LA RÉPLICATION : ", conditionMessage(e))
  quit(status = 1L)
})