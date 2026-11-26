-- Clean and standardize NYC Motor Vehicle Collisions data
-- One row per collision

WITH source AS (
    SELECT *
    FROM {{ source('nyc_project_raw_data', 'source_motor_vehicle_collisions') }}
),

cleaned AS (
    SELECT
        * EXCEPT (
            collision_id,
            crash_date,
            crash_time,
            borough,
            zip_code,
            on_street_name,
            cross_street_name,
            off_street_name,
            latitude,
            longitude,
            number_of_persons_injured,
            number_of_persons_killed,
            number_of_pedestrians_injured,
            number_of_pedestrians_killed,
            number_of_cyclist_injured,
            number_of_cyclist_killed,
            number_of_motorist_injured,
            number_of_motorist_killed,
            contributing_factor_vehicle_1,
            contributing_factor_vehicle_2,
            vehicle_type_code1,
            vehicle_type_code2
        ),

        -- Identifiers
        CAST(collision_id AS STRING) AS collision_id,

        -- Date / Time
        CAST(crash_date AS DATE) AS crash_date,
        CAST(crash_time AS STRING) AS crash_time,

        -- Conformed location fields
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        CASE
            WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN UPPER(TRIM(CAST(zip_code AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN LENGTH(TRIM(CAST(zip_code AS STRING))) = 5 THEN TRIM(CAST(zip_code AS STRING))
            WHEN LENGTH(TRIM(CAST(zip_code AS STRING))) = 9 THEN TRIM(CAST(zip_code AS STRING))
            WHEN LENGTH(TRIM(CAST(zip_code AS STRING))) = 10
                AND REGEXP_CONTAINS(TRIM(CAST(zip_code AS STRING)), r'^\d{5}-\d{4}')
            THEN TRIM(CAST(zip_code AS STRING))
            ELSE NULL
        END AS zip,

        CAST(on_street_name AS STRING) AS on_street_name,
        CAST(cross_street_name AS STRING) AS cross_street_name,
        CAST(off_street_name AS STRING) AS off_street_name,
        CAST(latitude AS NUMERIC) AS latitude,
        CAST(longitude AS NUMERIC) AS longitude,

        -- Injury & fatality counts
        CAST(number_of_persons_injured AS INT64) AS persons_injured,
        CAST(number_of_persons_killed AS INT64) AS persons_killed,
        CAST(number_of_pedestrians_injured AS INT64) AS pedestrians_injured,
        CAST(number_of_pedestrians_killed AS INT64) AS pedestrians_killed,
        CAST(number_of_cyclist_injured AS INT64) AS cyclists_injured,
        CAST(number_of_cyclist_killed AS INT64) AS cyclists_killed,
        CAST(number_of_motorist_injured AS INT64) AS motorists_injured,
        CAST(number_of_motorist_killed AS INT64) AS motorists_killed,

        -- Contributing factors & vehicles
        CAST(contributing_factor_vehicle_1 AS STRING) AS reason_for_crash_1,
        CAST(contributing_factor_vehicle_2 AS STRING) AS reason_for_crash_2,
        CAST(vehicle_type_code1 AS STRING) AS vehicle_type_1,
        CAST(vehicle_type_code2 AS STRING) AS vehicle_type_2,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE collision_id IS NOT NULL
        AND crash_date IS NOT NULL
        AND CAST(crash_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)

    QUALIFY ROW_NUMBER() OVER (PARTITION BY collision_id ORDER BY crash_date DESC) = 1
)

SELECT *
FROM cleaned