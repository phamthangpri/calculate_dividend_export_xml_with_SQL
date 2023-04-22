/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       Calculate the data from raw data in Datahub and then compare the result with xml files
					
 Parameter(s):      @quarter
					@year

 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-11-21          Thi Thang Pham       Init create script.
 *************************************************************************************************************/
CREATE OR ALTER PROCEDURE sp_quartly_statement_reporting_select
			@quarter VARCHAR(2),
			@year SMALLINT = NULL
AS
BEGIN 
DECLARE @startdate DATE = NULL, 
		@enddate DATE = NULL

SET @startdate = DATEFROMPARTS(@year,(CAST(RIGHT(@quarter,1) AS INT) * 3)-2,1) 
SET @enddate  =  EOMONTH(DATEFROMPARTS(@year,CAST(RIGHT(@quarter,1) AS INT) * 3,1)) 


------------- Step 1 : get raw dividend ----------------------------
IF OBJECT_ID('tempdb..##RAW_DIV') IS NOT NULL 
		DROP TABLE ##RAW_DIV
SELECT d.contract_id
	,SUM(d.gross_dividend)												AS gross_dividend
	,SUM(d.net_dividend)												AS net_dividend
	,SUM(d.enjoyment_share)												AS enjoyment_share
	,d.dividend_date
	,d.product_code
	,C.contract_code
	,CASE type_code WHEN 181500000 THEN 'normal' ELSE 'extra' END								AS type_div
	,CASE WHEN product_code IN ('PD2','PD1','PD3') AND act_country.mso_alpha3 = 'FRA' THEN 'FR'
	 WHEN product_code IN ('PD2','PD1','PD3') AND act_country.mso_alpha3 <> 'FRA' THEN 'INTIL'
	 WHEN product_code LIKE '%ECO%' AND act_country.mso_alpha3 = 'FRA' THEN 'ECO'
	 ELSE 'check_country'
	 END																						AS type_fichier
INTO ##RAW_DIV
FROM vw_dividend d
	JOIN rebo_contract C
	ON d.contract_id = C.contract_id
	LEFT OUTER JOIN raw_crm.contact S 
	ON S.contactid = 
				   CASE 
				   WHEN C.type <> 'HP'  THEN C.subscriber_id
				   WHEN C.type = 'HP'  THEN C.legal_representative_id
				   END 
	LEFT OUTER JOIN raw_crm.contact CS ON CS.contactid = C.cosubscriber_id
	LEFT OUTER JOIN raw_crm.account A ON A.accountid = C.subscriber_id
	LEFT JOIN raw_crm.systemuser SY ON SY.systemuserId = ISNULL(S.ownerid, A.ownerid)
	LEFT JOIN raw_crm.team T ON T.teamId = ISNULL(S.ownerid, A.ownerid)
	LEFT JOIN raw_crm.mso_country act_country ON act_country.mso_countryId = ISNULL(SY.mso_activitycountryid, T.mso_activitycountryid)
	
WHERE d.dividend_date BETWEEN @startdate AND @enddate
AND d.product_code in ('PD2','PD1','PD3','PD4','PD5')
GROUP BY d.contract_id, d.product_code, d.dividend_date, type_code,act_country.mso_alpha3, C.contract_code
		-- ,C.rebo_activity_country_iso3
		 

------------- Step 2 : get raw pei ----------------------------
IF OBJECT_ID('tempdb..##RAW_PEI') IS NOT NULL 
		DROP TABLE ##RAW_PEI
SELECT m.*
	,act_country.mso_alpha3																		AS act_country
	,CASE WHEN m.product_code IN ('PD2','PD1','PD3') 
		AND act_country.mso_alpha3 = 'FRA' THEN 'FR'
	 WHEN m.product_code IN ('PD2','PD1','PD3') 
		AND act_country.mso_alpha3 <> 'FRA' THEN 'INTIL'
	 WHEN m.product_code LIKE '%ECO%' 
		AND act_country.mso_alpha3 = 'FRA' THEN 'ECO'
	 ELSE 'check_country'
	 END																						AS type_fichier
