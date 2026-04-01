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
    "QQp",
    "PadicFieldFamily",
    "PadicNumber"}

-- unexported symbols
protect prime

---------------------
-- FLINT interface --
---------------------

flint = openSharedLibrary "flint"
fmpzInit = foreignFunction(flint, "fmpz_init", void, voidstar)
fmpzSetMpz = foreignFunction(flint, "fmpz_set_mpz", void, {voidstar, mpzT})
padicCtxInit = foreignFunction(flint, "padic_ctx_init", void,
    {voidstar, voidstar, long, long, int})
padicInit2 = foreignFunction(flint, "padic_init2", void, {voidstar, long})
padicSetFmpz = foreignFunction(flint, "padic_set_fmpz", void,
    {voidstar, voidstar, voidstar})
padicGetStr = foreignFunction(flint, "padic_get_str", charstar,
    {charstar, voidstar, voidstar})

-- typedef struct {
--     fmpz_t p;
--     double pinv;
--     fmpz *pow;
--     slong min;
--     slong max;
--     enum padic_print_mode mode;
-- } padic_ctx_struct;

ctx = getMemory(4 * size long + size double + size int)
p = getMemory voidstar
fmpzInit p
fmpzSetMpz(p, 3)
padicCtxInit(ctx, p, 0, 100, 1)

-- typedef struct {
--     fmpz u;
--     slong v;
--     slong N;
-- } padic_struct;

x = getMemory(3 * size long)
y = getMemory voidstar
fmpzInit y
fmpzSetMpz(y, 3)
padicSetFmpz(x, y, ctx)
padicGetStr("", x, ctx)

--------------------
-- p-adic numbers --
--------------------

QQp = new InexactFieldFamily of InexactNumber
QQp.synonym = "p-adic number"

------------------------------
-- fields of p-adic numbers --
------------------------------

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

end

loadPackage("Padic", FileName => "~/src/macaulay2/macaulay2-padic/Padic.m2", Reload => true)
