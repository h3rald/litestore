(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;

  app.navlinks = {
    controller: function(){
      app.navlinks.vm.init();
    },
    vm: {
      init: function(){
        this.info = Info.get();
        this.activelink = function(url){
          return (m.route().match(new RegExp("^\/"+url))) ? "active" : "";
        };
        this.guidelinks = [
          {path: "/guide/overview", title: "Overview"},
          {path: "/guide/getting-started", title: "Getting Started"},
          {path: "/guide/usage", title: "Usage"},
          {path: "/guide/api", title: "API"},
          {path: "/guide/credits", title: "Credits"}
        ];
        this.taglinks = function(info){ 
          return info.tags.map(function(tag){
            var key = Object.keys(tag)[0];
            return {path: "/tags/"+key, title: key+" ("+tag[key]+")"};
          });
        };
      }
    },
    view: function(ctrl){
      var vm = app.navlinks.vm;
      return m("ul.nav.navbar-nav", [
        m("li", {class: vm.activelink("info")}, [m("a", {href: "/info", config: m.route}, "Info")]),
        u.dropdown({title: "Tags", links: vm.taglinks(vm.info()), active: vm.activelink("tags")}),
        u.dropdown({title: "Guide", links: vm.guidelinks, active: vm.activelink("guide")})
      ]);
    }
  };
  
  app.navheader = {
    controller: function() {},
    view: function(ctrl) {
      return m(".navbar-header", [
        m("button.navbar-toggle.collapsed[data-toggle='collapse'][data-target='#nav-collapse'][type='button']", [
          m("span.sr-only", "Toggle navigation"),
          m("span.icon-bar"),
          m("span.icon-bar"),
          m("span.icon-bar")
        ]),
        m("a.navbar-brand", {href: "/", config:m.route}, "LiteStore")
      ]);
    }
  };
  
  app.searchbox = {
    controller: function() {},
    view: function(ctrl) {
      return m("form.navbar-form.navbar-right[role='search']", [
          m(".input-group", [
            m("input.form-control[type='text'i][placeholder='Search...']"),
            m("span.input-group-btn", 
              m("button.btn.btn-default[type='button']", [m("i.fa.fa-search")]))
          ])
        ]
      );
    }
  };
  
  app.navbar = {
    controller: function() {
      this.navheader = new app.navheader.controller();
      this.navlinks = new app.navlinks.controller();
      this.searchbox = new app.searchbox.controller();
    },
    view: function(ctrl) {
      return m("nav.navbar.navbar-inverse.navbar-fixed-top", [
        m(".container-fluid", [
          app.navheader.view(ctrl.navheader),
          m("#nav-collapse.collapse.navbar-collapse", [
            app.navlinks.view(ctrl.navlinks),
            app.searchbox.view(ctrl.searchbox)
          ])
        ])  
      ]);
    }
  };
}());
