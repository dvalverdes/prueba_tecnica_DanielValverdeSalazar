
-- =========================================================
-- BLOQUE 1 - SQL AVANZADO
-- Entregable: bloque1_queries.sql
-- =========================================================


-- =========================================================
-- Query 1: Ventas comparables (Comp Sales)
-- =========================================================

-- Objetivo:
-- Calcular GMV año actual vs año anterior, crecimiento YoY y ranking de tiendas
-- para tiendas comparables: aquellas que estuvieron operando en ambos periodos
-- y que además fueron abiertas al menos 13 meses antes del fin del periodo actual.

WITH fecha_referencia AS (
    SELECT
        MAX(CAST(transaction_date AS DATE)) AS max_tx_date
    FROM transactions
),

-- Define dos ventanas: actual: últimos 12 meses // anterior: 12 meses previos

periodos AS (
    SELECT
        max_tx_date,
        max_tx_date - INTERVAL '11 months' AS current_start_date,
        max_tx_date - INTERVAL '23 months' AS prior_start_date,
        max_tx_date - INTERVAL '12 months' AS prior_end_date
    FROM fecha_referencia
),

-- Filtra solo tiendas abiertas al menos 13 meses antes de la fecha máxima.

tiendas_elegibles AS (
    SELECT
        s.store_id,
        s.store_name,
        s.country,
        s.format,
        s.opening_date
    FROM stores s
    CROSS JOIN periodos p
    WHERE CAST(s.opening_date AS DATE) <= p.max_tx_date - INTERVAL '13 months'
),

-- Suma el total_amount por tienda, separando ventas del período actual y anterior.

ventas_periodizadas AS (
    SELECT
        t.store_id,
        te.store_name,
        te.country,
        te.format,
        CASE
            WHEN CAST(t.transaction_date AS DATE) BETWEEN p.current_start_date AND p.max_tx_date
                THEN 'CURRENT'
            WHEN CAST(t.transaction_date AS DATE) BETWEEN p.prior_start_date AND p.prior_end_date
                THEN 'PRIOR'
        END AS period_type,
        SUM(t.total_amount) AS gmv
    FROM transactions t
    INNER JOIN tiendas_elegibles te
        ON t.store_id = te.store_id
    CROSS JOIN periodos p
    WHERE CAST(t.transaction_date AS DATE) BETWEEN p.prior_start_date AND p.max_tx_date
    GROUP BY
        t.store_id,
        te.store_name,
        te.country,
        te.format,
        CASE
            WHEN CAST(t.transaction_date AS DATE) BETWEEN p.current_start_date AND p.max_tx_date
                THEN 'CURRENT'
            WHEN CAST(t.transaction_date AS DATE) BETWEEN p.prior_start_date AND p.prior_end_date
                THEN 'PRIOR'
        END
),

-- Se queda solo con tiendas que tienen ventas en ambos períodos.

tiendas_comparables AS (
    SELECT
        store_id
    FROM ventas_periodizadas
    GROUP BY store_id
    HAVING COUNT(DISTINCT period_type) = 2
),

-- Arma el GMV del año actual y del año anterior por tienda.

comp_sales_por_tienda AS (
    SELECT
        vp.store_id,
        vp.store_name,
        vp.country,
        vp.format,
        SUM(CASE WHEN vp.period_type = 'CURRENT' THEN vp.gmv ELSE 0 END) AS gmv_current_year,
        SUM(CASE WHEN vp.period_type = 'PRIOR' THEN vp.gmv ELSE 0 END) AS gmv_prior_year
    FROM ventas_periodizadas vp
    INNER JOIN tiendas_comparables tc
        ON vp.store_id = tc.store_id
    GROUP BY
        vp.store_id,
        vp.store_name,
        vp.country,
        vp.format
),


-- Calcula: crecimiento porcentual YoY // ranking por crecimiento dentro de country + format

resultado_final AS (
    SELECT
        store_id,
        store_name,
        country,
        format,
        gmv_current_year,
        gmv_prior_year,
        ROUND(
            ((gmv_current_year - gmv_prior_year) * 100.0) / NULLIF(gmv_prior_year, 0),
            2
        ) AS comp_sales_growth_pct,
        RANK() OVER (
            PARTITION BY country, format
            ORDER BY ((gmv_current_year - gmv_prior_year) / NULLIF(gmv_prior_year, 0)) DESC
        ) AS growth_rank_within_format
    FROM comp_sales_por_tienda
)

