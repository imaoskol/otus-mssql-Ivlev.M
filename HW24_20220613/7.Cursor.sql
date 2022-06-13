 --Где то в коде мы внелряем отправку сообщения от сервиса Init в Target
  --У меня моделирование данного процесса через курсор
 
 DECLARE @TransactionID INT
                
  DECLARE cur CURSOR FAST_FORWARD READ_ONLY LOCAL FOR
  	SELECT TOP(3) ct.CustomerTransactionID
  	FROM Sales.CustomerTransactions ct
    WHERE ct.IsFinalized = 1
  
  OPEN cur
  
  FETCH NEXT FROM cur INTO @TransactionID
  
  WHILE @@FETCH_STATUS = 0 
    BEGIN
  	  EXEC sales.SendToQueue @TransactionID
      FETCH NEXT FROM cur INTO @TransactionID
    END
  
  CLOSE cur
  DEALLOCATE cur