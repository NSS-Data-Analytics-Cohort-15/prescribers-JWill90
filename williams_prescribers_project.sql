SELECT *
FROM prescriber;

SELECT *
FROM drug;

SELECT *
FROM cbsa;

SELECT *
FROM prescription;


SELECT *
FROM public.fips_county;


SELECT *
FROM public.overdose_deaths;


SELECT *
FROM public.zip_fips;


SELECT *
FROM public.population;

-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT 
	prescriber.nppes_provider_last_org_name AS last_name,
	prescriber.nppes_provider_first_name AS first_name,
	prescriber.npi,
	COUNT(prescription.total_claim_count) AS highest_claim_total 
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi, prescriber.nppes_provider_last_org_name, prescriber.nppes_provider_first_name
ORDER BY highest_claim_total DESC
LIMIT 1;

Answer: Michael Cox. NPI 1356305197/Claims 379

--1. b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT 
	prescriber.nppes_provider_last_org_name AS last_name,
	prescriber.nppes_provider_first_name AS first_name,
	prescriber.specialty_description,
	SUM(prescription.total_claim_count) AS highest_claim_total -- Using SUM in this case, as each record could contain value greater than 1 (i.e No. of Claims, refills, etc.).
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY prescriber.nppes_provider_last_org_name, prescriber.nppes_provider_first_name, prescriber.specialty_description
ORDER BY highest_claim_total DESC
LIMIT 1;

Answer: Bruce Pendley. Family Practice. Claim Total 99707


-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT DISTINCT prescriber.specialty_description, SUM(prescription.total_claim_count) AS highest_claim_total 
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY prescriber.specialty_description
ORDER BY 2  DESC
LIMIT 1;


Answer: Family Practice - 9752347



-- 2. b. Which specialty had the most total number of claims for opioids?

SELECT DISTINCT prescriber.specialty_description, SUM(prescription.total_claim_count) AS highest_claim_total, drug.opioid_drug_flag
FROM prescriber
INNER JOIN prescription
ON prescriber.npi = prescription.npi
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description, drug.opioid_drug_flag
ORDER BY 2 DESC
LIMIT 1;

Answer: Nurse Practitioner, 900845

-- 3. a. Which drug (generic_name) had the highest total drug cost?

SELECT drug.generic_name, SUM(prescription.total_drug_cost) AS total_cost 
FROM drug
INNER JOIN prescription
USING(drug_name) -- joining the two tables using the drug_name column
GROUP BY drug.generic_name
ORDER BY total_cost DESC
LIMIT 1;

Answer: INSULIN GLARGINE,HUM.REC.ANLOG. Total_Cost: 104264066.35


-- 3. b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT drug.generic_name, ROUND(SUM(prescription.total_drug_cost) / SUM(prescription.total_day_supply), 2) AS cost_per_day -- sums all the drug costs, divides it by the sum of all the days supplied for that same generic name. This gives you the average cost per day across all prescriptions for that generic drug.
FROM drug
INNER JOIN prescription
USING(drug_name) -- joining the two tables using the drug_name column
GROUP BY drug.generic_name
ORDER BY cost_per_day DESC
LIMIT 1;

Answer: C1 ESTERASE INHIBITOR. Cost_Per_Day: 3495.22 


-- 4.   a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 


SELECT drug.drug_name,
	CASE 
		WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN drug.antibiotic_drug_flag = 'Y'THEN 'antibiotic'
		ELSE 'neither' END drug_type
FROM drug
ORDER BY 1;


-- 4  b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT drug.drug_name, SUM(prescription.total_drug_cost) AS total_cost 
	CASE 
		WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' 
		AND prescription.total_drug_cost 
		WHEN drug.antibiotic_drug_flag = 'Y'THEN 'antibiotic'
		WHEN prescription.total_drug_cost 
		WHEN 
		ELSE 'neither' END drug_type
FROM drug
ORDER BY 1;


SELECT
    CASE
        WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,  
    SUM(prescription.total_drug_cost)::MONEY AS total_spent -- Postgres specific cast to the money data type
FROM
    drug 
INNER JOIN prescription 
Using(drug_name)
WHERE drug.opioid_drug_flag = 'Y' OR drug.antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY total_spent DESC;

Answer: opioid - $105,080,626.37
		antibiotic - $38,435,121.26

-- 5.  a. How many CBSAs are in Tennessee? 


