var Page = {}

Page.get = function(id) {
  var content = m.prop("");
  return m.request({
      method: "GET", 
      url: "md/"+id+".md",
      deserialize: function(value) {return value;}
    }).then(function(content){ return marked(content)});
}

var app = {}

app.vm = {};

app.controller = function(){
  this.navbar = new app.navbar.controller();
  app.vm.init();
}

app.vm.init = function() {
  this.pageid = m.prop(m.route.param("page"));
  this.content = Page.get(this.pageid());
}
  
app.view = function(ctrl){
  return m("div", [
    m(".container", [
      app.navbar.view(ctrl.navbar),
        m("main.row", [
          m("article", m.trust(app.vm.content()))
        ])
      ])
    ])
}

app.navlinks = {
  controller: function() {
    this.links = m.prop([
      {id: "overview", title: "Overview"},
      {id: "getting-started", title: "Getting Started"},
      {id: "usage", title: "Usage"},
      {id: "api", title: "API"},
      {id: "credits", title: "Credits"}
    ]);
  },
  view: function(ctrl) {
    return m("ul#nav-links.nav.navbar-nav", 
      ctrl.links().map(function(e){
        return m("li", {id: "nav-"+e.id, class: (app.vm.pageid() == e.id) ? "active" : ""}, 
          [m("a", {href: "/pages/"+e.id, config: m.route}, e.title)])}));
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

m.route.mode = "hash";

m.route(document.body, "/pages/overview", {
    "/pages/:page": app
});
