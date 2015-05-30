import x_db_sqlite


# SQL QUERIES

const SQL_CREATE_DOCUMENTS_TABLE* = sql"""
CREATE TABLE documents (
docid INTEGER PRIMARY KEY,
id TEXT UNIQUE NOT NULL,
data TEXT,
content_type TEXT,
binary INTEGER,
searchable INTEGER,
created TEXT,
modified TEXT)
"""
const SQL_CREATE_TAGS_TABLE* = sql"""
CREATE TABLE tags (
namespace TEXT NOT NULL,
predicate TEXT NOT NULL,
value TEXT NOT NULL,
document_id TEXT NOT NULL,
FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE,
PRIMARY KEY (namespace, predicate, value, document_id))
"""

const SQL_CREATE_INFO_TABLE* = sql"""
CREATE TABLE info (
version INT,
total_documents INT)
"""

const SQL_CREATE_SEARCHDATA_TABLE* = sql"""
CREATE VIRTUAL TABLE searchdata USING fts4(
id TEXT UNIQUE NOT NULL,
data TEXT, 
tokenize=porter)
"""

const
  SQL_CREATE_INDEX_DOCUMENTS_DOCID* = sql"CREATE INDEX IF NOT EXISTS documents_docid ON documents(docid)"
  SQL_CREATE_INDEX_DOCUMENTS_ID* = sql"CREATE INDEX IF NOT EXISTS documents_id ON documents(id)"
  SQL_CREATE_INDEX_TAGS_DOCUMENT_ID* = sql"CREATE INDEX IF NOT EXISTS tags_document_id ON tags(document_id)"
  SQL_CREATE_INDEX_TAGS_NAMESPACE* = sql"CREATE INDEX IF NOT EXISTS tags_namespace ON tags(namespace)"
  SQL_CREATE_INDEX_TAGS_PREDICATE* = sql"CREATE INDEX IF NOT EXISTS tags_predicate ON tags(predicate)"
  SQL_CREATE_INDEX_TAGS_VALUE* = sql"CREATE INDEX IF NOT EXISTS tags_value ON tags(value)"

  SQL_DROP_INDEX_DOCUMENTS_DOCID* = sql"DROP INDEX IF EXISTS documents_docid" 
  SQL_DROP_INDEX_DOCUMENTS_ID* = sql"DROP INDEX IF EXISTS documents_id"
  SQL_DROP_INDEX_TAGS_DOCUMENT_ID* = sql"DROP INDEX IF EXISTS tags_document_id"
  SQL_DROP_INDEX_TAGS_NAMESPACE* = sql"DROP INDEX IF EXISTS tags_namespace"
  SQL_DROP_INDEX_TAGS_PREDICATE* = sql"DROP INDEX IF EXISTS tags_predicate"
  SQL_DROP_INDEX_TAGS_VALUE* = sql"DROP INDEX IF EXISTS tags_value"
  
  SQL_REINDEX* = sql"REINDEX"
  SQL_OPTIMIZE* = sql"INSERT INTO searchdata(searchdata) VALUES('optimize')"
  SQL_REBUILD* = sql"INSERT INTO searchdata(searchdata) VALUES('rebuild')"
  
  SQL_VACUUM* = sql"VACUUM"

const SQL_INSERT_INFO* = sql"""
INSERT INTO info
(version, total_documents)
VALUES (?, ?)
"""

const SQL_SELECT_INFO* = sql"""
SELECT * FROM info
"""

const SQL_INCREMENT_DOCS* = sql"""
UPDATE info
SET total_documents = total_documents + 1
"""

const SQL_DECREMENT_DOCS* = sql"""
UPDATE info
SET total_documents = total_documents - 1
"""

const SQL_INSERT_DOCUMENT* = sql"""
INSERT INTO documents
(id, data, content_type, binary, searchable, created)
VALUES (?, ?, ?, ?, ?, ?)
"""

const SQL_UPDATE_DOCUMENT* = sql"""
UPDATE documents
SET data = ?,
content_type = ?,
binary = ?,
searchable = ?,
modified = ?
WHERE id = ?
"""

const SQL_SET_DOCUMENT_MODIFIED* = sql"""
UPDATE documents
SET modified = ?
WHERE id = ?
"""

const SQL_DELETE_DOCUMENT* = sql"""
DELETE FROM documents
WHERE id = ? 
"""

const SQL_INSERT_TAG* = sql"""
INSERT INTO tags
(document_id, value, predicate, namespace)
VALUES (?, ?, ?, ?)
"""

const SQL_DELETE_DOCUMENT_TAGS* = sql"""
DELETE FROM tags
WHERE document_id = ?
"""

const SQL_SELECT_DOCUMENT_TAGS* = sql"""
SELECT * FROM tags
WHERE document_id = ?
"""

const SQL_DELETE_DOCUMENT_SYSTEM_TAGS* = sql"""
DELETE FROM tags WHERE
document_id = ? AND namespace = "sys"
"""

const SQL_INSERT_SEARCHCONTENT* = sql"""
INSERT INTO searchdata
(docid, id, data)
VALUES (?, ?, ?)
"""

const SQL_DELETE_SEARCHCONTENT* = sql"""
DELETE FROM searchdata WHERE
id = ?
"""

const SQL_UPDATE_SEARCHCONTENT* = sql"""
UPDATE searchdata
SET data = ?
WHERE id = ?
"""

const SQL_SELECT_TAGS_WITH_TOTALS* = sql"""
SELECT DISTINCT namespace, predicate, value, COUNT(document_id) 
FROM tags GROUP BY namespace, predicate, value ORDER BY namespace, predicate, value
"""

const SQL_COUNT_TAGS* = sql"""
SELECT COUNT(DISTINCT namespace, predicate, value) FROM tags 
"""

const SQL_COUNT_DOCUMENTS* = sql"""
SELECT COUNT(docid) FROM documents 
"""
