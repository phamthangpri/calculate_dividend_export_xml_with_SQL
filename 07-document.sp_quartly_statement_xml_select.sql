/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       Generat XML for RT Migration
					
 Parameter(s):      @quarter
					@generation_date 
					@mode : ECO, INTIL, FR
					@year
					@contract_codes : NULL = all contracts, 
									  OR 'Sample_auto' = create automatically a sample with all case types,
									  OR list of contracts with ; delimeter : '438273;182722;921812'
					@date_doc : date to precise on the document

 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-10-11          Thi Thang Pham       Init create script.
 *************************************************************************************************************/

 
CREATE OR ALTER PROCEDURE sp_quartly_statement_XML_select
			@quarter VARCHAR(2),
			@generation_date SMALLDATETIME NULL,
			@mode VARCHAR(5),
			@year SMALLINT = NULL,
			@contract_codes VARCHAR(MAX) = NULL,
			@date_doc DATE = NULL
AS
BEGIN 



DECLARE	
			------------- for testing -----
			--@quarter VARCHAR(2),
			--@generation_date SMALLDATETIME,
			--@mode VARCHAR(5),
			--@year SMALLINT = NULL,
			--@contract_codes VARCHAR(MAX) = NULL,
			--@date_doc DATE = NULL,	
		@code_version VARCHAR(5),
		@template_version VARCHAR(10),
		@project VARCHAR(50),
		@project_name VARCHAR(5),
		@batch_type VARCHAR(20),
		@requester VARCHAR(20),
		@currency VARCHAR(5),
		@type VARCHAR(10),
		@campaign VARCHAR(20),
		@startdate DATE = NULL, 
		@enddate DATE = NULL,
		@filename VARCHAR(200),
		@authoring_date DATE = NULL,
		@t_depart DATETIME,
		@t_end DATETIME,
		@t1 DATETIME,
		@t2 DATETIME,
		@sample_auto SMALLINT,
		@timezonename VARCHAR(80)
		;
-----------------test--------------------
--SET @quarter = 'Q4' 
--SET @generation_date =  GETDATE()
--SET @year = 2022
--SET @mode = 'INTIL'
--SET @contract_codes = Null
--------------------------------

SET @t_depart = GETDATE()
SET @code_version = '1.0'
SET @template_version = 'v2021a'
SET @project = 'QuaterlyStatements'
SET @batch_type = CASE WHEN @contract_codes IS NULL THEN 'Production' ELSE 'Sample' END
SET @sample_auto = CASE WHEN @contract_codes = 'Sample_auto' THEN 1 ELSE 0 END
SET @contract_codes = CASE WHEN @contract_codes = 'Sample_auto' THEN NULL ELSE @contract_codes END
SET @project_name = 'QS'
SET @requester = 'manual'
SET @currency = 'euros'
SET @generation_date = CASE @generation_date WHEN NULL THEN GETDATE() ELSE @generation_date END
SET @year = CASE WHEN @year IS NULL THEN YEAR(@generation_date) ELSE @year END
SET @type = CASE WHEN @mode = 'ECO' THEN 'ECO' ELSE 'SCPI' END	
SET @campaign = @type + '-' + @quarter + '-' + CAST(@year AS VARCHAR(4))
SET @startdate = DATEFROMPARTS(@year,(CAST(RIGHT(@quarter,1) AS INT) * 3)-2,1) 
SET @enddate  =  EOMONTH(DATEFROMPARTS(@year,CAST(RIGHT(@quarter,1) AS INT) * 3,1)) 
SET @authoring_date = CASE WHEN @date_doc IS NULL THEN @generation_date ELSE @date_doc END
SET @filename = CASE @batch_type WHEN 'Production' THEN 'all' ELSE 'samples' END 
				+ CASE WHEN @mode <> 'ECO' THEN '.' + @mode ELSE '' END
				+ '.qs.' + CAST(@year AS VARCHAR(4)) + '.' + @quarter
				+ '.' + @mode + '.' + @batch_type + '.' + CONVERT(VARCHAR,@generation_date,20)
