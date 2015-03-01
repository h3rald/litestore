var app = app || {};
var u = {};
  
(function(){
  'use strict';
  /**
   * @param mod a module
   * @param vm a view-model (with init function)
   * @param main the main view to load
   */
  u.layout = function(mod) {
  
    mod.controller = function(){
      this.navbar = new app.navbar.controller();
      mod.vm.init();
    }
  
    mod.view = function(ctrl){
      return m("div", [
        m(".container", [
            app.navbar.view(ctrl.navbar),
            m("main", [mod.main()])
          ])
      ])
    }
  }

  u.panel = function(obj){
    return m(".panel.panel-default", [
      m(".panel-heading", [
        m("h2.panel-title", obj.title)  
      ]),
      m(".panel-body", [
        obj.content
      ])
    ])
  }
  
}());
