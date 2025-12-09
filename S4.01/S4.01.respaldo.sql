/*======================Creación database======================*/
-- 
CREATE DATABASE financial_dw;
USE financial_dw;

/* ============== Creación table de dimensiones ==============*/

-- (id,name,surname,phone,email,birth_date,country,city,postal_code,address) primera fila csv

CREATE TABLE DIM_USER (
    id      INT PRIMARY KEY,
    name         VARCHAR(100),
    surname      VARCHAR(100),
    phone        VARCHAR(50),
    email        VARCHAR(150),
    birth_date   VARCHAR(30),    --  como texto para no complicar con formatos
    country      VARCHAR(100),
    city         VARCHAR(100),
    postal_code  VARCHAR(20),
    address      VARCHAR(255)
);

/*====================== DIM_COMPANY (companies.csv) ===================*/

/*(company_id, company_name, phone, email, country, website)*/

CREATE TABLE DIM_COMPANY (
    company_id    VARCHAR(10) PRIMARY KEY,   -- ej: b-2222
    company_name  VARCHAR(150),
    phone         VARCHAR(50),
    email         VARCHAR(150),
    country       VARCHAR(100),
    website       VARCHAR(255)
);

/* =======================DIM_CREDIT_CARD (credit_cards.csv)======================

/* Columnas Presentes primera fila csv
(id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date) */

CREATE TABLE DIM_CREDIT_CARD (
    id        	   VARCHAR(20) PRIMARY KEY,   -- ej: CcU-2938
    user_id        INT,                       -- se relaciona con DIM_USER
    iban           VARCHAR(50),
    pan            VARCHAR(50),
    pin            VARCHAR(10),
    cvv            INT,
    track1         VARCHAR(255),
    track2         VARCHAR(255),
    expiring_date  VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES DIM_USER(id)
);


/* Nota: las tarjetas no se enlazan por card_id con FACT (porque en FACT vienen otros códigos), 
pero sí se pueden enlazar por user_id cuando necesites IBAN + transacciones.*/



/*================DIM_PRODUCT (products.csv)============================
 Columnas oresentes primera fila csv
(id, product_name, price, colour, weight, warehouse_id)*/

CREATE TABLE DIM_PRODUCT (
    product_id     INT PRIMARY KEY,
    product_name   VARCHAR(150),
    price          VARCHAR(20),    -- viene con símbolo $, lo dejamos como texto
    colour         VARCHAR(10),
    weight         DECIMAL(10,2),
    warehouse_id   VARCHAR(20)
);

################ Tabla de HECHOS: FACT_TRANSACTIONS (transactions.csv) ################
/*Columnas reales en transactions.csv (separador ;):
id;card_id;business_id;timestamp;amount;declined;product_ids;user_id;lat;longitude
*/
-- Diseño FACT:

/*transaction_id = id

business_id → se relaciona con DIM_COMPANY.company_id

user_id → se relaciona con DIM_USER.user_id

card_id →se relaciona con DIM_USER.id

product_ids lo dejamos como texto (puede contener varios productos)*/

CREATE TABLE FACT_TRANSACTIONS (
    transaction_id  CHAR(36) PRIMARY KEY,   -- ej: CDDA7E40-544D-47BB-A4ED-671DD8A950D9
    card_id         VARCHAR(20),           -- CcS-6894 (no FK, solo atributo)
    business_id     VARCHAR(10),           -- FK hacia DIM_COMPANY
    timestamp       DATETIME,              -- '2018-12-12 08:05:17'
    amount          DECIMAL(10,2),
    declined        TINYINT,               -- 0 o 1
    product_ids     VARCHAR(255),          -- puede contener varios ids: '75, 73, 98'
    user_id         INT,                   -- FK hacia DIM_USER
    lat             VARCHAR(50),
    longitude       VARCHAR(50),
    FOREIGN KEY (business_id) REFERENCES DIM_COMPANY(company_id),
    FOREIGN KEY (user_id)     REFERENCES DIM_USER(id),
    FOREIGN KEY (card_id)      REFERENCES DIM_CREDIT_CARD(id)
);


/*=================================================
-- Cargar los CSV con LOAD DATA LOCAL INFILE
--  Activar antes código sql para importar:
===================================================*/
SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE 'local_infile';

-- Cargar american_users en DIM_USER

