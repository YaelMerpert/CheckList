
	USE elad1  


	SET TRAN ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRAN

	--step 1

	INSERT INTO dbo.elad10  
	VALUES
	( 19, '666', 'samson', N'2018-12-25T00:00:00', 'beit-hasmonai', 5 )

	--step 2  RUN Tab 2


	--step 3

	UPDATE dbo.elad10  SET last_name='aaa2' WHERE p_id=18
	COMMIT

	--cleanup
	--DELETE FROM elad10 WHERE p_id = 19
--UPDATE dbo.elad10  SET last_name='moti' WHERE p_id=18
