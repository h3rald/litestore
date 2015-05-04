(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;
  
  app.doclist = {};
  
  /*
   * - id
   * - tags
   * - content
   */
  app.doclist.panel = function(item){
    var obj = {};
    var path = (item.id.match(/\.html?$/)) ? "/html/" : "/document/view/";
    obj.title = m("a", {href: path+item.id, config: m.route}, [item.id]);
    obj.content = m("div", [
      m("p", [item.content]),
      m("p", item.tags.map(function(tag){
        return u.taglink(tag);
      }))
      ]
    );
    return m(".row.search-result", m(".col-md-12", [u.panel(obj)]));
  };
  
  /* 
   * - items (id, tags, content)
   * - title
   * - subtitle
   * - querydata (total, limit, offset, baseurl)
   */
  app.doclist.view = function(obj){
    var results = m(".row", [m(".col-md-12", obj.items.map(app.doclist.panel))]);
   
    return m("section", [
      m(".row", [obj.title]),
      m(".row", [obj.subtitle]),
      m(".row.text-center", [u.paginator(obj.querydata)]),
      results,
      m(".row.text-center", [u.paginator(obj.querydata)])
    ]);
  };
  
}());