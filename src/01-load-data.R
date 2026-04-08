# Purpose: Load and filter ASSISTments dataset
# Autor: T.H.N. Tran, T.P. Lam, N.M.Q. Nguyen
# Datum: 2026
# Dependencies: jsonlite

library(jsonlite)

# --- Config ---
config <- fromJSON("config/parameters.json")
log_msg <- function(msg) cat(paste0("[", Sys.time(), "] ", msg, "\n"))

log_msg("Starting 01-load-data.R")

# --- Load raw data ---
raw_path <- config$data$raw_file
if (!file.exists(raw_path)) stop("File not found: ", raw_path)

df <- read.csv(raw_path, fileEncoding = config$data$encoding,
               stringsAsFactors = FALSE)
log_msg(paste("Raw data loaded:", nrow(df), "rows,", ncol(df), "cols"))

# --- Filter original problems only ---
if (config$data$filter_original) {
  df <- df[df$original == 1, ]
  log_msg(paste("Filtered original=1:", nrow(df), "rows"))
}

# --- Remove NAs in key columns ---
key_cols <- c("user_id", "skill_name", "correct", "order_id")
df <- df[complete.cases(df[, key_cols]), ]
log_msg(paste("After NA removal:", nrow(df), "rows"))

# --- Sort by user and order ---
df <- df[order(df$user_id, df$order_id), ]

# --- Basic stats ---
log_msg(paste("Users:", length(unique(df$user_id))))
log_msg(paste("Skills:", length(unique(df$skill_name))))
log_msg(paste("Correct rate:", round(mean(df$correct), 4)))

# --- Save clean data ---
out_path <- "../data/as_clean.csv"
write.csv(df, out_path, row.names = FALSE)
log_msg(paste("Saved to:", out_path))

# --- Save as JSON for downstream ---
json_path <- "../data/as_summary.json"
dir.create("R/data", showWarnings = FALSE)
summary_data <- list(
  n_rows = nrow(df),
  n_users = length(unique(df$user_id)),
  n_skills = length(unique(df$skill_name)),
  correct_rate = round(mean(df$correct), 4),
  top_skills = as.list(head(sort(table(df$skill_name), decreasing = TRUE), 10))
)
write(toJSON(summary_data, auto_unbox = TRUE, pretty = TRUE), json_path)
log_msg(paste("Summary JSON:", json_path))
log_msg("01-load-data.R DONE")
