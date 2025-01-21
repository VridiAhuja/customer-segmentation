USE CustomerSegmentation; -- Switch to your database
GO
CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1), -- Auto-incrementing transaction ID
    CustomerID INT,                             -- Links to Customers table
    TransactionDate DATE,                       -- Date of transaction
    Amount FLOAT,                               -- Amount spent in transaction
    FOREIGN KEY (CustomerID) REFERENCES Customers(id) -- Links to Customers table
);
INSERT INTO Transactions (CustomerID, TransactionDate, Amount)
VALUES
    (1, '2024-01-01', 120.50),
    (1, '2024-01-10', 250.00),
    (2, '2024-01-15', 340.75),
    (3, '2024-01-20', 50.00),
    (3, '2024-01-25', 100.25),
    (4, '2024-01-30', 80.00),
    (4, '2024-02-01', 180.50),
    (5, '2024-02-05', 60.00),
    (5, '2024-02-10', 90.00),
    (6, '2024-02-15', 150.75);
SELECT * FROM Transactions;
CREATE TABLE RFM_calculations(CustomerID INT PRIMARY KEY,
RECENCY INT, FREQUENCY INT, MONETARY FLOAT,
FOREIGN KEY (CustomerID) REFERENCES Customers(id));
INSERT INTO RFM_calculations(CustomerID, RECENCY, FREQUENCY, MONETARY)
SELECT
    CustomerID,
    DATEDIFF(DAY, MAX(TransactionDate), GETDATE()) AS Recency,
    COUNT(TransactionID) AS Frequency,
    SUM(Amount) AS Monetary
FROM Transactions
GROUP BY CustomerID;
SELECT*FROM RFM_calculations
--Assigning RFM scores using manual bucketing method
ALTER TABLE RFM_calculations
ADD Recency_score INT,
    Frequency_score INT,
	Monetary_score INT;
UPDATE RFM_calculations
SET
	Recency_score = CASE
	                   WHEN Recency<=100 THEN 5
		               WHEN Recency<=200 THEN 4
		               WHEN Recency<=300 THEN 3
		               WHEN Recency<=400 THEN 2
		               ELSE 1
                    END,
                    
   Frequency_score = CASE
                        WHEN FREQUENCY>=5 THEN 5
	                    WHEN FREQUENCY=4 THEN 4
	                    WHEN FREQUENCY=3 THEN 3
	                    WHEN FREQUENCY=2 THEN 2
	                    ELSE 1
                     END,
  Monetary_score = CASE
	                   WHEN Monetary>=500 THEN 5
	                   WHEN Monetary>=400 THEN 4
	                   WHEN Monetary>=300 THEN 3
	                   WHEN Monetary>=200 THEN 2
	                   ELSE 1
	               END;
ALTER TABLE RFM_calculations
ADD RFM_SCORE AS(
        CAST(Recency_score AS VARCHAR(1)) +
		CAST(Frequency_score AS VARCHAR(1)) +
		CAST(Monetary_score AS VARCHAR(1)));
SELECT*FROM RFM_calculations;
ALTER TABLE RFM_calculations
ADD customer_segments VARCHAR(25);
UPDATE RFM_calculations
SET
  customer_segments = CASE
                        WHEN RFM_SCORE IN ('555', '554', '543') THEN 'Best Customers'
                        WHEN RFM_SCORE BETWEEN '443' AND '554' THEN 'Loyal Customers'
                        WHEN RFM_SCORE BETWEEN '222' AND '442' THEN 'Potential Customers'
                        WHEN RFM_SCORE BETWEEN '111' AND '221' THEN 'At Risk'
                        ELSE 'Lost Customers'
				     END;
SELECT*FROM RFM_calculations;
ALTER TABLE RFM_calculations
DROP COLUMN customer_segment;
SELECT*FROM RFM_calculations;
CREATE INDEX idx_customer_segments 
ON RFM_calculations (customer_segments);
--loop to generate multiple transactions programmatically
-- Drop the existing procedure if it exists (must be the first statement)
DROP PROCEDURE IF EXISTS UpdateRFMCalculations;
GO

