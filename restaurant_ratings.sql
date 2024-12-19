/*Purpose: To use as the benchmark for evaluating restaurant ratings*/
/*Overview of the dataset?*/
SELECT COUNT(*) AS count_rating
, COUNT(DISTINCT consumer_id) AS count_consumer
, COUNT(DISTINCT restaurant_id) AS count_restaurant
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(AVG(food_rating),2) AS food_rating
, ROUND(AVG(service_rating),2) AS service_rating
FROM db.ratings
;

/*Purpose: To evaluate the impact of consumer demographics on the bias of the ratings*/
/*What are the consumer range of ages*/
SELECT COUNT(*) AS count_consumer
, ROUND(AVG (age)) AS avg_age
, MIN(age) AS min_age
, MAX(age) AS max_age
/*, PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY age) AS median_age*/
FROM db.consumers
;
SELECT CASE 
	WHEN age BETWEEN 18 AND 30 THEN '17 - 30' 
	WHEN age BETWEEN 31 AND 45 THEN '31 - 45' 
    WHEN age BETWEEN 46 AND 60 THEN '46 - 60'
    ELSE 'Above 60' END AS age_group
, COUNT(consumer_id) AS count_consumer
FROM db.consumers
GROUP BY age_group
ORDER BY age_group
;
/*What are consumer budget*/
SELECT CASE WHEN budget ='' THEN 'Unknown' ELSE budget END AS budget
, COUNT(*) AS count_consumer
, ROUND(AVG(overall_rating),2) AS overall_rating
FROM db.consumers con
LEFT JOIN db.ratings ra 
ON con.consumer_id=ra.consumer_id
GROUP BY budget
ORDER BY count_consumer DESC
;
/*What are the consumer occupation <> budget?*/
SELECT CASE WHEN occupation='' THEN 'Unknown' ELSE occupation END AS occupation
, SUM(CASE WHEN budget='High' THEN 1 ELSE 0 END) AS high_budget
, SUM(CASE WHEN budget='Medium' THEN 1 ELSE 0 END) AS medium_budget
, SUM(CASE WHEN budget='Low' THEN 1 ELSE 0 END) AS low_budget
, SUM(CASE WHEN budget='' THEN 1 ELSE 0 END) AS unknown_budget
FROM db.consumers
GROUP BY occupation
;
/*Where do the majority of consumers and restaurants locate in*/
SELECT DISTINCT con.city 
, COUNT(DISTINCT consumer_id) AS count_consumer
, COUNT(DISTINCT restaurant_id) AS count_restaurant
FROM db.consumers con
LEFT JOIN db.restaurants re
ON con.city=re.city
GROUP BY con.city
ORDER BY count_consumer DESC
;


/*Purpose: Choosing a restaurant type to invest in*/
/*Top 5 restaurants by ratings*/
SELECT re.name 
, COALESCE(cu.cuisine,'Unknown') AS cuisine
, re.city
, re.price
, COUNT(DISTINCT(consumer_id)) AS count_rating
FROM db.ratings ra
LEFT JOIN db.restaurants re
ON ra.restaurant_id=re.restaurant_id
LEFT JOIN db.restaurant_cuisines cu
ON ra.restaurant_id=cu.restaurant_id
GROUP BY 1,2,3,4
ORDER BY count_rating DESC
LIMIT 5
;
/*Top 5 restaurants by overall ratings where number of ratings is more than 10*/
SELECT re.name 
, COALESCE(cu.cuisine,'Unknown') AS cuisine
, re.city
, re.price
, COUNT(DISTINCT(consumer_id)) AS count_rating
, ROUND(AVG(overall_rating),2) AS overall_rating
FROM db.ratings ra
LEFT JOIN db.restaurants re
ON ra.restaurant_id=re.restaurant_id
LEFT JOIN db.restaurant_cuisines cu
ON ra.restaurant_id=cu.restaurant_id
GROUP BY 1,2,3,4
HAVING count_rating >=10
ORDER BY overall_rating DESC
LIMIT 5
;
/*Details and ratings restaurants order by overall ratings*/
WITH restaurant_rating AS (
	SELECT ra.restaurant_id
	, re.name 
	, COALESCE(cu.cuisine,'Unknown') AS cuisine
	, re.city
	, re.state
	, re.alcohol_service
	, re.smoking_allowed
	, re.price
	, re.franchise
	, re.area
	, re.parking
	, COUNT(DISTINCT(consumer_id)) AS count_rating
	, ROUND(AVG(overall_rating),2) AS overall_rating
	, ROUND(AVG(food_rating),2) AS food_rating
	, ROUND(AVG(service_rating),2) AS service_rating
    , ROUND(SUM(CASE WHEN overall_rating=2 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),2) AS share_of_2
	, ROUND(SUM(CASE WHEN overall_rating=0 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),2) AS share_of_0
	FROM db.ratings ra
	LEFT JOIN db.restaurants re
	ON ra.restaurant_id=re.restaurant_id
	LEFT JOIN db.restaurant_cuisines cu
	ON ra.restaurant_id=cu.restaurant_id
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11
	ORDER BY count_rating DESC
	)