SELECT
    store_id,
    store_name,
    country,
    format,
    gmv_current_year,
    gmv_prior_year,
    comp_sales_growth_pct,
    growth_rank_within_format
FROM resultado_final
ORDER BY country, format, growth_rank_within_format, store_id;


-- =========================================================
-- Query 2: Productividad por metro cuadrado
-- =========================================================

-- Objetivo:
-- Para cada tienda calcular en el último trimestre del dataset:
-- 1) GMV total
-- 2) GMV por metro cuadrado
-- 3) Número de transacciones por metro cuadrado
-- 4) Ticket promedio
-- 5) Ranking dentro de su formato
-- 6) Bandera BAJO_RENDIMIENTO si está por debajo del percentil 25 de GMV/m² en su formato

WITH fecha_referencia AS (
    -- Tomamos la fecha máxima del dataset para definir el cierre del análisis
    SELECT
        MAX(CAST(transaction_date AS DATE)) AS max_tx_date
    FROM transactions
),

ultimo_trimestre AS (
    -- Definimos la ventana del último trimestre:
    -- desde 2 meses antes de la fecha máxima hasta la fecha máxima
    SELECT
        max_tx_date,
        max_tx_date - INTERVAL '2 months' AS quarter_start_date
    FROM fecha_referencia
),

ventas_trimestre AS (
    -- Filtramos solo las transacciones que caen dentro del último trimestre
    SELECT
        t.transaction_id,
        t.store_id,
        CAST(t.transaction_date AS DATE) AS transaction_date,
        t.total_amount
    FROM transactions t
    CROSS JOIN ultimo_trimestre u
    WHERE CAST(t.transaction_date AS DATE) BETWEEN u.quarter_start_date AND u.max_tx_date
),

metricas_por_tienda AS (
    -- Calculamos métricas operativas por tienda:
    -- GMV total, cantidad de transacciones y ticket promedio
    SELECT
        s.store_id,
        s.store_name,
        s.country,
        s.format,
        s.size_sqm,
        SUM(v.total_amount) AS gmv_total_qtr,
        COUNT(DISTINCT v.transaction_id) AS total_transactions_qtr,
        AVG(v.total_amount) AS avg_ticket_qtr
    FROM stores s
    INNER JOIN ventas_trimestre v
        ON s.store_id = v.store_id
    GROUP BY
        s.store_id,
        s.store_name,
        s.country,
        s.format,
        s.size_sqm
),

productividad_tienda AS (
    -- Derivamos los indicadores por metro cuadrado
    SELECT
        store_id,
        store_name,
        country,
        format,
        size_sqm,
        gmv_total_qtr,
        total_transactions_qtr,
        avg_ticket_qtr,
        ROUND(gmv_total_qtr / NULLIF(size_sqm, 0), 2) AS gmv_per_sqm,
        ROUND(total_transactions_qtr * 1.0 / NULLIF(size_sqm, 0), 4) AS transactions_per_sqm
    FROM metricas_por_tienda
),

percentiles_formato AS (
    -- Calculamos el percentil 25 de GMV/m² por formato
    SELECT
        format,
        quantile_cont(gmv_per_sqm, 0.25) AS p25_gmv_per_sqm
    FROM productividad_tienda
    GROUP BY format
),

resultado_final AS (
    -- Unimos cada tienda con el percentil de su formato,
    -- calculamos ranking y marcamos bajo rendimiento
    SELECT
        p.store_id,
        p.store_name,
        p.country,
        p.format,
        p.size_sqm,
        p.gmv_total_qtr,
        p.gmv_per_sqm,
        p.transactions_per_sqm,
        ROUND(p.avg_ticket_qtr, 2) AS avg_ticket_qtr,
        pf.p25_gmv_per_sqm,
        CASE
            WHEN p.gmv_per_sqm < pf.p25_gmv_per_sqm THEN 'BAJO_RENDIMIENTO'
            ELSE 'OK'
        END AS performance_flag,
        RANK() OVER (
            PARTITION BY p.format
            ORDER BY p.gmv_per_sqm DESC
        ) AS rank_within_format
    FROM productividad_tienda p
    INNER JOIN percentiles_formato pf
        ON p.format = pf.format
)

SELECT
    store_id,
    store_name,
    country,
    format,
    size_sqm,
    gmv_total_qtr,
    gmv_per_sqm,
    transactions_per_sqm,
    avg_ticket_qtr,
    ROUND(p25_gmv_per_sqm, 2) AS p25_gmv_per_sqm,
    performance_flag,
    rank_within_format
