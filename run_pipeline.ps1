# run_pipeline.ps1
# Rebuilds the entire data warehouse from scratch: init -> bronze -> silver -> gold
# Requires: sqlcmd (installed alongside SSMS / SQL Server command-line tools)

$server = "localhost\SQLEXPRESS"

Write-Host "==> Initializing database and schemas..." -ForegroundColor Cyan
sqlcmd -S $server -E -i "scripts\00_init_database.sql"

Write-Host "==> Creating and loading bronze layer..." -ForegroundColor Cyan
sqlcmd -S $server -d DataWarehouse -E -i "scripts\bronze\ddl_bronze.sql"
sqlcmd -S $server -d DataWarehouse -E -i "scripts\bronze\proc_load_bronze.sql"
sqlcmd -S $server -d DataWarehouse -E -Q "EXEC bronze.load_bronze;"

Write-Host "==> Creating and loading silver layer..." -ForegroundColor Cyan
sqlcmd -S $server -d DataWarehouse -E -i "scripts\silver\ddl_silver.sql"
sqlcmd -S $server -d DataWarehouse -E -i "scripts\silver\proc_load_silver.sql"
sqlcmd -S $server -d DataWarehouse -E -Q "EXEC silver.load_silver;"

Write-Host "==> Creating gold views..." -ForegroundColor Cyan
sqlcmd -S $server -d DataWarehouse -E -i "scripts\gold\ddl_gold.sql"
sqlcmd -S $server -d DataWarehouse -E -i "scripts\gold\report_customers.sql"
sqlcmd -S $server -d DataWarehouse -E -i "scripts\gold\report_products.sql"

Write-Host "==> Pipeline complete." -ForegroundColor Green