LOAD DATA LOCAL INFILE 'C:\\Ana_CDPY\\Especializacion\\S4.01\\american_users.csv'
INTO TABLE DIM_USER
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, birth_date, country, city, postal_code, address);

-- Cargar european_users en la MISMA tabla DIM_USER

LOAD DATA LOCAL INFILE "C:\\Ana_CDPY\\Especializacion\\S4.01\\european_users.csv"
INTO TABLE DIM_USER
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, name, surname, phone, email, birth_date, country, city, postal_code, address);

-- Cargar DIM_COMPANY

LOAD DATA LOCAL INFILE "C:\\Ana_CDPY\\Especializacion\\S4.01\\companies.csv"
INTO TABLE DIM_COMPANY
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(company_id, company_name, phone, email, country, website);

--  Cargar DIM_CREDIT_CARD

LOAD DATA LOCAL INFILE "C:\\Ana_CDPY\\Especializacion\\S4.01\\credit_cards.csv"
INTO TABLE DIM_CREDIT_CARD
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date);



-- Cargar DIM_PRODUCT

LOAD DATA LOCAL INFILE "C:\\Ana_CDPY\\Especializacion\\S4.01\\products.csv"
INTO TABLE DIM_PRODUCT
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, product_name, price, colour, weight, warehouse_id);

-- Cargar FACT_TRANSACTIONS (OJO: separador ;)

LOAD DATA LOCAL INFILE "C:\\Ana_CDPY\\Especializacion\\S4.01\\transactions.csv"
INTO TABLE FACT_TRANSACTIONS
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(transaction_id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude);



