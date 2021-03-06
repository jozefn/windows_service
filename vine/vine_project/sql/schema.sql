CREATE TABLE IF NOT EXISTS "facility" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE IF NOT EXISTS "names" (
	"id"	INTEGER NOT NULL UNIQUE,
	"facility"	INTEGER,
	"name"	TEXT,
	"IID"	TEXT,
	"status"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
