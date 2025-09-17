-- Test plan 

-- When Colpattern is given for mapping
DECLARE @docHandle int; 
DECLARE @xmlDocument nvarchar(1000); 
SET @xmlDocument =N'<ROOT>
<Customer CustomerID="VINET" ContactName="Paul Henriot">
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate=
           "1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3" OrderDate=
           "1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>'; 
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument; 
SELECT * 
FROM OPENXML (@docHandle, '/ROOT/Customer/Order/OrderDetail/@ProductID') 
       WITH ( ProdID  int '.',
              Qty     int '../@Quantity',
              OID     int '../../@OrderID');
EXEC sp_xml_removedocument @docHandle;
GO

-- flag = 0 (default attribute centric)
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer CustomerID="VINET" ContactName="Paul Henriot">
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5"
          OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT * 
FROM OPENXML (@DocHandle, '/ROOT/Customer',0)
      WITH (CustomerID  varchar(10) ,
            ContactName varchar(20));
EXEC sp_xml_removedocument @DocHandle;
GO

-- flag = 1 (attribute centric)
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer CustomerID="VINET" ContactName="Paul Henriot">
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5"
          OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT * 
FROM OPENXML (@DocHandle, '/ROOT/Customer',1)
      WITH (CustomerID  varchar(10) ,
            ContactName varchar(20));
EXEC sp_xml_removedocument @DocHandle;
GO

-- flag = 2 (element centric)
DECLARE @XmlDocumentHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer>
   <CustomerID>VINET</CustomerID>
   <ContactName>Paul Henriot</ContactName>
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer>
   <CustomerID>LILAS</CustomerID>
   <ContactName>Carlos Gonzalez</ContactName>
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3" OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @XmlDocument;

SELECT * 
FROM      OPENXML (@XmlDocumentHandle, '/ROOT/Customer', 2)
           WITH (CustomerID  varchar(10),
                 ContactName varchar(20));
EXEC sp_xml_removedocument @XmlDocumentHandle;
GO

-- flag = 3 (combines both)
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer customerid="VINET" contactname="Paul Henriot">
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5"
          OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer>
   <customerid>LILAS</customerid>
   <contactname>Carlos Gonzalez</contactname>
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3" OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT * 
FROM OPENXML (@DocHandle, '/ROOT/Customer',3)
      WITH (customerid  varchar(10),
            contactname varchar(20));
EXEC sp_xml_removedocument @DocHandle;
GO

-- flag = 8
DECLARE @XmlDocumentHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer>
   <CustomerID>VINET</CustomerID>
   <ContactName>Paul Henriot</ContactName>
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @XmlDocument;

SELECT *
FROM      OPENXML (@XmlDocumentHandle, '/ROOT/Customer',8)
           WITH (CustomerID  varchar(10),
                 ContactName varchar(20));
EXEC sp_xml_removedocument @XmlDocumentHandle;
GO

-- default flag is 0
DECLARE @idoc INT, @doc VARCHAR(1000);
SET @doc = N'<ROOT>
<Customer>
   <CustomerID>VINET</CustomerID>
   <ContactName>Paul Henriot</ContactName>
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @idoc OUTPUT, @doc;

SELECT *
FROM      OPENXML (@idoc, '/ROOT/Customer')
           WITH (CustomerID  varchar(10),
                 ContactName varchar(20));
EXEC sp_xml_removedocument @idoc;
GO

-- If tablename is given 
DECLARE @docHandle int;
DECLARE @XmlDocument varchar(1000);

SET @xmlDocument = N'<root>
  <Customer cid= "C1" name="Janine" city="Issaquah">
      <Order oid="O1" date="1/20/1996" amount="3.5" />
      <Order oid="O2" date="4/30/1997" amount="13.4">Customer was very
             satisfied</Order>
   </Customer>
   <Customer cid="C2" name="Ursula" city="Oelde" >
      <Order oid="O3" date="7/14/1999" amount="100" note="Wrap it blue
             white red">
          <Urgency>Important</Urgency>
      </Order>
      <Order oid="O4" date="1/20/1996" amount="10000"/>
   </Customer>
</root>'; 

EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument; 

SELECT * 
FROM OPENXML (@docHandle, '/root/Customer/Order', 1) 
     WITH test_openxml_table;

EXEC sp_xml_removedocument @docHandle;
GO

