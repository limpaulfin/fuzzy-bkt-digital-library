# Purpose: BKT core functions (Corbett & Anderson, 1994)
# Autor: T.H.N. Tran, T.P. Lam, N.M.Q. Nguyen
# Datum: 2026
# Reference: Corbett & Anderson (1994), van de Sande (2013)

bkt_update <- function(p_know, obs, P_G, P_S) {
  if (obs == 1) {
    p_obs_know <- 1 - P_S
    p_obs_notknow <- P_G
  } else {
    p_obs_know <- P_S
    p_obs_notknow <- 1 - P_G
  }
  numer <- p_obs_know * p_know
  denom <- numer + p_obs_notknow * (1 - p_know)
  if (denom < 1e-15) return(p_know)
  return(numer / denom)
}

bkt_predict <- function(responses, P_L0, P_T, P_G, P_S) {
  n <- length(responses)
  p_know <- numeric(n)
  p_correct <- numeric(n)
  pk <- P_L0
  for (i in seq_len(n)) {
    p_correct[i] <- pk * (1 - P_S) + (1 - pk) * P_G
    pk_post <- bkt_update(pk, responses[i], P_G, P_S)
    pk <- pk_post + (1 - pk_post) * P_T
    p_know[i] <- pk
  }
  return(list(p_know = p_know, p_correct = p_correct))
}

bkt_loglik <- function(responses_list, P_L0, P_T, P_G, P_S) {
  ll <- 0
  for (resp in responses_list) {
    pred <- bkt_predict(resp, P_L0, P_T, P_G, P_S)
    for (i in seq_along(resp)) {
      p <- pred$p_correct[i]
      p <- max(min(p, 1 - 1e-10), 1e-10)
      ll <- ll + resp[i] * log(p) + (1 - resp[i]) * log(1 - p)
    }
  }
  return(ll)
}

bkt_fit_grid <- function(responses_list) {
  best_ll <- -Inf
  best_params <- NULL
  for (P_L0 in seq(0.1, 0.7, by = 0.1)) {
    for (P_T in seq(0.05, 0.5, by = 0.05)) {
      for (P_G in seq(0.05, 0.4, by = 0.05)) {
        for (P_S in seq(0.05, 0.3, by = 0.05)) {
          ll <- bkt_loglik(responses_list, P_L0, P_T, P_G, P_S)
          if (ll > best_ll) {
            best_ll <- ll
            best_params <- list(
              P_L0 = P_L0, P_T = P_T,
              P_G = P_G, P_S = P_S, loglik = ll
            )
          }
        }
      }
    }
  }
  return(best_params)
}
