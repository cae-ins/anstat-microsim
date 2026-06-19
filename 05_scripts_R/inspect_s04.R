library(haven)
data <- read_dta("01_data_sources/Datain/Menage/s04_me_CIV2021.dta", n_max = 5)
print(colnames(data))
print(sapply(data, function(x) attr(x, "label")))
