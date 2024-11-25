module AravisCameras

using Gtk4
using Gtk4.GLib
using ColorTypes, FixedPointNumbers

using Glib_jll

using CEnum, BitFlags, Aravis_jll

export update_device_list

import Base: push!, pop!, length, unsafe_convert

eval(include("gen/aravis_consts"))
eval(include("gen/aravis_structs"))

module G_

using Glib_jll, Aravis_jll

using Gtk4.GLib, Gtk4
using ..AravisCameras
import AravisCameras: AccessCheckPolicy, AcquisitionMode, Auto, BufferPartDataType, BufferPayloadType, BufferStatus, ChunkParserError, ComponentSelectionFlags, DeviceError, DomNodeType, ExposureMode, GcAccessMode, GcCachable, GcDisplayNotation, GcError, GcIsLinear, GcNameSpace, GcPropertyNodeType, GcRepresentation, GcSignedness, GcStreamable, GcVisibility, GvIpConfigurationMode, GvPacketSizeAdjustment, GvStreamPacketResend, GvStreamSocketBuffer, RangeCheckPolicy, RegisterCachePolicy, StreamCallbackType, UvUsbMode, XmlSchemaError, GvInterfaceFlags, GvStreamOption

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

function get_data!(img::Vector{UInt8}, instance::ArvBuffer)
    m_size = Ref{UInt64}()
    ret = ccall(("arv_buffer_get_data", libaravis), Ptr{UInt8}, (Ptr{GObject}, Ptr{UInt64}), instance, m_size)
    ret2 = unsafe_wrap(Vector{UInt8}, ret, m_size[])
    copyto!(img, ret2)
    nothing
end

bits_per_pixel(format) = ((format >> 16) & 0xff)

const colortypes = Dict(PIXEL_FORMAT_BAYER_RG_8 => RGB{N0f8},
                        PIXEL_FORMAT_BAYER_RG_12 => RGB{N4f12},
                        PIXEL_FORMAT_MONO_8 => N0f8,
                        PIXEL_FORMAT_MONO_10 => N6f10,
                        PIXEL_FORMAT_MONO_12 => N4f12,
                        PIXEL_FORMAT_MONO_14 => N2f14)

function colortype(b::ArvBuffer)
    format = image_pixel_format(b)
    get(colortypes, format, nothing)
end

function imagearray(b::ArvBuffer)
    format = image_pixel_format(b)
    if format === nothing
        return nothing
    end
    w=G_.get_image_width(b)
    h=G_.get_image_height(b)
    if format == PIXEL_FORMAT_BAYER_RG_8 || format == PIXEL_FORMAT_BAYER_RG_12
        w = w ÷ 2
        h = h ÷ 2
    end
    Array{colortype(b)}(undef, w, h)
end

function rg_convert!(img::Array{RGB{T}},d,w,h) where T
    d2=reinterpret(T,reshape(d,(w,h)))
    for i=1:(w ÷ 2)
        for j=1:(h ÷ 2)
            img[i,j]=RGB{T}(d2[2*i-1,2*j-1],(float(d2[2*i-1,2*j])+float(d2[2*i,2*j-1]))/2,d2[2*i,2*j])
        end
    end
end

Base.size(b::ArvBuffer) = (G_.get_image_width(b), G_.get_image_height(b))

function image!(img, b::ArvBuffer)
    d=G_.get_data(b)
    w=G_.get_image_width(b)
    h=G_.get_image_height(b)
    format = image_pixel_format(b)
    if format == PIXEL_FORMAT_BAYER_RG_8
        @assert length(d) == w*h
        rg_convert!(img, d2, w, h)
    elseif format == PIXEL_FORMAT_BAYER_RG_12
        d2=reinterpret(UInt16,d)
        rg_convert!(img, d3, w, h)
    elseif format == PIXEL_FORMAT_RGB_8_PACKED
        copyto!(img, reshape(reinterpret(RGB{N0f8},d),(w,h)))
    elseif format == PIXEL_FORMAT_MONO_8
        @assert length(d) == w*h
        copyto!(img, reinterpret(N0f8,reshape(d,(w,h))))
    elseif format == PIXEL_FORMAT_MONO_12
        if length(d) != 2*w*h
            println("size issue: length(d) = $(length(d)) but 2*w*h = $(2*w*h)")
            return nothing
        end
        d2=reinterpret(UInt16,d)
        for i=1:w*h
            img[i]=reinterpret(N4f12, d2[i])
        end
    else
        println("length: $(length(d)), $w, $h")
        error("Pixel format $format not supported.")
    end
    nothing
end


function image(b::ArvBuffer)
    d=G_.get_data(b)
    w=G_.get_image_width(b)
    h=G_.get_image_height(b)
    format = image_pixel_format(b)
    if format == PIXEL_FORMAT_BAYER_RG_8
        length(d) != w*h && error("For PIXEL_FORMAT_BAYER_RG_8, expected $(w*h) bytes, got $(length(d)) bytes")
        img = Array{RGB{N0f8}}(undef,w ÷ 2,h ÷ 2)
        rg_convert!(img, d, w, h)
    elseif format == PIXEL_FORMAT_BAYER_RG_12
        d2=reinterpret(UInt16,d)
        img = Array{RGB{N4f12}}(undef,w ÷ 2,h ÷ 2)
        rg_convert!(img, d2, w, h)
    elseif format == PIXEL_FORMAT_RGB_8_PACKED
        img = copy(reshape(reinterpret(RGB{N0f8},d),(w,h)))
    elseif format == PIXEL_FORMAT_MONO_8
        length(d) != w*h && error("For PIXEL_FORMAT_MONO_8, expected $(w*h) bytes, got $(length(d)) bytes")
        img = copy(reinterpret(N0f8,reshape(d,(w,h))))
    elseif format == PIXEL_FORMAT_MONO_12
        length(d) != 2*w*h && error("For PIXEL_FORMAT_MONO_12, expected $(2*w*h) bytes, got $(length(d)) bytes")
        d2=reinterpret(UInt16,d)
        img = Array{N4f12}(undef, w, h)
        for i=1:w*h
            img[i]=reinterpret(N4f12, d2[i])
        end
    else
        println("length: $(length(d)), $w, $h")
        error("Pixel format $format not supported.")
    end
    img
end

function acquisition(instance::ArvCamera, _timeout::Integer)
    err = err_buf()
    ret = ccall(("arv_camera_acquisition", libaravis), Ptr{GObject}, (Ptr{GObject}, UInt64, Ptr{Ptr{GError}}), instance, _timeout, err)
    check_err(err)
    convert_if_not_null(ArvBuffer, ret, true)
end
acquisition(instance::ArvCamera) = acquisition(instance, 0)

include("gui.jl")

function __init__()
    gtype_wrapper_cache_init()
end

end
