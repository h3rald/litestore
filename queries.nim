import db_sqlite


# SQL QUERIES

const SQL_COUNT_TAGS* = sql"""
SELECT COUNT(DISTINCT tag_id) FROM tags 
"""

const SQL_CREATE_DOCUMENTS_TABLE* = sql"""
CREATE TABLE documents (
id TEXT PRIMARY KEY,
data TEXT,
content_type TEXT,
binary INTEGER,
searchable INTEGER,
created TEXT,
modified TEXT)
"""

const SQL_CREATE_SEARCHCONTENTS_TABLE* = sql"""
CREATE VIRTUAL TABLE searchcontents USING fts4(
document_id TEXT,
content TEXT)
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
WHERE document_id = ? AND tag_id = ?
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
(document_id, content)
VALUES (?, ?)
"""

const SQL_DELETE_SEARCHCONTENT* = sql"""
DELETE FROM searchcontents WHERE
document_id = ?
"""

const SQL_UPDATE_SEARCHCONTENT* = sql"""
UPDATE searchcontents
SET content = ?
WHERE document_id = ?
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
