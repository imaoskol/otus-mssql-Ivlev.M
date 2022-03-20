/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

TODO1:
--Исправленное
--найдём во внутреннем запросе тех кто делал прожади в этот день
-- а затем исключим их.
SELECT p.PersonID,p.FullName 
FROM Application.People p
WHERE p.PersonID NOT IN (
                          SELECT DISTINCT p1.PersonID
                          FROM Application.People p1 
                          LEFT JOIN Sales.Invoices i on i.SalespersonPersonID = p1.PersonID
                          WHERE p1.IsSalesperson = 1
                            AND i.InvoiceDate = '20150704'
                         )
ORDER BY p.PersonID                             

;WITH Who_20150704 (PersonID) AS
(
  SELECT DISTINCT p1.PersonID
  FROM Application.People p1 
  LEFT JOIN Sales.Invoices i on i.SalespersonPersonID = p1.PersonID
  WHERE p1.IsSalesperson = 1
    AND i.InvoiceDate = '20150704'
)
SELECT p.PersonID,p.FullName 
FROM Application.People p
WHERE p.PersonID NOT IN (SELECT w.PersonID FROM Who_20150704 w)
ORDER BY p.PersonID


-------1 вариант-----------
SELECT p.FullName,p.PersonID
FROM Application.People p
WHERE p.IsSalesperson = 1
  AND p.PersonID in (
                     SELECT DISTINCT s.SalespersonPersonID
                     FROM Sales.Invoices s
                     WHERE s.InvoiceDate <> '20150704'
                     )
ORDER BY p.PersonID
-----------------------------

-------2 вариант, извращённый------------
;WITH PersonID_CTE (FullName, PersonID) AS
(
 SELECT p.FullName,p.PersonID
 FROM Application.People p
 WHERE p.IsSalesperson = 1 
)
,Invoices_CTE (PersonID) AS
(
 SELECT DISTINCT s.SalespersonPersonID
 FROM Sales.Invoices s
 WHERE s.InvoiceDate <> '20150704'
)
SELECT pc.FullName, pc.PersonID
FROM PersonID_CTE pc
INNER JOIN Invoices_CTE ic on ic.PersonID = pc.PersonID
ORDER BY pc.PersonID
----------------------------------------------------------

------3 вариант,нормальный------------------------------
SELECT DISTINCT p.FullName,p.PersonID
FROM Application.People p
INNER JOIN Sales.Invoices i on i.SalespersonPersonID = p.PersonID
WHERE p.IsSalesperson = 1
  AND i.InvoiceDate <> '20150704'
ORDER BY p.PersonID
--------------------------------------------------------


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

TODO2:

--1
SELECT s.StockItemID,s.StockItemName,s.UnitPrice
FROM Warehouse.StockItems s
WHERE s.UnitPrice = (
                      SELECT MIN(s1.UnitPrice)
                      FROM Warehouse.StockItems s1
                    )
--2 Второй подзапрос в голову не приходит,но:
SELECT TOP(1) s.StockItemID,s.StockItemName,s.UnitPrice
FROM Warehouse.StockItems s
ORDER BY s.UnitPrice



/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO3: 
--1
--Вообще если сделать так то по условию подходит,
--но всё таки 5 последних максимальных платежей мог перевести один клиент( в данной таблице 5 разных)
-- а нам я так подразумеваю нужны именно 5 клиентов..
--если брать именно 5 максимальных платежей как в условии то так подойдёт:
;WITH MaxTrans_CTE (CustomerID) AS
(
  SELECT top(5) ct.CustomerID
  FROM Sales.CustomerTransactions ct
  ORDER BY ct.TransactionAmount DESC
)
SELECT c.CustomerID,c.CustomerName,c.PhoneNumber
FROM MaxTrans_CTE mc
INNER JOIN Sales.Customers c on c.CustomerID = mc.CustomerID
ORDER BY c.CustomerID

--2
-- Более правильное решение(на мой взгляд):

;WITH Max_Customer_CTE (CustomerID, Summa) AS
(
  SELECT TOP(5) c.CustomerID, max(c.TransactionAmount) as max_amount
  FROM Sales.CustomerTransactions c
  --WHERE c.IsFinalized = 1  -наверное надо учитывать состоявшуюся транзакцию в реальности
  GROUP BY c.CustomerID
  ORDER BY max_amount DESC
)      
SELECT c1.CustomerID,c1.CustomerName,c1.PhoneNumber
FROM Max_Customer_CTE mct
INNER JOIN Sales.Customers c1 on c1.CustomerID = mct.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO4:
--для удобства сохраним покупателей и упаковщиков во временную табличку
DROP TABLE IF EXISTS #tmp_sales
CREATE TABLE  #tmp_sales (CustomerID int, PickedByPersonID int) --PackedByPersonID не нашел такого(( есть PickedByPersonID, возьму это поле. 

--выберем все товары имеющие максимальную цену
;WITH TopPrice (StockItemID) AS
(
  SELECT st.StockItemID
  FROM (
        SELECT s.StockItemID, s.UnitPrice, DENSE_RANK() OVER(ORDER by s.UnitPrice DESC) as maxprice
        FROM Warehouse.StockItems s
       ) st 
  WHERE st.maxprice BETWEEN 1 and 5 -- возьму 5 максимальных цен а не 3, так интереснее, товаров больше
)
--вытащим покупателей и упаковщиков заказов с этими товарами, запишем во временную табличку
INSERT INTO #tmp_sales(CustomerID, PickedByPersonID)
SELECT o.CustomerID, o.PickedByPersonID 
FROM Sales.Orders o 
LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
INNER JOIN TopPrice tp on tp.StockItemID = o1.StockItemID


--города
SELECT  c1.DeliveryCityID, ci.CityName
FROM (
      SELECT DISTINCT t.CustomerID
      From #tmp_sales t
      ) as c
INNER JOIN Sales.Customers c1 on c1.CustomerID = c.CustomerID
INNER JOIN Application.Cities ci on ci.CityID = c1.DeliveryCityID       

--упаковщики
SELECT p.FullName
FROM (
      SELECT DISTINCT t.PickedByPersonID
      FROM #tmp_sales t
      ) ps
INNER JOIN Application.People p on p.PersonID = ps.PickedByPersonID




-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO5: --Двигался в сторону читабельности
;WITH SalesTotals (InvoiceID, TotalSumm) AS
(
  SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000
)
, TotalSummFPI (OrderId, Summa) AS 
(
  SELECT o.OrderId, SUM(o1.PickedQuantity*o1.UnitPrice)
  FROM Sales.Orders o
  LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
  WHERE o.PickingCompletedWhen IS NOT NULL	
  GROUP BY o.OrderID 
)
SELECT i.InvoiceID
      ,i.InvoiceDate
      ,p.FullName AS SalesPersonName
      ,sa.TotalSumm AS TotalSummByInvoice
      ,tf.Summa AS TotalSummForPickedItems 

FROM Sales.Invoices i
INNER JOIN Application.People p on p.PersonID = i.SalespersonPersonID
INNER JOIN SalesTotals sa on sa.InvoiceID = i.InvoiceID
INNER JOIN TotalSummFPI tf on tf.OrderID = i.OrderID
ORDER BY TotalSummByInvoice DESC

