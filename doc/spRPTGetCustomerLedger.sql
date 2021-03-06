USE [StoNino]
GO
/****** Object:  StoredProcedure [dbo].[spRPTGetCustomerLedger]    Script Date: 07/11/2022 1:55:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
	author:				
	date created:		
	purpose:			
	updates:			t1t1an0|09.24.13|https://app.asana.com/0/6391408470475/7828045635761
			1. 2017-06-09 Add DISTINCT in final Select kay nag double ang mga data.	
*/

ALTER PROC [dbo].[spRPTGetCustomerLedger]
	@strAccountCode VARCHAR(50), @intIDMasLocation INT
AS

--for debugging|start
	--USE StoNino

	--DECLARE @strAccountCode VARCHAR(50), @intIDMasLocation INT
	----select * from tblMasLocation
	--SET @strAccountCode='BSG-3521' SET @intIDMasLocation=11
--for debugging|end

DECLARE @strAccountCode_Local VARCHAR(50), @intIDMasLocation_Local INT
SET @strAccountCode_Local = @strAccountCode
SET @intIDMasLocation_Local = @intIDMasLocation

DECLARE @tblCustLedger TABLE (ID INT, strBranchName VARCHAR(500), strAccountCode VARCHAR(50), datAccountDate DATETIME,  
								datFirstDueDate DATETIME, strSINumber VARCHAR(50), strSalesTypeDescription VARCHAR(500),
								strCustomerCode VARCHAR(500), strCustomerName VARCHAR(500), strCustomerAddress VARCHAR(500),
								strProductStatusDescription VARCHAR(500), strProductCode VARCHAR(500), strProductDescription VARCHAR(500),  
								strEngineNumber VARCHAR(500), strChassisNumber VARCHAR(500), strColor VARCHAR(500),
								datTransactionDate DATETIME, strCreditInvestigatorName VARCHAR(500), strCollectorName VARCHAR(500),
								curSRP MONEY, curDownpayment MONEY, curDeferredBalance MONEY, curDiscount MONEY, curRebate MONEY,
								intTerm INT, curMonthlyAmortization MONEY, curNotesReceivable MONEY, curUnearnedInterestIncome MONEY,
								strSIStatusDescription VARCHAR(500), datSIStatusDate DATETIME, DocType  VARCHAR(500),
								RefDoc VARCHAR(500), DocDate DATETIME, curDebit MONEY, curCredit MONEY, curRebateDiscount MONEY,
								curPenaltyCharges MONEY, intIDNewNLCP MONEY, intNewTerm INT, curNewMA MONEY, curNewNR MONEY, curNewUII MONEY,
								strNewProductStatus VARCHAR(500), datNewFirstDueDate DATETIME, datAdjustmentDate DATETIME,
								strPromoType  VARCHAR(500), sequence INT, interestIncome MONEY, UIIDebit MONEY,UIICredit MONEY,CCO VARCHAR(100),
								strOldCustomer VARCHAR(500))

-- for NR and DP|start
INSERT INTO @tblCustLedger (ID, strBranchName, strAccountCode, datAccountDate,  
								datFirstDueDate, strSINumber, strSalesTypeDescription,
								strCustomerCode, strCustomerName, strCustomerAddress,
								strProductStatusDescription, strProductCode, strProductDescription,  
								strEngineNumber, strChassisNumber, strColor,
								datTransactionDate, strCreditInvestigatorName, strCollectorName,
								curSRP, curDownpayment, curDeferredBalance, curDiscount, curRebate,
								intTerm, curMonthlyAmortization, curNotesReceivable, curUnearnedInterestIncome,
								strSIStatusDescription, datSIStatusDate, DocType,
								RefDoc, DocDate, curDebit, curCredit, curRebateDiscount,
								curPenaltyCharges, intIDNewNLCP, intNewTerm, curNewMA, curNewNR, curNewUII,
								strNewProductStatus, datNewFirstDueDate, datAdjustmentDate,
								strPromoType, sequence, interestIncome, UIIDebit,UIICredit,CCO 
								)