FROM resultado_final
ORDER BY format, rank_within_format, store_id;


-- =========================================================
-- Query 3: Análisis de cohortes de clientes con tarjeta de lealtad
-- =========================================================

-- Objetivo:
-- 1) Tomar solo clientes identificados con loyalty_card = TRUE
-- 2) Definir la cohorte como el mes de la primera transacción de cada cliente
-- 3) Calcular para cada cohorte:
--    - tamaño de la cohorte
--    - clientes únicos activos por mes desde la cohorte
--    - tasa de retención para meses 1, 2, 3 y 6
--    - ticket promedio por período
-- 4) Entregar una salida tipo pivote con cohortes en filas

WITH loyalty_transactions AS (
    -- Filtramos solo transacciones con tarjeta de lealtad
    -- y customer_id válido, porque solo estas sirven para construir cohortes
    SELECT
        customer_id,
        transaction_id,
        CAST(transaction_date AS DATE) AS transaction_date,
        DATE_TRUNC('month', CAST(transaction_date AS DATE)) AS transaction_month,
        total_amount
    FROM transactions
    WHERE loyalty_card = TRUE
      AND customer_id IS NOT NULL
),

first_purchase AS (
    -- Identificamos el mes de primera compra de cada cliente
    -- ese será el mes de cohorte
    SELECT
        customer_id,
        MIN(transaction_month) AS cohort_month
    FROM loyalty_transactions
    GROUP BY customer_id
),

cohort_base AS (
    -- Asociamos cada transacción del cliente con su cohorte
    -- y calculamos cuántos meses han pasado desde la cohorte
    SELECT
        lt.customer_id,
        fp.cohort_month,
        lt.transaction_month,
        lt.total_amount,
        (
            EXTRACT(YEAR FROM lt.transaction_month) * 12 + EXTRACT(MONTH FROM lt.transaction_month)
            - EXTRACT(YEAR FROM fp.cohort_month) * 12 - EXTRACT(MONTH FROM fp.cohort_month)
        ) AS month_number
    FROM loyalty_transactions lt
    INNER JOIN first_purchase fp
        ON lt.customer_id = fp.customer_id
),

cohort_size AS (
    -- Calculamos el tamaño de cada cohorte:
    -- cantidad de clientes únicos cuyo primer mes fue cohort_month
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),

activity_by_cohort AS (
    -- Para cada cohorte y mes desde la cohorte calculamos:
    -- clientes activos únicos y ticket promedio del período
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers,
        AVG(total_amount) AS avg_ticket
    FROM cohort_base
    GROUP BY
        cohort_month,
        month_number
),

cohort_metrics AS (
    -- Unimos el tamaño de cohorte con la actividad
    -- y calculamos la tasa de retención
    SELECT
        a.cohort_month,
        c.cohort_size,
        a.month_number,
        a.active_customers,
        ROUND((a.active_customers * 100.0) / NULLIF(c.cohort_size, 0), 2) AS retention_rate_pct,
        ROUND(a.avg_ticket, 2) AS avg_ticket
    FROM activity_by_cohort a
    INNER JOIN cohort_size c
        ON a.cohort_month = c.cohort_month
),

pivot_retention AS (
    -- Pivoteamos la retención para los meses clave solicitados
    SELECT
        cohort_month,
        MAX(cohort_size) AS cohort_size,
        MAX(CASE WHEN month_number = 0 THEN active_customers END) AS month_0_customers,
        MAX(CASE WHEN month_number = 1 THEN retention_rate_pct END) AS retention_m1_pct,
        MAX(CASE WHEN month_number = 2 THEN retention_rate_pct END) AS retention_m2_pct,
        MAX(CASE WHEN month_number = 3 THEN retention_rate_pct END) AS retention_m3_pct,
        MAX(CASE WHEN month_number = 6 THEN retention_rate_pct END) AS retention_m6_pct,
        MAX(CASE WHEN month_number = 0 THEN avg_ticket END) AS avg_ticket_m0,
        MAX(CASE WHEN month_number = 1 THEN avg_ticket END) AS avg_ticket_m1,
        MAX(CASE WHEN month_number = 2 THEN avg_ticket END) AS avg_ticket_m2,
        MAX(CASE WHEN month_number = 3 THEN avg_ticket END) AS avg_ticket_m3,
        MAX(CASE WHEN month_number = 6 THEN avg_ticket END) AS avg_ticket_m6
    FROM cohort_metrics
    GROUP BY cohort_month
)

