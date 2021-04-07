import
  asynchttpserver,
  strutils,
  sequtils,
  pegs,
  json,
  os,
  tables,
  strtabs

{.passL: "-Lpackages/hastyscribe/src/hastyscribepkg/vendor".}  
import  
  ../../../packages/hastyscribe/src/hastyscribe,
  ../../../packages/hastyscribe/src/hastyscribepkg/markdown,
  ../../../packages/hastyscribe/src/hastyscribepkg/utils as utils_hs

import
  types,
  core,
  utils,
  logger

const
  options_embed = false  
  options_use_main_store = true
  options_markdown_css = "_renderer/_markdown.css"
  options_additional_css = "_renderer/_layout.css"
  options_fa_solid = "_renderer/fa-solid-900.woff"
  options_fa_brands = "_renderer/fa-brands-400.woff"
  options_user_js = ""
  options_watermark = ""
  options_template = "_renderer/_template.htm"
  options_common = "_renderer/_common.md"


proc convertWikiLinks(contents: string, findDocument: proc (name: string): string, baseUrl: string): string =
  ## replace [[Wiki Page]] links to real pages, e.g. [Wiki Page](wiki/Wiki-Page.md)   
  ## additionally allow changing the displayed name [[My Page|Wiki-Page]] links to real pages, e.g. [My Page](wiki/Wiki-Page.md)   
  ## the target page may have #Target-Anchor defined
  let peg_wiki_link1 = peg"'\[\[' {@} '\]\]'"
  let peg_wiki_link2 = peg"'\[\[' {@} '|' {@} '\]\]'"
  let peg_wiki_link3 = peg"'\[\[' {@} '|' {@} '#' {@} '\]\]'"
  var mapping = newSeq[(string,string)]()
  # find all wiki links and try to find corresponding documents
  for wikiLink in contents.findAll(peg_wiki_link1).deduplicate():
    var matches: array[0..2, string]    
    discard wikiLink.match(peg_wiki_link3, matches)
    LOG.debug("WikiLink '$1' match '$2' '$3' '$4'", wikiLink, matches[0], matches[1], matches[2])
    var label = matches[0].strip
    var name = matches[1].strip
    var anchor = matches[2].strip
    if label == "" or name == "" or anchor == "":
      discard wikiLink.match(peg_wiki_link2, matches)      
      LOG.debug("WikiLink '$1' match '$2' '$3'", wikiLink, matches[0], matches[1])
      label = matches[0].strip
      name = matches[1].strip
      anchor = ""
      if label == "" or name == "":
        discard wikiLink.match(peg_wiki_link1, matches)      
        LOG.debug("WikiLink '$1' match '$2'", wikiLink, matches[0])
        label = matches[0].strip
        name = label.replace(" ", "-")        
    var docId = findDocument(name)
    if baseUrl.endsWith('/') and docId.startsWith('/'):
      docId = docId[1 .. ^1]
    if anchor != "":
      anchor = "#" & anchor
    let link = "[" & label & "](" & baseUrl & docId & anchor & ")"
    LOG.debug("wiki link conversion: $1 -> $2 -> $3 -> $4 -> $5", wikiLink, label, name, docId, link)
    mapping.add((wikiLink, link))    
  # replace all pairs from the mapping table
  return multiReplace(contents, mapping)

