#!/usr/bin/env Rscript
# hc_curve.R — Higher-Criticism statistic on upper-tail p-values.
#
# Two operating modes:
#
#   * synthetic (default)
#       Draws a uniform null and a sparse-alternative p-value sample, plots
#       HC(α) for both, and writes hc_synthetic.png + hc_curve.json. No
#       external data required; reproducible (set.seed(2026)).
#
#   * --data-root <path>   (or $STRATEGY_DATA_ROOT)
#       Reads the precomputed per-asset HC table produced by the thesis
#       pipeline at <root>/01_Higher_Criticism/tables/{tab01,tab02}*.csv,
#       writes the per-asset bar chart + the portfolio-site JSON.
#
# Output:
#   figures/hc_synthetic.png     (or figures/hc_per_asset.png)
#   hc_curve.json

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(jsonlite)
})

`%||%` <- function(a, b) if (is.null(a) || (is.atomic(a) && length(a) == 1 && is.na(a))) b else a

# Resolve where this script lives so output paths are stable regardless of cwd.
script_dir <- (function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  }
  ofile <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL) %||% NULL
  if (!is.null(ofile)) return(dirname(normalizePath(ofile)))
  getwd()
})()
repo_root <- dirname(script_dir)
out_dir <- file.path(repo_root, "figures")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# --- argument parsing -----------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
data_root <- NULL
i <- 1
while (i <= length(args)) {
  if (args[i] == "--data-root" && i + 1 <= length(args)) {
    data_root <- args[i + 1]
    i <- i + 2
  } else {
    i <- i + 1
  }
}
if (is.null(data_root)) {
  env <- Sys.getenv("STRATEGY_DATA_ROOT", unset = "")
  if (nzchar(env)) data_root <- env
}

# --- HC statistic ---------------------------------------------------------
hc_statistic <- function(p, alpha0 = 0.2) {
  # Donoho & Jin (2004): HC(α) = √n (α − p_(⌈αn⌉)) / √(p (1 − p));
  # HC* is the maximum over α ∈ (0, α0]. Detection boundary under the null
  # is √(2 log log n).
  p <- sort(pmin(pmax(p, 1e-12), 1 - 1e-12))
  n <- length(p)
  k <- seq_len(n)
  alpha <- k / n
  num <- sqrt(n) * (alpha - p)
  denom <- sqrt(p * (1 - p))
  hc <- num / denom
  sel <- alpha <= alpha0
  list(alpha = alpha[sel], hc = hc[sel], max = max(hc[sel]))
}

# --- mode A: real-data ----------------------------------------------------
if (!is.null(data_root)) {
  path_per  <- file.path(data_root, "01_Higher_Criticism", "tables", "tab01_per_asset_hc.csv")
  path_pool <- file.path(data_root, "01_Higher_Criticism", "tables", "tab02_pooled_hc.csv")
  per  <- read_csv(path_per,  show_col_types = FALSE)
  pool <- read_csv(path_pool, show_col_types = FALSE)

  p <- ggplot(per, aes(x = reorder(Asset, HC_star), y = HC_star)) +
    geom_col(fill = "#6f7680") +
    geom_hline(yintercept = mean(per$null_95), linetype = "dashed", colour = "#e0625d") +
    annotate("text", x = 1, y = mean(per$null_95) + 0.2,
             label = sprintf("null 95%% ≈ %.2f", mean(per$null_95)),
             hjust = 0, colour = "#e0625d") +
    coord_flip() +
    labs(x = NULL, y = "HC*",
         title = "Higher Criticism · per asset",
         subtitle = "no asset exceeds the null 95% detection boundary") +
    theme_minimal(base_size = 11)
  ggsave(file.path(out_dir, "hc_per_asset.png"), p, width = 7, height = 4, dpi = 160)

  json_out <- list(
    assets = lapply(seq_len(nrow(per)), function(i)
      list(asset = per$Asset[i], hc_star = per$HC_star[i],
           null_95 = per$null_95[i], n_strategies = per$n_strategies[i],
           significant = per$significant_95[i])),
    pooled = list(hc_star = pool$HC_star[1], null_95 = pool$null_95[1],
                  null_99 = pool$null_99[1], n_strategies = pool$n_strategies[1]),
    detection_boundary = pool$null_95[1],
    source = "thesis"
  )
  json_path <- file.path(repo_root, "hc_curve.json")
  writeLines(toJSON(json_out, auto_unbox = TRUE, pretty = FALSE), json_path)
  cat("wrote", json_path, "\n")

# --- mode B: synthetic ----------------------------------------------------
} else {
  set.seed(2026)
  n <- 2000
  null_p <- runif(n)
  alt_p  <- pnorm(rnorm(n, mean = 1.8, sd = 1), lower.tail = FALSE)
  d_null <- hc_statistic(null_p)
  d_alt  <- hc_statistic(alt_p)
  df <- rbind(
    data.frame(alpha = d_null$alpha, hc = d_null$hc, src = "Uniform null"),
    data.frame(alpha = d_alt$alpha,  hc = d_alt$hc,  src = "Sparse alternative")
  )
  boundary <- sqrt(2 * log(log(n)))
  p <- ggplot(df, aes(alpha, hc, colour = src)) +
    geom_line(linewidth = 0.8) +
    geom_hline(yintercept = boundary, linetype = "dashed", colour = "#e0625d") +
    annotate("text", x = 0.18, y = boundary + 0.3,
             label = sprintf("detection boundary ≈ %.2f", boundary),
             colour = "#e0625d") +
    scale_colour_manual(values = c("Uniform null" = "#6f7680", "Sparse alternative" = "#b6ff4a")) +
    labs(x = "α  (rank fraction)", y = "HC(α)",
         title = "Higher Criticism · synthetic demo", colour = NULL) +
    theme_minimal(base_size = 11)
  ggsave(file.path(out_dir, "hc_synthetic.png"), p, width = 7, height = 4, dpi = 160)

  json_out <- list(
    source = "synthetic",
    n = n,
    detection_boundary = boundary,
    null = list(hc_star = d_null$max),
    alternative = list(hc_star = d_alt$max)
  )
  json_path <- file.path(repo_root, "hc_curve.json")
  writeLines(toJSON(json_out, auto_unbox = TRUE, pretty = FALSE), json_path)
  cat("wrote", file.path(out_dir, "hc_synthetic.png"), "and", json_path, "\n")
}
