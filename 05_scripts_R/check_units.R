library(haven)
data <- read_dta("01_data_sources/Datain/Menage/s04_me_CIV2021.dta", col_select = c("s04q43_unite"))
print(table(as_factor(data$s04q43_unite)))