INTO ##RAW_PEI
FROM [dbo].[rebo_movement_detail] m
JOIN rebo_contract C
	ON m.contract_id = C.contract_id
	LEFT OUTER JOIN raw_crm.contact S 
	ON S.contactid = 
				   CASE 
				   WHEN C.type <> 'HP'  THEN C.subscriber_id
				   WHEN C.type = 'HP'  THEN C.legal_representative_id
				   END 
	LEFT OUTER JOIN raw_crm.contact CS ON CS.contactid = C.cosubscriber_id
	LEFT OUTER JOIN raw_crm.account A ON A.accountid = C.subscriber_id
	LEFT JOIN raw_crm.systemuser SY ON SY.systemuserId = ISNULL(S.ownerid, A.ownerid)
	LEFT JOIN raw_crm.team T ON T.teamId = ISNULL(S.ownerid, A.ownerid)
	LEFT JOIN raw_crm.mso_country act_country ON act_country.mso_countryId = ISNULL(SY.mso_activitycountryid, T.mso_activitycountryid)
WHERE origin_code = '181500001'
AND subscription_date BETWEEN @startdate AND @enddate
AND m.product_code in ('PD2','PD1','PD3','PD4','PD5')


------------- Step 3 : calculate the number of contracts during the period ----------------------------
IF OBJECT_ID('tempdb..##RAW_NB_CONTRACTS') IS NOT NULL 
		DROP TABLE ##RAW_NB_CONTRACTS
	SELECT d.type_fichier										AS type_fichier, 
			COUNT(DISTINCT d.contract_code)						AS nb_contracts
	INTO ##RAW_NB_CONTRACTS
	FROM ##RAW_DIV d
	GROUP BY d.type_fichier
	UNION
		(SELECT p.type_fichier									AS type_fichier, 
				COUNT(DISTINCT p.contract_code)					AS nb_contracts
		FROM ##RAW_PEI p
		WHERE p.contract_code NOT IN 
			(SELECT contract_code 
			FROM ##RAW_DIV)
		GROUP BY p.type_fichier)
	UNION 
		(SELECT 'ECO'											AS type_fichier,
				COUNT(DISTINCT contract_code)					AS  nb_contracts
		FROM rebo_contract
		WHERE total_PD4_quantity>0
		AND contract_code NOT IN
			(SELECT contract_code 
			FROM ##RAW_DIV
			WHERE product_code = 'PD5'))

--------------------------Step 4 : Get all data in datahub --------------------------------------------

IF OBJECT_ID('tempdb..##DATAHUB') IS NOT NULL 
		DROP TABLE ##DATAHUB
SELECT d.type_fichier										AS mode
	  ,@quarter												AS quarter
	  ,@year												AS year
	  ,s.raw_enjoyment_share
	  ,c.raw_nb_contracts
	  ,d.raw_gross_dividend
	  ,d.raw_net_dividend
	  ,e.raw_extra_gross_dividend
	  ,e.raw_extra_net_dividend
	  ,p.raw_pei
INTO ##DATAHUB
FROM ---- div_normal
	(SELECT 
			type_fichier
			,SUM(CAST(ROUND(gross_dividend,2) AS NUMERIC(15,2)))		AS raw_gross_dividend
			,SUM(CAST(ROUND(net_dividend,2) AS NUMERIC(15,2)))			AS raw_net_dividend
	FROM ##RAW_DIV
	where type_div = 'normal'
	GROUP BY type_fichier) d
FULL JOIN 
	--- extra div
	(SELECT 
			type_fichier
			,SUM(CAST(ROUND(gross_dividend,2) AS NUMERIC(15,2)))		AS raw_extra_gross_dividend
			,SUM(CAST(ROUND(net_dividend,2) AS NUMERIC(15,2)))			AS raw_extra_net_dividend
	FROM ##RAW_DIV
	where type_div = 'extra'
	GROUP BY type_fichier) e
ON d.type_fichier = e.type_fichier

	------ PEI
FULL JOIN 
	(SELECT type_fichier
			,SUM(CAST(ROUND(amount,2) AS NUMERIC(15,2)))									AS raw_pei
	FROM ##RAW_PEI
	GROUP BY type_fichier) p
ON d.type_fichier = p.type_fichier

FULL JOIN	
	------- NB contracts
	(SELECT type_fichier,
		    SUM(nb_contracts)																AS raw_nb_contracts
	FROM ##RAW_NB_CONTRACTS
	GROUP BY type_fichier) c
ON d.type_fichier = c.type_fichier

FULL JOIN 
	-------- enjoyment share
	(SELECT other.type_fichier,
		    other.raw_enjoyment_share 
		      +  ISNULL(ecoc.total_PD4_quantity,0)									AS raw_enjoyment_share

	FROM (-- shares for PD1, PD2, PD3, PD5
		SELECT t.type_fichier
				,SUM(CAST(ROUND(enjoyment_share,3) AS NUMERIC(15,3)))  					AS raw_enjoyment_share
			 FROM (
				  SELECT  type_fichier
						 ,contract_id
						 ,type_div
						 ,enjoyment_share
						 ,ROW_NUMBER() OVER(PARTITION BY contract_id,product_code ORDER BY dividend_date DESC,type_div DESC)	AS rn
				  FROM ##RAW_DIV
				  ) AS t
			 WHERE rn = 1 AND type_div = 'normal'
			 GROUP BY t.type_fichier ) other
	FULL JOIN (-- shares for PD4
			SELECT 'ECO'								AS type_fichier,
			SUM( CAST(ROUND(total_PD4_quantity,3) AS NUMERIC(15,3)))					AS total_PD4_quantity
			FROM rebo_contract
			where total_PD4_quantity>0) ecoc
	ON other.type_fichier = ecoc.type_fichier 
	) s
ON s.type_fichier = d.type_fichier


--------------- Step 5 : compare with the data from xml files --------------
IF OBJECT_ID('tempdb..##REPORTING') IS NOT NULL 
		DROP TABLE ##REPORTING
SELECT COALESCE(x.mode,d.mode)  AS mode,
	   COALESCE(x.quarter,d.quarter) AS quarter,
	   COALESCE(x.year,d.year) AS year,
	   raw_enjoyment_share,
	   raw_nb_contracts,
	   raw_gross_dividend,
	   raw_net_dividend,
	   raw_extra_gross_dividend,
	   raw_extra_net_dividend,
	   raw_pei,
	   xml_shares_active,
	   xml_nb_contracts,
	   xml_gross_div,
	   xml_net_div,
	   xml_extra_gross_div,
	   xml_extra_net_div,
	   xml_total_pei,
	   raw_nb_contracts - xml_nb_contracts				AS check_nb_contracts,
	   raw_enjoyment_share - xml_shares_active			AS check_enjoyment_share,
	   raw_gross_dividend - xml_gross_div				AS check_gross_div,
	   raw_net_dividend - xml_net_div					AS check_net_div,
	   raw_extra_gross_dividend - xml_extra_gross_div   AS check_extra_gross_div,
	   raw_extra_net_dividend - xml_extra_net_div		AS check_extra_net_div,
	   raw_pei - xml_total_pei							AS check_total_pei
INTO ##REPORTING
FROM 
	(SELECT mode															AS mode
		   ,@quarter														AS quarter
		   ,@year															AS year
		  ,SUM(xml_shares_active)											AS xml_shares_active	
		  ,SUM(xml_nb_contracts)											AS xml_nb_contracts
		  ,SUM(xml_gross_div)												AS xml_gross_div	
		  ,SUM(xml_net_div) 												AS xml_net_div
		  ,SUM(xml_extra_gross_div)											AS xml_extra_gross_div
		  ,SUM(xml_extra_net_div)											AS xml_extra_net_div
		  ,SUM(xml_total_pei)											AS xml_total_pei
	 FROM ##XML 
	 GROUP BY mode
	)x
FULL JOIN ##DATAHUB d
ON x.mode = d.mode AND x.quarter = d.quarter AND x.year = d.year

IF OBJECT_ID('tempdb..##DATA_ISSUE') IS NOT NULL 
		DROP TABLE ##DATA_ISSUE
SELECT *
INTO ##DATA_ISSUE
FROM (
		SELECT	 associateId
				,COUNT(DISTINCT ir) AS nb_ir 
				,COUNT(DISTINCT rf) AS nb_rf 
				,COUNT(DISTINCT has_pf) AS nb_has_pf
		FROM ##full_data
		GROUP BY associateId ) t
WHERE nb_ir <> 1 or nb_rf <> 1 or nb_has_pf <> 1
ORDER BY nb_ir DESC, nb_rf DESC, nb_has_pf DESC
END
GO



