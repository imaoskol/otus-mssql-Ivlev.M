/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

DECLARE @xml AS XML
  SELECT @xml = bulkcolumn
    FROM  OPENROWSET(
                      BULK 'C:\Users\ivlev\OneDrive\Desktop\OtusSQL\Git\HW09_20220419\StockItems.xml'
                            ,SINGLE_CLOB 
                     ) AS data
    
    SELECT @xml AS [xml]



DECLARE @dockhandle INT
EXEC sp_xml_preparedocument @dockhandle OUTPUT, @xml

DROP TABLE IF EXISTS #tmp_StockItems
CREATE TABLE #tmp_StockItems (StockItemName NVARCHAR(100) COLLATE Latin1_General_100_CI_AS
                              ,SupplierID INT
                              ,UnitPacageID INT
                              ,OuterPackageID INT
                              ,QuantityPerOuter INT
                              ,TypicalWeightPerUnit DECIMAL(18,3)
                              ,LeadTimeDays INT
                              ,IsChillerStock BIT
                              ,TaxRate DECIMAL(18,3)
                              ,UnitPrice DECIMAL(18,2)
                              )  
  
  
INSERT INTO #tmp_StockItems
SELECT *
  FROM OPENXML(@dockhandle, N'/StockItems/Item')
  WITH  (
          [StockItemName] NVARCHAR(100) '@Name'
         ,[SupplierID]  INT 'SupplierID'
         ,[UnitPacageID] INT 'Package/UnitPackageID'
         ,[OuterPackageID]        INT 'Package/OuterPackageID'
         ,[QuantityPerOuter]      INT 'Package/QuantityPerOuter'
         ,[TypicalWeightPerUnit]  DECIMAL(18,3) 'Package/TypicalWeightPerUnit'
         ,[LeadTimeDays]          INT 'LeadTimeDays'
         ,[IsChillerStock]        BIT 'IsChillerStock'
         ,[TaxRate]               DECIMAL(18,3) 'TaxRate'
         ,[UnitPrice]             DECIMAL(18,2) 'UnitPrice' 
          
          )  

SELECT *
  FROM  #tmp_StockItems tsi

------------------Способ 2 ----------------------------------------------------------------
DROP TABLE IF EXISTS #tmp_StockItems2
CREATE TABLE #tmp_StockItems2 (StockItemName NVARCHAR(100) COLLATE Latin1_General_100_CI_AS
                              ,SupplierID INT
                              ,UnitPackageID INT
                              ,OuterPackageID INT
                              ,QuantityPerOuter INT
                              ,TypicalWeightPerUnit DECIMAL(18,3)
                              ,LeadTimeDays INT
                              ,IsChillerStock BIT
                              ,TaxRate DECIMAL(18,3)
                              ,UnitPrice DECIMAL(18,2)
                              )        


DECLARE @x AS XML
  SET @x = (
            SELECT * FROM  OPENROWSET(
                                      BULK 'C:\Users\ivlev\OneDrive\Desktop\OtusSQL\Git\HW09_20220419\StockItems.xml'
                                      ,SINGLE_CLOB 
                                      ) AS data
            )


INSERT INTO #tmp_StockItems2
SELECT t.Item.value('(@Name)[1]' ,'NVARCHAR(100)') AS [StockItemName]
      ,t.Item.value('(SupplierID)[1]' ,'INT') AS [SupplierID]
      ,t.Item.value('(Package/UnitPackageID)[1]' ,'INT') AS [UnitPackageID]
      ,t.Item.value('(Package/OuterPackageID)[1]' ,'INT') AS [OuterPackageID]
      ,t.Item.value('(Package/QuantityPerOuter)[1]' ,'INT') AS [QuantityPerOuter]
      ,t.Item.value('(Package/TypicalWeightPerUnit)[1]' ,'DECIMAL(18,3)') AS [TypicalWeightPerUnit]
      ,t.Item.value('(LeadTimeDays)[1]' ,'INT') AS [LeadTimeDays]
      ,t.Item.value('(IsChillerStock)[1]' ,'BIT') AS [IsChillerStock] 
      ,t.Item.value('(TaxRate)[1]' ,'DECIMAL(18,3)') AS [TaxRate]
      ,t.Item.value('(UnitPrice)[1]' ,'DECIMAL(18,2)') AS [UnitPrice] 
   FROM @x.nodes('/StockItems/Item') AS t(Item)

