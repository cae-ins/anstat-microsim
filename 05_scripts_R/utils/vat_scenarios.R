# Paramètres explicites des scénarios de taxation effective.
# Ces profils sont des hypothèses exogènes inspirées des courbes d'Engel de
# l'informalité de Bachas, Gadenne et Jensen (2024). Ils ne sont pas estimés
# sur l'EHCVM ivoirienne et ne sont calés sur aucune cible administrative.

vat_alpha_milieu_parameters <- function() {
  tibble::tribble(
    ~coicop_num, ~alpha_rural, ~alpha_urban,
    1L, 0.18, 0.42, 2L, 0.55, 0.72, 3L, 0.28, 0.52,
    4L, 0.68, 0.84, 5L, 0.28, 0.48, 6L, 0.38, 0.66,
    7L, 0.32, 0.62, 8L, 0.82, 0.94, 9L, 0.35, 0.58,
    10L, 0.62, 0.78, 11L, 0.18, 0.52, 12L, 0.88, 0.95,
    13L, 0.22, 0.48, 98L, 0.00, 0.00, 99L, 0.00, 0.00
  )
}

vat_alpha_decile_parameters <- function() {
  tibble::tribble(
    ~coicop_num, ~alpha_d1, ~slope,
    1L, 0.12, 0.034, 2L, 0.48, 0.024, 3L, 0.22, 0.030,
    4L, 0.62, 0.022, 5L, 0.22, 0.028, 6L, 0.30, 0.040,
    7L, 0.25, 0.038, 8L, 0.78, 0.015, 9L, 0.28, 0.032,
    10L, 0.55, 0.025, 11L, 0.12, 0.038, 12L, 0.85, 0.010,
    13L, 0.15, 0.034, 98L, 0.00, 0.000, 99L, 0.00, 0.000
  )
}

vat_alpha_decile_matrix <- function() {
  p <- vat_alpha_decile_parameters()
  deciles <- tibble::tibble(decile = 1:10)
  tidyr::crossing(p, deciles) |>
    dplyr::mutate(alpha = pmin(alpha_d1 + (decile - 1) * slope, 1)) |>
    dplyr::select(coicop_num, decile, alpha) |>
    tidyr::pivot_wider(names_from = decile, values_from = alpha,
                       names_prefix = "D")
}

vat_alpha_milieu <- function(coicop, milieu) {
  parameters <- vat_alpha_milieu_parameters()
  index <- match(as.integer(as.character(coicop)), parameters$coicop_num)
  rural <- as.character(milieu) %in% c("2", "Rural", "rural")
  alpha <- ifelse(rural, parameters$alpha_rural[index], parameters$alpha_urban[index])
  replace(alpha, is.na(alpha), 0)
}

vat_alpha_decile <- function(coicop, decile) {
  parameters <- vat_alpha_decile_parameters()
  index <- match(as.integer(as.character(coicop)), parameters$coicop_num)
  alpha <- parameters$alpha_d1[index] + (as.integer(decile) - 1) * parameters$slope[index]
  alpha <- pmin(alpha, 1)
  replace(alpha, is.na(alpha), 0)
}