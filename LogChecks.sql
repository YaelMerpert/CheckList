
		SELECT ValidationSPID ,
				Duration ,
				ExecutionDate ,
				DeclarationID ,
				Exception
				FROM  CustomsLog_Dev.Log.DealFileValidation_ChecksLog 
		WHERE duration >= 100
		AND   DATEPART(d,ExecutionDate) = DATEPART(d,GETDATE())
	--	WHERE ValidationSPID = 1721 
	--	WHERE DATEPART(d,ExecutionDate) = DATEPART(d,GETDATE())
		--	AND DeclarationID = 4871758
		ORDER BY ExecutionDate DESC--, Duration DESC



--22877400
--22877399
--22877398

SELECT * FROM  CustomsLog_Dev.Log.DealFileValidation_ChecksLog 
WHERE Exception NOT LIKE ' ' --OR Exception IS NOT NULL
Order BY 1 desc
SELECT *  FROM  CustomsLog_Dev.Log.DealFileValidation_LoadsLog 
WHERE Exception NOT LIKE ' ' --OR Exception IS NOT NULL
Order BY 1 desc

SELECT * FROM CustomsLog_Dev.[_Admin_].[Log_ErrorLog]
ORDER BY 1 DESC

--2015-02-25 18:32:54.883

SELECT ValidationSPID ,
       AVG (Duration)  AVG_Duration
       FROM  CustomsLog_Dev.Log.DealFileValidation_ChecksLog 
--WHERE duration >=500
--WHERE ValidationSPID = 1213
WHERE DATEPART(d,ExecutionDate) = DATEPART(d,GETDATE())
GROUP BY ValidationSPID
ORDER BY AVG (Duration) desc


SELECT * FROM CRP.DealFile_Declaration 
WHERE id = 22874830




		--SELECT *
		--		FROM  CustomsLog_Dev.Log.DealFileValidation_ChecksLog 
		--WHERE DeclarationID = 22874794
		--AND  DATEPART(d,ExecutionDate) = DATEPART(d,GETDATE())
		--ORDER BY ExecutionDate DESC, Duration DESC



