// Частина 3. Запити різної складності

// Запит 1. Фільми жанру Thriller із середнім рейтингом вище 4.0
MATCH (g:Genre {name: 'Thriller'})<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-(:User)
WITH m, avg(r.rating) AS avgRating, count(r) AS ratingsCount
WHERE avgRating > 4.0
RETURN m.title AS title,
       m.year AS year,
       round(avgRating, 2) AS avgRating,
       ratingsCount
ORDER BY avgRating DESC, ratingsCount DESC;

// Запит 2. Користувачі, які поставили оцінку 5 більш ніж 50 фільмам
MATCH (u:User)-[r:RATED]->(:Movie)
WHERE r.rating = 5
WITH u, count(r) AS fiveStarCount
WHERE fiveStarCount > 50
RETURN u.userId AS userId,
       u.gender AS gender,
       u.age AS age,
       fiveStarCount
ORDER BY fiveStarCount DESC;

// Запит 3. Фільми, які обидва користувачі (userId=1 і userId=2) оцінили високо (>= 4)
MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title AS title,
       m.year AS year,
       r1.rating AS user1Rating,
       r2.rating AS user2Rating
ORDER BY m.title;

// Запит 4. Жанри, чиї фільми стабільно отримують високі оцінки
MATCH (g:Genre)<-[:HAS_GENRE]-(:Movie)<-[r:RATED]-(:User)
WITH g,
     avg(r.rating) AS avgRating,
     count(r) AS ratingsCount,
     stDev(r.rating) AS stdDev,
     sum(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) AS highCount
RETURN g.name AS genre,
       round(avgRating, 2) AS avgRating,
       ratingsCount,
       round(stdDev, 2) AS stdDev,
       round(100.0 * highCount / ratingsCount, 1) AS highPercent
ORDER BY avgRating DESC;

// Запит 5. Рекомендації для користувача 1 ("схожі користувачі також дивилися")
MATCH (target:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(other:User)
WHERE r1.rating >= 4 AND r2.rating >= 4
WITH target, other, count(m) AS commonLiked
ORDER BY commonLiked DESC
LIMIT 50
MATCH (other)-[r3:RATED]->(rec:Movie)
WHERE r3.rating >= 4
  AND NOT EXISTS { (target)-[:RATED]->(rec) }
WITH rec, count(DISTINCT other) AS recommenders, avg(r3.rating) AS avgRating
RETURN rec.title AS title,
       rec.year AS year,
       recommenders,
       round(avgRating, 2) AS avgRating
ORDER BY recommenders DESC, avgRating DESC
LIMIT 10;

// Запит 6. Найкоротший ланцюжок між двома користувачами через спільні фільми
MATCH (u1:User {userId: 1}), (u2:User {userId: 2})
MATCH p = shortestPath((u1)-[:RATED*..10]-(u2))
RETURN [n IN nodes(p) | coalesce(n.title, 'User ' + toString(n.userId))] AS chain,
       length(p) AS pathLength;
