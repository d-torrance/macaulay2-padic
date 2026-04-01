newPackage("Padic",
    Headline => "p-adic numbers",
    Version => "0.1",
    Date => "April 2026",
    Authors => {{
	    Name => "Doug Torrance",
	    Email => "dtorrance@piedmont.edu",
	    HomePage => "https://webwork.piedmont.edu/~dtorrance"}},
    Keywords => {"Algebraic Number Theory"})

export {
    -- classes
    "PadicFieldFamily",
    "PadicNumber"}

-- unexported symbols
protect prime

PadicFieldFamily = new Type of InexactFieldFamily
PadicFieldFamily.synonym = "p-adic field family"

expression PadicFieldFamily := kk -> Subscript(QQ, kk.prime)
net PadicFieldFamily := net @@ expression

PadicNumber = new Type of InexactNumber

-- want to use QQ_p, but Ring_ZZ already exists, so overwrite it
oldRingSubZZ = lookup(symbol _, Ring, ZZ)
Ring _ ZZ := (R, p) -> (
    if R =!= QQ then oldRingSubZZ(R, p)
    else (
	if not isPrime p then error "expected a prime number";
	new PadicFieldFamily of PadicNumber from hashTable {symbol prime => p}))
