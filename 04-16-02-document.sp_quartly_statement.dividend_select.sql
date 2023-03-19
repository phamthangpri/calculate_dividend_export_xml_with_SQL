/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       Div calculations
					
 Parameter(s):      @startdate
					@enddate
					@contract_codes : NULL = all contracts, 
									  OR 'Sample_auto' = create automatically a sample with all case types,
									  OR list of contracts with ; delimeter : '042124;045640;062522'
					@timezonename : French time zone
 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-10-11          Thi Thang Pham       Init create script.
 *************************************************************************************************************/

 
CREATE OR ALTER PROCEDURE sp_quartly_statement_div_select
			@startdate DATE = NULL, 
			@enddate DATE = NULL,
			@contract_codes VARCHAR(MAX) = NULL,
			@timezonename VARCHAR(80)
AS
BEGIN 

DECLARE	
		@t1 DATETIME,
		@t2 DATETIME
		;


IF OBJECT_ID('tempdb..##list_contract_ids') IS NOT NULL
        DROP TABLE ##list_contract_ids
		SELECT contract_id
		INTO ##list_contract_ids
		FROM rebo_contract
		WHERE (@contract_codes IS NULL OR contract_code IN (SELECT splited_data FROM meta.fn_split_string(@contract_codes, ';'))) 

-----------------------------------DIVIDENDE---------------------------------------------------------------
-- Cette table de div est la somme agregee de tous les div recu par associe, par mois, par produit 
-- on peut avoir des cas ou un client sousccrit plusieurs ordres d'un produit. Donc il va recevoir plus div.
SET @t1 = GETDATE();
IF OBJECT_ID('tempdb..##DIVIDENDES_TRANSFORMED') IS NOT NULL
    DROP TABLE ##DIVIDENDES_TRANSFORMED
BEGIN
	SELECT  d.contract_id
			,product_code
			,type_code
			,d.net_dividend																								
			,d.gross_dividend																							
			,d.payment_date
			,enjoyment_share
			,net_dividend_after_reinvestment
			,CASE WHEN d.product_code IN ('PD1','PD2','PD3') THEN 0 ELSE is_subject_to_income_tax	END							AS ir
			,CASE WHEN d.product_code IN ('PD1','PD2','PD3') THEN 0 ELSE is_tax_residence_in_france END	 						AS rf
			,CASE WHEN d.product_code IN ('PD1','PD2','PD3') THEN 0 ELSE is_exempted_of_withholding_tax END 					AS has_pf
			,d.dividend_date								
	INTO ##DIVIDENDES_TRANSFORMED																									
	FROM [dbo].[vw_dividend] d
	JOIN ##list_contract_ids lcc
	ON d.contract_id IS NOT NULL AND d.contract_id = lcc.contract_id
	WHERE d.dividend_date BETWEEN @startdate AND @enddate
	
OPTION(RECOMPILE)
END
SET @t2 = GETDATE();
PRINT('#DIVIDENDES: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')


SET @t1 = GETDATE();
IF OBJECT_ID('tempdb..##DIVIDENDES') IS NOT NULL
    DROP TABLE ##DIVIDENDES
BEGIN
	SELECT  d.contract_id
			,UPPER(d.product_code)																								AS product_code
			,type_code
			,SUM(d.net_dividend)																								AS net_dividend
			,SUM(d.gross_dividend)																								AS gross_dividend
			,MAX(DATEADD(hh, 
					DATEDIFF(hh, d.payment_date AT TIME ZONE @timezonename, d.payment_date), 
					d.payment_date))																							AS payment_date
			,SUM(enjoyment_share)																								AS shares_active
			,SUM(net_dividend_after_reinvestment)																				AS net_distributed_dividend
			,SUM(d.net_dividend - net_dividend_after_reinvestment)																AS reinvested_amount
			,SUM(d.net_dividend - net_dividend_after_reinvestment)/SUM(net_dividend)											AS reinvestment_percentage
 			,CASE d.product_code WHEN 'PD4' THEN 'PD_4' 
									WHEN 'PD5' THEN 'PD_5' 
									ELSE d.product_code
									END																							AS product_clean
			,SUM(CAST(d.gross_dividend AS NUMERIC(15,2))- CAST(d.net_dividend AS NUMERIC(15,2)))								AS witheld_taxes
			,MONTH(d.dividend_date)																								AS month_num
			,ir
			,rf
			,CASE d.has_pf WHEN 1 THEN 0 ELSE 1 END																				AS has_pf
			,d.dividend_date								
	INTO ##DIVIDENDES																									
	FROM ##DIVIDENDES_TRANSFORMED d
	GROUP BY d.contract_id,d.product_code,d.type_code,d.dividend_date,
			d.ir,d.rf,d.has_pf
OPTION(RECOMPILE)
CREATE CLUSTERED INDEX combo_id 
ON  ##DIVIDENDES (contract_id,product_code,type_code)
END
SET @t2 = GETDATE();
PRINT('#DIVIDENDES: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')

