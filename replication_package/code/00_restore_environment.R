find_root <- function(start = getwd()) {
  p <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(p, "renv.lock"))) return(p)
    parent <- dirname(p)
    if (identical(parent, p)) stop("renv.lock introuvable.", call. = FALSE)
    p <- parent
  }
}
root <- find_root(); setwd(root)
if (!requireNamespace("renv", quietly = TRUE)) {
  stop("Installer d'abord renv 1.2.3 depuis CRAN, puis relancer ce script.", call. = FALSE)
}
lib <- renv::paths$library(project = root)
message("Restauration dans : ", lib)
renv::restore(project = root, library = lib, prompt = FALSE)
message("Environnement restauré. Lancer ensuite code/00_preflight.R.")