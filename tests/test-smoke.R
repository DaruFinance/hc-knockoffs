#!/usr/bin/env Rscript
# Smoke test: scripts/hc_curve.R runs end-to-end in synthetic mode and
# produces both a non-empty PNG and a parseable JSON.

# Locate this test file robustly (works under Rscript invocation).
this_file <- (function() {
  args <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args, value = TRUE)
  if (length(fa) > 0) return(normalizePath(sub("^--file=", "", fa[1])))
  ofile <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (!is.null(ofile)) return(normalizePath(ofile))
  stop("cannot determine script path")
})()
repo_root <- normalizePath(file.path(dirname(this_file), ".."), mustWork = FALSE)

old_wd <- getwd()
on.exit(setwd(old_wd))
setwd(repo_root)

fig_path  <- file.path(repo_root, "figures", "hc_synthetic.png")
json_path <- file.path(repo_root, "hc_curve.json")
if (file.exists(fig_path))  unlink(fig_path)
if (file.exists(json_path)) unlink(json_path)

cat("running scripts/hc_curve.R from", repo_root, "\n")
status <- system2("Rscript", args = "scripts/hc_curve.R", stdout = TRUE, stderr = TRUE)
cat(paste(status, collapse = "\n"), "\n")

stopifnot(file.exists(fig_path))
stopifnot(file.info(fig_path)$size > 5000)
stopifnot(file.exists(json_path))

payload <- jsonlite::fromJSON(json_path)
stopifnot(payload$source == "synthetic")
stopifnot(is.numeric(payload$detection_boundary))
stopifnot(payload$detection_boundary > 0)

cat("ok\n")
