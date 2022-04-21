---INSPECTING DATA 

SELECT * FROM [dbo].[sales_data_sample]

--CHECKING UNIUE VALUES.

SELECT DISTINCT STATUS FROM [dbo].[sales_data_sample] --Nice one to plot                                                                       
SELECT DISTINCT year_id FROM [dbo].[sales_data_sample]
SELECT DISTINCT PRODUCTLINE FROM [dbo].[sales_data_sample] ---Nice to plot
SELECT DISTINCT COUNTRY FROM [dbo].[sales_data_sample] ---Nice to plot
SELECT DISTINCT DEALSIZE FROM [dbo].[sales_data_sample] ---Nice to plot                              
SELECT DISTINCT TERRITORY FROM [dbo].[sales_data_sample] ---Nice to plot

SELECT DISTINCT MONTH_ID FROM [dbo].[sales_data_sample]
WHERE year_id = 2003

---ANALYSIS
----LET'S START BY GROUPING SALES BY PRODUCTLINE.

SELECT PRODUCTLINE, SUM(sales) Revenue
FROM [dbo].[sales_data_sample]
GROUP BY PRODUCTLINE
ORDER BY 2 DESC


SELECT YEAR_ID, SUM(sales) Revenue
FROM [dbo].[sales_data_sample]
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT  DEALSIZE,  SUM(sales) Revenue
FROM [PortfolioProject].[dbo].[sales_data_sample]
GROUP BY  DEALSIZE
ORDER BY 2 DESC


----WHAT WAS THE BEST MONTH FOR SALES IN A SPECIFIC YEAR? HOW MUCH WAS EARNED THAT MONTH? 

SELECT  MONTH_ID, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency
FROM [PortfolioProject].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 --change year to see the rest
GROUP BY  MONTH_ID
ORDER BY 2 DESC


--NOVEMBER SEEMS TO BE THE MONTH, WHAT PRODUCT DO THRY SELL IN NOVEMBER, CLASSIC I BELIEVE. 
SELECT  MONTH_ID, PRODUCTLINE, SUM(sales) Revenue, COUNT(ORDERNUMBER)
FROM [PortfolioProject].[dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
GROUP BY  MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


----WHO IS OUR BEST CUSTOMER? OUR BEST CUSTOMER? (THIS COULD BE BEST ANSWERED WITH RFM )


DROP TABLE IF EXISTS frm
;WITH rfm as 
(
	SELECT 
		CUSTOMERNAME, 
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample])) Recency
	FROM [PortfolioProject].[dbo].[sales_data_sample]
	GROUP BY CUSTOMERNAME
),
rfm_calc AS
(

	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
	FROM rfm r
)
SELECT 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary AS rfm_cell,
	CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary  AS VARCHAR)rfm_cell_string
INTO #rfm
FROM rfm_calc c

SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  --lost customers
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string in (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string in (323, 333,321, 422, 332, 432) THEN 'active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal'
	END rfm_segment

FROM #rfm



--WHAT PRODUCTS ARE MOST OFTEN SOLD TOGETHER? 
--SELECT * FROM [dbo].[sales_data_sample] WHERE ORDERNUMBER =  10411

SELECT DISTINCT OrderNumber, stuff(

	(SELECT ',' + PRODUCTCODE
	FROM [dbo].[sales_data_sample] p
	WHERE ORDERNUMBER in 
		(

			SELECT ORDERNUMBER
			FROM (
				SELECT ORDERNUMBER, count(*) rn
				FROM [PortfolioProject].[dbo].[sales_data_sample]
				WHERE STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			WHERE rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		FOR XML PATH (''))

		, 1, 1, '') ProductCodes

FROM [dbo].[sales_data_sample] s
ORDER BY 2 DESC


---EXTRAs----
--WHAT CITY HAS THE HIGHEST NUMBER OF SALES IN SPECIFIC COUNTRY 

SELECT city, SUM (sales) Revenue
FROM [PortfolioProject].[dbo].[sales_data_sample]                                                                                   
WHERE country = 'UK'
GROUP BY city
ORDER BY 2 DESC                                                                                                              



---WHAT IS THE BEST PRODUCT IN UNITED STATES?

SELECT country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
FROM [PortfolioProject].[dbo].[sales_data_sample]
WHERE country = 'USA'
GROUP BY  country, YEAR_ID, PRODUCTLINE
ORDER BY 4 DESC