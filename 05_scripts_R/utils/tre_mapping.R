# Shared mappings between EHCVM consumption items and national I/O products.

extract_wb_item_mapping <- function(root, variable = c("io", "cusio")) {
  variable <- match.arg(variable)
  wb_dofile <- file.path(
    root, "00_documentation", "ressources_CEQ",
    "01. CIV21WBN_presimulation_setup.do"
  )
  if (!file.exists(wb_dofile)) {
    stop("Do-file CEQ de concordance introuvable: ", wb_dofile, call. = FALSE)
  }
  wb_lines <- readLines(wb_dofile, warn = FALSE, encoding = "UTF-8")
  mapping_pattern <- paste0(
    "replace\\s+", variable, "\\s*=\\s*([0-9]+)\\s+if\\s+",
    "itemid\\s*==\\s*([0-9]+)"
  )
  mapping_matches <- regmatches(
    wb_lines,
    regexec(mapping_pattern, wb_lines, perl = TRUE)
  )
  mapping_matches <- mapping_matches[lengths(mapping_matches) == 3]
  sector_name <- paste0(variable, "_wb")
  out <- tibble::tibble(
    sector = as.integer(vapply(mapping_matches, `[[`, character(1), 2)),
    codpr = as.integer(vapply(mapping_matches, `[[`, character(1), 3))
  )
  names(out)[1] <- sector_name
  dplyr::distinct(out, codpr, .keep_all = TRUE)
}

wb52_to_tre48_bridge <- function() {
  tre_code_by_wb <- c(
    "A01", "A01", "A02", "A03", "A04", "A05", "A06", "B07",
    "C08", "C09", "C10", "C11", "C12", "C13", "C13", "C14",
    "C15", "C16", "C17", "C18", "C19", "C19", "C20", "C21",
    "C21", "C22", "C23", "C24", "C25", "C26", "C27", "C28",
    "C29", "C30", "D31", "E32", "F33", "G34", "H35", "I36",
    "J37", "K38", "L39", "M40", "N41", "O42", "P43", "Q44",
    "R45", "S46", "T47", "U48"
  )
  tibble::tibble(
    io_wb = seq_along(tre_code_by_wb),
    code_TRE = tre_code_by_wb
  )
}

build_tre_item_mapping <- function(root) {
  extract_wb_item_mapping(root, "io") |>
    dplyr::left_join(wb52_to_tre48_bridge(), by = "io_wb")
}

extract_wb_customs_rates <- function(root) {
  duty_dofile <- file.path(
    root, "00_documentation", "ressources_CEQ",
    "07. CIV21WBN_cus_in.do"
  )
  if (!file.exists(duty_dofile)) {
    stop("Do-file CEQ des droits de douane introuvable: ", duty_dofile,
         call. = FALSE)
  }
  lines <- readLines(duty_dofile, warn = FALSE, encoding = "UTF-8")
  rate_pattern <- paste0(
    "^\\s*global\\s+CUSIO([0-9]+)\\s*=\\s*([0-9.]+)",
    "(?:\\s*//\\s*(.*))?$"
  )
  matches <- regmatches(lines, regexec(rate_pattern, lines, perl = TRUE))
  matches <- matches[lengths(matches) >= 3]
  descriptions <- vapply(matches, function(x) {
    if (length(x) >= 4) x[[4]] else ""
  }, character(1))
  tibble::tibble(
    cusio_wb = as.integer(vapply(matches, `[[`, character(1), 2)),
    taux_wb_avec_rs = as.numeric(vapply(matches, `[[`, character(1), 3)),
    description_wb = descriptions
  ) |>
    dplyr::mutate(
      redevance_statistique = dplyr::if_else(taux_wb_avec_rs > 0, 0.01, 0),
      bande_tec = pmax(taux_wb_avec_rs - redevance_statistique, 0)
    )
}

build_customs_item_mapping <- function(root) {
  extract_wb_item_mapping(root, "cusio") |>
    dplyr::left_join(extract_wb_customs_rates(root), by = "cusio_wb")
}
