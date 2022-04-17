/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
INSERT INTO Sales.Customers (CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)
OUTPUT INSERTED.CustomerName
SELECT 'My Customer ' + CAST(c.CustomerID AS NVARCHAR)
      ,c.BillToCustomerID
      ,c.CustomerCategoryID
      ,c.BuyingGroupID
      ,c.PrimaryContactPersonID
      ,c.AlternateContactPersonID
      ,c.DeliveryMethodID
      ,c.DeliveryCityID
      ,c.PostalCityID
      ,c.CreditLimit
      ,c.AccountOpenedDate
      ,c.StandardDiscountPercentage
      ,c.IsStatementSent
      ,c.IsOnCreditHold
      ,c.PaymentDays
      ,c.PhoneNumber
      ,c.FaxNumber
      ,c.DeliveryRun
      ,c.RunPosition
      ,c.WebsiteURL
      ,c.DeliveryAddressLine1
      ,c.DeliveryAddressLine2
      ,c.DeliveryPostalCode
      ,c.DeliveryLocation
      ,c.PostalAddressLine1
      ,c.PostalAddressLine2
      ,c.PostalPostalCode
      ,c.LastEditedBy
  
FROM Sales.Customers c
WHERE c.CustomerID <=5

SELECT TOP(10) *
  FROM Sales.Customers c
  ORDER BY c.CustomerID DESC

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE
  FROM Sales.Customers
  WHERE CustomerName = 'My Customer 3' --тут лучше удалить where customerID=1064


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

SELECT  *
  FROM Sales.Customers c
  WHERE c.CustomerName = 'My Customer 2'

UPDATE  c
  SET c.CustomerName = 'My Customer 2 NEW'
  FROM Sales.Customers c
  WHERE c.CustomerName = 'My Customer 2'


/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Sales.Customers AS t
  USING (
          SELECT c.CustomerID
                ,c.CustomerName
                ,c.BillToCustomerID
                ,c.CustomerCategoryID
                ,c.BuyingGroupID
                ,c.PrimaryContactPersonID
                ,c.AlternateContactPersonID
                ,c.DeliveryMethodID
                ,c.DeliveryCityID
                ,c.PostalCityID
                ,c.CreditLimit
                ,c.AccountOpenedDate
                ,c.StandardDiscountPercentage
                ,c.IsStatementSent
                ,c.IsOnCreditHold
                ,c.PaymentDays
                ,c.PhoneNumber
                ,c.FaxNumber
                ,c.DeliveryRun
                ,c.RunPosition
                ,c.WebsiteURL
                ,c.DeliveryAddressLine1
                ,c.DeliveryAddressLine2
                ,c.DeliveryPostalCode
                --,c.DeliveryLocation
                ,c.PostalAddressLine1
                ,c.PostalAddressLine2
                ,c.PostalPostalCode
                ,c.LastEditedBy
          FROM Sales.Customers c
          WHERE c.CustomerID BETWEEN 10 AND 20
          UNION
          SELECT c.CustomerID
                ,'MyCustomer ' + CAST(c.CustomerID AS NVARCHAR)
                ,c.BillToCustomerID
                ,c.CustomerCategoryID
                ,c.BuyingGroupID
                ,c.PrimaryContactPersonID
                ,c.AlternateContactPersonID
                ,c.DeliveryMethodID
                ,c.DeliveryCityID
                ,c.PostalCityID
                ,c.CreditLimit
                ,c.AccountOpenedDate
                ,c.StandardDiscountPercentage
                ,c.IsStatementSent
                ,c.IsOnCreditHold
                ,c.PaymentDays
                ,c.PhoneNumber
                ,c.FaxNumber
                ,c.DeliveryRun
                ,c.RunPosition
                ,c.WebsiteURL
                ,c.DeliveryAddressLine1
                ,c.DeliveryAddressLine2
                ,c.DeliveryPostalCode
               --,c.DeliveryLocation
                ,c.PostalAddressLine1
                ,c.PostalAddressLine2
                ,c.PostalPostalCode
                ,c.LastEditedBy
          FROM Sales.Customers c
          WHERE c.CustomerID BETWEEN 30 AND 40  
        ) AS s
ON (t.CustomerName = s.CustomerName)
  WHEN MATCHED
  THEN UPDATE SET t.StandardDiscountPercentage = 1.5
  WHEN NOT MATCHED THEN INSERT  (CustomerName
                                ,BillToCustomerID
                                ,CustomerCategoryID
                                ,BuyingGroupID
                                ,PrimaryContactPersonID
                                ,AlternateContactPersonID
                                ,DeliveryMethodID
                                ,DeliveryCityID
                                ,PostalCityID
                                ,CreditLimit
                                ,AccountOpenedDate
                                ,StandardDiscountPercentage
                                ,IsStatementSent
                                ,IsOnCreditHold
                                ,PaymentDays
                                ,PhoneNumber
                                ,FaxNumber
                                ,DeliveryRun
                                ,RunPosition
                                ,WebsiteURL
                                ,DeliveryAddressLine1
                                ,DeliveryAddressLine2
                                ,DeliveryPostalCode
                                --,c.DeliveryLocation
                                ,PostalAddressLine1
                                ,PostalAddressLine2
                                ,PostalPostalCode
                                ,LastEditedBy)
  VALUES (s.CustomerName
        ,s.BillToCustomerID
        ,s.CustomerCategoryID
        ,s.BuyingGroupID
        ,s.PrimaryContactPersonID
        ,s.AlternateContactPersonID
        ,s.DeliveryMethodID
        ,s.DeliveryCityID
        ,s.PostalCityID
        ,s.CreditLimit
        ,s.AccountOpenedDate
        ,s.StandardDiscountPercentage
        ,s.IsStatementSent
        ,s.IsOnCreditHold
        ,s.PaymentDays
        ,s.PhoneNumber
        ,s.FaxNumber
        ,s.DeliveryRun
        ,s.RunPosition
        ,s.WebsiteURL
        ,s.DeliveryAddressLine1
        ,s.DeliveryAddressLine2
        ,s.DeliveryPostalCode
        --,c.DeliveryLocation
        ,s.PostalAddressLine1
        ,s.PostalAddressLine2
        ,s.PostalPostalCode
        ,s.LastEditedBy);

SELECT TOP(20) *
  FROM Sales.Customers c
  ORDER BY c.CustomerID DESC


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

/*
-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME  --IMA-HUAWEY
*/

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Application.PaymentMethods" out  "C:\Users\ivlev\OneDrive\Desktop\OtusSQL\Git\AppMetods.txt" -T -w -t"!delimetr!" -S IMA-HUAWEY'


DROP TABLE IF EXISTS #tmp 

SELECT * INTO #tmp 
FROM Application.PaymentMethods pm 
WHERE 1=2


  BULK INSERT #tmp
				   FROM "C:\Users\ivlev\OneDrive\Desktop\OtusSQL\Git\AppMetods.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '!delimetr!',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );

  SELECT *
    FROM #tmp t