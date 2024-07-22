/*************************************************************************************************************
 Author:            Thi Thang Pham
 Description:       Create tables
					
 Parameter(s):      

 **************************************************************************************************************
 SUMMARY OF CHANGES
 Date(yyyy-mm-dd)    Author              Comments
 ------------------- ------------------- ----------------------------------------------------------------------
 2023-10-11          Thi Thang Pham       Init create script.
 *************************************************************************************************************/

 
CREATE OR ALTER PROCEDURE sp_quartly_statement_signatures_create
AS
BEGIN

IF OBJECT_ID('tempdb..##SIGNATAIRES') IS NOT NULL
    DROP TABLE ##SIGNATAIRES
CREATE TABLE ##SIGNATAIRES (
				name VARCHAR(255), 
				title VARCHAR(255),
				phone VARCHAR(30),
				signature VARCHAR(100),
				office VARCHAR(20),
				country VARCHAR(2)
				)
INSERT INTO ##SIGNATAIRES (name, title, phone, signature, office, country) VALUES ('Person 1', 'Director',NULL,NULL, 'paris','FR');
INSERT INTO ##SIGNATAIRES (name, title, phone, signature, office, country) VALUES ('Person 2', 'Country Manager','+43 (0)1 123 456 789', 'p2.png','vienna','AT');
INSERT INTO ##SIGNATAIRES (name, title, phone, signature, office, country) VALUES ('Person 3', 'Director','+351 124 464 633','p3.png', 'lisbon','NL');
INSERT INTO ##SIGNATAIRES (name, title, phone, signature, office, country) VALUES ('Person 4', 'Country Manager','+351 333 544 333','p4.png', 'lisbon','PT');

------------------------------- A SUPPRIMER -----------------------------------
IF OBJECT_ID('tempdb..##DATA_PRODUCT1') IS NOT NULL
    DROP TABLE ##DATA_PRODUCT1
CREATE TABLE ##DATA_PRODUCT1 (
				product_code VARCHAR(10),
				gross_capitalized_amount NUMERIC(15,2),
				net_capitalized_amount NUMERIC(15,2),
				gross_distributed_amount NUMERIC(15,2),
				net_distributed_amount NUMERIC(15,2),
				payment_date SMALLDATETIME
				)
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2022-10-25');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2022-11-22');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2022-12-26');

INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.25,0.23,0.33,0.23,'2023-01-25');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-02-22');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-03-26');

INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-04-25');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-05-22');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-06-26');

INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-07-25');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-08-22');
INSERT INTO ##DATA_PRODUCT1 (product_code, gross_capitalized_amount, net_capitalized_amount, gross_distributed_amount,net_distributed_amount,payment_date) VALUES ('PRODUCT1',0.33,0.23,0.33,0.23,'2023-09-26');


IF OBJECT_ID('tempdb..##SHARE_VALUE') IS NOT NULL
    DROP TABLE ##SHARE_VALUE
CREATE TABLE ##SHARE_VALUE (
				product_code VARCHAR(10),
				share_value NUMERIC(15,2),
				share_value_date SMALLDATETIME
				)
INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT1',107.93,'2022-12-31');
INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT2',94.6,'2022-12-31');

INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT1',107.93,'2023-03-31');
INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT2',94.6,'2023-03-31');

INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT1',110.28,'2023-06-30');
INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT2',95.65,'2023-06-30');

INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT1',110.28,'2023-09-30');
INSERT INTO ##SHARE_VALUE (product_code, share_value, share_value_date) VALUES ('PRODUCT2',95.65,'2023-09-30');

END
GO


