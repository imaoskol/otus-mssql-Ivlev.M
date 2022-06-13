-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Sales.SendToQueue
	@transactionID INT
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (
                            SELECT ct.CustomerTransactionID AS TransactionID 
                                  ,ct.TransactionAmount AS TransactionAmount
                                  ,c.CustomerID AS CustomerID
                                  ,c.CustomerName AS CustomerName
                                  ,c.PhoneNumber AS PhoneNumber
                              FROM Sales.CustomerTransactions ct
                              INNER JOIN Sales.Invoices i ON i.InvoiceID = ct.InvoiceID
                              INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
                              WHERE ct.CustomerTransactionID = @transactionID  
            							  FOR XML PATH('TransInfo'), root('RequestMessage')
                            ) 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[local/TestInitService]
	TO SERVICE
	'local/TestTargetService'
	ON CONTRACT
	[/local/TestContract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[/local/RequestMessage]
	(@RequestMessage);
	--SELECT @RequestMessage AS SentRequestMessage;
	COMMIT TRAN 
END
GO