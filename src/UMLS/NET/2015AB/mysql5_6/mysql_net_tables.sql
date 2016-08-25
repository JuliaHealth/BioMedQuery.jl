DROP TABLE IF EXISTS SRDEF;
CREATE TABLE SRDEF (
	RT	VARCHAR (3) BINARY NOT NULL,
	UI	CHAR (4) BINARY NOT NULL,
	STY_RL	VARCHAR (41) BINARY NOT NULL,
	STN_RTN	VARCHAR (14) BINARY NOT NULL,
	DEF	TEXT	NOT NULL,
	EX	VARCHAR (185) BINARY,
	UN	TEXT,
	NH	VARCHAR (1) BINARY,
	ABR	VARCHAR (4) BINARY NOT NULL,
	RIN	VARCHAR (23) BINARY
) CHARACTER SET utf8;

load data infile 'SRDEF' into table SRDEF fields terminated by '|' ESCAPED BY '' lines terminated by '\n'
(@rt, @ui, @sty_rl, @stn_rtn, @def, @ex, @un, @nh, @abr, @rin)
SET RT = @rt,
UI = @ui,
STY_RL = @sty_rl,
STN_RTN = @stn_rtn,
DEF = @def,
EX = NULLIF(@ex,''),
UN = NULLIF(@un,''),
NH = NULLIF(@nh,''),
ABR = @abr,
RIN = NULLIF(@rin,'');


DROP TABLE IF EXISTS SRFIL;
CREATE TABLE SRFIL (
	FIL	VARCHAR (7) BINARY NOT NULL,
	DES	VARCHAR (56) BINARY NOT NULL,
	FMT	VARCHAR (41) BINARY NOT NULL,
	CLS	VARCHAR (2) BINARY NOT NULL,
	RWS	VARCHAR (4) BINARY NOT NULL,
	BTS	VARCHAR (6) BINARY NOT NULL
) CHARACTER SET utf8;

load data infile 'SRFIL' into table SRFIL fields terminated by '|' ESCAPED BY '' lines terminated by '\n';


DROP TABLE IF EXISTS SRFLD;
CREATE TABLE SRFLD (
	COL	VARCHAR (3) BINARY NOT NULL,
	DES	VARCHAR (32) BINARY NOT NULL,
	REF	VARCHAR (3) BINARY NOT NULL,
	FIL	VARCHAR (19) BINARY NOT NULL
) CHARACTER SET utf8;

load data infile 'SRFLD' into table SRFLD fields terminated by '|' ESCAPED BY '' lines terminated by '\n';


DROP TABLE IF EXISTS SRSTR;
CREATE TABLE SRSTR (
	STY_RL1	VARCHAR (41) BINARY NOT NULL,
	RL	VARCHAR (23) BINARY NOT NULL,
	STY_RL2	VARCHAR (39) BINARY,
	LS	VARCHAR (3) BINARY NOT NULL
) CHARACTER SET utf8;

load data infile 'SRSTR' into table SRSTR fields terminated by '|' ESCAPED BY '' lines terminated by '\n'
(@sty_rl1, @rl, @sty_rl2, @ls)
SET STY_RL1 = @sty_rl1,
RL = @rl,
STY_RL2 = NULLIF(@sty_rl2,''),
LS = @ls;

DROP TABLE IF EXISTS SRSTRE1;
CREATE TABLE SRSTRE1 (
	UI1	CHAR (4) BINARY NOT NULL,
	UI2	CHAR (4) BINARY NOT NULL,
	UI3	CHAR (4) BINARY NOT NULL
) CHARACTER SET utf8;

load data infile 'SRSTRE1' into table SRSTRE1 fields terminated by '|' ESCAPED BY '' lines terminated by '\n';


DROP TABLE IF EXISTS SRSTRE2;
CREATE TABLE SRSTRE2 (
	STY1	VARCHAR (41) BINARY NOT NULL,
	RL	VARCHAR (23) BINARY NOT NULL,
	STY2	VARCHAR (41) BINARY NOT NULL
) CHARACTER SET utf8;

load data infile 'SRSTRE2' into table SRSTRE2 fields terminated by '|' ESCAPED BY '' lines terminated by '\n';
