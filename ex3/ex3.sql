USE uni_db;


-- Transazione: scrivere una transazione che assegni al prof.\ meno impegnato l'unico corso scoperto
START TRANSACTION;

SELECT @prof := matricola, sum(cfu) as cfu_tot
FROM professori p 
INNER JOIN corsi c 
ON c.professore=p.matricola
GROUP BY professore
ORDER BY cfu_tot asc
LIMIT 1;

UPDATE corsi
SET professore = @prof
WHERE professore IS NULL;

COMMIT;


-- Stored Procedure 1: scrivere una stored procedure che restituisca le medie ponderate ed aritmetiche di tutti gli studenti
DELIMITER $$
CREATE PROCEDURE CalcoloMedie()
BEGIN
	SELECT s.matricola, s.nome, s.cognome, 
	SUM(e.voto*c.cfu)/SUM(c.cfu) as mp,
	AVG(e.voto) as ma
	FROM studenti s INNER JOIN esami e 
	ON s.matricola = e.studente
		INNER JOIN corsi c ON e.corso = c.codice
	GROUP BY e.studente;
END $$
DELIMITER ;


-- Stored Procedure 2: scrivere una stored procedure che restituisca gli studenti con la media superiore ad un dato voto
DELIMITER $$
CREATE PROCEDURE StudentiConMediaSopraSoglia(IN soglia INT)
BEGIN
	SELECT s.matricola, s.nome, s.cognome, 
	SUM(e.voto*c.cfu)/SUM(c.cfu) as mp
	FROM studenti s
	INNER JOIN esami e ON s.matricola = e.studente
	INNER JOIN corsi c ON e.corso = c.codice
	GROUP BY e.studente HAVING mp >= soglia;
END $$
DELIMITER ;


-- Stored Procedure 3: scrivere una stored procedure che restituisca in una variabile passata il numero di studenti che hanno sostenuto almeno un esame
DELIMITER $$
CREATE PROCEDURE NStudentiConEsami(OUT numero INT)
BEGIN
	SELECT COUNT(DISTINCT matricola)
    INTO numero
    FROM studenti s
    INNER JOIN esami e
    ON s.matricola = e.studente;
END $$
DELIMITER ;


-- Stored Procedure 4: scrivere na stored procedure che restituisca in una variabile passata il monte di ore di un dato docente 
-- (se il docente non esiste bisogna lanciare un errore)
DELIMITER $$
CREATE PROCEDURE MonteOre(IN docente INT, OUT ore INT)
BEGIN
	SELECT SUM(cfu*8)
    INTO ore
    FROM corsi c
    WHERE professore=docente;
    IF ore IS NULL THEN
        SIGNAL SQLSTATE "02000"
        SET MESSAGE_TEXT = "Docente not found!";
    END IF;
END $$
DELIMITER ;
