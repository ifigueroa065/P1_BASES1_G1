
-- REPORTES ----------------------------------------------

-- 1 ***********************************
SELECT
    Nombre_eleccion,
    Anio_eleccion,
    Nombre_Pais,
    Nombre_Partido,
    Porcentaje_Maximo_Votos
FROM (
    SELECT
        subconsulta.Nombre_eleccion,
        subconsulta.Anio_eleccion,
        subconsulta.Nombre_Pais,
        subconsulta.Nombre_Partido,
        (Total_Votos / Total_Votos_Pais) * 100 AS Porcentaje_Votos,
        MAX((Total_Votos / Total_Votos_Pais) * 100) OVER (PARTITION BY subconsulta.Nombre_Pais) AS Porcentaje_Maximo_Votos
    FROM (
        SELECT
            Eleccion.tipo AS Nombre_eleccion,
            Eleccion.anio AS Anio_eleccion,
            Pais.nombre AS Nombre_Pais,
            PartidoPolitico.Nombre AS Nombre_Partido,
            SUM(Votante.votantes_analfabetos + Votante.votantes_alfabetos + Votante.votantes_primaria + Votante.votantes_nivelMedio + Votante.votantes_universitarios) AS Total_Votos,
            SUM(SUM(Votante.votantes_analfabetos + Votante.votantes_alfabetos + Votante.votantes_primaria + Votante.votantes_nivelMedio + Votante.votantes_universitarios)) OVER (PARTITION BY Pais.nombre) AS Total_Votos_Pais
        FROM
            Votante
        INNER JOIN PartidoEleccion ON Votante.partido_id = PartidoEleccion.partido_id AND Votante.eleccion_id = PartidoEleccion.eleccion_id AND Votante.municipio_id = PartidoEleccion.municipio_id
        INNER JOIN Eleccion on PartidoEleccion.eleccion_id = Eleccion.id_eleccion
        INNER JOIN PartidoPolitico ON PartidoEleccion.partido_id = PartidoPolitico.id_partidopolitico
        INNER JOIN Municipio ON Votante.municipio_id = Municipio.id_municipio
        INNER JOIN Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
        INNER JOIN PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
        INNER JOIN Pais ON PaisRegion.pais_id_pais = Pais.id_pais
        GROUP BY Pais.nombre, PartidoPolitico.Nombre, Eleccion.tipo, Eleccion.anio
    ) AS subconsulta
) AS max_porcentaje_por_pais
WHERE Porcentaje_Votos = Porcentaje_Maximo_Votos;

-- 2 ***********************************
SELECT
    Pais.nombre AS Nombre_Pais,
    Departamento.nombre AS Nombre_Departamento,
    SUM(Votante.sexo = 'Mujeres') AS Total_Votos_Mujeres,
    ROUND((SUM(Votante.sexo = 'Mujeres') / TotalVotosPais.Total_Votos_Pais) * 100, 2) AS Porcentaje_Votos_Mujeres
FROM
    Votante
INNER JOIN Municipio ON Votante.municipio_id = Municipio.id_municipio
INNER JOIN Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
INNER JOIN PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
INNER JOIN Pais ON PaisRegion.pais_id_pais = Pais.id_pais
INNER JOIN (
    SELECT
        Pais.id_pais,
        SUM(Votante.sexo = 'Mujeres') AS Total_Votos_Pais
    FROM
        Votante
    INNER JOIN Municipio ON Votante.municipio_id = Municipio.id_municipio
    INNER JOIN Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
    INNER JOIN PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
    INNER JOIN Pais ON PaisRegion.pais_id_pais = Pais.id_pais
    GROUP BY
        Pais.id_pais
) AS TotalVotosPais ON Pais.id_pais = TotalVotosPais.id_pais
GROUP BY
    Pais.nombre, Departamento.nombre, TotalVotosPais.Total_Votos_Pais;

-- 3 ***********************************
SELECT
    p.nombre AS Nombre_Pais,
    pp.Nombre AS Nombre_Partido,
    COUNT(*) AS Numero_Alcaldias
FROM
    Municipio m
INNER JOIN
    Votante v ON m.id_municipio = v.municipio_id
INNER JOIN
    PartidoEleccion pe ON v.partido_id = pe.partido_id AND v.eleccion_id = pe.eleccion_id AND v.municipio_id = pe.municipio_id
INNER JOIN
    PartidoPolitico pp ON pe.partido_id = pp.id_partidopolitico
INNER JOIN
    (
        SELECT
            m.id_municipio,
            pe.partido_id,
            ROW_NUMBER() OVER (PARTITION BY m.id_municipio ORDER BY SUM(v.votantes_analfabetos + v.votantes_alfabetos + v.votantes_primaria + v.votantes_nivelMedio + v.votantes_universitarios) DESC) AS ranking
        FROM
            Municipio m
        INNER JOIN
            Votante v ON m.id_municipio = v.municipio_id
        INNER JOIN
            PartidoEleccion pe ON v.partido_id = pe.partido_id AND v.eleccion_id = pe.eleccion_id AND v.municipio_id = pe.municipio_id
        GROUP BY
            m.id_municipio, pe.partido_id
    ) AS ranking ON m.id_municipio = ranking.id_municipio AND pe.partido_id = ranking.partido_id AND ranking.ranking = 1
