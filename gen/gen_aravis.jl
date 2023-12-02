using GI
GI.prepend_search_path("/usr/lib64/girepository-1.0")
GI.prepend_search_path("/usr/local/lib64/girepository-1.0")

toplevel, exprs, exports = GI.output_exprs()

path="../src/gen"

ns = GINamespace(:Aravis,"0.8")

## constants, enums, and flags

const_mod = Expr(:block)

const_exports = Expr(:export)

c = GI.all_const_exprs!(const_mod, const_exports, ns; skiplist= [])
push!(const_mod.args, const_exports)

push!(exprs, const_mod)

## export constants, enums, and flags code
GI.write_to_file(path,"aravis_consts",toplevel)

## structs and objects

toplevel, exprs, exports = GI.output_exprs()

GI.all_objects!(exprs,exports,ns,skiplist=[],constructor_skiplist=[:new_from_url,:new_access_mode,:new_address,:new_bit,:new_cachable,:new_command_value,:new_constant,:new_description,:new_display_name,:new_endianness,:new_expression,:new_formula,:new_formula_from,:new_formula_to,:new_increment,:new_length,:new_lsb,:new_maximum,:new_minimum,:new_msb,:new_off_value,:new_on_value,:new_chunk_id,:new_p_address,:new_p_command_value,:new_p_feature,:new_p_increment,:new_p_is_available,:new_p_is_implemented,:new_p_is_locked,:new_p_length,:new_p_maximum,:new_p_minimum,:new_p_port,:new_p_value,:new_polling_time,:new_sign,:new_tooltip,:new_unit,:new_value,:new_display_notation,:new_display_precision,:new_event_id,:new_imposed_access_mode,:new_is_linear,:new_p_selected,:new_p_value_default,:new_p_variable,:new_representation,:new_slope,:new_streamable,:new_value_default,:new_visibility])

disguised = []
special = []
struct_skiplist=vcat(disguised, special, [])

struct_skiplist = GI.all_struct_exprs!(exprs,exports,ns;excludelist=struct_skiplist)
GI.all_callbacks!(exprs, exports, ns)

push!(exprs,exports)

GI.write_to_file(path,"aravis_structs",toplevel)

## struct methods

toplevel, exprs, exports = GI.output_exprs()

GI.all_struct_methods!(exprs,ns,struct_skiplist=vcat(struct_skiplist,[]);print_detailed=true)

## object methods

objects=GI.get_all(ns,GI.GIObjectInfo)

object_skiplist=[]

skiplist=[:get_instance, :set_fill_pattern, :get_value]

GI.all_object_methods!(exprs,ns;skiplist=skiplist,object_skiplist=object_skiplist,interface_helpers=false)

GI.write_to_file(path,"aravis_methods",toplevel)

## functions

toplevel, exprs, exports = GI.output_exprs()

GI.all_functions!(exprs,ns,skiplist=skiplist)

GI.write_to_file(path,"aravis_functions",toplevel)
