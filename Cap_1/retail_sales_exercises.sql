-- TENDENCIAS BASICAS --
SELECT
	sales_month,
    sales
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Retail and Food Services Sales, Total";

SELECT
    -- EXTRAE SOLO EL AÑO DE LAS VENTAS X MES  --
	EXTRACT(YEAR FROM sales_month) AS ventas_anuales,
    SUM(sales) AS ventas
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Retail and Food Services Sales, Total"
GROUP BY ventas_anuales;

-- TENDENCIAS COMPLEJAS --
SELECT
	EXTRACT(YEAR FROM sales_month) AS Año,
    kind_of_business,
    SUM(sales) AS Ventas
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business IN("Book Stores","Sporting goods stores","Hobby, toy, and game stores")
GROUP BY 1,2;

-- TENDENCIAS COMPLEJAS CON PORCENTAJES --
SELECT
	-- SOLO EXTRAE LA FECHA --
	DATE(sales_month) AS Mes_Venta,
    kind_of_business,
    sales
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business IN("Men's clothing stores","Women's clothing stores");

-- Lo mismo que se hizo en excel, solo que en SQL --
SELECT
	EXTRACT(YEAR FROM sales_month) AS Año,
    kind_of_business,
    SUM(sales)
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business IN("Men's clothing stores","Women's clothing stores")
GROUP BY 1,2;

-- Ventas de hombres VS mujeres
SELECT
	EXTRACT(YEAR FROM sales_month) AS Año,
    SUM(CASE WHEN kind_of_business = "Women's clothing stores" THEN sales END) AS ventas_mujeres,
    SUM(CASE WHEN kind_of_business = "Men's clothing stores" THEN sales END) AS ventas_hombres
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business IN ("Men's clothing stores","Women's clothing stores")
GROUP BY 1;

-- Diferencia entre las ventas de los hombres VS mujeres
SELECT
	Año,
    ventas_mujeres - ventas_hombres AS ventas_hombres_menos_mujeres
	FROM(SELECT
		EXTRACT(YEAR FROM sales_month) AS Año,
		SUM(CASE WHEN kind_of_business = "Women's clothing stores" THEN sales END) AS ventas_mujeres,
		SUM(CASE WHEN kind_of_business = "Men's clothing stores" THEN sales END) AS ventas_hombres
	FROM serie_de_tiempo.retail_sales
	WHERE kind_of_business IN ("Men's clothing stores","Women's clothing stores")
	GROUP BY 1) AS A;
    
-- Tasa entre hombres VS mujeres
SELECT
	Año,
    ventas_mujeres / ventas_hombres AS tasa_hombres_mujeres
	FROM(SELECT
		EXTRACT(YEAR FROM sales_month) AS Año,
		SUM(CASE WHEN kind_of_business = "Women's clothing stores" THEN sales END) AS ventas_mujeres,
		SUM(CASE WHEN kind_of_business = "Men's clothing stores" THEN sales END) AS ventas_hombres
	FROM serie_de_tiempo.retail_sales
	WHERE kind_of_business IN ("Men's clothing stores","Women's clothing stores")
	GROUP BY 1) AS A;
    
    -- Porcentaje de Hombres VS Mujeres --
    SELECT
    -- Selecciona el año de la subconsulta interna --
	Año,
    (ventas_hombres / ventas_mujeres)*100 AS porcentaje_hombres_mujeres
	FROM(SELECT
		EXTRACT(YEAR FROM sales_month) AS Año,
        -- Suma las ventas de las tiendas de ropa para mujeres y las renombra como ventas_mujeres --
		SUM(CASE WHEN kind_of_business = "Women's clothing stores" THEN sales END) AS ventas_mujeres,
        -- Suma las ventas de las tiendas de ropa para hombres y las renombra como ventas_hombres --
		SUM(CASE WHEN kind_of_business = "Men's clothing stores" THEN sales END) AS ventas_hombres
	FROM serie_de_tiempo.retail_sales
	WHERE kind_of_business IN ("Men's clothing stores","Women's clothing stores")
    -- Agrupa los resultados por año --
	GROUP BY 1) AS sales_men_and_woman_at_year;
    
    
    -- PORCENTAJE DEL TOTAL --
    -- Porcentaje del total de cada mes --
    
