
-- QUERYS

-- QUERY 1
-- Consulta para obtener el país y el partido político con mayor porcentaje de votos en cada elección
SELECT 
    e.tipo AS nombre_eleccion,
    e.anio AS anio_eleccion,
    p.nombre AS pais,
    pp.Nombre AS nombre_partido,
    (SUM(v.votantes_alfabetos) + SUM(v.votantes_primaria) + SUM(v.votantes_nivelMedio) + SUM(v.votantes_universitarios)) /
        (SUM(t.ALFABETOS) + SUM(t.PRIMARIA) + SUM(t.NIVEL_MEDIO) + SUM(t.UNIVERSITARIOS)) * 100 AS porcentaje_votos
FROM Eleccion e
JOIN Municipio m ON e.municipio_id_municipio = m.id_municipio
JOIN Departamento d ON m.departamento_id_departamento = d.id_departamento
JOIN Pais p ON d.paisregion_pais_id_pais = p.id_pais
JOIN PartidoEleccion pe ON e.id_eleccion = pe.eleccion_id
JOIN PartidoPolitico pp ON pe.partido_id = pp.id_partidopolitico
JOIN Votante v ON e.id_eleccion = v.eleccion_id
JOIN temp_table t ON e.tipo = t.NOMBRE_ELECCION AND e.anio = t.AÑO_ELECCION AND m.nombre = t.municipio
WHERE (v.votantes_alfabetos + v.votantes_primaria + v.votantes_nivelMedio + v.votantes_universitarios) > 0
GROUP BY e.tipo, e.anio, p.nombre, pp.Nombre
ORDER BY e.tipo, e.anio, porcentaje_votos DESC;


-- QUERY 2

-- Consulta para obtener el total de votos y porcentaje de votos de mujeres por departamento y país
-- Query to calculate total votes and percentage of votes by women per department and country
-- Consulta para calcular total de votos y porcentaje de votos de mujeres por departamento y país
SELECT 
    p.nombre AS pais,
    d.nombre AS departamento,
    SUM(v.votantes_analfabetos + v.votantes_alfabetos + v.votantes_primaria + v.votantes_nivelMedio + v.votantes_universitarios) AS total_votos_mujeres,
    (SUM(v.votantes_analfabetos + v.votantes_alfabetos + v.votantes_primaria + v.votantes_nivelMedio + v.votantes_universitarios) /
     (SELECT SUM(v2.votantes_analfabetos + v2.votantes_alfabetos + v2.votantes_primaria + v2.votantes_nivelMedio + v2.votantes_universitarios)
      FROM Votante v2
      JOIN Eleccion e2 ON v2.eleccion_id = e2.id_eleccion
      JOIN Municipio m2 ON e2.municipio_id_municipio = m2.id_municipio
      JOIN Departamento d2 ON m2.departamento_id_departamento = d2.id_departamento
      JOIN Pais p2 ON d2.paisregion_pais_id_pais = p2.id_pais
      WHERE v2.sexo = 'mujeres' AND p2.id_pais = p.id_pais) * 100) AS porcentaje_votos_mujeres
FROM Votante v
JOIN Eleccion e ON v.eleccion_id = e.id_eleccion
JOIN Municipio m ON e.municipio_id_municipio = m.id_municipio
JOIN Departamento d ON m.departamento_id_departamento = d.id_departamento
JOIN Pais p ON d.paisregion_pais_id_pais = p.id_pais
WHERE v.sexo = 'mujeres'
GROUP BY p.nombre, d.nombre, p.id_pais
ORDER BY p.nombre, d.nombre;


-- QUERY 3


 
 
 -- QUERY 4
 
SELECT
    p.nombre AS pais,
    r.region AS region,
    SUM(CASE WHEN UPPER(v.raza) = 'INDIGENAS' THEN 1 ELSE 0 END) AS votos_indigenas
FROM
    Votante v
JOIN
    Eleccion e ON v.eleccion_id = e.id_eleccion
JOIN
    Municipio m ON e.municipio_id_municipio = m.id_municipio
JOIN
    Departamento d ON m.departamento_id_departamento = d.id_departamento
JOIN
    Region r ON d.paisregion_region_id_region = r.id_region
JOIN
    Pais p ON d.paisregion_pais_id_pais = p.id_pais