SELECT
    cohort_month,
    cohort_size,
    month_0_customers,
    retention_m1_pct,
    retention_m2_pct,
    retention_m3_pct,
    retention_m6_pct,
    avg_ticket_m0,
    avg_ticket_m1,
    avg_ticket_m2,
    avg_ticket_m3,
    avg_ticket_m6
FROM pivot_retention
ORDER BY cohort_month;


-- =========================================================
-- Query 4: GMROI por proveedor y categoría
-- =========================================================

-- Objetivo:
-- 1) Unir transaction_items con products y vendors
-- 2) Calcular ventas, costo y margen por proveedor y categoría
-- 3) Calcular GMROI = margen_bruto / costo_total
-- 4) Marcar como alerta cuando GMROI < 1

WITH ventas_detalle AS (
    -- Tomamos el detalle de venta por item y lo enriquecemos con producto y proveedor
    -- unit_price representa el precio de venta por unidad
    -- cost representa el costo unitario del producto
    SELECT
        ti.transaction_id,
        ti.item_id,
        ti.quantity,
        ti.unit_price,
        p.item_name,
        p.category,
        p.vendor_id,
        v.vendor_name,
        p.cost
    FROM transaction_items ti
    INNER JOIN products p
        ON ti.item_id = p.item_id
    INNER JOIN vendors v
        ON p.vendor_id = v.vendor_id
),

metricas_vendor_categoria AS (
    -- Calculamos:
    -- GMV = precio de venta * cantidad
    -- costo total = costo unitario * cantidad
    -- margen bruto = GMV - costo total
    -- unidades activas = suma de quantity
    SELECT
        vendor_id,
        vendor_name,
        category,
        SUM(unit_price * quantity) AS gmv,
        SUM(cost * quantity) AS total_cost,
        SUM((unit_price - cost) * quantity) AS gross_margin,
        SUM(quantity) AS active_units
    FROM ventas_detalle
    GROUP BY
        vendor_id,
        vendor_name,
        category
),

resultado_final AS (
    -- Calculamos GMROI y marcamos alerta cuando es menor que 1
    SELECT
        vendor_id,
        vendor_name,
        category,
        active_units,
        ROUND(gmv, 2) AS gmv,
        ROUND(total_cost, 2) AS total_cost,
        ROUND(gross_margin, 2) AS gross_margin,
        ROUND(gross_margin / NULLIF(total_cost, 0), 4) AS gmroi,
        CASE
            WHEN (gross_margin / NULLIF(total_cost, 0)) < 1 THEN 'GMROI_LT_1'
            ELSE 'OK'
        END AS gmroi_flag
    FROM metricas_vendor_categoria
)

SELECT
    vendor_id,
    vendor_name,
    category,
    active_units,
    gmv,
    total_cost,
    gross_margin,
    gmroi,
    gmroi_flag
FROM resultado_final
ORDER BY gmroi ASC, vendor_name, category;


-- =========================================================
-- Query 5: Detección de posibles quiebres de stock
-- =========================================================

-- Objetivo:
-- 1) Construir ventas diarias por tienda-item
-- 2) Generar calendario diario entre primera y última venta de cada tienda-item
-- 3) Detectar días sin venta
-- 4) Agrupar días consecutivos sin venta en gaps
-- 5) Quedarse solo con gaps de 3 o más días
-- 6) Calcular promedio diario previo al gap y GMV estimado perdido
-- 7) Ordenar por GMV perdido estimado desc

WITH ventas_diarias AS (
    -- Calculamos ventas diarias por tienda-item
    -- GMV diario = suma de unit_price * quantity en cada fecha
    SELECT
        t.store_id,
        s.store_name,
        ti.item_id,
        p.item_name,
        p.category,
        CAST(t.transaction_date AS DATE) AS sale_date,
        SUM(ti.quantity) AS qty_sold,
        SUM(ti.unit_price * ti.quantity) AS gmv_sold
    FROM transaction_items ti
    INNER JOIN transactions t
        ON ti.transaction_id = t.transaction_id
    INNER JOIN stores s
        ON t.store_id = s.store_id
    INNER JOIN products p
        ON ti.item_id = p.item_id
    GROUP BY
        t.store_id,
        s.store_name,
        ti.item_id,
        p.item_name,
        p.category,
        CAST(t.transaction_date AS DATE)
),

rangos_tienda_item AS (
    -- Para cada tienda-item obtenemos el rango entre primera y última venta
    SELECT
        store_id,
        store_name,
        item_id,
        item_name,
        category,
        MIN(sale_date) AS min_sale_date,
        MAX(sale_date) AS max_sale_date
    FROM ventas_diarias
    GROUP BY
        store_id,
        store_name,
        item_id,
        item_name,
        category
),

