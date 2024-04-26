CREATE DATABASE proymag;
USE proymag;

-- Tabla Temporal
CREATE TEMPORARY TABLE IF NOT EXISTS temp_table (
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

LOAD DATA INFILE '/var/lib/mysql-files/ICE-Fuente.csv'
INTO TABLE temp_table
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Creacion de Tablas
CREATE TABLE Pais (
    id_pais INT AUTO_INCREMENT PRIMARY KEY,
    nombre  VARCHAR(100) NOT NULL
);

CREATE TABLE Region (
    id_region INT AUTO_INCREMENT PRIMARY KEY,
    region    VARCHAR(50) NOT NULL
);

CREATE TABLE PaisRegion (
    pais_id_pais     INT NOT NULL,
    region_id_region INT NOT NULL,
    PRIMARY KEY (pais_id_pais, region_id_region),
    FOREIGN KEY (pais_id_pais) REFERENCES Pais(id_pais),
    FOREIGN KEY (region_id_region) REFERENCES Region(id_region)
);

CREATE TABLE Departamento (
    id_departamento             INT AUTO_INCREMENT PRIMARY KEY,
    nombre                      VARCHAR(100) NOT NULL,
    paisregion_pais_id_pais     INT NOT NULL,
    paisregion_region_id_region INT NOT NULL,
    FOREIGN KEY (paisregion_pais_id_pais, paisregion_region_id_region) REFERENCES PaisRegion(pais_id_pais, region_id_region)
);

CREATE TABLE Municipio (
    id_municipio                 INT AUTO_INCREMENT PRIMARY KEY,
    nombre                       VARCHAR(100) NOT NULL,
    departamento_id_departamento INT NOT NULL,
    FOREIGN KEY (departamento_id_departamento) REFERENCES Departamento(id_departamento)
);

CREATE TABLE PartidoPolitico (
    id_partidopolitico INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100),
    NombreCompleto VARCHAR(100)
);

CREATE TABLE Eleccion (
    id_eleccion INT AUTO_INCREMENT PRIMARY KEY,
    tipo                   VARCHAR(30) NOT NULL,
    anio                   INT NOT NULL,
    municipio_id_municipio INT NOT NULL,
    FOREIGN KEY (municipio_id_municipio) REFERENCES Municipio(id_municipio)
);

CREATE TABLE PartidoEleccion (
    partido_id INT,
    eleccion_id INT,
    FOREIGN KEY (partido_id) REFERENCES PartidoPolitico(id_partidopolitico),
    FOREIGN KEY (eleccion_id) REFERENCES Eleccion(id_eleccion),
    PRIMARY KEY (partido_id, eleccion_id)
);

CREATE TABLE Votante (
    id_votante INT AUTO_INCREMENT PRIMARY KEY,
    sexo VARCHAR(10),
    raza VARCHAR(50),
    votantes_analfabetos INT,
    votantes_alfabetos INT,
    votantes_primaria INT,
    votantes_nivelMedio INT,
    votantes_universitarios INT,
    eleccion_id INT,
    FOREIGN KEY (eleccion_id) REFERENCES Eleccion(id_eleccion)
);

-- Insertando DATA
INSERT INTO Pais (nombre)
SELECT DISTINCT UPPER(pais)
FROM temp_table;

SELECT * FROM Pais;

INSERT INTO Region (region)
SELECT DISTINCT UPPER(t.REGION) AS REGION
FROM temp_table t;

SELECT * FROM Region;

INSERT INTO PaisRegion (pais_id_pais, region_id_region)
SELECT DISTINCT p.id_pais, r.id_region
FROM temp_table t
JOIN Pais p ON t.PAIS = p.nombre
JOIN Region r ON t.REGION = r.region;

SELECT * FROM PaisRegion;

INSERT INTO Departamento (nombre, paisregion_pais_id_pais, paisregion_region_id_region)
SELECT DISTINCT
    td.DEPTO,
    p.id_pais,
    r.id_region
FROM temp_table td
JOIN Pais p ON td.PAIS = p.nombre
JOIN Region r ON td.REGION = r.region;

SELECT * FROM Departamento;

INSERT INTO Municipio (nombre, departamento_id_departamento)
SELECT DISTINCT
    tm.municipio,
    d.id_departamento
FROM temp_table tm
JOIN Departamento d ON tm.depto = d.nombre;

SELECT * FROM Municipio;

INSERT INTO PartidoPolitico (Nombre, NombreCompleto)
SELECT DISTINCT PARTIDO, NOMBRE_PARTIDO
FROM temp_table;

SELECT * FROM PartidoPolitico;

INSERT INTO Eleccion (tipo, anio, municipio_id_municipio)
SELECT DISTINCT NOMBRE_ELECCION, AÑO_ELECCION, m.id_municipio
FROM temp_table t
JOIN Municipio m ON t.municipio = m.nombre
JOIN Departamento d ON t.DEPTO = d.nombre AND m.departamento_id_departamento = d.id_departamento
JOIN Region r ON t.REGION = r.region AND d.paisregion_region_id_region = r.id_region
JOIN Pais p ON t.PAIS = p.nombre AND d.paisregion_pais_id_pais = p.id_pais;

SELECT * FROM Eleccion;

INSERT INTO PartidoEleccion (partido_id, eleccion_id)
SELECT DISTINCT pp.id_partidopolitico, e.id_eleccion
FROM temp_table t
INNER JOIN PartidoPolitico pp ON t.PARTIDO = pp.Nombre AND t.NOMBRE_PARTIDO = pp.NombreCompleto
INNER JOIN Eleccion e ON t.NOMBRE_ELECCION = e.tipo AND t.AÑO_ELECCION = e.Anio
JOIN Municipio m ON t.municipio = m.nombre AND e.municipio_id_municipio = m.id_municipio
JOIN Departamento d ON t.DEPTO = d.nombre AND m.departamento_id_departamento = d.id_departamento
JOIN Region r ON t.REGION = r.region AND d.paisregion_region_id_region = r.id_region
JOIN Pais p ON t.PAIS = p.nombre AND d.paisregion_pais_id_pais = p.id_pais;

SELECT * FROM PartidoEleccion;

INSERT INTO Votante (sexo, raza, votantes_analfabetos, votantes_alfabetos, votantes_primaria, votantes_nivelMedio, votantes_universitarios, eleccion_id)
SELECT DISTINCT t.SEXO, t.RAZA, t.ANALFABETOS, t.ALFABETOS, t.PRIMARIA, t.NIVEL_MEDIO, t.UNIVERSITARIOS, e.id_eleccion
FROM temp_table t
INNER JOIN Eleccion e ON t.NOMBRE_ELECCION = e.tipo AND t.AÑO_ELECCION = e.Anio
JOIN Municipio m ON t.municipio = m.nombre AND e.municipio_id_municipio = m.id_municipio
JOIN Departamento d ON t.DEPTO = d.nombre AND m.departamento_id_departamento = d.id_departamento
JOIN Region r ON t.REGION = r.region AND d.paisregion_region_id_region = r.id_region
JOIN Pais p ON t.PAIS = p.nombre AND d.paisregion_pais_id_pais = p.id_pais;

SELECT * FROM Votante;
