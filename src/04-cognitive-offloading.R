# Purpose: Detect cognitive offloading via response time analysis
# Autor: T.H.N. Tran, T.P. Lam, N.M.Q. Nguyen
# Datum: 2026
# Dependencies: jsonlite

library(jsonlite)

config <- fromJSON("config/parameters.json")
log_msg <- function(msg) cat(paste0("[", Sys.time(), "] ", msg, "\n"))

log_msg("Starting 04-cognitive-offloading.R")

df <- read.csv("../data/as_clean.csv", stringsAsFactors = FALSE)
log_msg(paste("Data loaded:", nrow(df), "rows"))

rt_col <- config$bkt$columns$response_time
fast_th <- config$cognitive_offloading$fast_threshold_ms
slow_th <- config$cognitive_offloading$slow_threshold_ms

df_rt <- df[!is.na(df[[rt_col]]) & df[[rt_col]] > 0 & df[[rt_col]] < slow_th, ]
log_msg(paste("Valid response times:", nrow(df_rt)))

df_rt$is_fast <- as.integer(df_rt[[rt_col]] < fast_th)
df_rt$rt_category <- ifelse(df_rt$is_fast == 1, "suspicious_fast",
  ifelse(df_rt[[rt_col]] > 120000, "suspicious_slow", "normal"))

rt_dist <- table(df_rt$rt_category)
log_msg("Response time categories:")
print(rt_dist)

# --- Per-user stats (separate aggregations for correctness) ---
user_counts <- aggregate(cbind(n = rep(1, nrow(df_rt))),
  by = list(user_id = df_rt$user_id), FUN = sum)
user_fast <- aggregate(cbind(n_fast = df_rt$is_fast),
  by = list(user_id = df_rt$user_id), FUN = sum)
user_correct <- aggregate(cbind(correct_rate = df_rt$correct),
  by = list(user_id = df_rt$user_id), FUN = mean)
user_hints <- aggregate(cbind(mean_hints = df_rt$hint_count),
  by = list(user_id = df_rt$user_id), FUN = function(x) mean(x, na.rm = TRUE))
user_rt <- aggregate(df_rt[[rt_col]],
  by = list(user_id = df_rt$user_id), FUN = median)
names(user_rt)[2] <- "median_rt"

us <- Reduce(function(a, b) merge(a, b, by = "user_id"),
  list(user_counts, user_fast, user_correct, user_hints, user_rt))

us$fast_rate <- us$n_fast / us$n
hint_max <- max(us$mean_hints, na.rm = TRUE)
if (hint_max < 1) hint_max <- 10
us$offloading_score <- us$fast_rate * us$correct_rate *
  pmax(0, 1 - us$mean_hints / hint_max)

n_suspicious <- sum(us$offloading_score > 0.3, na.rm = TRUE)
n_total <- nrow(us)
log_msg(sprintf("Users offloading score > 0.3: %d / %d (%.1f%%)",
  n_suspicious, n_total, 100 * n_suspicious / n_total))

results <- list(
  rt_distribution = as.list(rt_dist),
  n_users_total = n_total,
  n_users_suspicious = n_suspicious,
  pct_suspicious = round(100 * n_suspicious / n_total, 1),
  summary_stats = list(
    median_rt_ms = median(df_rt[[rt_col]], na.rm = TRUE),
    mean_rt_ms = round(mean(df_rt[[rt_col]], na.rm = TRUE)),
    fast_threshold_ms = fast_th
  )
)
write(toJSON(results, auto_unbox = TRUE, pretty = TRUE),
      "output/cognitive_offloading.json")
log_msg("04-cognitive-offloading.R DONE")
