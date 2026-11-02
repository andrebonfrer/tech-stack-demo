# Workshop prompts

Used to rebuild the simulation live. AI output varies between runs, so the live result will differ from the tested files in `simulation/`; the tagged version (`v-demo`) is the fallback.

## Prompt 1: simulate

```
Write an R script sim.R (base R only, set.seed(2026)) that simulates
daily sales for 3 years (1095 days) from a Koyck model:
S_t = 10 + 2*A_t + 0.7*S_{t-1} + e_t, e_t ~ N(0, 1).
A_t is a 0/1 advertising pulse with probability 0.3 per day.
Save a data frame with columns day, week, month, A, S.
Also write a function aggregate_data(df, level) that sums A and S to
"week" or "month" level.
```

## Prompt 2: estimate

```
Add a function estimate_koyck(df) that regresses S_t on A_t and S_{t-1}
by OLS and returns beta, lambda, the long-run effect beta/(1-lambda),
and the 90% duration interval log(0.1)/log(lambda) in that data's time
units. Run it on daily, weekly and monthly data. For weekly and monthly,
also convert lambda to a daily equivalent (lambda^(1/7) and
lambda^(1/30)). Print a comparison table against the true daily values.
```

## Prompt 3: Shiny app

```
Turn this into a single-file Shiny app (app.R) using shiny and ggplot2.
Sidebar: sliders for true lambda (0.3-0.95), ad pulse probability
(0.05-0.9), noise SD (0.5-3) and a "Simulate" button.
Main panel: (1) a table of estimates at daily, weekly and monthly level
against the true values; (2) a bar chart of the implied 90% duration
interval in days at each level, with a dashed line at the true value.
Keep the code under 150 lines with comments.
```

## Things to watch for in the live output

- Monthly data has only ~36 observations, so the estimated carryover can be negative. Duration is then undefined; the tested version reports it as missing rather than producing NaN.
- Check the daily estimates recover the true values before interpreting the weekly and monthly ones.
