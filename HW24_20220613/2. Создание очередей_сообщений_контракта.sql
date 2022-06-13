
----------------- 1. Типы сообщений для запроса и ответа: XML

CREATE MESSAGE TYPE
  [/local/RequestMessage]
  VALIDATION = WELL_FORMED_XML

CREATE MESSAGE TYPE
  [/local/ReplyMessage]
  VALIDATION = WELL_FORMED_XML
----------------------------------------------------------


--------------------------- 2. Контракт-----------------------
CREATE CONTRACT [/local/TestContract]
  (
  [/local/RequestMessage]
    SENT BY INITIATOR,
    [/local/ReplyMessage]
    SENT BY TARGET
  )
----------------------------------------------------------------

--------------------------3. Очередь и Сервис Получателя------
CREATE QUEUE TestTargetQueue

CREATE SERVICE [local/TestTargetService]
  ON QUEUE TestTargetQueue 
  ([/local/TestContract])   
---------------------------------------------------------------

-------------------------4. Очередь и сервис Инициатора-----------
CREATE QUEUE  TestInitQueue

CREATE SERVICE [local/TestInitService]
  ON QUEUE TestInitQueue
  ([/local/TestContract])

------------------------------------------------------------------

-------------------------5. Активация очередей-------------------
ALTER QUEUE TestInitQueue WITH STATUS = ON, RETENTION = OFF, POISON_MESSAGE_HANDLING (STATUS = OFF)
                          ,ACTIVATION ( STATUS = ON
                                       ,PROCEDURE_NAME = Sales.ReplyConfirm
                                       ,MAX_QUEUE_READERS = 10
                                       ,EXECUTE AS OWNER
                                      ); 

ALTER QUEUE TestTargetQueue WITH STATUS = ON, RETENTION = OFF, POISON_MESSAGE_HANDLING (STATUS = OFF)
                          ,ACTIVATION ( STATUS = ON
                                       ,PROCEDURE_NAME = Sales.ReplyMessage
                                       ,MAX_QUEUE_READERS = 10
                                       ,EXECUTE AS OWNER
                                      ); 
------------------------------------------------------------------