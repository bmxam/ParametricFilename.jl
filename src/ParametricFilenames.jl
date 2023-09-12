module ParametricFilenames
using DataFrames
using Random
using CSV

# Constants
const _PREFIX = "prefix"
const _IDENTIFIER = :identifier
const _EXTENSION = "extension"
const _DEFAULT_NRANDOM = 4
const _NRANDOM = "nrandom"
const _WRITE_PATH = "write_path"

_get_nrandom(df::DataFrame) = metadata(df, _NRANDOM)
_get_prefix(df::DataFrame) = metadata(df, _PREFIX)
_get_extension(df::DataFrame) = metadata(df, _EXTENSION)
_get_write_path(df::DataFrame) = metadata(df, _WRITE_PATH)

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

    metadata!(df, _PREFIX, prefix, style = :note)
    metadata!(df, _EXTENSION, extension, style = :note)
    metadata!(df, _NRANDOM, nrandom, style = :note)
    metadata!(df, _WRITE_PATH, write_path, style = :note)

    return df
end

"""
Build a new random String identifier according to the number of chars of the `DataFrame`
"""
_new_identifier(df::DataFrame) = lowercase(randstring(_get_nrandom(df)))

"""
Tell if the set of parameters values already exist in the database or not.
`t` is a `NamedTuple` of a `Dict`
"""
function exists(df::DataFrame, t)
    query = [name => x -> x .== value for (name, value) in pairs(t)]
    return nrow(subset(df, query)) > 0
end

"""
Build a filename from the String identifier and, eventually, the prefix and extension
of the `DataFrame`.
"""
function _build_filename(df::DataFrame, id)
    filename = _get_prefix(df) * id
    ext = _get_extension(df)
    return length(ext) > 0 ? filename * "." * ext : filename
end

"""
Build a new (unique) filename based on the input parameter values.
`t` is a `NamedTuple` of a `Dict`
"""
function new_filename(df::DataFrame, t)
    @assert !exists(df, t) "New entry already exists"

    id = _new_identifier(df)
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
    push!(df, _t)

    # Write dataframe to file if asked
    wpath = _get_write_path(df)
    (length(wpath) > 0) && write(df, wpath)

    # Return new name
    return _build_filename(df, id)
end

"""
Return a filename corresponding to the input parameter values, and a boolean indicating
if this value was preexistent to the function call. If the filename does not
exist yet, it is created (and added to the database).
`t` is a `NamedTuple` of a `Dict`
"""
function get_filename(df::DataFrame, t)
    query = [name => x -> x .== value for (name, value) in pairs(t)]
    _df = subset(df, query)
    if nrow(_df) > 0
        id = _df[1, _IDENTIFIER]
        return _build_filename(df, id), false
    else
        return new_filename(df, t), true
    end
end

"""
`val` is a unique value (default value) or a vector of values
(one for each row)
"""
new_parameter!(df::DataFrame, name, value) = insertcols!(df, name => value)

function read(path; autowrite = false)
    df = CSV.read(path, DataFrame)
    wpath = autowrite ? path : ""
    metadata!(df, _WRITE_PATH, wpath)
    return df
end

function write(df::DataFrame, path = "")
    _wpath = length(path) > 0 ? path : _get_write_path(df)
    CSV.write(_wpath, df)
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

end