-- If flag value more than 3
DECLARE @XmlDocumentHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer>
   <CustomerID>VINET</CustomerID>
   <ContactName>Paul Henriot</ContactName>
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @XmlDocument;

SELECT *
FROM      OPENXML (@XmlDocumentHandle, '/ROOT/Customer', 4)
           WITH (CustomerID  varchar(10),
                 ContactName varchar(20));
EXEC sp_xml_removedocument @XmlDocumentHandle;
GO

DECLARE @XmlDocumentHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer>
   <CustomerID>VINET</CustomerID>
   <ContactName>Paul Henriot</ContactName>
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @XmlDocument;

SELECT *
FROM      OPENXML (@XmlDocumentHandle, '/ROOT/Customer', 7)
           WITH (CustomerID  varchar(10),
                 ContactName varchar(20));
EXEC sp_xml_removedocument @XmlDocumentHandle;
GO

-- rowpattern is case sensitive (this gives null)
DECLARE @XmlDocumentHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer>
   <CustomerID>VINET</CustomerID>
   <ContactName>Paul Henriot</ContactName>
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @XmlDocument;

SELECT *
FROM      OPENXML (@XmlDocumentHandle, '/root/customer', 4)
           WITH (CustomerID  varchar(10),
                 ContactName varchar(20));
EXEC sp_xml_removedocument @XmlDocumentHandle;
GO

-- colpattern is case sensitive
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer CustomerID="VINET" ContactName="Paul Henriot">
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5"
          OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT * 
FROM OPENXML (@DocHandle, '/ROOT/Customer',1)
      WITH (customerid  varchar(10) ,
            contactname varchar(20));
EXEC sp_xml_removedocument @DocHandle;
GO

-- negative flag value
DECLARE @XmlDocumentHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer>
   <CustomerID>VINET</CustomerID>
   <ContactName>Paul Henriot</ContactName>
   <Order OrderID="10248" CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail ProductID="11" Quantity="12"/>
      <OrderDetail ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzalez">
   <Order OrderID="10283" CustomerID="LILAS" EmployeeID="3"
          OrderDate="1996-08-16T00:00:00">
      <OrderDetail ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @XmlDocument;

SELECT *
FROM      OPENXML (@XmlDocumentHandle, '/ROOT/Customer', -1)
           WITH (CustomerID  varchar(10),
                 ContactName varchar(20));
EXEC sp_xml_removedocument @XmlDocumentHandle;
GO

-- Mixed attributes
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<Library>
<Book ISBN="123456789" Category="Fiction">
    <Title>The Great Novel</Title>
    <Author>
        <FirstName>John</FirstName>
        <LastName>Author</LastName>
        <Rating>4.5</Rating>
    </Author>
    <Publication>
        <Publisher>Book House</Publisher>
        <Year>2023</Year>
        <Price currency="USD">29.99</Price>
    </Publication>
</Book>
</Library>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT * 
FROM OPENXML (@DocHandle, '/Library/Book', 2)
WITH (
    ISBN varchar(20),
    Category varchar(50),
    Title varchar(100) 'Title',
    AuthorFirstName varchar(50) 'Author/FirstName',
    AuthorLastName varchar(50) 'Author/LastName',
    Rating decimal(3,1) 'Author/Rating',
    Publisher varchar(50) 'Publication/Publisher',
    PublishYear int 'Publication/Year',
    Price decimal(10,2) 'Publication/Price',
    Currency varchar(3) 'Publication/Price/@currency'
);
EXEC sp_xml_removedocument @DocHandle;
GO

-- Nested elements
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(2000);
SET @XmlDocument = N'<Invoices>
<Invoice InvoiceID="INV001" Date="2024-01-15">
    <Customer ID="CUST001">
        <Name>Acme Corp</Name>
        <Address>123 Business St</Address>
    </Customer>
    <Items>
        <Item SKU="SKU001">
            <Description>Laptop</Description>
            <Quantity>2</Quantity>
            <UnitPrice>999.99</UnitPrice>
            <Discount>0.10</Discount>
        </Item>
        <Item SKU="SKU002">
            <Description>Mouse</Description>
            <Quantity>5</Quantity>
            <UnitPrice>24.99</UnitPrice>
            <Discount>0.05</Discount>
        </Item>
    </Items>
</Invoice>
</Invoices>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT * 
FROM OPENXML (@DocHandle, '/Invoices/Invoice', 2)
WITH (
    InvoiceID varchar(10),
    InvoiceDate date '@Date',
    CustomerID varchar(10) 'Customer/@ID',
    CustomerName varchar(50) 'Customer/Name',
    CustomerAddress varchar(100) 'Customer/Address'
);

