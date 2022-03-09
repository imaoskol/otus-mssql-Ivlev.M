/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO1:

SELECT YEAR(i.InvoiceDate) as year_
      ,MONTH(i.InvoiceDate) as month_
      ,AVG(i1.UnitPrice) as [Средняя цена товара]
      ,SUM(i1.Quantity * i1.UnitPrice) as [сумма продаж] --Там есть ещё налог, его не учитывал.
FROM Sales.Invoices i
LEFT JOIN Sales.InvoiceLines i1 on i1.InvoiceID = i.InvoiceID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
ORDER BY year_ DESC, month_ DESC    

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO2:
-- или я не так понял или эта задача от предыдущей отличается только Хэвингом
-- не понял эту формулировку: <Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
--то этот месяц также отображался бы в результатах, но там были нули>
--Ведь у нас по условию уже месяцы, где общаяя сумма больше 10 000
--Что такое продажа? Я количество умножаю на стоимость.. Но там есть ещё налог.... ???

SELECT YEAR(i.InvoiceDate) as year_
      ,MONTH(i.InvoiceDate) as month_
      ,SUM(i1.Quantity * i1.UnitPrice) as [сумма продаж] --Там есть ещё налог, его не учитывал.
FROM Sales.Invoices i
LEFT JOIN Sales.InvoiceLines i1 on i1.InvoiceID = i.InvoiceID
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
HAVING SUM(i1.Quantity * i1.UnitPrice) > 10000
ORDER BY year_ DESC, month_ DESC    

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

TODO3:
--если я правильно понял где какие данные в таблицах
--можно сдлеать сразу join на Warehouse.StockItems, но группировать придётся по названию товара, лучше всё таки по id-шнику

SELECT G.year_          as [Год]
      ,G.month_         as [Месяц]
      ,s.StockItemName  as [Наименование товара]
      ,G.sum_           as [сумма]
      ,G.mindate        as [дата первой продажи]
      ,G.col            as [Количество]
 FROM (
        SELECT YEAR(i.InvoiceDate) as year_
              ,MONTH(i.InvoiceDate) as month_
              ,o1.StockItemID
              ,SUM(o1.Quantity*o1.UnitPrice) as sum_
              ,MIN(i.InvoiceDate) as mindate
              ,COUNT(*) as col       
        FROM Sales.Invoices i 
        INNER JOIN Sales.Orders o on o.OrderID = i.OrderID
        LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
        GROUP BY YEAR(i.InvoiceDate),MONTH(i.InvoiceDate),o1.StockItemID
        HAVING COUNT(*) < 50
      ) AS G
INNER JOIN Warehouse.StockItems s on s.StockItemID =G.StockItemID
ORDER BY G.year_ DESC, g.month_ DESC, g.col DESC




-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