SELECT
    sales_month,
    kind_of_business,
    sales * 100 / ventas_totales AS pct_ventas_totales
FROM (
    SELECT
        a.sales_month,
        a.kind_of_business,
        a.sales,
        -- Subconsulta correlacionada que calcula la suma total de ventas para cada 'sales_month' y 'kind_of_business' especificados
        (SELECT 
			SUM(b.sales)
         FROM serie_de_tiempo.retail_sales b
         WHERE b.sales_month = a.sales_month
           -- Filtra las filas para incluir solo las tiendas de ropa de hombres y mujeres --
           AND b.kind_of_business IN ("Men's clothing stores", "Women's clothing stores")
        ) AS ventas_totales
    FROM serie_de_tiempo.retail_sales a
    WHERE a.kind_of_business IN ("Men's clothing stores", "Women's clothing stores")
) AS aa;

-- Self Join --
SELECT
    a.sales_month,
    a.kind_of_business,
    a.sales * 100 / b.ventas_totales AS pct_ventas_totales
FROM 
    serie_de_tiempo.retail_sales a
JOIN (
    SELECT
        sales_month,
        SUM(sales) AS ventas_totales
    FROM
        serie_de_tiempo.retail_sales
    WHERE
        kind_of_business IN ("Men's clothing stores", "Women's clothing stores")
    GROUP BY
        sales_month
) b ON a.sales_month = b.sales_month
WHERE
    a.kind_of_business IN ("Men's clothing stores", "Women's clothing stores");
	
    -- OVER
    -- Obtener las ventas mensuales, mostrando tanto el monto total de ventas por mes como... --
    -- el porcentaje que representan las ventas de cada fila dentro del total mensual. --
    SELECT
		sales_month,
        kind_of_business
        sales,
        SUM(sales) OVER (PARTITION BY sales_month) AS ventas_totales,
        sales * 100/SUM(sales) OVER (PARTITION BY sales_month)
    FROM retail_sales
    WHERE kind_of_business IN ("Men's clothing stores","Women's clothing stores");
    
    -- PORCENTAJE DEL TOTAL QUE CADA MES QUE REPRESENTA DE TODAS LAS VENTAS TOTALES AL AÑO --
    -- Self join --
    SELECT
		sales_month,
        kind_of_business,
        sales*100/ventas_anuales AS pct_total
    FROM(
		SELECT
			-- Selecciona tres columnas de la tabla --
			a.sales_month,
			a.kind_of_business,
			a.sales,
            -- Calcula la suma de las ventas de la tabla b --
			SUM(b.sales) AS ventas_anuales
		-- Realiza un JOIN de la tabla retail_sales consigo misma --
        FROM retail_sales a
		JOIN retail_sales b ON
			-- Une las filas donde el año de sales_month es igual en ambas tablas --
            EXTRACT(YEAR FROM a.sales_month) = EXTRACT(YEAR FROM b.sales_month)
				-- Une las filas donde kind_of_business es igual en ambas tablas --
                AND a.kind_of_business = b.kind_of_business
                -- Filtra las filas de b para incluir solo las tiendas de ropa de hombres y mujeres
				AND b.kind_of_business IN ("Men's clothing stores","Women's clothing stores")
		-- Filtra las filas de a para incluir solo las tiendas de ropa de hombres y mujeres
        WHERE a.kind_of_business IN ("Men's clothing stores","Women's clothing stores")
		-- Agrupa los resultados por sales_month, kind_of_business y sales
        GROUP BY 1,2,3) AS aa;
        
        