SELECT
	al.ID,
	strBranchName = mcs.strBranchName,  
	strAccountCode = mcs.strAccountCode,  
	datAccountDate = mcs.datAccountDate,  
	datFirstDueDate = mcs.datFirstDueDate,  
	strSINumber = mcs.strSINo,  
	strSalesTypeDescription = mcs.strSalesTypeDescription,  
	strCustomerCode = mcs.strCode,  
	strCustomerName = mcs.strCustomerName,  
	strCustomerAddress = mcs.strCityAddress,  
	strProductStatusDescription = mcs.strProductStatusDescription,  
	strProductCode = mcs.strProductMCCode, -- CAST (mcs.intItemID AS VARCHAR(50)) + ' - ' + mcs.strCode ,  
	strProductDescription = mcs.strItemDescription,  
	strEngineNumber = mcs.strEngineNumber,  
	strChassisNumber = mcs.strChassisNumber,  
	strColor = mcs.strColor,  
	datTransactionDate = mcs.datTransactionDate,  
	strCreditInvestigatorName = mcs.strCreditInvestigatorName,  
	strCollectorName = mcs.strCollectorName,  
	curSRP = mcs.curSRP,  
	curDownpayment = mcs.curDP,  
	curDeferredBalance = mcs.curDeferredBal,  
	curDiscount = mcs.curDiscount,  
	curRebate = mcs.curRebate,  
	intTerm = mcs.intTerm,  
	curMonthlyAmortization = mcs.curMA,  
	curNotesReceivable = mcs.curNR - mcs.curDP,  
	curUnearnedInterestIncome = mcs.curUII,
	strSIStatusDescription = mcs.strSIStatusDescription,  
	datSIStatusDate = mcs.datSIStatus,  
	DocType = dt.strName,
	RefDoc = al.strRefDocNo,
	--DocDate = CAST(CONVERT(VARCHAR(10),al.datTransaction,101) AS DATETIME),
	DocDate = CONVERT(VARCHAR(10),al.datTransaction,101),
	curDebit = ISNULL(al.curDebit,0),
	--t1t1an0|09.24.13|start
	--curCredit = ISNULL(al.curCredit,0),
	curCredit = ISNULL(al.curCredit,0),
		--CASE
		--	WHEN al.intIDMasDocType <> 4 THEN ISNULL(al.curCredit,0)
		--	ELSE NULL
		--END,
	--t1t1an0|09.24.13|end
	curRebateDiscount = ISNULL(al.curRebateDiscount,0),
	curPenaltyCharges = ISNULL(al.curPenaltyCharges,0),
	intIDNewNLCP = ISNULL(dcm.intIDNewNLCP,0),
	intNewTerm = ISNULL(mcs.intNewTerm,dcm.intNewTerm),
	curNewMA = ISNULL(mcs.curNewMA,dcm.curNewMA),
	curNewNR = ISNULL(mcs.curNewNR,dcm.curNewNR),
	curNewUII = CASE WHEN (dcm.intIDAdjustmentType in (46,52,48,49)) THEN
						0 ELSE ISNULL(mcs.curNewUII,0) END,
	strNewProductStatus = mcs.strNewProductStatus,
	datNewFirstDueDate = ISNULL(mcs.datNewFirstDueDate,dcm.datNewDueDate),
	datAdjustmentDate = mcs.datAdjustmentDate,
	strPromoType = mcs.strPromoTypeDescription,
	sequence =-- CASE WHEN (al.intIDMasDocType in (1,2)) THEN
						al.intIDMasDocType,
						--CASE WHEN (select intIDAdjustmentType from tblAcctDebitCreditMemo where strAccountCode = @strAccountCode_Local and intIDAdjustmentNo = al.strRefDocNo ) in (5,12) THEN	
						--		1 
						--	 WHEN (select intIDAdjustmentType from tblAcctDebitCreditMemo where strAccountCode = @strAccountCode_Local and intIDAdjustmentNo = al.strRefDocNo ) in (1, 20) THEN
						--		3
					--	--END
					--WHEN (al.intIDMasDocType in (1,2)) THEN
					--	al.intIDMasDocType
				--	ELSE	
				--		3
				--	END,
									--get collection
	  interestIncome =  CASE WHEN ((mcs.intIDMasProductStatus = 2 AND al.intIDMasDocType=2)) 
							THEN
								Round(dbo.udfGetUIIRatePerAccount(@strAccountCode_Local)  * al.curCredit ,2)
							ELSE
							0
							END,
						--check kng unsa na adjustment type	
	  UIIDebit = 0,
	  UIICredit = 0,
	  CCO = concat(bz.strName, ' - ', mcc.strLastName, ', ', mcc.strFirstName, ' ', UPPER(LEFT(mcc.strLastName, 1)), '.')
	 
