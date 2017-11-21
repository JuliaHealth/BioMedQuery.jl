CREATE TABLE IF NOT EXISTS article(
    pmid INTEGER NOT NULL PRIMARY KEY,
    title TEXT,
    pubYear INTEGER,
    abstract TEXT
);


CREATE TABLE IF NOT EXISTS author(
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    forename VARCHAR(255),
    lastname VARCHAR(255) NOT NULL,
    CONSTRAINT unq UNIQUE(forename,  lastname)
);

CREATE TABLE IF NOT EXISTS author2article(
    aid INTEGER,
    pmid INTEGER,
    FOREIGN KEY(aid) REFERENCES author(id),
    FOREIGN KEY(pmid) REFERENCES article(pmid),
    PRIMARY KEY(aid, pmid)
);

-- --------------------------
--  MeshHeading Tables
-- --------------------------
--
-- Descriptor
-- The id corresponds to the DUI of mesh library
-- Adding a "D" at the beginning of the id, allows for
-- lookup in the mesh browerser
--  https://www.nlm.nih.gov/mesh/MBrowser.html

CREATE TABLE IF NOT EXISTS mesh_descriptor(
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(255) UNIQUE
);

-- Qualifier
CREATE TABLE IF NOT EXISTS mesh_qualifier(
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(255) UNIQUE
);

-- Heading
CREATE TABLE IF NOT EXISTS mesh_heading(
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    pmid INTEGER, did INTEGER, qid INTEGER,
    dmjr VARCHAR(1), qmjr VARCHAR(1),
    FOREIGN KEY(pmid) REFERENCES article(pmid),
    FOREIGN KEY(did) REFERENCES mesh_descriptor(id),
    FOREIGN KEY(qid) REFERENCES mesh_qualifier(id),
    CONSTRAINT unq UNIQUE(pmid, did, qid)
);
