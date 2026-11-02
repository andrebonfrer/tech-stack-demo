# tech-stack-demo

Demo materials for the workshop *The Academic's Tech Stack: Tools for Research, Teaching and Marketing*.

## Simulation: does the data interval matter?

Estimates of advertising carryover depend on how finely data are aggregated. Tellis and Franses (2006) show that the optimal data interval is the unit exposure time, the interval in which a consumer would typically see a single ad. This demo simulates daily sales from a Koyck model with known carryover, aggregates to weekly and monthly totals, and re-estimates the model at each level.

| File | What it does |
|---|---|
| `simulation/sim.R` | Simulates, aggregates and prints a comparison table (base R) |
| `simulation/app.R` | Shiny app to explore how the bias changes with carryover, ad frequency and noise |
| `prompts.md` | The prompts used to build these files live in the workshop |

Run:

```r
source("simulation/sim.R")          # or: Rscript simulation/sim.R
shiny::runApp("simulation")         # needs shiny and ggplot2
```

## The `v-demo` tag

`v-demo` marks the tested version. In the workshop the code is rebuilt live on a separate branch; if that goes wrong:

```
git stash -u
git checkout v-demo
```

## Reference

Tellis, G. J., & Franses, P. H. (2006). Optimal data interval for estimating advertising response. *Marketing Science*, 25(3), 217–229. https://doi.org/10.1287/mksc.1050.0178
