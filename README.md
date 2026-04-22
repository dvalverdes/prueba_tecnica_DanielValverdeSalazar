# prueba_tecnica_DanielValverdeSalazar

# README — Registro de uso de IA

## Introducción

Esta prueba técnica fue desarrollada con apoyo de herramientas de IA como asistente para estructurar el trabajo, aclarar requerimientos, redactar entregables y acelerar la generación de borradores en SQL, Python y Markdown.

### Ambiente de trabajo utilizado
- **Google Colab** fue utilizado como entorno principal de trabajo.
- El archivo **`Datasets.zip`** se cargó en Colab y se descomprimió en la carpeta:
  - `/content/datasets`
- **Python + pandas** se utilizó para:
  - Bloque 0 de auditoría de datos
  - análisis exploratorio
  - evaluación estadística del A/B test
- **DuckDB** se instaló dentro de Colab y se utilizó para ejecutar SQL directamente sobre los archivos CSV.
- Se crearon vistas SQL sobre los archivos extraídos:
  - `transactions`
  - `transaction_items`
  - `stores`
  - `products`
  - `vendors`
  - `store_promotions`
- **draw.io** se utilizó para crear el diagrama del modelo dimensional.
- Los archivos en Markdown fueron redactados con apoyo de IA y luego ajustados para la entrega final.
- El contenido de la presentación ejecutiva en inglés fue redactado con apoyo de IA y luego preparado para exportarse a PDF.

### Nota general sobre el uso de IA
La IA se utilizó como:
- asistente de redacción
- asistente para borradores de SQL / Python
- asistente de estructura para los entregables
- herramienta de apoyo para interpretar requerimientos y diseñar el flujo de análisis

La IA **no** se utilizó como sustituto de validación. Los resultados fueron revisados, ajustados y ejecutados en Colab / DuckDB antes de formar parte de la solución final.

---

## Archivo: `bloque0_auditoria.md`

### Propósito
Realizar la auditoría de calidad de datos de los seis archivos CSV antes de cualquier análisis posterior.

### Principales prompts utilizados
- “Ayúdame a crear una guía táctica para resolver el Bloque 0 paso a paso usando los archivos CSV del ZIP.”
- “Explícame cómo validar completitud, consistencia, unicidad, validez, integridad referencial, frescura, integridad temporal e integridad del A/B test.”
- “Explícame cómo resolver la pregunta de completitud usando Python y los CSV directamente.”
- “Explícame línea por línea cómo funciona el cálculo de porcentajes en el análisis de completitud.”
- “Genera el texto en markdown para cada pregunta del Bloque 0 con: pregunta, objetivo, explicación del código y conclusión final.”
- “Ayúdame a estructurar cada sección del Bloque 0 usando markdown + código + conclusión.”

### Apoyo de IA aplicado en este archivo
- Estructuración de la lógica de auditoría
- Redacción de secciones Markdown para cada dimensión de calidad
- Explicación del código en Python y su interpretación
- Borradores del texto final de hallazgos y decisiones

### Nota importante
Los resultados reales fueron validados en Google Colab después de cargar y ejecutar los archivos CSV.

---

## Archivo: `bloque1_queries.sql`

### Propósito
Desarrollar queries SQL avanzadas para los casos analíticos solicitados.

### Principales prompts utilizados
- “Recomiéndame qué ambiente SQL usar si los datos están en archivos CSV y no en una base de datos.”
- “Explícame cómo usar DuckDB en Google Colab para consultar archivos CSV directamente.”
- “Ayudame a generar el SQL del Query 1 con comentarios paso a paso para comprender que se esta realizando y un objetivo en markdown.”
- “Ayudame a generar el SQL del Query 2 con comentarios paso a paso para comprender que se esta realizando y un objetivo en markdown.”
- “Ayudame a generar el SQL del Query 3 con comentarios paso a paso para comprender que se esta realizando y un objetivo en markdown.”
- “Ayudame a generar el SQL del Query 4 con comentarios paso a paso para comprender que se esta realizando y un objetivo en markdown.”
- “Ayudame a generar el SQL del Query 5 con comentarios paso a paso para comprender que se esta realizando y un objetivo en markdown.”
- “Ayudame a generar el SQL del Query 6 con comentarios paso a paso para comprender que se esta realizando y un objetivo en markdown.”
- “Explícame qué realiza cada query desde la perspectiva del negocio para poder explicarlo.”

### Apoyo de IA aplicado en este archivo
- Redacción de borradores de queries SQL
- Inclusión de comentarios explicativos dentro del SQL
- Redacción de objetivos en markdown para cada query
- Apoyo para interpretar el valor de negocio de cada query
- Explicación de conceptos analíticos utilizados

### Nota importante
Todos los queries SQL fueron ejecutados en DuckDB sobre los archivos CSV extraídos en Colab.

---

## Archivo: `bloque2_decisiones.md`

### Propósito
Documentar las decisiones del modelo dimensional, diseño ETL / ELT y gobernanza.

### Principales prompts utilizados
- “Propón un star schema en BigQuery que soporte comp sales, GMROI, cohortes, productividad y análisis de promociones.”
- “Ayudame a redactar la sección del modelo dimensional en Markdown, incluyendo tablas de hechos, dimensiones, campos clave y decisiones de diseño.”
- “Genera al menos 3 justificaciones de diseño, incluyendo cómo modelar el caso donde falta `customer_id`.”
- “Ayudame a redactar la sección del pipeline ETL / ELT en Markdown respondiendo cómo manejar late arrivals, monitoreo de frescura, cargas incrementales y refresh diario.”
- “Ayudane a redactar la sección de gobernanza en Markdown cubriendo calidad de datos, privacidad de `customer_id`, ownership, particionado, linaje y control de acceso.”