SELECT * 
FROM OPENXML (@DocHandle, '/Invoices/Invoice/Items/Item', 2)
WITH (
    InvoiceID varchar(10) '../../../@InvoiceID',
    SKU varchar(10) '@SKU',
    Description varchar(100) 'Description',
    Quantity int 'Quantity',
    UnitPrice decimal(10,2) 'UnitPrice',
    Discount decimal(4,2) 'Discount'
);

EXEC sp_xml_removedocument @DocHandle;
GO

-- Basic example which gives customer, order, product details
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<ROOT>
<Customer CustomerID="C001" ContactName="John Doe">
   <Order OrderID="1001" OrderDate="2024-01-15">
      <Product ProductID="P1" Quantity="5" Price="100"/>
      <Product ProductID="P2" Quantity="3" Price="200"/>
   </Order>
</Customer>
<Customer CustomerID="C002" ContactName="Jane Smith">
   <Order OrderID="1002" OrderDate="2024-01-16">
      <Product ProductID="P3" Quantity="2" Price="150"/>
   </Order>
</Customer>
</ROOT>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;


SELECT * 
FROM OPENXML (@DocHandle, '/ROOT/Customer', 1)
WITH (
    CustomerID varchar(10),
    ContactName varchar(50)
);

SELECT * 
FROM OPENXML (@DocHandle, '/ROOT/Customer/Order', 1)
WITH (
    OrderID int,
    OrderDate date,
    CustomerID varchar(10) '../@CustomerID'
);


SELECT * 
FROM OPENXML (@DocHandle, '/ROOT/Customer/Order/Product', 1)
WITH (
    OrderID int '../@OrderID',
    ProductID varchar(10),
    Quantity int,
    Price decimal(10,2)
);

EXEC sp_xml_removedocument @DocHandle;
GO

-- When table name or colname > 64 bytes

-- Test Case 1: Long table name (> 64 bytes)
INSERT INTO very_long_table_name_that_exceeds_sixty_four_characters_limit_test 
VALUES (1, 'Test', 100);

DECLARE @xml_doc INT;
EXEC sp_xml_preparedocument @xml_doc OUTPUT, 
'<root><item id="1" name="John" value="200"/></root>';

SELECT * FROM 
OPENXML(@xml_doc, '/root/item') 
WITH very_long_table_name_that_exceeds_sixty_four_characters_limit_test;

EXEC sp_xml_removedocument @xml_doc;
GO

-- Test Case 2: Long column names (> 64 bytes)
INSERT INTO test_long_columns VALUES (1, 'Test Value', 999);

DECLARE @xml_doc2 INT;
EXEC sp_xml_preparedocument @xml_doc2 OUTPUT, 
'<data>
    <record very_long_column_name_that_definitely_exceeds_sixty_four_characters_limit_test="123" 
            another_extremely_long_column_name_exceeding_standard_limits_for_testing="Long Value" 
            short_col="456"/>
</data>';


SELECT * FROM 
OPENXML(@xml_doc2, '/data/record') 
WITH test_long_columns;

EXEC sp_xml_removedocument @xml_doc2;
GO

-- Test Case 3: Explicit column definitions with long names
DECLARE @xml_doc3 INT;
EXEC sp_xml_preparedocument @xml_doc3 OUTPUT, 
'<items>
    <item col1="value1" col2="value2"/>
</items>';

SELECT * FROM 
OPENXML(@xml_doc3, '/items/item') WITH (
    very_long_column_name_that_definitely_exceeds_sixty_four_characters_limit_one VARCHAR(100),
    another_extremely_long_column_name_that_exceeds_standard_database_limits_two VARCHAR(100)
);

EXEC sp_xml_removedocument @xml_doc3;
GO

-- Test Case 4: Mixed long and short names
DECLARE @xml_doc4 INT;
EXEC sp_xml_preparedocument @xml_doc4 OUTPUT, 
'<test>
    <row id="1" 
         extremely_long_column_name_that_exceeds_the_standard_sixty_four_character_limit_for_identifiers="Long Value Test" 
         short="Short"/>
</test>';

SELECT * FROM 
OPENXML(@xml_doc4, '/test/row') 
WITH mixed_length_names;

EXEC sp_xml_removedocument @xml_doc4;
GO