SET @filename = REPLACE(@filename,':','.')
SET @timezonename = 'Central European Standard Time'
;

EXEC sp_quartly_statement_signatures_create

EXEC sp_quartly_statement_div_select @startdate = @startdate, @enddate = @enddate, @contract_codes = @contract_codes, @timezonename = @timezonename

EXEC sp_quartly_statement_pei_select @startdate = @startdate, @enddate = @enddate, @timezonename = @timezonename

EXEC sp_quartly_statement_pei_div_select @startdate = @startdate, @enddate = @enddate, @timezonename = @timezonename

EXEC sp_quartly_statement_contracts_select

EXEC sp_quartly_statement_full_data_select @quarter = @quarter, @year = @year, @mode = @mode, @project_name = @project_name


---------- CREATE SAMPLE --------------------------
-----cette table permet de cr�er dynamiquement un �chantillon pour faire valider le r�sultat avec le m�tier
----- �a contient tous les cas particuliers
SET @t1 = GETDATE();
IF OBJECT_ID('tempdb..##SAMPLE_TEST') IS NOT NULL 
		DROP TABLE ##SAMPLE_TEST
CREATE TABLE ##SAMPLE_TEST (
			associateId VARCHAR(50),
			case_type VARCHAR(50)
			);
BEGIN
	IF @sample_auto = 1 BEGIN
		;WITH nb_rows_byclient AS
		 (
			SELECT associateId,
				  COUNT(*)	AS nb_rows
			FROM ##FULL_DATA
			GROUP BY associateId,product_code,doc_type_scpi
		)
		INSERT INTO ##SAMPLE_TEST (associateId,case_type)
		SELECT associateId,case_type
		FROM
			(
					  (SELECT TOP 2 associateId, 'X1' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '1' ORDER BY NEWID() )
			UNION ALL (SELECT TOP 2 associateId, 'X2' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '2' ORDER BY NEWID()) 
			UNION ALL (SELECT TOP 2 associateId, 'X3' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '3' ORDER BY NEWID()) 
			UNION ALL (SELECT TOP 2 associateId, 'X4' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '4' ORDER BY NEWID()) 
			UNION ALL (SELECT TOP 2 associateId, 'X5' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '5' ORDER BY NEWID()) 
			UNION ALL (SELECT TOP 2 associateId, 'X6' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '6' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X7' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '7' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X8' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '8' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X9' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '9' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X10' AS case_type FROM ##PRODUCT_AGG WHERE doc_type_scpi = '10' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X1' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_X1_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X3' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_X3_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X5' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_X5_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X7' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_X7_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'X9' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_X9_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'ms' AS case_type FROM ##ASSOCIATES_AGG WHERE text_form = 'ms' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'fs' AS case_type FROM ##ASSOCIATES_AGG WHERE text_form = 'FS' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'mp' AS case_type FROM ##ASSOCIATES_AGG WHERE text_form = 'MP' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'fp' AS case_type FROM ##ASSOCIATES_AGG WHERE text_form = 'FP' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'xx' AS case_type FROM ##ASSOCIATES_AGG WHERE associate_type = 'xx' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'postal_communication true' AS case_type FROM ##ASSOCIATES_AGG WHERE postal_communication = 'true' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'postal_communication false' AS case_type FROM ##ASSOCIATES_AGG WHERE postal_communication = 'false' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'postal_communication null = true' AS case_type FROM ##ASSOCIATES_AGG WHERE postal_communication IS NULL ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'pays = country1' AS case_type FROM ##ASSOCIATES_AGG WHERE country1 = 'country1' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'pays = country2' AS case_type FROM ##ASSOCIATES_AGG WHERE country1 = 'country2' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'pays = country3' AS case_type FROM ##ASSOCIATES_AGG WHERE country1 = 'country3' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'pays = country4' AS case_type FROM ##ASSOCIATES_AGG WHERE country1 = 'country4' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD1' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_scpi LIKE '%_PD1_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD2' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_scpi LIKE '%_PD2_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD3' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_scpi LIKE '%_PD3_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD1-PD3' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_scpi LIKE '%_PD1-PD3_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD1-PD2' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_scpi LIKE '%_PD1-PD2_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD3-PD2' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_scpi LIKE '%_PD3-PD2_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD1-PD3-XL' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_scpi LIKE '%_PD1-PD3-XL_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD4' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_PD4_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD5' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_PD5_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, 'PD4D' AS case_type FROM ##ASSOCIATES_AGG WHERE filename_eco LIKE '%_PD4D_%' ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, '1 ligne' AS case_type FROM nb_rows_byclient WHERE nb_rows = 1 ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, '2 lignes' AS case_type FROM nb_rows_byclient WHERE nb_rows = 2 ORDER BY NEWID())
			UNION ALL (SELECT TOP 2 associateId, '3 lignes' AS case_type FROM nb_rows_byclient WHERE nb_rows = 3 ORDER BY NEWID())
			) tt
	END
END
SET @t2 = GETDATE();
PRINT('##SAMPLE_TEST: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')	


IF OBJECT_ID('tempdb..##XML_FOR_REPORTING') IS NOT NULL 
		DROP TABLE ##XML_FOR_REPORTING
	SELECT mode
		  ,quarter
		  ,year
		  ,r.postal_communication
		  ,r.label_reporting
		  ,r.products
		  ,xml_shares_active
		  ,xml_nb_contracts
		  ,xml_gross_div
		  ,xml_net_div
		  ,xml_extra_gross_div
		  ,xml_extra_net_div
		  ,xml_total_pei
	INTO ##XML_FOR_REPORTING
	FROM (
		SELECT 
			   @mode															AS mode
			   ,@quarter														AS quarter
			   ,@year															AS year
			   ,a.postal_communication
			   ,a.label_reporting
			   ,products	
			  ,COUNT(DISTINCT a.associateId)									AS xml_nb_contracts
			  ,SUM(f.gross_dividend)											AS xml_gross_div	
			  ,SUM(f.net_dividend) 												AS xml_net_div
			  ,SUM(f.extra_gross_dividend)										AS xml_extra_gross_div
			  ,SUM(f.extra_net_dividend)										AS xml_extra_net_div
			  ,SUM(f.pei_transaction_value)										AS xml_total_pei
		
		FROM ##ASSOCIATES_AGG a
		JOIN ##FULL_DATA f
			ON f.associateId = a.associateId 
		GROUP BY a.postal_communication, products, a.label_reporting
		) r
	JOIN 
		(
		SELECT 
			  
				   postal_communication
				   ,label_reporting
				   ,products	
					,SUM(total_shares)												AS xml_shares_active
			FROM ##ASSOCIATES_AGG 
			GROUP BY postal_communication,products,label_reporting
		) a
	ON a.postal_communication = r.postal_communication AND a.products = r.products AND a.label_reporting = r.label_reporting
	

----------------------------TEST--------------------------

	SELECT * 
	FROM ##SAMPLE_TEST

-------------------------------------XML Export --------------------------------------------------------
-----Create different batches to export -------------

--IF OBJECT_ID('tempdb..##BATCH_NUMBER') IS NOT NULL 
--		DROP TABLE ##BATCH_NUMBER
--SELECT batch_number,
--	   @filename 
--	   + ' '+ CAST(batch_number AS VARCHAR(20)) 
--	   + '.' + CAST((SELECT MAX(batch_number) 
--					 FROM ##ASSOCIATES_AGG) AS VARCHAR(20))			AS filename
--INTO ##BATCH_NUMBER
--FROM ##ASSOCIATES_AGG
--GROUP BY batch_number
--ORDER BY batch_number

-----------------------------------------------------------------
--SET @t1 = GETDATE()
--BEGIN


SELECT batch_number,
		filename,
	(SELECT 
		(------company
		SELECT
			 @code_version																					AS 'xml/version'
			,@generation_date																				AS 'xml/generation_date'
			,LOWER(NEWID())																					AS 'xml/id'
			,@generation_date																				AS 'data/date'
			,'DATAHUB'																						AS 'data/source'
			,@code_version																					AS 'data/code_version'
			,@type																							AS 'template/name'
			,'??'																							AS 'template/id'
			,@template_version																				AS 'template/version'
			,@project																						AS 'output/project'
			,@campaign																						AS 'output/campaign'
			,@batch_type																					AS 'output/batch_type'
			,@project_name																					AS 'output/project_name'
			,@requester																						AS 'requester'

		FOR XML PATH(''),TYPE)																				AS [company]
	   ------organisation
	   ,@year																								AS 'organisation/parameters/year'
	   ,@currency																							AS 'organisation/parameters/currency'
	   ,@authoring_date																						AS 'organisation/parameters/authoring_date'
	   ,CASE @mode WHEN 'ECO' THEN
			(SELECT product_code																			AS [product/@code]
	            ,(SELECT
				share_value																					AS share_value
				,CONVERT(VARCHAR(10), share_value_date, 23)													AS share_value_date
				FOR XML PATH(''),TYPE)					AS product
			 FROM ##SHARE_VALUE
			 WHERE MONTH(share_value_date) = MONTH(@enddate) AND YEAR(share_value_date) = YEAR(@enddate)
			 FOR XML PATH(''),TYPE)
		 ELSE NULL END																						AS 'organisation/parameters/products/product_info'
	   ,RIGHT(@quarter,1)																					AS 'organisation/parameters/quarter'
	   ,(
		SELECT a.associateId																					AS [associate/@id]
		----- apres une node avec /@, il faut ajouter une subquerry, sinon impossible de preciser cette node dans la structure
	
		------ associate node
			,(SELECT
				( ------ c'est la vue agregee par associate, donc on va utiliser la table #ASSOCIATES_AGG
				SELECT CASE @mode WHEN 'ECO' THEN filename_eco 																				
							ELSE filename_scpi
							END																				AS 'doc/filename'
					,products																				AS 'doc/keys/products'
					,'QS'																					AS 'doc/datamatrix/line'
					,NULL																					AS 'doc/datamatrix'
					,@type																					AS 'doc/datamatrix/line'
					,NULL																					AS 'doc/datamatrix'
					,CAST(@year AS VARCHAR) + '-' + @quarter												AS 'doc/datamatrix/line'
					,NULL																					AS 'doc/datamatrix'
					,a.associateId																			AS 'doc/datamatrix/line'
					,associate_name																			AS 'contact/associate_name'
					,associate_type																			AS 'contact/associate_type'
					,text_form																				AS 'contact/text_form'
					,display_name																			AS 'contact/person/display_name'
					,civility_code																			AS 'contact/person/civility_code'
					,text_form																				AS 'contact/person/text_form'
					,subscriber_firstname																	AS 'contact/person/firstname'
					,subscriber_lastname																	AS 'contact/person/lastname'
					,CASE deceased WHEN 1 THEN 'true' ELSE 'false' END										AS 'contact/person/deceased'
					,country2																				AS 'contact/language'
					,postal_communication																	AS 'contact/postal_communication'
					,address1_line1																			AS 'contact/address/address_lines/line'
					,NULL																					AS 'contact/address/address_lines'
					,address1_line2																			AS 'contact/address/address_lines/line'
					,NULL																					AS 'contact/address/address_lines'
					,address1_line3																			AS 'contact/address/address_lines/line'
					,NULL																					AS 'contact/address/address_lines'
					,postal_address_zip_code																AS 'contact/address/postalcode'
					,postal_address_city																	AS 'contact/address/city'
					,UPPER(country)																			AS 'contact/address/country'
					,signataire_name																		AS 'contact/company_representative/name'
					,signataire_title																		AS 'contact/company_representative/title'
					,signataire_phone																		AS 'contact/company_representative/phone'
					,signataire_office																		AS 'contact/company_representative/office'
					,LOWER(activity_country)																AS 'contact/activity_country'
				FOR XML PATH(''),TYPE)																					
		
			------ products node
				,(----- ici c'est la vue agregee par associate par produit => utiliser la table #PRODUCT_AGG
				SELECT product_code																			AS [product/@code]
						------ product node
							,(SELECT 
								COALESCE(shares,'0')														AS shares
							----- flag node
						
								,CASE WHEN @mode <> 'ECO' THEN
											CASE has_transactions WHEN 1 THEN 'true' ELSE 'false' END
										ELSE NULL
										END																	AS 'flags/has_transactions'
								,CASE WHEN @mode <> 'ECO' THEN
											CASE has_div WHEN 1 THEN 'true' ELSE 'false' END
										ELSE NULL
										END																	AS 'flags/has_div'
								,CASE WHEN @mode <> 'ECO' THEN
											CASE has_pei WHEN 1 THEN 'true' ELSE 'false' END
										ELSE NULL
										END																	AS 'flags/has_pei'
								,CASE WHEN @mode <> 'ECO' THEN
											CASE has_rd WHEN 1 THEN 'true' ELSE 'false' END
										ELSE NULL
										END																	AS 'flags/has_rd'
								,CASE WHEN @mode <> 'ECO' THEN
											CASE has_extra WHEN 1 THEN 'true' ELSE 'false' END
										ELSE NULL
										END																	AS 'flags/has_extra'
																										
								----- end flag
								----- months node
								,(SELECT  month_num															AS [month/@num]
								-----maintenant c'est la vue de details
										----- dividende node
										,(SELECT 
												CONVERT(VARCHAR(10), payment_date, 23)						AS 'dividend/payment_date'
												,CASE WHEN @mode <> 'ECO' THEN CAST(shares_active AS DECIMAL(15,3))
														ELSE NULL END										AS 'dividend/shares_active'
												,CASE WHEN product_code IN ('PD1','PD2','PD3') 
												THEN net_dividend ELSE NULL END 							AS 'dividend/net_dividend'
												,CASE WHEN product_code IN ('PD1','PD2','PD3') 
												THEN gross_dividend ELSE NULL END 							AS 'dividend/gross_dividend'
												,CASE product_code WHEN 'PD5' THEN net_dividend
												ELSE NULL END												AS 'dividend/net_distributed' 
												,CASE product_code WHEN 'PD5' THEN gross_dividend
												ELSE NULL END 												AS 'dividend/gross_distributed'
												,CASE product_code WHEN 'PD4' THEN gross_capitalized_amount
												ELSE NULL END 												AS 'dividend/capitalized_per_share'
												,CASE WHEN has_rd = 1 --reinvestment_percentage>0 
													THEN ISNULL(net_distributed_dividend,0)	-- parfois il y just rd sur 1 des 3 mois
													ELSE NULL END											AS 'dividend/net_distributed_dividend'
												,CASE WHEN has_rd = 1  
													THEN ISNULL(reinvested_amount,0)		
													ELSE NULL END											AS 'dividend/reinvested_amount'
												,CASE WHEN has_rd = 1 
													THEN ISNULL(reinvestment_percentage,0)	
													ELSE NULL END											AS 'dividend/reinvestment_percentage'
												,CASE WHEN @mode <> 'ECO' THEN 
													gross_dividend - net_dividend
													ELSE NULL END											AS 'dividend/witheld_taxes'

											----- end dividende node	
												------ pei node
												,CONVERT(VARCHAR(10), pei_transaction_date, 23)				AS 'pei/transaction_date'
												,pei_created_shares											AS 'pei/created_shares'
												,pei_transaction_value										AS 'pei/transaction_value'
											-- end pei node
											FROM ##FULL_DATA fmn
											WHERE fmn.associateId = fmns.associateId 
											AND fmn.product_code = fmns.product_code
											AND fmn.month_num = fmns.month_num
											FOR XML PATH(''), TYPE
												)															AS month
							
							
								FROM ##FULL_DATA fmns
								WHERE prdag.associateId = fmns.associateId 
								AND fmns.product_code = prdag.product_code
								ORDER BY month_num
								FOR XML PATH(''),TYPE
								)																			AS months																	
								------ end months
								----- total node
								,total_net_distributed														AS 'total/net_distributed'
								,total_gross_distributed													AS 'total/gross_dividend'
								,CASE WHEN @mode <> 'ECO' THEN 
									total_gross_distributed -   total_net_distributed
									ELSE NULL END															AS 'total/witheld_taxes'
								,CASE WHEN total_net_distributed <> total_net_distributed_dividend
									THEN total_net_distributed_dividend	
									ELSE NULL END 															AS 'total/net_distributed_dividend'
								, CASE product_code WHEN 'PD4' THEN total_gross_capitalized_amount
									ELSE NULL END															AS 'total/capitalized_per_share'
								,CASE WHEN total_net_distributed <> total_net_distributed_dividend
									THEN total_reinvested_amount	
									ELSE NULL END															AS 'total/reinvested_amount'
																									
							------ end total
							------extras
								,CASE WHEN extra_net_dividend IS NOT NULL 
										THEN 'some extra dividend'
										ELSE NULL END														AS 'extras/extra/label'
								,CASE WHEN extra_net_dividend IS NOT NULL
									THEN DATEFROMPARTS(@year,month_num,28) 
									ELSE NULL END															AS 'extras/extra/display_date'
								,CONVERT(VARCHAR(10), extra_payment_date, 23)								AS 'extras/extra/payement_date'
								,extra_shares																AS 'extras/extra/shares'
								,extra_net_dividend															AS 'extras/extra/net_dividend'
								,extra_gross_dividend														AS 'extras/extra/gross_dividend'
								,CASE WHEN @mode <> 'ECO' THEN 
									extra_gross_dividend - extra_net_dividend
									ELSE NULL END															AS 'extras/extra/witheld_taxes'
								,CASE WHEN @mode <> 'ECO' THEN filename
									ELSE NULL END															AS filename
						FOR XML PATH(''),TYPE)																AS product
						
					FROM ##PRODUCT_AGG prdag
					WHERE prdag.associateId = a.associateId
					FOR XML PATH(''),TYPE)																	AS products																
				------- end products
		
			FOR XML PATH(''),TYPE)																			AS associate																					
			----- end associate
		FROM ##ASSOCIATES_AGG a
		WHERE 
			(@sample_auto = 1 AND EXISTS (SELECT 1 FROM ##SAMPLE_TEST st WHERE st.associateId = a.associateId))
			OR @sample_auto = 0 
			AND a.batch_number = b.batch_number
		FOR XML PATH('associates'),TYPE
		)																									AS [organisation/data]
	FOR XML PATH(''),TYPE, ROOT('root')
	)																					AS xml_file
	FROM ##BATCH_NUMBER b
OPTION(RECOMPILE)
END
SET @t2 = GETDATE();
PRINT('XML: ' +  CAST(DATEDIFF(millisecond,@t1,@t2) AS VARCHAR(25)) + ' elapsed_ms')	


SET @t_end = GETDATE();
PRINT('Total: ' +  CAST(DATEDIFF(millisecond,@t_depart,@t_end) AS VARCHAR(25)) + ' elapsed_ms')

END
GO
