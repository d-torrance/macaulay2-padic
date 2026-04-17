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
    "teichmuller",
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
fmpzGetMpz = foreignFunction(flint, "fmpz_get_mpz", void, {mpzT, voidstar})

toFmpz = x -> (
    -- typedef slong fmpz;
    -- typedef fmpz fmpz_t[1];
    y := getMemory size long;
    fmpzInit y;
    registerFinalizer(y, fmpzClear);
    fmpzSetMpz(y, x);
    y)

fromFmpz = x -> (
    y := mpzT 0;
    fmpzGetMpz(y, x);
    value y)

-- fmpq (flint rational type)
fmpqInit = foreignFunction(flint, "fmpq_init", void, voidstar)
fmpqClear = foreignFunction(flint, "fmpq_clear", void, voidstar)
fmpqSetFmpzFrac = foreignFunction(flint, "fmpq_set_fmpz_frac", void,
    {voidstar, voidstar, voidstar})
fmpqGetMpzFrac = foreignFunction(flint, "fmpq_get_mpz_frac", void,
    {mpzT, mpzT, voidstar})

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

fromFmpq = x -> (
    (a, b) := (mpzT 0, mpzT 1);
    fmpqGetMpzFrac(a, b, x);
    value a / value b)

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
padicUnit = foreignFunction(flint, "padic_unit", voidstar, voidstar)
padicGetVal = foreignFunction(flint, "padic_get_val", long, voidstar)
padicGetPrec = foreignFunction(flint, "padic_get_prec", long, voidstar)
padicSetFmpq = foreignFunction(flint, "padic_set_fmpq", void,
    {voidstar, voidstar, voidstar})
padicGetFmpz = foreignFunction(flint, "padic_get_fmpz", void,
    {voidstar, voidstar, voidstar})
padicGetFmpq = foreignFunction(flint, "padic_get_fmpq", void,
    {voidstar, voidstar, voidstar})

newPadic = N -> (
    -- typedef struct {
    --  fmpz u;
    --  slong v;
    --  slong N;
    -- } padic_struct;
    y := getMemory(3 * size long);
    padicInit2(y, N);
    registerFinalizer(y, padicClear);
    y)

padicGetStr = foreignFunction(flint, "padic_get_str", charstar,
    {charstar, voidstar, voidstar})

padicAdd = foreignFunction(flint, "padic_add", void,
    {voidstar, voidstar, voidstar, voidstar})

padicSub = foreignFunction(flint, "padic_sub", void,
    {voidstar, voidstar, voidstar, voidstar})

padicMul = foreignFunction(flint, "padic_mul", void,
    {voidstar, voidstar, voidstar, voidstar})

padicDiv = foreignFunction(flint, "padic_div", void,
    {voidstar, voidstar, voidstar, voidstar})

padicShift = foreignFunction(flint, "padic_shift", void,
    {voidstar, voidstar, long, voidstar})

padicNeg = foreignFunction(flint, "padic_neg", void,
    {voidstar, voidstar, voidstar})

padicInv = foreignFunction(flint, "padic_inv", void,
    {voidstar, voidstar, voidstar})

padicSqrt = foreignFunction(flint, "padic_sqrt", int,
    {voidstar, voidstar, voidstar})

padicPowSi = foreignFunction(flint, "padic_pow_si", void,
    {voidstar, voidstar, long, voidstar})

padicExp = foreignFunction(flint, "padic_exp", int,
    {voidstar, voidstar, voidstar})

padicLog = foreignFunction(flint, "padic_log", int,
    {voidstar, voidstar, voidstar})

padicTeichmuller = foreignFunction(flint, "padic_teichmuller", int,
    {voidstar, voidstar, voidstar})

padicEqual = foreignFunction(flint, "padic_equal", int, {voidstar, voidstar})

padicIsZero = foreignFunction(flint, "padic_is_zero", int, voidstar)

--------------------
-- p-adic numbers --
--------------------

PadicFieldFamily = new Type of RingFamily
PadicFieldFamily.synonym = "p-adic field family"

expression PadicFieldFamily := kk -> Subscript(QQ, kk.prime)
net PadicFieldFamily := net @@ expression

PadicNumber = new Type of Number
PadicNumber.synonym = "p-adic number"

precision PadicNumber := x -> value padicGetPrec x.number

unit = method()
unit PadicNumber := x -> fromFmpz padicUnit x.number

valuation PadicNumber := x -> (
    if x == 0 then infinity
    else value padicGetVal x.number)

