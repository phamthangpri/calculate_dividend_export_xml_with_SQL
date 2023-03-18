/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       Retrieve contracts information
					
 Parameter(s):      

 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-10-11          Thi Thang Pham       Init create script.
 *************************************************************************************************************/

 
CREATE OR ALTER PROCEDURE sp_quartly_statement_contracts_select
AS
BEGIN 


IF OBJECT_ID('tempdb..##CONTRATS') IS NOT NULL
        DROP TABLE ##CONTRATS
	SELECT 
		 C.contract_name													AS associate_name							
		,C.contract_code													AS associateId
		,C.contract_id														AS contract_id										
		,C.type
		,C.subscriber_id
		,C.subscriber_name
		,C.cosubscriber_id
		,C.cosubscriber_name
		,total_PD4_quantity
		,S.gendercode														AS civility_code					
		,S.firstname														AS subscriber_firstname						
		,S.lastname															AS subscriber_lastname	
		,ISNULL(CASE C.type WHEN 'HP' THEN A.mso_preferredchannelcode
							   ELSE S.mso_preferredchannelcode
				END,'999999') 												AS mso_preferredchannelcode -- si c'est NULL, = digital + paper
		,CASE C.type WHEN 'HP' THEN A.mso_pndcode
							   ELSE S.mso_pndcode
				END															AS mso_pndcode
		,CASE C.type WHEN 'HP' THEN A.mso_isincorrectemail
							   ELSE S.mso_isincorrectemail
				END															AS mso_isincorrectemail
		,CASE WHEN LOWER(S.mso_isdeceased) = 'true' THEN 1 ELSE 0 END		AS deceased
		,CASE C.type WHEN 'HP' THEN S.fullname
								ELSE C.contract_name END					AS display_name
		,act_country.mso_alpha3												AS activity_country									
		,CS.gendercode														AS cosubscriber_civility_code					
		,CS.firstname														AS cosubscriber_firstname							
		,CS.lastname														AS cosubscriber_lastname
		,A.name																AS company_name
		,UPPER(CASE C.type WHEN 'HP' THEN A.address1_line1
					ELSE S.address1_line1 END)								AS address1_line1
		,UPPER(CASE C.type WHEN 'HP' THEN A.address1_line2
					ELSE S.address1_line2 END)								AS address1_line2	
		,UPPER(CASE C.type WHEN 'HP' THEN A.address1_line3
					ELSE S.address1_line3 END)								AS address1_line3
		,UPPER(CASE C.type WHEN 'HP' THEN A.address1_city
					ELSE S.address1_city END)								AS postal_address_city
		,CASE C.type WHEN 'HP' THEN A.address1_postalcode
					ELSE S.address1_postalcode END							AS postal_address_zip_code
		,CASE C.type WHEN 'HP' THEN UPPER(a_country.mso_alpha3)
					ELSE UPPER(s_country.mso_alpha3) END					AS country
		,act_country.mso_alpha3												AS country1
		,CASE act_country.mso_alpha3 WHEN 'XXX' THEN 'YYY'
				ELSE act_country.mso_alpha3 END								AS country2
		,UPPER(act_country.mso_alpha3)										AS activity_country_iso3
		,CASE C.type WHEN 'XP' THEN 'tp'
							   WHEN 'PP'  THEN 'ap'
							   WHEN 'HP'  THEN 'xx'
							   END											AS associate_type
		,CASE C.type WHEN 'PP' THEN
							CASE S.gendercode WHEN 5 THEN 'ms'
											  WHEN 10 THEN 'fs'
									END
					WHEN 'XP' THEN
							CASE WHEN S.gendercode = 5 OR CS.gendercode = 5
													THEN 'mp'
													ELSE 'fp'
									END
					WHEN 'HP' THEN 'ms'
								END											AS text_form
		,CASE WHEN ISNULL(S.mso_isnonhabitualresident, A.mso_isnonhabitualresident) = 'True' 
		THEN 1 ELSE 0 END																			AS non_usual_resident
		,signataire.name																			AS signataire_name
		,signataire.title																			AS signataire_title
		,signataire.phone																			AS signataire_phone
		,signataire.office																			AS signataire_office
	INTO ##CONTRATS
	FROM rebo_contract C
	LEFT OUTER JOIN raw_tb2.contact S 
	ON S.contactid = 
				   CASE 
				   WHEN C.type <> 'HP'  THEN C.subscriber_id
				   WHEN C.type = 'HP'  THEN C.legal_representative_id
				   END 
	LEFT OUTER JOIN raw_tb2.contact CS ON CS.contactid = C.cosubscriber_id
	LEFT OUTER JOIN raw_tb2.account A ON A.accountid = C.subscriber_id
	ON ls.contract_id = C.contract_id
	LEFT JOIN ##SIGNATAIRES signataire
	ON signataire.country = UPPER(act_country.mso_alpha2)
OPTION(RECOMPILE)
END
GO