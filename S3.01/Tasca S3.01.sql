-- Exercici 1
-- La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi "detalls crucials "
-- sobre les targetes de crèdit. La nova taula ha de ser capaç d'identificar de "manera única cada targeta" 
-- i "establir una relació adequada amb les altres dues taules" ("transaction" i "company"). Després de 
-- crear la taula serà necessari que ingressis la informació del document denominat 
-- "dades_introduir_credit".Recorda mostrar el diagrama i realitzar una breu descripció d'aquest.

CREATE TABLE credit_card (
    id VARCHAR(50) PRIMARY KEY,  -- NOT NULL UNIQUE
    iban VARCHAR(34) UNIQUE,
    pan VARCHAR(19) ,
    pin CHAR(6),
    cvv CHAR(4),
    expiring_date VARCHAR(10)
);

-- para modificar el formato de fecha a DATE primero 
-- agrego una columna llamada fecha_actual y conservo la original
ALTER TABLE credit_card
ADD COLUMN fecha_actual DATE;
-- hago la conversión de la fecha 
UPDATE credit_card
SET fecha_actual = STR_TO_DATE(expiring_date, '%m/%d/%y')
WHERE id >='0'; -- MySQL no te deja ejecutar el UPDATE sin un WHERE 
				-- cuando está activado el safe mode.
                                             
                
  -- Establezco relación 1:M entre credit_card y transaction        

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);

-- Exercici 2. El departament de Recursos Humans ha identificat un error en el número de compte associat 
-- a la targeta de crèdit amb ID CcU-2938. La informació que ha de mostrar-se per a aquest registre 
-- és: TR323456312213576817699999. Recorda mostrar que el canvi es va realitzar.

SELECT *
FROM credit_card
WHERE id = 'CcU-2938';

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT *
FROM credit_card
WHERE id = 'CcU-2938';

-- Exercici 3. En la taula "transaction" ingressa una nova transacció amb la següent informació:
-- id: 108B1D1D-5B23-A76C-55EF-C568E49A99DD
-- credit_card_id	CcU-9999
-- company_id	b-9999
-- user_id	9999
-- lat	829.999
-- longitude	-117.999
-- amount	111.11
-- declined	0
-- no es obligatorio poner fecha, pero  pondré null para que sql no de error


INSERT INTO company (id)
VALUES ('b-9999');

INSERT INTO credit_card (id)
VALUES ('CcU-9999');

-- Incerto los datos, coloco NULL en timestamp pq no me proporcionan la fecha y 
INSERT INTO transaction(id,credit_card_id,company_id,user_id,lat,longitude,timestamp ,amount,declined )
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD','CcU-9999','b-9999',9999,829.999,-117.999,NULL,111.11,0);


-- Exercici 4. Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. 
-- Recorda mostrar el canvi realitzat.

ALTER TABLE credit_card
DROP COLUMN pan;

DESCRIBE credit_card;



-- NIVEL II
-- Exercici 1. Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD 
-- de la base de dades.

SELECT id
FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

DELETE FROM transaction WHERE id ='000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Exercici 2. La secció de màrqueting desitja tenir accés a informació específica per a realitzar
-- anàlisi i estratègies efectives. S'ha sol·licitat crear una vista que proporcioni detalls clau 
-- sobre les companyies i les seves transaccions. Serà necessària que creïs una vista anomenada
-- VistaMarketing que contingui la següent informació: Nom de la companyia. Telèfon de contacte.
-- País de residència. Mitjana de compra realitzat per cada companyia. Presenta la vista creada, 
-- ordenant les dades de major a menor mitjana de compra.

CREATE VIEW VistaMarketing AS
SELECT  
c.company_name, 
c.phone,
 c.country, 
round(AVG(t.amount),2) AS media_compra -- ======ARREGLA EN EL PDF===================
FROM company c
JOIN transaction t
    ON c.id = t.company_id
