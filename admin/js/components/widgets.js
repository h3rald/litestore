(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  
  app.widgets = {};
    
  /**
   * Creates a Panel component.
   * @param {Object} obj
   * @param {string} obj.title
   * @param {string} obj.footer
   * @param {string} obj.content
   */
  app.widgets.panel = function(obj){
    var panel = {
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
    return m.component(panel, obj);
  };
    
  /**
   * Creates a Paginator component.
   * @param {Object} obj
   * @param {string} obj.baseurl
   * @param {int} obj.total
   * @param {int} obj.limit
   * @param {int} obj.offset
   */
  app.widgets.paginator = function(obj) {
    var paginator = {
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
    return m.component(paginator, obj);
  };
  
  /**
   * @typedef {Object} DropdownLink
   * @prop {string} path
   * @prop {string} title
   *
   * Creates a Dropdown component.
   * @param {Object} obj
   * @param {string} obj.icon
   * @param {string} obj.title
   * @param {string} obj.active
   * @param {array.DropdownLink} obj.links
   */
  app.widgets.dropdown = function(obj) {
    var dropdown = {
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
    return m.component(dropdown, obj);
  };

  /**
   * Creates a TagLink component.
   * @param {Object} obj
   * @param {string} obj.name
   */
  app.widgets.taglink = function(obj){
    var taglink = {
      view: function(ctrl, args) {
        var color = /^\$/.test(args.name) ? "warning" : "primary"
        return m("span.tag-label.label.label-"+color, 
          [m("i.fa.fa-tag"), " ", m("a", {href: "/tags/"+args.name, config:m.route}, args.name)]);
      }
    };
    return m.component(taglink, obj);
  };
  
  /**
   * Creates a DocLink component.
   * @param {Object} obj
   * @param {string} obj.id
   */
  app.widgets.doclink = function(obj) {
    var doclink = {
      view: function(ctrl, args) {
        return m("a", {href: "/document/view/"+args.id, config: m.route}, id);
      }
    };
    return m.component(doclink, obj);
  };
  
  /**
   * Creates a TagButton component.
   * @param {Object} obj
   * @param {string} obj.name
   * @param {int} obj.n
   */
  app.widgets.tagbutton = function(obj) {
    var tagbutton = {
      view: function(ctrl, args) {
        return m("a", {href: "/tags/"+args.name, config:m.route},
          [m("i.fa.fa-tag"), " "+args.name+" ", m("span.badge", args.n)]);
      }
    };
    return m.component(tagbutton, obj);
  };
  
  /**
   * @typedef {Object} ToolbarLink
   * @prop {Function} action
   * @prop {Function} config
   * @prop {string} title
   * @prop {string} icon
   *
   * Creates a ToolBar component.
   * @param {Object} obj
   * @param {array.<ToolbarLink>} obj.links
   */
  app.widgets.toolbar = function(obj) {
    var toolbar = {
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
    return m.component(toolbar, obj);
  };
  
  /**
   * Creates a Modal component.
   * @param {Object} obj
   * @param {string} obj.id
   * @param {string} obj.content
   * @param {string} obj.title
   * @param {Function} obj.action
   * @param {string} obj.actionText
   */
  app.widgets.modal = function(obj) {
    var modal = {
      view: function(ctrl, args){
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
                  m("button.btn.btn-default[data-dismiss='modal']", "Close"),
                  m("button.btn.btn-primary[data-dismiss='modal']", {onclick: args.action}, args.actionText)
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
