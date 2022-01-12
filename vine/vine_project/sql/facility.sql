.headers on
.mode csv
.once /tmp/facility.csv
select * from facility order by name;
