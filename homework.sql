USE uni_db;


-- Query 1: quali prof. hanno una media voti più bassa del normale agli esami?
SELECT c.professore, AVG(e.voto) as media
FROM esami e
INNER JOIN corsi c
ON e.corso = c.codice
GROUP BY c.professore
HAVING media < (
SELECT AVG(voto)
FROM esami);


-- Query 2: quanti esami sono stati svolti per ciascun anno? E per ciascun mese dell'anno?
SELECT YEAR(e.data) as anno, COUNT(*)
FROM esami e
GROUP BY anno
ORDER BY anno;

SELECT MONTH(e.data) as mese, COUNT(*)
FROM esami e
GROUP BY mese
ORDER BY mese;


-- Query 3: ci sono casi di omonimia (nome e cognome uguale) tra studenti e/o professori?
SELECT nome, cognome, COUNT(*) AS c
FROM (SELECT nome, cognome
FROM studenti
UNION ALL
SELECT nome, cognome
FROM professori) AS t
GROUP BY nome, cognome
ORDER BY c DESC;


-- Query 4: quanti studenti e professori ci sono con lo stesso nome? (es. 9 persone si chiamano Luca, 11 si chiamano Matteo, ...)
SELECT nome, COUNT(*) AS c
FROM (SELECT nome
FROM studenti
UNION ALL
SELECT nome
FROM professori) AS t
GROUP BY nome
ORDER BY c DESC;


-- Prepared Statement 1: creare uno statement che mostri tutti gli esami (con voto e nome del corso) di uno studente passato come parametro 
-- (come parametro ci aspettiamo la matricola dello studente)
PREPARE esami_con_voto FROM
"SELECT e.corso, c.nome, e.data, e.voto, e.lode
FROM esami e
INNER JOIN corsi c
ON e.corso = c.codice
WHERE e.studente = ?";


-- Prepared Statement 2: creare uno statement che restituisca la media aritmetica e la media ponderata degli esami sostenuti in un determinato mese 
-- di un determinato anno (mese ed anno sono passati come parametri)
PREPARE media_esami_mese_anno FROM
"SELECT SUM(e.voto*c.cfu)/SUM(c.cfu) as mp,
AVG(e.voto) as ma
FROM esami e 
INNER JOIN corsi c ON e.corso = c.codice
WHERE MONTH(e.data)=? AND YEAR(e.data)=?";


-- Prepared Statement 3: creare uno statement che restituisca tutti gli studenti (nome, cognome e matricola) che hanno sostenuto l'esame di un dato 
-- corso (passato come parametro, tramite codice)
PREPARE studenti_superato_corso FROM
"SELECT s.nome, s.cognome, s.matricola
FROM studenti s
INNER JOIN esami e
ON s.matricola = e.studente
WHERE e.corso=?";


-- Query Complesse 1: quali sono i voti preferiti di ogni professore?
CREATE VIEW dist_voti AS
SELECT p.matricola, p.nome, p.cognome, e.voto,
    COUNT(e.voto) as n_voti
FROM professori p
INNER JOIN corsi c ON p.matricola=c.professore
    INNER JOIN esami e ON c.codice=e.corso
GROUP BY p.matricola, e.voto;

SELECT DISTINCT matricola, nome, cognome, voto
FROM dist_voti d1
WHERE n_voti=(
    SELECT MAX(n_voti)
    FROM dist_voti d2
    WHERE d1.matricola=d2.matricola
);


-- Query Complesse 2: quali sono gli studenti più bravi di ogni corso di laurea?
CREATE VIEW bravura_per_cdl AS
SELECT s.matricola, s.nome, s.cognome, 
    SUBSTRING(s.matricola,1,4) as cdl,
    SUM(e.voto*c.cfu) as bravura
FROM studenti s
INNER JOIN esami e ON s.matricola=e.studente
    INNER JOIN corsi c ON e.corso=c.codice
GROUP BY s.matricola;

SELECT DISTINCT matricola, nome, cognome, cdl
FROM bravura_per_cdl b1
WHERE bravura=(
    SELECT MAX(bravura)
    FROM bravura_per_cdl b2
    WHERE b1.cdl=b2.cdl
);


-- Query Complesse 3: quali studenti hanno migliorato almeno una volta la loro media nel corso della loro carriera universitaria?
CREATE VIEW media_per_anno AS
SELECT s.matricola, s.nome, s.cognome, 
SUM(e.voto*c.cfu)/SUM(c.cfu) as media, YEAR(e.data) as anno
FROM studenti s
INNER JOIN esami e 
ON s.matricola = e.studente
    INNER JOIN corsi c
    ON e.corso = c.codice
GROUP BY e.studente, anno;

SELECT DISTINCT matricola, nome, cognome
FROM media_per_anno m1
WHERE m1.media > (
	SELECT MIN(media)
    FROM media_per_anno m2
    WHERE m1.matricola=m2.matricola AND
    m1.anno > m2.anno
);