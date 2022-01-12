.headers on
.mode csv
.once /mnt/c/Users/jozef/Documents/S_report.csv
select f.name,n.name,n.IID,n.status from names n join facility f on (n.facility = f.id ) 
 order by f.name,n.name;
