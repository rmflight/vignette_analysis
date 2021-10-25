
# Vignette Analysis

<!-- badges: start -->
<!-- badges: end -->

The goal of this project is to analyze the changes in the number of vignettes over time, ideally to quantify the effect of knitr and rmarkdown.

I created a personal CRAN mirror and cloned all available Bioconductor git repos on 2021-10-09.
For each current and available package under the CRAN archive, I counted how many sweave and markdown vignettes were present.
For Bioconductor, I counted how many of each vignette type was present at each commit.

The RDS files with this data are in:

  * [Bioconductor](https://github.com/rmflight/vignette_analysis/blob/main/_targets/objects/bioc_has_vignettes)
  * [CRAN](https://github.com/rmflight/vignette_analysis/blob/main/_targets/objects/cran_has_vignettes)
  * [CRAN archive](https://github.com/rmflight/vignette_analysis/blob/main/_targets/objects/archive_has_vignettes)
  
For more information on how I ran this code, see the `_targets.R` file and the underlying functions in the R directory.

The quickest way to get started with this data is to clone it and then use targets to load the data of interest:

```r
targets::tar_load(cran_has_vignettes)
targets::tar_load(bioc_has_vignettes)
```

I'm relatively sure the code is counting vignettes correctly, given that only 200 Bioconductor vignettes have zero, and when I check some of those manually, there are no vignettes listed on the package web-page.
