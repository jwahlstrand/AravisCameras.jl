using Gtk4, Gtk4.GLib
using AravisCameras, ImageIO, FileIO

const winref = Ref{GtkApplicationWindowLeaf}()
entry::GtkEntryLeaf = GtkEntry()

if isinteractive()
    Gtk4.GLib.stop_main_loop()  # g_application_run will run the loop
end

function on_save(a,v)
    s = v[String]
    if s == ""
        s = entry.text
    end
    if s == ""
        @warn("filename is empty")
        return
    end
    fname = if endswith(s, ".png")
        s
    else
        s*".png"
    end
    buf = AravisCameras.acquisition(cam, 1000000) # 1 sec timeout
    if buf !== nothing
        img = AravisCameras.image(buf)
        FileIO.save(fname, img)
    else
        @warn("Unable to acquire")
    end
end

function on_quit(a,v)
    close(winref[])
end

# callback to be called when application is "activated"
function activate(app)
    if length(ARGS) > 1
        println("too many args")
        return
    end
    update_device_list()
    n_dev = AravisCameras.n_devices()
    if n_dev == 0
        @warn("No cameras found")
        return
    end
    if length(ARGS) == 0
        global cam = ArvCamera(AravisCameras.device_id(0))
    else
        found = false
        for i=1:n_dev
            global cam = ArvCamera(AravisCameras.device_id(i-1))
            if contains(AravisCameras.G_.get_device_id(i-1), ARGS[1])
                found = true
                break
            end
        end
        if !found
            @warn("No matching camera found")
            return
        end
    end

    add_action(GActionMap(app), "quit", on_quit)
    add_action(GActionMap(app), "save", String, on_save)
    win = GtkApplicationWindow(app, "Aravis snapshotter")
    b=GtkBox(:v)
    push!(b, entry)
    button = GtkButton("Save"; action_name = "app.save", action_target = GVariant(""))
    push!(b,button)
    win[]=b
    winref[] = win
    show(winref[])
end

# create application -- argument is the application id, which is optional
const app = GtkApplication("julia.gtk4.aravisapp")

Gtk4.signal_connect(activate, app, :activate)

if isinteractive()
    loop()=Gtk4.run(app)
    t = schedule(Task(loop))
else
    Gtk4.run(app)
end
