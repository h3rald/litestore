import db_sqlite


# SQL QUERIES

const SQL_CREATE_DOCUMENTS_TABLE* = sql"""
CREATE TABLE documents (
docid INTEGER PRIMARY KEY,
id TEST,
data TEXT,
content_type TEXT,
binary INTEGER,
searchable INTEGER,
created TEXT,
modified TEXT)
"""

const
  SQL_CREATE_INDEX_DOCUMENTS_DOCID* = sql"CREATE INDEX IF NOT EXISTS documents_docid ON documents(docid)"
  SQL_CREATE_INDEX_DOCUMENTS_ID* = sql"CREATE INDEX IF NOT EXISTS documents_id ON documents(id)"
  SQL_CREATE_INDEX_TAGS_DOCUMENT_ID* = sql"CREATE INDEX IF NOT EXISTS tags_document_id ON tags(document_id)"
  SQL_CREATE_INDEX_TAGS_TAG_ID* = sql"CREATE INDEX IF NOT EXISTS tags_tag_id ON tags(tag_id)"

  SQL_DROP_INDEX_DOCUMENTS_DOCID* = sql"DROP INDEX IF EXISTS documents_docid" 
  SQL_DROP_INDEX_DOCUMENTS_ID* = sql"DROP INDEX IF EXISTS documents_id"
  SQL_DROP_INDEX_TAGS_DOCUMENT_ID* = sql"DROP INDEX IF EXISTS tags_document_id"
  SQL_DROP_INDEX_TAGS_TAG_ID* = sql"DROP INDEX IF EXISTS tags_tag_id"
  
  SQL_REINDEX* = sql"REINDEX"
  SQL_OPTIMIZE* = sql"INSERT INTO searchdata(searchdata) VALUES('optimize')"
  SQL_REBUILD* = sql"INSERT INTO searchdata(searchdata) VALUES('rebuild')"
  
  SQL_VACUUM* = sql"VACUUM"

const SQL_CREATE_SEARCHDATA_TABLE* = sql"""
CREATE VIRTUAL TABLE searchdata USING fts5(
id TEXT,
data TEXT, 
tokenize = 'porter unicode61')
"""

const SQL_CREATE_TAGS_TABLE* = sql"""
CREATE TABLE tags (
tag_id TEXT,
document_id TEXT,
PRIMARY KEY (tag_id, document_id))
"""

const SQL_CREATE_INFO_TABLE* = sql"""
CREATE TABLE info (
version INT,
total_documents INT)
"""

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
(tag_id, document_id)
VALUES (?, ?)
"""

const SQL_DELETE_TAG* = sql"""
DELETE FROM tags
WHERE tag_id = ? AND document_id = ?
"""

const SQL_DELETE_DOCUMENT_TAGS* = sql"""
DELETE FROM tags
WHERE document_id = ?
"""

const SQL_SELECT_DOCUMENT_TAGS* = sql"""
SELECT tag_id FROM tags
WHERE document_id = ?
"""

const SQL_DELETE_DOCUMENT_SYSTEM_TAGS* = sql"""
DELETE FROM tags WHERE
document_id = ? AND tag_id LIKE "$%"
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

const SQL_SELECT_DOCUMENTS_BY_TAG* = sql"""
SELECT * FROM documents, tags
WHERE documents.id = tags.document_id AND
tag_id = ?
"""

const SQL_SELECT_DOCUMENT_IDS_BY_TAG* = sql"""
SELECT id FROM documents, tags
WHERE documents.id = tags.document_id AND
tag_id = ?
"""

const SQL_SELECT_TAGS_WITH_TOTALS* = sql"""
SELECT DISTINCT tag_id, COUNT(document_id) 
FROM tags GROUP BY tag_id ORDER BY tag_id ASC
"""

const SQL_COUNT_TAGS* = sql"""
SELECT COUNT(DISTINCT tag_id) FROM tags 
"""

const SQL_COUNT_DOCUMENTS* = sql"""
SELECT COUNT(docid) FROM documents 
"""

const SQL_DELETE_DOCUMENTS_BY_TAG* = sql"""
DELETE FROM documents
WHERE documents.id IN 
(SELECT document_id FROM tags WHERE tag_id = ?)
"""

const SQL_DELETE_SEARCHDATA_BY_TAG* = sql"""
DELETE FROM searchdata
WHERE id IN 
(SELECT document_id FROM tags WHERE tag_id = ?)
"""

const SQL_DELETE_TAGS_BY_TAG* = sql"""
DELETE FROM tags
WHERE document_id IN 
(SELECT document_id FROM tags WHERE tag_id = ?)
"""
