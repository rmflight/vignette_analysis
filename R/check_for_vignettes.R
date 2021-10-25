check_for_vignettes = function(tgz_list){
  check_vig = purrr::map_lgl(tgz_list, function(.x){
    all_files = untar(.x, list = TRUE)
    any(grepl("doc.*Rmd|doc.*Rnw|doc.*pdf|doc.*html", all_files))
  })
  tgz_list[check_vig]
}

create_tmp_dir = function(tmp_loc = tempdir()){
  use_loc = tempfile(pattern = "check_knitr", tmpdir = tmp_loc)
  dir.create(use_loc)
  use_loc
}

untar_pkg = function(tar_loc, tmp_dir){
  untar(tar_loc, exdir = tmp_dir)
  pkg_dir = file.path(tmp_dir, gsub("_.*", "", basename(tar_loc)))
  pkg_dir
}

check_tar_list = function(untared_dir){
  if (dir.exists(untared_dir)) {
    all_files = dir(untared_dir, full.names = TRUE, recursive = TRUE)
    vig_files = grep("vignettes.*", all_files, value = TRUE)
    if (length(vig_files) > 0) {
      n_rnw = sum(grepl(".Rnw$", vig_files))
      n_rmd = sum(grepl(".Rmd$", vig_files))
    } else {
      n_rnw = 0
      n_rmd = 0
    }
    desc_data = read.dcf(file.path(untared_dir, "DESCRIPTION"))
    if ("Package" %in% colnames(desc_data)) {
      out_data = data.frame(
        package = desc_data[1, "Package"],
        version = desc_data[1, "Version"],
        date = if ("Packaged" %in% colnames(desc_data)) gsub(";.*", "", desc_data[1, "Packaged"]) else "0",
        rnw = n_rnw,
        rmd = n_rmd)
      rownames(out_data) = NULL
    } else {
      out_data = NULL
    }
    
    unlink(untared_dir, recursive = TRUE, force = TRUE)
    out_data
  } else {
    out_data = NULL
  }
  out_data
}

count_tgz_vignettes = function(tgz_list, tmp_dir = "/big_data/data"){
  use_dir = create_tmp_dir(tmp_dir)
  tgz_data = purrr::map_df(tgz_list, function(tar_file){
    #message(basename(tar_file))
    pkg_dir = untar_pkg(tar_file, use_dir)
    out_res = try(check_tar_list(pkg_dir))
    if (inherits(out_res, "try-error")) {
      return(NULL)
    } else (
      return(out_res)
    )
  })
  tgz_data
}

count_bioc_vignettes = function(bioc_directories){
  n_bioc = length(bioc_directories)
  #prog_bar = knitrProgressBar::progress_estimated(n_bioc)
  
  bioc_counts = furrr::future_map(bioc_directories, check_bioc_git)
  bioc_counts = purrr::map_df(bioc_counts, ~ .x)
  bioc_counts
}

check_bioc_git = function(bioc_repo){
  all_commits = try(git2r::commits(bioc_repo))
  if (inherits(all_commits, "try-error")) {
    return(NULL)
  }
  commit_rmd = purrr::map_df(all_commits, git_dates_files)
  # if (inherits(commit_rmd, "try-error")) {
  #   return(NULL)
  # }
  commit_rmd$package = basename(bioc_repo)
  #message(basename(bioc_repo))
  #knitrProgressBar::update_progress(prog_bar)
  commit_rmd
}

git_dates_files = function(in_commit){
  out_frame = try({
    commit_date = as.POSIXct(in_commit$author$when)
    commit_vignettes = ls_tree(tree(in_commit), recursive = TRUE) %>%
      dplyr::filter(path %in% "vignettes/") %>%
      dplyr::pull(name)
    
    n_rnw = sum(grepl("[.][rsRS]nw$|[.][rsRS]tex$|[.]tex$", commit_vignettes, ignore.case = TRUE))
    n_rmd = sum(grepl("[.]rmd$", commit_vignettes, ignore.case = TRUE))
    data.frame(date = commit_date, rnw = n_rnw, rmd = n_rmd)
  })
  if (inherits(out_frame, "try-error")) {
    return(NULL)
  } else {
    return(out_frame)
  }
}

# bioconductor, every package should have a vignette
# So if we don't have any at all for the whole commit
# history, then something went wrong.d
check_bioc = function(bioc_has_vignettes){
  all_packages = unique(bioc_has_vignettes$package)
  n_per = bioc_has_vignettes %>%
    dplyr::mutate(n_vig = rmd + rnw) %>%
    dplyr::group_by(package) %>%
    dplyr::arrange(desc(n_vig)) %>%
    dplyr::slice(n = 1) %>%
    dplyr::select(n_vig, package)
  n_zero = n_per %>%
    dplyr::filter(n_vig == 0)
  n_zero
}