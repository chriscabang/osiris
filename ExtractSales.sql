
DECLARE @intIDMasLocation INT, @datAsOf DATETIME,@intIDMasLocationSNDC INT
SET @intIDMasLocation  = 199
SET @datAsOf = '10-31-2021'
SET @intIDMasLocationSNDC = 286



DECLARE @tblTempColection TABLE  
(
strAccountCode varchar(100),
intIDMasPaymentType INT,
NoOfPayments int,
TotalCredit decimal,
Rebate decimal,
curNR decimal,
datColTransDate date
)
INSERT INTO @tblTempColection
select 
aa.strAccountCode,
aa.intIDMasPaymentType as intIDMasPaymentType,
COUNT(aa.strAccountCode) as NoOfPayments, 
SUM(aa.curGrossPaid) as TotalCredit,
SUM(aa.curRebateDiscount)  as Rebate,
bb.curNR,
datColTransDate = (SELECT TOP 1 CAST(datColTransDate AS DATE) From StoNino.dbo.tblColCollection WITH(NOLOCK) 
		where --intIDMasLocation = @intIDMasLocationSNDC 
		--AND 
		intIDMasPaymentType IN (2,3) AND strAccountCode =  aa.strAccountCode 
		GROUP BY strAccountCode,datColTransDate
		--ORDER BY datColTransDate DESC
)
from StoNino.dbo.tblColCollection aa WITH(NOLOCK)
LEFT JOIN StoNino.dbo.tblSalMCFinancing bb WITH(NOLOCK) ON aa.strAccountCode = bb.strAccountCode
where --aa.intIDMasLocation = @intIDMasLocationSNDC
--and aa.strAccountCode LIKE '%TOL-4-1%' 
--and 
aa.intIDMasPaymentType IN (2,3)
GROUP BY aa.strAccountCode,aa.intIDMasPaymentType,bb.curNR

--select * from @tblTempColection


select 
b.strCode as CustomerNo,
a.intIDMasLocation,
m.strName as SkygoBranchName,
a.strAccountCode as SKYGOAccountCode,
ff.intIDMasLocation,
n.strName as SNDCBranchName,
ff.strAccountCode as SNDCAccountCode,
d.strName as ModelPurChased,
a.datSI as datDatePurchased,
ff.curRebate as Rebate,
CASE WHEN a.blnRepo = 0 THEN 'Brand New' ELSE 'Repo' END as isRepoOrBrandNew,
CASE WHEN e.SalesRepID IS NULL THEN 'Walk in' ELSE 'IBP' END IBPorWalk,
CASE WHEN b.custType = 0 THEN b.BaranggayAddress ELSE b.orgBaranggayAddress END as Brgy,
j.strName as City,
CAST(b.datOfBirth AS DATE) as Birthdate,
b.strMaritalStatus as MaritalStatus,
b.strOccupation as Profession,
Religion = '',
b.intMonthlyIncome as PersonalIncome,
CombinedIncome = (ISNULL(b.intMonthlyIncome,0) + ISNULL(b.intMonthlyIncomeSpouse,0)),
AdditionalIncome = '',
CASE WHEN (b.strCoMaker2 = 'NA' OR 
		  b.strCoMaker2 = 'na' OR
		  b.strCoMaker2 = '' OR
		  b.strCoMaker2 = '-' OR
		  b.strCoMaker2 = 'NONE' OR
		  b.strCoMaker2 = 'none' OR
		  b.strCoMaker2 = '0'
		  ) THEN CASE WHEN (b.strCoMaker1 = 'NA' OR 
							  b.strCoMaker1 = 'na' OR
							  b.strCoMaker1 = '' OR
							  b.strCoMaker1 = '-' OR
							  b.strCoMaker1 = 
							  'NONE' OR
							  b.strCoMaker1 = 'none' OR
							  b.strCoMaker1 = '0'
							)  THEN 0 ELSE 1 END
				
		    ELSE 2 END as NoOfCoMaker,
