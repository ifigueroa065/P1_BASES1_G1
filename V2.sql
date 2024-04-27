 
CREATE SCHEMA IF NOT EXISTS ICE;
use ICE;

 -- SCRIPT PARA CREAR TEMPORAL
 
 CREATE TEMPORARY TABLE IF NOT EXISTS ICE.temp_table (
    NOMBRE_ELECCION VARCHAR(100),
    AÑO_ELECCION INT,
    PAIS VARCHAR(100),
    REGION VARCHAR(100),
    DEPTO VARCHAR(100),
    MUNICIPIO VARCHAR(100),
    PARTIDO VARCHAR(100),
    NOMBRE_PARTIDO VARCHAR(100),
    SEXO VARCHAR(100),
    RAZA VARCHAR(100),
    ANALFABETOS INT,
    ALFABETOS INT,
    SEXO_1 VARCHAR(100),
    RAZA_1 VARCHAR(100),
    PRIMARIA INT,
    NIVEL_MEDIO INT,
    UNIVERSITARIOS INT
);

-- VER LA RUTA PERMITIDA PARA CARGAR ARCHIVOS
SHOW VARIABLES LIKE 'secure_file_priv';

-- CARGAR DATA DE CSV CON QUERY
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\ICE-Fuente.csv'
INTO TABLE ICE.temp_table
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- VERIFICAR LA DATA CARGADA
SELECT * FROM ICE.temp_table;

SELECT COUNT(*) AS total_registros
FROM ICE.temp_table;

-- SCRIPT PARA CREAR EL MODELO
CREATE TABLE pais (
    id_pais INTEGER AUTO_INCREMENT NOT NULL,
    nombre  VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_pais)
);

CREATE TABLE region (
    id_region    INTEGER AUTO_INCREMENT NOT NULL,
    region       VARCHAR(50) NOT NULL,
    pais_id_pais INTEGER NOT NULL,
    PRIMARY KEY (id_region),
    FOREIGN KEY (pais_id_pais) REFERENCES pais (id_pais)
);

CREATE TABLE departamento (
    id_departamento  INTEGER AUTO_INCREMENT NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_departamento)
);

CREATE TABLE region_departamento (
    id_relacion                INTEGER AUTO_INCREMENT NOT NULL,
    region_id_region           INTEGER NOT NULL,
    departamento_id_departamento INTEGER NOT NULL,
    PRIMARY KEY (id_relacion),
    FOREIGN KEY (region_id_region) REFERENCES region (id_region),
    FOREIGN KEY (departamento_id_departamento) REFERENCES departamento (id_departamento)
);

CREATE TABLE municipio (
    id_municipio                 INTEGER AUTO_INCREMENT NOT NULL,
    nombre                       VARCHAR(100) NOT NULL,
    departamento_id_departamento INTEGER NOT NULL,
    PRIMARY KEY (id_municipio),
    FOREIGN KEY (departamento_id_departamento) REFERENCES departamento (id_departamento)
);

CREATE TABLE eleccion (
    id_eleccion            INTEGER AUTO_INCREMENT NOT NULL,
    tipo                   VARCHAR(30) NOT NULL,
    anio                   INTEGER NOT NULL,
    municipio_id_municipio INTEGER NOT NULL,
    PRIMARY KEY (id_eleccion),
    FOREIGN KEY (municipio_id_municipio) REFERENCES municipio (id_municipio)
);

CREATE TABLE partidopolitico (
    id_partido INTEGER AUTO_INCREMENT NOT NULL,
    partido    VARCHAR(20) NOT NULL,
    nombre     VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_partido)
);

CREATE TABLE participacion (
    id_participacion           INTEGER AUTO_INCREMENT NOT NULL,
    raza                       VARCHAR(30) NOT NULL,
    sexo                       VARCHAR(50) NOT NULL,
    analfabetos                INTEGER NOT NULL,
    alfabetos                  INTEGER NOT NULL,
    primaria                   INTEGER NOT NULL,
    nivel_medio                INTEGER NOT NULL,
    universitarios             INTEGER NOT NULL,
    eleccion_id_eleccion       INTEGER NOT NULL,
    partidopolitico_id_partido INTEGER NOT NULL,
    PRIMARY KEY (id_participacion),
    FOREIGN KEY (eleccion_id_eleccion) REFERENCES eleccion (id_eleccion),
    FOREIGN KEY (partidopolitico_id_partido) REFERENCES partidopolitico (id_partido)
);



