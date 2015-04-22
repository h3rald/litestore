(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // Tags Module
  app.tags = {vm: {}};
  app.tags.vm.init = function(){
    var vm= this;
    vm.id = m.route.param("id");
    vm.docs = Doc.getByTag(vm.id).then(function(docs){return docs}, vm.flashError); 
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

  u.layout(app.tags);

}());