proc handleFootnotes(contents: string): string =
  ## replace [^footnote] with a superscripted internal link to the footnote
  ## and replace [^footnote]: text into and anchored line of text with [footnote] header
  let peg_footnote_use = peg"'\[\^' {@} '\]'"
  let peg_footnote_definition = peg" \n '\[\^' {@} '\]:' {@} \n"
  var mapping = newSeq[(string,string)]()
  var footnotes = newStringTable()
  # footnote definitions should be unique
  for footnote_definition in contents.findAll(peg_footnote_definition):
    var matches: array[0..1, string]
    discard footnote_definition.match(peg_footnote_definition, matches)      
    LOG.debug("footnote definition $1 $2", matches[0], matches[1].substr(0,40))
    let footnote_id = matches[0].strip
    let footnote_text = matches[1].strip
    let back_link = "<a href=\"#$1-use\" title=\"back to document\"><span class=\"fa-arrow-up\"></span></a>" % footnote_id
    let footnote_definition_tag = "\n<a id=\"$1\"></a>[<b>$1</b>]: $2 $3\n" % [footnote_id, footnote_text, back_link] 
    mapping.add((footnote_definition, footnote_definition_tag))    
    footnotes[footnote_id] = footnote_text
  # find footnote uses, there may be duplicates
  for footnote_use in contents.findAll(peg_footnote_use).deduplicate():
    var matches: array[0..0, string]
    discard footnote_use.match(peg_footnote_use, matches)      
    LOG.debug("footnote use $1", matches[0])
    let footnote_id = matches[0].strip
    let back_link = "<a id=\"$1-use\"></a>" % footnote_id
    var footnote_use_tag = ""
    if footnotes.hasKey(footnote_id):
      let footnote_text = footnotes[footnote_id]
      footnote_use_tag = "$3<sup><a href=\"#$1\" title=\"$2\">$1</a></sup>" % [footnote_id, footnote_text, back_link]
    else:
      # no backlink, this footnote has no definition
      footnote_use_tag = "<sup><a href=\"#$1\" title=\"No definition!\">$1</a></sup>$2" % [footnote_id, back_link]
    mapping.add((footnote_use, footnote_use_tag)) 
  # replace all pairs from the mapping table
  return multiReplace(contents, mapping)


proc getFonts(baseUrl: string): string =
  var fa_solid = ""
  var fa_brands = ""  
  if options_embed:
    fa_solid = fa_solid_font
    fa_brands = fa_brands_font
  else:
    fa_solid = baseUrl & options_fa_solid
    fa_brands = baseUrl & options_fa_brands    

  let fonts = @[
    create_font_face(fa_solid, "Font Awesome 5 Free", "normal", 900, options_embed),
    create_font_face(fa_brands, "Font Awesome 5 Brands", "normal", 400, options_embed),
  ]
  return fonts.join.style_tag


proc handleToc(contents: string, hasToc: var bool): string =
  let peg_toc = peg"{'\[' i'toc' '\]' \n}"
  result = contents  
  for toc in result.findAll(peg_toc):    
    result = result.replace(toc, "")
    hasToc = true
    return #replace only the first occurence


