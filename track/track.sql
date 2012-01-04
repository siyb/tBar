CREATE TABLE widget (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	type TEXT UNIQUE
);

CREATE TABLE widgetargument (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	argument TEXT UNIQUE
);

CREATE TABLE userwidget (
	uid INTEGER,
	timestamp INTEGER,
	widgetId INTEGER,
	widgetargumentId INTEGER,
	updateinterval INTEGER,
	value TEXT,
	FOREIGN KEY(widgetId) REFERENCES widget(id),
	FOREIGN KEY(widgetargumentId) REFERENCES widgetargument(id)
	CONSTRAINT uc_userwidget UNIQUE (widgetId, widgetargumentId, updateinterval, value, uid)
);

CREATE TABLE error (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	time TEXT,
	hostname TEXT,
	executable TEXT,
	tclversion TEXT,
	osversion TEXT,
	tbarversion TEXT,
	threaded INTEGER,
	machine TEXT,
	errorinfo TEXT,
	errorcode TEXT
);

CREATE TABLE errorconfig (
	errorId,
	key TEXT,
	value TEXT,
	FOREIGN KEY(errorId) REFERENCES error(id)
);

CREATE TABLE errorsysarray (
	errorId,
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sysarray TEXT,
	key TEXT,
	value TEXT,
	FOREIGN KEY(errorId) REFERENCES error(id)
);

