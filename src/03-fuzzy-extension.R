# Purpose: Apply Fuzzy TFN extension to BKT knowledge states
# Autor: T.H.N. Tran, T.P. Lam, N.M.Q. Nguyen
# Datum: 2026
# Dependencies: jsonlite, 00-bkt-utils.R

library(jsonlite)
source("00-bkt-utils.R")

config <- fromJSON("config/parameters.json")
log_msg <- function(msg) cat(paste0("[", Sys.time(), "] ", msg, "\n"))

log_msg("Starting 03-fuzzy-extension.R")

# --- Load fitted BKT params ---
bkt_params <- fromJSON("output/bkt_params.json")
log_msg(paste("BKT params loaded:", length(bkt_params), "skills"))

# --- Fuzzy TFN functions ---
tfn_scale <- config$fuzzy$tfn_scale

classify_knowledge <- function(p_know) {
  if (p_know < 0.2) return("very_low")
  if (p_know < 0.4) return("low")
  if (p_know < 0.6) return("medium")
  if (p_know < 0.8) return("high")
  return("very_high")
}

fuzzify <- function(p_know) {
  level <- classify_knowledge(p_know)
  tfn <- tfn_scale[[level]]
  list(level = level, l = tfn[1], m = tfn[2], u = tfn[3])
}

defuzzify_centroid <- function(l, m, u) (l + m + u) / 3

# --- Get fitted params for first skill ---
skill <- config$data$selected_skills[1]
if (length(bkt_params) > 0 && !is.null(bkt_params[[skill]])) {
  bp <- bkt_params[[skill]]
  P_L0 <- bp$P_L0; P_T <- bp$P_T; P_G <- bp$P_G; P_S <- bp$P_S
  log_msg(sprintf("Using fitted: P(L0)=%.2f P(T)=%.2f P(G)=%.2f P(S)=%.2f",
                  P_L0, P_T, P_G, P_S))
} else {
  P_L0 <- 0.3; P_T <- 0.1; P_G <- 0.2; P_S <- 0.1
  log_msg("WARNING: No fitted params, using defaults")
}

# --- Pick sample user ---
df <- read.csv("../data/as_clean.csv", stringsAsFactors = FALSE)
sub <- df[df$skill_name == skill, ]
sub <- sub[order(sub$user_id, sub$order_id), ]
user_counts <- table(sub$user_id)
candidates <- names(user_counts[user_counts >= 15])
if (length(candidates) == 0) stop("No user with >= 15 records for skill: ", skill)
# Pick user with MIXED correct/incorrect (not all-correct) for better demo
best_user <- NULL
best_mix <- 1  # want closest to 0.5
for (cand in candidates) {
  ud <- sub[sub$user_id == as.integer(cand), ]
  mix <- abs(mean(ud$correct) - 0.5)
  if (mix < best_mix) { best_mix <- mix; best_user <- as.integer(cand) }
}
sample_user <- best_user
user_data <- sub[sub$user_id == sample_user, ]
log_msg(sprintf("Sample user: %d, records: %d, correct rate: %.2f",
  sample_user, nrow(user_data), mean(user_data$correct)))

# --- BKT + Fuzzy trajectory ---
trajectory <- data.frame(
  step = seq_len(nrow(user_data)),
  correct = user_data$correct,
  p_know_binary = NA_real_,
  fuzzy_level = NA_character_,
  fuzzy_defuzzified = NA_real_,
  stringsAsFactors = FALSE
)

pk <- P_L0
for (i in seq_len(nrow(user_data))) {
  pk_post <- bkt_update(pk, user_data$correct[i], P_G, P_S)
  pk <- pk_post + (1 - pk_post) * P_T
  pk <- max(min(pk, 0.9999), 0.0001)  # clamp: never exactly 0 or 1
  trajectory$p_know_binary[i] <- pk
  fz <- fuzzify(pk)
  trajectory$fuzzy_level[i] <- fz$level
  trajectory$fuzzy_defuzzified[i] <- defuzzify_centroid(fz$l, fz$m, fz$u)
}

write(toJSON(trajectory, auto_unbox = TRUE, pretty = TRUE),
      "output/fuzzy_trajectory.json")
log_msg("03-fuzzy-extension.R DONE")