-- Openxml with table having default constraints
INSERT INTO employee_defaults (name, department, salary) 
VALUES ('Test Employee', 'IT', 50000);

DECLARE @xml_doc INT;
EXEC sp_xml_preparedocument @xml_doc OUTPUT, 
'<employees>
    <emp name="John Smith" department="HR"/>
    <emp name="Jane Doe" salary="75000"/>
    <emp name="Bob Wilson"/>
</employees>';

SELECT * FROM 
OPENXML(@xml_doc, '/employees/emp') WITH employee_defaults;

EXEC sp_xml_removedocument @xml_doc;
GO

-- Test with empty XML document
DECLARE @DocHandle int;
EXEC sp_xml_preparedocument @DocHandle OUTPUT;
SELECT * 
FROM OPENXML (@DocHandle, '/', 1)
WITH (
    CustomerID varchar(10),
    ContactName varchar(50)
);
EXEC sp_xml_removedocument @DocHandle;
GO

-- CROSS APPLY with openxml
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<Customers>
    <Customer ID="1" Name="John">
        <Order ID="1" Date="2024-01-01"/>
        <Order ID="2" Date="2024-01-02"/>
    </Customer>
    <Customer ID="2" Name="Jane">
        <Order ID="3" Date="2024-01-03"/>
    </Customer>
</Customers>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate 
FROM 
    OPENXML(@DocHandle, '/Customers/Customer', 2) 
    WITH (
        CustomerID int '@ID',
        CustomerName varchar(50) '@Name'
    ) c 
CROSS APPLY
    OPENXML(@DocHandle, '/Customers/Customer', 2) 
    WITH (
        OrderID int '@ID',
        OrderDate date '@Date'
    ) o;

EXEC sp_xml_removedocument @DocHandle;
GO

-- cross apply for different row patterns
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<Customers>
    <Customer ID="1" Name="John">
        <Order ID="1" Date="2024-01-01"/>
        <Order ID="2" Date="2024-01-02"/>
    </Customer>
    <Customer ID="2" Name="Jane">
        <Order ID="3" Date="2024-01-03"/>
    </Customer>
</Customers>';

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;

SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate 
FROM 
    OPENXML(@DocHandle, '/Customers/Customer', 2) 
    WITH (
        CustomerID int '@ID',
        CustomerName varchar(50) '@Name'
    ) c 
CROSS APPLY
    OPENXML(@DocHandle, 
        concat('/Customers/Customer[@ID=', c.CustomerID, ']/Order'),
        2) 
    WITH (
        OrderID int '@ID',
        OrderDate date '@Date'
    ) o;

EXEC sp_xml_removedocument @DocHandle;
GO

-- cross apply for different row patterns
DECLARE @DocHandle int;
DECLARE @XmlDocument nvarchar(1000);
SET @XmlDocument = N'<Customers></Customers>';
EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument;
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate 
FROM 
    OPENXML(@DocHandle, '/Customers/Customer', 2)
    WITH (
        CustomerID int '@ID',
        CustomerName varchar(50) '@Name'
    ) c 
CROSS APPLY 
    OPENXML(@DocHandle, 
        concat('/Customers/Customer[@ID=', c.CustomerID, ']/Order'),
        2) 
    WITH (
        OrderID int '@ID',
        OrderDate date '@Date'
    ) o;
EXEC sp_xml_removedocument @DocHandle;
GO

-- Basic CROSS APPLY with OPENXML using table reference
INSERT INTO person_table VALUES (1, 'John', 25), (2, 'Jane', 30);

DECLARE @xml_doc INT;
EXEC sp_xml_preparedocument @xml_doc OUTPUT, '<root><person id="1" name="John"/><person id="2" name="Jane"/></root>';

SELECT * FROM 
(SELECT 1 as id) t 
CROSS APPLY OPENXML(@xml_doc, '/root/person') WITH person_table;

EXEC sp_xml_removedocument @xml_doc;
GO

-- OUTER APPLY
DECLARE @xml_doc2 INT;
EXEC sp_xml_preparedocument @xml_doc2 OUTPUT, 
'<data>
    <customer id="1" name="John"/>
    <customer id="2" name="Jane"/>
    <order cust_id="1" order_id="100" amount="500"/>
    <order cust_id="1" order_id="101" amount="300"/>
    <order cust_id="2" order_id="102" amount="200"/>
</data>';

