(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils = {};
  
  /**
   * @param mod a module
   * @param vm a view-model (with init function)
   * @param main the main view to load
   */
  u.layout = function(mod) {
  
    mod.controller = mod.controller || function(){
      this.navbar = new app.navbar.controller();
      mod.vm.init();
    };
  
    mod.view = function(ctrl){
      return m("div", [
        m(".container", [
            app.navbar.view(ctrl.navbar),
            m("main", [mod.main()])
          ])
      ]);
    };
  };

  u.panel = function(obj){
    return m(".panel.panel-default", [
      m(".panel-heading", [
        m("h2.panel-title", [obj.title])  
      ]),
      m(".panel-body", [
        obj.content
      ])
    ]);
  };
  u.dropdown = function(obj) {
    var el = "li.dropdown";
    if (obj.active.length > 0) {
      el += "."+obj.active;
    }
    return m(el, [
      m("a.dropdown-toggle[href='#'][data-toggle='dropdown'][role='button'][aria-expanded='false']",
      [m("span", obj.title+" "), m("span.caret")]),
      m("ul.dropdown-menu[role='menu']", 
      obj.links.map(function(e){
        return m("li", 
      [m("a", {href: e.path, config: m.route}, e.title)]);}))
    ]);
  };

  u.taglink = function(tag) {
    return m("span.label.label-primary", [m("a", {href: "/tags/"+tag, config:m.route}, tag)]);
  };

  u.doclink = function(id) {
    return m("a", {href: "/document/"+id, config: m.route}, id);
  };

  u.date = function(date) {
    if (date === ""){
      return "";
    } else {
      return new Date(Date.parse(date)).toUTCString();
    }
  };

  u.toolbar = function(obj){
    return m("nav.toolbar.btn-group[role='group'][aria-label='...'].pull-right", obj.links.map(function(l){
      return m("a.btn.btn-default", {onclick:l.action}, [m("i.fa.fa-"+l.icon), " "+l.title]);
      })  
    );
  };

  u.getContentType = function(doc){
    var type = "";
    var subtype = "";
    doc.tags.forEach(function(tag){
      var t = tag.match(/^\$type:(.+)/);
      var s = tag.match(/^\$subtype:(.+)/);
      if (t) type = t[1];
      if (s) subtype = s[1];
    });
    return function(xhr) {
      xhr.setRequestHeader("Content-Type", type+"/"+subtype);
    };
  };
}());
