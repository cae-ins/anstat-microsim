find_root <- function(start = getwd()) {
  p <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(p, "05_scripts_R", "00_master.R"))) return(p)
    parent <- dirname(p)
    if (identical(parent, p)) stop("Racine du dépôt introuvable.", call. = FALSE)
    p <- parent
  }
}

activate_replication_library <- function(root) {
  base <- file.path(root, "renv", "library")
  if (!dir.exists(base)) return(NA_character_)
  dirs <- list.dirs(base, recursive = TRUE, full.names = TRUE)
  hit <- dirs[vapply(dirs, function(x) file.exists(file.path(x, "arrow", "DESCRIPTION")), logical(1))]
  if (length(hit) == 1L) {
    .libPaths(unique(c(hit, .libPaths())))
    return(normalizePath(hit, winslash = "/"))
  }
  NA_character_
}
preflight_main <- function(stop_on_fail = TRUE) {
  root <- find_root()
  replication_library <- activate_replication_library(root)
  old <- setwd(root); on.exit(setwd(old), add = TRUE)
  out_dir <- file.path(root, "replication_package", "output")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  add <- function(check, status, detail) {
    rows[[length(rows) + 1L]] <<- data.frame(
      check = check, status = status, detail = as.character(detail),
      stringsAsFactors = FALSE
    )
  }

  manifest_path <- file.path(root, "replication_package", "data", "data_manifest.csv")
  if (!file.exists(manifest_path)) {
    add("manifest", "FAIL", "data_manifest.csv absent")
  } else {
    add("manifest", "PASS", "manifeste lu")
    manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE,
                                check.names = FALSE, encoding = "UTF-8")
    for (i in seq_len(nrow(manifest))) {
      p <- file.path(root, manifest$path[[i]])
      label <- paste0("entrée: ", manifest$path[[i]])
      if (!file.exists(p)) {
        add(label, if (isTRUE(manifest$required[[i]])) "FAIL" else "WARN", "absente")
        next
      }
      size <- file.info(p)$size
      hash <- unname(tools::md5sum(p))
      ok_hash <- identical(tolower(hash), tolower(manifest$md5[[i]]))
      ok_size <- identical(as.numeric(size), as.numeric(manifest$bytes[[i]]))
      add(label, if (ok_hash && ok_size) "PASS" else "FAIL",
          sprintf("md5=%s; octets=%s", hash, size))
    }
  }

  add("bibliothèque renv restaurée", if (is.na(replication_library)) "WARN" else "PASS",
      if (is.na(replication_library)) "absente; exécuter 00_restore_environment.R" else replication_library)

  ref_version <- "4.5.3"
  add("version R", if (identical(as.character(getRversion()), ref_version)) "PASS" else "WARN",
      paste(R.version.string, "; référence", ref_version))
  required_packages <- c("haven", "arrow", "dplyr", "tidyr", "tibble", "purrr",
                         "ggplot2", "scales", "openxlsx", "readxl", "readr",
                         "survey", "sandwich", "lmtest", "jsonlite")
  for (pkg in required_packages) {
    ok <- requireNamespace(pkg, quietly = TRUE)
    version <- if (ok) as.character(utils::packageVersion(pkg)) else "absent"
    add(paste0("paquet R: ", pkg), if (ok) "PASS" else "FAIL", version)
  }

  r_files <- list.files(file.path(root, "05_scripts_R"), pattern = "\\.[Rr]$",
                        recursive = TRUE, full.names = TRUE)
  absolute_hits <- unlist(lapply(r_files, function(p) {
    x <- readLines(p, warn = FALSE, encoding = "UTF-8")
    hit <- grep("[A-Za-z]:[/\\\\](Users|home)[/\\\\]", x, value = TRUE)
    if (length(hit)) paste(basename(p), hit, sep = ": ") else character()
  }))
  add("chemins absolus dans 05_scripts_R", if (length(absolute_hits)) "FAIL" else "PASS",
      if (length(absolute_hits)) paste(absolute_hits, collapse = " | ") else "aucun")

  probe <- file.path(out_dir, ".write_test")
  writable <- tryCatch({writeLines("ok", probe); unlink(probe); TRUE}, error = function(e) FALSE)
  add("écriture des sorties", if (writable) "PASS" else "FAIL", out_dir)
  add("RNG", "PASS", paste(RNGkind(), collapse = "; "))

  report <- do.call(rbind, rows)
  utils::write.csv(report, file.path(out_dir, "preflight_report.csv"), row.names = FALSE,
                   fileEncoding = "UTF-8")
  print(report, row.names = FALSE)
  failures <- sum(report$status == "FAIL")
  message(sprintf("Pré-contrôle : %d PASS, %d WARN, %d FAIL.",
                  sum(report$status == "PASS"), sum(report$status == "WARN"), failures))
  if (stop_on_fail && failures > 0L) stop("Pré-contrôle non conforme.", call. = FALSE)
  invisible(report)
}

if (sys.nframe() == 0L) {
  tryCatch(preflight_main(TRUE), error = function(e) {message(conditionMessage(e)); quit(status = 1L)})
}