proc renderHtml(contents: string, getFragment: proc (name: string): string, findDocument: proc (name: string): string, getSpecialContent: proc (name: string): string, baseUrl, specialBaseUrl: string, tags: openArray[string]): string =
  ## render markdown as HTML using HastyScribe
  
  try:  
    # process YAML metadata and convert it into fields for HastyScribe
    # remove metadata from the document as Discount cannot handle it 
    # (it can handle pandoc metadata but it is too limiting)
    var fields = HastyFields()  
    var document = contents
    var hasMetadata = handleYamlMetadata(document, fields)
    LOG.debug("YAML metadata $1", hasMetadata)

    # check if MathJax (math) or Mermaid (diagrams) was enabled
    # remove the fields as they are not needed in the document
    var options_math = false
    if fields.hasKey("math"):
      options_math = fields["math"].parseBool
      LOG.debug("Math $1", options_math)
      fields.del("math")  
      
    var options_diagrams = false
    if fields.hasKey("diagrams"):
      options_diagrams = fields["diagrams"].parseBool
      LOG.debug("Diagrams $1", options_diagrams)
      fields.del("diagrams")  

    # if tags were defined concatenate them into a single string and add as a field
    if tags.len > 0:
      var systemTags = newSeq[string]()
      var userTags = newSeq[string]()
      for tag in tags:
        if tag.startsWith('$'):
          systemTags.add(tag)
        else:
          userTags.add(tag)  
      if systemTags.len > 0:
        fields["system-tags"] = systemTags.join(" ")
      if userTags.len > 0:
        fields["tags"] = userTags.join(" ")
    
    # create and configure instance of the renderer, use pre-populated fields
    # disable most options, they are handled manually later in this function
    var options = HastyOptions(toc: false, output: "", css: "", watermark: "", fragment: true)
    var hs = newHastyScribe(options, fields)
    
    # check if [toc] is present in the document, use it as a flag switching on table of contents
    # remove it as the table of contents is displayed in a sidebar
    var options_toc = false
    document = handleToc(document, options_toc)
    LOG.debug("TOC: $1", options_toc)
      
    # retrieve optional sidebar and footer
    var sidebar = getFragment("sidebar")
    LOG.debug("sidebar:\n$1\n...", sidebar.substr(0,40))
    var footer = getFragment("footer")
    LOG.debug("footer:\n$1\n...", footer.substr(0,40))
    
    # prepend common macros and snippets
    # discard result, store macro and snippets definitions in hs.macros
    let common = getSpecialContent(options_common)
    discard hs.preprocess(common, "")
    LOG.debug("common macros:\n$1\n...", common.substr(0,40))

    # process all fragments converting [[Wiki Links]] to markdown links
    sidebar = sidebar.convertWikiLinks(findDocument, baseUrl)
    footer = footer.convertWikiLinks(findDocument, baseUrl)
    document = document.convertWikiLinks(findDocument, baseUrl)
    LOG.debug("Converted WikiLinks")

    # render footer and sidebar
    let sidebar_fragment = hs.compileFragment(sidebar, "")
    LOG.debug("Rendered sidebar:\n$1\n...", sidebar_fragment.substr(0,40))
    let footer_fragment = hs.compileFragment(footer, "")    
    LOG.debug("Rendered footer:\n$1\n...", footer_fragment.substr(0,40))

    # process main document
    # Parse transclusions, fields, snippets, and macros
    document = hs.preprocess(document, "")   
    LOG.debug("Pre-processed document:\n$1\n...", document.substr(0,40))

    # handle footnotes (only in the main document)
    # convert them to syntax understood by discount
    document = document.handleFootnotes()
    LOG.debug("Footnotes:\n$1\n...", document.substr(0,40))

    # Process markdown    
    var metadata = TMDMetaData(title:"", author:"", date:"", toc:"", css:"")
    document = document.md(0, metadata)
    LOG.debug("Metadata, TOC, CSS processed");

    # get 3 Pandoc/YAML metadata values
    if metadata.title == "" and fields.hasKey("title"):
      metadata.title = fields["title"]
    if metadata.author == "" and fields.hasKey("author"):
      metadata.author = fields["author"]
    if metadata.date == "" and fields.hasKey("doc_date"):
      metadata.date = fields["doc_date"]
    
    # Manage metadata 
    var author_footer = ""
    if metadata.author != "":
      author_footer = "<span class=\"copy\"></span> " & metadata.author & " &ndash;"
    
    var title_tag = ""
    var header_tag = ""
    if metadata.title != "":
      title_tag = "<title>" & metadata.title & "</title>"
      header_tag = "<div id=\"header\"><h1>" & metadata.title & "</h1></div>"
    
    var sec_class_tag = ""
    if fields.hasKey("sec_class"):
      sec_class_tag = "<div id=\"sec_class\"><p>" & fields["sec_class"] & "</p></div>"  
  
    # handle TOC if it was found in the document
    var toc = ""
    var headings = ""
    if options_toc and metadata.toc != "":
      toc = metadata.toc
      headings = " class=\"headings\""    
    
    # read main CSS, fallback to HastyScribe style
    var main_css_tag = ""
    if options_embed:
      var main_css =  getSpecialContent(options_markdown_css)
      if main_css == "":
        main_css = stylesheet
      main_css_tag = main_css.style_tag
    else:
      main_css_tag = (specialBaseUrl & options_markdown_css).style_link_tag
  
    # read additional CSS
    var additional_css_tag = ""    
    if options_additional_css != "":
      if options_embed:
        let additional_css = getSpecialContent(options_additional_css)
        if additional_css != "":
            additional_css_tag = additional_css.style_tag
      else:
        additional_css_tag = (specialBaseUrl & options_additional_css).style_link_tag

    # read optional javascript code
    var user_js_tag = ""
    let jsFile = getSpecialContent(options_user_js)
    if jsFile != "":
      user_js_tag = "<script type=\"text/javascript\">\n" & specialBaseUrl & jsFile & "\n</script>"
      LOG.debug("User js:\n$1\n...", user_js_tag.substr(0,40))

    # handle javascript for MathJax
    var mathjax_js_tag = ""
    if options_math:
      mathjax_js_tag = """
<script type="text/javascript" id="MathJax-config" defer src="$1_renderer/_mathjax_config.js"></script>
<script type="text/javascript" id="MathJax-script" defer src="$1_mathjax/es5/tex-svg.js"></script>
""" % specialBaseUrl
      LOG.debug("MathJax js:\n$1\n...", mathjax_js_tag.substr(0,40))

    # handle javascript for Mermaid
    var mermaid_js_tag = ""
    if options_diagrams:
      mermaid_js_tag = """
<script src="$1_mermaid/mermaid.min.js"></script>
<script>mermaid.initialize({startOnLoad:true});</script>
""" % specialBaseUrl
      LOG.debug("Mermaid js:\n$1\n...", mermaid_js_tag.substr(0,40))  

    # read optional watermark picture
    var watermark_css_tag  = ""
    if options_watermark != "":
      watermark_css_tag = watermark_css(options_watermark)

    # read fonts needed for icons
    var fonts_tag = getFonts(specialBaseUrl) 
    
    # get document template and populate fields
    let docTemplate = getSpecialContent(options_template)
    LOG.debug("Loaded template:\n$1\n...", docTemplate.substr(0,40))
    result = docTemplate
    let mapping = [
    "title", metadata.title, 
    "title_tag", title_tag, 
    "header_tag", header_tag, 
    "sec_class_tag", sec_class_tag,
    "author", metadata.author, 
    "author_footer", author_footer, 
    "doc_date", metadata.date, 
    "toc", toc, 
    "main_css_tag", main_css_tag, 
    "additional_css_tag", additional_css_tag, 
    "headings", headings, 
    "body", document,
    "fonts_css_tag", fonts_tag,
    "internal_css_tag", metadata.css, 
    "watermark_css_tag", watermark_css_tag,
    "user_js_tag", user_js_tag,
    "mathjax_js_tag", mathjax_js_tag,
    "mermaid_js_tag", mermaid_js_tag,
    "sidebar", sidebar_fragment,
    "footer", footer_fragment]
  
    var html = docTemplate % mapping
    LOG.debug("HTML:\n$1\n...", html.substr(0,40))
    
    #hs.embed_images(dir)
    html = html.add_jump_to_top_links()
    LOG.debug("top-document links:\n$1\n...", html.substr(0,40))

    result = html
  except:
    LOG.warn("Exception $1", getCurrentExceptionMsg())    