-- TRASLADANDO LA DATA TEMP A NORMALIZADO

-- TRANSFIRIENDO DATA A PAIS
INSERT INTO pais (nombre)
SELECT DISTINCT PAIS FROM ICE.temp_table;

-- TRANSFIRIENDO DATA A REGION
INSERT INTO region (region, pais_id_pais)
SELECT DISTINCT REGION, p.id_pais
FROM ICE.temp_table t
INNER JOIN pais p ON t.PAIS = p.nombre;


-- TRANSFIRIENDO DATA A DEPTO
INSERT INTO departamento (nombre)
SELECT DISTINCT DEPTO FROM ICE.temp_table;

-- ADICIONAL
INSERT INTO region_departamento (region_id_region, departamento_id_departamento)
SELECT r.id_region, d.id_departamento
FROM ICE.temp_table t
INNER JOIN region r ON t.REGION = r.region
INNER JOIN departamento d ON t.DEPTO = d.nombre;


-- TRANSFIRIENDO DATA A MUNICIPIO
INSERT INTO municipio (nombre, departamento_id_departamento)
SELECT DISTINCT MUNICIPIO, d.id_departamento
FROM ICE.temp_table t
INNER JOIN departamento d ON t.DEPTO = d.nombre;

-- Insertar datos en la tabla partidopolitico si no existen
INSERT INTO partidopolitico (partido, nombre)
SELECT DISTINCT PARTIDO, NOMBRE_PARTIDO FROM ICE.temp_table;

-- Insertar datos en la tabla eleccion
INSERT INTO eleccion (tipo, anio, municipio_id_municipio)
SELECT DISTINCT NOMBRE_ELECCION, AÑO_ELECCION, m.id_municipio
FROM ICE.temp_table t
INNER JOIN municipio m ON t.MUNICIPIO = m.nombre;



-- Insertar datos en la tabla participacion
INSERT INTO participacion (raza, sexo, analfabetos, alfabetos, primaria, nivel_medio, universitarios, eleccion_id_eleccion, partidopolitico_id_partido)
SELECT DISTINCT RAZA, SEXO, ANALFABETOS, ALFABETOS, PRIMARIA, NIVEL_MEDIO, UNIVERSITARIOS, e.id_eleccion, pp.id_partido
FROM ICE.temp_table t
INNER JOIN eleccion e ON t.NOMBRE_ELECCION = e.tipo AND t.AÑO_ELECCION = e.anio
INNER JOIN municipio m ON t.MUNICIPIO = m.nombre
INNER JOIN partidopolitico pp ON t.PARTIDO = pp.partido
LIMIT 1000; -- Limitar la inserción a 1000 filas por consulta


DELIMITER //

CREATE PROCEDURE process_participacion_data()
BEGIN
    DECLARE start_idx INT DEFAULT 0;
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE total_rows INT;

    SELECT COUNT(*) INTO total_rows FROM ICE.temp_table;

    WHILE start_idx < total_rows DO
        INSERT INTO participacion (raza, sexo, analfabetos, alfabetos, primaria, nivel_medio, universitarios, eleccion_id_eleccion, partidopolitico_id_partido)
        SELECT DISTINCT RAZA, SEXO, ANALFABETOS, ALFABETOS, PRIMARIA, NIVEL_MEDIO, UNIVERSITARIOS, e.id_eleccion, pp.id_partido
        FROM ICE.temp_table t
        INNER JOIN eleccion e ON t.NOMBRE_ELECCION = e.tipo AND t.AÑO_ELECCION = e.anio
        INNER JOIN municipio m ON t.MUNICIPIO = m.nombre
        INNER JOIN partidopolitico pp ON t.PARTIDO = pp.partido
        LIMIT start_idx, batch_size;

        SET start_idx = start_idx + batch_size;
    END WHILE;
END //

DELIMITER ;

CALL process_participacion_data();


SET SQL_SAFE_UPDATES = 0;
DELETE FROM departamento;
SET SQL_SAFE_UPDATES = 1;

-- drops
DROP TABLE participacion;
DROP TABLE eleccion;
DROP TABLE municipio;
DROP TABLE departamento;
DROP TABLE region;
DROP TABLE pais;
