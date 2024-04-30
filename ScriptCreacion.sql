CREATE DATABASE proymag;
USE proymag;

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
    anio                   INT NOT NULL
);

CREATE TABLE PartidoEleccion (
    partido_id INT,
    eleccion_id INT,
    municipio_id INT NOT NULL,
    FOREIGN KEY (municipio_id) REFERENCES Municipio(id_municipio),
    FOREIGN KEY (partido_id) REFERENCES PartidoPolitico(id_partidopolitico),
    FOREIGN KEY (eleccion_id) REFERENCES Eleccion(id_eleccion),
    PRIMARY KEY (partido_id, eleccion_id, municipio_id)
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
    partido_id INT,
    eleccion_id INT,
    municipio_id INT,
    FOREIGN KEY (partido_id, eleccion_id, municipio_id) REFERENCES PartidoEleccion(partido_id, eleccion_id, municipio_id)
);
