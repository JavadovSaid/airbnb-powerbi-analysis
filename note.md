# Methodological Note & Validation: HR Attrition Analytics

## 1. Banding & Segmentation Rationale
* **Tenure Bands (`0-2`, `3-5`, `6-10`, `11+` years):** 
  * *Rationale:* Employee turnover in tech and corporate environments typically concentrates heavily during the onboarding and early career adaptation phase (first 2 years). Grouping by 0–2 years isolates high-risk new hires, while 3–5 years captures mid-tenure stabilization, and 11+ years measures institutional loyalty.
* **Income Quartiles (`NTILE(4)`):** 
  * *Rationale:* Dividing monthly income into four equal statistical segments removes subjective thresholds and allows us to test whether lower compensation tiers experience disproportionate voluntary churn.

---

## 2. SQL vs. DAX Cross-Validation Matrix
To ensure analytical integrity, macro metrics calculated in SQL were cross-validated against Power BI DAX measures across multiple segments. 

| Segment / Filter | SQL Attrition Rate (%) | DAX Attrition Rate (%) | Variance Status |
| :--- | :---: | :---: | :---: |
| **Overall Portfolio** | 16.10% | 16.10% | Exact Match ✅ |
| **OverTime = 'Yes'** | 30.50% | 30.50% | Exact Match ✅ |
| **Tenure: 0-2 Years** | 36.10% | 36.10% | Exact Match ✅ |

*Conclusion:* Filter context behavior and explicit `DIVIDE` functions in DAX match SQL aggregation results with zero discrepancy.