FROM dbo.tblAccCustomerLedgerDetail al WITH(NOLOCK)
	JOIN dbo.tblAccCustomerLedger alh WITH(NOLOCK) ON alh.ID = al.intIDAccCustomerLedger and alh.intIDMasLocation = al.intIDMasLocation
	JOIN dbo.tblMasDocType dt WITH(NOLOCK) ON dt.ID = al.intIDMasDocType
	-- 2021-06-03 update | Start : mag double ang NR ug DP. cause: kaduha gi Restructuring for Overdue Accounts - Debit. Concerned by: Grace Inot
	LEFT JOIN (SELECT TOP 1 dcMaxID = MAX(dc.ID), strAccount = @strAccountCode_Local FROM dbo.tblAcctDebitCreditMemo dc WITH(NOLOCK) 
			WHERE dc.intIDMasLocation = @intIDMasLocation_Local AND dc.strAccountCode = @strAccountCode_Local AND dc.intIDAdjustmentType in (46,52,48,49,64) 
			GROUP BY dc.intIDAdjustmentType) ddcc ON ddcc.strAccount = alh.strAccountCode
	-- 2021-06-03 update | End
	--LEFT JOIN dbo.tblAcctDebitCreditMemo dcm WITH(NOLOCK) ON dcm.strAccountCode = alh.strAccountCode AND dcm.intIDAdjustmentType in (46,52,48,49) -- Old: 2021-06-03 update
	LEFT JOIN dbo.tblAcctDebitCreditMemo dcm WITH(NOLOCK) ON dcm.ID = ddcc.dcMaxID -- Old: 2021-06-03 update
	LEFT JOIN dbo.vwSalAllMCSaleFinancing mcs WITH(NOLOCK) ON mcs.intSaleID = alh.intSalesID
	LEFT JOIN tblMasCOI mcc WITH(NOLOCK) ON mcs.intCollectorID = mcc.ID
	LEFT JOIN tblMasBranchZone bz WITH(NOLOCK) ON mcc.intIDMasBranchZone = bz.ID
	
WHERE alh.strAccountCode = @strAccountCode_Local
	AND al.intIDMasLocation = @intIDMasLocation_Local
	and al.intIDMasDocType in (1,2,4)
	AND al.strRefDocNo IS NOT NULL
	--and alh.blnActive = 1
	--AND (CASE al.intIDMasDocType  
	--		WHEN 5 THEN 
	--			(select intIDAdjustmentType from tblAcctDebitCreditMemo where intIDAdjustmentNo = convert(int,al.strRefDocNo) and intIDMasLocation = @intIDMasLocation_Local)
	--		ELSE
	--			0
	--	END) NOT IN (5,12)
--		AND alh.intIDMasLocation = 2
ORDER BY CONVERT(VARCHAR(10),al.datTransaction,101)
--		, al.strRefDocNo
	, sequence --dt.intIDOrder, alh.ID
-- for NR and DP|end

