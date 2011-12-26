CREATE TABLE widget (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	type TEXT,
	updateinterval INTEGER
);

CREATE TABLE widgetargument (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	argument TEXT
);

CREATE TABLE widget_widgetargument (
	widgetId INTEGER,
	widgetargumentID INTEGER,
	value TEXT,
	FOREIGN KEY(widgetId) REFERENCES widget(id),
	FOREIGN KEY(widgetargumentId) REFERENCES widgetargument(id)
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

CREATE TABLE widgetsysarray (
	errorId,
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	sysarray TEXT,
	key TEXT,
	value TEXT,
	FOREIGN KEY(errorId) REFERENCES error(id)
);
