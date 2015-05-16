(function(){
  'use strict';
  var app = window.LS || (window.LS = {});
  var u = app.utils;
  
  app.doclist = {};
  
  // Subcomponent
  app.doclist.panel = {
  
    /**
     * @typedef {Object} DoclistPanelConfig
     * @prop {string} id
     * @prop {string[]} tags
     * @prop {string} content
     *
     * @param {Function} ctrl
     * @param {DoclistPanelConfig} args
     */
    view: function(ctrl, args){
      var obj = {};
      var path = (args.id.match(/\.html?$/)) ? "/html/" : "/document/view/";
      obj.title = m("a", {href: path+args.id, config: m.route}, [args.id]);
      obj.content = m("div", [
        m("p", [args.content]),
        m("p", args.tags.map(function(tag){
          return u.taglink({name: tag, key: u.guid()});
        }))
      ]);
      return m(".row.search-result", m(".col-md-12", [u.panel(obj)])); 
    }
  };
  
  /**
   * @param {Function} ctrl
   * @param {Object} args
   * @param {string} args.title
   * @param {string} args.subtitle
   * @param {array.} args.items
   * @param {PaginatorConfig} args.querydata
   */
  app.doclist.view = function(ctrl, args){
    var results = m(".row", [m(".col-md-12", args.items.map(function(item){
      item.key = u.guid();
      return m.component(app.doclist.panel, item);
    }))]);
   
    return m("section", [
      m(".row", [args.title]),
      m(".row", [args.subtitle]),
      m(".row.text-center", [u.paginator(args.querydata)]),
      results,
      m(".row.text-center", [u.paginator(args.querydata)])
    ]);
  };
  
}());
