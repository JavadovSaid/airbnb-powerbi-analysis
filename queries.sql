-- =========================================================================
-- CAPSTONE: END-TO-END HR ATTRITION ANALYTICS
-- File: queries.sql
-- =========================================================================

-- Q1: DDL & ATTRITION FLAG CREATION
-- Business Question: Load raw employee records and create a binary target variable (1 for churned, 0 for retained) for analytical modeling.
-- Note: Adjust data types based on your SQL flavor (PostgreSQL/SQL Server/MySQL syntax shown below).

DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    Age INT,
    Attrition VARCHAR(10),
    BusinessTravel VARCHAR(50),
    DailyRate INT,
    Department VARCHAR(50),
    DistanceFromHome INT,
    Education INT,
    EducationField VARCHAR(50),
    EmployeeCount INT,
    EmployeeNumber INT PRIMARY KEY,
    EnvironmentSatisfaction INT,
    Gender VARCHAR(20),
    HourlyRate INT,
    JobInvolvement INT,
    JobLevel INT,
    JobRole VARCHAR(50),
    JobSatisfaction INT,
    MaritalStatus VARCHAR(20),
    MonthlyIncome INT,
    MonthlyRate INT,
    NumCompaniesWorked INT,
    Over18 VARCHAR(5),
    OverTime VARCHAR(5),
    PercentSalaryHike INT,
    PerformanceRating INT,
    RelationshipSatisfaction INT,
    StandardHours INT,
    StockOptionLevel INT,
    TotalWorkingYears INT,
    TrainingTimesLastYear INT,
    WorkLifeBalance INT,
    YearsAtCompany INT,
    YearsInCurrentRole INT,
    YearsSinceLastPromotion INT,
    YearsWithCurrManager INT
);

-- (After importing your CSV via COPY or Import Wizard, execute the flag column and validation)
ALTER TABLE employees ADD COLUMN attrition_flag INT;

UPDATE employees 
SET attrition_flag = CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END;


-- Q2: DATA VALIDATION
-- Business Question: Validate row integrity, primary key uniqueness, null values, and target class balance.
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT EmployeeNumber) AS unique_employees,
    SUM(CASE WHEN EmployeeNumber IS NULL THEN 1 ELSE 0 END) AS null_employee_numbers,
    SUM(attrition_flag) AS total_attritions,
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2) AS overall_attrition_rate_pct
FROM employees;


-- Q3: KPI SUMMARY BY ATTRITION STATUS
-- Business Question: What are the macro differences in headcount, income, tenure, and satisfaction between churned and retained employees?
SELECT 
    Attrition,
    COUNT(*) AS headcount,
    ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income,
    ROUND(AVG(YearsAtCompany), 2) AS avg_years_at_company,
    ROUND(AVG(JobSatisfaction), 2) AS avg_job_satisfaction
FROM employees
GROUP BY Attrition;


-- Q4: ATTRITION RATE BY DEPARTMENT
-- Business Question: Which departments face the highest turnover risk?
SELECT 
    Department,
    COUNT(*) AS headcount,
    SUM(attrition_flag) AS attritions,
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM employees
GROUP BY Department
ORDER BY attrition_rate_pct DESC;


-- Q5: ATTRITION RATE BY JOB ROLE (WITH LOW-VOLUME FILTER)
-- Business Question: Which specific job roles drive attrition, filtering out statistically insignificant sample sizes (headcount < 30)?
SELECT 
    JobRole,
    COUNT(*) AS headcount,
    SUM(attrition_flag) AS attritions,
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM employees
GROUP BY JobRole
HAVING COUNT(*) >= 30
ORDER BY attrition_rate_pct DESC;


-- Q6: ATTRITION RATE BY DEMOGRAPHIC & WORKPLACE FACTORS
-- Business Question: How do OverTime, MaritalStatus, BusinessTravel, and Gender impact attrition rates?
-- (Run as separate queries or unified reporting blocks; here grouped by OverTime as a primary example)
SELECT 
    'OverTime' AS factor_category,
    OverTime AS factor_value,
    COUNT(*) AS headcount,
    SUM(attrition_flag) AS attritions,
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM employees
GROUP BY OverTime
UNION ALL
SELECT 
    'MaritalStatus',
    MaritalStatus,
    COUNT(*),
    SUM(attrition_flag),
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2)
FROM employees
GROUP BY MaritalStatus
UNION ALL
SELECT 
    'BusinessTravel',
    BusinessTravel,
    COUNT(*),
    SUM(attrition_flag),
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2)
FROM employees
GROUP BY BusinessTravel
UNION ALL
SELECT 
    'Gender',
    Gender,
    COUNT(*),
    SUM(attrition_flag),
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2)
FROM employees
GROUP BY Gender;


-- Q7: TENURE BANDING VIA CASE WHEN
-- Business Question: How does employee tenure stage affect the risk of leaving?
SELECT 
    CASE 
        WHEN YearsAtCompany BETWEEN 0 AND 2 THEN '0-2 years'
        WHEN YearsAtCompany BETWEEN 3 AND 5 THEN '3-5 years'
        WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 years'
        ELSE '11+ years'
    END AS tenure_band,
    COUNT(*) AS headcount,
    SUM(attrition_flag) AS attritions,
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM employees
GROUP BY 
    CASE 
        WHEN YearsAtCompany BETWEEN 0 AND 2 THEN '0-2 years'
        WHEN YearsAtCompany BETWEEN 3 AND 5 THEN '3-5 years'
        WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 years'
        ELSE '11+ years'
    END
