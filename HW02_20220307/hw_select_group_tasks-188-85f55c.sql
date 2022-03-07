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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

TODO1: 
SELECT s.StockItemID,s.StockItemName
FROM Warehouse.StockItems s
WHERE s.StockItemName like '%urgent%'
or s.StockItemName like 'Animal%'
/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

TODO2: 
select  s.SupplierID,s.SupplierName--,p.PurchaseOrderID,p.OrderDate
from Purchasing.Suppliers s
left JOIN Purchasing.PurchaseOrders p  on p.SupplierID = s.SupplierID
WHERE p.PurchaseOrderID is NULL
order by s.SupplierID 


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

TODO3:
--не нашёл встроенных функция для получения трети года.
--можно написать свою функцию чтобы не городить кейс-вены по коду. Но тут думаю сойдёт :) 
select DISTINCT o.OrderID
               ,o.OrderDate
               ,DATENAME(MONTH,o.OrderDate) as month
               ,DATEPART(QUARTER,o.OrderDate) as quarter
               ,CASE WHEN DATEPART(MONTH,o.OrderDate) <=4 then 1
                     WHEN DATEPART(MONTH,o.OrderDate) >4 and DATEPART(MONTH,o.OrderDate) <=8 then 2
                     WHEN DATEPART(MONTH,o.OrderDate) >8 and DATEPART(MONTH,o.OrderDate) <=12 then 3
                     ELSE 0
                END as [Треть года]
                ,c.CustomerName
FROM  Sales.Orders o
LEFT JOIN Sales.OrderLines o1 on o1.OrderID = o.OrderID
INNER JOIN Sales.Customers c on c.CustomerID = o.CustomerID 
WHERE o1.UnitPrice > 100
OR (o1.Quantity > 20 AND o.PickingCompletedWhen is not NULL)
ORDER BY o.OrderID


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

TODO4:
SELECT d.DeliveryMethodName
      ,p.ExpectedDeliveryDate
      ,s.SupplierName
      ,pe.FullName
FROM Purchasing.Suppliers s 
LEFT JOIN Purchasing.PurchaseOrders p on p.SupplierID = s.SupplierID
INNER JOIN Application.DeliveryMethods d on d.DeliveryMethodID = s.DeliveryMethodID
INNER JOIN Application.People pe on pe.PersonID = s.PrimaryContactPersonID
WHERE DATEPART(MONTH,p.ExpectedDeliveryDate) = 1
  AND DATEPART(YEAR,p.ExpectedDeliveryDate) = 2013
  AND (d.DeliveryMethodName = 'Air Freight' or d.DeliveryMethodName = 'Refrigerated Air Freight' )
  and p.IsOrderFinalized = 1 
  

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

TODO5:
--вообще сортировку лучше сделать по первичному ключу (primary key clustered)
--тогда последние заказы не надо сортировать по дате.
--там данные тогда уже и так отсортированы
 
SELECT top(10) o.OrderID,o.OrderDate,c.CustomerID,c.CustomerName,o.SalespersonPersonID,p.FullName
FROM Sales.Orders o
INNER JOIN Sales.Customers c on c.CustomerID = o.CustomerID
INNER JOIN Application.People p on p.PersonID = o.SalespersonPersonID
WHERE c.CustomerID is not NULL
  AND p.FullName IS not NULL
ORDER BY o.OrderDate DESC



/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

TODO6: --напишите здесь свое решение

SELECT DISTINCT c.CustomerID,c.CustomerName,c.PhoneNumber
FROM Sales.OrderLines o
INNER JOIN Sales.Orders od on od.OrderID = o.OrderID
INNER JOIN Warehouse.StockItems s on s.StockItemID = o.StockItemID
INNER JOIN Sales.Customers c on c.CustomerID = od.CustomerID
WHERE s.StockItemName = 'Chocolate frogs 250g'
ORDER BY c.CustomerID

