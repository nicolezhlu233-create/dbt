# dbt project (Snowflake)

Turns two raw tables (orders, line items) into clean tables.

## What you get (all in INTERVIEW.CLEAN)
| Table | Use it for |
|---|---|
| `ORDERS_CLEAN`      | one row per order, fixed dates / carriers / regions, plus a `dq_flags` note saying what was changed |
| `LINE_ITEMS_CLEAN`  | one row per item in an order (join to orders on `order_id`) |
| `ORDERS_REJECTED`   | the 740 duplicate order rows that were removed (nothing is silently lost) |


## Setup (once)
1. `dbt_project.yml` -> check the four `raw_*` values: database, schema and the two table names of your uploaded data.
   Both `ORDER_ID` columns must be VARCHAR.
2. `profiles.yml` -> already set to role ACCOUNTADMIN, warehouse COMPUTE_WH, database INTERVIEW, schema CLEAN.
3. Seeds first (3 small lookup tables), then build everything.

## Run
In the Snowsight dbt workspace use the dbt dropdown: **Seed**, then **Build** (target `dev`).
If a command is missing from the dropdown: run **Seed**, then **Run**, then **Test**.

## Check it worked
Run `snowflake/02_check_results.sql` (expect 310,905 / 411,581 / 740 rows), then explore with
`snowflake/03_analysis_starter_queries.sql`.

## Notes
* `data_cutoff` (dbt_project.yml) = 2022-11-16 is an assumption (file date). Dates after it are treated as invalid.
* `is_zero_value_order = TRUE` rows look like cancelled orders; exclude them from revenue / fulfilment analysis.
* `snowflake/01_load_raw.sql` and `profiles.local.yml.example` are only for other setups (loading via SQL / running dbt on your laptop).
