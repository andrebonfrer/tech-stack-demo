# app.R
# Interactive demo of data interval bias in advertising response.
# Simulate daily sales with known carryover, aggregate to weekly and
# monthly totals, re-estimate, and compare with the truth.
#
# Run with: shiny::runApp("simulation")

library(shiny)
library(ggplot2)

# ---- simulation and estimation (same logic as sim.R) ----------------------
simulate_daily <- function(n_days, alpha, beta, lambda, p_ad, sd) {
  A <- rbinom(n_days, 1, p_ad)
  S <- numeric(n_days)
  S_prev <- alpha / (1 - lambda)
  for (t in seq_len(n_days)) {
    S[t] <- alpha + beta * A[t] + lambda * S_prev + rnorm(1, 0, sd)
    S_prev <- S[t]
  }
  data.frame(day = seq_len(n_days),
             week = (seq_len(n_days) - 1) %/% 7 + 1,
             month = (seq_len(n_days) - 1) %/% 30 + 1,
             A = A, S = S)
}

aggregate_data <- function(df, level) {
  agg <- aggregate(cbind(A, S) ~ df[[level]], data = df, FUN = sum)
  names(agg)[1] <- "period"
  len <- table(df[[level]])
  agg[len[as.character(agg$period)] == max(len), ]   # drop partial period
}

estimate_lambda <- function(df) {
  n <- nrow(df)
  unname(coef(lm(S[-1] ~ A[-1] + S[-n], data = df))[3])
}

# 90% duration interval in days, given carryover per period of k days
duration_days <- function(lambda, k) {
  ifelse(lambda > 0 & lambda < 1, k * log(0.1) / log(lambda), NA)
}

# ---- UI --------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Does the data interval matter?"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("lambda", "True daily carryover (lambda)", 0.3, 0.95, 0.7, 0.05),
      sliderInput("p_ad", "Probability of an ad pulse per day", 0.05, 0.9, 0.3, 0.05),
      sliderInput("sd", "Noise (SD)", 0.5, 3, 1, 0.25),
      actionButton("go", "Simulate", class = "btn-primary"),
      hr(),
      helpText("Daily sales follow S_t = 10 + 2 A_t + lambda S_{t-1} + e_t",
               "over 3 years. The same model is then estimated on weekly",
               "and monthly totals.")
    ),
    mainPanel(
      h4("Estimates by data interval"),
      tableOutput("tab"),
      h4("Implied 90% duration of the ad effect (days)"),
      plotOutput("plot", height = "300px"),
      textOutput("note")
    )
  )
)

# ---- server ----------------------------------------------------------------
server <- function(input, output, session) {

  results <- eventReactive(input$go, ignoreNULL = FALSE, {
    daily <- simulate_daily(1095, 10, 2, input$lambda, input$p_ad, input$sd)
    lam <- c(estimate_lambda(daily),
             estimate_lambda(aggregate_data(daily, "week")),
             estimate_lambda(aggregate_data(daily, "month")))
    k <- c(1, 7, 30)
    data.frame(
      Level = factor(c("Daily", "Weekly", "Monthly"),
                     levels = c("Daily", "Weekly", "Monthly")),
      `Estimated lambda (per period)` = lam,
      `Daily-equivalent lambda` = ifelse(lam > 0 & lam < 1, lam^(1 / k), NA),
      `90% duration (days)` = duration_days(lam, k),
      check.names = FALSE
    )
  })

  true_duration <- reactive({
    input$go
    isolate(log(0.1) / log(input$lambda))
  })

  output$tab <- renderTable({
    rbind(
      data.frame(Level = "True", `Estimated lambda (per period)` = NA,
                 `Daily-equivalent lambda` = isolate(input$lambda),
                 `90% duration (days)` = true_duration(), check.names = FALSE),
      results()
    )
  }, digits = 3, na = "–")

  output$plot <- renderPlot({
    d <- results()
    ggplot(d, aes(Level, `90% duration (days)`)) +
      geom_col(fill = "#1F3A5F", width = 0.6, na.rm = TRUE) +
      geom_hline(yintercept = true_duration(), linetype = "dashed",
                 colour = "#E07A1F", linewidth = 1) +
      labs(x = NULL, y = "Days", caption = "Dashed line: true duration") +
      theme_minimal(base_size = 14)
  })

  output$note <- renderText({
    if (any(is.na(results()$`90% duration (days)`)))
      "A missing bar means the estimated carryover was not between 0 and 1, so no duration can be implied at that interval."
  })
}

shinyApp(ui, server)
