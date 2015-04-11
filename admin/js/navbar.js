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
        var vm = this;
        this.activelink = function(url){
          return (m.route().match(new RegExp("^\/"+url))) ? "active" : "";
        };
        vm.guidelinks = [
          {path: "/guide/overview", title: "Overview"},
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
      }
    },
    view: function(ctrl){
      var vm = app.navlinks.vm;
      var links = [
        m("li", {class: vm.activelink("info")}, [m("a", {href: "/info", config: m.route}, 
            [m("i.fa.fa-info-circle"), " Info"])]),
        u.dropdown({title: "Guide", icon:"fa-book", links: vm.guidelinks, active: vm.activelink("guide")}),
        u.dropdown({title: "Tags", icon:"fa-tags", links: vm.taglinks(app.system), active: vm.activelink("tags")})];
      if (!app.system.read_only) {
        links.push(m("li", 
          {class: vm.activelink("new")}, [m("a", {href: "/document/create/", config: m.route}, 
            [m("i.fa.fa-plus-circle"), " New"])]));
      }
      return m("ul.nav.navbar-nav", links);
    }
  };
  
  app.navheader = {
    controller: function() {},
    view: function(ctrl) {
      var vm =  app.navlinks.vm;
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
    controller: function() {
      app.searchbox.vm.init();
    },
    vm: {
      init: function(){
        var vm =  this;
        vm.query = m.prop("");
        vm.keySearch = function(el, isInitialized, context){
          $(el).keypress(function(event){
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
      }
    },
    view: function(ctrl) {
      var vm = app.searchbox.vm;
      return m("form.navbar-form.navbar-right[role='search']", [
          m(".input-group", [
            m("input.form-control", {
              type:"text", 
              placeholder:"Search...",
              onchange: m.withAttr("value", vm.query),
              config: vm.keySearch,
              value: vm.query()
            }),
            m("span.input-group-btn", 
              m("button.btn.btn-default",
                {
                  type: "button",
                  onclick: vm.search
                }, 
                [m("i.fa.fa-search")]))
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