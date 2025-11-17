-- Exercici 2. Utilitzant JOIN realitzaràs les següents consultes:
-- Llistat dels països que estan generant vendes.

SELECT DISTINCT country
FROM company AS c
JOIN transaction AS t
ON t.company_id = c.id 
WHERE t.declined = 0;

-- Des de quants països es generen les vendes.
SELECT count(DISTINCT country) AS num_paises
FROM company AS c
JOIN transaction AS t
ON t.company_id = c.id 
WHERE t.declined = 0;

-- Identifica la companyia amb la mitjana més gran de vendes.

SELECT  c.id,  c.company_name,ROUND(AVG(t.amount),2) AS promedio
FROM company AS c
JOIN transaction AS t
ON t.company_id = c.id 
WHERE t.declined = 0
GROUP BY c.id, c.company_name
ORDER BY promedio DESC
LIMIT 1;

-- Exercici 3. Utilitzant només subconsultes (sense utilitzar JOIN):
-- Mostra totes les transaccions realitzades per empreses d'Alemanya.

SELECT *
FROM transaction as t
WHERE  t.declined = 0 AND t.company_id IN (SELECT id 
                                           FROM company 
                                           WHERE country = 'Germany'
                                           );

-- Llista les empreses que han rea litzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT id, company_name
FROM company as c
WHERE EXISTS (SELECT 1
              FROM transaction as t 
              WHERE c.id = t.company_id
              AND t.declined = 0
              AND t.amount > (SELECT AVG(amount)
							 FROM transaction));


-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.


SELECT id, company_name
FROM company AS c
WHERE  NOT EXISTS(SELECT 1 
                 FROM transaction AS t 
				 WHERE t.declined = 0  AND c.id = t.company_id 
			     );
                 
               
-- Nivell 2
-- Exercici 1.Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a 
-- l'empresa per vendes. Mostra la data de cada transacció juntament amb el total de les vendes.



SELECT DATE(timestamp),sum(amount) AS Total_ventas
FROM transaction AS t
WHERE t.declined = 0
GROUP BY DATE(timestamp)
ORDER BY Total_ventas DESC
LIMIT 5;


-- Exercici 2
-- Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.

SELECT country, ROUND(AVG(amount),2) AS promedio_ventas
FROM transaction AS t
JOIN company AS c 
ON c.id= t.company_id
WHERE t.declined = 0
GROUP BY country 
ORDER BY promedio_ventas DESC;


-- Exercici 3.En la teva empresa, es planteja un nou projecte per a llançar algunes 
-- campanyes publicitàries per a fer competència a la companyia "Non Institute".
-- Per a això, et demanen la llista de totes les transaccions realitzades per empreses que 
-- estan situades en el mateix país que aquesta companyia.

-- Mostra el llistat aplicant JOIN i subconsultes.

SELECT DISTINCT t.*
FROM transaction t
JOIN company c
ON c.id = t.company_id
WHERE c. company_name <> "Non Institute" 
AND t.declined = 0 
AND country = (SELECT country
			   FROM company 
			   WHERE company_name= "Non Institute"
     );

-- Mostra el llistat aplicant solament subconsultes.


SELECT  *
FROM transaction t
WHERE t.declined = 0
AND EXISTS(SELECT 1
		     FROM company c 
		     WHERE c.id = t.company_id 
             AND c.country = (SELECT country 
							  FROM company c 
							  WHERE company_name= "Non Institute")
);
            
-- Nivell 3.
-- Exercici 1. Presenta el nom, telèfon, país, data i amount, d'aquelles empreses 
-- que van realitzar transaccions amb un valor comprès entre 350 i 400 euros i en alguna 
-- d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
-- Ordena els resultats de major a menor quantitat.

SELECT c.company_name,c.phone,c.country,t.timestamp,t.amount
FROM company c
JOIN transaction t
ON c.id = t.company_id
WHERE t.declined = 0 AND t.amount BETWEEN 350 AND 400
AND DATE(timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13') 
ORDER BY  t.amount DESC;

-- Exercici 2. Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat
-- operativa que es requereixi, per la qual cosa et demanen la informació sobre la quantitat 
-- de transaccions que realitzen les empreses, però el departament de recursos humans és exigent 
-- i vol un llistat de les empreses on especifiquis si tenen més de 400 transaccions o menys. 

SELECT
      c.company_name, 
      t.company_id, 
      count(t.company_id) as num_transacciones,
	CASE
		  WHEN count(t.company_id) >=400 THEN 'Mayor de 400 transacciones'
		  ELSE 'Menos de 400 transacciones'
	  END AS Volumen_transacciones
FROM company c
LEFT JOIN transaction t
ON  c.id = t.company_id
WHERE t.declined = 0
GROUP BY  t.company_id,c.company_name
ORDER BY   count(t.company_id) DESC;