-- Over --
	--  Ventas anuales x tipo de negocio x año --
    SELECT 
		sales_month,
        kind_of_business,
        sales,
        -- Utiliza la función SUM para calcular el total de ventas (ventas_anuales) dentro de cada partición definida
        -- por el año (EXTRACT(YEAR FROM sales_month)) y el tipo de negocio (kind_of_business)
        SUM(sales) OVER (PARTITION BY EXTRACT(YEAR FROM sales_month),kind_of_business) AS ventas_anuales,
        -- Este cálculo da el porcentaje de las ventas de la fila actual con respecto al total anual de ventas para ese tipo de negocio.
        sales*100 /SUM(sales) OVER (PARTITION BY EXTRACT(YEAR FROM sales_month),kind_of_business) AS pct_anual
    -- Especifica que los datos se seleccionan de la tabla 'retail_sale'
    FROM retail_sales
	WHERE kind_of_business IN("Men's clothing stores","Women's clothing stores")
    -- Ordena los resultados por las columnas 'sales_month' (1ª columna) y 'kind_of_business' (2ª columna)
    ORDER BY 1,2;
    
    -- CAMBIO PORCENTUAL A LO LARGO DEL TIEMPO --
    
    SELECT
		año_venta,
        ventas,
        (ventas/FIRST_VALUE(ventas) OVER (ORDER BY año_venta)-1) * 100 AS indice_ventas
	FROM(-- Subconsulta
    SELECT
			-- Extrae el año de la columna y lo denomina 'sales_month' y lo denomina 'año_venta'
            EXTRACT(YEAR FROM sales_month) AS año_venta,
			SUM(sales) AS ventas
		-- Especifica la tabla de donde se extraen los datos
        FROM serie_de_tiempo.retail_sales
		WHERE kind_of_business = "Women's clothing stores"
		GROUP BY 1) AS ventas_año_mujer; -- La subconsulta agrupa las ventas por año para las tiendas de ropa de mujeres 
	
    -- Cambio porcentual (hombres vs mujeres)
    SELECT
		año_venta,
        kind_of_business,
        ventas,
        -- Calcula el índice de ventas (indice_ventas), 
        -- que es el cambio porcentual en las ventas en comparación con el primer año en la partición para cada tipo de negocio
        (ventas/FIRST_VALUE(ventas) OVER (PARTITION BY kind_of_business ORDER BY año_venta)-1) * 100 AS indice_ventas
	FROM(SELECT
			EXTRACT(YEAR FROM sales_month) AS año_venta,
            kind_of_business,
			SUM(sales) AS ventas
		-- Especifica la tabla de donde se extraen los datos
        FROM serie_de_tiempo.retail_sales
		WHERE kind_of_business IN("Men's clothing stores","Women's clothing stores")
		GROUP BY 1,2) AS ventas_año_negocio; -- La subconsulta agrupa las ventas por año y tipo de negocio

-- Promedio movil para las 12 meses (TTM) - Mujeres --
SELECT
	a.sales_month,
    a.sales,
    -- Calcula el promedio de las ventas (sales) de la tabla alias b y lo denomina ventas_moviles
    AVG(b.sales) AS ventas_moviles,
    COUNT(b.sales) AS numero_registros
FROM serie_de_tiempo.retail_sales a
-- Realiza un auto-join con la misma tabla retail_sales con el alias b
JOIN serie_de_tiempo.retail_sales b
	-- Establece la condición de unión donde el tipo de negocio en 'a' y 'b' debe ser el mismo
    ON a.kind_of_business = b.kind_of_business
    -- Establece la condición de que la fecha de ventas en 'b' debe estar en un rango de 11 meses antes hasta la fecha de ventas en 'a'
    AND b.sales_month BETWEEN a.sales_month - INTERVAL 11 MONTH
    AND a.sales_month
    AND b.kind_of_business = "Women's clothing stores"
