(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // Tags Module
  app.tags = {vm: {}};
  app.tags.vm.init = function(){
    var vm= this;
    vm.id = m.route.param("id");
    vm.limit = m.route.param("limit") || 10;
    vm.page = m.route.param("page") || 1;
    vm.page -= 1; // pages are 0-based
    vm.baseurl = "/tags/"+vm.id+"/";
    vm.offset = vm.page * vm.limit;
    vm.total= 0;
    vm.execTime = 0;
    vm.docs = Doc.getByTag(vm.id, vm.offset, vm.limit).then(function(docs){
      vm.total = docs.total;
      vm.execTime = (docs["execution-time"]*1000).toFixed(0);
      return docs;
    }, vm.flashError); 
  };
  app.tags.main = function(){
    var vm = app.tags.vm;
    var docs = vm.docs();
    var obj = {};
    obj.querydata = vm;
    obj.title = m("h2", ["Tag: ", m("em", docs.tags)]);
    obj.subtitle = m("p", [m("strong",docs.total), " results, ("+vm.execTime+" ms)"]);
    obj.items = docs.results;
    obj.items.forEach(function(item){ 
      item.content = m("ul", [
        m("li", [m("strong", "Created: "), u.date(item.created)]),
        m("li", [m("strong", "Modified: "), u.date(item.modified) || "n/a"]),
      ]);
    });
    return app.doclist.view(obj);
  };

  u.layout(app.tags);

}());