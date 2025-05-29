-- Active: 1747806667802@@127.0.0.1@3306@classicmodels

-- Show all the customers whose creditLimit is greater than 20000
SELECT * FROM customers WHERE `creditLimit` > 20000;


--Show the employees who report to VP Sales.
-- SELECT emp.*, rep.`firstName`, rep.`lastName`, rep.`jobTitle`
SELECT emp.*
FROM employees emp
JOIN employees rep
ON emp.`reportsTo` = rep.`employeeNumber`
WHERE rep.`jobTitle` = "VP Sales"


-- 3. Find all the customers who have set their state while filling the forms and Lives in USA
-- and credit limit is between 100000 and 200000.

SELECT *
FROM customers
WHERE
state IS NOT NULL
AND country = "USA"
AND `creditLimit` > 100000
AND `creditLimit` < 200000;



--  4. Find all the employees who report to Sales Managers of all types.
SELECT emp.*
FROM employees emp
JOIN employees rep
ON emp.`reportsTo` = rep.`employeeNumber`
WHERE rep.`jobTitle` LIKE "Sales Manager%"
OR rep.`jobTitle` LIKE "Sale Manager*";



-- 5. Find the average credit limit of customers of each country.
SELECT country, AVG(`creditLimit`) as avgCreditLimit
FROM customers
GROUP BY country


-- 6. Find the total no. of orders for each date and customer. Show only dates with total
-- number of orders greater than 10 for date and customer.
SELECT orderDate, customerNumber, COUNT(orderNumber) AS totalOrders
FROM orders
GROUP BY orderDate, customerNumber
HAVING totalOrders > 10;


-- 7. Find the name of the supervisor, job title of supervisor and total no. of supervisee using
--subquery. (With out using Join operation)

SELECT
    (SELECT firstName FROM employees WHERE employeeNumber = e.reportsTo) AS supervisorFirstName,
    (SELECT lastName FROM employees WHERE employeeNumber = e.reportsTo) AS supervisorLastName,
    (SELECT jobTitle FROM employees WHERE employeeNumber = e.reportsTo) AS supervisorJobTitle,
    COUNT(e.employeeNumber) AS totalSupervisee
FROM employees AS e
WHERE e.reportsTo IS NOT NULL
GROUP BY e.reportsTo;


-- 8. Find the name of the supervisor, job title of supervisor and total no. of supervisee using
--subquery. (With using Join operation)
SELECT manager.firstName AS supervisorFirstName, manager.lastName AS supervisorLastName, manager.jobTitle AS supervisorJobTitle, supervisee_counts.totalSupervisee
FROM employees AS manager
JOIN (
    SELECT reportsTo, COUNT(employeeNumber) AS totalSupervisee
    FROM employees
    WHERE reportsTo IS NOT NULL
    GROUP BY reportsTo
) AS supervisee_counts
ON manager.employeeNumber = supervisee_counts.reportsTo;



-- 9: Find all customers with a credit limit greater than average credit credit limit using WITH Clause.
WITH AverageCredit AS (
    SELECT AVG(creditLimit) AS avgCreditLimit
    FROM customers
)
SELECT c.customerName, c.creditLimit
FROM customers AS c, AverageCredit AS ac
WHERE c.creditLimit > ac.avgCreditLimit;



-- 10: Find the rank of customer. [Customer with highest credit limit have 1 rank and Customer with lowest credit limit have highest rank]. Then, find the customer with the third highest credit limit.
SELECT customerName, creditLimit, DENSE_RANK() OVER (ORDER BY creditLimit DESC) AS customerRank
FROM customers
ORDER BY customerRank;

-- Customer with the third highest credit limit
SELECT customerName, creditLimit
FROM (
    SELECT customerName, creditLimit, DENSE_RANK() OVER (ORDER BY creditLimit DESC) AS customerRank
    FROM customers
) AS ranked_customers
WHERE customerRank = 3;



-- 11: Generate a report that shows total no. of employees working in each office.
SELECT offices.`officeCode`, offices.city, offices.country, COUNT(employees.`officeCode`) AS employeeCount
FROM employees
JOIN offices
ON employees.`officeCode` = offices.`officeCode`
GROUP BY offices.`officeCode`, offices.city, offices.country;


