(function(){
    var doc = {
        user: $req.jwt.claims && $req.jwt.claims.sub || null,
        agent: $req.headers['user-agent'],
        language: $req.headers['accept-language'] && $req.headers['accept-language'].replace(/,.+$/, ''),
        path: $req.path,
        existing: !!$ctx.existing,
        method: $req.method,
        timestamp: Date.now()
    }
    $store.post('docs', 'logs', JSON.stringify(doc), 'application/json');
}())