SELECT 
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.amount 
FROM 
    OPENXML(@xml_doc2, '/data/customer', 1) WITH (
        customer_id INT,
        customer_name VARCHAR(50)
    ) c 
OUTER APPLY 
    OPENXML(@xml_doc2, '/data/order', 1) WITH (
        cust_id INT,
        order_id INT,
        amount DECIMAL(10,2)
    ) o;

EXEC sp_xml_removedocument @xml_doc2;
GO

-- Base table with outer apply openxml
INSERT INTO regions VALUES (1, 'North'), (2, 'South'), (3, 'East'), (4, 'West');

DECLARE @xml_doc3 INT;
EXEC sp_xml_preparedocument @xml_doc3 OUTPUT, 
'<sales>
    <region id="1">
        <sale amount="1000" product="Laptop"/>
        <sale amount="500" product="Mouse"/>
    </region>
    <region id="3">
        <sale amount="750" product="Keyboard"/>
    </region>
</sales>';

SELECT 
    r.region_id,
    r.region_name,
    s.amount,
    s.product 
FROM 
    regions r 
OUTER APPLY 
    OPENXML(@xml_doc3, '/sales/region/sale', 2) WITH (
        region_id INT '../@id',
        amount DECIMAL(10,2),
        product VARCHAR(50)
    ) s 
WHERE s.region_id = r.region_id OR s.region_id IS NULL;

EXEC sp_xml_removedocument @xml_doc3;
GO

-- With namespaces
--test1
DECLARE @xml nvarchar(1000) = 
'<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2">
    <ns1:child>value1</ns1:child>
    <ns2:child>value2</ns2:child>
</root>';
DECLARE @namespace nvarchar(100) = '<root xmlns:ns1="http://example.com/ns1" />';
DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;
SELECT * FROM OPENXML(@handle, '/root/ns1:child', 3) WITH (child nvarchar(10) '.');
EXEC sp_xml_removedocument @handle;
GO
 
DECLARE @h int;
EXEC sp_xml_preparedocument @h OUTPUT,
         N'<root xmlns:a="urn:1">
           <a:Elem abar="asdf">
             T<a>a</a>U
           </a:Elem>
         </root>',
         '<ns xmlns:b="urn:1" />';

SELECT * FROM openxml(@h, '/root/b:Elem', 3)
      WITH (Col1 varchar(20) '.');
EXEC sp_xml_removedocument @h;
GO

-- test2
DECLARE @xml nvarchar(2000) = '
<root xmlns:hr="http://hr.example.com" 
      xmlns:fin="http://finance.example.com">
    <hr:employee>
        <hr:name>John Doe</hr:name>
        <fin:salary currency="USD">50000</fin:salary>
    </hr:employee>
    <hr:employee>
        <hr:name>Jane Smith</hr:name>
        <fin:salary currency="USD">60000</fin:salary>
    </hr:employee>
</root>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:hr="http://hr.example.com" 
      xmlns:fin="http://finance.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/root/hr:employee', 2)
WITH (
    name nvarchar(50) 'hr:name',
    salary int 'fin:salary',
    currency nvarchar(10) 'fin:salary/@currency'
);

EXEC sp_xml_removedocument @handle;
GO

--test3
DECLARE @xml nvarchar(2000) = '
<catalog xmlns:prod="http://products.example.com"
         xmlns:cat="http://categories.example.com">
    <cat:category name="Electronics">
        <prod:product>
            <prod:name>Laptop</prod:name>
            <prod:price>999.99</prod:price>
        </prod:product>
        <prod:product>
            <prod:name>Smartphone</prod:name>
            <prod:price>599.99</prod:price>
        </prod:product>
    </cat:category>
</catalog>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:prod="http://products.example.com"
      xmlns:cat="http://categories.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/catalog/cat:category/prod:product', 2)
WITH (
    category_name nvarchar(50) '../../@name',
    product_name nvarchar(50) 'prod:name',
    price decimal(10,2) 'prod:price'
);

EXEC sp_xml_removedocument @handle;
GO

--test4
DECLARE @xml nvarchar(2000) = '
<orders xmlns:ord="http://orders.example.com"
        xmlns:cust="http://customers.example.com"
        xmlns:prod="http://products.example.com">
    <ord:order id="1001">
        <cust:customer>
            <cust:name>Alice Johnson</cust:name>
            <cust:email>alice@email.com</cust:email>
        </cust:customer>
        <prod:items>
            <prod:item qty="2">Widget A</prod:item>
            <prod:item qty="1">Widget B</prod:item>
        </prod:items>
    </ord:order>
