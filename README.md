# Credit Card Fraud & Transaction Pattern Analytics

A SQL + Python portfolio project analyzing what actually predicts fraud in credit card transaction data.

## Summary

This project answers three questions using real data: which transaction patterns most strongly predict fraud (timing, amount, merchant type, velocity, or geography); how a velocity and merchant-risk aware detection approach compares to a simple amount-threshold rule; and what the tradeoff looks like between catching more fraud and flagging legitimate customers.

The centerpiece is 13 SQL queries run against the full 24 million row dataset, from a basic fraud rate breakdown through recursive-style fraud ring detection and dynamic per-card percentile thresholds. This is paired with a Python notebook covering EDA, feature engineering, and a logistic regression model that improved measurably (56% to 72% recall) once features from the strongest SQL findings were added.

## Dataset

- **Name:** IBM TabFormer Credit Card Transaction Dataset
- **Source:** [Kaggle](https://www.kaggle.com/datasets/ealtman2019/credit-card-transactions), originally released by IBM
- **Size:** 24,386,900 transactions (full dataset used, not a sample)
- **License:** Kaggle listing, free for portfolio/research use

## Setup / how to run

1. Download the dataset from Kaggle and place `credit_card_transactions-ibm_v2.csv` in the `data/` folder.
2. Open `notebooks/fraud_analysis.ipynb` in Jupyter.
3. Run the cells in order. The notebook cleans the raw data, loads it into a local SQLite database (`data/fraud_analytics.db`), and runs the analysis from there.

Each query in `/sql` can also be run directly against `fraud_analytics.db` using any SQLite client.

## Key findings

- Overall fraud rate: 0.122% (29,757 of 24,386,900 transactions)
- Fraud concentrates heavily by merchant category: cruise lines, airlines, electronics, and jewelry all show elevated fraud rates well above average
- One specific merchant had a literal 100% fraud rate across 148 transactions, a strong signal of a compromised payment system
- One transaction pair showed the same card used in Italy and Tennessee at the identical minute, a clear sign of a cloned card
- The riskiest 10% of cards account for 35.5% of all fraud in the dataset; the safest 50% of cards had zero fraud transactions
- A dynamic, per-card spending threshold (flagging a transaction only if it exceeds that specific card's own 95th percentile) produced zero false positives in the top 20 flagged transactions, outperforming a flat threshold applied to every card equally
- Adding merchant risk and the per-card threshold as model features improved recall from 56% to 72% and ROC-AUC from 0.69 to 0.86

Full detail on all 14 findings is in `Fraud_Analytics_Findings.docx`. The SQL behind each finding is in the `sql/` folder.

## Repo structure

```
fraud-analytics-project/
├── sql/                              # 13 queries, each documented with what it answers and why
├── notebooks/
│   └── fraud_analysis.ipynb          # EDA, feature engineering, model training and evaluation
├── Fraud_Analytics_Findings.docx     # Full writeup of all findings
└── README.md
```

Note: the raw data file and local database (`data/`) are not included in this repo due to file size. See Setup above.

## License

This code is shared publicly for portfolio review purposes only. All rights reserved.