/* Purpose: To determine scalability
What is the performance of franchise vs non-franchise restaurants?*/
SELECT franchise
, SUM(count_rating) AS count_rating
, COUNT(*) AS count_restaurant
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(AVG(food_rating),2) AS food_rating
, ROUND(AVG(service_rating),2) AS service_rating
FROM restaurant_rating rera
GROUP BY franchise
ORDER BY overall_rating DESC
;
/*Purpose: To evaluate which factors have impact on customer ratings*/
/*Top 5 preferred cuisines, number of restaurants and ratings?*/
SELECT DISTINCT cu.cuisine
, COUNT(DISTINCT ra.restaurant_id) AS count_restaurant
, COUNT(*) AS count_rating
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(AVG(food_rating),2) AS food_rating
, ROUND(AVG(service_rating),2) AS service_rating
, ROUND(SUM(CASE WHEN overall_rating=2 THEN 1 ELSE 0 END)/COUNT(*),2) AS share_of_2
, ROUND(SUM(CASE WHEN overall_rating=0 THEN 1 ELSE 0 END)/COUNT(*),2) AS share_of_0
FROM db.restaurant_cuisines cu
LEFT JOIN db.ratings ra
ON cu.restaurant_id=ra.restaurant_id
GROUP BY 1
ORDER BY count_rating DESC
LIMIT 5
/*Top 5 cuisines by overall ratings?*/
SELECT DISTINCT cu.cuisine
, COUNT(DISTINCT ra.restaurant_id) AS count_restaurant
, COUNT(*) AS count_rating
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(AVG(food_rating),2) AS food_rating
, ROUND(AVG(service_rating),2) AS service_rating
, ROUND(SUM(CASE WHEN overall_rating=2 THEN 1 ELSE 0 END)/COUNT(*),2) AS share_of_2
, ROUND(SUM(CASE WHEN overall_rating=0 THEN 1 ELSE 0 END)/COUNT(*),2) AS share_of_0
FROM db.restaurant_cuisines cu
LEFT JOIN db.ratings ra
ON cu.restaurant_id=ra.restaurant_id
GROUP BY 1
ORDER BY overall_rating DESC
LIMIT 5
;
/*Does price impact restaurant ratings?*/   
SELECT price
, COUNT(DISTINCT re.restaurant_id) AS count_restaurant
, COUNT(*) AS count_rating
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(AVG(food_rating),2) AS food_rating
, ROUND(AVG(service_rating),2) AS service_rating
FROM db.restaurants re
LEFT JOIN db.ratings ra 
ON re.restaurant_id=ra.restaurant_id
GROUP BY price
ORDER BY overall_rating DESC
;
/*Does restaurant prices impact customers ratings based on their budget?
Option 1: Calculated with CTE*/
WITH price_budget AS (
	SELECT price
	, SUM(CASE WHEN budget='High' THEN 1 ELSE 0 END) AS count_high_budget
	, SUM(CASE WHEN budget='Medium' THEN 1 ELSE 0 END) AS count_medium_budget
	, SUM(CASE WHEN budget='Low' THEN 1 ELSE 0 END) AS count_low_budget
	, SUM(CASE WHEN budget='' THEN 1 ELSE 0 END) AS count_unknown_budget
	FROM db.restaurants re
	LEFT JOIN db.ratings ra 
	ON ra.restaurant_id=re.restaurant_id
	LEFT JOIN db.consumers con
	ON con.consumer_id=ra.consumer_id
	GROUP BY price
    )
