/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       select all data before generating XML
					
 Parameter(s):      @quarter
					@year
					@mode : ECO, INTIL, FR
					@contract_codes : NULL = all contracts, 
									  OR 'Sample_auto' = create automatically a sample with all case types,
									  OR list of contracts with ; delimeter : '042124;045640;062522'
					@project_name 

 Copyright (c) 2023 CORUM
 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-10-11          Thi Thang Pham       Init create script.
 *************************************************************************************************************/
 CREATE OR ALTER PROCEDURE sp_quartly_statement_full_data_select
			@quarter VARCHAR(2),
			@year SMALLINT = NULL,
			@mode VARCHAR(5),
			@project_name VARCHAR(5)
AS
BEGIN 

DECLARE	@t1 DATETIME,
		@t2 DATETIME
		;

SET @t1 = GETDATE()
BEGIN
IF OBJECT_ID('tempdb..##FULL_DATA') IS NOT NULL  --vue details 
        DROP TABLE ##FULL_DATA
	SELECT   C.associateId	
			,C.contract_id
			,COALESCE(product_clean,P.product_code)							AS product_clean
			,country1
			,country2
			,associate_name
			,civility_code
			,display_name
			,associate_type
			,text_form
			,subscriber_firstname
			,subscriber_lastname
			,deceased
			,mso_preferredchannelcode
			--,mso_optinmailcode
			,CASE WHEN (mso_preferredchannelcode = '861810001' OR mso_preferredchannelcode = 861810001
						OR mso_isincorrectemail = 'True' 
						)  AND mso_pndcode = 0 AND postal_address_zip_code IS NOT NULL AND activity_country = 'FRA'
						THEN 'true'
					ELSE 'false' END																	AS postal_communication
			,address1_line1
			,address1_line2
			,address1_line3
			,postal_address_zip_code
			,postal_address_city
			,c.country
			,signataire_name
			,signataire_office
			,signataire_title
			,signataire_phone
			,activity_country
			,P.product_code
			,CAST(ROUND(shares,3) AS NUMERIC(10,3))												AS shares
			,has_div	
			,has_rd
			,has_pei
			,has_extra
			,ir
			,rf
			,has_pf
			,CASE WHEN has_div | has_rd | has_pei | has_extra = 0 THEN 0
				ELSE 1
				END																						AS has_transactions
			,CASE WHEN has_div = 1 AND has_rd = 0 AND has_pei = 0 AND has_extra = 0
					THEN '1'
				  WHEN has_div = 1 AND has_rd = 1 AND has_pei = 0 AND has_extra = 0
					THEN '2'
				  WHEN has_div = 0 AND has_rd = 0 AND has_pei = 1 AND has_extra = 0
					THEN '3'
				  WHEN has_div = 1 AND has_rd = 0 AND has_pei = 1 AND has_extra = 0
					THEN '4'
				  WHEN has_div = 1 AND has_rd = 1 AND has_pei = 1 AND has_extra = 0
					THEN '5'
				  WHEN has_div = 0 AND has_rd = 0 AND has_pei = 0 AND has_extra = 1
					THEN '6'
				  WHEN has_div = 1 AND has_rd = 0 AND has_pei = 0 AND has_extra = 1
					THEN '61'
				  WHEN has_div = 1 AND has_rd = 1 AND has_pei = 0 AND has_extra = 1
					THEN '62'
				  WHEN has_div = 0 AND has_rd = 0 AND has_pei = 1 AND has_extra = 1
					THEN '63'
				  WHEN has_div = 1 AND has_rd = 0 AND has_pei = 1 AND has_extra = 1
					THEN '64'
				  WHEN has_div = 1 AND has_rd = 1 AND has_pei = 1 AND has_extra = 1
					THEN '65'
				END																						AS doc_type_scpi											
			,CAST(ROUND(shares_active,3) AS DECIMAL(10,3)) 												AS shares_active
			,month_num
			,payment_date
			,type_code
			,CAST(ROUND(net_dividend,2) AS NUMERIC(10,2)) 												AS net_dividend
			,CAST( ROUND(gross_dividend,2) AS NUMERIC(10,2)) 											AS gross_dividend
			,CASE WHEN @mode <> 'ECO' THEN CAST(ROUND(witheld_taxes,2) AS NUMERIC(10,2))										
										ELSE NULL END													AS witheld_taxes
			,CASE WHEN @mode <> 'ECO' THEN CAST(ROUND(reinvestment_percentage*100,1) AS NUMERIC(10,1)) 
										ELSE NULL END													AS reinvestment_percentage
			,CASE WHEN @mode <> 'ECO' THEN CAST(ROUND(reinvested_amount,2) AS NUMERIC(10,2))
										ELSE NULL END													AS reinvested_amount
			,CASE WHEN @mode <> 'ECO' THEN CAST(ROUND(net_distributed_dividend,2) AS NUMERIC(10,2))
										ELSE NULL END													AS net_distributed_dividend
			,CAST(ROUND(total_net_distributed,2) AS NUMERIC(10,2))										AS total_net_distributed
			,CAST(ROUND(total_gross_distributed,2)	AS NUMERIC(10,2)) 									AS total_gross_distributed
			,CASE WHEN @mode <> 'ECO' THEN CAST(ROUND(total_net_distributed_dividend,2) AS NUMERIC(10,2))
										ELSE NULL END													AS total_net_distributed_dividend
			,CASE WHEN @mode <> 'ECO' THEN CAST(ROUND(total_reinvested_amount,2) AS NUMERIC(10,2))							
										ELSE NULL END													AS total_reinvested_amount
			,pei_transaction_date
			,CAST(ROUND(pei_created_shares,3) AS NUMERIC(10,3)) 								AS pei_created_shares
			,CAST(ROUND(pei_transaction_value,2) AS NUMERIC(10,2))								AS pei_transaction_value
			,extra_payment_date
			,CAST(ROUND(extra_shares,3) AS NUMERIC(10,3))										AS extra_shares
			,CAST(ROUND(extra_net_dividend,2) AS NUMERIC(10,2))									AS extra_net_dividend
			,CAST(ROUND(extra_gross_dividend,2) AS NUMERIC(10,2))								AS extra_gross_dividend
			,CAST(ROUND(extra_witheld_taxes,2) AS NUMERIC(10,2))								AS extra_witheld_taxes
			,gross_distributed_amount
			,gross_capitalized_amount
			,total_gross_capitalized_amount
	INTO ##FULL_DATA
	FROM ##CONTRATS C
	INNER JOIN ##PEI_DIV P
	ON C.contract_id = P.contract_id 
	JOIN ##AGG A
	ON C.contract_id = A.contract_id AND P.product_code = A.product_code
	WHERE CASE 
			WHEN @mode='ECO' AND P.product_code LIKE 'ECO%' THEN 1 
			WHEN @mode='FR' AND C.activity_country_iso3 = 'FRA' AND P.product_code IN ('CC','XL','EU') THEN 1
			WHEN @mode='INTIL' AND C.activity_country_iso3 <> 'FRA' THEN 1
			ELSE 0
		END = 1
	ORDER BY C.associateId,P.product_code
