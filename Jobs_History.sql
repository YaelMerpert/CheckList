--##########--YESTERDAY!!!!--####################

-- Variable Declarations 
DECLARE @FinalDate INT;
SET @FinalDate = CONVERT(int
    , CONVERT(varchar(10), DATEADD(DAY, -1, GETDATE()), 112)
    ) -- Yesterday's date as Integer in YYYYMMDD format

-- Final Logic 

SELECT  j.[name],  
        s.step_name,  
        h.step_id,  
        h.step_name,  
        h.run_date,  
        h.run_time,  
        h.sql_severity,  
        h.message,   
        h.server  
FROM    msdb.dbo.sysjobhistory h  
        INNER JOIN msdb.dbo.sysjobs j  
            ON h.job_id = j.job_id  
        INNER JOIN msdb.dbo.sysjobsteps s  
            ON j.job_id = s.job_id 
                AND h.step_id = s.step_id  
WHERE    h.run_status = 0 -- Failure  
         AND h.run_date > @FinalDate  
ORDER BY h.instance_id DESC;

--####HISTORY##


select j.name
    ,js.step_name
    ,jh.sql_severity
    ,jh.message
    ,jh.run_date
    ,jh.run_time
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS js
   ON js.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobhistory AS jh
   ON jh.job_id = j.job_id AND jh.step_id = js.step_id
WHERE jh.run_status = 0 AND DATEDIFF(DAY,jh.run_time, GETDATE())<7
ORDER BY jh.run_date DESC