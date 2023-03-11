/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       PEI and DIV
					
 Parameter(s):      @startdate
					@enddate 
					@timezonename : Paris time zone

 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-10-11          Thi Thang Pham       Init create script.
 *************************************************************************************************************/

 
CREATE OR ALTER PROCEDURE sp_quartly_statement_pei_div_select
			@startdate DATE = NULL, 
			@enddate DATE = NULL,
			@timezonename VARCHAR(80)
AS
BEGIN 

IF OBJECT_ID('tempdb..##DIV_PD4') IS NOT NULL
        DROP TABLE ##DIV_PD4
	SELECT contract_id, 
		   total_PD4_quantity				AS shares,
		   d.*
	INTO ##DIV_PD4
	FROM rebo_contract c,
		(SELECT *
				,MONTH(payment_date)			AS month_num
		FROM ##DATA_PD4 
		WHERE payment_date BETWEEN @startdate AND @enddate
		) d
	WHERE c.total_PD4_quantity > 0
	AND c.contract_id IN 
					(SELECT * FROM ##list_contract_ids)
	ORDER BY c.contract_id, month_num

IF OBJECT_ID('tempdb..##PEI_DIV') IS NOT NULL
        DROP TABLE ##PEI_DIV
	SELECT 	 COALESCE(d.contract_id,p.contract_id,c.contract_id)		AS contract_id
			,COALESCE(d.product_code,p.product_code,c.product_code)	AS product_code
			,COALESCE(d.month_num,p.month_num,c.month_num)			AS month_num
			,d.type_code								AS type_code
			,d.net_dividend
			,d.gross_dividend
			,COALESCE(d.payment_date,c.payment_date) AS payment_date
			,d.shares_active
			,d.reinvestment_percentage
			,d.net_distributed_dividend
			,d.reinvested_amount
			,d.total_net_distributed
			,d.total_gross_distributed
			,d.total_net_distributed_dividend
			,d.total_reinvested_amount
 			,d.product_clean
			,d.witheld_taxes
			,d.dividend_date
			,COALESCE(d.shares,c.shares)				AS shares
			,d.extra_gross_dividend
			,d.extra_net_dividend
			,d.extra_payment_date
			,d.extra_shares
			,d.extra_witheld_taxes
			,ir
			,rf
			,has_pf
			,origin_code						AS pei_origin_code
			,transaction_value					AS pei_transaction_value
			,created_shares						AS pei_created_shares
			,transaction_date					AS pei_transaction_date
			,gross_capitalized_amount
			,gross_distributed_amount
			,total_gross_capitalized_amount
	INTO ##PEI_DIV
	FROM ##PEI p
	FULL JOIN ##DIV_ALL d
	ON p.contract_id = d.contract_id 
		AND p.month_num = d.month_num
		AND p.product_code = d.product_code
	FULL JOIN ##DIV_PD4 c
	ON c.contract_id = ISNULL(d.contract_id,p.contract_id)
		AND c.month_num = ISNULL(d.month_num,p.month_num)
		AND c.product_code = ISNULL(d.product_code,p.product_code)
	FULL JOIN 
		(SELECT contract_id, product_code, SUM(gross_capitalized_amount) AS total_gross_capitalized_amount
		FROM ##DIV_PD4
		GROUP BY contract_id, product_code
		) s
	ON c.contract_id = s.contract_id AND c.product_code = s.product_code
OPTION(RECOMPILE)	

IF OBJECT_ID('tempdb..##AGG') IS NOT NULL 
        DROP TABLE ##AGG	
	SELECT	 contract_id
			,product_code
		    ,CASE WHEN SUM(COALESCE(gross_dividend,0)) > 0 THEN 1 ELSE 0 END					AS has_div
			,CASE WHEN SUM(COALESCE(extra_gross_dividend,0)) > 0 	THEN 1 ELSE 0 END			AS has_extra
			,CASE WHEN SUM(COALESCE(pei_transaction_value,0)) > 0	THEN 1 ELSE 0 END			AS has_pei
			,CASE WHEN SUM(COALESCE(reinvested_amount,0)) > 0	THEN 1 ELSE 0 END				AS has_rd
	INTO ##AGG	
	FROM ##PEI_DIV
	GROUP BY  contract_id,product_code
OPTION(RECOMPILE)

END
GO