.headers on
.mode csv
.once /tmp/m1.csv
select IID, mdate from names order by IID;

