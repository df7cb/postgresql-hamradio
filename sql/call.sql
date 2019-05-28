SELECT 'DF7CB'::call;
SELECT 'DF7CB/P'::call;
SELECT 'F/DF7CB/P'::call;
SELECT 'DE-1234'::call; -- SWL

-- errors
SELECT 'df7cb'::call;
SELECT 'DE 1234'::call;
