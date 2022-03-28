/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
--Не понял фрмулировку, что в строках должна быть дата начала месяца, и при этом количество в разрезе месяцев... А года?
--сделал кол-во в разрезе месяцев с учётом годов... как то так красивше..или я не понял посыл в задаче?
SELECT *
FROM (
      SELECT YEAR(i.InvoiceDate) as year_, MONTH(i.InvoiceDate) as month_, substring(c.CustomerName,16, LEN(c.CustomerName)-16) as name_
      FROM Sales.Invoices i 
      INNER JOIN Sales.Customers c on c.CustomerID = i.CustomerID
      WHERE i.CustomerID BETWEEN 2 and 6
      ) AS P
PIVOT
( COUNT(p.name_) 
  FOR P.name_ IN ([Sylvanite, MT], [Peeples Valley, AZ], [Gasport, NY], [Jessie, ND], [Medicine Lodge, KS]) 
) AS PVT
ORDER BY PVT.year_, PVT.month_


--Переспал с этим заданием и придумал решение изходя из условий, хотя я так и не понял зачем в дату писать именно первое число как
--в примере, ведь дата первой покупке в месяце не совпадает с первым числом
-- Да и вообще формулировка "в разрезе клиентов и месяцев" мне представляется по другому,нежели в примере

;WITH Crazy_CTE (ID, date_, name_)
AS
(
  SELECT i.InvoiceID
        ,CASE WHEN DATEPART(DAY,i.InvoiceDate) <> 1 THEN DATEADD(DAY,1,EOMONTH(i.InvoiceDate,-1))
              ELSE i.InvoiceDate
         END 
        ,SUBSTRING(c.CustomerName,16, LEN(c.CustomerName)-16) AS CName
  FROM Sales.Invoices i
  INNER JOIN Sales.Customers c on c.CustomerID = i.CustomerID
  WHERE i.CustomerID BETWEEN 2 AND 6
)
SELECT *
FROM Crazy_CTE
PIVOT
(
  COUNT(ID) FOR name_ IN ([Sylvanite, MT], [Peeples Valley, AZ], [Gasport, NY], [Jessie, ND], [Medicine Lodge, KS])
) AS CrazyPivot
ORDER BY date_

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
SELECT T.name_, T.addresses
FROM (
      SELECT *
      FROM (
            SELECT c.CustomerName as name_, c.DeliveryAddressLine1 as addr1, c.DeliveryAddressLine2 as addr2, c.PostalAddressLine1 as addr3, c.PostalAddressLine2 as addr4
            FROM Sales.Customers c
            WHERE c.CustomerName LIKE '%Tailspin Toys%'
            ) AS P
      UNPIVOT
        ( 
          addresses FOR Addr in ([addr1], [addr2], [addr3], [addr4])
        ) AS unpvt
 
      ) as T
/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
SELECT R.ID, R.name,R.code_
FROM (
      SELECT *
      FROM (
            SELECT c.CountryID as id, c.CountryName AS name, c.IsoAlpha3Code AS Acode, CAST(c.IsoNumericCode as NVARCHAR(3)) as Ncode
            FROM Application.Countries c
           ) AS T 
      UNPIVOT
        (
          code_ FOR code IN ([Acode], [Ncode])
        ) as unpvt
      ) AS R
/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
--Задача на Cross Apply

SELECT c.CustomerID,
       c.CustomerName,
       T.* 
FROM Sales.Customers c
CROSS APPLY (
              SELECT TOP(2) i.InvoiceDate, o1.StockItemID, o1.UnitPrice
              FROM Sales.Invoices i
              INNER JOIN Sales.Orders o on o.OrderID = i.OrderID
              LEFT JOIN Sales.OrderLines o1 ON o1.OrderID = o.OrderID
              WHERE i.CustomerID = c.CustomerID
              ORDER BY o1.UnitPrice DESC 
            ) AS T

