# GDP vs CO2 Emissions: Which Countries Achieved Absolute Decoupling?

Project for **MAT2007 Introduction to Programming** (Maastricht University).
Author: Konstantina Kyrmizoglou

## Research question

Can an economy grow while its CO2 emissions fall? Which countries achieved
**absolute decoupling** (GDP up, CO2 down) between 2000 and 2022, and how many?

Each country is classified by comparing its % change in GDP and CO2:

| Category | Definition |
|---|---|
| Absolute decoupling | GDP increased and CO2 decreased |
| Relative decoupling | Both increased, but CO2 grew more slowly than GDP |
| No decoupling | Everything else |

## Dataset

- **Source:** Our World in Data, *CO2 and Greenhouse Gas Emissions*
  (https://github.com/owid/co2-data)
- **Direct download link used by the script:**
  https://raw.githubusercontent.com/owid/co2-data/master/owid-co2-data.csv
- **Size:** a single CSV of a few MB (50,411 rows, 79 columns, years 1750-2024 at the time of writing).
- **Columns used:** `country`, `iso_code`, `year`, `gdp`, `co2`.

**No manual download is needed.** The script reads the CSV directly from the URL above.

**Cleaning:** the script cleans the data automatically (nothing to do by hand):
- aggregates such as "World" or "Europe" are removed (no `iso_code`, or a code starting with `OWID_`);
- only the years 2000 and 2022 are kept;
- only countries with GDP **and** CO2 values in both years are kept (164 countries).

## Requirements

- **R** (version 4.x or newer): https://cran.r-project.org
- **R package:** `tidyverse` (uses `readr`, `dplyr`, `tidyr`, `stringr`, `ggplot2`)
- **Internet connection** (the data is downloaded when the script runs)
- Developed and tested in **Visual Studio Code** with the *R* extension (REditorSupport)
  and the `languageserver` R package.

### Installation

Open R (or the VS Code terminal, then type `R`) and run once:

```r
install.packages("tidyverse")
```

## How to run

1. Download or clone this repository and open the **project folder** in VS Code
   (File > Open Folder).
2. Make sure R's working directory is the project folder. Opening the folder in VS Code
   normally does this. You can check with `getwd()`.
3. Run the script from the terminal:

   ```bash
   Rscript Analysis.R
   ```

   Alternatively, open `Analysis.R` in VS Code and run it line by line (Ctrl+Enter, or Cmd+Enter on Mac).

The script runs in a few seconds.

## Output

The script prints to the terminal:
- the number of countries after cleaning;
- the number of countries per category and the list of absolute decouplers;
- a summary table (share, median GDP and CO2 change per category);
- the Spearman correlation between GDP growth and CO2 growth.

It also creates a `figures/` folder (created automatically) with:
- `decoupling_scatter.png`: GDP change vs CO2 change for each country;
- `top10_decoupling.png`: the 10 largest CO2 reductions among absolute decouplers.

## Main results

| Category | Countries | Share |
|---|---|---|
| Absolute decoupling | 42 | 25.6% |
| Relative decoupling | 80 | 48.8% |
| No decoupling | 42 | 25.6% |

- Spearman correlation between GDP growth and CO2 growth: **rho = 0.67**, p < 2.2e-16.
- Typical absolute decoupler (median): GDP +64%, CO2 -22%.

**Note:** Our World in Data updates this file over time (it is read from the `master` branch),
so numbers may differ slightly if the script is run later. The values above were obtained in October 2026.

## Limitations

- Only two years (2000 and 2022) are compared, so what happens in between is ignored.
- Emissions are territorial (produced inside the country); imported goods are not counted.
- Some reductions are not "success stories" (for example Ukraine, where war and economic disruption played a role).

## Repository contents

```
README.md       this file
Analysis.R      the analysis code
report.pdf      short report (2 pages, LaTeX)
figures/        plots produced by the script
```