-- for Collection|start
INSERT INTO @tblCustLedger (ID, strBranchName, strAccountCode, datAccountDate,  
								datFirstDueDate, strSINumber, strSalesTypeDescription,
								strCustomerCode, strCustomerName, strCustomerAddress,
								strProductStatusDescription, strProductCode, strProductDescription,  
								strEngineNumber, strChassisNumber, strColor,
								datTransactionDate, strCreditInvestigatorName, strCollectorName,
								curSRP, curDownpayment, curDeferredBalance, curDiscount, curRebate,
								intTerm, curMonthlyAmortization, curNotesReceivable, curUnearnedInterestIncome,
								strSIStatusDescription, datSIStatusDate, DocType,
								RefDoc, DocDate, curDebit, curCredit, curRebateDiscount,
								curPenaltyCharges, intIDNewNLCP,  intNewTerm, curNewMA, curNewNR, curNewUII,
								strNewProductStatus, datNewFirstDueDate, datAdjustmentDate,
								strPromoType, sequence, interestIncome, UIIDebit,UIICredit, CCO
								)
SELECT
	al.ID,
	strBranchName = mcs.strBranchName,  
	strAccountCode = mcs.strAccountCode,  
	datAccountDate = mcs.datAccountDate,  
	datFirstDueDate = mcs.datFirstDueDate,  
	strSINumber = mcs.strSINo,  
	strSalesTypeDescription = mcs.strSalesTypeDescription,  
	strCustomerCode = mcs.strCode,  
	strCustomerName = mcs.strCustomerName,  
	strCustomerAddress = mcs.strCityAddress,  
	strProductStatusDescription = mcs.strProductStatusDescription,  
	strProductCode = mcs.strProductMCCode, -- CAST (mcs.intItemID AS VARCHAR(50)) + ' - ' + mcs.strCode ,  
	strProductDescription = mcs.strItemDescription,  
	strEngineNumber = mcs.strEngineNumber,  
	strChassisNumber = mcs.strChassisNumber,  
	strColor = mcs.strColor,  
	datTransactionDate = mcs.datTransactionDate,  
	strCreditInvestigatorName = mcs.strCreditInvestigatorName,  
	strCollectorName = mcs.strCollectorName,  
	curSRP = mcs.curSRP,  
	curDownpayment = mcs.curDP,  
	curDeferredBalance = mcs.curDeferredBal,  
	curDiscount = mcs.curDiscount,  
	curRebate = mcs.curRebate,  
	intTerm = mcs.intTerm,  
	curMonthlyAmortization = mcs.curMA,  
	curNotesReceivable = mcs.curNR,  
	curUnearnedInterestIncome = mcs.curUII,
	strSIStatusDescription = mcs.strSIStatusDescription,  
	datSIStatusDate = mcs.datSIStatus,  
	DocType = dt.strName,
	RefDoc = al.strRefDocNo,
	DocDate = CONVERT(VARCHAR(10),al.datTransaction,101),
	--DocDate = CAST(CONVERT(VARCHAR(10),al.datTransaction,101) AS DATETIME),
	curDebit = ISNULL(al.curDebit,0),
	--t1t1an0|09.24.13|start
	--curCredit = ISNULL(al.curCredit,0),
	curCredit =
		CASE
			WHEN al.intIDMasDocType <> 4 THEN ISNULL(al.curCredit,0)
			ELSE NULL
		END,
	--t1t1an0|09.24.13|end
	curRebateDiscount = ISNULL(al.curRebateDiscount,0),
	curPenaltyCharges = ISNULL(al.curPenaltyCharges,0),
	intIDNewNLCP = 0,
	intNewTerm = ISNULL(mcs.intNewTerm,0),
	curNewMA = ISNULL(mcs.curNewMA,0),
	curNewNR = ISNULL(mcs.curNewNR,0),
	curNewUII = ISNULL(mcs.curNewUII,0),
	strNewProductStatus = mcs.strNewProductStatus,
	datNewFirstDueDate = mcs.datNewFirstDueDate,
	datAdjustmentDate = mcs.datAdjustmentDate,
	strPromoType = mcs.strPromoTypeDescription,
	sequence = --CASE WHEN (al.intIDMasDocType in (1,2)) THEN
						--CASE WHEN (select intIDAdjustmentType from tblAcctDebitCreditMemo where strAccountCode = @strAccountCode_Local and intIDAdjustmentNo = al.strRefDocNo ) in (5,12) THEN	
						--		1 
						--	 WHEN (select intIDAdjustmentType from tblAcctDebitCreditMemo where strAccountCode = @strAccountCode_Local and intIDAdjustmentNo = al.strRefDocNo ) in (1, 20) THEN
						--		2
						--END
						--al.intIDMasDocType
					--WHEN (al.intIDMasDocType in (1,2)) THEN
					--	al.intIDMasDocType
				--	ELSE	
						4,
				--	END,
									--get collection
	  interestIncome = CASE WHEN ((al.intIDMasDocType=3) or 
								  (mcs.intIDMasProductStatus = 2 AND al.intIDMasDocType=2) or ((select intIDAdjustmentType from tblAcctDebitCreditMemo WITH(NOLOCK)
								    where intIDMasLocation = @intIDMasLocation_Local AND strAccountCode = @strAccountCode_Local and intIDAdjustmentNo= CASE WHEN(al.intIDMasDocType NOT IN (1 , 2)) THEN 
																												al.strRefDocNo 
																										ELSE 
																										0 END) IN (1 ,20,24)
																										))
						THEN
							[dbo].[fsvGetInterestIncome](@strAccountCode_Local, 'Installment', cc.strReferenceNumber, al.datTransaction )
						   --Round(dbo.udfGetUIIRatePerAccount(@strAccountCode_Local)  * al.curCredit ,2)
							 -- dbo.udfGetUIIRatePerAccount(@strAccountCode_Local)  * al.curCredit
						ELSE
						 NULL 
						END,
						--check kng unsa na adjustment type	
	  UIIDebit = atd.curDebit,
	  UIICredit = atd.curCredit,
	  CCO = concat(bz.strName, ' - ', mcc.strLastName, ', ', mcc.strFirstName, ' ', UPPER(LEFT(mcc.strLastName, 1)), '.')
