

--===============================
--Name		: Belal Uddin 
--ID		: 1246403
--Round		: 39
--Subject	: C#
--==============================

--Project On Inventory Management System (SQL):
/*
This project is based on simple Inventory Management System which is incluede product purchase from suppliers with different brand, different item, different
category by using a single store procedure as a shop owner. This project also shows, how you can purchas product from the shop as a customer with another single
store procedure. At the time of purchase product from the shop, the invoice and shipper will auto generate. shipper will set a date of delivery within 3 days 
from the date of purchase. it also incluede calculation of sales price, free offer handling etc.
=> The shop owner always follow the minimum price policy to hold maximum amount of customer.
=> For product id 2, one product is free for every two product purchase.
*/

--===============================

USE master
IF DB_ID('MyInventoryMgt') IS NOT NULL
DROP DATABASE MyInventoryMgt
GO


Use master
CREATE DATABASE MyInventoryMgt
GO

Alter Database MyInventoryMgt Modify File (Name = 'MyInventoryMgt', Size = 16MB, MaxSize = Unlimited, FileGrowth = 2MB)
Alter Database MyInventoryMgt Modify File (Name = 'MyInventoryMgt_log', Size = 10MB, MaxSize = 100MB, FileGrowth = 1MB)
Go

USE MyInventoryMgt
Go

Create Schema BUH
GO


USE MyInventoryMgt
CREATE TABLE BUH.Suppliers
(
SuppliersID int primary key identity,
SuppliersName varchar (15) not null,
Address varchar (50) not null
)
GO

Insert into BUH.Suppliers values
('Ridwan', 'Chittagong'),
('Rashed', 'Dhaka'),
('Farhad', 'Comilla')
GO


USE MyInventoryMgt
CREATE TABLE BUH.Category
(
CategoryID int Primary key identity,
CategoryName varchar (20) not null
)
GO

Insert into BUH.Category Values
('Electronics'),
('Clothings'),
('Food')
GO


USE MyInventoryMgt
CREATE TABLE BUH.Brand
(
BrandID int primary key identity,
BrandName varchar (20) not null
)
GO

Insert into BUH.Brand Values 
('Walton'),
('CatsEye'),
('WellFood')
GO


USE MyInventoryMgt
CREATE TABLE BUH.Items
(
ItemsID int primary key identity,
ItemsName varchar (20) not null
)
GO

Insert into BUH.Items Values
('Mobile'),
('Shirt'),
('Pizza')
GO

USE MyInventoryMgt
CREATE TABLE BUH.Purchase
(
PurchaseID int primary key identity,
SuppliersID int foreign key references BUH.Suppliers (SuppliersID),
CategoryID int foreign key references BUH.Category (CategoryID),
BrandID int foreign key references BUH.Brand (BrandID),
ItemsID int foreign key references BUH.Items(ItemsID),
NumberOfUnit int,
UnitePrice money,
DateOfPurchase datetime default( Getdate())
)
GO


USE MyInventoryMgt
CREATE TABLE BUH.Product
(
ProductID int primary key identity,
ProductName varchar (20) not null,
PurchaseID int foreign key references BUH.Purchase (PurchaseID),
NumberOfUnit int,
RetailUnitPrice money
)
GO

USE MyInventoryMgt
CREATE TABLE BUH.Customer
(
CustomerID int primary key,
CustomerName varchar (20) not null,
CellPhone varchar (15) CHECK (CellPhone like'018%' OR CellPhone like'017%' OR CellPhone like'016%'),
Address varchar (50) not null
)
GO

USE MyInventoryMgt
Create Sequence cust_Sequence
AS Bigint
START WITH 1
INCREMENT BY 1
GO

Insert into BUH.Customer (CustomerID, CustomerName, CellPhone, Address)  Values
(NEXT VALUE FOR cust_Sequence,'Karim', '0160987654','Chittagong'),
(NEXT VALUE FOR cust_Sequence,'Rashid', '0180987654','Dhaka'),
(NEXT VALUE FOR cust_Sequence,'Selim','0170987654', 'Barishal'),
(NEXT VALUE FOR cust_Sequence,'Rashid', '0180987654','Dhaka'),
(NEXT VALUE FOR cust_Sequence,'Selim','0170987654', 'Barishal')
GO

USE MyInventoryMgt
CREATE TABLE BUH.OrderTable
(
OrderID int primary key identity,
ProductID int foreign key references BUH.Product (ProductID),
CustomerID int foreign key references BUH.Customer (CustomerID),
Quantity int,
DateOfOrder AS ((CONVERT(varchar (20) , getdate(), 0)))
)
GO


USE MyInventoryMgt
CREATE TABLE BUH.OrderDetails
(
OrderDetailsID int primary key identity,
OrderID int foreign key references BUH.OrderTable (OrderID),
TotalAmount money
)
GO

