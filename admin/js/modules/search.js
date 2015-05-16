(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = LS.utils;

  // Search Module
  app.search = {vm: {}};
  app.search.vm.init = function(){
    var vm = this;
    vm.query = m.route.param("q");
    vm.baseurl = "/search/" + vm.query + "/";
    vm.limit = m.route.param("limit") || 10;
    vm.page = m.route.param("page") || 1;
    vm.page -= 1; // pages are 0-based
    vm.offset = vm.page * vm.limit;
    vm.result = m.prop({total: 0, results: []});
    vm.total = 0;
    vm.execTime = 0;
    Doc.search(vm.query, vm.offset, vm.limit).then(function(result){
      vm.result(result);
      vm.total = result.total;
      vm.execTime = (result.execution_time*1000).toFixed(0);
    }, vm.flashError); 
  };
  app.search.main = function(){
    var vm = app.search.vm;
    var result = vm.result();
    var obj = {};
    obj.title = m("h2.col-md-12", ["You searched for: ", m("em", vm.query)]);
    obj.subtitle = m("p.col-md-12", [m("strong", result.total), " results ("+vm.execTime+" ms)"]);
    obj.items = result.results;
    obj.items.forEach(function(item){ item.content = m.trust(item.highlight) });
    obj.querydata = vm;
    return m.component(app.doclist, obj);
  };

  u.layout(app.search);

}());
