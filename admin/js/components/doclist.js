(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;
  
  app.doclist = {};
  
  // Subcomponent
  app.doclist.panel = {
  
    controller: function(args){
      return {
        id: args.id,
        tags: args.tags,
        content: args.content
      };
    },
    
    view: function(ctrl){
      var obj = {};
      var path = (ctrl.id.match(/\.html?$/)) ? "/html/" : "/document/view/";
      obj.title = m("a", {href: path+ctrl.id, config: m.route}, [ctrl.id]);
      obj.content = m("div", [
        m("p", [ctrl.content]),
        m("p", ctrl.tags.map(function(tag){
          return u.taglink(tag);
        }))
      ]);
      return m(".row.search-result", m(".col-md-12", [u.panel(obj)])); 
    }
  };
  
  app.doclist.controller = function(args){
    return {
      items: args.items,
      title: args.title,
      subtitle: args.subtitle,
      querydata: args.querydata
    };
  };
  
  app.doclist.view = function(ctrl){
    var results = m(".row", [m(".col-md-12", ctrl.items.map(function(item){
      return m.component(app.doclist.panel, item);
    }))]);
   
    return m("section", [
      m(".row", [ctrl.title]),
      m(".row", [ctrl.subtitle]),
      m(".row.text-center", [u.paginator(ctrl.querydata)]),
      results,
      m(".row.text-center", [u.paginator(ctrl.querydata)])
    ]);
  };
  
}());