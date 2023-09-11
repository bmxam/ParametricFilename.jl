# ParametricFilename.jl

Usage :

```julia
using ParametricFilenames
pf = ParametricFilename((:nx, :method), (Int, String))

t = Dict(:nx => 10, :method => "Euler")
@show new_filename(pf, t)

t[:nx] = 20
@show new_filename(pf, t)

@show exists(pf, t)
t[:nx] = 30
@show exists(pf, t)

@show get_filename(pf, t)

t[:nx] = 10
@show get_filename(pf, t)

new_parameter!(pf, :ny, 5)
@show get_dataframe(pf)

ParametricFilenames.write(pf, "pf.csv")
pf = ParametricFilenames.read("pf.csv")
```
