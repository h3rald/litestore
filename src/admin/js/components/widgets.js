(function(){
  'use strict';
  var app = window.LS || (window.LS = {});

  app.widgets = {};

  /* PANEL */
  app.widgets.panel = {
    view: function(ctrl, args){
      var title = "";
      var footer = "";
      if (args.title){
        title = m(".panel-heading", [
          m("h2.panel-title", [args.title])
        ]);
      }
      if (args.footer){
        footer = m(".panel-footer", args.footer);
      }
      return m(".panel.panel-default", [
        title,
        m(".panel-body", [
          args.content
        ]),
        footer
      ]);
    }
  };

  /* PAGINATOR */
  app.widgets.paginator = {
    view: function(ctrl, args){
      var max_page = Math.min(14, Math.ceil(args.total/args.limit)-1);
      var c_page = Math.ceil(args.offset/args.limit);
      var page = function(n, sign, disabled){
        var klass;
        if (disabled) {
          klass = "disabled";
        } else {
          klass = (n === c_page) ? "active" : "inactive";
        }
        var first = (n === 0);
        var last = (n == max_page);
        var offset = args.limit * n;
        sign = sign || n+1;
        return m("li", {class: klass},
            [m("a", {
                      href: args.baseurl +(n+1), // assuming 10 elements per page //+"/"+obj.limit,
                      config: m.route
                    }, [m.trust(sign)]
            )]
          );
      };

      var pages = [];
      var prev;
      var next;
      for (var i=0; i<=max_page; i++){
        var p;
        switch(i){
          case c_page-1:
            prev = page(i, "&laquo;");
            break;
          case c_page+1:
            next = page(i, "&raquo;");
            break;
        }
        if (c_page === 0){
            prev = page(0, "&laquo;", true);
        }
        if (c_page === max_page){
            next = page(max_page, "&raquo;", true);
        }
        pages.push(page(i));
      }
      pages.unshift(prev);
      pages.push(next);
      return m("nav", [m("ul.pagination", pages)]);
     }
  };

  /* DROPDOWN */
  app.widgets.dropdown = {
    view: function(ctrl, args){
      var el = "li.dropdown";
      var icon = (args.icon) ? m("i.fa."+args.icon) : "";
      if (args.active.length > 0) {
        el += "."+args.active;
      }
      return m(el, [
        m("a.dropdown-toggle[href='#'][data-toggle='dropdown'][role='button'][aria-expanded='false']",
        [icon, m("span", " "+args.title+" "), m("span.caret")]),
        m("ul.dropdown-menu[role='menu']",
        args.links.map(function(e){
          return m("li",
        [m("a", {href: e.path, config: m.route}, m.trust(e.title))]);}))
      ]);
    }
  };

  /* DROPDOWN */
  app.widgets.taglink = {
    view: function(ctrl, args) {
      var color = /^\$/.test(args.name) ? "warning" : "primary";
      return m("span.tag-label.label.label-"+color,
        [m("i.fa.fa-tag"), " ", m("a", {href: "/tags/"+args.name, config:m.route}, args.name)]);
    }
  };

  /* DOCLINK */
  app.widgets.doclink = {
    view: function(ctrl, args) {
      return m("a", {href: "/document/view/"+args.id, config: m.route}, id);
    }
  };

  /* TAGBUTTON */
  app.widgets.tagbutton = {
    view: function(ctrl, args) {
      return m("a", {href: "/tags/"+args.name, config:m.route},
        [m("i.fa.fa-tag"), " "+args.name+" ", m("span.badge", args.n)]);
    }
  };

  /* TOOLBAR */
  app.widgets.toolbar = {
    view: function(ctrl, args){
      return m("nav.toolbar.btn-group[role='group'][aria-label='...'].pull-right",
        args.links.map(function(l){
          return m("a.btn.btn-default",
                    {onclick:l.action, config: l.config},
                    [m("i.fa.fa-"+l.icon), " "+l.title]);
        })
      );
    }
  };

  /* MODAL */
  app.widgets.modal = {
    view: function(ctrl, args){
      if (!args.dismiss){
        args.dismiss = function(){};
      }
      if (!args.dismissText) {
        args.dismissText = "Close";
      }
      return m(".modal.fade",
        {id: args.id, tabindex: "-1", role: "dialog"},
        [
          m(".modal-dialog", [
            m(".modal-content", [
              m(".modal-header", [
                m("button", {type: "button", class: "close", "data-dismiss": "modal"},
                [m.trust("&times;")]),
                m("h4.modal-title", args.title)
              ]),
              m(".modal-body", [args.content]),
              m(".modal-footer", [
                m("button.btn.btn-default[data-dismiss='modal']", {onclick: args.dismiss}, args.dismissText),
                m("button.btn.btn-primary[data-dismiss='modal']", {onclick: args.action}, args.actionText)
              ])
            ])
          ])
        ]
      );
    }
  };

}());
