-- Location dimension shared by both data sources
-- Grain: one row per distinct combination of borough and zip.

WITH stg_311 AS (
    SELECT * FROM {{ ref('stg_nyc_311_dot') }}
),

stg_second AS (
    SELECT * FROM {{ ref('stg_nyc_vehicle_crashes') }}
),

all_locations AS (
    SELECT DISTINCT
        borough,
        zip
    FROM stg_311
    WHERE borough IS NOT NULL
       OR zip IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT
        borough,
        zip
    FROM stg_second
    WHERE borough IS NOT NULL
       OR zip IS NOT NULL
),

location_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'borough', 'zip'
        ]) }} AS location_key,

        borough,
        zip

    FROM all_locations
),

-- Null placeholder row to handle NULL values.
null_placeholder AS (

    SELECT
        '-1' AS location_key,
        CAST(NULL AS STRING) AS borough,
        CAST(NULL AS STRING) AS zip
)

SELECT
    location_key,
    borough,
    zip
FROM location_dimension

UNION ALL

SELECT
    location_key,
    borough,
    zip
FROM null_placeholder