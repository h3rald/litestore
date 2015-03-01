  var app = app || {};
  
(function(){
  'use strict';

  app.navlinks = {
    controller: function(){
      app.navlinks.vm.init();
    },
    vm: {
      init: function(){
        this.guide = m.prop([
          {path: "/pages/overview", title: "Overview"},
          {path: "/pages/getting-started", title: "Getting Started"},
          {path: "/pages/usage", title: "Usage"},
          {path: "/pages/api", title: "API"},
          {path: "/pages/credits", title: "Credits"}
        ]);
        this.title = m.prop("Guide");
        this.guideDropdown = new bsNavDropdown();
      }
    },
    view: function(ctrl){
      var vm = app.navlinks.vm;
      return m("ul.nav.navbar-nav", [
        m("li", [m("a", {href: "/info", config: m.route}, "Info")]),
        vm.guideDropdown.view({title: vm.title, links: vm.guide})
      ])
    }
  }
  
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
      ])
    }
  }
  
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
      )
    }
  }
  
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
      ])
    }
  }
}());