proc findSpecialDocument(LS: LiteStore, dirId, name:string): string =
  ## search for special pages (e.g. _footer.md) starting from specified directory up to the root
  var searchDir = dirId
  var options = newQueryOptions()
  options.like = "1"
  while searchDir != "":
    let searchId = searchDir & "/\\_" & name & "%.md"
    LOG.debug("Search $1: '$2'", name, searchId)
    let specialDoc = LS.store.retrieveDocument(searchId, options)
    if specialDoc.data != "":
      return specialDoc.data
    else:
      let parts = searchDir.splitFile
      searchDir = parts.dir
  return ""


proc findDocumentId(LS: LiteStore, name:string): string =
  ## Search for a markdown document of given name (last part of the document id)
  ## and return the full document id with the extension changed to .htm  
  let searchId = "%/" & name & ".md"
  LOG.debug("Search $1: '$2'", name, searchId)
  let docId = LS.store.findDocumentId(searchId)
  if docId != "":
    result = docId.changeFileExt(".htm")    
  else:
    result = ""


proc getSpecialDocumentContent(LS: LiteStore, name: string): string =      
  result = ""
  if name != "":
    let options = newQueryOptions()
    LOG.debug("Get special document $1", name)
    var doc = LS.store.retrieveDocument(name, options)
    result = doc.data


proc findSpecialFile(dir, name:string): string =
  ## search for special pages (e.g. _footer.md) starting from specified directory up to the root
  var searchDir = dir
  while searchDir != "":
    let searchPattern = searchDir / ("_" & name & "*.md")
    LOG.debug("Search $1: '$2'", name, searchPattern)
    for file in walkFiles(searchPattern):
      try:
        return file.readFile                
      except:
        discard
    searchDir = searchDir.parentDir
  return ""  


