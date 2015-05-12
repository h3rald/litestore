(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  
  app.widgets = {};
    
  // Panel
  app.widgets.panel = function(obj){
    var panel = {
      controller: function(args){
        return {
          title: args.title,
          footer: args.footer,
          content: args.content,
        };
      },
      view: function(ctrl){
        var title = "";
        var footer = "";
        if (ctrl.title){
          title = m(".panel-heading", [
            m("h2.panel-title", [ctrl.title])  
          ]);
        }
        if (ctrl.footer){
          footer = m(".panel-footer", ctrl.footer);
        }
        return m(".panel.panel-default", [
          title,
          m(".panel-body", [
            ctrl.content
          ]),
          footer
        ]);
      }
    };
    return m.component(panel, obj);
  };
    
  // Paginator
  app.widgets.paginator = function(obj) {
    var paginator = {
      controller: function(args){
        var max_page = Math.min(14, Math.ceil(args.total/args.limit)-1);
        var c_page = Math.ceil(args.offset/args.limit);
        return {
          baseurl: args.baseurl,
          total: args.total,
          limit: args.limit,
          offset: args.offset,
          max_page: max_page,
          c_page: c_page
        };
      },
      view: function(ctrl){
        var page = function(n, sign, disabled){
          var klass;
          if (disabled) {
            klass = "disabled";
          } else {
            klass = (n === ctrl.c_page) ? "active" : "inactive";
          }
          var first = (n === 0);
          var last = (n == ctrl.max_page);
          var offset = ctrl.limit * n;
          sign = sign || n+1;  
          return m("li", {class: klass},
              [m("a", {
                        href: ctrl.baseurl +(n+1), // assuming 10 elements per page //+"/"+obj.limit,
                        config: m.route
                      }, [m.trust(sign)]
              )]
            );
        };
        
        var pages = [];
        var prev;
        var next;
        for (var i=0; i<=ctrl.max_page; i++){
          var p;
          switch(i){
            case ctrl.c_page-1:
              prev = page(i, "&laquo;");
              break;
            case ctrl.c_page+1:
              next = page(i, "&raquo;");
              break;
          }
          if (ctrl.c_page === 0){
              prev = page(0, "&laquo;", true);
          }
          if (ctrl.c_page === ctrl.max_page){
              next = page(ctrl.max_page, "&raquo;", true);
          }
          pages.push(page(i));
        }
        pages.unshift(prev);
        pages.push(next);
        return m("nav", [m("ul.pagination", pages)]);
        }
    };
    return m.component(paginator, obj);
  };
  
  // Dropdown
  app.widgets.dropdown = function(obj) {
    var dropdown = {
      controller: function(args){
        return {
          icon: args.icon,
          active: args.active,
          title: args.title,
          links: args.links
        };
      },
      view: function(ctrl){
        var el = "li.dropdown";
        var icon = (ctrl.icon) ? m("i.fa."+ctrl.icon) : "";
        if (ctrl.active.length > 0) {
          el += "."+ctrl.active;
        }
        return m(el, [
          m("a.dropdown-toggle[href='#'][data-toggle='dropdown'][role='button'][aria-expanded='false']",
          [icon, m("span", " "+ctrl.title+" "), m("span.caret")]),
          m("ul.dropdown-menu[role='menu']", 
          ctrl.links.map(function(e){
            return m("li", 
          [m("a", {href: e.path, config: m.route}, m.trust(e.title))]);}))
        ]);
      }
    };
    return m.component(dropdown, obj);
  };

  // TagLink
  app.widgets.taglink = function(obj){
    var taglink = {
      controller: function(args) {
        return {
          color: /^\$/.test(args.name) ? "warning" : "primary",
          name: args.name
        };
      },
      view: function(ctrl) {
        return m("span.tag-label.label.label-"+ctrl.color, 
          [m("i.fa.fa-tag"), " ", m("a", {href: "/tags/"+ctrl.name, config:m.route}, ctrl.name)]);
      }
    };
    return m.component(taglink, obj);
  };
  
  // DocLink (warning: API change!)
  app.widgets.doclink = function(obj) {
    var doclink = {
      controller: function(args){
        return {id: args.id};
      },
      view: function(ctrl) {
        return m("a", {href: "/document/view/"+ctrl.id, config: m.route}, id);
      }
    };
    return m.component(doclink, obj);
  };
  
  // TagButton (warning: API change!)
  app.widgets.tagbutton = function(obj) {
    var tagbutton = {
      view: function(ctrl, args) {
        return m("a", {href: "/tags/"+args.name, config:m.route},
          [m("i.fa.fa-tag"), " "+args.name+" ", m("span.badge", args.n)]);
      }
    };
    return m.component(tagbutton, obj);
  };
  
  // Toolbar
  app.widgets.toolbar = function(obj) {
    var toolbar = {
      controller: function(args){
        return {links: args.links};
      },
      view: function(ctrl){
        return m("nav.toolbar.btn-group[role='group'][aria-label='...'].pull-right", 
          ctrl.links.map(function(l){
            return m("a.btn.btn-default", 
                      {onclick:l.action, config: l.config}, 
                      [m("i.fa.fa-"+l.icon), " "+l.title]);
          })  
        );
      }
    };
    return m.component(toolbar, obj);
  };
  
  // Modal
  app.widgets.modal = function(obj) {
    var modal = {
      controller: function(args){
        return {
          id: args.id,
          content: args.content,
          title: args.title,
          action: args.action,
          actionText: args.actionText
        };
      },
      view: function(ctrl){
        return m(".modal.fade", 
          {id: ctrl.id, tabindex: "-1", role: "dialog"},
          [
            m(".modal-dialog", [
              m(".modal-content", [
                m(".modal-header", [
                  m("button", {type: "button", class: "close", "data-dismiss": "modal"}, 
                  [m.trust("&times;")]),
                  m("h4.modal-title", ctrl.title)
                ]),
                m(".modal-body", [ctrl.content]),
                m(".modal-footer", [
                  m("button.btn.btn-default[data-dismiss='modal']", "Close"),
                  m("button.btn.btn-primary[data-dismiss='modal']", {onclick: ctrl.action}, ctrl.actionText)
                ])
              ])
            ])
          ]
        );
      }
    };
    return m.component(modal, obj);
  };

}());