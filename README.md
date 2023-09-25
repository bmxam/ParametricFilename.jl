# ParametricFilename.jl

Usage :

```julia
import ParametricFilenames as PF

pf = PF.create((:nx, :method), (Int, String))

t = Dict(:nx => 10, :method => "Euler")
@show PF.new_filename(pf, t)

t[:nx] = 20
@show PF.new_filename(pf, t)

@show PF.exists(pf, t)
t[:nx] = 30
@show PF.exists(pf, t)

@show PF.get_filename(pf, t)

t[:nx] = 10
@show PF.get_filename(pf, t)

PF.new_parameter!(pf, :ny, 5)
@show pf

PF.write(pf, "pf.csv")
pf = PF.read("pf.csv")
using DataFrames
@show metadata(pf)
```