prime = method()
prime PadicNumber := x -> (class x).prime

numdigits := x -> floor log(10, x) + 1
toString PadicNumber := x -> (
    (N, v, p) := (precision x, valuation x, prime x);
    if v == infinity then v = 0;
    -- from src/padic/get_str.c
    n := (N - v) * (2 * numdigits p + numdigits max(abs v, abs N) + 5) + 1;
    value padicGetStr(concatenate(n:"\0"), x.number, x.context))

PadicNumber.AfterPrint = lookup(AfterPrint, InexactNumber)

peek'(ZZ, PadicNumber) := lookup(peek', ZZ, HashTable)

describe PadicNumber := x -> describe(unit x * Power(prime x, valuation x))

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

new PadicNumber from (voidstar, voidstar) := (T, ctx, num) -> (
    new T from hashTable {
	symbol context => ctx,
	symbol number => num})
new PadicNumber from (ZZ, Number) := (T, N, x) -> (
    try x _= QQ else x ^= QQ; -- promote/lift to QQ if needed
    ctx := newPadicContext(T.prime, N);
    y := newPadic N;
    padicSetFmpq(y, toFmpq x, ctx);
    new T from (ctx, y))
new PadicNumber from Number := (T, x) -> new T from (20, x)
new PadicNumber from Constant := (T, x) -> new T from numeric x
new PadicNumber from (ZZ, Constant) := (T, N, x) -> new T from (N, numeric x)

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
    padicAdd(z.number, x.number, y.number, z.context);
    z)
PadicNumber + Number := (x, y) -> x + QQ_(prime x) y
Number + PadicNumber := (x, y) -> QQ_(prime y) x + y

PadicNumber - PadicNumber := (x, y) -> (
    z := combinePadics(x, y);
    padicSub(z.number, x.number, y.number, z.context);
    z)
PadicNumber - Number := (x, y) -> x - QQ_(prime x) y
Number - PadicNumber := (x, y) -> QQ_(prime y) x - y

PadicNumber * PadicNumber := (x, y) -> (
    z := combinePadics(x, y);
    padicMul(z.number, x.number, y.number, z.context);
    z)
PadicNumber * Number := (x, y) -> x * QQ_(prime x) y
Number * PadicNumber := (x, y) -> QQ_(prime y) x * y

PadicNumber / PadicNumber := (x, y) -> (
    if y == 0 then error "division by zero";
    z := combinePadics(x, y);
    padicDiv(z.number, x.number, y.number, z.context);
    z)
PadicNumber / Number := (x, y) -> x / QQ_(prime x) y
Number / PadicNumber := (x, y) -> QQ_(prime y) x / y

PadicNumber << ZZ := (x, y) -> (
    z := newPadic precision x;
    padicShift(z, x.number, y, x.context);
    QQ_(prime x)(x.context, z))

(PadicNumber >> ZZ) := (x, y) -> x << -y

-PadicNumber := x -> (
    y := newPadic precision x;
    padicNeg(y, x.number, x.context);
    QQ_(prime x)(x.context, y))

+PadicNumber := identity

abs PadicNumber := x -> (prime x)^(-valuation x)

inverse PadicNumber := x -> (
    if x == 0 then error "division by zero";
    y := newPadic precision x;
    padicInv(y, x.number, x.context);
    QQ_(prime x)(x.context, y))

sqrt PadicNumber := x -> (
    y := newPadic precision x;
    r := value padicSqrt(y, x.number, x.context);
    if r == 1 then QQ_(prime x)(x.context, y)
    else error("not a ", prime x, "-adic square"))

PadicNumber^ZZ := (x, y) -> (
    z := newPadic precision x;
    padicPowSi(z, x.number, y, x.context);
    QQ_(prime x)(x.context, z))

exp PadicNumber := x -> (
    y := newPadic precision x;
    r := value padicExp(y, x.number, x.context);
    if r == 1 then QQ_(prime x)(x.context, y)
    else error(prime x, "-adic exponential function does not converge"))

log PadicNumber := x -> (
    y := newPadic precision x;
    r := value padicLog(y, x.number, x.context);
    if r == 1 then QQ_(prime x)(x.context, y)
    else error(prime x, "-adic logarithm function does not converge"))

teichmuller = method()
teichmuller PadicNumber := x -> (
    if valuation x < 0 then error("expected a ", prime x, "-adic integer");
    y := newPadic precision x;
    padicTeichmuller(y, x.number, x.context);
    QQ_(prime x)(x.context, y))

