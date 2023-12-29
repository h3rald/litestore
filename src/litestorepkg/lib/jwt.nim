import openssl, base64, strutils, macros


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

proc base64UrlDecode(encoded: string): string =
    let padding = 4 - (encoded.len mod 4)
    let base64String = encoded.replace("-", "+").replace("_", "/") & repeat("=", padding)
    result = base64.decode(base64String)

proc validateJwtToken*(token: string; x5c: string): bool =
    let parts = token.split(".")
    let sig = parts[2].base64UrlDecode
    let payload = parts[0]&"."&parts[1]
    let cert = x5c.decode
    let alg = EVP_sha256();
    var x509: PX509
    var pubkey: EVP_PKEY
    var pkeyctx: EVP_PKEY_CTX

    ### Validate Signature (Only RS256 supported)
    x509 = d2i_X509(cert)
    if x509.isNil:
        raise newException(ValueError, "Invalid X509 certificate")

    pubkey = X509_get_pubkey(x509)
    if pubkey.isNil:
        raise newException(ValueError, "An error occurred while retrieving the public key")

    let mdctx = EVP_MD_CTX_create()
    if mdctx.isNil:
        raise newException(ValueError, "Unable to initialize MD CTX")

    if EVP_DigestVerifyInit(mdctx, addr pkeyctx, alg, nil, pubkey) != 1:
        raise newException(ValueError, "Unable to initialize digest verification")

    if EVP_DigestVerify_Update(mdctx, addr payload[0], payload.len.cuint) != 1:
        raise newException(ValueError, "Unable to update digest verification")

    if EVP_DigestVerify_Final(mdctx, addr sig[0], sig.len.cuint) != 1:
        raise newException(ValueError, "Verification failed")

    if not mdctx.isNil:
        EVP_MD_CTX_destroy(mdctx)
    if not pkeyctx.isNil:
        EVP_PKEY_CTX_free(pkeyctx)
    #if not pubkey.isNil:
    #  EVP_PKEY_free(pubkey)
    if not x509.isNil:
        X509_free(x509)

    ### TODO: Verify claims
    return true











