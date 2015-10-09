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
   * @param {Object} mod
   * @param {Object} mod.vm
   * @param {Function} mod.vm.init
   * @param {Function} mod.main
   */
  u.layout = function(mod) {
    mod.controller = mod.controller || function(args){
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
            m.component(app.navbar),
            m("main", [mod.vm.flash(), mod.main()]),
            m("footer.footer.container.center", [
              m("p")])
          ])
      ]);
    };
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

  u.date = function(date) {
    return (date) ? new Date(Date.parse(date)).toUTCString() : "n/a";
  };

  
  u.showModal = function(sel){
    return function(){
      $(sel).modal();
    };
  };


  /* Component Factories */

  /**
   * @param {Object} obj
   * @param {string} obj.docid
   * @param {string} obj.id
   * @param {Function} obj.onSuccess
   * @param {Function} obj.onFailure
   */
  u.uploader = function(obj){
    var modalId = "#upload-"+obj.id+"-modal";
    var instance = m.component(app.uploader, obj);
    instance.show = function() {
      return u.showModal(modalId);
    };
    return instance;
  };

  /**
   * Creates a Panel component.
   * @param {Object} obj
   * @param {string} obj.title
   * @param {string} obj.footer
   * @param {string} obj.content
   */
  u.panel = function(obj){
    return m.component(app.widgets.panel, obj);
  };
    
  /**
   * @typedef {Object} PaginatorConfig
   * @prop {string} baseurl
   * @prop {int} total
   * @prop {int} limit
   * @prop {int} offset
   *
   * Creates a Paginator component.
   * @param {PaginatorConfig} obj
   */
  u.paginator = function(obj) {
    return m.component(app.widgets.paginator, obj);
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
  u.dropdown = function(obj) {
    return m.component(app.widgets.dropdown, obj);
  };

  /**
   * Creates a TagLink component.
   * @param {Object} obj
   * @param {string} obj.name
   */
  u.taglink = function(obj){
    return m.component(app.widgets.taglink, obj);
  };
  
  /**
   * Creates a DocLink component.
   * @param {Object} obj
   * @param {string} obj.id
   */
  u.doclink = function(obj) {
    return m.component(app.widgets.doclink, obj);
  };

  /**
   * Creates a TagButton component.
   * @param {Object} obj
   * @param {string} obj.name
   * @param {int} obj.n
   */
  u.tagbutton = function(obj) {
    return m.component(app.widgets.tagbutton, obj);
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
  u.toolbar = function(obj) {
    return m.component(app.widgets.toolbar, obj);
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
  u.modal = function(obj) {
    return m.component(app.widgets.modal, obj);
  };

}());
