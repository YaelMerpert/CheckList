USE msdb
Go 
SELECT JS.name AS JobName,
JH.step_name AS StepName,
JH.message AS StepMessage, 
JH.run_duration AS StepDuration, 
JH.run_date AS TS
FROM sysjobhistory JH 
INNER JOIN sysjobs JS  ON JS.job_id = JH.job_id
WHERE JH.message LIKE '%Query timeout expired%'
ORDER BY  JH.run_date desc
GO