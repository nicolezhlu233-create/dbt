/* ============================================================================
   LOAD THE TWO RAW CSVs INTO SNOWFLAKE  (run once, before dbt)
   Everything is loaded as VARCHAR on purpose.

   !! Do NOT use the Snowsight "Load data into table" wizard with type inference.
   !! It will guess ORDER_ID is a FLOAT and silently merge ~354 different orders
   !! (e.g. 3558273.1 and 3558273.10).
   ============================================================================ */
USE ROLE TRANSFORMER;                         -- any role that can create objects
USE WAREHOUSE COMPUTE_WH;
CREATE DATABASE IF NOT EXISTS ANALYTICS;
CREATE SCHEMA   IF NOT EXISTS ANALYTICS.RAW;
USE SCHEMA ANALYTICS.RAW;

CREATE OR REPLACE FILE FORMAT csv_ff
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    ENCODING = 'UTF8';

CREATE OR REPLACE STAGE landing FILE_FORMAT = csv_ff;

/* Upload the files. Either use SnowSQL / Snowflake CLI:
       PUT file:///full/path/to/csv_files/orders.csv      @landing AUTO_COMPRESS=TRUE;
       PUT file:///full/path/to/csv_files/line_items.csv  @landing AUTO_COMPRESS=TRUE;
   ...or in Snowsight: Data > Databases > ANALYTICS > RAW > Stages > LANDING > "+ Files".  */

CREATE OR REPLACE TABLE orders_raw (
    row_id                  NUMBER,        -- line number in the file; used as a stable tie-breaker
    merchant_id             VARCHAR,
    order_id                VARCHAR,       -- KEEP AS TEXT
    shop_id                 VARCHAR,
    address_to_country      VARCHAR,
    address_to_region       VARCHAR,
    order_dt                VARCHAR,
    fulfilled_dt            VARCHAR,
    sales_channel_type_id   VARCHAR,
    total_cost              VARCHAR,
    total_shipping          VARCHAR,
    merchant_registered_dt  VARCHAR,
    sub_is_active_flag      VARCHAR,
    sub_plan                VARCHAR,
    shipment_carrier        VARCHAR,
    shipment_delivered_at   VARCHAR
);

CREATE OR REPLACE TABLE line_items_raw (
    row_id              NUMBER,
    order_id            VARCHAR,           -- KEEP AS TEXT
    print_provider_id   VARCHAR,
    product_brand       VARCHAR,
    product_type        VARCHAR,
    quantity            VARCHAR,
    reprint_flag        VARCHAR
);

COPY INTO orders_raw
FROM (SELECT METADATA$FILE_ROW_NUMBER, $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15
      FROM @landing/orders.csv.gz);

COPY INTO line_items_raw
FROM (SELECT METADATA$FILE_ROW_NUMBER, $1,$2,$3,$4,$5,$6
      FROM @landing/line_items.csv.gz);

-- Sanity check. Expected: orders_raw = 311645, line_items_raw = 411581
SELECT 'orders_raw' AS tbl, COUNT(*) AS n FROM orders_raw
UNION ALL SELECT 'line_items_raw', COUNT(*) FROM line_items_raw;
