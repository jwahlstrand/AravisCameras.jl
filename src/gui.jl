_get_node(n, v) = C_NULL
function _get_node(n::ArvGcCategory, visibility)
    if visibility <= G_.get_visibility(n)
        features2 = G_.get_features(n)
        fs = collect(features2)
        modelValues = GtkStringList(fs)
        GLib.glib_ref(modelValues)
        return modelValues.handle
    else
        return C_NULL
    end
end

function feature_tree(gc, visibility)
    node = G_.get_node(gc,"Root")
    features = G_.get_features(node)
    categories = collect(features)
    
    rootmodel = GtkStringList(categories)

    function create_model(obj)
        node2 = G_.get_node(gc,obj.string)
        return _get_node(node2, visibility)
    end
    
    GtkTreeListModel(GListModel(rootmodel),false, true, create_model)
end

function feature_list_setup_cb(f, li)
    tree_expander = GtkTreeExpander()
    b = GtkCenterBox(:h; hexpand=true)
    b[:start] = GtkLabel("")
    set_child(tree_expander,b)
    set_child(li,tree_expander)
    nothing
end

function fillbox(box, node)
    access = G_.get_actual_access_mode(node)
    if access == GcAccessMode_RW
        fillbox_rw(box, node)
    elseif access == GcAccessMode_RO
        fillbox_ro(box, node)
    elseif access == GcAccessMode_WO
        fillbox_wo(box, node)
    end
end
fillbox_ro(box, node) = nothing
fillbox_rw(box, node) = nothing
function fillbox_wo(box, node)
    box[:end] = GtkLabel("Write only")
end
function _bool_toggled(bptr, node)
    b=convert(GtkToggleButton,bptr)
    if G_.get_value(node) != b.active
        G_.set_value(node, b.active)
    end
    nothing
end
function fillbox_rw(box, node::ArvGcBoolean)
    checkbutton = GtkCheckButton()
    box[:end] = checkbutton
    box[:end].active = G_.get_value(node)
    Gtk4.on_toggled(_bool_toggled, checkbutton, node)
end
function fillbox_ro(box, node::ArvGcBoolean)
    box[:end] = GtkLabel(G_.get_value(node) ? "true" : "false")
end
_command_clicked(bptr, node) = G_.execute(node)
function fillbox_rw(box, node::ArvGcCommand)
    b = GtkButton("Execute")
    box[:end] = b
    Gtk4.on_clicked(_command_clicked, b, node)
end
fillbox_wo(box, node::ArvGcCommand) = fillbox_rw(box, node)
function fillbox_ro(box, node::ArvGcStringNode)
    box[:end] = GtkLabel(G_.get_value(ArvGcString(node)))
end
function fillbox_ro(box, node::ArvGcStringRegNode)
    box[:end] = GtkLabel(G_.get_value(ArvGcString(node)))
end
function _enum_selected(ddptr, pars, node)
    dd=convert(GtkDropDown,ddptr)
    str = Gtk4.selected_string(dd)
    G_.set_value(ArvGcString(node), str)
    nothing
end
function fillbox_rw(box, node::ArvGcEnumeration)
    try
        vals = G_.dup_available_string_values(node)
        dd = GtkDropDown(vals)
        Gtk4.selected_string!(dd,G_.get_value(ArvGcString(node)))
        Gtk4.GLib.on_notify(_enum_selected, dd, "notify::selected", node)
        box[:end] = dd
    catch e
    end
end
function fillbox_ro(box, node::ArvGcEnumeration)
    try
        box[:end] = GtkLabel(G_.get_value(ArvGcString(node)))
    catch e
    end
end
function _int_changed(sbptr, node)
    sb = convert(GtkSpinButton, sbptr)::GtkSpinButtonLeaf
    val = Gtk4.G_.get_value_as_int(sb)
    G_.set_value(ArvGcInteger(node), val)
    nothing
end
function fillbox_rw(box, node::ArvGcIntegerNode)
    if !G_.is_implemented(node)
        return
    end
    try
        v = G_.get_value(ArvGcInteger(node))
        mn = G_.get_min(ArvGcInteger(node))
        mx = G_.get_max(ArvGcInteger(node))
        step = try
            G_.get_inc(ArvGcInteger(node))
        catch e2
            1.0
        end
        sb = GtkSpinButton(mn, mx, step)
        Gtk4.G_.set_value(sb, v)
        box[:end] = sb
        Gtk4.on_value_changed(_int_changed,sb,node)
    catch e
        println("error during int:", e)
    end
end
function fillbox_ro(box, node::ArvGcIntegerNode)
    box[:end] = GtkLabel(string(G_.get_value(ArvGcInteger(node))))
end
function _float_changed(sbptr, node)
    sb = convert(GtkSpinButton, sbptr)::GtkSpinButtonLeaf
    val = Gtk4.G_.get_value(sb)
    G_.set_value(ArvGcInteger(node), val)
    nothing
end
function fillbox_rw(box, node::ArvGcFloatNode)
    try
        v = G_.get_value(ArvGcFloat(node))
        mn = G_.get_min(ArvGcFloat(node))
        mx = G_.get_max(ArvGcFloat(node))
        step = try
            G_.get_inc(ArvGcFloat(node))
        catch e2
            1.0
        end
        sb = GtkSpinButton(mn, mx, step)
        Gtk4.G_.set_value(sb, v)
        box[:end] = sb
        Gtk4.on_value_changed(_float_changed, sb, node)
    catch e
        println("error during float:", e)
    end
end
function fillbox_ro(box, node::ArvGcFloatNode)
    box[:end] = GtkLabel(string(G_.get_value(ArvGcFloat(node))))
end

const Visibility = (AravisCameras.GcVisibility_BEGINNER, AravisCameras.GcVisibility_EXPERT, AravisCameras.GcVisibility_GURU)

function visibility_dropdown()
    GtkDropDown(["Beginner","Expert","Guru"])
end
