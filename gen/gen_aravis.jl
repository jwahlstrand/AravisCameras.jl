using GI
GI.prepend_search_path("/usr/lib64/girepository-1.0")
GI.prepend_search_path("/usr/local/lib64/girepository-1.0")

path="../src/gen"

ns = GINamespace(:Aravis,"0.8")

GI.export_consts!(ns, path, "aravis"; export_constants = false)

## structs and objects

disguised = []
special = []
struct_skiplist=vcat(disguised, special, [])

object_constructor_skiplist=[:new_from_url,:new_access_mode,:new_address,:new_bit,:new_cachable,:new_command_value,
                             :new_constant,:new_description,:new_display_name,:new_endianness,:new_expression,
                             :new_formula,:new_formula_from,:new_formula_to,:new_increment,:new_length,:new_lsb,
                             :new_maximum,:new_minimum,:new_msb,:new_off_value,:new_on_value,:new_chunk_id,
                             :new_p_address,:new_p_command_value,:new_p_feature,:new_p_increment,
                             :new_p_is_available,:new_p_is_implemented,:new_p_is_locked,:new_p_length,
                             :new_p_maximum,:new_p_minimum,:new_p_port,:new_p_value,:new_polling_time,:new_sign,
                             :new_tooltip,:new_unit,:new_value,:new_display_notation,:new_display_precision,
                             :new_event_id,:new_imposed_access_mode,:new_is_linear,:new_p_selected,
                             :new_p_value_default,:new_p_variable,:new_representation,:new_slope,:new_streamable,
                             :new_value_default,:new_visibility, :new_is_deprecated, :new_p_alias, :new_p_cast_alias]
struct_skiplist = GI.export_struct_exprs!(ns,path,"aravis", struct_skiplist, []; object_constructor_skiplist)

object_method_skiplist=[:get_instance, :set_fill_pattern, :acquisition]

GI.export_methods!(ns,path,"aravis"; struct_skiplist, object_method_skiplist, interface_helpers=false)
GI.export_functions!(ns,path,"aravis")

