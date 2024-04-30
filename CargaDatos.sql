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

-- Insertando datos en la tabla temporal
LOAD DATA INFILE '/var/lib/mysql-files/ICE-Fuente.csv'
INTO TABLE temp_table
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- Insertando DATA a Pais
INSERT INTO Pais (nombre)
SELECT DISTINCT UPPER(pais)
FROM temp_table;

-- Insertando DATA a Region
INSERT INTO Region (region)
SELECT DISTINCT UPPER(t.REGION) AS REGION
FROM temp_table t;

-- Insertando DATA a PaisRegion
INSERT INTO PaisRegion (pais_id_pais, region_id_region)
SELECT DISTINCT p.id_pais, r.id_region
FROM temp_table t
JOIN Pais p ON t.PAIS = p.nombre
JOIN Region r ON t.REGION = r.region;

-- Insertando DATA a Departamento
INSERT INTO Departamento (nombre, paisregion_pais_id_pais, paisregion_region_id_region)
SELECT DISTINCT
    td.DEPTO,
    p.id_pais,
    r.id_region
FROM temp_table td
JOIN Pais p ON td.PAIS = p.nombre
JOIN Region r ON td.REGION = r.region;

-- Insertando DATA a Municipio
INSERT INTO Municipio (nombre, departamento_id_departamento)
SELECT DISTINCT
    tm.municipio,
    d.id_departamento
FROM temp_table tm
JOIN Departamento d ON tm.depto = d.nombre;

-- Insertando DATA a PartidoPolitico
INSERT INTO PartidoPolitico (Nombre, NombreCompleto)
SELECT DISTINCT PARTIDO, NOMBRE_PARTIDO
FROM temp_table;

-- Insertando DATA a Eleccion
INSERT INTO Eleccion (tipo, anio)
SELECT DISTINCT NOMBRE_ELECCION, AÑO_ELECCION
FROM temp_table t
JOIN Municipio m ON t.municipio = m.nombre
JOIN Departamento d ON t.DEPTO = d.nombre AND m.departamento_id_departamento = d.id_departamento
JOIN Region r ON t.REGION = r.region AND d.paisregion_region_id_region = r.id_region
JOIN Pais p ON t.PAIS = p.nombre AND d.paisregion_pais_id_pais = p.id_pais;

-- Insertando DATA a PartidoEleccion
INSERT INTO PartidoEleccion (partido_id, eleccion_id, municipio_id)
SELECT DISTINCT pp.id_partidopolitico, e.id_eleccion, m.id_municipio
FROM temp_table t
INNER JOIN PartidoPolitico pp ON t.PARTIDO = pp.Nombre AND t.NOMBRE_PARTIDO = pp.NombreCompleto
INNER JOIN Eleccion e ON t.NOMBRE_ELECCION = e.tipo AND t.AÑO_ELECCION = e.Anio
JOIN Municipio m ON t.municipio = m.nombre;

-- Insertando DATA a Votante
INSERT INTO
    Votante (sexo, raza, votantes_analfabetos, votantes_alfabetos,
             votantes_primaria, votantes_nivelMedio, votantes_universitarios, partido_id, eleccion_id, municipio_id)
SELECT DISTINCT t.SEXO, t.RAZA, t.ANALFABETOS, t.ALFABETOS, t.PRIMARIA, t.NIVEL_MEDIO, t.UNIVERSITARIOS, pp.id_partidopolitico, e.id_eleccion, m.id_municipio
FROM temp_table t
INNER JOIN Eleccion e ON t.NOMBRE_ELECCION = e.tipo AND t.AÑO_ELECCION = e.Anio
JOIN PartidoPolitico pp ON t.PARTIDO = pp.nombre AND t.NOMBRE_PARTIDO = pp.NombreCompleto
JOIN Municipio m ON t.municipio = m.nombre
JOIN Departamento d ON t.DEPTO = d.nombre AND m.departamento_id_departamento = d.id_departamento
JOIN Region r ON t.REGION = r.region AND d.paisregion_region_id_region = r.id_region
JOIN Pais p ON t.PAIS = p.nombre AND d.paisregion_pais_id_pais = p.id_pais;

