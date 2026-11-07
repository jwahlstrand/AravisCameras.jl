# AravisCameras.jl

Julia package for using GigE and USB cameras by wrapping [Aravis](https://github.com/AravisProject/aravis), a GObject-based library.

Documentation for the Aravis library can be found [here](https://aravisproject.github.io/aravis/index.html).

This package uses [GI.jl](https://github.com/JuliaGtk/Gtk4.jl/tree/main/GI) to do the wrapping, so it depends on GObjects (the GLib/GObject layer of [Gtk4.jl](https://github.com/JuliaGtk/Gtk4.jl)) rather than on Gtk4 itself. Gtk4 is only needed for the optional `feature_tree` extension.

