// Частина 4. Виявлення супервузлів

// Крок 1. Вузли з найбільшою кількістю ребер (топ-20)
MATCH (n)
RETURN labels(n)[0] AS label,
       coalesce(n.title, n.name, 'User ' + toString(n.userId)) AS node,
       COUNT { (n)--() } AS degree
ORDER BY degree DESC
LIMIT 20;

// Крок 2. Статистика ступенів по кожному типу вузлів
MATCH (n)
WITH labels(n)[0] AS label, COUNT { (n)--() } AS degree
RETURN label,
       count(*)                          AS nodes,
       min(degree)                       AS minDegree,
       round(avg(degree), 1)             AS avgDegree,
       percentileDisc(degree, 0.5)       AS median,
       percentileDisc(degree, 0.99)      AS p99,
       max(degree)                       AS maxDegree
ORDER BY maxDegree DESC;

// Крок 3. Жанри: кількість фільмів і оцінок через кожен жанр
MATCH (g:Genre)
RETURN g.name AS genre,
       COUNT { (g)<-[:HAS_GENRE]-(:Movie) } AS movies,
       COUNT { (g)<-[:HAS_GENRE]-(:Movie)<-[:RATED]-(:User) } AS ratingsThroughGenre
ORDER BY movies DESC;

// Крок 4. Порівняння швидкодії через PROFILE (Drama vs Film-Noir)
PROFILE
MATCH (g:Genre {name: 'Drama'})<-[:HAS_GENRE]-(:Movie)<-[r:RATED]-(:User)
RETURN count(r) AS ratings;

PROFILE
MATCH (g:Genre {name: 'Film-Noir'})<-[:HAS_GENRE]-(:Movie)<-[r:RATED]-(:User)
RETURN count(r) AS ratings;