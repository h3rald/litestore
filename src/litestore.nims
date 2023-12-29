
switch("mm", "refc")
switch("opt", "size")
switch("define", "ssl")
switch("define", "release")
switch("threadAnalysis", "off")

when defined(windows):
    switch("dynlibOverride", "sqlite3_64")
else:
    switch("dynlibOverride", "sqlite3")

when defined(ssl):
    switch("define", "useOpenSsl3")
    when defined(windows):
        # TODO",  change once issue nim#15220 is resolved
        switch("define", "noOpenSSLHacks")
        switch("define", "sslVersion:(")
        switch("dynlibOverride", "ssl-")
        switch("dynlibOverride", "crypto-")
    else:
        switch("dynlibOverride", "ssl")
        switch("dynlibOverride", "crypto")
