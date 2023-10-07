using Gtk4, Gtk4.GLib
using AravisCameras

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

    function on_ok_clicked(b)
        sel = Gtk4.selection(tv)
        if !hasselection(sel)
            return
        end
        name = cam_list[selected(sel)][2]

        global camera = ArvCamera(name)

        width, height = AravisCameras.sensor_size(camera)
        mps = AravisCameras.G_.gv_auto_packet_size(camera)
        ps = AravisCameras.G_.gv_get_packet_size(camera)
        println("sensor size: $width, $height")
        println("auto_packet_size: $mps")
        println("packet size: $ps")

        global stream = AravisCameras.create_stream(camera)
        if stream !== nothing
            stream.packet_timeout = 20*1000
            stream.frame_retention = 100*1000
            payload = AravisCameras.payload(camera)
            push!(stream, ArvBuffer(payload))
        end

        AravisCameras.G_.start_acquisition(camera)
        buf = pop!(stream)
        img = AravisCameras.G_.get_data(buf)
        println("image size: $(size(img))")
        imwidth = AravisCameras.image_width(buf)
        imheight = AravisCameras.image_height(buf)
        format = AravisCameras.image_pixel_format(buf)
        payload_type = AravisCameras.payload_type(buf)
        println("image width and height: $imwidth, $imheight")
        println("image format: $format")
        println("payload type: $payload_type")
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