</orders>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:ord="http://orders.example.com"
      xmlns:cust="http://customers.example.com"
      xmlns:prod="http://products.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/orders/ord:order/prod:items/prod:item', 2)
WITH (
    order_id int '../../../@id',
    customer_name nvarchar(50) '../../../cust:customer/cust:name',
    item_name nvarchar(50) '.',
    quantity int '@qty'
);

EXEC sp_xml_removedocument @handle;
GO

--test5
DECLARE @xml nvarchar(2000) = '
<weather xmlns:loc="http://location.example.com"
         xmlns:met="http://meteorology.example.com">
    <loc:city id="NYC">
        <loc:name>New York</loc:name>
        <met:conditions date="2023-01-01">
            <met:temperature unit="C">20</met:temperature>
            <met:humidity>65</met:humidity>
        </met:conditions>
    </loc:city>
</weather>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:loc="http://location.example.com"
      xmlns:met="http://meteorology.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/weather/loc:city', 2)
WITH (
    city_id varchar(10) '@id',
    city_name varchar(50) 'loc:name',
    temperature int 'met:conditions/met:temperature',
    temp_unit varchar(1) 'met:conditions/met:temperature/@unit',
    humidity int 'met:conditions/met:humidity',
    reading_date date 'met:conditions/@date'
);

EXEC sp_xml_removedocument @handle;
GO

--test6
DECLARE @xml nvarchar(2000) = '
<medical xmlns:pat="http://patient.example.com"
         xmlns:doc="http://doctor.example.com"
         xmlns:treat="http://treatment.example.com">
    <pat:record id="12345">
        <pat:info>
            <pat:name>John Smith</pat:name>
            <pat:age>45</pat:age>
        </pat:info>
        <doc:physician>
            <doc:name>Dr. Brown</doc:name>
            <doc:specialty>Cardiology</doc:specialty>
        </doc:physician>
        <treat:treatment>
            <treat:diagnosis>Hypertension</treat:diagnosis>
            <treat:medication>Lisinopril</treat:medication>
        </treat:treatment>
    </pat:record>
</medical>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:pat="http://patient.example.com"
      xmlns:doc="http://doctor.example.com"
      xmlns:treat="http://treatment.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/medical/pat:record', 2)
WITH (
    record_id int '@id',
    patient_name nvarchar(50) 'pat:info/pat:name',
    patient_age int 'pat:info/pat:age',
    doctor_name nvarchar(50) 'doc:physician/doc:name',
    specialty nvarchar(50) 'doc:physician/doc:specialty',
    diagnosis nvarchar(100) 'treat:treatment/treat:diagnosis',
    medication nvarchar(100) 'treat:treatment/treat:medication'
);

EXEC sp_xml_removedocument @handle;
GO

--test7
DECLARE @xml nvarchar(2000) = '
<employees xmlns:hr="http://hr.example.com">
    <hr:employee id="1" department="IT">
        <hr:name>John Doe</hr:name>
        <hr:salary>50000</hr:salary>
    </hr:employee>
    <hr:employee id="2" department="HR">
        <hr:name>Jane Smith</hr:name>
        <hr:salary>60000</hr:salary>
    </hr:employee>
</employees>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:hr="http://hr.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/employees/hr:employee', 1)
WITH (
    id int,
    department varchar(20),
    name varchar(50),
    salary int
);

SELECT * FROM OPENXML(@handle, '/employees/hr:employee', 2)
WITH (
    id int,
    department varchar(20),
    name varchar(50),
    salary int
);

EXEC sp_xml_removedocument @handle;
GO

--test8
DECLARE @xml nvarchar(2000) = '
<employees xmlns:hr="http://hr.example.com">
    <hr:employee id="1" department="IT">
        <hr:name>John Doe</hr:name>
        <hr:salary>50000</hr:salary>
    </hr:employee>
    <hr:employee id="2" department="HR">
        <hr:name>Jane Smith</hr:name>
        <hr:salary>60000</hr:salary>
    </hr:employee>
</employees>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:hr="http://hr.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/employees/hr:employee', 3)
WITH (
    id int '@id',
    department varchar(20) '@department',
    name varchar(50) 'hr:name', 
    salary int 'hr:salary'
);

EXEC sp_xml_removedocument @handle;
GO