SELECT * FROM #tmp_StockItems2 tsi
---------------------------------------------------------------------------------------------


SELECT *
  FROM OPENXML(@dockhandle, N'/StockItems/Item')
  WITH  (
          [StockItemName] NVARCHAR(100) '@Name'
         ,[SupplierID]  INT 'SupplierID'
         ,[UnitPacageID] INT 'Package/UnitPackageID'
         ,[OuterPackageID]        INT 'Package/OuterPackageID'
         ,[QuantityPerOuter]      INT 'Package/QuantityPerOuter'
         ,[TypicalWeightPerUnit]  DECIMAL(18,3) 'Package/TypicalWeightPerUnit'
         ,[LeadTimeDays]          INT 'LeadTimeDays'
         ,[IsChillerStock]        BIT 'IsChillerStock'
         ,[TaxRate]               DECIMAL(18,3) 'TaxRate'
         ,[UnitPrice]             DECIMAL(18,2) 'UnitPrice' 
          
          )  




---------------------------------------------------------------------------------------------



MERGE Warehouse.StockItems AS Target
  USING (
          SELECT *
          FROM #tmp_StockItems tsi
        ) AS Source
ON (Target.StockItemName = Source.StockItemName)
WHEN MATCHED THEN 
  UPDATE SET target.SupplierID = Source.SupplierID
            ,target.UnitPackageID = source.UnitPacageID
            ,Target.OuterPackageID = source.OuterPackageID
            ,target.QuantityPerOuter = source.QuantityPerOuter
            ,target.TypicalWeightPerUnit = source.TypicalWeightPerUnit
            ,Target.LeadTimeDays = source.LeadTimeDays
            ,target.IsChillerStock = source.IsChillerStock
            ,Target.TaxRate = Source.TaxRate
            ,Target.UnitPrice = Source.UnitPrice
WHEN  NOT MATCHED THEN 
  INSERT (
           StockItemName
          ,SupplierID
          ,UnitPackageID
          ,OuterPackageID
          ,QuantityPerOuter
          ,LeadTimeDays
          ,IsChillerStock
          ,TaxRate
          ,UnitPrice
          ,TypicalWeightPerUnit
          ,LastEditedBy
          
         ) VALUES (
                     source.StockItemName
                    ,Source.SupplierID
                    ,Source.UnitPacageID
                    ,Source.OuterPackageID
                    ,Source.QuantityPerOuter
                    ,Source.LeadTimeDays
                    ,Source.IsChillerStock
                    ,Source.TaxRate
                    ,Source.UnitPrice
                    ,0.001
                    ,2    
                  )
  OUTPUT DELETED.*, $ACTION,  INSERTED.*;
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/


SELECT        si.StockItemName AS [@name]
             ,si.SupplierID
             ,si.UnitPackageID AS [Package/UnitPackageID]
             ,si.OuterPackageID AS [Package/OuterPackageID]  
             ,si.QuantityPerOuter AS [Package/QuantityPerOute]
             ,si.LeadTimeDays
             ,si.TaxRate
             ,si.UnitPrice
             ,si.TypicalWeightPerUnit             
  FROM   Warehouse.StockItems si
  FOR XML PATH('Item'), ROOT ('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT si.StockItemID
      ,si.StockItemName
      ,JSON_VALUE(si.CustomFields,'$.CountryOfManufacture') AS Country
      ,JSON_VALUE(si.CustomFields,'$.Tags[0]') AS FirstTag
      ,si.CustomFields
  FROM Warehouse.StockItems si

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/



SELECT si.StockItemID
      ,si.StockItemName
      ,si.CustomFields
      ,tags.[key]
      ,tags.value
FROM Warehouse.StockItems si
CROSS APPLY OPENJSON(si.CustomFields,'$.Tags') tags
WHERE tags.value = 'Vintage'