CREATE PROCEDURE UpdateRFMCalculations
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate percentiles and update scores
    WITH AggregatedData AS (
        SELECT 
            T.CustomerID,
            DATEDIFF(DAY, MAX(T.TransactionDate), GETDATE()) AS RECENCY, 
            COUNT(*) AS FREQUENCY,
            SUM(T.Amount) AS MONETARY
        FROM dbo.Transactions T
        GROUP BY T.CustomerID
    ),
    Percentiles AS (
        SELECT 
            PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY RECENCY) 
                OVER () AS Recency20,
            PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY RECENCY) 
                OVER () AS Recency40,
            PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY RECENCY) 
                OVER () AS Recency60,
            PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY RECENCY) 
                OVER () AS Recency80,

            PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY FREQUENCY) 
                OVER () AS Frequency20,
            PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY FREQUENCY) 
                OVER () AS Frequency40,
            PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY FREQUENCY) 
                OVER () AS Frequency60,
            PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY FREQUENCY) 
                OVER () AS Frequency80,

            PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY MONETARY) 
                OVER () AS Monetary20,
            PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY MONETARY) 
                OVER () AS Monetary40,
            PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY MONETARY) 
                OVER () AS Monetary60,
            PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY MONETARY) 
                OVER () AS Monetary80
        FROM AggregatedData
    )

    UPDATE R
    SET 
        R.RECENCY = A.RECENCY,
        R.FREQUENCY = A.FREQUENCY,
        R.MONETARY = A.MONETARY,

        -- Correct percentile-based scoring using the Percentiles CTE
        R.Recency_score = CASE 
                            WHEN A.RECENCY <= P.Recency20 THEN 5
                            WHEN A.RECENCY <= P.Recency40 THEN 4
                            WHEN A.RECENCY <= P.Recency60 THEN 3
                            WHEN A.RECENCY <= P.Recency80 THEN 2
                            ELSE 1
                          END,

        R.Frequency_score = CASE 
                            WHEN A.FREQUENCY >= P.Frequency80 THEN 5
                            WHEN A.FREQUENCY >= P.Frequency60 THEN 4
                            WHEN A.FREQUENCY >= P.Frequency40 THEN 3
                            WHEN A.FREQUENCY >= P.Frequency20 THEN 2
                            ELSE 1
                          END,

        R.Monetary_score = CASE 
                            WHEN A.MONETARY >= P.Monetary80 THEN 5
                            WHEN A.MONETARY >= P.Monetary60 THEN 4
                            WHEN A.MONETARY >= P.Monetary40 THEN 3
                            WHEN A.MONETARY >= P.Monetary20 THEN 2
                            ELSE 1
                          END
    FROM RFM_calculations R
    JOIN AggregatedData A ON R.CustomerID = A.CustomerID
    CROSS JOIN Percentiles P;

    -- Drop and Recalculate RFM_SCORE as an integer-based score
    ALTER TABLE RFM_calculations
    DROP COLUMN IF EXISTS RFM_SCORE;

    ALTER TABLE RFM_calculations
    ADD RFM_SCORE AS (
        CAST(Recency_score AS VARCHAR(1)) + 
        CAST(Frequency_score AS VARCHAR(1)) + 
        CAST(Monetary_score AS VARCHAR(1))
    );

    -- Update customer segments based on corrected RFM_SCORE
    UPDATE RFM_calculations
    SET customer_segments = CASE 
        WHEN CAST(RFM_SCORE AS INT) IN (555, 554, 543) THEN 'Best Customers'
        WHEN CAST(RFM_SCORE AS INT) BETWEEN 443 AND 554 THEN 'Loyal Customers'
        WHEN CAST(RFM_SCORE AS INT) BETWEEN 222 AND 442 THEN 'Potential Customers'
        WHEN CAST(RFM_SCORE AS INT) BETWEEN 111 AND 221 THEN 'At Risk'
        ELSE 'Lost Customers'
    END;
END;
GO

-- Execute the corrected procedure
EXEC UpdateRFMCalculations;
SELECT * FROM RFM_calculations;

SELECT COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM dbo.Transactions;
SELECT*FROM RFM_calculations;