INNER JOIN
    Departamento d ON m.departamento_id_departamento = d.id_departamento
INNER JOIN
    PaisRegion pr ON d.paisregion_pais_id_pais = pr.pais_id_pais AND d.paisregion_region_id_region = pr.region_id_region
INNER JOIN
    Pais p ON pr.pais_id_pais = p.id_pais
GROUP BY
    p.nombre, pp.Nombre
ORDER BY
    p.nombre, Numero_Alcaldias DESC;

-- 4 ***********************************
SELECT
    region_id_region,
    Nombre_Pais,
    Nombre_Region,
    Total_Votos_Indigenas
FROM (
    SELECT
        PR.region_id_region,
        P.nombre AS Nombre_Pais,
        R.region AS Nombre_Region,
        SUM(votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios) AS Total_Votos_Indigenas
    FROM
        Votante V
    INNER JOIN Municipio M ON V.municipio_id = M.id_municipio
    INNER JOIN Departamento D ON M.departamento_id_departamento = D.id_departamento
    INNER JOIN PaisRegion PR ON D.paisregion_pais_id_pais = PR.pais_id_pais AND D.paisregion_region_id_region = PR.region_id_region
    INNER JOIN Region R ON PR.region_id_region = R.id_region
    INNER JOIN Pais P ON PR.pais_id_pais = P.id_pais
    WHERE
        V.raza = 'Indigenas'
    GROUP BY
        PR.region_id_region, P.nombre, R.region
) AS Subconsulta_Indigenas
WHERE
    Total_Votos_Indigenas > 0;

-- 5 ***********************************
SELECT
    Departamento.nombre AS Nombre_Departamento,
    SUM(CASE WHEN Votante.sexo = 'Mujeres' THEN votantes_universitarios ELSE 0 END) AS Votantes_Universitarias,
    SUM(CASE WHEN Votante.sexo = 'Hombres' THEN votantes_universitarios ELSE 0 END) AS Votantes_Universitarios_Hombres,
    SUM(CASE WHEN Votante.sexo = 'Mujeres' THEN votantes_universitarios ELSE 0 END) / SUM(votantes_universitarios) * 100 AS Porcentaje_Mujeres_Universitarias,
    SUM(CASE WHEN Votante.sexo = 'Hombres' THEN votantes_universitarios ELSE 0 END) / SUM(votantes_universitarios) * 100 AS Porcentaje_Hombres_Universitarios
FROM
    Votante
INNER JOIN
    Municipio ON Votante.municipio_id = Municipio.id_municipio
INNER JOIN
    Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
GROUP BY
    Departamento.nombre
HAVING
    SUM(CASE WHEN Votante.sexo = 'Mujeres' THEN votantes_universitarios ELSE 0 END) > SUM(CASE WHEN Votante.sexo = 'Hombres' THEN votantes_universitarios ELSE 0 END);


-- 6 ***********************************
SELECT
    Pais.nombre AS Nombre_Pais,
    Region.region AS Nombre_Region,
    AVG(Total_Votos) AS Promedio_Votos_Por_Departamento
FROM (
    SELECT
        Departamento.id_departamento,
        SUM(Votante.votantes_analfabetos + Votante.votantes_alfabetos + Votante.votantes_primaria + Votante.votantes_nivelMedio + Votante.votantes_universitarios) AS Total_Votos
    FROM
        Votante
    INNER JOIN
        Municipio ON Votante.municipio_id = Municipio.id_municipio
    INNER JOIN
        Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
    GROUP BY
        Departamento.id_departamento
) AS Votos_Por_Departamento
INNER JOIN
    Departamento ON Votos_Por_Departamento.id_departamento = Departamento.id_departamento
INNER JOIN
    PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
INNER JOIN
    Pais ON PaisRegion.pais_id_pais = Pais.id_pais
INNER JOIN
    Region ON PaisRegion.region_id_region = Region.id_region
GROUP BY
    Pais.nombre, Region.region;

-- 7 ***********************************
SELECT
    Pais.nombre AS Nombre_Pais,
    SUM(CASE WHEN Votante.raza = 'INDIGENAS' THEN votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios ELSE 0 END) / SUM(votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios) * 100 AS Porcentaje_Votos_Indigenas,
    SUM(CASE WHEN Votante.raza = 'LADINOS' THEN votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios ELSE 0 END) / SUM(votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios) * 100 AS Porcentaje_Votos_Ladinos,
    SUM(CASE WHEN Votante.raza = 'GARIFUNAS' THEN votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios ELSE 0 END) / SUM(votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios) * 100 AS Porcentaje_Votos_Garifunas
