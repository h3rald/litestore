(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;

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
        {path: "/guide/data_model", title: caret+"Data Model"},
        {path: "/guide/getting-started", title: "Getting Started"},
        {path: "/guide/usage", title: "Usage"},
        {path: "/guide/auth", title: "Authorization"},
        {path: "/guide/admin_app", title: "Administration App"},
        {path: "/guide/api", title: "HTTP API Reference"},
        {path: "/guide/api_info", title: caret+"info (LiteStore Information)"},
        {path: "/guide/api_dir", title: caret+"dir (LiteStore Directory)"},
        {path: "/guide/api_docs", title: caret+"docs (LiteStore Documents)"},
        {path: "/guide/api_tags", title: caret+"tags (LiteStore Tags)"},
        {path: "/guide/api_indexes", title: caret+"indexes (LiteStore Indexes)"},
        {path: "/guide/nim-api", title: "Nim API Reference"},
        {path: "/guide/nim-api_high", title: caret+"High Level"},
        {path: "/guide/nim-api_low", title: caret+"Low Level"},
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
        u.dropdown({title: "Guide", icon:"fa-book", links: ctrl.guidelinks, active: ctrl.activelink("guide")}),
        u.dropdown({title: "Tags", icon:"fa-tags", links: ctrl.taglinks(app.system), active: ctrl.activelink("tags")})];
      if (!app.system.read_only) {
        links.push(m("li",
          {class: ctrl.activelink("new")}, [m("a", {href: "/document/create/", config: m.route},
            [m("i.fa.fa-plus-circle"), " New"])]));
      }
      return m("ul.nav.navbar-nav", links);
    }
  };

  app.navheader = {
    view: function(ctrl, args) {
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
    view: function(ctrl, args) {
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
    view: function(ctrl, args) {
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