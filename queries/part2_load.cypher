// Частина 2. Завантаження MovieLens 1M у Neo4j

// 1. Користувачі
LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);

// 2. Фільми
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title,
    m.year = toInteger(substring(row.title, size(row.title) - 5, 4));

// 3. Жанри
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
UNWIND split(row.genres, '|') AS genreName
WITH DISTINCT genreName
MERGE (:Genre {name: genreName});

// 4. Індекси та обмеження унікальності (створюємо до ребер)
CREATE CONSTRAINT user_id IF NOT EXISTS
FOR (u:User) REQUIRE u.userId IS UNIQUE;

CREATE CONSTRAINT movie_id IF NOT EXISTS
FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;

CREATE CONSTRAINT genre_name IF NOT EXISTS
FOR (g:Genre) REQUIRE g.name IS UNIQUE;

CREATE INDEX movie_title IF NOT EXISTS
FOR (m:Movie) ON (m.title);

SHOW INDEXES;

// 5. Ребра Фільм -> Жанр
LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MATCH (m:Movie {movieId: toInteger(row.movieId)})
UNWIND split(row.genres, '|') AS genreName
MATCH (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

// 6. Ребра User -> Movie (оцінки) батчами по 10 000
CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
  "MATCH (u:User  {userId:  toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   MERGE (u)-[r:RATED]->(m)
   SET r.rating = toInteger(row.rating),
       r.timestamp = toInteger(row.timestamp)",
  {batchSize: 10000, parallel: false}
)
YIELD batches, total, timeTaken, committedOperations, failedOperations, errorMessages
RETURN batches, total, timeTaken, committedOperations, failedOperations, errorMessages;

// 7. Перевірка кількості завантажених даних
MATCH (u:User) RETURN count(u) AS users;
MATCH (m:Movie) RETURN count(m) AS movies;
MATCH ()-[r:RATED]->() RETURN count(r) AS ratings;
MATCH (g:Genre) RETURN count(g) AS genres;
MATCH ()-[h:HAS_GENRE]->() RETURN count(h) AS hasGenre;
MATCH (m:Movie) WHERE m.year IS NULL RETURN count(m) AS moviesWithoutYear;

// 8. Візуалізація графа для користувача 1
MATCH (u:User {userId: 1})-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
RETURN u, r, m, g LIMIT 25;