ORDER BY attrition_rate_pct DESC;


-- Q8: INCOME QUARTILES VIA NTILE
-- Business Question: Are lower-income brackets disproportionately prone to leaving?
WITH ranked_income AS (
    SELECT 
        MonthlyIncome,
        attrition_flag,
        NTILE(4) OVER (ORDER BY MonthlyIncome) as income_quartile
    FROM employees
)
SELECT 
    'Quartile ' || income_quartile AS quartile,
    MIN(MonthlyIncome) AS min_income,
    MAX(MonthlyIncome) AS max_income,
    COUNT(*) AS headcount,
    SUM(attrition_flag) AS attritions,
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM ranked_income
GROUP BY income_quartile
ORDER BY income_quartile;


-- Q9: PIVOT TABLE - DEPARTMENT x JOB SATISFACTION
-- Business Question: What is the attrition rate across departments broken down by Job Satisfaction levels (1 to 4)?
SELECT 
    Department,
    ROUND(CAST(SUM(CASE WHEN JobSatisfaction = 1 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN JobSatisfaction = 1 THEN 1 ELSE 0 END), 0) * 100, 2) AS js_1_rate,
    ROUND(CAST(SUM(CASE WHEN JobSatisfaction = 2 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN JobSatisfaction = 2 THEN 1 ELSE 0 END), 0) * 100, 2) AS js_2_rate,
    ROUND(CAST(SUM(CASE WHEN JobSatisfaction = 3 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN JobSatisfaction = 3 THEN 1 ELSE 0 END), 0) * 100, 2) AS js_3_rate,
    ROUND(CAST(SUM(CASE WHEN JobSatisfaction = 4 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN JobSatisfaction = 4 THEN 1 ELSE 0 END), 0) * 100, 2) AS js_4_rate
FROM employees
GROUP BY Department;


-- Q10: PIVOT TABLE - DEPARTMENT x WORK-LIFE BALANCE
-- Business Question: How does Work-Life Balance (1 to 4) interact with Departmental attrition?
SELECT 
    Department,
    ROUND(CAST(SUM(CASE WHEN WorkLifeBalance = 1 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN WorkLifeBalance = 1 THEN 1 ELSE 0 END), 0) * 100, 2) AS wlb_1_rate,
    ROUND(CAST(SUM(CASE WHEN WorkLifeBalance = 2 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN WorkLifeBalance = 2 THEN 1 ELSE 0 END), 0) * 100, 2) AS wlb_2_rate,
    ROUND(CAST(SUM(CASE WHEN WorkLifeBalance = 3 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN WorkLifeBalance = 3 THEN 1 ELSE 0 END), 0) * 100, 2) AS wlb_3_rate,
    ROUND(CAST(SUM(CASE WHEN WorkLifeBalance = 4 THEN attrition_flag ELSE 0 END) AS DECIMAL) / NULLIF(SUM(CASE WHEN WorkLifeBalance = 4 THEN 1 ELSE 0 END), 0) * 100, 2) AS wlb_4_rate
FROM employees
GROUP BY Department;


-- Q11: MULTI-FACTOR RISK PROFILES
-- Business Question: Which multi-factor employee segments (OverTime + Tenure Band + Income Quartile) exhibit extreme attrition risk (excluding tiny cohorts where headcount < 20)?
WITH segmented AS (
    SELECT 
        OverTime,
        CASE 
            WHEN YearsAtCompany BETWEEN 0 AND 2 THEN '0-2 years'
            WHEN YearsAtCompany BETWEEN 3 AND 5 THEN '3-5 years'
            WHEN YearsAtCompany BETWEEN 6 AND 10 THEN '6-10 years'
            ELSE '11+ years'
        END AS tenure_band,
        NTILE(4) OVER (ORDER BY MonthlyIncome) as income_quartile,
        attrition_flag
    FROM employees
)
SELECT 
    OverTime,
    tenure_band,
    'Quartile ' || income_quartile AS income_quartile,
    COUNT(*) AS headcount,
    SUM(attrition_flag) AS attritions,
    ROUND(CAST(SUM(attrition_flag) AS DECIMAL) / COUNT(*) * 100, 2) AS attrition_rate_pct
FROM segmented
GROUP BY OverTime, tenure_band, income_quartile
HAVING COUNT(*) >= 20
ORDER BY attrition_rate_pct DESC
LIMIT 3;


-- Q12: CORRELATION INPUT (MEAN BY ATTRITION STATUS)
-- Business Question: What are the directional differences in numeric attributes between retained and churned employees to assess feature importance?
SELECT 
    Attrition,
    ROUND(AVG(Age), 2) AS avg_age,
    ROUND(AVG(DistanceFromHome), 2) AS avg_distance_from_home,
    ROUND(AVG(MonthlyIncome), 2) AS avg_monthly_income,
    ROUND(AVG(NumCompaniesWorked), 2) AS avg_num_companies_worked,
    ROUND(AVG(PercentSalaryHike), 2) AS avg_percent_salary_hike,
    ROUND(AVG(TotalWorkingYears), 2) AS avg_total_working_years,
    ROUND(AVG(YearsAtCompany), 2) AS avg_years_at_company,
    ROUND(AVG(YearsInCurrentRole), 2) AS avg_years_in_current_role
FROM employees
GROUP BY Attrition;