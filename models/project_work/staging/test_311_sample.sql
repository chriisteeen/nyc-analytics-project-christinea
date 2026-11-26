-- Quick test to verify source connection works
SELECT
    unique_key,
    created_date,
    complaint_type,
    borough
FROM {{ source('nyc_project_raw_data', 'source_service_requests_dot') }}
LIMIT 10