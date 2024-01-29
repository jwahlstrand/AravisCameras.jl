function feature_tree(gc, visibility)
    node = G_.get_node(gc,"Root")
    features = G_.get_features(node)
    f=GList{GLib._GSList{String},String}(features,false)
    categories = collect(f)
    
    rootmodel = GtkStringList(categories)

    function create_model(obj)
        node2 = G_.get_node(gc,obj.string)
        if node2 isa ArvGcCategory && visibility <= G_.get_visibility(node2)
            features2 = G_.get_features(node2)
            f2=GList{GLib._GSList{String},String}(features2,false)
            fs = collect(f2)
            modelValues = GtkStringList(fs)
            GLib.glib_ref(modelValues)
            return modelValues.handle
        else
            return C_NULL
        end
    end
    
    GtkTreeListModel(GListModel(rootmodel),false, true, create_model)
end

