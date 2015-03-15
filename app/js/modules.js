(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // Info Module
  app.info = {vm: {}};
  app.info.vm.init = function() {
    this.content = Info.get();
  };
  app.info.main = function(){
    var vm = app.info.vm;
    var info = vm.content();
    var infolist = m("dl", [
          m("dt", "Version"),
          m("dd", info.version),
          m("dt", "Size"),
          m("dd", info.size),
          m("dt", "Loaded directory"),
          m("dd", info.directory),
          m("dt", "Mirroring"),
          m("dd", info.mirror),
          m("dt", "Read-only"),
          m("dd", info.read_only),
          m("dt", "Total Documents"),
          m("dd", info.total_documents),
          m("dt", "Total Tags"),
          m("dd", info.total_tags)
    ]);
    var taglist = m("ul", info.tags.map(function(tag){
        var key = Object.keys(tag)[0];
        return m("li", [m("a", {href: "/tags/"+key, config: m.route}, key+" ("+tag[key]+")")]);
        })
      );
    var v = m(".row", [
      m(".col-md-6", [u.panel({title: "Datastore Information", content: infolist})]),
      m(".col-md-6", [u.panel({title: "Tags", content: taglist})])
    ]);
    return v;
  };

  // Tags Module
  app.tags = {vm: {}};
  app.tags.vm.init = function(){
    this.id = m.route.param("id");
    this.docs = Doc.getByTag(this.id); 
  };
  app.tags.main = function(){
    var docs = app.tags.vm.docs();
    var title = m("h2", ["Tag: ", m("em", docs.tags)]);
    var table = m("table.table.table-bordered.table-hover", [
      m("thead", [
        m("tr", [
          m("th", "ID"),
          m("th", "Created"),
          m("th", "Modified"),
          m("th", "Tags")
        ])
      ]),
      m("tbody",  [
        docs.results.map(function(d){
          return m("tr", [
            m("td", u.doclink(d.id)),  
            m("td", u.date(d.created)),  
            m("td", u.date(d.modified)),  
            m("td", d.tags.map(function(t){return u.taglink(t);})),  
          ]);
        })
      ])
    ]);
    return m(".row", [
      title,
      m("p", "Total: "+docs.total),
      table
    ]);
  };

  // Guide Module
  app.guide = {vm: {}};
  app.guide.vm.init = function() {
    this.id = m.route.param("id");
    this.content = Page.get(this.id);
  };
  app.guide.main = function(){
    return m("article.row", m.trust(app.guide.vm.content()));
  };


  u.layout(app.guide);
  u.layout(app.info);
  u.layout(app.tags);

}());yout(app.document);

}());