FROM
    Votante
INNER JOIN
    Municipio ON Votante.municipio_id = Municipio.id_municipio
INNER JOIN
    Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
INNER JOIN
    PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
INNER JOIN
    Pais ON PaisRegion.pais_id_pais = Pais.id_pais
GROUP BY
    Pais.nombre;

-- 8 ***********************************
SELECT
    Nombre_Pais
FROM (
    SELECT
        p.nombre AS Nombre_Pais,
        e.anio AS Anio_Eleccion,
        e.tipo AS Tipo_Eleccion,
        MAX(porcentaje_votos) AS Mayor_Porcentaje,
        MIN(porcentaje_votos) AS Menor_Porcentaje,
        MAX(porcentaje_votos) - MIN(porcentaje_votos) AS Diferencia_Porcentaje
    FROM (
        SELECT
            pais.id_pais,
            eleccion.id_eleccion,
            (MAX(total_votos) - MIN(total_votos)) / NULLIF(MAX(total_votos), 0) AS porcentaje_votos
        FROM (
            SELECT
                partido_id,
                eleccion_id,
                SUM(votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios) AS total_votos
            FROM
                Votante
            GROUP BY
                partido_id, eleccion_id
        ) AS votos_por_partido
        INNER JOIN PartidoEleccion pe ON votos_por_partido.partido_id = pe.partido_id AND votos_por_partido.eleccion_id = pe.eleccion_id
        INNER JOIN Eleccion eleccion ON pe.eleccion_id = eleccion.id_eleccion
        INNER JOIN Municipio municipio ON pe.municipio_id = municipio.id_municipio
        INNER JOIN Departamento departamento ON municipio.departamento_id_departamento = departamento.id_departamento
        INNER JOIN PaisRegion pr ON departamento.paisregion_pais_id_pais = pr.pais_id_pais AND departamento.paisregion_region_id_region = pr.region_id_region
        INNER JOIN Pais pais ON pr.pais_id_pais = pais.id_pais
        GROUP BY
            pais.id_pais, eleccion.id_eleccion
    ) AS porcentajes_por_pais_eleccion
    INNER JOIN Eleccion e ON porcentajes_por_pais_eleccion.id_eleccion = e.id_eleccion
    INNER JOIN Pais p ON porcentajes_por_pais_eleccion.id_pais = p.id_pais
    GROUP BY
        p.nombre, e.anio, e.tipo
) AS Elecciones_Por_Pais
ORDER BY
    Diferencia_Porcentaje ASC
LIMIT 1;

-- 9 ***********************************
SELECT
    Pais.nombre AS Nombre_Pais,
    SUM(votantes_analfabetos) / NULLIF(SUM(votantes_analfabetos + votantes_alfabetos + votantes_primaria + votantes_nivelMedio + votantes_universitarios), 0) * 100 AS Porcentaje_Analfabetas
FROM
    Votante
INNER JOIN
    Municipio ON Votante.municipio_id = Municipio.id_municipio
INNER JOIN
    Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
INNER JOIN
    PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
INNER JOIN
    Pais ON PaisRegion.pais_id_pais = Pais.id_pais
GROUP BY
    Pais.nombre
ORDER BY
    Porcentaje_Analfabetas DESC
LIMIT 1;

-- 10 ***********************************
SELECT
    Departamento.nombre AS Nombre_Departamento,
    SUM(Votante.votantes_analfabetos + Votante.votantes_alfabetos + Votante.votantes_primaria + Votante.votantes_nivelMedio + Votante.votantes_universitarios) AS Total_Votos
FROM
    Votante
INNER JOIN
    Municipio ON Votante.municipio_id = Municipio.id_municipio
INNER JOIN
    Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
INNER JOIN
    PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
INNER JOIN
    Pais ON PaisRegion.pais_id_pais = Pais.id_pais
WHERE
    Pais.nombre = 'Guatemala'
GROUP BY
    Departamento.nombre
HAVING
    Total_Votos > (SELECT SUM(Votante.votantes_analfabetos + Votante.votantes_alfabetos + Votante.votantes_primaria + Votante.votantes_nivelMedio + Votante.votantes_universitarios) AS Total_Votos_Jutiapa
                   FROM Votante
                   INNER JOIN Municipio ON Votante.municipio_id = Municipio.id_municipio
                   INNER JOIN Departamento ON Municipio.departamento_id_departamento = Departamento.id_departamento
                   INNER JOIN PaisRegion ON Departamento.paisregion_pais_id_pais = PaisRegion.pais_id_pais AND Departamento.paisregion_region_id_region = PaisRegion.region_id_region
                   INNER JOIN Pais ON PaisRegion.pais_id_pais = Pais.id_pais
                   WHERE Departamento.nombre = 'Guatemala')
ORDER BY
    Total_Votos DESC;