USE MyInventoryMgt
CREATE TABLE BUH.Invoice
(
InvoiceID int primary key identity,
OrderDetailsID int foreign key references BUH.OrderDetails (OrderDetailsID),
Tax varchar (20),
AmountIncludingTax money
)
GO

USE MyInventoryMgt
CREATE TABLE BUH.Shipper
(
ShipperID int identity,
OrderDetailsID int foreign key references BUH.OrderDetails (OrderDetailsID),
DateOfDelivery AS CAST(GETDATE() + 3 as date)
)
GO


--================================================================================================================
-- Function for Product Price Calculation
Create Function fn_TotalPrice
(
@price money
)
returns money
AS
BEGIN
declare @totalprice money
Set @totalprice = @price + (@price * .15)
return @totalprice
END
GO


--=================================================================================================================
-- Function for Product Quantity Calculation
Create Function fn_ProductOrderWithFree
(
@quantity int
)
Returns int
As
Begin
	declare @totalquantity int
	Set @totalquantity = @quantity + (@quantity / 2)
	Return @totalquantity
End
Go

--================================================================================================================

Create Proc SP_MyPurchase
(
@purchaseid int,
@supplierid int,
@categoryid int,
@brandid int,
@itemid int,
@numberofunity int,
@unitprice money,
@productname varchar(20),

@productid int,
@operation varchar (20)
)
AS
	BEGIN
	Set nocount on
		BEGIN TRY
			BEGIN TRAN

				if(@operation = 'Insert')
					BEGIN
						INSERT INTO BUH.Purchase (SuppliersID, CategoryID, BrandID, ItemsID, NumberOfUnit, UnitePrice)
						VALUES (@supplierid, @categoryid, @brandid, @itemid, @numberofunity, @unitprice)

						IF(@productname IN (Select ProductName from BUH.Product) AND @unitprice IN (Select (RetailUnitPrice * 100)/105  from BUH.Product Where ProductName = @productname))
							Begin
								UPDATE BUH.Product Set NumberOfUnit = NumberOfUnit + @numberofunity where RetailUnitPrice = @unitprice + (@unitprice * 0.05) AND ProductName = @productname
								Print 'Updated Existing Items !!!'
							End
						Else
							Begin
								INSERT INTO BUH.Product (ProductName, PurchaseID, NumberOfUnit, RetailUnitPrice)
								VALUES (@productname, @@IDENTITY,@numberofunity, @unitprice + (@unitprice * 0.05))
								Print 'Purchased New Items !!!'
							End

					END

					IF(@operation = 'Update')
					BEGIN
						Update BUH.Purchase set CategoryID = @categoryid, BrandID = @brandid, ItemsID = @itemid, NumberOfUnit = @numberofunity, UnitePrice = @unitprice Where PurchaseID = @purchaseid
						Update BUH.Product set RetailUnitPrice = @unitprice where PurchaseID = @purchaseid
					END

				
				if(@operation = 'Delete')
					BEGIN
						DELETE FROM BUH.Product WHERE PurchaseID = @purchaseid
					END

			COMMIT TRAN
		END TRY

		BEGIN CATCH
			ROLLBACK TRAN
		END CATCH
	END
GO


-- Purchase Product From Suppliers.

-- Input item   (Purchaseid, Supplierid, Categoryid, Brandid, Itemid, Numberofunit, Price, Productname, Productid, Operation)
EXEC SP_MyPurchase   2,        3,          3,          3,       3,         3,        3000,  'Monitor',      1,      'Insert'
GO  

select * from BUH.Product
GO

--=============================================================================================================================
Create Proc SP_Order
(
@productid int, 
@customerid int,
@quanitiy int
)
AS
BEGIN
	set nocount on

	declare @totalamount money
	Set @totalamount = (Select RetailUnitPrice from BUH.Product Where ProductID = @productid) * @quanitiy

	if (@quanitiy) <= (Select NumberOfUnit from BUH.Product where ProductID = @productid)
	BEGIN
		if(@quanitiy >= 2 AND @productid = 2)
		Begin
			if(dbo.fn_ProductOrderWithFree(@quanitiy) <= (Select NumberOfUnit from BUH.Product where ProductID = 2))
				Begin
					INSERT INTO BUH.OrderTable (ProductID, CustomerID, Quantity) VALUES(@productid, @customerid, dbo.fn_ProductOrderWithFree(@quanitiy))
					INSERT INTO BUH.OrderDetails VALUES (@@IDENTITY, @totalamount)
					INSERT INTO BUH.Invoice (OrderDetailsID, Tax, AmountIncludingTax) VALUES (@@IDENTITY,'15%', dbo.fn_TotalPrice(@totalamount))
					INSERT INTO BUH.Shipper (OrderDetailsID) VALUES (@@IDENTITY)
					UPDATE BUH.Product SET NumberOfUnit = NumberOfUnit - dbo.fn_ProductOrderWithFree(@quanitiy) Where ProductID = @productid
					PRINT'Successfully Purchased !!!'
				End
			Else
				Begin
					Print 'Stock Shortage !!!';
				End
			
		End

		Else

			Begin
				INSERT INTO BUH.OrderTable (ProductID, CustomerID, Quantity) VALUES(@productid, @customerid, @quanitiy)
				INSERT INTO BUH.OrderDetails VALUES (@@IDENTITY, @totalamount)
				INSERT INTO BUH.Invoice (OrderDetailsID, Tax, AmountIncludingTax) VALUES (@@IDENTITY,'15%', dbo.fn_TotalPrice(@totalamount))
				INSERT INTO BUH.Shipper (OrderDetailsID) VALUES (@@IDENTITY)
				UPDATE BUH.Product SET NumberOfUnit = NumberOfUnit - @quanitiy Where ProductID = @productid
				PRINT'Successfully Purchased !!!'
			End
	END

	ELSE
	BEGIN
	PRINT 'Stock Shortage !!! OR Invalid Product ID !!!'
	END
