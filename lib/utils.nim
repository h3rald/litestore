import 
  x_sqlite3,
  x_db_sqlite, 
  x_asynchttpserver, 
  json,
  strutils, 
  pegs, 
  asyncdispatch, 
  math, 
  strtabs

import 
  types, 
  queries, 
  contenttypes, 
  logger

proc toPlainText*(s: string): string =
  var tags = peg"""'<' [^>]+ '>'"""
  return s.replace(tags)

proc checkIfBinary*(binary:int, contenttype:string): int =
  if binary == -1 and contenttype.isBinary:
    return 1
  else:
    return binary

proc fail*(code: int, msg: string) =
  LOG.error(msg)
  quit(code)

proc ctHeader*(ct: string): StringTableRef =
  var h = TAB_HEADERS.newStringTable
  h["Content-Type"] = ct
  return h

proc ctJsonHeader*(): StringTableRef =
  return ctHeader("application/json")

proc resError*(code: HttpCode, message: string, trace = ""): Response =
  LOG.warn(message.replace("$", "$$"))
  if trace.len > 0:
    LOG.debug(trace.replace("$", "$$"))
  result.code = code
  result.content = """{"error":"$1"}""" % message
  result.headers = ctJsonHeader()

proc resDocumentNotFound*(id): Response =
  resError(Http404, "Document '$1' not found." % id)

proc eWarn*() =
  var e = getCurrentException()
  LOG.warn(e.msg)
  LOG.debug(getStackTrace(e))

#  Created by Joshua Wilson on 27/05/14.
#  Copyright (c) 2014 Joshua Wilson. All rights reserved.
#  https://github.com/neozenith/sqlite-okapi-bm25
#
# This is an extension to the work of "Radford 'rads' Smith"
# found at: https://github.com/rads/sqlite-okapi-bm25
# which is covered by the MIT License
# http://opensource.org/licenses/MIT
# the following code shall also be covered by the same MIT License
proc okapi_bm25f_kb*(pCtx: Pcontext, nVal: int32, apVal: PValueArg) {.cdecl.} =
  var matchinfo = cast[ptr uarray[int32]](value_blob(apVal[0]))
  # Setting the default values and ignoring argument based inputs so the extra
  # arguments can be the column weights instead.
  if nVal < 2:
    pCtx.result_error("wrong number of arguments to function okapi_bm25_kb(), expected k1 parameter", -1)
  if nVal < 3: 
    pCtx.result_error("wrong number of arguments to function okapi_bm25_kb(), expected b parameter", -1);
  let K1 = value_double(apVal[1]) # 1.2
  let B = value_double(apVal[2])  # 0.75
  # For a good explanation fo the maths and how to choose these variables
  # http://stackoverflow.com/a/23161886/622276
  # NOTE: the rearranged order of parameters to match the order presented on
  # SQLite3 FTS3 documentation 'pcxnals' (http://www.sqlite.org/fts3.html#matchinfo)
  let P_OFFSET = 0
  let C_OFFSET = 1
  let X_OFFSET = 2
  let termCount = matchinfo[P_OFFSET].int32
  let colCount = matchinfo[C_OFFSET].int32
  let N_OFFSET = X_OFFSET + 3*termCount*colCount
  let A_OFFSET = N_OFFSET + 1
  let L_OFFSET = A_OFFSET + colCount
  let totalDocs = matchinfo[N_OFFSET].float
  var avgLength:float = 0.0 
  var docLength:float = 0.0 
  for col in 0..colCount-1:
    avgLength = avgLength + matchinfo[A_OFFSET + col].float
    docLength = docLength + matchinfo[L_OFFSET + col].float
  var epsilon = 1.0 / (totalDocs*avgLength)
  var sum = 0.0;
  for i in 0..termCount-1:
    for col in 0..colCount-1:
      let currentX = X_OFFSET + (3 *  col * (i + 1))
      let termFrequency = matchinfo[currentX].float
      let docsWithTerm = matchinfo[currentX + 2].float
      var idf: float = ln((totalDocs - docsWithTerm + 0.5) / (docsWithTerm + 0.5))
      # "...terms appearing in more than half of the corpus will provide negative contributions to the final document score."
      # http://en.wikipedia.org/wiki/Okapi_BM25
      idf = if idf < 0: epsilon else: idf
      var rightSide: float = (termFrequency * (K1 + 1)) / (termFrequency + (K1 * (1 - B + (B * (docLength / avgLength)))))
      rightSide = rightSide+1.0
      # To comply with BM25+ that solves a lower bounding issue where large documents that match are unfairly scored as
      # having similar relevancy as short documents that do not contain as many terms
      # Yuanhua Lv and ChengXiang Zhai. 'Lower-bounding term frequency normalization.' In Proceedings of CIKM'2011, pages 7-16.
      # http://sifaka.cs.uiuc.edu/~ylv2/pub/cikm11-lowerbound.pdf
      let weight:float = if nVal > col+3: value_double(apVal[col+3]) else: 1.0
      sum = sum + (idf * rightSide) * weight
  pCtx.result_double(sum)
