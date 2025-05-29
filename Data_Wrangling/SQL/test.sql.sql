

--1.​ Show all the customers whose creditLimit is greater than 20000
SELECT * FROM customers
WHERE creditLimit > 20000;


--2.​ Show the employees who report to VP Sales.
SELECT * FROM employees
WHERE reportsTo = (
  SELECT employeeNumber FROM employees
  WHERE jobTitle = 'VP Sales'
);


--3.​ Find all the customers who have set their state while filling the forms and Lives in USA and credit limit is between 100000 and 200000.
SELECT * FROM customers
WHERE state IS NOT NULL AND country = 'USA'
AND creditLimit BETWEEN 100000 AND 200000;


--4.​ Find all the employees who report to Sales Managers of all types.
SELECT * FROM employees
WHERE reportsTo IN (
  SELECT employeeNumber FROM employees
  WHERE jobTitle LIKE '%Sales Manager%'
);


--5.​ Find the average credit limit of customers of each country.
SELECT country, AVG(creditLimit) AS avg_creditLimit
FROM customers
GROUP BY country;


--6.​ Find the total no. of orders for each date and customer. Show only dates with total number of orders greater than 10 for date and customer.
SELECT orderDate, customerNumber, COUNT(*) AS totalOrders
FROM orders
GROUP BY orderDate, customerNumber
HAVING COUNT(*) > 10;


--7. Find the name of the supervisor, job title of supervisor and total no. of supervisee using subquery. (With out using Join operation)
SELECT 
  (SELECT e1.firstName FROM employees e1 WHERE e1.employeeNumber = e.reportsTo) AS supervisorName,
  (SELECT e1.jobTitle FROM employees e1 WHERE e1.employeeNumber = e.reportsTo) AS supervisorTitle,
  COUNT(*) AS totalSupervisees
FROM employees e
WHERE e.reportsTo IS NOT NULL
GROUP BY e.reportsTo;


--8. Find the name of the supervisor, job title of supervisor and total no. of supervisee using subquery. (With using Join operation)
SELECT 
  sup.firstName AS supervisorName,
  sup.jobTitle AS supervisorTitle,
  COUNT(emp.employeeNumber) AS totalSupervisees
FROM employees emp
JOIN employees sup ON emp.reportsTo = sup.employeeNumber
GROUP BY emp.reportsTo;


--9.​ Find all customers with a credit limit greater than average credit credit limit using WITHClause.
WITH avgCredit AS (
  SELECT AVG(creditLimit) AS avgLimit FROM customers
)
SELECT * FROM customers
WHERE creditLimit > (SELECT avgLimit FROM avgCredit);


--10.​Find the rank of customer. [Customer with highest credit limit have 1 rank and Customer
--with lowest credit limit have highest rank]. Then, find the customer with the third highest
--credit limit.
WITH ranked_customers AS (
  SELECT
    customerNumber,
    customerName,
    creditLimit,
    RANK() OVER (ORDER BY creditLimit DESC) AS credit_rank
  FROM customers
)
SELECT * FROM ranked_customers
LIMIT 100;


--11.​Generate a report that shows total no. of employees working in each office.
SELECT officeCode, COUNT(*) AS totalEmployees
FROM employees
GROUP BY officeCode;


--12.​Generate a report that shows total no. of customers visited each office.
SELECT salesRepEmployeeNumber, COUNT(*) AS totalCustomers
FROM customers
GROUP BY salesRepEmployeeNumber;


--13.​Generate a report that shows total payment received by each office using payment
--tables and essential tables. The report should show the office name, state and country,
--along with total payments made.
SELECT o.officeCode, o.city, o.state, o.country, SUM(p.amount) AS totalPayments
FROM payments p
JOIN customers c ON p.customerNumber = c.customerNumber
JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
JOIN offices o ON e.officeCode = o.officeCode
GROUP BY o.officeCode;


--14.​Generate a report that shows total sales(in amount) by each office using order details
--table and other essential tables.
SELECT o.officeCode, o.city, o.state, o.country, SUM(od.quantityOrdered * od.priceEach) AS totalSales
FROM orderdetails od
JOIN orders o1 ON od.orderNumber = o1.orderNumber
JOIN customers c ON o1.customerNumber = c.customerNumber
JOIN employees e ON c.salesRepEmployeeNumber = e.employeeNumber
JOIN offices o ON e.officeCode = o.officeCode
GROUP BY o.officeCode;


