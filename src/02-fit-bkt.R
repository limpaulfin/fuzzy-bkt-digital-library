# Purpose: Fit BKT model on selected skills
# Autor: T.H.N. Tran, T.P. Lam, N.M.Q. Nguyen
# Datum: 2026
# Dependencies: jsonlite, 00-bkt-utils.R

library(jsonlite)
source("00-bkt-utils.R")

config <- fromJSON("config/parameters.json")
log_msg <- function(msg) cat(paste0("[", Sys.time(), "] ", msg, "\n"))

log_msg("Starting 02-fit-bkt.R")

df <- read.csv("../data/as_clean.csv", stringsAsFactors = FALSE)
log_msg(paste("Data loaded:", nrow(df), "rows"))

skills <- config$data$selected_skills
log_msg(paste("Selected skills:", length(skills)))
min_responses <- as.integer(config$bkt$num_fits)

results <- list()
for (skill in skills) {
  log_msg(paste("Fitting:", skill))
  sub <- df[df$skill_name == skill, ]
  if (nrow(sub) < 100) { log_msg("  SKIP: too few rows"); next }

  resp_list <- lapply(unique(sub$user_id), function(u) {
    ud <- sub[sub$user_id == u, ]
    ud$correct[order(ud$order_id)]
  })
  resp_list <- resp_list[sapply(resp_list, length) >= 3]

  tryCatch({
    params <- bkt_fit_grid(resp_list)
    params$skill <- skill
    params$n_records <- nrow(sub)
    params$n_users <- length(resp_list)
    results[[skill]] <- params
    log_msg(sprintf("  P(L0)=%.2f P(T)=%.2f P(G)=%.2f P(S)=%.2f LL=%.1f",
                    params$P_L0, params$P_T, params$P_G, params$P_S, params$loglik))
  }, error = function(e) log_msg(paste("  ERROR:", e$message)))
}

dir.create("R/output", showWarnings = FALSE, recursive = TRUE)
write(toJSON(results, auto_unbox = TRUE, pretty = TRUE), "output/bkt_params.json")
log_msg("02-fit-bkt.R DONE")
