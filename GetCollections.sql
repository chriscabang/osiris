DECLARE @intIDMasLocation     INT,
        @datStartDate         DATETIME,
        @datEndDate           DATETIME,
        @datAsOf              DATETIME,
        @intIDMasLocationSNDC INT

SET @intIDMasLocation = 199
SET @datStartDate = '01-02-2022'
SET @datAsOf = '12-31-2022'
SET @datEndDate = @datAsOf
SET @intIDMasLocationSNDC = 286

DECLARE @tblTempColection TABLE
  (
     straccountcode      VARCHAR(100),
     intidmaspaymenttype INT,
     noofpayments        INT,
     totalcredit         DECIMAL,
     rebate              DECIMAL,
     curnr               DECIMAL,
     datcoltransdate     DATE
  )

INSERT INTO @tblTempColection
SELECT StNCollection.straccountcode,
       StNCollection.intidmaspaymenttype                AS PaymentType,
       Count(StNCollection.straccountcode)              AS NoOfPayments,
       Sum(StNCollection.curgrosspaid)                  AS TotalCredit,
       Sum(StNCollection.currebatediscount)             AS Rebate,
       bb.curnr,
       -- What is datcoltransdate and why are we only interested on the first payment date? 
       -- The original script took datcoltransdate 'TOP 1' with 'ORDER BY -- DESC' commented out. Maybe it was a mistake?
       -- Ln 86 below say's that datcoltransdate is "DateOfLastPayment", changing this to 'Max' instead so we get the last payment made.
       Cast(Max(StNCollection.datcoltransdate) AS DATE) AS datColTransDate
FROM   stonino.dbo.tblcolcollection StNCollection
       LEFT JOIN stonino.dbo.tblsalmcfinancing bb
              ON StNCollection.straccountcode = bb.straccountcode
-- Payment Types : [1 = DP, 2 = Installment, 3 = Spot Cash]
-- Orignal script took 2 (Installment) and 3 (Spot Cash) payment types of Financing.
-- Why do we have separate Downpayment types? Do we have installments without downpayments?			  
-- Let's take Installment types only 
WHERE  StNCollection.intidmaspaymenttype = 2
GROUP  BY StNCollection.straccountcode,
          StNCollection.intidmaspaymenttype,
          bb.curnr

SELECT b.strcode             AS CustomerNo,
       m.strname             AS SkygoBranchName,
       a.straccountcode      AS SKYGOAccountCode,
    --    ff.straccountcode     AS StNAccountCode,
    --    k.straccountcode      AS StNCollectionAccountCode,
    --    k.intidmaspaymenttype AS PaymentType,
       d.strname             AS ModelPurChased,
       Cast(a.datsi AS DATE) AS DatePurchased,
       ff.currebate          AS Rebate,
       CASE
         WHEN a.blnrepo = 0 THEN 'Yes'
         ELSE 'No'
       END                   AS isBrandNew,
       CASE
         WHEN e.salesrepid IS NULL THEN 'Walk in'
         ELSE 'IBP'
       END                   AS IBPorWalk,
       CASE
         WHEN ff.curgrossprice IS NULL THEN a.curcashprice
         ELSE ff.curgrossprice
       END                   AS TotalPurchase,
       CODPrice = ff.curdeferredbal,
       ff.curdp              AS DownPayment,
       ff.intterm            AS NoOfMonth,
       c.curlcp              AS currentLCP,
       MonthlyAmortization = ff.curma,
       CASE
         WHEN k.noofpayments IS NULL THEN 1
         ELSE k.noofpayments
       END                   AS NoOfPaymentsMade,
       CASE
         WHEN k.totalcredit IS NULL THEN f.curdp
         ELSE ( k.totalcredit + f.curdp )
       END                   AS TotalOfPaymentMade,
       k.rebate              AS TotalOfRebatesMade,
       CASE
         WHEN k.intidmaspaymenttype IS NULL THEN ( f.curgrossprice - ff.curdp )
         ELSE ( k.curnr - ( k.totalcredit + ff.curdp ) )
       END                   AS OutstadingBalance,
       k.datcoltransdate     AS DateOfLastPayment,
       StatusOfAccount = ( CASE
                             WHEN h.strname = 'Repo Sales' THEN h.strname
                             ELSE i.strname
                           END ),
       DateOfRepo = ( CASE
                        WHEN h.strname = 'Repo Sales' THEN f.datsistatus
                        ELSE NULL
                      END )
FROM   skygoerp.dbo.tblsalmcsale a WITH(nolock)
       INNER JOIN skygoerp.dbo.tblmascustomer b WITH(nolock)
               ON a.intidmascustomer = b.id
       INNER JOIN skygoerp.dbo.tblinvmcstock c WITH(nolock)
               ON a.intidinvmcstock = c.id
       INNER JOIN skygoerp.dbo.tblmasmc d WITH(nolock)
               ON c.intidmasmc = d.id
       LEFT JOIN dbnetworking.dbo.tblar e WITH(nolock)
              ON a.straccountcode = e.acctcode
       LEFT JOIN stonino.dbo.tblsalmcfinancing f WITH(nolock)
              ON a.straccountcode = f.straccountcode
       LEFT JOIN stonino.dbo.tblsalmcfinancing ff WITH(nolock)
              ON f.intidinvmcstock = ff.intidinvmcstock
       LEFT JOIN skygoerp.dbo.tblltomasmunicipality j WITH(nolock)
              ON b.intidltomasmunicipality = j.id
       LEFT JOIN stonino.dbo.tblmassistatus h WITH(nolock)
              ON ff.intidmassistatus = h.id
       LEFT JOIN stonino.dbo.tblmasaccountstatus i WITH(nolock)
              ON ff.intidmasaccountstatus = i.id
       -- This line does not effectively get the code with installment, when do we put the record for collection? 
	   -- ff and k can be both NULL (which most likely means Spot Cash payment made), and thus includes this record.
	   -- Try to find a way for joining this, maybe inner? 
       LEFT JOIN @tblTempColection k
              ON ff.straccountcode = k.straccountcode
       LEFT JOIN skygoerp.dbo.tblmaslocation m WITH(nolock)
              ON a.intidmaslocation = m.id
       LEFT JOIN stonino.dbo.tblmaslocation n WITH(nolock)
              ON ff.intidmaslocation = n.id
WHERE
  -- Let's not include SkyGo accounts with "CASH-" in them, as it is assumed they are codes for Spot Cash payments made. 
  -- Is this always true? Might need to check further
  a.strAccountCode NOT LIKE '%CASH-%' AND
  m.strname = 'Dalaguete' AND
  CAST(a.datSI AS DATE) < = @datAsOf
  --   Cast(a.datsi AS DATE) BETWEEN @datStartDate AND @datEndDate
ORDER  BY m.strname ASC,
          a.datsi ASC 