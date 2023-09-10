module ParametricFilenames
using DataFrames
using Random
using CSV

export ParametricFilename, exists, new_filename, get_filename, new_parameter!, get_dataframe

const _PREFIX = :prefix
const _IDENTIFIER = :identifier
const _EXTENSION = :extension
const _DEFAULT_NRANDOM = 4

"""
Almost just a wrapper to `DataFrame`
"""
struct ParametricFilename
    df::DataFrame
    prefix::String
    extension::String
    nrandom::Int
    write_path::String # path to write (automatically) the DataFrame
end
_get_nrandom(pf::ParametricFilename) = pf.nrandom
get_dataframe(pf::ParametricFilename) = pf.df
_get_prefix(pf::ParametricFilename) = pf.prefix
_get_extension(pf::ParametricFilename) = pf.extension
_get_write_path(pf::ParametricFilename) = pf.write_path

"""
`colnames` and `coltypes` must be provided as iterables (`Tuple`, `Vector`, ...) of `Symbol`.
"""
function ParametricFilename(
    colnames,
    coltypes;
    prefix = "",
    extension = "",
    nrandom = _DEFAULT_NRANDOM,
    write_path = "",
)
    d = Dict(name => type[] for (name, type) in zip(colnames, coltypes))
    d[_IDENTIFIER] = String[]
    df = DataFrame(d)
    return ParametricFilename(df, prefix, extension, nrandom, write_path)
end

"""
Build a new random String identifier according to the number of chars of the `ParametricFilename`
"""
_new_identifier(pf::ParametricFilename) = lowercase(randstring(_get_nrandom(pf)))

"""
Tell if the set of parameters values already exist in the database or not.
`t` is a `NamedTuple` of a `Dict`
"""
function exists(pf::ParametricFilename, t)
    query = [name => x -> x .== value for (name, value) in pairs(t)]
    return nrow(subset(get_dataframe(pf), query)) > 0
end

"""
Build a filename from the String identifier and, eventually, the prefix and extension
of the `ParametricFilename`.
"""
function _build_filename(pf::ParametricFilename, id)
    filename = _get_prefix(pf) * id
    ext = _get_extension(pf)
    return length(ext) > 0 ? filename * "." * ext : filename
end

"""
Build a new (unique) filename based on the input parameter values.
`t` is a `NamedTuple` of a `Dict`
"""
function new_filename(pf::ParametricFilename, t)
    @assert !exists(pf, t) "New entry already exists"

    id = _new_identifier(pf)
    if t isa NamedTuple
        # Oups, I can't use `_t = (t..., _IDENTIFIER = id)` here,
        # beause _IDENTIFIER is not interpreted, it because the name...
        _t = (t..., identifier = id)
    elseif t isa Dict
        _t = t
        _t[_IDENTIFIER] = id
    else
        error("$(typeof(t)) not supported yet")
    end

    # Add to dataframe
    push!(get_dataframe(pf), _t)

    # Write dataframe to file if asked
    wpath = _get_write_path(pf)
    (length(wpath) > 0) && write(pf, wpath)

    # Return new name
    return _build_filename(pf, id)
end

"""
Return a filename corresponding to the input parameter values. If the filename does not
exist yet, it is created (and added to the database).
`t` is a `NamedTuple` of a `Dict`
"""
function get_filename(pf::ParametricFilename, t)
    query = [name => x -> x .== value for (name, value) in pairs(t)]
    _df = subset(get_dataframe(pf), query)
    if nrow(_df) > 0
        id = _df[1, _IDENTIFIER]
        return _build_filename(pf, id)
    else
        return new_filename(pf, t)
    end
end

"""
`val` is a unique value (default value) or a vector of values
(one for each row)
"""
function new_parameter!(pf::ParametricFilename, name, value)
    insertcols!(get_dataframe(pf), name => value)
end

function read(
    path;
    prefix = "",
    extension = "",
    nrandom = _DEFAULT_NRANDOM,
    autowrite = false,
)
    df = CSV.read(path, DataFrame)
    wpath = autowrite ? path : ""
    return ParametricFilename(df, prefix, extension, nrandom, wpath)
end

function write(pf::ParametricFilename, path = "")
    _wpath = length(path) > 0 ? path : _get_write_path(pf)
    CSV.write(_wpath, get_dataframe(pf))
end

macro only_if_new(df, filename, f)
    error("In construction")
    _filename = esc(filename)
    _f = esc(f)
    return quote
        $_filename = "after"
        $_f
    end
end

end # module ParametricFilenames
