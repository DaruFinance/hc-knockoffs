# hc-knockoffs

> Reference implementation for [Sparse signal detection with FDR control](https://www.daru.finance/projects/hc-knockoffs), from the Lab that Daniel Gatto keeps at [daru.finance](https://www.daru.finance).

**Higher Criticism under dependence · Model-X Knockoffs for FDR-controlled
strategy selection.**

Two complementary multiple-testing primitives for large-scale strategy audits:

1. **Higher Criticism** (Donoho & Jin 2004) — a non-parametric detector of
   sparse, weak signal in a population of test statistics. Under the null
   the HC statistic converges at rate `√(2 log log n)`; values below this
   detection boundary indicate no discoveries survive.
2. **Model-X Knockoffs** (Candès, Fan, Janson, Lv 2018) — a distribution-free
   construction of "knockoff" variables that share the covariance of the
   originals but are conditionally independent of the response. Enables
   finite-sample FDR control without parametric assumptions.

## Reproduce

```bash
git clone https://github.com/DaruFinance/hc-knockoffs
cd hc-knockoffs
Rscript -e 'install.packages(c("ggplot2","dplyr","readr","jsonlite"), repos="https://cloud.r-project.org")'
Rscript scripts/hc_curve.R
```

Runs the reproducible synthetic demo (`set.seed(2026)`) and writes
`figures/hc_synthetic.png` plus `hc_curve.json`. No external data needed.

## Problem statement

Given per-strategy out-of-sample t-statistics `t₁, …, tₙ`, let `p₁, …, pₙ` be
one-sided upper-tail p-values. The HC statistic is

```
HC_n* = max_{α ∈ (0, α₀]}  √n (α − p_{(⌈αn⌉)}) / √(p_{(⌈αn⌉)} (1 − p_{(⌈αn⌉)}))
```

HC* is a rare-and-weak signal test: it detects departures from the uniform
null in the extreme tail without requiring knowledge of where the signal sits.

## Usage

The default mode runs a synthetic Gaussian null + sparse alternative:

```bash
Rscript scripts/hc_curve.R
```

To reproduce the per-asset thesis figure, point the script at the data root
either via `--data-root` or the `STRATEGY_DATA_ROOT` environment variable:

```bash
export STRATEGY_DATA_ROOT="$HOME/PhD_Research"   # adjust for your machine
Rscript scripts/hc_curve.R --data-root "$STRATEGY_DATA_ROOT"
```

The expected layout under `$STRATEGY_DATA_ROOT` is:

```
01_Higher_Criticism/tables/tab01_per_asset_hc.csv
01_Higher_Criticism/tables/tab02_pooled_hc.csv
```

## Key result

Across all nine instruments (crypto / FX / commodities, N > 30k strategies each),
HC* is well below the Monte-Carlo null 95% threshold `≈ 3.08`:

| Asset  |  n  | HC* | null 95% |
|--------|-----|-----|----------|
| BTC    |  37,956 | −2.23 | 3.08 |
| DOGE   |  36,681 | −1.89 | 3.14 |
| SOL    |  38,208 | −0.22 | 3.12 |
| BNB    |  38,100 | −4.09 | 3.08 |
| EURUSD |  50,709 | −5.54 | 3.10 |
| USDJPY |  50,705 | −23.07 | 3.10 |
| EURGBP |  50,690 | −6.93 | 3.09 |
| XAUUSD |  50,706 | −2.64 | 3.10 |
| WTI    |  50,703 | −4.14 | 3.07 |

No asset exhibits detectable alpha under this test.

## References

- Donoho, D. L. & Jin, J. (2004). *Higher criticism for detecting sparse
  heterogeneous mixtures.* Annals of Statistics 32(3).
- Candès, E. J., Fan, Y., Janson, L. & Lv, J. (2018). *Panning for gold:
  Model-X knockoffs for high-dimensional controlled variable selection.* JRSSB.
- Barber, R. F. & Candès, E. J. (2015). *Controlling the false discovery rate
  via knockoffs.* Annals of Statistics 43(5).

## License

MIT © Daniel Vieira Gatto.