FROM dbo.tblAccCustomerLedgerDetail al WITH(NOLOCK)
	JOIN dbo.tblAccCustomerLedger alh WITH(NOLOCK) ON alh.ID = al.intIDAccCustomerLedger and alh.intIDMasLocation = al.intIDMasLocation
	JOIN dbo.tblMasDocType dt WITH(NOLOCK) ON dt.ID = al.intIDMasDocType
	JOIN dbo.tblColCollection cc WITH(NOLOCK) ON cc.id = al.intIDColCollection
	LEFT JOIN dbo.vwSalAllMCSaleFinancing mcs WITH(NOLOCK) ON mcs.intSaleID = alh.intSalesID
	LEFT JOIN tblAcctTran at WITH(NOLOCK) ON --at.intIDMasLocation = alh.intIDMasLocation AND 
	at.intIDMasBookTypeForm = 4 AND at.strReference = CAST(al.intIDColCollection as VARCHAR(100))
	LEFT JOIN tblAcctTranDetail atd WITH(NOLOCK) ON atd.intIDAccTran = at.ID AND atd.intIDMasCOA = 37
	LEFT JOIN tblMasCOI mcc WITH(NOLOCK) ON mcs.intCollectorID = mcc.ID
	LEFT JOIN tblMasBranchZone bz WITH(NOLOCK) ON mcc.intIDMasBranchZone = bz.ID
WHERE alh.strAccountCode = @strAccountCode_Local
	AND al.intIDMasLocation = @intIDMasLocation_Local
	AND al.intIDMasDocType in (3)
	--and alh.blnActive = 1
	--AND (CASE al.intIDMasDocType  
	--		WHEN 5 THEN 
	--			(select intIDAdjustmentType from tblAcctDebitCreditMemo where intIDAdjustmentNo = convert(int,al.strRefDocNo) and intIDMasLocation = @intIDMasLocation_Local)
	--		ELSE
	--			0
	--	END) NOT IN (5,12)