-- 12: Generate a report that shows total no. of customers visited each office.
-- Assuming 'visited each office' means customers associated with a sales representative from that office.
SELECT offices.`officeCode`, offices.city, offices.country, COUNT(customers.`customerNumber`) as noOfCustomersVisited
FROM customers
JOIN employees
ON customers.`salesRepEmployeeNumber` = employees.`employeeNumber`
JOIN offices
ON employees.`officeCode` = offices.`officeCode`
GROUP BY offices.`officeCode`, offices.city, offices.country;



-- 13: Generate a report that shows total payment received by each office using payment tables and essential tables. The report should show the office name, state and country, along with total payments made.
SELECT offices.`officeCode`, offices.state, offices.country, SUM(payments.amount) as totalPayments
FROM customers
JOIN employees
ON customers.`salesRepEmployeeNumber` = employees.`employeeNumber`
JOIN offices
ON employees.`officeCode` = offices.`officeCode`
JOIN payments
ON customers.`customerNumber` = payments.`customerNumber`
GROUP BY offices.`officeCode`, offices.city, offices.country;



-- 14.​Generate a report that shows total sales(in amount) by each office using order details
--table and other essential tables.
SELECT offices.`officeCode`, offices.state, offices.country, SUM(orderdetails.`quantityOrdered` * orderdetails.`priceEach`) as totalSales
FROM customers
JOIN employees
ON customers.`salesRepEmployeeNumber` = employees.`employeeNumber`
JOIN offices
ON employees.`officeCode` = offices.`officeCode`
JOIN orders
ON orders.`customerNumber` = customers.`customerNumber`
JOIN orderdetails
ON orderdetails.`orderNumber` = orders.`orderNumber`
GROUP BY offices.`officeCode`, offices.city, offices.country;



-- 15. Generate a report that shows total payment pending for each office.
SELECT offices.`officeCode`, SUM(orderdetails.`quantityOrdered` * orderdetails.`priceEach`) as pendingPayment
FROM customers
JOIN employees
ON customers.`salesRepEmployeeNumber` = employees.`employeeNumber`
JOIN offices
ON employees.`officeCode` = offices.`officeCode`
JOIN orders
ON orders.`customerNumber` = customers.`customerNumber`
JOIN orderdetails
ON orderdetails.`orderNumber` = orders.`orderNumber`
WHERE orders.status IN ("On Hold", "Disputed", "In Process")
GROUP BY offices.`officeCode`
ORDER BY offices.`officeCode`;



-- Find the creditLimit of each person, proportion of creditLimit of each person in each
--country. [Proportion of person in USA = creditLimit of that person / sum(creditLimit of all
--person in USA]

-- Proportion
SELECT `customerNumber`, `customerName`, `creditLimit`,
CASE 
    WHEN totalCreditLimit = 0 THEN 0
    ELSE `creditLimit`/totalCreditLimit
END AS proportion
FROM customers
JOIN
(
    SELECT country, SUM(`creditLimit`) AS totalCreditLimit
    FROM customers
    GROUP BY country
    -- HAVING totalCreditLimit > 0
) AS countryCreditLimit
ON customers.country = countryCreditLimit.country;



-- 17. Create a view showing the customer name, complete address, and their total number of
--orders.
CREATE VIEW customerInfo AS
SELECT customers.`customerNumber`, customers.`customerName`, customers.`addressLine1`, customers.city, customers.country, orderCount.totalOrders AS totalOrders
FROM customers
JOIN 
(
    SELECT customers.`customerNumber`, COUNT(orders.`orderNumber`) AS totalOrders
    FROM customers
    JOIN orders
    ON orders.`customerNumber`=customers.`customerNumber`
    GROUP BY customers.`customerNumber`
) AS orderCount
ON orderCount.customerNumber = customers.`customerNumber`;




-- 18. Update the country of a customer (use any one record).
UPDATE customers
SET country = 'Nepal'
WHERE customerNumber = 103;


-- 19.​Delete all payments below 20,000.
DELETE FROM payments
WHERE amount < 20000;



-- 20.Add new payments manually for an existing customer.
INSERT INTO payments (customerNumber, checkNumber, paymentDate, amount)
VALUES (103, 'ABCNEPAL', CURDATE(), 25000.00);