OPTION(RECOMPILE)
CREATE CLUSTERED INDEX CONTRACT_ID 
ON ##FULL_DATA (associateId)

END
SET @t2 = GETDATE();
PRINT('#FULL_DATA: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')


--------------- Table agrégée par associate -------------
SET @t1 = GETDATE()
BEGIN
IF OBJECT_ID('tempdb..##ASSOCIATES_AGG') IS NOT NULL --vue par associate
        DROP TABLE ##ASSOCIATES_AGG
	SELECT  
		FLOOR(((ROW_NUMBER() OVER (ORDER BY c.associateId))-1)/10000)+1								AS batch_number,
		c.associateId 
		,CASE WHEN products IN ('ECO18C-ECO18D','ECO18D-ECO18C') 
				THEN 'ECO18CD' ELSE products END													AS products
		,associate_name
		,civility_code
		,associate_type
		,text_form
		,display_name																																					
		,subscriber_firstname																			
		,subscriber_lastname 
		,deceased 					
		,CASE WHEN (mso_preferredchannelcode = '861810001' OR mso_preferredchannelcode = 861810001
						OR mso_isincorrectemail = 'True' 
						) AND mso_pndcode = 0 AND postal_address_zip_code IS NOT NULL AND activity_country = 'FRA'
						THEN 'true'
					ELSE 'false' END																	AS postal_communication
			 --861810001 = digital + paper
			 --861810000 = digital

		--,CASE WHEN (mso_preferredchannelcode = '861810001' 
		--			OR mso_optinmailcode = 1
		--			) AND postal_address_zip_code IS NOT NULL
		--			THEN 'true'
		--		ELSE 'false' END																	AS postal_communication --back up
		,total_shares
		,address1_line1
		,address1_line2
		,address1_line3
		,postal_address_zip_code															
		,postal_address_city																
		,country
		,CASE country WHEN 'FRA' THEN 'FRANCE' ELSE 'INTERNATIONAL' END								AS label_reporting
		,country1
		,country2
		,signataire_name
		,signataire_office
		,signataire_title
		,signataire_phone
		,activity_country
		,CAST(@year AS VARCHAR) + '-' + @quarter + '_'+ @project_name +'_'  
		 +country1 + '-' + country2 + '_' + products + '_'
		 + doc_type_scpi  
		 +'_' + CAST(c.associateId AS VARCHAR)																AS filename_scpi
		
		,CAST(@year AS VARCHAR) + '-' + @quarter + '_'+ @project_name +'_'  
		 +country1 + '-' + country2 + '_' 
		 + (CASE WHEN products IN ('ECO18C-ECO18D','ECO18D-ECO18C') 
				THEN 'ECO18CD' ELSE products END) + '_'
			+(CASE WHEN has_ecc = 1 AND has_ecd = 0 
					THEN 'T1'
			   WHEN has_ecc = 0 AND has_ecd = 1 AND ir = 1 
					THEN 'T3'
			   WHEN has_ecc = 0 AND has_ecd = 1 AND ir = 0
					THEN 'T5'
			   WHEN has_ecc = 1 AND has_ecd = 1 AND ir = 1
					THEN 'T7'
			   WHEN has_ecc = 1 AND has_ecd = 1 AND ir = 0
					THEN 'T9'
				END		)	
		 +'_' + CAST(c.associateId AS VARCHAR)																AS filename_eco --créer 2 champs pour ne pas embrouiller la revue
	INTO ##ASSOCIATES_AGG
	FROM ##CONTRATS c
	JOIN -------------Get text data ------------
		(SELECT associateId
			,STRING_AGG(product_code,'-') WITHIN GROUP (ORDER BY product_code)								AS products
			,STRING_AGG('T' + doc_type_scpi,'-') WITHIN GROUP (ORDER BY product_code)						AS doc_type_scpi
			,CASE WHEN STRING_AGG(product_code,'-') LIKE  '%ECO18C%' 
					THEN 1 ELSE 0 END																		AS has_ecc
			,CASE WHEN STRING_AGG(product_code,'-') LIKE  '%ECO18D%' 
					THEN 1 ELSE 0 END																		AS has_ecd
		FROM 
				(SELECT DISTINCT
						 associateId
						,product_code
						,doc_type_scpi
				FROM ##FULL_DATA
						)		AS distc
		GROUP BY associateId)						AS prd_agg
	ON prd_agg.associateId = c.associateId

	FULL JOIN ------------- get enjoyment shares/associate for the reporting -------------
		(SELECT associateId
			,SUM(shares)																					AS total_shares
		FROM 
				(SELECT 
						 associateId
						,product_code
						,shares
						,ROW_NUMBER() OVER(PARTITION BY associateId, product_code ORDER BY month_num DESC)	AS rn
				FROM ##FULL_DATA
				WHERE shares IS NOT NULL
						)		AS tt
		WHERE rn = 1
		GROUP BY associateId)						AS shares_agg

	ON shares_agg.associateId = c.associateId

	JOIN
		(SELECT  associateId
				,CASE WHEN SUM(CAST(ir AS INT))>0 THEN 1 ELSE 0 END											AS ir
				,CASE WHEN SUM(CAST(rf AS INT))>0 THEN 1 ELSE 0 END											AS rf 
				,CASE WHEN SUM(CAST(has_pf AS INT))>0 THEN 1 ELSE 0 END										AS has_pf 
		 FROM  ##FULL_DATA f
		 GROUP BY associateId
		) AS dt 
	ON dt.associateId = c.associateId
	ORDER BY c.associateId ASC
