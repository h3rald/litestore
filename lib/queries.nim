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

const SQL_CREATE_DOCID_INDEX* = sql"""
CREATE INDEX docid_index ON documents(docid)
"""

const SQL_CREATE_SEARCHCONTENTS_TABLE* = sql"""
CREATE VIRTUAL TABLE searchcontents USING fts4(
id TEXT,
data TEXT, 
tokenize=porter)
"""

const SQL_CREATE_TAGS_TABLE* = sql"""
CREATE TABLE tags (
tag_id TEXT,
document_id TEXT,
PRIMARY KEY (tag_id, document_id))
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
INSERT INTO searchcontents
(docid, id, data)
VALUES (?, ?, ?)
"""

const SQL_DELETE_SEARCHCONTENT* = sql"""
DELETE FROM searchcontents WHERE
id = ?
"""

const SQL_UPDATE_SEARCHCONTENT* = sql"""
UPDATE searchcontents
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

const SQL_DELETE_SEARCHCONTENTS_BY_TAG* = sql"""
DELETE FROM searchcontents
WHERE id IN 
(SELECT document_id FROM tags WHERE tag_id = ?)
"""

const SQL_DELETE_TAGS_BY_TAG* = sql"""
DELETE FROM tags
WHERE document_id IN 
(SELECT document_id FROM tags WHERE tag_id = ?)
"""
