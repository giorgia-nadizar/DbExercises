USE uni_db;


-- Query 4: quali studenti non hanno mai preso una lode?
SELECT * 
FROM studenti s
WHERE NOT EXISTS (
    SELECT *
    FROM esami e
    WHERE e.lode=TRUE AND 
    e.studente=s.matricola
);

SELECT * 
FROM studenti s
WHERE s.matricola NOT IN(
    SELECT DISTINCT studente
    FROM esami e
    WHERE e.lode=TRUE
);


-- Query 5: quali docenti svolgono un monte ore annuo minore di 120 ore?
SELECT p.nome, p.cognome, SUM(8*c.cfu) as monte_ore
FROM professori p
INNER JOIN corsi c
ON p.matricola = c.professore
GROUP BY c.professore
HAVING monte_ore<120;


-- Query 6: qual è la media ponderata di ogni studente?
SELECT s.matricola, s.nome, s.cognome, 
SUM(e.voto*c.cfu)/SUM(c.cfu) as media
FROM studenti s
INNER JOIN esami e 
ON s.matricola = e.studente
    INNER JOIN corsi c
    ON e.corso = c.codice
GROUP BY e.studente;


-- Prepared statement: creare uno statement che mostri tutti gli studenti di un corso di laurea passato come parametro
PREPARE studenti_cdl FROM
"SELECT * 
FROM studenti
WHERE matricola LIKE CONCAT(?,'%')";

SET @cdl = "IN05";
EXECUTE studenti_cdl USING @cdl;