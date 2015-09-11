(function(){
  window.Page = {};
  window.Info = {};
  window.Doc = {};
  var app = window.LS || (window.LS = {});
  var u = app.utils;
  app.host = 'http://localhost:9500';

  var host = location.origin === app.host ? "" : app.host;
  
  Page.get = function(id) {
    var content = m.prop("");
    return m.request({
        method: "GET", 
        url: host+"/docs/admin/md/"+id+".md",
        deserialize: function(value) {
          return value;
        }
      }).then(function(content){ 
        return u.markdown(content);
      });
  };
  
  Info.get = function(){
    var content = m.prop("");
    return m.request({
        method: "GET", 
        url: host+"/info"
      }).then(content);
  };
  
  Doc.getByTag = function(tag, offset, limit) {
    offset = offset || 0;
    limit = limit || 10;
    var docs = m.prop("");
    return m.request({
        method: "GET", 
        url: host+"/docs?contents=false&tags="+tag+"&limit="+limit+"&offset="+offset
      }).then(docs);
  };
  
  Doc.search = function(search, offset, limit){
    offset = offset || 0;
    limit = limit || 10;
    var docs = m.prop("");
    return m.request({
        method: "GET", 
        url: host+"/docs?contents=false&search="+search+"&limit="+limit+"&offset="+offset,
      }).then(docs);
  };

  Doc.get = function(id) {
    var doc = m.prop("");
    return m.request({
        method: "GET", 
        url: host+"/docs/"+id+"?raw=true"
      }).then(doc);
  };
  
  Doc.delete = function(id){
    return m.request({
        method: "DELETE", 
        url: host+"/docs/"+id
      });
  };
  
  Doc.put = function(doc, contentType){
    xhrcfg = u.setContentType(doc, contentType);
    console.log("Doc.put - Saving Document:", doc);
    return m.request({
        method: "PUT", 
        url: host+"/docs/"+doc.id,
        data: doc.data,
        serialize: function(data){return data;},
        config: xhrcfg
      });
  };
  
  Doc.upload = function(doc) {
    console.log("Doc.put - Uploading Document:", doc);
    return m.request({
      method: "PUT",
      url: host+"/docs/"+doc.id,
      data: doc.data,
      serialize: function(data) {return data}
    });
  };
  
  Doc.patch = function(id, updatedTags){
    return Doc.get(id).then(function(doc){
      var tags = doc.tags;
      var count = 0;
      var ops = [];
      tags.forEach(function(tag){
        if (updatedTags[count]){
          if (updatedTags[count] != tag){
            // update tag
            ops.push({"op": "replace", "path": "/tags/"+count, "value": updatedTags[count]});
          }
        } else {
          // delete tag
          ops.push({"op": "remove", "path": "/tags/"+count});
        }
        count++;
      });
      if (updatedTags.length > tags.length) {
        for (i = tags.length; i< updatedTags.length; i++){
          // add tag
          ops.push({"op": "add", "path": "/tags/"+i, "value": updatedTags[i]});
        }
      }
      console.log("Doc.patch - Saving Tags:", ops);
      return m.request({
        method: "PATCH",
        url: host+"/docs/"+id,
        data: ops
      });
    });
  };
}());