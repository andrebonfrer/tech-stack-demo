# sim.R
# Data interval bias in advertising response (cf. Tellis & Franses 2006,
# Marketing Science 25(3), 217-229).
#
# 1. Simulate daily sales from a Koyck model with known carryover.
# 2. Aggregate to weekly and monthly totals.
# 3. Re-estimate the model at each level and compare with the truth.
#
# Base R only. Run with: Rscript simulation/sim.R

set.seed(2026)

# ---- true parameters -------------------------------------------------------
true <- list(alpha = 10, beta = 2, lambda = 0.7, p_ad = 0.3, sd = 1)

# ---- simulate daily data ---------------------------------------------------
simulate_daily <- function(n_days = 1095, alpha = 10, beta = 2, lambda = 0.7,
                           p_ad = 0.3, sd = 1) {
  A <- rbinom(n_days, 1, p_ad)                # 0/1 advertising pulse
  S <- numeric(n_days)
  S_prev <- alpha / (1 - lambda)              # start near steady state
  for (t in seq_len(n_days)) {
    S[t] <- alpha + beta * A[t] + lambda * S_prev + rnorm(1, 0, sd)
    S_prev <- S[t]
  }
  data.frame(day   = seq_len(n_days),
             week  = (seq_len(n_days) - 1) %/% 7 + 1,
             month = (seq_len(n_days) - 1) %/% 30 + 1,   # 30-day "months"
             A = A, S = S)
}

# ---- aggregate to week or month -------------------------------------------
aggregate_data <- function(df, level = c("week", "month")) {
  level <- match.arg(level)
  agg <- aggregate(cbind(A, S) ~ df[[level]], data = df, FUN = sum)
  names(agg)[1] <- "period"
  # drop an incomplete final period
  len <- table(df[[level]])
  agg[len[as.character(agg$period)] == max(len), ]
}

# ---- estimate the Koyck model by OLS --------------------------------------
estimate_koyck <- function(df) {
  n <- nrow(df)
  fit <- lm(S[-1] ~ A[-1] + S[-n], data = df)
  b <- unname(coef(fit))
  beta <- b[2]; lambda <- b[3]
  # carryover only interpretable for 0 < lambda < 1
  ok <- lambda > 0 && lambda < 1
  c(beta = beta,
    lambda = lambda,
    long_run = if (ok) beta / (1 - lambda) else NA,
    duration90 = if (ok) log(0.1) / log(lambda) else NA)  # in data's time units
}

# daily-equivalent carryover; NA when lambda is outside (0, 1)
daily_equiv <- function(lambda, k) ifelse(lambda > 0 & lambda < 1, lambda^(1/k), NA)

# ---- compare daily, weekly and monthly ------------------------------------
compare_levels <- function(daily) {
  d <- estimate_koyck(daily)
  w <- estimate_koyck(aggregate_data(daily, "week"))
  m <- estimate_koyck(aggregate_data(daily, "month"))
  data.frame(
    level = c("true (daily)", "daily", "weekly", "monthly"),
    lambda_raw = c(NA, d["lambda"], w["lambda"], m["lambda"]),
    lambda_daily_equiv = c(true$lambda, d["lambda"],
                           daily_equiv(w["lambda"], 7),
                           daily_equiv(m["lambda"], 30)),
    duration90_days = c(log(0.1) / log(true$lambda),
                        d["duration90"],
                        w["duration90"] * 7,
                        m["duration90"] * 30),
    row.names = NULL
  )
}

if (sys.nframe() == 0) {
  daily <- do.call(simulate_daily, true)
  res <- compare_levels(daily)
  print(res, digits = 3)
}