--		AND alh.intIDMasLocation = 2
ORDER BY CONVERT(VARCHAR(10),al.datTransaction,101)
--		, al.strRefDocNo
	, sequence --dt.intIDOrder, alh.ID
-- for Collection|end

-- for DMCM|start
INSERT INTO @tblCustLedger (ID, strBranchName, strAccountCode, datAccountDate,  
								datFirstDueDate, strSINumber, strSalesTypeDescription,
								strCustomerCode, strCustomerName, strCustomerAddress,
								strProductStatusDescription, strProductCode, strProductDescription,  
								strEngineNumber, strChassisNumber, strColor,
								datTransactionDate, strCreditInvestigatorName, strCollectorName,
								curSRP, curDownpayment, curDeferredBalance, curDiscount, curRebate,
								intTerm, curMonthlyAmortization, curNotesReceivable, curUnearnedInterestIncome,
								strSIStatusDescription, datSIStatusDate, DocType,
								RefDoc, DocDate, curDebit, curCredit, curRebateDiscount,
								curPenaltyCharges, intIDNewNLCP, intNewTerm, curNewMA, curNewNR, curNewUII,
								strNewProductStatus, datNewFirstDueDate, datAdjustmentDate,
								strPromoType, sequence, interestIncome, UIIDebit,UIICredit, CCO, strOldCustomer
								)