WHERE t.declined = 0    
GROUP BY 
    c.company_name,
    c.phone,
    c.country;
    
SELECT *
FROM VistaMarketing
ORDER BY media_compra DESC; 


-- EXERCICI 3
SELECT *
FROM VistaMarketing
WHERE country = 'Germany'
ORDER BY media_compra DESC;


-- NIVEL III
-- La setmana vinent tindràs una nova reunió amb els gerents de màrqueting. Un company del teu 
-- equip va realitzar modificacions en la base de dades, però no recorda com les va realitzar. 
-- Et demana que l'ajudis a deixar els comandos executats per a obtenir el següent diagrama:

-- Como los datos proporcionados para introducir no coinciden con el nombre de
-- tabla del diagrama proporcionado, crearé la tabla con la misma estructura de la original y 
-- luego se realizaran los cambios para ajustarlo al diagrama
-- Creación tabla data_user
CREATE TABLE IF NOT EXISTS user (
	id int PRIMARY KEY,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(150),
	email VARCHAR(150),
	birth_date VARCHAR(100),
	country VARCHAR(150),
	city VARCHAR(150),
	postal_code VARCHAR(100),
	address VARCHAR(255)    
);

 -- cambios para hacer coincidir  on el diagrama del ejercicio
-- modificación de nombre de tabla de user a data_uswer

RENAME TABLE user TO data_user;
ALTER TABLE data_user
RENAME COLUMN email TO personal_email;

-- se hacen las modificaciones de tipo de datos y longitud  en la tabla credit_card
-- Renombrar columnas (si aplica el cambio de nombres)
ALTER TABLE credit_card
RENAME COLUMN expiration_date TO vencing_date;

-- Ajustes de tipos de datos y longitudes
ALTER TABLE credit_card
    MODIFY id VARCHAR(20),
    MODIFY iban VARCHAR(50),
    MODIFY pin VARCHAR(4),    
    MODIFY cvv INT,             
    MODIFY expiring_date VARCHAR(20),
    MODIFY fecha_actual DATE;
    
-- Validar la integridad referencial o limpiar datos erróneos, ya que en ejercicios anteriores
-- se realizaron modificaciones en las tablas.  

SELECT DISTINCT user_id
FROM transaction
WHERE user_id IS NOT NULL
AND user_id NOT IN (SELECT id FROM data_user);

-- Introducir dato huerfano en la tabla padre
insert into
data_user(id)
values('9999');

-- Crear la relación transaction → data_user (muchas transacciones por usuario)

SELECT @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_user
FOREIGN KEY (user_id)
REFERENCES data_user(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- Se debe borrar de la tabla company el campo website 
alter table company
drop column website;

-- Modificar el tipo de dato en tabla data_user
alter table data_user
modify personal_email varchar(150);

-- EXERCICI 2-L'empresa també us demana crear una vista anomenada "InformeTecnico" que 
-- contingui la següent informació:
-- ID de la transacció
-- Nom de l'usuari/ària
-- Cognom de l'usuari/ària
-- IBAN de la targeta de crèdit usada.
-- Nom de la companyia de la transacció realitzada.

-- Assegureu-vos d'incloure informació rellevant de les taules que coneixereu i utilitzeu 
-- àlies per canviar de nom columnes segons calgui.
-- Mostra els resultats de la vista, ordena els resultats de forma descendent en funció de la
-- variable ID de transacció.

CREATE VIEW InformeTecnico AS
SELECT
    t.id AS transaction_id,
    u.name AS user_name,
    u.surname AS user_surname,
    c.iban AS credit_card_iban,
    comp.company_name AS company_name
FROM transaction t
JOIN data_user u
    ON t.user_id = u.id
JOIN credit_card c
    ON t.credit_card_id = c.id
JOIN company comp
    ON t.company_id = comp.id
WHERE declined = 0;

SELECT *
FROM InformeTecnico;