/*=============================================TABLA PUENTE==============================================================*/      
	CREATE TABLE fact_transaction_products (
    transaction_id CHAR(36) NOT NULL,
    product_id INT NOT NULL,
    PRIMARY KEY (transaction_id, product_id),
    FOREIGN KEY (transaction_id) REFERENCES fact_transactions(transaction_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);
-- Poblar la tabla puente usando JSON_TABLE
INSERT INTO fact_transaction_products (transaction_id, product_id)
SELECT 
    ft.transaction_id,
    jt.product_id
FROM fact_transactions ft
JOIN JSON_TABLE(
    CONCAT('[', ft.product_ids, ']'),
    "$[*]" COLUMNS(product_id INT PATH "$")
) AS jt;

/*-- Validación
SELECT * FROM fact_transaction_products LIMIT 20;

SELECT transaction_id, product_id, COUNT(*)
FROM fact_transaction_products
GROUP BY 1,2
HAVING COUNT(*) > 1;*/



/*===========================================NIVEL 1=========================================
/* Exercici 1.Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions 
utilitzant almenys 2 taules.*/
SELECT u.id, u.name, u.surname
FROM dim_user u
WHERE u.id IN (
    SELECT t.user_id
    FROM fact_transactions t
    WHERE declined = 0
    GROUP BY t.user_id
    HAVING COUNT(t.user_id) >80
);      -- OJO MODIFICARA EN WORD
/* ¿Usar in o exists?, depende del número de usuarios con > de 80 transacciones. Más de 10000 usuarios  EXISTS
menos de 1000 IN 
SELECT COUNT(*)
FROM (
    SELECT t.user_id
    FROM fact_transactions t
    GROUP BY t.user_id
    HAVING COUNT(*) > 80
) AS x;*/

/*Exercici 2.Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, 
utilitza almenys 2 taules.*/
     
	
SELECT c.iban, AVG(f.amount)
FROM fact_transactions f
JOIN dim_credit_card c
    ON f.card_id = c.id
JOIN dim_company co
    ON f.business_id = co.company_id
WHERE co.company_name = 'Donec Ltd' AND declined = 0 -- ojo cambiar poner el roun 2
GROUP BY c.iban;       
        
       SELECT CONSTRAINT_NAME
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'financial_dw'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';
  
  -- ============================= NIVEL 2. CREACIÓN DE TABLA ULTIMAS 3 TRANSACCIONES====================================
 /* Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes 
 transaccions han estat declinades aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. 
Partint d’aquesta taula respon:
Exercici 1. Quantes targetes estan actives?*/
 --  corregir   resp 4995  falta tambien el declined
  CREATE TABLE credit_card_status (
    card_id VARCHAR(20) PRIMARY KEY,
    status  VARCHAR(10)
);


ALTER TABLE credit_card_status
ADD CONSTRAINT fk_status_card
FOREIGN KEY (card_id) REFERENCES dim_credit_card(id);
/* Poblar tabla*/

INSERT INTO credit_card_status (card_id, status)
SELECT card_id,
	CASE 
	WHEN SUM(declined) = 3 THEN 'INACTIVA'
        ELSE 'ACTIVA'
    END AS status
FROM (
    SELECT 
        f.card_id,
        f.declined,
        ROW_NUMBER() OVER (PARTITION BY f.card_id ORDER BY f.timestamp DESC) AS rn
    FROM fact_transactions f
) AS x
WHERE rn <= 3 
GROUP BY card_id;
-- Verificar tabla creada

SELECT * FROM credit_card_status ;

SELECT COUNT(*) 
FROM credit_card_status
WHERE status = 'ACTIVA' ;

-- Activas con nombre de usuarios

SELECT c.card_id, c.status, u.name, u.surname
FROM credit_card_status c
JOIN dim_credit_card d ON c.card_id = d.id
JOIN dim_user u ON d.user_id = u.id
WHERE c.status = 'ACTIVA';

/*================================= NIVEL 3==========================================
/*Crea una taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades 
creada, tenint en compte que des de transaction tens product_ids. Genera la següent consulta:

Exercici 1.Necessitem conèixer el nombre de vegades que s'ha venut cada producte.*/
-- La tabla puente ya la había creado
-- resp 100 rows  declined

SELECT 
    p.product_id,
    p.product_name,
    COUNT(*) AS veces_vendido
FROM fact_transaction_products ftp
JOIN dim_product p 
    ON ftp.product_id = p.product_id
JOIN fact_transactions f 
    ON ftp.transaction_id = f.transaction_id
WHERE f.declined = 0
GROUP BY p.product_id, p.product_name
ORDER BY veces_vendido DESC;

/* =======================================================================================*/
/* ACCIONES PARA DETERMINATR POR QUÉ LAS LINEAS DE LAS RELACIONES ENTRE TABLAS ESTAN PUNTEADAS
 Se modifican las tablas porque el programa me ignora 3 fk creadas*/

ALTER TABLE DIM_USER ENGINE=InnoDB;
ALTER TABLE DIM_COMPANY ENGINE=InnoDB;
ALTER TABLE DIM_CREDIT_CARD ENGINE=InnoDB;
ALTER TABLE DIM_PRODUCT ENGINE=InnoDB;
ALTER TABLE FACT_TRANSACTIONS ENGINE=InnoDB;
ALTER TABLE fact_transaction_products ENGINE=InnoDB;
ALTER TABLE credit_card_status ENGINE=InnoDB;

SELECT TABLE_NAME, CONSTRAINT_NAME
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'financial_dw'
AND CONSTRAINT_TYPE = 'FOREIGN KEY';

/* Se borraron y crearon de nuevo las FK*/
ALTER TABLE DIM_CREDIT_CARD
ADD CONSTRAINT fk_credit_user
FOREIGN KEY (user_id)
REFERENCES DIM_USER(id)
ON DELETE NO ACTION
ON UPDATE CASCADE;

ALTER TABLE FACT_TRANSACTIONS
ADD CONSTRAINT fk_fact_user
FOREIGN KEY (user_id)
REFERENCES DIM_USER(id)
ON DELETE NO ACTION
ON UPDATE CASCADE;

ALTER TABLE FACT_TRANSACTIONS
ADD CONSTRAINT fk_fact_card
FOREIGN KEY (card_id)
REFERENCES DIM_CREDIT_CARD(id)
ON DELETE NO ACTION
ON UPDATE CASCADE;

ALTER TABLE FACT_TRANSACTIONS
ADD CONSTRAINT fk_fact_company
FOREIGN KEY (business_id)
REFERENCES DIM_COMPANY(company_id)
ON DELETE NO ACTION
ON UPDATE CASCADE;

ALTER TABLE fact_transaction_products
ADD CONSTRAINT fk_ftp_tx
FOREIGN KEY (transaction_id)
REFERENCES FACT_TRANSACTIONS(transaction_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE fact_transaction_products
ADD CONSTRAINT fk_ftp_product
FOREIGN KEY (product_id)
REFERENCES DIM_PRODUCT(product_id)
ON DELETE NO ACTION
ON UPDATE CASCADE;

ALTER TABLE credit_card_status
ADD CONSTRAINT fk_status_card
FOREIGN KEY (card_id)
REFERENCES DIM_CREDIT_CARD(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