calendario_tienda_item AS (
    -- Generamos un calendario diario completo por tienda-item
    -- usando generate_series entre la primera y última venta observada
    SELECT
        r.store_id,
        r.store_name,
        r.item_id,
        r.item_name,
        r.category,
        gs.generate_series AS calendar_date
    FROM rangos_tienda_item r,
    generate_series(r.min_sale_date, r.max_sale_date, INTERVAL '1 day') AS gs
),

base_completa AS (
    -- Unimos el calendario con las ventas diarias reales
    -- Si no hubo venta ese día, qty_sold y gmv_sold quedan en 0
    SELECT
        c.store_id,
        c.store_name,
        c.item_id,
        c.item_name,
        c.category,
        c.calendar_date,
        COALESCE(v.qty_sold, 0) AS qty_sold,
        COALESCE(v.gmv_sold, 0) AS gmv_sold
    FROM calendario_tienda_item c
    LEFT JOIN ventas_diarias v
        ON c.store_id = v.store_id
       AND c.item_id = v.item_id
       AND c.calendar_date = v.sale_date
),

dias_sin_venta AS (
    -- Nos quedamos solo con los días donde no hubo venta
    SELECT
        *,
        calendar_date
          - INTERVAL '1 day' * ROW_NUMBER() OVER (
                PARTITION BY store_id, item_id
                ORDER BY calendar_date
            ) AS grp_gap
    FROM base_completa
    WHERE qty_sold = 0
),

gaps_consecutivos AS (
    -- Agrupamos días consecutivos sin venta en un mismo gap
    SELECT
        store_id,
        store_name,
        item_id,
        item_name,
        category,
        MIN(calendar_date) AS gap_start_date,
        MAX(calendar_date) AS gap_end_date,
        COUNT(*) AS gap_days
    FROM dias_sin_venta
    GROUP BY
        store_id,
        store_name,
        item_id,
        item_name,
        category,
        grp_gap
),

gaps_filtrados AS (
    -- Conservamos solo los posibles quiebres:
    -- gaps de 3 o más días consecutivos sin venta
    SELECT
        *
    FROM gaps_consecutivos
    WHERE gap_days >= 3
),

ventas_previas AS (
    -- Para cada gap calculamos el GMV promedio diario antes del inicio del gap.
    -- Aquí usamos una ventana histórica de 30 días previos al gap.
    -- Solo promediamos sobre días con venta registrada del mismo tienda-item.
    SELECT
        g.store_id,
        g.item_id,
        g.gap_start_date,
        AVG(b.gmv_sold) AS avg_daily_gmv_before_gap
    FROM gaps_filtrados g
    INNER JOIN base_completa b
        ON g.store_id = b.store_id
       AND g.item_id = b.item_id
       AND b.calendar_date BETWEEN g.gap_start_date - INTERVAL '30 day' AND g.gap_start_date - INTERVAL '1 day'
       AND b.gmv_sold > 0
    GROUP BY
        g.store_id,
        g.item_id,
        g.gap_start_date
),

resultado_final AS (
    -- Calculamos el GMV estimado perdido
    -- GMV perdido estimado = promedio diario previo * duración del gap
    SELECT
        g.store_id,
        g.store_name,
        g.item_id,
        g.item_name,
        g.category,
        g.gap_start_date,
        g.gap_end_date,
        g.gap_days,
        ROUND(vp.avg_daily_gmv_before_gap, 2) AS avg_daily_gmv_before_gap,
        ROUND(vp.avg_daily_gmv_before_gap * g.gap_days, 2) AS estimated_gmv_lost
    FROM gaps_filtrados g
    LEFT JOIN ventas_previas vp
        ON g.store_id = vp.store_id
       AND g.item_id = vp.item_id
       AND g.gap_start_date = vp.gap_start_date
)

SELECT
    store_id,
    store_name,
    item_id,
    item_name,
    category,
    gap_start_date,
    gap_end_date,
    gap_days,
    avg_daily_gmv_before_gap,
    estimated_gmv_lost
FROM resultado_final
ORDER BY estimated_gmv_lost DESC NULLS LAST, gap_days DESC, store_id, item_id;


-- =========================================================
-- Query 6: Impacto de promociones en ticket y volumen
-- =========================================================

