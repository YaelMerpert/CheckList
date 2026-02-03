use SSISDB
go

select
    ex.start_time,
    ex.end_time,
    ex.folder_name,
    ex.project_name,
    ex.package_name,
    ex.execution_id,
    em.message_time,
    em.message
FROM SSISDB.catalog.event_messages em
JOIN SSISDB.catalog.executions ex
    ON em.operation_id = ex.execution_id
WHERE em.message_type = 120 and  ex.start_time>=dateadd(dd, -7, getdate()) ---AND ex.status = 7 -- Error and Failed
ORDER BY ex.start_time DESC;


SELECT
    ex.start_time,
    ex.package_name,
    COUNT(*) AS error_count
FROM SSISDB.catalog.event_messages em
JOIN SSISDB.catalog.executions ex
    ON em.operation_id = ex.execution_id
WHERE em.message_type = 120 and  ex.start_time>=dateadd(dd, -7, getdate())
GROUP BY ex.start_time, ex.package_name
ORDER BY ex.start_time DESC;