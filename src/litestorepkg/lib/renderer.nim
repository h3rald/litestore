import
  asynchttpserver,
  strutils,
  sequtils,
  pegs,
  json,
  os,
  tables

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
  options_markdown_css = "styles/_markdown.css"
  options_additional_css = "styles/_layout.css"
  options_fa_solid = "fonts/fa-solid-900.woff"
  options_fa_brands = "fonts/fa-brands-400.woff"
  options_js = ""
  options_watermark = ""
  options_template = "_template.htm"
  options_common = "_common.mac"


proc convertWikiLinks(contents: string, findDocument: proc (name: string): string, baseUrl: string): string =
  ## replace [[Wiki Page]] links to real pages, e.g. [Wiki Page](wiki/Wiki-Page.md)   
  ## additionally allow changing the displayed name [[My Page|Wiki-Page]] links to real pages, e.g. [My Page](wiki/Wiki-Page.md)   
  let peg_wiki_link1 = peg"'\[\[' {@} '\]\]'"
  let peg_wiki_link2 = peg"'\[\[' {@} '|' {@} '\]\]'"
  var mapping = newSeq[(string,string)]()
  # find all wiki links and try to find corresponding documents
  for wikiLink in contents.findAll(peg_wiki_link1).deduplicate():
    var matches: array[0..1, string]
    discard wikiLink.match(peg_wiki_link2, matches)      
    LOG.debug("match '$1' '$2'", matches[0], matches[1])
    var label = matches[0].strip
    var name = matches[1].strip
    if label == "" or name == "":
      discard wikiLink.match(peg_wiki_link1, matches)      
      LOG.debug("match '$1'", matches[0])
      label = matches[0].strip
      name = label.replace(" ", "-")
    let docId = findDocument(name)
    let link = "[" & label & "](" & baseUrl & docId & ")"
    LOG.debug("wiki link conversion: $1 -> $2 -> $3 -> $4 -> $5", wikiLink, label, name, docId, link)
    mapping.add((wikiLink, link))    
  # replace all pairs from the mapping table
  return multiReplace(contents, mapping)

proc getFonts(): string =
  var fa_solid = ""
  var fa_brands = ""  
  if options_embed:
    fa_solid = fa_solid_font
    fa_brands = fa_brands_font
  else:  
    fa_solid = options_fa_solid
    fa_brands = options_fa_brands

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


proc renderHtml(contents: string, getFragment: proc (name: string): string, findDocument: proc (name: string): string, getSpecialContent: proc (name: string): string, baseUrl: string, tags: openArray[string]): string =
  ## render markdown as HTML using HastyScribe
  
  try:
    # process YAML metadata and convert it into fields for HastyScribe
    # remove metadata from the document as Discount cannot handle it 
    # (it can handle pandoc metadata but it is too limiting)
    var fields = HastyFields()  
    var document = contents
    var hasMetadata = handleYamlMetadata(document, fields)
    LOG.debug("YAML metadata $1", hasMetadata)

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

    # TODO: correct ==highlights==    

    # render footer and sidebar
    let sidebar_fragment = hs.compileFragment(sidebar, "")
    LOG.debug("Rendered sidebar:\n$1\n...", sidebar_fragment.substr(0,40))
    let footer_fragment = hs.compileFragment(footer, "")    
    LOG.debug("Rendered footer:\n$1\n...", footer_fragment.substr(0,40))

    # process main document
    # Parse transclusions, fields, snippets, and macros
    document = hs.preprocess(document, "")   
    LOG.debug("Pre-processed document:\n$1\n...", document.substr(0,40))

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
      main_css_tag = (baseUrl & options_markdown_css).style_link_tag
  
    # read additional CSS
    var additional_css_tag = ""    
    if options_additional_css != "":
      if options_embed:
        let additional_css = getSpecialContent(options_additional_css)
        if additional_css != "":
            additional_css_tag = additional_css.style_tag
      else:
        additional_css_tag = (baseUrl & options_additional_css).style_link_tag

    # read optional javascript code
    var user_js_tag = ""
    let jsFile = getSpecialContent(options_js)
    if jsFile != "":
      user_js_tag = "<script type=\"text/javascript\">\n" & jsFile & "\n</script>"

    # read optional watermark picture
    var watermark_css_tag  = ""
    if options_watermark != "":
      watermark_css_tag = watermark_css(options_watermark)
    
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
    "fonts_css_tag", getFonts(), # needed for decorating links with icons
    "internal_css_tag", metadata.css, 
    "watermark_css_tag", watermark_css_tag,
    "js", user_js_tag,
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
    let footerDoc = LS.store.retrieveDocument(searchId, options)
    if footerDoc.data != "":
      return footerDoc.data
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
  
  try:
    let markdown = data
    proc getFragment(name: string):string = findSpecialDocument(LS, parts.dir, name)
    proc findDocument(name: string):string = findDocumentId(LS, name)   
    proc getSpecialContent(name: string):string = getSpecialDocumentContent(LS, name)   
    
    let html = markdown.renderHtml(getFragment, findDocument, getSpecialContent, baseUrl, tags)
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
    
    let html = markdown.renderHtml(getFragment, findDocument, getSpecialContent,"/dir/", tags)    
    result.headers = ctHeader("text/html")
    setOrigin(LS, req, result.headers)
    result.content = html
    result.code = Http200    
  except:
    return resError(Http500, "Unable to read and render file '$1'." % mdPath)