SELECT distinct
	al.ID,
	strBranchName = mcs.strBranchName, strAccountCode = mcs.strAccountCode, datAccountDate = mcs.datAccountDate,  
	datFirstDueDate = mcs.datFirstDueDate, strSINumber = mcs.strSINo, strSalesTypeDescription = mcs.strSalesTypeDescription,  
	strCustomerCode = mcs.strCode, strCustomerName = mcs.strCustomerName, strCustomerAddress = mcs.strCityAddress,  
	strProductStatusDescription = mcs.strProductStatusDescription, strProductCode = mcs.strProductMCCode, strProductDescription = mcs.strItemDescription,  
	strEngineNumber = mcs.strEngineNumber, strChassisNumber = mcs.strChassisNumber, strColor = mcs.strColor,  
	datTransactionDate = mcs.datTransactionDate, strCreditInvestigatorName = mcs.strCreditInvestigatorName, strCollectorName = mcs.strCollectorName,  
	curSRP = mcs.curSRP, curDownpayment = mcs.curDP, curDeferredBalance = mcs.curDeferredBal, curDiscount = mcs.curDiscount, curRebate = mcs.curRebate,  
	intTerm = mcs.intTerm, curMonthlyAmortization = mcs.curMA, curNotesReceivable = mcs.curNR, curUnearnedInterestIncome = mcs.curUII,
	strSIStatusDescription = mcs.strSIStatusDescription, datSIStatusDate = mcs.datSIStatus, 
	DocType = CASE WHEN (dcm.intIDAdjustmentType in (24)) THEN
					'Downpayment'
				ELSE
					dt.strName
				END,
	--RefDoc = al.strRefDocNo, DocDate = CAST(CONVERT(VARCHAR(10),al.datTransaction,101) AS DATETIME),
	RefDoc = al.strRefDocNo, DocDate = CONVERT(VARCHAR(10),al.datTransaction,101),
	curDebit = CASE WHEN (dcm.intIDAdjustmentType = 40) THEN  NULL
				ELSE
				ISNULL(al.curDebit,0)
				END,
	--t1t1an0|09.24.13|start
	--curCredit = ISNULL(al.curCredit,0),
	curCredit =
		CASE
	        WHEN dcm.intIDAdjustmentType IN (41) THEN NULL
			WHEN al.intIDMasDocType <> 4 THEN ISNULL(al.curCredit,0)
			ELSE NULL
		END,
	--t1t1an0|09.24.13|end
	curRebateDiscount = CASE WHEN (dcm.intIDAdjustmentType = 17) THEN
										ISNULL(al.curRebateDiscount,0)
								ELSE
									ISNULL(al.curRebateDiscount,0)
						END,
	curPenaltyCharges = ISNULL(al.curPenaltyCharges,0),
	intIDNewNLCP = dcm.intIDNewNLCP,
	intNewTerm = ISNULL(mcs.intNewTerm,0),
	curNewMA = ISNULL(mcs.curNewMA,0),
	curNewNR = ISNULL(mcs.curNewNR,0),
	curNewUII = CASE WHEN (dcm.intIDAdjustmentType in (46,52,48,49)) THEN
						0 ELSE ISNULL(mcs.curNewUII,0) END,
	strNewProductStatus = mcs.strNewProductStatus,
	datNewFirstDueDate = mcs.datNewFirstDueDate,
	datAdjustmentDate = mcs.datAdjustmentDate,
	strPromoType = mcs.strPromoTypeDescription,
	sequence = CASE WHEN (dcm.intIDAdjustmentType in (5,24)) THEN
						2
					WHEN (dcm.intIDAdjustmentType in (12,16,54,19)) THEN
						3
					ELSE
						CASE WHEN (dcm.intIDAdjustmentType in (13,51)) THEN
									5
							ELSE
									4
						END
					END,
									--get collection
	  interestIncome = --CASE WHEN dcm.intIDAdjustmentType in (1 , 20, 17 , 36) THEN
			--					--Round(dbo.udfGetUIIRatePerAccount(@strAccountCode_Local)  * al.curCredit ,2) 
			--					[dbo].[fsvGetInterestIncome](@strAccountCode_Local, 'Adjustment', dcm.intIDAdjustmentNo, al.datTransaction)
			--				WHEN dcm.intIDAdjustmentType in (10) THEN
			--				    Round(dcm.curUII,2)
			--				WHEN dcm.intIDAdjustmentType in (9) THEN
			--					 --Round((dbo.udfGetUIIRatePerAccount(@strAccountCode_Local)  * al.curCredit) * -1 ,2) 
			--					 [dbo].[fsvGetInterestIncome](@strAccountCode_Local, 'Adjustment', dcm.intIDAdjustmentNo, al.datTransaction) * -1
			--				ELSE
			--					0
			--				END,
						[dbo].[fsvGetInterestIncome](@strAccountCode_Local, 'Adjustment', dcm.intIDAdjustmentNo, al.datTransaction),
						--check kng unsa na adjustment type	
	  UIIDebit = CASE WHEN (dcm.intIDAdjustmentType IN (1, 10, 3,5 , 4 , 26,28,30,31,32,34,35,37,11,40,45,52,49,50, 55, 68)) THEN
						  dcm.curUII
				ELSE
					CASE WHEN dcm.intIDAdjustmentType IN (22 , 33, 61) THEN
						dcm.curAdjustAmount
					ELSE
						0
					END
				END,
	  UIICredit = CASE WHEN dcm.intIDAdjustmentType IN(9 ,18 ,12,23 , 27,16,54,2, 13,41,42, 46 , 48 , 51) THEN
						 dcm.curUII
				ELSE
					CASE WHEN dcm.intIDAdjustmentType IN (23,21) THEN
						dcm.curAdjustAmount
					ELSE
						0
					END
				END,
	 CCO = concat(bz.strName, ' - ', mcc.strLastName, ', ', mcc.strFirstName, ' ', UPPER(LEFT(mcc.strLastName, 1)), '.'),
	 strOldCustomer = CASE WHEN dcm.intIDAdjustmentType IN ( 12, 19, 31 ) THEN concat(cer.strLastName, ', ', cer.strFirstName, ' ', UPPER(LEFT(cer.strMiddleName, 1)), '.') ELSE '' END
