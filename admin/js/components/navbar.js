(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;
  var w = app.widgets;

  app.navlinks = {
    controller: function(args){
      var vm = {};
      var caret = "<i class='fa fa-angle-right'></i> ";
      vm.activelink = function(url){
        return (m.route().match(new RegExp("^\/"+url))) ? "active" : "";
      };
      vm.guidelinks = [
        {path: "/guide/overview", title: "Overview"},
        {path: "/guide/use-cases", title: caret+"Use Cases"},
        {path: "/guide/architecture", title: caret+"Architecture"},
        {path: "/guide/getting-started", title: "Getting Started"},
        {path: "/guide/usage", title: "Usage"},
        {path: "/guide/api", title: "API"},
        {path: "/guide/credits", title: "Credits"}
      ];
      vm.taglinks = function(info){ 
        return info.tags.map(function(tag){
          var key = Object.keys(tag)[0];
          return {path: "/tags/"+key, title: key+" ("+tag[key]+")"};
        });
      };
      return vm;
    },
    view: function(ctrl){
      var links = [
        m("li", {class: ctrl.activelink("info")}, [m("a", {href: "/info", config: m.route}, 
            [m("i.fa.fa-info-circle"), " Info"])]),
        w.dropdown({title: "Guide", icon:"fa-book", links: ctrl.guidelinks, active: ctrl.activelink("guide")}),
        w.dropdown({title: "Tags", icon:"fa-tags", links: ctrl.taglinks(app.system), active: ctrl.activelink("tags")})];
      if (!app.system.read_only) {
        links.push(m("li", 
          {class: ctrl.activelink("new")}, [m("a", {href: "/document/create/", config: m.route}, 
            [m("i.fa.fa-plus-circle"), " New"])]));
      }
      return m("ul.nav.navbar-nav", links);
    }
  };
  
  app.navheader = {
    controller: function(args) {},
    view: function(ctrl) {
      return m(".navbar-header", [
        m("button.navbar-toggle.collapsed[data-toggle='collapse'][data-target='#nav-collapse'][type='button']", [
          m("span.sr-only", "Toggle navigation"),
          m("span.icon-bar"),
          m("span.icon-bar"),
          m("span.icon-bar")
        ]),
        m("a.navbar-brand", {href: "/", config:m.route}, "LiteStore Admin")
      ]);
    }
  };
  
  app.searchbox = {
    controller: function() {
      var vm =  {};
      vm.query = m.prop("");
      vm.keySearch = function(el, isInitialized, context){
        if (isInitialized) return;
        $(el).keypress(function(event){
          if (isInitialized) return;
          m.redraw.strategy("none");
          vm.query($(el).val());
          if (event.which == 13){
            vm.search();
            return false;
          }
        });
      };
      vm.search = function(){
        m.route("/search/"+vm.query());
      };
      return vm;
    },
    view: function(ctrl) {
      return m("form.navbar-form.navbar-right[role='search']", [
          m(".input-group", [
            m("input.form-control", {
              type:"text", 
              placeholder:"Search...",
              onchange: m.withAttr("value", ctrl.query),
              config: ctrl.keySearch,
              value: ctrl.query()
            }),
            m("span.input-group-btn", 
              m("button.btn.btn-default",
                {
                  type: "button",
                  onclick: ctrl.search
                }, 
                [m("i.fa.fa-search")]))
          ])
        ]
      );
    }
  };
  
  app.navbar = {
    view: function(ctrl) {
      return m("nav.navbar.navbar-inverse.navbar-fixed-top", [
        m(".container-fluid", [
          m.component(app.navheader),
          m("#nav-collapse.collapse.navbar-collapse", [
            m.component(app.navlinks),
            m.component(app.searchbox)
          ])
        ])  
      ]);
    }
  };
}());