### Apoyo de IA aplicado en este archivo
- Diseño conceptual del star schema
- Redacción de la explicación del modelo dimensional
- Redacción de decisiones de diseño ETL / ELT
- Redacción de recomendaciones de gobernanza
- Conversión de todo el contenido a Markdown listo para entregar

---

## Archivo: `bloque2_modelo.pdf`

### Propósito
Presentar visualmente el modelo dimensional.

### Principales prompts utilizados
- “Genera un diagrama limpio del modelo dimensional con tablas de hechos y dimensiones para BigQuery.”
- “Ya tengo una idea de como crear el modelo con tabla hechos y dimensionales. Ahora quiero una imagen de referencia para usarla como guía en el diagrama de draw.io.”
- “Explícame cómo debe organizarse visualmente el modelo alrededor de la tabla de hechos principal.”

### Apoyo de IA aplicado en este archivo
- Generación de una imagen de referencia del star schema
- Apoyo visual para construir el diagrama en draw.io
- Clarificación de nombres de tablas, campos clave y relaciones

### Nota importante
El diagrama final fue recreado / adaptado manualmente en draw.io tomando como base el modelo diseñado.

---

## Archivo: `bloque3_analisis.ipynb` / salidas del notebook exploratorio

### Propósito
Resolver el análisis exploratorio y la experimentación.

### Principales prompts utilizados para la Parte A
- “Genera el SQL para estacionalidad semanal por formato.”
- “Genera el SQL para Pareto de categorías por formato.”
- “Genera el SQL para análisis de cohortes de lealtad con retención y ticket promedio.”
- “Genera el SQL y la lógica para analizar impacto de quiebres de stock por categoría y proveedor.”
- “Sugiere un hallazgo libre con valor de negocio usando los datos de promociones.”
- “Redacta conclusiones en markdown para cada pregunta exploratoria.”

### Principales prompts utilizados para la Parte B
- “Estructura la sección de A/B test con markdown + SQL + Python + conclusión.”
- “Genera las queries de validación de comparabilidad entre CONTROL y TREATMENT.”
- “Genera el flujo en SQL y Python para comparar GMV semanal por tienda entre CONTROL y TREATMENT.”
- “Incluye t-test, p-value, diferencia absoluta, lift relativo e intervalo de confianza 95%.”
- “Genera el flujo en SQL y Python para comparar ticket y frecuencia entre CONTROL y TREATMENT.”
- “Redacta la sección de decisión de negocio basada en p-value, tamaño del efecto y costo de implementación.”
- “Explícame qué significa p-value y qué significan CONTROL y TREATMENT en este experimento.”
- “Resúmeme qué debo comprender de la Parte A y Parte B para posibles preguntas en entrevista.”

### Apoyo de IA aplicado en este archivo
- Estructuración del notebook
- Redacción de queries SQL para el análisis
- Redacción de código Python para estadística
- Redacción de secciones markdown y conclusiones
- Explicación de la interpretación de los resultados
- Preparación de explicaciones tipo entrevista

### Nota importante
Los resultados no se tomaron de forma automática desde la IA. Fueron ejecutados y revisados dentro del notebook.

---

## Archivo: `bloque4_kpi_framework.md`

### Propósito
Diseñar un framework de KPIs desde cero para un programa de mejora de productividad de tiendas.

### Principales prompts utilizados
- “Crea un KPI framework de referencia en Markdown cubriendo productividad de tienda, experiencia del cliente y desempeño de proveedor.”
- “Incluye una North Star Metric, al menos un leading indicator y al menos un KPI compuesto.”
- “Para cada KPI define: definición exacta, fórmula, frecuencia, fuente de datos, target y cómo detectar problemas en la calidad del dato.”

### Apoyo de IA aplicado en este archivo
- Diseño del framework de KPIs
- Redacción de definiciones y fórmulas
- Propuesta de targets y controles de calidad de datos
- Selección de la North Star Metric
- Redacción del archivo Markdown final

---

## Archivo: Presentación ejecutiva del Bloque 5 (PDF)

### Propósito
Crear una presentación ejecutiva de 5 slides en inglés para el VP of Operations.

### Principales prompts utilizados
- “Ayudame a crear una presentación en ingles cpn la siguiente estructura: Executive Summary, Store Performance, Opportunities, Risks y Recommendations.”
- “Usa inglés claro y simple, bullets cortos y tono ejecutivo.”
- “Haz que cada recomendación incluya al menos un número.”
- “Crea una versión con tono más ejecutivo y mejor flujo entre hallazgos, riesgos y recomendaciones.”

### Apoyo de IA aplicado en este archivo
- Redacción del contenido de las slides
- Simplificación del inglés
- Estructuración narrativa de hallazgos y recomendaciones
- Alineación del flujo ejecutivo desde findings hasta actions

---

## Notas adicionales

### Tipos de prompts omitidos
Se omitieron del registro preguntas menores de troubleshooting que no aportan valor importante a la solución final, por ejemplo:
- errores puntuales de runtime
- preguntas de navegación en Colab
- aclaraciones menores de sintaxis sin impacto real en la lógica final

### Enfoque de validación
Todos los resultados importantes generados con apoyo de IA fueron:
- revisados manualmente
- ejecutados en el ambiente de trabajo cuando aplicaba
- ajustados para que coincidieran con el dataset y el requerimiento del ejercicio
- reescritos cuando fue necesario para mejorar calidad de entrega

---

## Declaración final
La IA fue utilizada como una **herramienta de apoyo**, todas las respuestas finales fueron revisadas manualmente para asegurar un output confiable.  
Los entregables finales fueron construidos con base en:
- ejecución en Google Colab
- validación SQL en DuckDB
- revisión manual de resultados
- interpretación alineada con el contexto de negocio de la prueba técnica
