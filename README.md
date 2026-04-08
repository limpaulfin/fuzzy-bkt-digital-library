# Fuzzy-BKT: Wissensverfolgung in digitalen Bibliotheken

Implementierung eines Fuzzy Bayesian Knowledge Tracing (Fuzzy-BKT) Modells zur Bewertung der Informationskompetenz von Studierenden in intelligenten digitalen Bibliothekssystemen. Das Modell erweitert das klassische BKT um unscharfe Dreiecks-Zugehoerigkeitsfunktionen (TFN) und erkennt Cognitive Offloading durch Analyse der Antwortzeiten.

## Systemvoraussetzungen

- Betriebssystem: Linux (Ubuntu 22.04+)
- R >= 4.4.1
- R-Pakete: jsonlite, ggplot2

## Installation

```bash
# R-Pakete installieren
Rscript -e "install.packages(c('jsonlite', 'ggplot2'), repos='https://cloud.r-project.org')"
```

## Ausfuehrung

```bash
# ASSISTments-Datensatz herunterladen (80 MB)
cd src && Rscript -e "
library(jsonlite)
url <- 'https://raw.githubusercontent.com/CAHLR/pyBKT-examples/master/data/as.csv'
download.file(url, '../data/as.csv')
"

# Pipeline starten
chmod +x src/init.sh
./src/init.sh
```

Ergebnisse befinden sich in `src/output/`.

## Datensatz

| Datensatz | Quelle | Format | Groesse |
|-----------|--------|--------|---------|
| ASSISTments 2009-2010 | [ASSISTments](https://sites.google.com/site/assistmentsdata/) | CSV | 525.534 Zeilen |
| CognitiveTutor | [pyBKT](https://github.com/CAHLR/pyBKT) | CSV | 16.857 Zeilen |

## Zitation

```bibtex
@inproceedings{tran2026fuzzy,
  title={Fuzzy-BKT: Bewertung der Informationskompetenz in digitalen Bibliotheken},
  author={Tran, Thi Huynh Nhi and Lam, Thanh Phong and Nguyen, Ngoc My Quyen},
  booktitle={HUB 2026: Digitale Bibliotheken und KI},
  year={2026}
}
```

## Lizenz

MIT
