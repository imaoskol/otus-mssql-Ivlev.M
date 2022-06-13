CREATE PROCEDURE Sales.ReplyMessage
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
    			@Message NVARCHAR(4000),
    			@MessageType Sysname,
    			@ReplyMessage NVARCHAR(4000),
    			@ReplyMessageName Sysname,
          @TransactionID INT,
    			@CustomerName NVARCHAR(100), 
          @PhoneNumber NVARCHAR(20),
          @status SMALLINT,
    			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TestTargetQueue; 
	
	SET @xml = CAST(@Message AS XML);

	SELECT @CustomerName  = X.nodes.value('CustomerName[1]','nvarchar(100)')
        ,@TransactionID = X.nodes.value('TransactionID[1]','int')
        ,@PhoneNumber   = X.nodes.value('PhoneNumber[1]','nvarchar(20)')
	FROM @xml.nodes('/RequestMessage/TransInfo') as X(nodes)

  --Тут логика отправки смс-ки по @PhoneNumber телефона через Api
  --получили от API статус успешной отправки

  SET @status = 1 --заглушка
	IF @TransactionID IS NOT NULL AND @status <> 0
    BEGIN
      INSERT INTO Sales.sms (transactionID, CustomerName, PhoneNumber, Status)
      VALUES (@TransactionID,@CustomerName, @PhoneNumber, @status)    
    END  
  		
	-- Confirm and Send a reply
	IF @MessageType=N'/local/RequestMessage'
	BEGIN		
    SET @ReplyMessage =CONCAT('<ReplyMessage>', 'Message received ', ' TransactionID= ', TRY_CAST(@TransactionID AS NVARCHAR), '</ReplyMessage>');
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[/local/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	COMMIT TRAN;
END
GO