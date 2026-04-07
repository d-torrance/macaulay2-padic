newPackage("Padic",
    Headline => "p-adic numbers",
    Version => "0.1",
    Date => "April 2026",
    Authors => {{
	    Name => "Doug Torrance",
	    Email => "dtorrance@piedmont.edu",
	    HomePage => "https://webwork.piedmont.edu/~dtorrance"}},
    Keywords => {"Algebraic Number Theory"},
    PackageImports => {"ForeignFunctions", "Valuations"})

export {
    -- methods
    "prime",
    "unit",

    -- classes
    "PadicNumber",
    "PadicFieldFamily",
    }

exportFrom(Valuations, "valuation")

-- unexported symbols
protect context

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
    fmpqSetFmpzFrac(y, toFmpz numerator x, toFmpz denominator x);
    y)

-- padic_ctx_t
padicCtxInit = foreignFunction(flint, "padic_ctx_init", void,
    {voidstar, voidstar, long, long, int})
padicCtxClear = foreignFunction(flint, "padic_ctx_clear", void, voidstar)

newPadicContext = memoize((p, N) -> (
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
	ctx))

-- padic_t
padicInit2 = foreignFunction(flint, "padic_init2", void, {voidstar, long})
padicClear = foreignFunction(flint, "padic_clear", void, voidstar)
padicSetFmpq = foreignFunction(flint, "padic_set_fmpq", void,
    {voidstar, voidstar, voidstar})

padicStruct = foreignStructType("padic_struct", {
	"u" => long,
	"v" => long,
	"N" => long})

newPadic = N -> (
    y := getMemory size padicStruct;
    padicInit2(y, N);
    registerFinalizer(y, padicClear);
    y)

padicGetStr = foreignFunction(flint, "padic_get_str", charstar,
    {charstar, voidstar, voidstar})

padicAdd = foreignFunction(flint, "padic_add", void,
    {voidstar, voidstar, voidstar, voidstar})

--------------------
-- p-adic numbers --
--------------------

PadicFieldFamily = new Type of RingFamily
PadicFieldFamily.synonym = "p-adic field family"

expression PadicFieldFamily := kk -> Subscript(QQ, kk.prime)
net PadicFieldFamily := net @@ expression

PadicNumber = new Type of Number
PadicNumber.synonym = "p-adic number"

precision PadicNumber := x -> value (padicStruct * x.value)_"N"

unit = method()
unit PadicNumber := x -> value (padicStruct * x.value)_"u"

valuation PadicNumber := x -> value (padicStruct * x.value)_"v"

prime = method()
prime PadicNumber := x -> (class x).prime

numdigits := x -> floor log(10, x) + 1
toString PadicNumber := x -> (
    (N, v, p) := (precision x, valuation x, prime x);
    -- from src/padic/get_str.c
    n := (N - v) * (2 * numdigits p + numdigits max(abs v, abs N) + 5) + 1;
    value padicGetStr(concatenate(n:"\0"), x.value, x.context))

PadicNumber.AfterPrint = lookup(AfterPrint, InexactNumber)

peek'(ZZ, PadicNumber) := lookup(peek', ZZ, HashTable)

knownPadicFields = new MutableHashTable

-- want to use QQ_p, but Ring_ZZ already exists, so overwrite it
oldRingSubZZ = lookup(symbol _, Ring, ZZ)
Ring _ ZZ := (R, p) -> (
    if R =!= QQ then oldRingSubZZ(R, p)
    else (
	if not isPrime p then error "expected a prime number";
	knownPadicFields#p ??= (
	    new PadicFieldFamily of PadicNumber
	    from hashTable {symbol prime => p})))

new PadicNumber from (voidstar, voidstar) := (T, ctx, val) -> (
    new T from hashTable {
	symbol context => ctx,
	symbol value => val})
new PadicNumber from (ZZ, Number) := (T, N, x) -> (
    x _= QQ; -- promote to QQ if needed
    ctx := newPadicContext(T.prime, N);
    y := newPadic N;
    padicSetFmpq(y, toFmpq x, ctx);
    new T from (ctx, y))
new PadicNumber from Number := (T, x) -> new T from (20, x)

PadicFieldFamily Thing := (T, x) -> new T from x

----------------
-- operations --
----------------

combinePadics = (x, y) -> (
    p := prime x;
    if p != prime y then error "expected elements of the same field";
    N := min(precision x, precision y);
    ctx := newPadicContext(p, N);
    val := newPadic N;
    QQ_p(ctx, val))

PadicNumber + PadicNumber := (x, y) -> (
    z := combinePadics(x, y);
    padicAdd(z.value, x.value, y.value, z.context);
    z)

TEST ///
assert Equation(toString QQ_7(12/7), "5*7^-1 + 1")
///

end

loadPackage("Padic", FileName => "~/src/macaulay2/macaulay2-padic/Padic.m2", Reload => true)