lift(PadicNumber, ZZ) := o -> (x, kk) -> (
    if valuation x < 0 then error("expected a ", prime x, "-adic integer");
    y := toFmpz 0;
    padicGetFmpz(y, x.number, x.context);
    fromFmpz y)

lift(PadicNumber, QQ) := o -> (x, kk) -> (
    y := toFmpq(0/1);
    padicGetFmpq(y, x.number, x.context);
    fromFmpq y)

ZZ_PadicFieldFamily      :=
QQ_PadicFieldFamily      :=
promote(ZZ, PadicNumber) :=
promote(QQ, PadicNumber) := (x, kk) -> kk x

numeric PadicNumber := x -> numeric x^QQ
numeric(ZZ, PadicNumber) := (prec, x) -> numeric(prec, x^QQ)
interval PadicNumber := o -> x -> interval(x^QQ, o)
interval(PadicNumber, PadicNumber) := o -> (x, y) -> interval(x^QQ, y^QQ, o)
interval(PadicNumber, Number) := o -> (x, y) -> interval(x^QQ, y, o)
interval(Number, PadicNumber) := o -> (x, y) -> interval(x, y^QQ, o)

PadicNumber == PadicNumber := (x, y) -> (
    prime x == prime y and value padicEqual(x.number, y.number) == 1
    or
    -- if primes don't agree, then just compare in QQ
    x^QQ == y^QQ)

PadicNumber == Number := (x, y) -> (
    if y == 0 then value padicIsZero x.number == 1
    else x^QQ == y)
Number == PadicNumber := (x, y) -> y == x

TEST ///
assert Equation(toString QQ_7(12/7), "5*7^-1 + 1")
///

TEST ///
assert Equation(valuation QQ_7 49, 2)
assert Equation(valuation QQ_7 0, infinity)
assert Equation(unit QQ_7 49, 1)
assert Equation(precision QQ_7 49, 20)
///

TEST ///
assert Equation(QQ_7 3 + QQ_7 2, QQ_7 5)
assert Equation(QQ_7 3 - QQ_7 2, QQ_7 1)
assert Equation(QQ_7 3 * QQ_7 2, QQ_7 6)
assert Equation(QQ_2 3 / QQ_2 2, QQ_2 (3/2))
assert Equation(QQ_7 3 << 2, QQ_7(3 * 49))
assert Equation(QQ_7 3 >> 2, QQ_7(3/49))
assert Equation(-QQ_7 3 + QQ_7 3, 0)
assert Equation(+QQ_7 3, QQ_7 3)
assert Equation(QQ_7 3 * inverse QQ_7 3, QQ_7 1)
assert Equation(sqrt QQ_7 4, QQ_7 2)
assert Equation((QQ_7 3)^2, QQ_7 9)
assert Equation(log exp QQ_7 7, QQ_7 7)
t = teichmuller QQ_7 3
assert Equation(t^7 - t, 0)
///

TEST ///
assert Equation(QQ_2 5, QQ_2 5)
assert Equation(QQ_2 5, QQ_3 5)
assert Equation(QQ_2 5, 5)
assert Equation(5, QQ_2 5)
assert BinaryOperation(symbol ===, (QQ_2 5)^ZZ, 5)
assert BinaryOperation(symbol ===, (QQ_2 5)^QQ, 5/1)
assert BinaryOperation(symbol ===, numeric QQ_2 5, 5.0)
assert BinaryOperation(symbol ===, numeric(100, QQ_2 5), 5p100)
assert BinaryOperation(symbol ===, interval QQ_2 5, interval 5)
assert BinaryOperation(symbol ===, interval(QQ_2 5, Precision => 100), interval 5p100)
assert BinaryOperation(symbol ===, interval(QQ_2 5, QQ_2 6), interval(5, 6))
assert BinaryOperation(symbol ===, interval(QQ_2 5, 6), interval(5, 6))
assert BinaryOperation(symbol ===, interval(5, QQ_2 6), interval(5, 6))
///

TEST ///
-- hensel's lemma example (cube root of 2 in QQ_5)
newton = x -> x - (x^3 - 2)/(3*x^2)
x = QQ_5 3
while x != (x = newton x) do null
assert Equation(x^3, 2)
///

end

loadPackage("Padic", FileName => "~/src/macaulay2/macaulay2-padic/Padic.m2", Reload => true)
