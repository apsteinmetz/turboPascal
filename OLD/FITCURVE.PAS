{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 65500,16384,655360} {Turbo 3 default stack and heap}

program FITCURVE;  {Fits parameters to a discount function using coupon bond
                    prices.  Uses the simplex algorithm.  Requires an input
                    file with bond data.}

{!USES!}

const   memo =
        'Function:  Pt = exp[B * t* (1-exp(-a * t)) + g * t]';
        memo2 =
        'Parameters are: a, b, g ';

        m          = 3;    {number of parameters to fit}
        nvpp       = 2;    {total number of variables per data point}
        n          = 4;    {m + 1}
        mnp        = 200;  {maximum number of data points}
        lw         = 5;    {width of line in data fields +1}
        alfa       = 1.0;  {reflection coefficient}
        beta       = 0.5;  {contraction coefficient}
        gamma      = 2.0;  {expansion coefficient}

        page       = 12;
        root2      = 1.414214;

type    vector     = array[1..n] of real;
        BondData    = record
                       Price,
                       Accrued,
                       FirstTime,
                       CpnFact,
                       Yield,
                       weight,
                       Coupon    :  real;
                       FlowCount :  integer;
                     end;

        index      = 0..255;
        anystr     = string[12];


var     done       : boolean;   {convergence}
        i,j        : index;
        h,l        : array[1..n] of index; {number high/low parameters}
        np,                    {number of data points}
        maxiter,
        OldX, OldY,
        niter      : integer;
        next,                {next vertex to be tested}
        center,              {center of hyperplane described by all
                              vertices of the simplex excluding the
                              worst}
        mean, error,
        maxerr,
        p,q,                 {to compute first simplex}
        step        : vector;  {input starting steps}
        simp        : array[1..n] of vector;     {the simplex}
        Bond        : array[1..mnp] of BondData;
        answer,
        FName       : anystr;                    {filename}
        FileToRead,
        Outfile     : text;                      {input,output}
        TimeIn,
        ElapsedTime : real;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

function f (x : vector; B: BondData) : real;
         { x(1..m) the parameters, B has the Bond}
var  Time,
     DiscSum,
     AdjCoup  :  real;
     i        :  index;

  begin
     DiscSum := 0.0;
     with B do
        begin
           for i := 1 to FlowCount do
              begin
                 if i = 1 then AdjCoup := Coupon * CpnFact
                 else AdjCoup := Coupon;
                 if i = FlowCount then AdjCoup := Coupon + 100;
                 Time    := FirstTime + 0.5 * (i-1);
                 DiscSum := DiscSum + AdjCoup *
                          exp(-Time * (x[2] * (1-exp(-x[1]*Time)) + x[3]));
              end;
        end;
     f := DiscSum
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function Power(base,raise : real) : real;

begin
   Power  := exp(ln(base) * raise)
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
function BondPrice ( B: BondData) : real;
         { B has the Bond}
var  Time,
     DiscSum,
     AdjCoup  :  real;
     i        :  index;

  begin
     DiscSum := 0.0;
     with B do
        begin
           for i := 1 to FlowCount do
              begin
                 if i = 1 then AdjCoup := Coupon * CpnFact
                 else AdjCoup := Coupon;
                 if i = FlowCount then AdjCoup := Coupon + 100;
                 Time    := FirstTime + 0.5 * (i-1);
                 DiscSum := DiscSum + AdjCoup / power(1+Yield/2,Time);
              end;
        end;
     BondPrice := DiscSum - B.Accrued;
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure ComputeWeights;
                           {the weights are the reciprocal of}
                           {each bond's price multiplier     }
                           {adjusted so they sum to one (1)  }

  var   i         : index;
        SumWeight,
        PriceUp,
        PriceDn   : real;
  begin
    SumWeight := 0.0;
    for i := 1 to np do
          with Bond[i] do
           begin
             Yield   := Yield - 0.001;
             PriceUp   := BondPrice(Bond[i]);
             Yield   := Yield + 0.002;
             PriceDn := BondPrice(Bond[i]);
             weight := 1 / (PriceUp - PriceDn);
             Yield := Yield - 0.001;           {restore original Yield}
             SumWeight := SumWeight + weight;
           end;
    for i := 1 to np do
          with Bond[i] do
           begin
             weight := weight / SumWeight;
           end

  end;


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
procedure SumOfResiduals (var x :vector);
          {computes sum of the squared residuals}
          {x(1..m) passes the parameters. Result returned in x(n)}

  var   i      : index;
  begin
    x[n] := 0.0;
    for i := 1 to np do
        begin
           x[n] := x[n] +
               Bond[i].weight * sqr(f(x,Bond[i]) - Bond[i].Price);
        end
  end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

{Includes utility subroutines during compliation}

{$I Date.sub}