WHERE a.kind_of_business = "Women's clothing stores"
GROUP BY 1,2
ORDER BY 1;

SELECT
	sales_month,
    -- Calcula el promedio de ventas (sales) usando una función de ventana
    -- AVG(sales): Calcula el promedio de las ventas.
	-- OVER: Define la ventana para la función de ventana.
	-- ORDER BY sales_month: Ordena las filas por sales_month.
	-- ROWS BETWEEN 11 PRECEDING AND CURRENT ROW:
		-- Define la ventana como las 11 filas anteriores más la fila actual, es decir, una ventana de 12 meses incluyendo el mes actual.
    AVG(sales) OVER (ORDER BY sales_month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS promedio_movil_ventas,
    -- COUNT(sales): Cuenta el número de registros de ventas.
	-- OVER: Define la ventana para la función de ventana.
	-- OORDER BY sales_month: Ordena las filas por sales_month..
	-- ROWS BETWEEN 11 PRECEDING AND CURRENT ROW:
		-- Define la ventana como las 11 filas anteriores más la fila actual, es decir, una ventana de 12 meses incluyendo el mes actual
    COUNT(sales) OVER (ORDER BY sales_month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS numero_registros
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business =  "Women's clothing stores";

-- ACOMULADO YTD
-- Over
SELECT
	DATE(sales_month) AS Mes_ventas,
    sales AS ventas,
	-- SUM(sales): Calcula la suma acumulada de las ventas.
	-- OVER: Define la ventana para la función de ventana.
	-- PARTITION BY EXTRACT(YEAR FROM sales_month): Divide las filas en particiones, donde cada partición corresponde a un año.
	-- ORDER BY sales_month: Dentro de cada partición (año), ordena las filas por sales_month.
    SUM(sales) OVER (PARTITION BY EXTRACT(YEAR FROM sales_month) ORDER BY sales_month) AS ventas_ytd
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Women's clothing stores";



SELECT 
	kind_of_business,
    sales_month,
    sales AS ventas,
	-- LAG(sales_month) OVER (PARTITION BY kind_of_business ORDER BY sales_month) AS mes_previo --
	-- Usa la función de ventana LAG para obtener el valor de sales_month de la fila anterior dentro de la misma partición.
	-- Renombra el resultado como mes_previo.
    LAG(sales_month) OVER (PARTITION BY kind_of_business ORDER BY sales_month) AS mes_previo,
    LAG (sales) OVER (PARTITION BY kind_of_business ORDER BY sales_month) AS ventas_mes_previo
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Book Stores";

-- CALCULO EL CRECIMIENTO PORCENTUAL DE LAS VENTAS PARA CADA MES EN COMPARACIÓN CON EL MES ANTERIOR, PARA "BOOK STORES"
SELECT 
	kind_of_business,
    sales_month,
    sales AS ventas,
    -- Usa la función de ventana LAG para obtener el valor de 'sales_month'de la fila anterior dentro de la misma partición.
    LAG(sales_month) OVER (PARTITION BY kind_of_business ORDER BY sales_month) AS mes_previo,
     -- Usa la función de ventana LAG para obtener el valor de 'sales'de la fila anterior dentro de la misma partición.
    LAG (sales) OVER (PARTITION BY kind_of_business ORDER BY sales_month) AS ventas_mes_previo,
    -- Calcula el porcentaje de crecimiento de las ventas para cada mes en comparación con el mes anterior.
    -- Esta fórmula calcula la diferencia entre las ventas del mes actual y las ventas del mes anterior, divide por las ventas del mes anterior y resta 1.
    -- Luego, multiplica por 100 para expresar el resultado como un porcentaje.
    (sales / LAG (sales) OVER (PARTITION BY kind_of_business ORDER BY sales_month) -1)*100 AS pct_crecimiento
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Book Stores";


SELECT
	año_ventas,
    ventas_anuales,
    LAG(ventas_anuales) OVER (ORDER BY año_ventas) AS ventas_año_previo,
    -- Calcula la diferencia entre las ventas anuales actuales y las ventas anuales del año anterior, divide por las ventas anuales del año anterior y resta 1.
    -- Luego, multiplica por 100 para expresar el resultado como un porcentaje.
    (ventas_anuales / LAG(ventas_anuales) OVER (ORDER BY año_ventas)-1)*100 AS pct_crecimiento
FROM( -- Cálculo preciso del crecimiento porcentual anual de las ventas
	SELECT
		EXTRACT(YEAR FROM sales_month) AS año_ventas,
		SUM(sales) AS ventas_anuales
	FROM serie_de_tiempo.retail_sales
	WHERE kind_of_business = "Book Stores"
	GROUP BY 1) AS crecimiento_porcentual_anual;
    
-- MISMO MES VS AÑO PASADO --
SELECT
	sales_month,
    EXTRACT(MONTH FROM sales_month) AS mes
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Book Stores"
ORDER BY EXTRACT(MONTH FROM sales_month);

SELECT
	sales_month,
    sales,
    EXTRACT(MONTH FROM sales_month) AS mes,
    LAG(sales_month) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS mes_año_previo,
    LAG (sales) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS ventas_año_previo
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Book Stores";

-- Porcentaje de Diferencia --
SELECT
	sales_month,
    sales,
    EXTRACT(MONTH FROM sales_month) AS mes,
    -- El código utiliza la función de ventana 'LAG' con partición por 'EXTRACT(MONTH FROM sales_month)'.
    -- Esto asegura que los cálculos se realicen dentro del mismo mes (enero, febrero, etc.)
    LAG(sales_month) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS mes_año_previo,
    -- 'LAG' recupera el valor de la fila anterior en base al orden especificado por 'ORDER BY' sales_month
    LAG (sales) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS ventas_año_previo,
    -- Resta las ventas_año_previo (ventas del mes anterior) de las sales del mes actual.
    sales - LAG (sales) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS diferencia_absoluta,
    -- Calcula la diferencia en ventas en comparación con el mes anterior y la expresa como un porcentaje
    (sales / LAG (sales) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month)-1)*100 AS pct_diferencia
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Book Stores";

-- Varios Periodos --
SELECT
	sales_month,
    sales,
    -- El código utiliza la función de ventana 'LAG' con partición por 'EXTRACT(MONTH FROM sales_month)'.
    -- Esto asegura que los cálculos se realicen dentro del mismo mes (enero, febrero, etc.)
    -- 'LAG(sales, N)' recupera el valor de sales de 'N' filas atrás dentro de la misma partición de mes, ordenadas por 'sales_month'
    LAG(sales,1) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS ventas_previas_1,
    LAG(sales,2) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS ventas_previas_2,
    LAG(sales,3) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month) ORDER BY sales_month) AS ventas_previas_3
FROM retail_sales
WHERE kind_of_business = "Book stores";

-- Calculo el porcentaje de ventas para cada mes en comparación con el promedio de ventas de los tres meses anteriores para el tipo de negocio
SELECT
	sales_month,
    sales AS Ventas,
    -- La consulta utiliza la función de ventana 'AVG' con partición por 'EXTRACT(MONTH FROM sales_month)'.
    -- Esto garantiza que el promedio se calcule únicamente para las ventas dentro del mismo mes.
    -- La cláusula 'ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING' especifica que el promedio se calcule utilizando las ventas de los tres meses anteriores
    -- (3 PRECEDING) al mes actual y el mes anterior (1 PRECEDING) al mes actual
    sales / AVG(sales) OVER (PARTITION BY EXTRACT(MONTH FROM sales_month)  ORDER BY sales_month ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS pct_ventas
FROM serie_de_tiempo.retail_sales
WHERE kind_of_business = "Book Stores";
