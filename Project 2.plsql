/* Formatted on 4/4/2023 2:24:42 PM (QP5 v5.139.911.3011) */
/*
                     HELPER FUNCTIONS
As the magician uses a special tool kit to assist him in doing his tricks 
a programmer needs a set of helper functions to help him do magic.
Every function will have its decent docstring just use the describe 
function to visualize what it does (But not how it does it -Abstraction-).

The two projects will be achieved using functional programming (easy breezy).

Every function is tested (unit testing) you don't have to bother making 
sure that every function (unit) do what it is supposed to do it is a black box
just have a peak on the labels.
*/

CREATE OR REPLACE FUNCTION GET_INTERVAL(PERIOD VARCHAR2)
RETURN NUMBER
--=============================================
-- Parameters:
--  @period:   Whether it will be paid every year, month, or whatever
-- Returns:     Every how many months should the installment be paid
--  DESCRIPTION
--This function takes in the paying method and return every how many
--months should the installment be paid.
-- =============================================
IS
   --Every how many months should the installment be paid
   interval_ number(2);
BEGIN
   --Get the intervals between each payment 
   IF PERIOD = 'ANNUAL' THEN
        interval_ := 12;
   ELSIF PERIOD = 'HALF_ANNUAL' THEN
        interval_ := 6;
   ELSIF PERIOD = 'QUARTER' THEN
        interval_ := 3;
   ELSIF PERIOD = 'MONTHLY' THEN
        interval_ := 1;        
   ELSE 
        raise_application_error(-20001, 'Invalid Paying Method!!');     
   END IF; 
   
   RETURN INTERVAL_;

END;
--Assure everything is done as expected
SHOW ERROR;
                    --------------------------------------------------
CREATE OR REPLACE FUNCTION GET_INSTALLMENT (START_DATE    DATE,
                                            END_DATE      DATE,
                                            PERIOD        VARCHAR2,
                                            AMOUNT        NUMBER,
                                            INTERVAL_ OUT NUMBER,
                                            INSTALLMENTS OUT NUMBER)
   RETURN NUMBER
--=============================================
-- Parameters:
--   @start_date  IN: The date when the installments will start
--   @end_date  IN:  The date of the last payment
--   @period  IN:       Whether it will be paid every year, month, or whatever
--   @amount  IN:      The total amount to be paid
--   @interval_ OUT:   intervals between each payment
--   @installments OUT: the number of installments to be paid
-- Returns:                MONEY TO BE PAID FOR EACH INSTALLMENT
--  DESCRIPTION
--This function takes in the data of a contract and gets the data of the 
--installments that should be paid for this contract
-- =============================================

IS
   --For how many months the installments will be paid 
   months    NUMBER (3);
   --The output showing the amount to be paid for each installments
   payment   NUMBER (8, 2);
BEGIN   
    --Get the number of installments to be paid
    
   --How many months are there in the paying period
   months := MONTHS_BETWEEN (end_date, start_date);
   --Get the intervals between each payment 
   interval_ := get_interval(period); 
   
    --Get the number of installments to be paid
    installments := trunc(months / interval_);
    
   --Get the payment to be paid for every installment

   --Total divided by number of installments
   payment := amount / installments;
   RETURN payment;
END;
--Assure everything is done as expected
SHOW ERROR;
                    -------------------------------------

CREATE OR REPLACE PROCEDURE POPULATE (P_CONTRACT_ID NUMBER)
--=============================================
-- Parameters:
--   @p_contract_id IN: The ID of the contract to get installments for

--  DESCRIPTION
--This procedure takes in an ID of a contract and start getting the installments
--data for that contract and insert that data into the table.
-- =============================================
IS
   --The money to be paid for each installment
   PAYMENT        NUMBER (8, 2);
   --The current contract we are dealing with
   CONTRACT       CONTRACTS%ROWTYPE;
   --intervals between each payment
   interval_      NUMBER (3);
   --The number of installments to be paid
   installments   NUMBER (3);
   --The due day for each installment
   due_date       DATE;
BEGIN
   --Get the data for the current contract
   SELECT *
     INTO contract
     FROM contracts
    WHERE contract_id = p_contract_id;

   --Get the payment data for the current contract
   payment :=
      get_installment (
         start_date     => contract.contract_startdate,
         end_date       => contract.contract_enddate,
         period         => contract.contract_payment_type,
         amount         => (contract.contract_total_fees
                            - NVL (contract.contract_deposit_fees, 0)),
         interval_      => interval_,
         installments   => installments);
   --As the first installment will be paid at the start date so we need to 
   --Subtract an interval from the start date.
   due_date := add_months(contract.contract_startdate, - interval_);

   --Loop over each installment
   FOR i IN 1 .. installments
   LOOP
      --Get the due date for the current installment
      due_date := ADD_MONTHS (due_date, interval_);

      --Insert the data into the table
      INSERT INTO installments_paid
      (CONTRACT_ID,INSTALLMENT_DATE,  INSTALLMENT_AMOUNT, PAID)
           VALUES (
                   contract.contract_id,
                   due_date,
                   payment,
                   1);
   END LOOP;
END;
--Assure everything is done as expected

SHOW ERROR;
---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE DO_MAGIC
--=============================================
-- Parameters:
--   
--  DESCRIPTION
--This procedure does what is supposed to be in the annonymous 
--block but I am not a fan of that
-- =============================================
IS
   --All the contracts in the contracts table
   CURSOR CONTRACTS
   IS
      SELECT CONTRACT_ID FROM CONTRACTS;
BEGIN
   --For every contract populate its installments
   FOR CONTRACT IN CONTRACTS
   LOOP
      POPULATE (CONTRACT.CONTRACT_ID);
   END LOOP;
END;
--Assure everything is done as expected
SHOW ERROR;
-------------------------------------------------------------------------
BEGIN
   DO_MAGIC;
END;

