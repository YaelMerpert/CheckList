

	USE elad1  
	--step 2

	SET TRAN ISOLATION LEVEL READ UNCOMMITTED 
	BEGIN TRAN 

	DECLARE @i AS TABLE (id INT )

	INSERT INTO @i
	SELECT p_id FROM dbo.elad10  E 
	WHERE E.first_name = 'samson'

	SELECT * FROM @i

	UPDATE dbo.elad10  
	SET adress='aaa'  
	FROM @i a  WHERE p_id=a.id 





--COMMIT  --no need to commit deadlock rollback


