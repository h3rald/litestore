import std/[
    openssl, base64, strutils, macros, json, times, pegs, sequtils, os
    ]
import types

when defined(windows) and defined(amd64):
    {.passL: "-static -L"&getProjectPath()&"/litestorepkg/vendor/openssl/windows -lssl -lcrypto -lbcrypt".}
elif defined(linux) and defined(amd64):
    {.passL: "-static -L"&getProjectPath()&"/litestorepkg/vendor/openssl/linux -lssl -lcrypto".}
elif defined(macosx) and defined(amd64):
    {.passL: "-Bstatic -L"&getProjectPath()&"/litestorepkg/vendor/openssl/macosx -lssl -lcrypto -Bdynamic".}


proc X509_get_pubkey(cert: PX509): EVP_PKEY {.cdecl, importc.}
proc EVP_DigestVerifyInit(ctx: EVP_MD_CTX; pctx: ptr EVP_PKEY_CTX; typ: EVP_MD;
        e: ENGINE; pkey: EVP_PKEY): cint {.cdecl, importc.}
proc EVP_DigestVerifyUpdate(ctx: EVP_MD_CTX; data: pointer;
        len: cuint): cint {.cdecl, importc.}
proc EVP_DigestVerifyFinal(ctx: EVP_MD_CTX; data: pointer;
        len: cuint): cint {.cdecl, importc.}

proc getLastError(): string =
    return $ERR_error_string(ERR_get_error(),  nil)

proc raiseJwtError(msg: string) =
    let err = getLastError()
    raise newException(EJwtValidationError, msg&"\n"&err)

proc getX5c*(token: JWT): string =
    let file = getCurrentDir() / "jwks.json"
    if not file.fileExists:
        raise newException(ValueError, "JWKS file not found: " & file)
    let keys = file.readFile.parseJson["keys"]
    if token.header.hasKey("kid"):
        let kid = token.header["kid"].getStr
        return keys.filterIt(it["kid"].getStr == kid)[0]["x5c"][0].getStr
    return keys[0]["x5c"][0].getStr

proc base64UrlDecode(encoded: string): string =
    let padding = 4 - (encoded.len mod 4)
    let base64String = encoded.replace("-", "+").replace("_", "/") & repeat("=", padding)
    result = base64.decode(base64String)

proc newJwt*(token: string): JWT =
    let parts = token.split(".")
    result.token = token
    result.payload = parts[0]&"."&parts[1]
    result.header = parts[0].base64UrlDecode.parseJson
    result.claims = parts[1].base64UrlDecode.parseJson
    result.signature = parts[2].base64UrlDecode

proc verifyTimeClaims*(jwt: JWT) =
    let t = now().toTime.toUnix
    if jwt.claims.hasKey("nbf") and jwt.claims["nbf"].getInt > t:
        raiseJwtError("Token cannot be used yet.")
    if jwt.claims.hasKey("exp") and jwt.claims["exp"].getInt < t:
        raiseJwtError("Token has expired.")

proc verifyAlgorithm*(jwt: JWT) =
    let alg = jwt.header["alg"].getStr
    if alg != "RS256":
        raiseJwtError("Algorithm not supported: " & alg)

proc verifyScope*(jwt: JWT; reqScope: seq[string] = @[]) =
    if reqScope.len == 0:
        return
    var scp = newSeq[string](0)
    if jwt.claims.hasKey("scp"):
        scp = jwt.claims["scp"].getStr.split(peg"\s")
    elif jwt.claims.hasKey("scope"):
        scp = jwt.claims["scope"].getStr.split(peg"\s")
    if scp.len == 0:
        raiseJwtError("No scp or scope claim found in token")
    var authorized = ""
    for s in scp:
        for r in reqScope:
            if r == s:
                authorized = s
                break
    if authorized == "":
        raise newException(EUnauthorizedError, "Unauthorized")

proc verifySignature*(jwt: JWT; x5c: string) =
    let sig = jwt.signature
    let payload = jwt.payload
    let cert = x5c.decode
    let alg = EVP_sha256();
    var x509: PX509
    var pubkey: EVP_PKEY

    ### Validate Signature (Only RS256 supported)
    x509 = d2i_X509(cert)
    if x509.isNil:
        raiseJwtError("Invalid X509 certificate")

    pubkey = X509_get_pubkey(x509)
    if pubkey.isNil:
        raiseJwtError("An error occurred while retrieving the public key")

    var mdctx = EVP_MD_CTX_create()
    if mdctx.isNil:
        raiseJwtError("Unable to initialize MD CTX")

    var pkeyctx = EVP_PKEY_CTX_new(pubkey, nil)
    if pkeyctx.isNil:
        raiseJwtError("Unable to initialize PKEY CTX")
    #var pkeyctx: EVP_PKEY_CTX 

    echo "****************"
    if EVP_DigestVerifyInit(mdctx, addr pkeyctx, alg, nil, pubkey) != 1:
        raiseJwtError("Unable to initialize digest verification")

    if EVP_DigestVerifyUpdate(mdctx, addr payload[0], payload.len.cuint) != 1:
        raiseJwtError("Unable to update digest verification")

    if EVP_DigestVerifyFinal(mdctx, addr sig[0], sig.len.cuint) != 1:
        raiseJwtError("Verification failed")

    if not mdctx.isNil:
        EVP_MD_CTX_destroy(mdctx)
    #if not pkeyctx.isNil:
    #    EVP_PKEY_CTX_free(pkeyctx)
    #if not pubkey.isNil:
    #  EVP_PKEY_free(pubkey)
    if not x509.isNil:
        X509_free(x509)


when isMainModule:

  let token = "token.txt".readFile
  let x5c = "x5c.cert".readFile
  let jwt = token.newJwt

  echo token
  echo "---"
  echo x5c
  jwt.verifySignature(x5c)
