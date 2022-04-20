
CREATE VIEW [dbo].[analytics_main] as

SELECT s.set_num, s.NAME AS set_name, s.year, s.theme_id, CAST(s.num_parts AS NUMERIC) num_parts, t.NAME AS theme_name, t.parent_id, p.NAME AS parent_theme_name,
case 
	WHEN s.year between 1901 and 2000 THEN '20th_Century'
	WHEN s.year between 2001 and 2100 THEN '21st_Century'
END
AS Century
FROM dbo.SETS s
left join [dbo].[themes] t
	on s.theme_id = t.id
left join [dbo].[themes] p
	ON t.parent_id = p.id
GO




---1---
---What is the total number of parts per theme
--SELECT * from dbo.analytics_main


SELECT theme_name, sum(num_parts) AS total_num_parts 
FROM dbo.analytics_main
--where parent_theme_name is not null
GROUP BY theme_name
ORDER BY 2 DESC


---2---
---What is the total number of parts per year

SELECT year, sum(num_parts) AS total_num_parts 
FROM dbo.analytics_main
WHERE parent_theme_name is not null
GROUP BY year
ORDER BY 2 DESC


---3---
--- How many sets where created in each Century in the dataset

SELECT Century, count(set_num) AS total_set_num
FROM dbo.analytics_main
---where parent_theme_name is not null
GROUP BY Century



---4---
--- What percentage of sets ever released in the 21st Century were Trains Themed 

;WITH cte AS 
(
	SELECT Century, theme_name, count(set_num) total_set_num
	FROM analytics_main
	WHERE Century = '21st_Century'
	GROUP BY Century, theme_name
)
SELECT SUM(total_set_num), SUM(percentage)
FROM(
	SELECT Century, theme_name, total_set_num, SUM(total_set_num) OVER() AS total,  CAST(1.00 * total_set_num / SUM(total_set_num) OVER() AS DECIMAL(5,4))*100 PERCENTAGE
	FROM cte	
	--order by 3 desc
	)m
WHERE theme_name like '%Star wars%'



--- 5 ---
--- What was the popular theme by year in terms of sets released in the 21st Century

SELECT year, theme_name, total_set_num
FROM (
	SELECT year, theme_name, count(set_num) total_set_num, ROW_NUMBER() OVER (PARTITION BY year ORDER BY count(set_num) DESC) rn
	FROM analytics_main
	WHERE Century = '21st_Century'
		--and parent_theme_name is not null
	GROUP BY year, theme_name
)m
WHERE rn = 1	
ORDER BY year DESC



---6---
---What is the most produced color of lego ever in terms of quantity of parts?

SELECT color_name, SUM(quantity) AS quantity_of_parts
FROM 
	(
		SELECT
			inv.color_id, inv.inventory_id, inv.part_num, cast(inv.quantity AS NUMERIC) quantity, inv.is_spare, c.name as color_name, c.rgb, p.name as part_name, p.part_material, pc.name as category_name
		FROM inventory_parts inv
		INNER JOIN colors c
			ON inv.color_id = c.id
		INNER JOIN parts p
			ON inv.part_num = p.part_num
		INNER JOIN part_categories pc
			ON part_cat_id = pc.id
	)main

GROUP BY color_name
ORDER BY 2 desc