-- Objetivo:
-- 1) Clasificar cada transacción-categoría según tenga o no al menos un ítem en promoción
-- 2) Calcular ticket y unidades por transacción-categoría
-- 3) Comparar por categoría los promedios entre transacciones con promo vs sin promo
-- 4) Generar una lectura simple del posible efecto: basket uplift vs solo descuento

WITH transaccion_categoria AS (
    -- Construimos una base por transacción y categoría
    -- Aquí calculamos:
    -- - unidades totales compradas en esa categoría dentro de la transacción
    -- - GMV total de esa categoría dentro de la transacción
    -- - bandera de si hubo al menos un ítem en promoción
    SELECT
        ti.transaction_id,
        p.category,
        SUM(ti.quantity) AS total_units_in_txn_category,
        SUM(ti.unit_price * ti.quantity) AS total_gmv_in_txn_category,
        MAX(CASE WHEN ti.was_on_promo = TRUE THEN 1 ELSE 0 END) AS has_promo_item
    FROM transaction_items ti
    INNER JOIN products p
        ON ti.item_id = p.item_id
    GROUP BY
        ti.transaction_id,
        p.category
),

metricas_por_categoria_y_promo AS (
    -- Agrupamos por categoría y por condición promocional
    -- para obtener ticket promedio, unidades promedio y conteo de transacciones
    SELECT
        category,
        CASE
            WHEN has_promo_item = 1 THEN 'CON_PROMO'
            ELSE 'SIN_PROMO'
        END AS promo_group,
        COUNT(*) AS transaction_count,
        ROUND(AVG(total_gmv_in_txn_category), 2) AS avg_ticket,
        ROUND(AVG(total_units_in_txn_category), 2) AS avg_units
    FROM transaccion_categoria
    GROUP BY
        category,
        CASE
            WHEN has_promo_item = 1 THEN 'CON_PROMO'
            ELSE 'SIN_PROMO'
        END
),

resultado_pivoteado AS (
    -- Pivoteamos para dejar una fila por categoría y comparar fácilmente
    SELECT
        category,
        MAX(CASE WHEN promo_group = 'CON_PROMO' THEN transaction_count END) AS tx_con_promo,
        MAX(CASE WHEN promo_group = 'SIN_PROMO' THEN transaction_count END) AS tx_sin_promo,
        MAX(CASE WHEN promo_group = 'CON_PROMO' THEN avg_ticket END) AS avg_ticket_con_promo,
        MAX(CASE WHEN promo_group = 'SIN_PROMO' THEN avg_ticket END) AS avg_ticket_sin_promo,
        MAX(CASE WHEN promo_group = 'CON_PROMO' THEN avg_units END) AS avg_units_con_promo,
        MAX(CASE WHEN promo_group = 'SIN_PROMO' THEN avg_units END) AS avg_units_sin_promo
    FROM metricas_por_categoria_y_promo
    GROUP BY category
),

resultado_final AS (
    -- Calculamos diferencias y una interpretación simple:
    -- - Si suben unidades, puede haber basket uplift
    -- - Si no suben unidades pero baja ticket, parece más descuento que volumen incremental
    SELECT
        category,
        tx_con_promo,
        tx_sin_promo,
        avg_ticket_con_promo,
        avg_ticket_sin_promo,
        avg_units_con_promo,
        avg_units_sin_promo,
        ROUND(avg_ticket_con_promo - avg_ticket_sin_promo, 2) AS diff_ticket,
        ROUND(avg_units_con_promo - avg_units_sin_promo, 2) AS diff_units,
        CASE
            WHEN avg_units_con_promo > avg_units_sin_promo AND avg_ticket_con_promo >= avg_ticket_sin_promo
                THEN 'POSIBLE_BASKET_UPLIFT'
            WHEN avg_units_con_promo > avg_units_sin_promo AND avg_ticket_con_promo < avg_ticket_sin_promo
                THEN 'MAS_UNIDADES_CON_DESCUENTO'
            WHEN avg_units_con_promo <= avg_units_sin_promo AND avg_ticket_con_promo < avg_ticket_sin_promo
                THEN 'POSIBLE_SOLO_DESCUENTO'
            ELSE 'MIXTO_O_INCONCLUSO'
        END AS promo_impact_reading
    FROM resultado_pivoteado
)

SELECT
    category,
    tx_con_promo,
    tx_sin_promo,
    avg_ticket_con_promo,
    avg_ticket_sin_promo,
    avg_units_con_promo,
    avg_units_sin_promo,
    diff_ticket,
    diff_units,
    promo_impact_reading
FROM resultado_final
ORDER BY category;

