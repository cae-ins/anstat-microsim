# Outils communs pour la TVA incorporee dans les chaines de production.

check_io_matrix <- function(A, label = "A") {
  A <- as.matrix(A)
  if (nrow(A) != ncol(A)) {
    stop(label, " doit etre une matrice carree.", call. = FALSE)
  }
  if (any(!is.finite(A)) || any(A < -1e-12)) {
    stop(label, " contient des coefficients invalides.", call. = FALSE)
  }
  A[A < 0] <- 0
  A
}

convert_uses_to_basic_prices <- function(U_purchaser, basic_total,
                                         purchaser_total) {
  U_purchaser <- as.matrix(U_purchaser)
  if (nrow(U_purchaser) != length(basic_total) ||
      length(basic_total) != length(purchaser_total)) {
    stop("Dimensions incompatibles pour le passage aux prix de base.",
         call. = FALSE)
  }

  ratio <- ifelse(purchaser_total > 0, basic_total / purchaser_total, 0)
  ratio[!is.finite(ratio)] <- 0
  sweep(U_purchaser, 1, ratio, "*")
}

convert_sut_uses_to_basic_prices <- function(
    U_purchaser, valuation, trade_code = "G34", transport_code = "H35") {
  U_purchaser <- as.matrix(U_purchaser)
  required <- c(
    "code", "purchaser_total", "trade_margins", "transport_margins",
    "nondeductible_vat", "product_subsidies", "other_product_taxes",
    "export_taxes", "import_taxes"
  )
  missing <- setdiff(required, names(valuation))
  if (length(missing) > 0) {
    stop("Colonnes de valorisation manquantes: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  if (!identical(rownames(U_purchaser), valuation$code)) {
    stop("Ordre des produits incoherent dans la passerelle de valorisation.",
         call. = FALSE)
  }

  purchaser_total <- valuation$purchaser_total
  trade_margin <- pmax(valuation$trade_margins, 0)
  transport_margin <- pmax(valuation$transport_margins, 0)
  net_product_tax <-
    valuation$nondeductible_vat + valuation$product_subsidies +
    valuation$other_product_taxes + valuation$export_taxes +
    valuation$import_taxes

  share <- function(amount) {
    value <- ifelse(purchaser_total > 0, amount / purchaser_total, 0)
    value[!is.finite(value)] <- 0
    value
  }

  trade_share <- share(trade_margin)
  transport_share <- share(transport_margin)
  tax_share <- share(net_product_tax)
  commodity_factor <- 1 - trade_share - transport_share - tax_share
  commodity_factor <- pmax(commodity_factor, 0)

  U_basic <- sweep(U_purchaser, 1, commodity_factor, "*")
  trade_allocation <- colSums(sweep(U_purchaser, 1, trade_share, "*"))
  transport_allocation <- colSums(
    sweep(U_purchaser, 1, transport_share, "*")
  )

  trade_row <- match(trade_code, rownames(U_basic))
  transport_row <- match(transport_code, rownames(U_basic))
  if (is.na(trade_row) || is.na(transport_row)) {
    stop("Produits de marge absents de la matrice d'emplois.", call. = FALSE)
  }
  U_basic[trade_row, ] <- U_basic[trade_row, ] + trade_allocation
  U_basic[transport_row, ] <- U_basic[transport_row, ] + transport_allocation

  list(
    uses_basic = U_basic,
    commodity_factor = commodity_factor,
    trade_allocation = trade_allocation,
    transport_allocation = transport_allocation,
    removed_product_tax = colSums(sweep(U_purchaser, 1, tax_share, "*"))
  )
}

split_uses_by_origin <- function(U_basic, domestic_supply, imports) {
  U_basic <- as.matrix(U_basic)
  total_supply <- pmax(domestic_supply, 0) + pmax(imports, 0)
  domestic_share <- ifelse(total_supply > 0,
                           pmax(domestic_supply, 0) / total_supply, 0)
  domestic_share[!is.finite(domestic_share)] <- 0

  list(
    domestic = sweep(U_basic, 1, domestic_share, "*"),
    imported = sweep(U_basic, 1, 1 - domestic_share, "*"),
    domestic_share = domestic_share
  )
}

compute_embedded_vat <- function(A_dom, statutory_rate, taxable_share,
                                 A_import = NULL, tolerance = 1e-10) {
  A_dom <- check_io_matrix(A_dom, "A_dom")
  n <- nrow(A_dom)

  if (is.null(A_import)) {
    A_import <- matrix(0, n, n)
  }
  A_import <- check_io_matrix(A_import, "A_import")
  if (!identical(dim(A_dom), dim(A_import))) {
    stop("A_dom et A_import doivent avoir les memes dimensions.",
         call. = FALSE)
  }
  if (length(statutory_rate) != n || length(taxable_share) != n) {
    stop("Les vecteurs fiscaux doivent avoir une valeur par secteur.",
         call. = FALSE)
  }

  statutory_rate <- pmax(as.numeric(statutory_rate), 0)
  taxable_share <- pmin(pmax(as.numeric(taxable_share), 0), 1)
  spectral_radius <- max(Mod(eigen(A_dom, only.values = TRUE)$values))
  if (!is.finite(spectral_radius) || spectral_radius >= 1 - tolerance) {
    stop(sprintf(
      "Condition de Hawkins-Simon non satisfaite (rayon spectral %.6f).",
      spectral_radius
    ), call. = FALSE)
  }

  # La TVA facturee sur les intrants est deductible si la production est
  # taxable. Seule la fraction non deductible devient un cout dans le secteur
  # exonere; ce cout se propage ensuite dans toutes les productions en aval.
  input_vat <- drop(t(A_dom + A_import) %*% statutory_rate)
  first_round <- (1 - taxable_share) * input_vat
  embedded_rate <- drop(
    solve(diag(n) - t(A_dom), first_round)
  )
  embedded_rate[abs(embedded_rate) < tolerance] <- 0
  if (any(embedded_rate < -tolerance)) {
    stop("Le calcul produit un taux de TVA incorporee negatif.", call. = FALSE)
  }
  embedded_rate <- pmax(embedded_rate, 0)

  residual <- max(abs(
    embedded_rate -
      drop(t(A_dom) %*% embedded_rate) -
      first_round
  ))

  list(
    direct_rate = statutory_rate,
    embedded_rate = embedded_rate,
    total_rate = statutory_rate + embedded_rate,
    first_round = first_round,
    input_vat = input_vat,
    spectral_radius = spectral_radius,
    equation_residual = residual
  )
}

vat_content_from_expenditure <- function(expenditure, direct_rate,
                                         embedded_rate,
                                         formal_share = 1) {
  formal_share <- pmin(pmax(formal_share, 0), 1)
  formal_exp <- expenditure * formal_share
  informal_exp <- expenditure * (1 - formal_share)

  formal_denominator <- 1 + direct_rate + embedded_rate
  informal_denominator <- 1 + embedded_rate

  direct_vat <- formal_exp * direct_rate / formal_denominator
  embedded_vat <-
    formal_exp * embedded_rate / formal_denominator +
    informal_exp * embedded_rate / informal_denominator

  list(
    direct = direct_vat,
    embedded = embedded_vat,
    total = direct_vat + embedded_vat
  )
}
