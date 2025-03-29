using Gtk4, Gtk4.GLib

actions = String[]
entry = GtkEntry()

function on_action_added(group, name)
    println(name)
    push!(actions, name)
end

function on_button_clicked(widget)
    "save" in actions || return
    GLib.G_.activate_action(GActionGroup(remote_action_group), "save", GVariant(entry.text))
end

function activate(app)
    global remote_action_group = GDBusActionGroup(app, "julia.gtk4.aravisapp","/julia/gtk4/aravisapp")
    signal_connect(on_action_added, remote_action_group, "action-added")
    actions = GLib.list_actions(remote_action_group)

    window = GtkApplicationWindow(app, "Test snapshotter")
    box = GtkBox(:v)
    window[] = box

    button = GtkButton("Save a picture")
    push!(box, button)
    push!(box, entry)

    signal_connect(on_button_clicked, button, "clicked")

    show(window)
end

app = GtkApplication("julia.gtk4.example2")

Gtk4.signal_connect(activate, app, :activate)

# When all windows are closed, loop automatically stops running

if isinteractive()
    Gtk4.GLib.stop_main_loop()  # g_application_run will run the loop
    loop()=Gtk4.run(app)
    t = schedule(Task(loop))
else
    Gtk4.run(app)
end