proc findFile(root, name:string): string =
  ## Search for a markdown file of given name 
  ## and return the relative file path (without root) converted to URL and with the extension changed to .htm
  for file in walkDirRec(root):
    let parts = file.splitFile
    if parts.name == name and parts.ext.cmpIgnoreCase(".md") == 0:
       return file.changeFileExt(".htm").replace("\\", "/")[len(root) .. ^1]       
  return ""       


proc getSpecialFileContent(dir, name: string): string =
  ## read content of the specified file from the served directory
  result = ""
  if name != "":
    try:
      let path = dir / name    
      result = path.readFile      
    except:
      discard


proc tryRenderMarkdownDocument*(LS: LiteStore, id: string, options = newQueryOptions(), req: LSRequest): LSResponse =  
  ## render given document to HTML when the requested document had HTML extension
  ## and the corresponding markdown document exists
  
  let parts = id.splitFile()
  if parts.ext.cmpIgnoreCase(".htm") != 0 and parts.ext.cmpIgnoreCase(".html") != 0:
    return resDocumentNotFound(id)    

  # if requested document was HTML then check if the corresponding MD document exists
  let mdId = id.changeFileExt("md")
  let mdDoc = LS.store.retrieveRawDocument(mdId, options)
  if mdDoc == "":
    return resDocumentNotFound(id)
  let jdoc = mdDoc.parseJson
  let data = jdoc["data"].getStr
  var tags = newSeq[string]()
  for tag in jdoc["tags"].items:
    tags.add(tag.str)
  
  # detect if the URL contained store id
  var storeId = ""
  for id, ls in pairs(LSDICT):
    if (ls == LS):
      storeId = id
      break;
  var baseUrl = ""
  if storeId != "":
    baseUrl = "/stores/" & storeId & "/docs/"
  else:
    baseUrl = "/docs/"  

  var specialBaseUrl = baseUrl
  var specialStore = LS
  if options_use_main_store:
    specialStore = LSDICT["master"]    
    specialBaseUrl = "/docs/"

  try:
    let markdown = data
    proc getFragment(name: string):string = findSpecialDocument(LS, parts.dir, name)
    proc findDocument(name: string):string = findDocumentId(LS, name)      
    proc getSpecialContent(name: string):string = getSpecialDocumentContent(specialStore, name)   
    
    let html = markdown.renderHtml(getFragment, findDocument, getSpecialContent, baseUrl, specialBaseUrl, tags)
    result.headers = ctHeader("text/html")
    setOrigin(LS, req, result.headers)
    result.content = html
    result.code = Http200
  except:
    return resError(Http500, "Unable to render document '$1'." % mdId)


proc tryRenderMarkdownFile*(LS: LiteStore, path: string, req: LSRequest): LSResponse =  
  ## render given file to HTML when the requested file had HTML extension
  ## and the corresponding markdown file exists

  let parts = path.splitFile()
  if parts.ext.cmpIgnoreCase(".htm") != 0 and parts.ext.cmpIgnoreCase(".html") != 0:
    return resError(Http404, "File '$1' not found." % path)

  # if requested file was HTML then check if the corresponding MD file exists
  let mdPath = path.changeFileExt(".md")
  if not mdPath.fileExists:
    return resError(Http404, "File '$1' not found." % path)
  let tags = getTagsForFile(mdPath)  

  try:
    let markdown = mdPath.readFile
    proc getFragment(name: string):string = findSpecialFile(parts.dir, name)
    proc findDocument(name: string):string = findFile(LS.directory, name)
    proc getSpecialContent(name: string):string = getSpecialFileContent(LS.directory, name)   
    
    let html = markdown.renderHtml(getFragment, findDocument, getSpecialContent,"/dir/", "/dir/", tags)    
    result.headers = ctHeader("text/html")
    setOrigin(LS, req, result.headers)
    result.content = html
    result.code = Http200    
  except:
    return resError(Http500, "Unable to read and render file '$1'." % mdPath)