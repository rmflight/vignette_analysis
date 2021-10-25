## Load your packages, e.g. library(targets).
source("./packages.R")

## Load your R files
lapply(list.files("./R", full.names = TRUE), source)
#tar_option_set(memory = "worker")

## tar_plan supports drake-style targets and also tar_target()
tar_plan(
  
  current_cran = dir("/big_data/data/cran_2021-10-09/src/contrib", pattern = "tar.gz$", full.names = TRUE),
  
  current_has_vignettes = count_tgz_vignettes(current_cran),
  
  archive_cran = grep("tar.gz", unlist(purrr::map(dir("/big_data/data/cran_2021-10-09/src/contrib/Archive", full.names = TRUE), ~ dir(.x, full.names = TRUE, recursive = TRUE))), value = TRUE) %>%
  grep("BiplotGUI", ., value = TRUE, invert = TRUE),
  archive_has_vignettes = count_tgz_vignettes(archive_cran),
  
  all_bioc = dir("/big_data/data/bioconductor_2021-10-09", full.names = TRUE),
  bioc_has_vignettes = count_bioc_vignettes(all_bioc),
  bioc_zero = check_bioc(bioc_has_vignettes),
  
  tar_render(explore_vignette_counts, "doc/explore_vignette_counts.Rmd")

)