FROM dbo.tblAccCustomerLedgerDetail al WITH(NOLOCK)
	JOIN dbo.tblAccCustomerLedger alh WITH(NOLOCK) ON alh.ID = al.intIDAccCustomerLedger and alh.intIDMasLocation = al.intIDMasLocation
	JOIN dbo.tblMasDocType dt WITH(NOLOCK) ON dt.ID = al.intIDMasDocType
	JOIN dbo.tblAcctDebitCreditMemo dcm WITH(NOLOCK) ON dcm.id = al.intIDAcctDebitCreditMemo
	JOIN [dbo].[tblAcctTran] at with(nolock) ON at.strReference = CAST(dcm.ID as varchar(50))
	LEFT JOIN [dbo].[tblAcctTranDetail] atd with(nolock) on at.id = atd.intidAccTran
	LEFT JOIN dbo.vwSalAllMCSaleFinancing mcs WITH(NOLOCK) ON mcs.intSaleID = alh.intSalesID
	LEFT JOIN tblMasCOI mcc WITH(NOLOCK) ON mcs.intCollectorID = mcc.ID
	LEFT JOIN tblMasBranchZone bz WITH(NOLOCK) ON mcc.intIDMasBranchZone = bz.ID
	LEFT JOIN tblMasCustomer cer WITH(NOLOCK) ON cer.ID = dcm.intMasOldCustomer
WHERE alh.strAccountCode = @strAccountCode_Local
	AND al.intIDMasLocation = @intIDMasLocation_Local
	and al.intIDMasDocType in (5)
	--AND dcm.intIDAdjustmentType not in (40, 41)
	--and alh.blnActive = 1
	--AND (CASE al.intIDMasDocType  
	--		WHEN 5 THEN 
	--			(select intIDAdjustmentType from tblAcctDebitCreditMemo where intIDAdjustmentNo = convert(int,al.strRefDocNo) and intIDMasLocation = @intIDMasLocation_Local)
	--		ELSE
	--			0
	--	END) NOT IN (5,12)
--		AND alh.intIDMasLocation = 2
ORDER BY CONVERT(VARCHAR(10),al.datTransaction,101)
--		, al.strRefDocNo
	, sequence --dt.intIDOrder, alh.ID
-- for DMCM|end

	DECLARE @oldcustomer VARCHAR(100)

	SELECT @oldcustomer = concat(b.strLastName, ', ', b.strFirstName, ' ', UPPER(LEFT(b.strMiddleName, 1)), '.')
	FROM dbo.tblAcctDebitCreditMemo a WITH(NOLOCK) 
	LEFT JOIN tblMasCustomer b WITH(NOLOCK) ON b.ID = a.intMasOldCustomer
	WHERE a.strAccountCode = @strAccountCode_Local AND a.intIDMasLocation = @intIDMasLocation_Local AND a.intIDAdjustmentType IN ( 12, 19, 31 )

	if LEN(@oldcustomer) > 0 
	BEGIN
		UPDATE @tblCustLedger SET strOldCustomer = @oldcustomer
	END

	SELECT DISTINCT 
	ID,
	strBranchName,
	strAccountCode,
	datAccountDate,
	datFirstDueDate,
	strSINumber,
	strSalesTypeDescription,
	strCustomerCode,
	strCustomerName,
	strCustomerAddress,
	strProductStatusDescription,
	strProductCode,
	strProductDescription,
	strEngineNumber,
	strChassisNumber,
	strColor,
	datTransactionDate,
	strCreditInvestigatorName,
	strCollectorName,
	curSRP,
	curDownpayment,
	curDeferredBalance,
	curDiscount,
	curRebate,
	intTerm,
	curMonthlyAmortization,
	curNotesReceivable,
	curUnearnedInterestIncome,
	strSIStatusDescription,
	datSIStatusDate,
	DocType,
	RefDoc,
	DocDate,
	curDebit,
	curCredit,
	curRebateDiscount,
	curPenaltyCharges,
	intIDNewNLCP,
	intNewTerm,
	curNewMA,
	curNewNR,
	curNewUII,
	strNewProductStatus,
	datNewFirstDueDate,
	datAdjustmentDate,
	strPromoType,
	sequence,
	interestIncome,
	UIIDebit,
	UIICredit,
	CCO,
	strOldCustomer
	FROM @tblCustLedger -- 2017-06-09 Add DISTINCT in final Select kay nag double ang mga data.	
	ORDER BY DocDate, ID, sequence 