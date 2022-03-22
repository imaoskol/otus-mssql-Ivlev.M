/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
DROP TABLE IF EXISTS #TMP
CREATE TABLE #TMP (InvoiceDate date, Summa Decimal(38,2) )

INSERT INTO #TMP
  SELECT i.InvoiceDate
        ,SUM(o1.UnitPrice*o1.Quantity) as Summa
                                      
  FROM Sales.Invoices i
  INNER JOIN Sales.Orders o on o.OrderID = i.OrderID
  LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
  WHERE i.InvoiceDate >= '20150101'
  GROUP BY i.InvoiceDate

SELECT t.InvoiceDate, COALESCE(SUM(t1.Summa),0) as summa
FROM #TMP t
INNER JOIN #TMP t1 on t1.InvoiceDate <= t.InvoiceDate
GROUP BY t.InvoiceDate , t.Summa
ORDER by t.InvoiceDate


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SELECT T.InvoiceDate
      ,T.summa_prod
      ,SUM(T.summa_prod) OVER (ORDER BY T.InvoiceDate) AS SUMMA_NARAST
      ,SUM(T.summa_prod) OVER (ORDER BY MONTH(T.InvoiceDate)) as summa_month
FROM (
      SELECT i.InvoiceDate
            ,SUM(o1.Quantity*o1.UnitPrice) as summa_prod                                      
      FROM Sales.Invoices i
      INNER JOIN Sales.Orders o on o.OrderID = i.OrderID
      LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
      WHERE i.InvoiceDate >= '20150101'
      GROUP BY i.InvoiceDate
      ) T
ORDER BY T.InvoiceDate
/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;WITH CTE (StockItemID, month_, YEAR_, col) AS
(
  SELECT o1.StockItemID
        ,MONTH(i.InvoiceDate) AS month_ 
        ,'2016' as YEAR_
        ,COUNT(*) as col
  FROM Sales.Invoices i
  INNER JOIN Sales.Orders o on o.OrderID = i.OrderID
  LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
  WHERE i.InvoiceDate BETWEEN '20160101' AND '20161231'
  GROUP BY o1.StockItemID, MONTH(i.InvoiceDate)
  
)
SELECT s.StockItemName,t.month_,t.YEAR_
FROM (
      SELECT c.*, ROW_NUMBER() OVER(PARTITION BY c.month_ ORDER BY c.col DESC) AS top_
      FROM CTE c  
     ) T
INNER JOIN Warehouse.StockItems s on s.StockItemID = t.StockItemID
WHERE T.top_ <=2  
ORDER BY month_  


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT s.StockItemID
      ,s.StockItemName
      ,s.Brand
      ,s.UnitPrice
      ,s.TypicalWeightPerUnit
      ,ROW_NUMBER() OVER (PARTITION BY SUBSTRING(s.StockItemName,1,1) ORDER BY s.StockItemID) as alf --не понятно при изменении какой буквы, взял первую
      ,COUNT(*) OVER() AS col_tovar
      ,COUNT(*) OVER (PARTITION BY SUBSTRING(s.StockItemName,1,1) ) AS col_alf
      ,LEAD(s.StockItemID) OVER( ORDER BY s.StockItemName) AS next_id
      ,LAG(s.StockItemID) OVER (ORDER BY s.StockItemName) AS before_
      ,LAG(s.StockItemName, 2 ,'No items') OVER (ORDER BY s.StockItemName) AS before2
      ,NTILE(30) OVER (PARTITION BY s.TypicalWeightPerUnit ORDER BY s.StockItemID) AS ntile_
FROM Warehouse.StockItems s




/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT T.OrderID
      ,T.CustomerID
      ,c.CustomerName
      ,T.SalespersonPersonID
      ,p.FullName
      ,T.OrderDate
      ,(
          Select SUM(o1.Quantity*o1.UnitPrice) 
          FROM Sales.Orders o
          LEFT JOIN Sales.OrderLines o1 ON o1.OrderID = o.OrderID
          WHERE o.OrderID = T.OrderID
       ) AS summa      
FROM (
      SELECT o.OrderID
            ,o.CustomerID
            ,o.SalespersonPersonID
            ,o.OrderDate
            ,ROW_NUMBER() OVER(PARTITION BY o.SalespersonPersonID ORDER BY o.OrderDate DESC) AS num
      FROM Sales.Orders o          
     ) T 
INNER JOIN Application.People p on p.PersonID = T.SalespersonPersonID
INNER JOIN Sales.Customers c ON c.CustomerID = T.CustomerID
WHERE T.num = 1
ORDER BY T.SalespersonPersonID

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT T.*
FROM (
      SELECT o.OrderID
            ,o.OrderDate
            ,o.CustomerID
            ,c.CustomerName
            ,o1.OrderLineID
            ,o1.UnitPrice
            ,ROW_NUMBER() OVER (PARTITION BY o.CustomerID ORDER BY o1.UnitPrice DESC) AS num
      FROM Sales.Orders o 
      LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
      INNER JOIN Sales.Customers c on c.CustomerID = o.CustomerID
     ) T  
WHERE T.num <= 2
ORDER BY T.CustomerID


--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 