OPTION(RECOMPILE)
END

CREATE CLUSTERED INDEX CONTRACT_ID 
ON ##ASSOCIATES_AGG (associateId)

SET @t2 = GETDATE();
PRINT('##ASSOCIATES_AGG: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')	
	
-----------Table agrégée par associate, par produit ----------------
SET @t1 = GETDATE();
BEGIN
IF OBJECT_ID('tempdb..##PRODUCT_AGG') IS NOT NULL --vue par associate, par produit
        DROP TABLE ##PRODUCT_AGG
	SELECT DISTINCT
		f.associateId
		,f.postal_communication
		,f.product_code
		,f.shares
		,f.has_transactions
		,f.has_rd
		,f.has_div
		,f.has_pei
		,f.has_extra
		,f.doc_type_scpi
		,f.total_gross_distributed
		,f.total_net_distributed
		,f.total_net_distributed_dividend
		,f.total_reinvested_amount
		,f.total_gross_capitalized_amount
		,CAST(@year AS VARCHAR) + '-' + @quarter + '_QS_' + f.country1 + '-' + f.country2 + '_'+ f.product_code + '_Type'+ CAST(f.doc_type_scpi AS VARCHAR(2)) +'_' + CAST(f.associateId AS VARCHAR) AS filename
		,ext.extra_payment_date
		,ext.extra_shares
		,ext.extra_net_dividend
		,ext.extra_gross_dividend
		,ext.extra_witheld_taxes
		,ext.month_num
	INTO ##PRODUCT_AGG
	FROM ##FULL_DATA f
	FULL JOIN 
			(SELECT*
			FROM ##FULL_DATA
			WHERE extra_payment_date IS NOT NULL) ext
	ON ext.associateId = f.associateId AND ext.product_code = f.product_code
	ORDER BY f.associateId, f.product_code
OPTION(RECOMPILE)

CREATE CLUSTERED INDEX CONTRACT_ID 
ON ##PRODUCT_AGG (associateId)

END
SET @t2 = GETDATE();
PRINT('##PRODUCT_AGG: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')	

END
GO