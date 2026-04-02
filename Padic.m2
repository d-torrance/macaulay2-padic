newPackage("Padic",
    Headline => "p-adic numbers",
    Version => "0.1",
    Date => "April 2026",
    Authors => {{
	    Name => "Doug Torrance",
	    Email => "dtorrance@piedmont.edu",
	    HomePage => "https://webwork.piedmont.edu/~dtorrance"}},
    Keywords => {"Algebraic Number Theory"},
    PackageImports => {"ForeignFunctions"})

export {
    -- classes
    "PadicFieldFamily",
    }

-- unexported symbols
protect prime

---------------------
-- FLINT interface --
---------------------

flint = openSharedLibrary "flint"

-- fmpz (flint integer type)
fmpzInit = foreignFunction(flint, "fmpz_init", void, voidstar)
fmpzClear = foreignFunction(flint, "fmpz_clear", void, voidstar)
fmpzSetMpz = foreignFunction(flint, "fmpz_set_mpz", void, {voidstar, mpzT})

toFmpz = x -> (
    -- typedef slong fmpz;
    -- typedef fmpz fmpz_t[1];
    y := getMemory size long;
    fmpzInit y;
    registerFinalizer(y, fmpzClear);
    fmpzSetMpz(y, x);
    y)

-- fmpq (flint rational type)
fmpqInit = foreignFunction(flint, "fmpq_init", void, voidstar)
fmpqClear = foreignFunction(flint, "fmpq_clear", void, voidstar)
fmpqSetFmpzFrac = foreignFunction(flint, "fmpq_set_fmpz_frac", void,
    {voidstar, voidstar, voidstar})

toFmpq = x -> (
    -- typedef struct {
    --     fmpz num;
    --     fmpz den;
    -- } fmpq;
    y := getMemory(2 * size long);
    fmpqInit y;
    registerFinalizer(y, fmpqClear);
    x _= QQ; -- promote to QQ if needed
    fmpqSetFmpzFrac(y, toFmpz numerator x, toFmpz denominator x);
    y)

-- padic_ctx_t
padicCtxInit = foreignFunction(flint, "padic_ctx_init", void,
    {voidstar, voidstar, long, long, int})
padicCtxClear = foreignFunction(flint, "padic_ctx_clear", void, voidstar)

newPadicContext = (p, N) -> (
    -- typedef struct {
    --     fmpz_t p;
    --     double pinv;
    --     fmpz *pow;
    --     slong min;
    --     slong max;
    --     enum padic_print_mode mode;
    -- } padic_ctx_struct;
    ctx := getMemory(4 * size long + size double + size int);
    m := max(0, N - 10);
    M := max(0, N + 10);
    padicCtxInit(ctx, toFmpz p, m, M, 1 -* PADIC_SERIES *-);
    registerFinalizer(ctx, padicCtxClear);
    ctx)

-- padic_t
padicInit2 = foreignFunction(flint, "padic_init2", void, {voidstar, long})
padicClear = foreignFunction(flint, "padic_clear", void, voidstar)
padicSetFmpq = foreignFunction(flint, "padic_set_fmpq", void,
    {voidstar, voidstar, voidstar})

newPadic = (x, N, ctx) -> (
    -- typedef struct {
    --     fmpz u;
    --     slong v;
    --     slong N;
    -- } padic_struct;
    y := getMemory(3 * size long);
    padicInit2(y, N);
    registerFinalizer(y, padicClear);
    padicSetFmpq(y, toFmpq x, ctx);
    y)

padicGetStr = foreignFunction(flint, "padic_get_str", charstar,
    {charstar, voidstar, voidstar})

--------------------
-- p-adic numbers --
--------------------

PadicFieldFamily = new Type of RingFamily
PadicFieldFamily.synonym = "p-adic field family"

expression PadicFieldFamily := kk -> Subscript(QQ, kk.prime)
net PadicFieldFamily := net @@ expression

knownPadicFields = new MutableHashTable

-- want to use QQ_p, but Ring_ZZ already exists, so overwrite it
oldRingSubZZ = lookup(symbol _, Ring, ZZ)
Ring _ ZZ := (R, p) -> (
    if R =!= QQ then oldRingSubZZ(R, p)
    else (
	if not isPrime p then error "expected a prime number";
	knownPadicFields#p ??= (
	    new PadicFieldFamily of Number
	    from hashTable {symbol prime => p})))

end

loadPackage("Padic", FileName => "~/src/macaulay2/macaulay2-padic/Padic.m2", Reload => true)
