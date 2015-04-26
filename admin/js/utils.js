(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils = {};
  
  
  // http://byronsalau.com/blog/how-to-create-a-guid-uuid-in-javascript/
  u.guid = function(){
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random()*16|0, v = c === 'x' ? r : (r&0x3|0x8);
      return v.toString(16);
    });
  };
  
  u.fixHeadings = function(html, maxheading){
    var $content = $(html);
    var n = maxheading;
    if ($content.find("h"+n).length > 0) {
      return $content.html();
    } else {
      for (var i=n+1; i<=6; i++){
        var j = i-1;
        $content.find("h"+i).each(function(){
          $(this).replaceWith("<h"+j+">"+$(this).html()+"</h"+j+">");
        });
      }
      return u.fixHeadings($content, maxheading);
    }
  };
  
  u.markdown = function(s) {
    var hs = new marked.Renderer();
    var md = new marked.Renderer();
    hs.blockquote = function(q){
      var lines = q.split("\n");
      if (lines[0]){
        var r = /^<p>\s*%(.+?)%\s*/;
        var matches = lines[0].match(r);
        if (matches) {
          var klass = matches[1];
          if (klass){
            return "<div class=\""+klass+"\">\n"+q.replace(r, "<p>")+"\n</div>";
          }
        }
      }
      return md.blockquote(q);
    };
    hs.link = function(href, title, text){
      var components = href.match(/^([a-z]+):(.+)$/);
      if (components && components.length > 2){
        var protocol = components[1];
        var value = components[2];
        if (protocol === "class"){
          return "<span class=\""+value+"\">"+text+"</span>";
        } else if (protocol === "id"){
          return "<a id=\""+value+"\">"+text+"</a>";
        } else if (protocol === "abbr"){
          return "<abbr title=\""+value+"\">"+text+"</abbr>";
        }
      }
      return md.link(href, title, text);
    };
    var html = marked(s, {renderer: hs});
    var $html = $('<div>').append($(html).clone());
    return u.fixHeadings($html, 2);
  };
  
  /**
   * mod object:
   * @property vm a view-model (with init function)
   * @property main the main view to load
   */
  u.layout = function(mod) {
  
    mod.controller = mod.controller || function(){
      this.navbar = new app.navbar.controller();
      mod.vm.init();
      // Display flash if set on previous route
      mod.vm.flash = m.prop(u.flash());
      LS.flash = m.prop();
      mod.vm.showFlash = function(obj){
        LS.flash(obj);
        mod.vm.flash(u.flash());
        LS.flash = m.prop();
      };
      mod.vm.flashError = function(obj){
        mod.vm.showFlash({type: "warning", content: obj.error});
      };
    };
  
    mod.view = function(ctrl){
      return m("div", [
        m(".container", [
            app.navbar.view(ctrl.navbar),
            m("main", [mod.vm.flash(), mod.main()]),
            m("footer.footer.container.center", [
              m("p")])
          ])
      ]);
    };
  };

  u.panel = function(obj){
    var title = "";
    var footer = "";
    if (obj.title){
      title = m(".panel-heading", [
        m("h2.panel-title", [obj.title])  
      ]);
    }
    if (obj.footer){
      footer = m(".panel-footer", obj.footer);
    }
    return m(".panel.panel-default", [
      title,
      m(".panel-body", [
        obj.content
      ]),
      footer
    ]);
  };
  
  /**
   * - total
   * - limit
   * - offset
   * - query
   */
  u.paginator = function(obj) {
    var max_page = Math.min(14, Math.ceil(obj.total/obj.limit)-1);
    var c_page = Math.ceil(obj.offset/obj.limit);
    var page = function(n, sign, disabled){
      var klass;
      if (disabled) {
        klass = "disabled";
      } else {
        klass = (n === c_page) ? "active" : "inactive";
      }
      var first = (n === 0);
      var last = (n == max_page);
      var offset = obj.limit * n;
      sign = sign || n+1;  
      return m("li", {class: klass},
          [m("a", {
                    href: "/search/"+obj.query+"/"+(n+1), // assuming 10 elements per page //+"/"+obj.limit,
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
  };
  
  u.dropdown = function(obj) {
    var el = "li.dropdown";
    var icon = (obj.icon) ? m("i.fa."+obj.icon) : "";
    if (obj.active.length > 0) {
      el += "."+obj.active;
    }
    return m(el, [
      m("a.dropdown-toggle[href='#'][data-toggle='dropdown'][role='button'][aria-expanded='false']",
      [icon, m("span", " "+obj.title+" "), m("span.caret")]),
      m("ul.dropdown-menu[role='menu']", 
      obj.links.map(function(e){
        return m("li", 
      [m("a", {href: e.path, config: m.route}, m.trust(e.title))]);}))
    ]);
  };

  u.taglink = function(tag) {
    var color = /^\$/.test(tag) ? "warning" : "primary";
    return m("span.tag-label.label.label-"+color, 
      [m("i.fa.fa-tag"), " ", m("a", {href: "/tags/"+tag, config:m.route}, tag)]);
  };
  
  u.tagbutton = function(tag, n) {
    return m("a", 
      {href: "/tags/"+tag, config:m.route},
      [m("i.fa.fa-tag"), " "+tag+" ", m("span.badge", n)]);
  };

  u.doclink = function(id) {
    return m("a", {href: "/document/view/"+id, config: m.route}, id);
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
      return m("a.btn.btn-default", {onclick:l.action, config: l.config}, [m("i.fa.fa-"+l.icon), " "+l.title]);
      })  
    );
  };
  
  u.flash = function(){
    if (LS.flash()){
      return m(".row.alert.alert-dismissible.alert-"+LS.flash().type, [
        m("button.close[data-dismiss='alert']", m.trust("&times;")),
        LS.flash().content]);
    } else {
      return "";
    }
  };
  
  u.showModal = function(sel){
    return function(){
      $(sel).modal();
    };
  };
  
  /**
   * obj:
   * - id
   * - content
   * - title
   * - action
   * - actionText
   */
  u.modal = function(obj) {
    return m(".modal.fade", 
      {id: obj.id, tabindex: "-1", role: "dialog"},
      [
        m(".modal-dialog", [
          m(".modal-content", [
            m(".modal-header", [
              m("button", {type: "button", class: "close", "data-dismiss": "modal"}, 
              [m.trust("&times;")]),
              m("h4.modal-title", obj.title)
            ]),
            m(".modal-body", [obj.content]),
            m(".modal-footer", [
              m("button.btn.btn-default[data-dismiss='modal']", "Close"),
              m("button.btn.btn-primary[data-dismiss='modal']", {onclick: obj.action}, obj.actionText)
            ])
          ])
        ])
      ]);
  };

  u.setContentType = function(doc, contentType){
    var type = "";
    var subtype = "";
    if (doc.tags && doc.tags.length > 0) {
      doc.tags.forEach(function(tag){
        var t = tag.match(/^\$type:(.+)/);
        var s = tag.match(/^\$subtype:(.+)/);
        if (t) type = t[1];
        if (s) subtype = s[1];
      });
      contentType = type+"/"+subtype;
    }
    return function(xhr) {
      xhr.setRequestHeader("Content-Type", contentType);
    };
  };
}());