--test9
DECLARE @xml nvarchar(2000) = '
<root xmlns:cust="http://customer.example.com">
    <cust:Customer customerid="VINET" contactname="Paul Henriot" country="France">
        <cust:Order orderid="10248" total="100.00"/>
    </cust:Customer>
    <cust:Customer customerid="LILAS" contactname="Carlos Gonzalez" country="Spain">
        <cust:Order orderid="10283" total="200.00"/>
    </cust:Customer>
</root>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:cust="http://customer.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/root/cust:Customer', 1)
WITH (
    customerid varchar(10),
    contactname varchar(50),
    country varchar(20)
);

EXEC sp_xml_removedocument @handle;
GO

--test10
DECLARE @xml nvarchar(2000) = '
<root xmlns:emp="http://employee.example.com">
    <emp:Employee>
        <emp:EmployeeId>1001</emp:EmployeeId>
        <emp:FirstName>John</emp:FirstName>
        <emp:LastName>Doe</emp:LastName>
        <emp:Department>IT</emp:Department>
    </emp:Employee>
    <emp:Employee>
        <emp:EmployeeId>1002</emp:EmployeeId>
        <emp:FirstName>Jane</emp:FirstName>
        <emp:LastName>Smith</emp:LastName>
        <emp:Department>HR</emp:Department>
    </emp:Employee>
</root>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:emp="http://employee.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/root/emp:Employee', 2)
WITH (
    EmployeeId varchar(10),
    FirstName varchar(50),
    LastName varchar(50),
    Department varchar(20)
);

EXEC sp_xml_removedocument @handle;
GO

--test11
DECLARE @xml nvarchar(2000) = '
<root xmlns:ord="http://order.example.com">
    <ord:Order id="1001" date="2023-01-01">
        <ord:CustomerName>John Doe</ord:CustomerName>
        <ord:Total>100.00</ord:Total>
    </ord:Order>
    <ord:Order id="1002" date="2023-01-02">
        <ord:CustomerName>Jane Smith</ord:CustomerName>
        <ord:Total>200.00</ord:Total>
    </ord:Order>
</root>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:ord="http://order.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/root/ord:Order', 3)
WITH (
    id varchar(10),
    date datetime,
    CustomerName varchar(50),
    Total decimal(10,2)
);

EXEC sp_xml_removedocument @handle;
GO

--test12
DECLARE @xml nvarchar(2000) = '
<root xmlns:cust="http://customer.example.com"
      xmlns:addr="http://address.example.com">
    <cust:Customer id="C001">
        <cust:Name>John Doe</cust:Name>
        <addr:Address>
            <addr:Street>123 Main St</addr:Street>
            <addr:City>New York</addr:City>
        </addr:Address>
    </cust:Customer>
    <cust:Customer id="C002">
        <cust:Name>Jane Smith</cust:Name>
        <addr:Address>
            <addr:Street>456 Oak Ave</addr:Street>
            <addr:City>Los Angeles</addr:City>
        </addr:Address>
    </cust:Customer>
</root>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:cust="http://customer.example.com"
      xmlns:addr="http://address.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/root/cust:Customer', 3)
WITH (
    id varchar(10),
    Name varchar(50),
    Street varchar(100),
    City varchar(50)
);

EXEC sp_xml_removedocument @handle;
GO

--test13
DECLARE @xml nvarchar(2000) = '
<root xmlns:inv="http://invoice.example.com">
    <inv:Invoice number="INV001" type="Standard">
        <inv:Details>
            <inv:Amount>1000.00</inv:Amount>
            <inv:Tax>100.00</inv:Tax>
            <inv:Total>1100.00</inv:Total>
        </inv:Details>
    </inv:Invoice>
    <inv:Invoice number="INV002" type="Express">
        <inv:Details>
            <inv:Amount>2000.00</inv:Amount>
            <inv:Tax>200.00</inv:Tax>
            <inv:Total>2200.00</inv:Total>
        </inv:Details>
    </inv:Invoice>
</root>';

DECLARE @namespace nvarchar(200) = '
<root xmlns:inv="http://invoice.example.com" />';

DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;

SELECT * FROM OPENXML(@handle, '/root/inv:Invoice', 3)
WITH (
    number varchar(10),
    type varchar(20),
    Amount decimal(10,2),
    Tax decimal(10,2),
    Total decimal(10,2)
);

EXEC sp_xml_removedocument @handle;
GO