--15.​Generate a report that shows total payment pending for each office.
WITH order_totals AS (
    SELECT 
        c.customerNumber,
        SUM(od.quantityOrdered * od.priceEach) AS total_order_value
    FROM customers c
    JOIN orders o ON c.customerNumber = o.customerNumber
    JOIN orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY c.customerNumber
),
payment_totals AS (
    SELECT 
        customerNumber,
        SUM(amount) AS total_paid
    FROM payments
    GROUP BY customerNumber
),
customer_balances AS (
    SELECT 
        c.customerNumber,
        c.salesRepEmployeeNumber,
        COALESCE(ot.total_order_value, 0) - COALESCE(pt.total_paid, 0) AS payment_pending
    FROM customers c
    LEFT JOIN order_totals ot ON c.customerNumber = ot.customerNumber
    LEFT JOIN payment_totals pt ON c.customerNumber = pt.customerNumber
)
SELECT 
    o.officeCode,
    o.city,
    o.state,
    o.country,
    SUM(cb.payment_pending) AS payment_pending
FROM offices o
JOIN employees e ON o.officeCode = e.officeCode
JOIN customer_balances cb ON e.employeeNumber = cb.salesRepEmployeeNumber
GROUP BY o.officeCode, o.city, o.state, o.country
ORDER BY payment_pending DESC;




--16.​Find the creditLimit of each person, proportion of creditLimit of each person in each
--country. [Proportion of person in USA = creditLimit of that person / sum(creditLimit of all
--person in USA]
SELECT customerName, country, creditLimit,
       creditLimit / SUM(creditLimit) OVER (PARTITION BY country) AS proportion
FROM customers;


--17.​Create a view showing the customer name, complete address, and their total number of
--orders.
CREATE VIEW customer_order_summary_2 AS
SELECT c.customerName, CONCAT(addressLine1, ', ', city, ', ', state, ', ', country) AS fullAddress,
       COUNT(o.orderNumber) AS totalOrders
FROM customers c
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber;



--18.​Update the country of a customer (use any one record).
SELECT customerNumber, customerName, country 
FROM customers 
WHERE customerNumber = 103;
UPDATE customers 
SET country = 'Canada' 
WHERE customerNumber = 103;
SELECT customerNumber, customerName, country 
FROM customers 
WHERE customerNumber = 103;





CREATE VIEW customer_order_summary AS
SELECT 
    c.customerNumber,
    c.customerName,
    CONCAT(c.addressLine1, 
           CASE WHEN c.addressLine2 IS NOT NULL THEN CONCAT(', ', c.addressLine2) ELSE '' END,
           ', ', c.city,
           CASE WHEN c.state IS NOT NULL THEN CONCAT(', ', c.state) ELSE '' END,
           ', ', c.postalCode,
           ', ', c.country) as complete_address,
    COUNT(o.orderNumber) as total_orders
FROM customers c
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber, c.customerName, complete_address
ORDER BY total_orders DESC; -- example ID


--19.​Delete all payments below 20,000.
SELECT COUNT(*) as payments_to_delete
FROM payments 
WHERE amount < 20000;
SELECT * FROM payments WHERE amount < 20000;
DELETE FROM payments 
WHERE amount < 20000;
SELECT COUNT(*) as remaining_payments
FROM payments;
SELECT COUNT(*) as payments_above_20000
FROM payments 
WHERE amount >= 20000;


--20.​Add new payments manually for an existing customer.
SELECT customerNumber, customerName 
FROM customers 
WHERE customerNumber = 103;
INSERT INTO payments (customerNumber, checkNumber, paymentDate, amount)
VALUES (103, 'CHK001', '2024-01-15', 25000.00);
INSERT INTO payments (customerNumber, checkNumber, paymentDate, amount)
VALUES (103, 'CHK002', '2024-02-15', 30000.00);
SELECT * FROM payments 
WHERE customerNumber = 103 
ORDER BY paymentDate DESC;
