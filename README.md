# AravisCameras.jl

Julia package for using GigE and USB cameras by wrapping [Aravis](https://github.com/AravisProject/aravis), a GObject-based library.

This package uses [GI.jl](https://github.com/JuliaGtk/Gtk4.jl/tree/main/GI) to do the wrapping, so it depends on [Gtk4.jl](https://github.com/JuliaGtk/Gtk4.jl). In the future, GLib functionality could be split off into a different package. File an issue if that is of interest to you.