CASE WHEN ff.curGrossPrice IS NULL THEN a.curCashPrice ELSE ff.curGrossPrice END as TotalPurchase,
CODPrice = ff.curDeferredBal,
ff.curDP as DownPayment,
ff.intTerm as NoOfMonth,
c.curLCP as currentLCP, 
MonthlyAmortization = ff.curMA,

CASE WHEN k.NoOfPayments IS NULL THEN 1 ELSE  k.NoOfPayments END AS NoOfPaymentsMade,
CASE WHEN k.TotalCredit IS NULL THEN f.curDP ELSE (k.TotalCredit + f.curDP) END AS TotalOfPaymentMade,
k.Rebate as TotalOfRebatesMade,

CASE WHEN k.intIDMasPaymentType = 3 THEN 0 ELSE 
CASE WHEN k.intIDMasPaymentType IS NULL THEN (f.curGrossPrice - ff.curDP)
	ELSE
	(k.curNR - (k.TotalCredit + ff.curDP))
	END
END as OutStadingBalance,
k.datColTransDate as DateOfLastePayment,
--StatusOfAccount = (i.strName),
--StatusOfAccount1 = (h.strName),
StatusOfAccount = (CASE WHEN h.strName = 'Repo Sales' then h.strName ELSE i.strName END),
DateOfRepo = (CASE WHEN h.strName = 'Repo Sales' THEN f.datSIStatus ELSE null END)


from SkyGoERP.dbo.tblSalMCSale a WITH(NOLOCK)
INNER JOIN SkyGoERP.dbo.tblMasCustomer b WITH(NOLOCK) ON a.intIDMasCustomer = b.ID
INNER JOIN SkygoERP.dbo.tblInvMCStock c WITH(NOLOCK) ON a.intIDInvMCStock = c.ID
INNER JOIN SkyGoERP.dbo.tblMasMC d WITH(NOLOCK) ON c.intIDMasMC = d.ID
LEFT JOIN dbNetworking.dbo.tblAR e WITH(NOLOCK) ON a.strAccountCode = e.AcctCode
LEFT JOIN StoNino.dbo.tblSalMCFinancing f WITH(NOLOCK) ON a.strAccountCode = f.strAccountCode
LEFT JOIN StoNino.dbo.tblSalMCFinancing ff WITH(NOLOCK) ON f.intIDInvMCStock = ff.intIDInvMCStock
LEFT JOIN SkyGoERP.dbo.tblLtoMasMunicipality j WITH(NOLOCK) ON b.intIDLTOMasMunicipality = j.ID
LEFT JOIN StoNino.dbo.tblMasSIStatus h WITH(NOLOCK) ON ff.intIDMasSIStatus = h.ID
LEFT JOIN StoNino.dbo.tblMasAccountStatus i WITH(NOLOCK) ON ff.intIDMasAccountStatus = i.ID  
--LEFT JOIN StoNino.dbo.tblColCollection g WITH(NOLOCK) ON f.intIDMasLocation = g.intIDMasLocation and g.intIDMasPaymentType = 2
LEFT JOIN @tblTempColection k ON ff.strAccountCode = k.strAccountCode
--LEFT JOIN StoNino.dbo.vwSalAllMCSaleFinancing l WITH(NOLOCK) ON
LEFT JOIN SkygoERP.dbo.tblMasLocation m WITH(NOLOCK) ON a.intIDMasLocation = m.ID
LEFT JOIN StoNino.dbo.tblMasLocation n WITH(NOLOCK) ON ff.intIDMasLocation = n.ID

WHERE --a.intIDMasLocation IN (@intIDMasLocation) AND 
CAST(a.datSI AS DATE) < = @datAsOf
--and a.strAccountCode = 'TOL-4'
--GROUP BY 
--b.strCode,
--a.intIDMasLocation,
--a.strAccountCode,
--f.intIDMasLocation,
--f.strAccountCode,
--h.strName,
--i.strName,
--f.datSIStatus,
--a.datSI
ORDER BY m.strName ASC,a.datSI ASC

