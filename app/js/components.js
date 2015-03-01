var app = app || {};

var bsNavDropdown = function() {
  var dropdown = {}
  dropdown.view = function(ctrl) {
    return m("li.dropdown", [
      m("a.dropdown-toggle[href='#'][data-toggle='dropdown'][role='button'][aria-expanded='false']",
        [m("span", ctrl.title()+" "), m("span.caret")]),
      m("ul.dropdown-menu[role='menu']", 
        ctrl.links().map(function(e){
          return m("li", 
            [m("a", {href: e.path, config: m.route}, e.title)])}))
      ])
  };
  return dropdown;
};