SELECT re.price
, COUNT(ra.consumer_id) AS count_rating
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(SUM(CASE WHEN budget='High' THEN overall_rating ELSE 0 END)/MAX(count_high_budget),2) AS high_budget_rating
, ROUND(SUM(CASE WHEN budget='Medium' THEN overall_rating ELSE 0 END)/MAX(count_medium_budget),2) AS medium_budget_rating
, ROUND(SUM(CASE WHEN budget='Low' THEN overall_rating ELSE 0 END)/MAX(count_low_budget),2) AS low_budget_rating
, ROUND(SUM(CASE WHEN budget='' THEN overall_rating ELSE 0 END)/MAX(count_unknown_budget),2) AS unknown_budget_rating
FROM db.restaurants re
LEFT JOIN db.ratings ra 
ON ra.restaurant_id=re.restaurant_id
LEFT JOIN db.consumers con
ON con.consumer_id=ra.consumer_id
LEFT JOIN price_budget pr
ON pr.price=re.price
GROUP BY re.price
;
/*Option 2: Calculated without CTE*/
SELECT price
, SUM(CASE WHEN budget='High' THEN 1 ELSE 0 END) AS count_high_budget
, SUM(CASE WHEN budget='Medium' THEN 1 ELSE 0 END) AS count_medium_budget
, SUM(CASE WHEN budget='Low' THEN 1 ELSE 0 END) AS count_low_budget
, SUM(CASE WHEN budget='' THEN 1 ELSE 0 END) AS count_unknown_budget
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(SUM(CASE WHEN budget='High' THEN overall_rating ELSE 0 END)/SUM(CASE WHEN budget='High' THEN 1 ELSE 0 END),2) AS high_budget_rating
, ROUND(SUM(CASE WHEN budget='Medium' THEN overall_rating ELSE 0 END)/SUM(CASE WHEN budget='Medium' THEN 1 ELSE 0 END),2) AS medium_budget_rating
, ROUND(SUM(CASE WHEN budget='Low' THEN overall_rating ELSE 0 END)/SUM(CASE WHEN budget='Low' THEN 1 ELSE 0 END),2) AS low_budget_rating
, ROUND(SUM(CASE WHEN budget='' THEN overall_rating ELSE 0 END)/SUM(CASE WHEN budget='' THEN 1 ELSE 0 END),2) AS unknown_budget_rating	
FROM db.restaurants re
LEFT JOIN db.ratings ra 
ON ra.restaurant_id=re.restaurant_id
LEFT JOIN db.consumers con
ON con.consumer_id=ra.consumer_id
GROUP BY price
;
/*To test recommendations: If we want to focus on San Luis potosi, how many restaurant are there and what is the split?*/
SELECT DISTINCT cu.cuisine
, COUNT(DISTINCT ra.restaurant_id) AS count_restaurant
, COUNT(*) AS count_rating
, ROUND(AVG(overall_rating),2) AS overall_rating
, ROUND(AVG(food_rating),2) AS food_rating
, ROUND(AVG(service_rating),2) AS service_rating
, ROUND(SUM(CASE WHEN overall_rating=2 THEN 1 ELSE 0 END)/COUNT(*),2) AS share_of_2
, ROUND(SUM(CASE WHEN overall_rating=0 THEN 1 ELSE 0 END)/COUNT(*),2) AS share_of_0
FROM db.restaurant_cuisines cu
LEFT JOIN db.ratings ra
ON cu.restaurant_id=ra.restaurant_id
LEFT JOIN db.restaurants re
ON ra.restaurant_id=ra.restaurant_id
WHERE re.city='San Luis Potosi'
GROUP BY 1
ORDER BY overall_rating DESC, count_rating DESC
;