END
GO

-- Order as a Customer

-- Input item (Productid, Customerid, Quantity)        (in case of productID 2, one product is free for every two product purchase)
EXEC SP_Order      1,          2,        1
GO


--=============== Trigger ======================
--USE MyInventoryMgt
Create Trigger tr_ProductOrderTrigger on BUH.OrderTable
For Insert
As
	declare @quantity int
	declare @productid int
	Select @productid = i.ProductID from inserted i;
	Select @quantity = i.Quantity from inserted i;
Begin

	if(@quantity >=2 AND @productid = 2)
		Begin
			Print 'Congratulation !! You have got free product with purchased quantity !!!'
		End
	else
		Begin
			Print 'You have purchse product with no free offer !!!'
		End
End
Go

--=======================================================================================================================================
--	                                                                  REPORTING WORK
--=======================================================================================================================================


--======================= View ===================
Create view vw_ProductOrderDetails
With Encryption
AS
Select Count (p.ProductID) as OrderedProductID, p.ProductName, COUNT ( o.Quantity) as AmountOfOrder, sum (od.TotalAmount) as Price
From BUH.Product p
JOIN BUH.OrderTable o
ON p.ProductID = o.ProductID
JOIN BUH.OrderDetails od
ON o.OrderID = od.OrderID
Where p.ProductID in (Select ProductID from BUH.OrderTable)
Group by p.ProductName, od.TotalAmount
Having od.TotalAmount > 0

Go

Select * from vw_ProductOrderDetails
GO

--=============== Join =================================
Select pur.PurchaseID, SuppliersID, CategoryID, BrandID, ItemsID, UnitePrice as PurchasePrice, ProductID, ProductName, pdt.NumberOfUnit as AvailableUnit, RetailUnitPrice
From BUH.Purchase pur
INNER JOIN BUH.Product pdt
ON pur.PurchaseID = pdt.PurchaseID 
Order by pur.PurchaseID
Go

Select o.OrderID, o.ProductID, o.CustomerID, o.Quantity, od.TotalAmount, o.DateOfOrder
From BUH.OrderTable o
LEFT OUTER JOIN BUH.OrderDetails od
ON o.OrderID = od.OrderID
Where od.TotalAmount > 0
GO

Select o.OrderID, o.ProductID, o.CustomerID, o.Quantity, od.TotalAmount, o.DateOfOrder
From BUH.OrderTable o
RIGHT OUTER JOIN BUH.OrderDetails od
ON o.OrderID = od.OrderID
Where od.TotalAmount<= 500 OR od.TotalAmount >= 900
GO

Select o.OrderID, o.ProductID, o.CustomerID, o.Quantity, od.TotalAmount, o.DateOfOrder
From BUH.OrderTable o
CROSS JOIN BUH.OrderDetails od
Where od.TotalAmount > 0
GO

Select o.OrderID, o.ProductID, o.CustomerID, o.Quantity, o.DateOfOrder
From BUH.OrderTable o
JOIN BUH.OrderTable od
ON o.OrderID = od.OrderID
Where od.OrderID > 0
GO
--================== Temp Table ===========================
if OBJECT_ID('tempdb..#tempProductTable') IS NOT NULL
drop table #tempProductTable
Go

Create table #tempProductTable
(
ProductID int,
ProductName varchar (20),
NumberOfUnit int,
RetailUnitPrie money
)
GO

insert into #tempProductTable (ProductID, ProductName, NumberOfUnit, RetailUnitPrie)
Select ProductID, ProductName, NumberOfUnit, RetailUnitPrice 
from BUH.Product
go


Select * from #tempProductTable
go