SELECT COUNT(DISTINCT cbsa.cbsa) AS number_of_cbsas_in_tn
FROM cbsa
WHERE cbsa.cbsaname LIKE '%, TN'; 

Answer: 6 
 

-- 5.  b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
INNER JOIN population
ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsa.cbsa, cbsa.cbsaname -- This is grouping by both the cbsa number and name to ensure correct grouping for the name
ORDER BY total_population DESC
LIMIT 1;

Answer: Largest: Nashville-Davidson--Murfreesboro--Franklin, TN.  Total_Population: 1830410
		Smallest: Morristown, TN. Total_Population: 116352

		
-- 5.  c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT fips_county.county AS county_name, SUM(population.population) AS total_population
FROM population
INNER JOIN fips_county 
ON population.fipscounty = fips_county.fipscounty
LEFT JOIN cbsa 
ON population.fipscounty = cbsa.fipscounty
WHERE cbsa.fipscounty IS NULL
GROUP BY fips_county.county
ORDER BY total_population DESC
LIMIT 1;

Answer: SEVIER. Population: 95523

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT prescription.drug_name, prescription.total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- 6. b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag AS is_opioid_drug
FROM prescription
INNER JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000;
	

-- 6. c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag AS is_opioid_drug, prescriber.nppes_provider_last_org_name AS last_name,
	prescriber.nppes_provider_first_name AS first_name
FROM prescription
INNER JOIN drug
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000;

-- 7 a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


SELECT prescriber.npi, drug.drug_name     
FROM prescriber   
CROSS JOIN
    drug -- Creating every possible pair between a prescriber record and a drug record         
WHERE prescriber.specialty_description = 'Pain Management' 
    AND prescriber.nppes_provider_city = 'NASHVILLE'     
    AND drug.opioid_drug_flag = 'Y';               

-- 7 b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi, drug.drug_name, SUM(prescription.total_claim_count) AS number_of_claims 
FROM prescriber                                 
UNION ALL drug -- Combining every prescriber with every drug
LEFT JOIN prescription
ON prescriber.npi = prescription.npi AND drug.drug_name = prescription.drug_name -- LEFT JOIN to get claims for the combinations                                             
GROUP BY prescriber.npi, drug.drug_name                                     
ORDER BY prescriber.npi, drug.drug_name;
    
-- 7 c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT prescriber.npi, drug.drug_name, COALESCE(SUM(prescription.total_claim_count), 0) AS number_of_claims -- Sum claims, replace NULLs with 0
FROM prescriber                                 
CROSS JOIN drug -- Combining every prescriber with every drug
LEFT JOIN prescription
ON prescriber.npi = prescription.npi AND drug.drug_name = prescription.drug_name -- LEFT JOIN to get claims for the combinations                                             
GROUP BY prescriber.npi, drug.drug_name                                     
ORDER BY prescriber.npi, drug.drug_name;


Bonus Questions: 

-- 2. c. Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?


SELECT DISTINCT prescriber.specialty_description
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE prescription IS NULL;


-- 2. d. For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH ClaimsBySpecialty AS (
    SELECT
        prescriber.specialty_description,
        SUM(prescription.total_claim_count) AS total_claims_for_specialty,
        SUM(CASE
                WHEN drug.opioid_drug_flag = 'Y' THEN prescription.total_claim_count
                ELSE 0
            END) AS total_opioid_claims_for_specialty
    FROM prescriber
    JOIN prescription
        ON prescriber.npi = prescription.npi
    JOIN drug
        ON prescription.drug_name = drug.drug_name
    GROUP BY prescriber.specialty_description
)
SELECT
    cbs.specialty_description,
    cbs.total_claims_for_specialty,
    cbs.total_opioid_claims_for_specialty,
    -- This calculates the percentage, handling division by zero and rounding
    CASE
        WHEN cbs.total_claims_for_specialty > 0 THEN
            ROUND(
                (CAST(cbs.total_opioid_claims_for_specialty AS NUMERIC) * 100.0) / cbs.total_claims_for_specialty,
                2 -- Round to 2 decimal places
            )
        ELSE
            0.0
    END AS percentage_opioid_claims
FROM ClaimsBySpecialty AS cbs
ORDER BY percentage_opioid_claims DESC, cbs.specialty_description
LIMIT 1;

Answer: Speciality - Case Manager/Care Coordinator
		Total Claims for Speciality - 50
		Total Opioid Claims - 36 
		Percentage_Opioid_Claims - 72.00