IF OBJECT_ID('tempdb..##DIV_NORMAL') IS NOT NULL
    DROP TABLE ##DIV_NORMAL
BEGIN
	SELECT *
	INTO ##DIV_NORMAL
	FROM ##DIVIDENDES
	WHERE type_code = 12345
END
-----------------------------Table DIV_SUM ------------------------------------------------
--- cette table pour calculer le total de div sur le trimestre en cours. Juste pour am�liorer la performance pour la table #DIV_ALL
--- sinon elle mets trop de temps avec subquerry
SET @t1 = GETDATE();
BEGIN
IF OBJECT_ID('tempdb..##DIV_SUM') IS NOT NULL
    DROP TABLE ##DIV_SUM 

	SELECT  contract_id
		,product_code
		,type_code									
		,SUM(CAST(ROUND(d.net_dividend,2) AS NUMERIC(10,2))) 															AS total_net_distributed
		,SUM(CAST(ROUND(d.gross_dividend,2) AS NUMERIC(10,2)) )															AS total_gross_distributed
		,SUM(CAST(ROUND(net_distributed_dividend,2) AS NUMERIC(10,2)) )													AS total_net_distributed_dividend
		,SUM(CAST(ROUND(d.net_dividend,2) AS NUMERIC(10,2))- CAST(ROUND( net_distributed_dividend,2) AS NUMERIC(10,2))) AS total_reinvested_amount
 		,MAX(dividend_date)																								AS max_dividend_date
	INTO ##DIV_SUM 
	FROM ##DIV_NORMAL d
	GROUP BY contract_id,product_code,type_code
OPTION(RECOMPILE)
END
SET @t2 = GETDATE();
PRINT('##DIV_SUM: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')

-----------------------------Table Shares active ------------------------------------------------
-----chercher le nb parts du dernier mois == nb parts en jouissance
SET @t1 = GETDATE();
BEGIN
IF OBJECT_ID('tempdb..##SHARES_ACTIVE') IS NOT NULL
    DROP TABLE ##SHARES_ACTIVE 

	SELECT  d.contract_id
		,d.product_code
		,d.type_code									
		,shares_active																	AS shares
	INTO ##SHARES_ACTIVE  
	FROM ##DIV_NORMAL d
	JOIN ##DIV_SUM ds
	ON d.contract_id = ds.contract_id AND d.product_code = ds.product_code 
		AND d.type_code = ds.type_code AND d.dividend_date = ds.max_dividend_date 

	
OPTION(RECOMPILE)
END
SET @t2 = GETDATE();
PRINT('###SHARES_ACTIVE: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')

------------------------------------ DIV_ALL -------------------------------------
---- la diff�rence de cette table par rapport � la table DIV est que cette table est la table transpos�e :
---- pour chaque contrat, chaque produit, par mois, on a une seule ligne, les donn�es de div normal et div except sont en colonnes.
---- cela permet de faciliter la cr�ation de XMLs, s'il y a 2 lignes pour le meme combo, �a va cr�er 2 lignes dans le XML
IF OBJECT_ID('tempdb..##DIV_ALL') IS NOT NULL
    DROP TABLE ##DIV_ALL 
	

	SELECT   COALESCE(d.contract_id,ext.contract_id)							AS contract_id
			,COALESCE(d.product_code,ext.product_code)							AS product_code
			,d.type_code
			,d.net_dividend
			,d.gross_dividend
			,d.payment_date
			,shares_active																						
			,reinvestment_percentage																						
			,net_distributed_dividend																			
			,reinvested_amount														
			,total_net_distributed
			,total_gross_distributed
			,total_net_distributed_dividend
			,total_reinvested_amount
 			,product_clean
			,d.witheld_taxes
			,MONTH(COALESCE(d.dividend_date,ext.dividend_date))					AS month_num
			,d.dividend_date
			,ISNULL(s.shares,0)													AS shares
			,ir
			,rf
			,has_pf
			,ext.payment_date					AS extra_payment_date
			,ext.net_dividend					AS extra_net_dividend
			,ext.gross_dividend					AS extra_gross_dividend
			,ext.witheld_taxes					AS extra_witheld_taxes
			,ext.shares							AS extra_shares
		INTO ##DIV_ALL 
		FROM ##DIV_NORMAL d
		FULL JOIN --extras
			(SELECT  contract_id
					,product_code
					,payment_date 
					,dividend_date
					,net_dividend
					,gross_dividend
					,gross_dividend - net_dividend									AS witheld_taxes
					,shares_active													AS shares
					,type_code
			FROM ##DIVIDENDES
			WHERE type_code <> 12345)	ext
			ON d.contract_id = ext.contract_id AND d.product_code = ext.product_code
			AND d.dividend_date = ext.dividend_date
			
		FULL JOIN ##DIV_SUM ds
			ON ds.contract_id = d.contract_id AND ds.product_code = d.product_code AND ds.type_code = d.type_code
		FULL JOIN ##SHARES_ACTIVE s
			ON s.contract_id = d.contract_id AND s.product_code = d.product_code AND s.type_code = d.type_code


OPTION(RECOMPILE)



END
GO