--============= CUBE ==================
Select ProductName, Sum (RetailUnitPrie) as TotalPrice
from #tempProductTable
Group by ProductName, RetailUnitPrie With CUBE
GO

--============ ROLLUP ================
Select ProductName, Sum (RetailUnitPrie) as TotalPrice
from #tempProductTable
Group by ProductName, RetailUnitPrie With ROLLUP
GO

--=========== Groupint Set =============
Select ProductName, Sum (RetailUnitPrie) as TotalPrice
from #tempProductTable
Group by GROUPING SETS (
(ProductName, RetailUnitPrie),
(ProductName)
)
GO
--==================== MAX ================
Select ProductName, MAX(RetailUnitPrice) as unitPrice
From BUH.Product
Group by ProductName
order by unitPrice
GO

--============= MIN =====================
Select ProductName, MIN (RetailUnitPrice) as unitPrice
From BUH.Product
Group by ProductName
order by unitPrice
GO
--============= AVG =================
Select OrderID, AVG (TotalAmount) as Average
From BUH.OrderDetails
Group by OrderID
GO

--======== DISTINCT =================
Select DISTINCT CustomerName
From BUH.Customer
GO 

--=========== CTE ==================
WITH my_CustomerCTE
AS
(
Select CustomerID, CustomerName, CellPhone from BUH.Customer
)

Select * from my_CustomerCTE
GO

--================== BETWEEN =============
Select * from BUH.Product
Where RetailUnitPrice between 0 and 500
go

--============== INDEX ====================

CREATE CLUSTERED INDEX cIndex
ON BUH.Shipper (ShipperID)
GO

CREATE NONCLUSTERED INDEX ncIndex
ON BUH.Product (PurchaseID)
GO

--============== TOP =====================
Select Top 3 * from BUH.Product
Go

--============ UNION, UNION ALL ===================
Select CustomerID as ID, CustomerName, Address from BUH.Customer
UNION 
Select SuppliersID, SuppliersName, Address from BUH.Suppliers

Select CustomerID as ID, CustomerName, Address from BUH.Customer
UNION All
Select SuppliersID, SuppliersName, Address from BUH.Suppliers
Go

--=========== ANY, ALL, SOME =============================
Select ProductID, ProductName, NumberOfUnit as AvailableUnit, RetailUnitPrice from BUH.Product
Where ProductID = ANY (Select OrderID from BUH.OrderTable)
Go

Select ProductID, ProductName, NumberOfUnit as AvailableUnit, RetailUnitPrice from BUH.Product
Where ProductID = All (Select OrderID from BUH.OrderTable)
Go

Select * from BUH.Product
Where RetailUnitPrice > some (Select UnitePrice from BUH.Purchase)
GO

--================ EXISTS =====================
SELECT ProductName FROM BUH.Product
WHERE EXISTS (SELECT ProductID FROM BUH.OrderTable Where ProductID > 0)
GO

--================= INTERSECT, EXCEPT ===============
Select ProductID from BUH.Product
INTERSECT
Select ProductID from BUH.OrderTable
GO

Select ProductID from BUH.Product
EXCEPT
Select ProductID from BUH.OrderTable
GO
--====================== RANK, GROUPING ==================

Select CustomerID, CustomerName, CellPhone, RANK() over( Order by CustomerName asc) as Ranking 
from BUH.Customer
GO

Select Address, COUNT(CustomerName) [Total Customer],  GROUPING(Address) AS Grouping 
from BUH.Customer
GROUP BY Address
Go

--============== CASE, CHOOSE, COALESCE ============
Select ProductID, ProductName,
CASE 
	WHEN RetailUnitPrice > 400 THEN ('The Unit Price is grater than 400')
	WHEN RetailUnitPrice < 400 THEN ('The Unit Price is less than 400')
END
from BUH.Product
GO

Select ProductName, CHOOSE(ProductID, 'A', 'B', 'C', 'D') As Result 
from BUH.Product
GO

Select COALESCE (Null, Null, CustomerName, Null, Address) As Name
From BUH.Customer
GO

--======================== ROUND, FLOOR, CEILING ==================
Select ProductID, ProductName, ROUND (RetailUnitPrice, 2) as Price
from BUH.Product
GO

Select ProductID, ProductName, FLOOR(RetailUnitPrice) as Price
from BUH.Product
GO

Select ProductID, ProductName, CEILING (RetailUnitPrice) as Price
from BUH.Product
GO
--======================================================
USE MyInventoryMgt
Select * from BUH.Purchase
Select * from BUH.Product
Select * from BUH.OrderTable
Select * from BUH.OrderDetails
Select * from BUH.Suppliers
Select * from BUH.Category
Select * from BUH.Brand
Select * from BUH.Customer
Select * from BUH.Invoice
Select * from BUH.Shipper
GO





