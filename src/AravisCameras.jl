module AravisCameras

using Gtk4
using Gtk4.GLib

using Glib_jll

using CEnum, BitFlags, Aravis_jll

export update_device_list

import Base: push!, pop!

eval(include("gen/aravis_consts"))
eval(include("gen/aravis_structs"))

module G_

using Glib_jll, Aravis_jll

using Gtk4.GLib, Gtk4
using ..AravisCameras

eval(include("gen/aravis_methods"))
eval(include("gen/aravis_functions"))

end

let skiplist = [:device_id,
                :interface_flags,
                :string] # conflicts with Base exports
    for func in filter(x->startswith(string(x),"get_"),Base.names(G_,all=true))
        ms=methods(getfield(AravisCameras.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.isgetter(m) || continue
            eval(GLib.gen_getter(func,v,m))
        end
    end

    for func in filter(x->startswith(string(x),"set_"),Base.names(G_,all=true))
        ms=methods(getfield(AravisCameras.G_,func))
        v=Symbol(string(func)[5:end])
        v in skiplist && continue
        for m in ms
            GLib.issetter(m) || continue
            eval(GLib.gen_setter(func,v,m))
        end
    end
end

n_devices() = G_.get_n_devices()
device_id(i) = G_.get_device_id(i)
update_device_list() = G_.update_device_list()

ArvCamera(name::AbstractString) = G_.Camera_new(name)

push!(s::ArvStream, b::ArvBuffer) = (G_.push_buffer(s, b); s)

function ArvStreamCallback(user_data, typ, buffer)
    f = user_data
    ret = f(typ, buffer)
    nothing
end

function create_stream(cam::ArvCamera)
    ret = ccall(("arv_camera_create_stream_full", libaravis), Ptr{GObject}, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Ptr{GError}}), cam, C_NULL, C_NULL, C_NULL, C_NULL)
    ArvStreamLeaf(ret, true)
end

function create_stream(cam::ArvCamera, callback::Function)
    cfunc = @cfunction(ArvStreamCallback, Cvoid, (Ref{Function}, Cint, Ptr{GObject}))
    ref, deref = GLib.gc_ref_closure(match)
    ret = ccall(("arv_camera_create_stream_full", libaravis), Ptr{GObject}, (Ptr{GObject}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Ptr{GError}}), cam, cfunc, ref, deref, C_NULL)
    ArvStreamLeaf(ret, true)
end

# GI-generated versions don't return nothing if NULL
function pop!(s::ArvStream)
    ret = ccall(("arv_stream_pop_buffer", libaravis), Ptr{GObject}, (Ptr{GObject},), s)
    convert(ArvBuffer, ret, true)
end

function try_pop_buffer(instance::ArvStream)
    ret = ccall(("arv_stream_try_pop_buffer", libaravis), Ptr{GObject}, (Ptr{GObject},), instance)
    if ret == C_NULL
        return nothing
    end
    convert(ArvBuffer, ret, false)
end

function __init__()
    gtype_wrapper_cache_init()
end

end
