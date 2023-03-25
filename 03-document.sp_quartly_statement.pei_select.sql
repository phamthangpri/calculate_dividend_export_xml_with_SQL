/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       PEI calculations
					
 Parameter(s):      @startdate
					@enddate
					@timezonename : French time zone

 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-10-11          Thi Thang Pham       Init create script.
 *************************************************************************************************************/

 
CREATE OR ALTER PROCEDURE sp_quartly_statement_pei_select
			@startdate DATE = NULL, 
			@enddate DATE = NULL,
			@timezonename VARCHAR(80)
AS
BEGIN 


IF OBJECT_ID('tempdb..##PEI') IS NOT NULL
        DROP TABLE ##PEI
	SELECT 	 MQ.contract_id
			,UPPER(MQ.product_code)								AS product_code
			,MAX(MQ.movement_date)								AS movement_date
			,MAX(MQ.subscription_date)							AS subscription_date
			,MQ.subscriber_id
			,MQ.subscriber_name
			,MQ.origin
			,MQ.origin_code
			,SUM(MQ.amount)										AS transaction_value
			,SUM(MQ.quantity)									AS created_shares
			,MAX(DATEADD(hh, 
					DATEDIFF(hh, S.date_prlv AT TIME ZONE @timezonename, S.date_prlv), 
					S.date_prlv))						AS transaction_date
			,CASE 
				WHEN origin_code = 34567 THEN MONTH(DATEADD(month, -1,MAX(MQ.subscription_date)))
				WHEN origin_code = 23456 THEN MONTH(MAX(MQ.subscription_date))
				END																AS month_num
	INTO ##PEI
	FROM  [dbo].[rebo_movement_detail] MQ
	-- Recuperer la date de prelevement pour les PEI
	LEFT JOIN raw_tb.tb1 L
	ON MQ.movement_id = L.mvttid
	LEFT JOIN raw_tb.tb2 S
	ON S.tb2id = L.tb2id
	JOIN ##list_contract_ids lcc
	ON MQ.contract_id = lcc.contract_id
	WHERE origin_code = 23456 AND subscription_date BETWEEN @startdate AND @enddate 
	GROUP BY MQ.contract_id, MQ.product_code, MQ.subscriber_id,MQ.subscriber_name,MQ.origin, MQ.origin_code
OPTION(RECOMPILE)
END
GO