(function () {
  var id = $req.path.replace(/^\/docs\//, '');
  var valid = /[A-Z]{2}[0-9]{3}[A-Z]{2}/;
  if (!id.match(valid)) {
    $res.content = {
      error: 'Invalid number plate'
    };
    $res.code = 400;
    return true;
  }
}())