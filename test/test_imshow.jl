using Gtk4, Gtk4.GLib
using AravisCameras
using ImageView

# Pops up a window for selecting a camera, captures a single image and shows it using ImageView

function startup(app)
    update_device_list()
    n_dev = AravisCameras.n_devices()
    if n_dev == 0
        @info("No cameras found")
        Gtk4.GLib.quit(app)
    end

    global cam_list = GtkListStore(Int, String)
    for i=1:n_dev
        push!(cam_list, (i, AravisCameras.device_id(i-1)))
    end
end

function activate(app)
    tv = GtkTreeView(GtkTreeModel(cam_list))
    renderer = GtkCellRendererText()
    column = GtkTreeViewColumn("Camera ID", renderer, Dict([("text",1)]))
    push!(tv, column)

    selection_window = GtkApplicationWindow(app, "Select camera")

    box = GtkBox(:v)
    push!(box, tv)
    
    button_box = GtkBox(:h)
    push!(box, button_box)

    ok_button = GtkButton("Open")
    push!(button_box, ok_button)
    
    spinner = GtkSpinner()
    push!(button_box, spinner)

    function on_ok_clicked(b)
        sel = Gtk4.selection(tv)
        if !hasselection(sel)
            return
        end
        name = cam_list[selected(sel)][2]

        global camera = ArvCamera(name)
        global stream = AravisCameras.create_stream(camera)
        if stream !== nothing
            stream.packet_timeout = 20*1000
            stream.frame_retention = 100*1000
            payload = AravisCameras.payload(camera)
            push!(stream, ArvBuffer(payload))
        else
            @warn("failed to create stream")
            return nothing
        end

        AravisCameras.G_.set_pixel_format(camera, AravisCameras.PIXEL_FORMAT_RGB_8_PACKED)
        AravisCameras.G_.gv_set_packet_size(camera, 1500)
        AravisCameras.G_.set_frame_rate(camera, 10)
        AravisCameras.G_.set_exposure_time(camera,500000)
        AravisCameras.G_.set_acquisition_mode(camera, AravisCameras.AcquisitionMode_CONTINUOUS)
        AravisCameras.G_.start_acquisition(camera)
        
        global buf = pop!(stream)
        while AravisCameras.G_.get_status(buf) != AravisCameras.BufferStatus_SUCCESS
            println(AravisCameras.G_.get_status(buf))
            push!(stream, buf)
            println("attempting to get another buffer")
            global buf = pop!(stream)
        end
        img = AravisCameras.image(buf)
        imshow(img)
        AravisCameras.G_.stop_acquisition(camera)
    end
    
    Gtk4.signal_connect(on_ok_clicked, ok_button, :clicked)

    selection_window[] = box

    show(selection_window)
end

function shutdown(app)
    AravisCameras.G_.stop_acquisition(camera)
    AravisCameras.G_.shutdown()
end

app = GtkApplication("julia.aravis.example",
        Gtk4.GLib.ApplicationFlags_FLAGS_NONE)

if isinteractive()
    Gtk4.GLib.stop_main_loop()  # g_application_run will run the loop
end

Gtk4.signal_connect(startup, app, :startup)
Gtk4.signal_connect(activate, app, :activate)
Gtk4.signal_connect(shutdown, app, :shutdown)

if isinteractive()
    loop()=Gtk4.run(app)
    t = schedule(Task(loop))
else
    Gtk4.run(app)
end