WHERE
    UPPER(v.raza) = 'INDIGENAS' -- Filtrar por la raza indígena (considerando mayúsculas/minúsculas)
GROUP BY
    p.nombre, r.region
ORDER BY
    p.nombre, r.region;

-- QUERY 5
-- Consulta para desplegar porcentaje de mujeres universitarias y hombres universitarios que votaron por departamento
SELECT
    d.nombre AS departamento,
    SUM(CASE WHEN v.sexo = 'mujeres' AND v.votantes_universitarios = 1 THEN 1 ELSE 0 END) AS mujeres_universitarias,
    SUM(CASE WHEN v.sexo = 'hombres' AND v.votantes_universitarios = 1 THEN 1 ELSE 0 END) AS hombres_universitarios,
    COUNT(*) AS total_votantes,
    (SUM(CASE WHEN v.sexo = 'mujeres' AND v.votantes_universitarios = 1 THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS porcentaje_mujeres_universitarias,
    (SUM(CASE WHEN v.sexo = 'hombres' AND v.votantes_universitarios = 1 THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS porcentaje_hombres_universitarios
FROM
    Votante v
JOIN
    Eleccion e ON v.eleccion_id = e.id_eleccion
JOIN
    Municipio m ON e.municipio_id_municipio = m.id_municipio
JOIN
    Departamento d ON m.departamento_id_departamento = d.id_departamento
GROUP BY
    d.nombre
HAVING
    mujeres_universitarias > hombres_universitarios;


-- QUERY 6


-- QUERY 7

-- Consulta para desplegar el nombre del país y el porcentaje de votos por raza
SELECT
    p.nombre AS pais,
    t.raza AS raza,
    (SUM(t.votantes_analfabetos) + SUM(t.votantes_alfabetos) + SUM(t.votantes_primaria) + SUM(t.votantes_nivelMedio) + SUM(t.votantes_universitarios)) AS total_votos,
    ROUND((SUM(t.votantes_analfabetos) + SUM(t.votantes_alfabetos) + SUM(t.votantes_primaria) + SUM(t.votantes_nivelMedio) + SUM(t.votantes_universitarios)) / (SELECT SUM(votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios) FROM Votante WHERE eleccion_id IN (SELECT id_eleccion FROM Eleccion WHERE municipio_id_municipio IN (SELECT id_municipio FROM Municipio WHERE departamento_id_departamento IN (SELECT id_departamento FROM Departamento WHERE paisregion_pais_id_pais IN (SELECT id_pais FROM Pais WHERE nombre = p.nombre))))) * 100, 2) AS porcentaje_votos
FROM
    Votante t
JOIN
    Eleccion e ON t.eleccion_id = e.id_eleccion
JOIN
    Municipio m ON e.municipio_id_municipio = m.id_municipio
JOIN
    Departamento d ON m.departamento_id_departamento = d.id_departamento
JOIN
    Pais p ON d.paisregion_pais_id_pais = p.id_pais
GROUP BY
    p.nombre, t.raza;


-- QUERY 8
-- Consulta para desplegar el nombre del país con las elecciones más peleadas


-- QUERY 9
-- Consulta para desplegar el nombre del país con el mayor porcentaje de votos de analfabetos
SELECT
    pais,
    MAX(porcentaje_analfabetos) AS mayor_porcentaje_analfabetos
FROM (
    SELECT
        p.nombre AS pais,
        SUM(v.votantes_analfabetos) / SUM(v.votantes_analfabetos + v.votantes_alfabetos + v.votantes_primaria + v.votantes_nivelMedio + v.votantes_universitarios) AS porcentaje_analfabetos
    FROM
        Votante v
    JOIN
        Eleccion e ON v.eleccion_id = e.id_eleccion
    JOIN
        Municipio m ON e.municipio_id_municipio = m.id_municipio
    JOIN
        Departamento d ON m.departamento_id_departamento = d.id_departamento
    JOIN
        Pais p ON d.paisregion_pais_id_pais = p.id_pais
    GROUP BY
        p.nombre
) AS porcentajes_analfabetos_por_pais
GROUP BY
    pais
ORDER BY
    mayor_porcentaje_analfabetos DESC
LIMIT 1;


-- QUERY 10
-- Consulta para desplegar departamentos de Guatemala con más votos que el departamento de Guatemala