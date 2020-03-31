## Authorization

LiteStore can be configured to automatically validate [JWT](https://jwt.io/) tokens and authorize authenticated users on specific resources (and specific resource verbs even) based on their [OAuth2 scopes](https://oauth.net/2/scope/) specified in the token itself.

> %note%
> auth.json vs. config.json 
> 
> As of version 1.8.0, it is recommended to use the LiteStore configuration file to configure authorization. This specialized **auth.json** configuration file  format will however be maintained  for compatibility reasons.

To configure authorization, create an **auth.json** file like the following:

```
{
  "access": {
    "/info": {
      "GET": ["admin:server"]
    }, 
    "/docs/*": {
      "POST": ["admin:server"],
      "PATCH": ["admin:server"],
      "PUT": ["admin:server"],
      "DELETE": ["admin:server"]
    },
    "/docs/wiki/*": {
      "POST": ["admin:wiki"],
      "PUT": ["admin:wiki"],
      "PATCH": ["admin:wiki"],
      "DELETE": ["admin:wiki"]
    }
  },
  "signature": "\n-----BEGIN CERTIFICATE-----\n<certificate text goes here>\n-----END CERTIFICATE-----\n"
}
```

The **access** property is a dictionary of endpoints to which only users that have one of the specified scopes can access. 

For example, in this case only users with the **admin:server** scope will be able to access /info, and any /docs/ document.

However, users with the **admin:wiki** scope will be able to access documents located under the /docs/wiki/ folder.

Finally, specify the public signature to be used to validate JWT tokens using the **signature** property. Typically, its value should be set to the first value of the [x.509 certificate chain](https://auth0.com/docs/tokens/reference/jwt/jwks-properties) specified in the [JSON Web Key Set](https://auth0.com/docs/jwks) of your API.

To use this configuration at runtime, specify it through the **--auth** option, like this:

`litestore --auth:auth.json`

Once enabled, LiteStore will return HTTP 401 error codes if an invalid token or no token is included in the HTTP Authorization header of the request accessing the resource or HTTP 403 error codes in case an authenticated user does not have a valid scope to access a specified resource.