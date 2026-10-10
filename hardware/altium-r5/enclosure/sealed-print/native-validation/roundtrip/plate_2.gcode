; HEADER_BLOCK_START
; BambuStudio 02.07.01.57
; model printing time: 41m 18s; total estimated time: 48m 19s
; total layer number: 35
; total filament length [mm] : 1781.86
; total filament volume [cm^3] : 4285.87
; total filament weight [g] : 5.31
; model label id: 7,8,9,10,11,12,13,14,15
; object max height: 1.20,1.20,1.20,7.00,7.00,7.00,7.00,7.00,7.00
; filament_density: 1.27,1.24
; filament_diameter: 1.75,1.75
; max_z_height: 7.00
; filament: 2
; HEADER_BLOCK_END

; CONFIG_BLOCK_START
; accel_to_decel_enable = 0
; accel_to_decel_factor = 50%
; activate_air_filtration = 0,0
; additional_cooling_fan_speed = 0,70
; additional_fan_full_speed_layer = 0,0
; alternate_extra_wall = 0
; apply_scarf_seam_on_circles = 1
; auxiliary_fan = 1
; avoid_crossing_wall_includes_support = 0
; bed_custom_model = 
; bed_custom_texture = 
; bed_exclude_area = 
; bed_temperature_formula = by_first_filament
; before_layer_change_gcode = 
; best_object_pos = 0.5,0.5
; bottom_color_penetration_layers = 3
; bottom_shell_layers = 6
; bottom_shell_thickness = 0
; bottom_surface_density = 100%
; bottom_surface_pattern = monotonic
; bridge_angle = 0
; bridge_flow = 1
; bridge_no_support = 0
; bridge_speed = 25
; brim_object_gap = 0.1
; brim_type = no_brim
; brim_width = 5
; chamber_temperatures = 0,0
; change_filament_gcode = ;======== P2S filament_change gcode ==========\n;===== 2026/05/15 =====\n\nM620 S[next_filament_id]A\nM204 S9000\n{if toolchange_count > 1 && (z_hop_types[current_filament_id] == 0 || z_hop_types[current_filament_id] == 3)}\nG17\nG2 Z{z_after_toolchange + 0.4} I0.86 J0.86 P1 F10000 ; spiral lift a little from second lift\n{endif}\n\n;nozzle_change_gcode\n\nG1 Z{max_layer_z + 3.0} F1200\n\nM400\nM106 P1 S0\n\n{if toolchange_count == 2}\n; get travel path for change filament\n;M620.1 X[travel_point_1_x] Y[travel_point_1_y] F21000 P0\n;M620.1 X[travel_point_2_x] Y[travel_point_2_y] F21000 P1\n;M620.1 X[travel_point_3_x] Y[travel_point_3_y] F21000 P2\n{endif}\n\n{if ((filament_type[current_filament_id] == \"PLA\") || (filament_type[current_filament_id] == \"PLA-CF\") || (filament_type[current_filament_id] == \"PETG\")) && (nozzle_diameter_at_nozzle_id[current_nozzle_id] == 0.2)}\nM620.10 A0 F74.8347 L[flush_length] H{nozzle_diameter_at_nozzle_id[current_nozzle_id]} T{flush_temperatures[current_filament_id]} P[old_filament_temp] S1\n{else}\nM620.10 A0 F{flush_volumetric_speeds[current_filament_id]/2.4053*60} L[flush_length] H{nozzle_diameter_at_nozzle_id[current_nozzle_id]} T{flush_temperatures[current_filament_id]} P[old_filament_temp] S1\n{endif}\n\n{if ((filament_type[next_filament_id] == \"PLA\") || (filament_type[next_filament_id] == \"PLA-CF\") || (filament_type[next_filament_id] == \"PETG\")) && (nozzle_diameter_at_nozzle_id[next_nozzle_id] == 0.2)}\nM620.10 A1 F74.8347 L[flush_length] H{nozzle_diameter_at_nozzle_id[next_nozzle_id]} T{flush_temperatures[next_filament_id]} P[new_filament_temp] S1\n{else}\nM620.10 A1 F{flush_volumetric_speeds[next_filament_id]/2.4053*60} L[flush_length] H{nozzle_diameter_at_nozzle_id[next_nozzle_id]} T{flush_temperatures[next_filament_id]} P[new_filament_temp] S1\n{endif}\n\nM620.15 C{new_filament_temp - filament_cooling_before_tower[next_filament_id]}\n\n{if long_retraction_when_cut}\nM620.11 P1 L0 I[current_filament_id] E-{retraction_distance_when_cut} F{max((flush_volumetric_speeds[current_filament_id]/2.4053*60), 200)}\n{else}\nM620.11 P0 L0 I[current_filament_id] E0\n{endif}\n\nM620.11 K0 I[current_filament_id] R0\n\n\nT[next_filament_id]\n\n;deretract\n{if filament_type[next_filament_id] == \"TPU\"}\n{else}\n{if filament_type[next_filament_id] == \"PA\"}\n;VG1 E1 F{max(new_filament_e_feedrate, 200)}\n;VG1 E1 F{max(new_filament_e_feedrate/2, 100)}\n{else}\n;VG1 E4 F{max(new_filament_e_feedrate, 200)}\n;VG1 E4 F{max(new_filament_e_feedrate/2, 100)}\n{endif}\n{endif}\n\n; VFLUSH_START\n{if flush_length>41.5}\n;VG1 E41.5 F{min(old_filament_e_feedrate,new_filament_e_feedrate)}\n;VG1 E{flush_length-41.5} F{new_filament_e_feedrate}\n{else}\n;VG1 E{flush_length} F{min(old_filament_e_feedrate,new_filament_e_feedrate)}\n{endif}\nSYNC T{ceil(flush_length / 80) * 5}\n; VFLUSH_END\n\nM1002 set_filament_type:{filament_type[next_filament_id]}\n\nM400\nM83\n{if next_filament_id < 255}\nM620.10 R{retract_length_toolchange[filament_map[next_filament_id]-1]}\nM628 S0\n;VM109 S[new_filament_temp]\n\nM629\nM400\nM983.3 F{filament_max_volumetric_speed[next_filament_id]/2.4} A0.4 R{retract_length_toolchange[filament_map[next_filament_id]-1]}\nM400\nG1 Y247 F30000\nG1 Y217 F18000\n\nG1 Z{max_layer_z + 3.0} F3000\n{if layer_z <= (initial_layer_print_height + 0.001)}\nM204 S[initial_layer_acceleration]\n{else}\nM204 S[travel_acceleration]\n{endif}\n\n{else}\nG1 X[x_after_toolchange] Y[y_after_toolchange] Z[z_after_toolchange] F12000\n{endif}\n\nM621 S[next_filament_id]A\n\nM622.1 S0 ;for prev version, default skip\nM1002 judge_flag powerloss_resume_flag\nM622 J1\nM983.3 F{filament_max_volumetric_speed[next_filament_id]/2.4} A0.4 R{retract_length_toolchange[filament_map[next_filament_id]-1]}\nM400\nG1 Y247 F30000\nG1 Y217 F18000\nG1 Z{max_layer_z + 3.0} F3000\n{if layer_z <= (initial_layer_print_height + 0.001)}\nM204 S[initial_layer_acceleration]\n{else}\nM204 S[travel_acceleration]\n{endif}\nM1002 set_flag powerloss_resume_flag=0\nM623\n\n{if (filament_type[next_filament_id] == \"PLA\") ||  (filament_type[next_filament_id] == \"PETG\")\n ||  (filament_type[next_filament_id] == \"PLA-CF\")  ||  (filament_type[next_filament_id] == \"PETG-CF\")}\nM1015.4 S1 K1 H{nozzle_diameter_at_nozzle_id[next_nozzle_id]} ;enable E air printing detect\n{else}\nM1015.4 S0 K0 H{nozzle_diameter_at_nozzle_id[next_nozzle_id]} ;disable E air printing detect\n{endif}\n\nM620.6 I[next_filament_id] W1 ;enable ams air printing detect\n\nG1 Y256 F18000\n\n{if (overall_chamber_temperature < 40)}\n{if (layer_num + 1 <= close_additional_fan_first_x_layers[next_filament_id])}\n    {if (min_vitrification_temperature <= 50)}\n        M106 P2 S{first_x_layer_fan_speed[next_filament_id]*255.0/100.0 };set first x_layer aux fan\n    {endif}\n{elsif (layer_num + 1 < additional_fan_full_speed_layer[next_filament_id] && additional_fan_full_speed_layer[next_filament_id] > close_additional_fan_first_x_layers[next_filament_id])}\n    {if (min_vitrification_temperature <= 50)}\n        M106 P2 S{(first_x_layer_fan_speed[next_filament_id] + (additional_cooling_fan_speed[next_filament_id] - first_x_layer_fan_speed[next_filament_id]) * (layer_num + 1 - close_additional_fan_first_x_layers[next_filament_id]) / max(additional_fan_full_speed_layer[next_filament_id] - close_additional_fan_first_x_layers[next_filament_id], 1)) * 255.0/100.0}\n    {endif}\n{else}\n    {if (min_vitrification_temperature <= 50)}\n        {if (nozzle_diameter_at_nozzle_id[current_nozzle_id] == 0.2)}\n            M142 P1 R30 S40 U{max_additional_fan/100.0} V1.0 O45; set PLA/TPU ND0.2 chamber autocooling\n        {else}\n            M142 P1 R30 S40 U{max_additional_fan/100.0} V1.0 O45; set PLA/TPU ND0.4 chamber autocooling\n        {endif}\n    {endif}\n{endif}\n{endif}\n\nM622.1 S0\nM1002 judge_flag ventobox_replace_aux1_fan_flag\nM622 J0\n{if (layer_num + 1 <= close_additional_fan_first_x_layers[next_filament_id])}\n    M106 P10 S{first_x_layer_fan_speed[next_filament_id]*255.0/100.0 };set first x_layer left aux fan\n{elsif (layer_num + 1 < additional_fan_full_speed_layer[next_filament_id] && additional_fan_full_speed_layer[next_filament_id] > close_additional_fan_first_x_layers[next_filament_id])}\n    M106 P10 S{(first_x_layer_fan_speed[next_filament_id] + (additional_cooling_fan_speed[next_filament_id] - first_x_layer_fan_speed[next_filament_id]) * (layer_num + 1 - close_additional_fan_first_x_layers[next_filament_id]) / max(additional_fan_full_speed_layer[next_filament_id] - close_additional_fan_first_x_layers[next_filament_id], 1)) * 255.0/100.0}\n{else}\n    M106 P10 S{additional_cooling_fan_speed[next_filament_id]*255.0/100.0};set left aux fan\n{endif}\nM623\n\n;not set fan changing filament
; circle_compensation_manual_offset = 0
; circle_compensation_speed = 200,200
; close_additional_fan_first_x_layers = 3,1
; close_fan_the_first_x_layers = 3,1
; compatible_printers_condition = 
; complete_print_exhaust_fan_speed = 70,70
; cool_plate_temp = 0,30
; cool_plate_temp_initial_layer = 0,30
; cooling_filter_enabled = 0
; cooling_perimeter_transition_distance = 10,10
; cooling_slowdown_logic = uniform_cooling,uniform_cooling
; counter_coef_1 = 0,0
; counter_coef_2 = 0.008,0.008
; counter_coef_3 = -0.041,-0.041
; counter_limit_max = 0.033,0.033
; counter_limit_min = -0.035,-0.035
; curr_bed_type = Textured PEI Plate
; default_acceleration = 3000
; default_filament_colour = ""
; default_filament_profile = "Bambu PLA Basic @BBL P2S"
; default_jerk = 0
; default_nozzle_volume_type = Standard
; default_print_profile = 0.20mm Standard @BBL P2S
; deretraction_speed = 30
; detect_floating_vertical_shell = 1
; detect_narrow_internal_solid_infill = 1
; detect_overhang_wall = 1
; detect_thin_wall = 0
; diameter_limit = 50,50
; different_settings_to_system = ;;;
; draft_shield = disabled
; during_print_exhaust_fan_speed = 70,70
; elefant_foot_compensation = 0.1
; embedding_wall_into_infill = 0
; enable_arc_fitting = 1
; enable_circle_compensation = 0
; enable_filament_dynamic_map = 0
; enable_height_slowdown = 0
; enable_long_retraction_when_cut = 2
; enable_mixed_color_sublayer = 0
; enable_order_independent_overlap_carving = 0
; enable_overhang_bridge_fan = 1
; enable_overhang_speed = 1
; enable_pre_heating = 0
; enable_pressure_advance = 0
; enable_prime_tower = 0
; enable_support = 0
; enable_support_ironing = 0
; enable_tower_interface_features = 0
; enable_wrapping_detection = 0
; enforce_support_layers = 0
; eng_plate_temp = 70,35
; eng_plate_temp_initial_layer = 70,35
; ensure_vertical_shell_thickness = enabled
; exclude_object = 1
; extruder_ams_count = 
; extruder_clearance_dist_to_rod = 36.5
; extruder_clearance_height_to_lid = 141.5
; extruder_clearance_height_to_rod = 32.5
; extruder_clearance_max_radius = 72
; extruder_colour = #018001
; extruder_max_nozzle_count = 1
; extruder_nozzle_stats = 
; extruder_offset = 0x0
; extruder_printable_area = 
; extruder_type = Direct Drive
; extruder_variant_list = "Direct Drive Standard,Direct Drive High Flow"
; fan_cooling_layer_time = 30,100
; fan_direction = right
; fan_max_speed = 90,100
; fan_min_speed = 40,100
; filament_adaptive_volumetric_speed = 0,0
; filament_adhesiveness_category = 300,600
; filament_bridge_speed = 25,25
; filament_change_length = 10,10
; filament_change_length_nc = 10
; filament_colour = #2A414A;#58BFB5
; filament_cooling_before_tower = 10,10
; filament_cost = 30,20
; filament_density = 1.27,1.24
; filament_dev_ams_drying_ams_limitations = 1;1;1
; filament_dev_ams_drying_heat_distortion_temperature = 75,45
; filament_dev_ams_drying_temperature = 65,65,55,55,65,75,45,45
; filament_dev_ams_drying_time = 12,12,12,12,12,18,12,18
; filament_dev_chamber_drying_bed_temperature = 80,90
; filament_dev_chamber_drying_time = 12,16
; filament_dev_drying_cooling_temperature = 55,40
; filament_dev_drying_softening_temperature = 60,50
; filament_diameter = 1.75,1.75
; filament_enable_overhang_speed = 1,1
; filament_end_gcode = "; filament end gcode \n\n";"; filament end gcode \n\n"
; filament_extruder_compatibility = 0,0
; filament_extruder_variant = "Direct Drive Standard";"Direct Drive Standard"
; filament_flow_ratio = 0.95,1
; filament_flush_temp = 0,0
; filament_flush_temp_fast = 0,0
; filament_flush_volumetric_speed = 0,0
; filament_ids = GFG99;GFU99
; filament_is_mixed = 0
; filament_is_support = 0,0
; filament_map = 1,1
; filament_map_2 = 0,0
; filament_map_mode = Auto For Flush
; filament_max_volumetric_speed = 8,2
; filament_metal_stickiness = High,High
; filament_minimal_purge_on_wipe_tower = 15,15
; filament_mixed_components = ""
; filament_mixed_gradient = 0
; filament_mixed_gradient_curve = ""
; filament_mixed_gradient_per_part = 0
; filament_mixed_gradient_range = ""
; filament_mixed_sublayer_ratios = ""
; filament_notes = 
; filament_nozzle_map = 0,0
; filament_overhang_1_4_speed = 0,0
; filament_overhang_2_4_speed = 50,50
; filament_overhang_3_4_speed = 30,30
; filament_overhang_4_4_speed = 10,10
; filament_overhang_totally_speed = 10,10
; filament_pre_cooling_temperature = 0,0
; filament_pre_cooling_temperature_nc = 0,0
; filament_preheat_temperature_delta = 10,10
; filament_prime_volume = 45,45
; filament_prime_volume_nc = 60,60
; filament_printable = 3,3
; filament_ramming_travel_time = 0,0
; filament_ramming_travel_time_nc = 0,0
; filament_ramming_volumetric_speed = -1,-1
; filament_ramming_volumetric_speed_nc = -1,-1
; filament_retract_length_nc = 14,14
; filament_retraction_length = nil,0.4
; filament_scarf_gap = 0%,0%
; filament_scarf_height = 10%,10%
; filament_scarf_length = 10,10
; filament_scarf_seam_type = none,none
; filament_self_index = 1,2
; filament_settings_id = "Generic PETG @BBL P2S";"Generic TPU @BBL P2S"
; filament_shrink = 100%,100%
; filament_soluble = 0,0
; filament_start_gcode = "; filament start gcode\n";"; filament start gcode\n"
; filament_tower_interface_pre_extrusion_dist = 10,10
; filament_tower_interface_pre_extrusion_length = 0,0
; filament_tower_interface_print_temp = -1,-1
; filament_tower_interface_purge_volume = 20,20
; filament_tower_ironing_area = 4,4
; filament_type = PETG;TPU
; filament_velocity_adaptation_factor = 1,1
; filament_vendor = Generic;Generic
; filament_volume_map = 0,0
; filename_format = {input_filename_base}_{filament_type[0]}_{print_time}.gcode
; fill_multiline = 1
; filter_out_gap_fill = 0
; first_layer_print_sequence = 0
; first_x_layer_fan_speed = 0,40
; first_x_layer_part_fan_speed = 0
; flush_into_infill = 0
; flush_into_objects = 0
; flush_into_support = 1
; flush_multiplier = 1
; flush_multiplier_fast = 1.2
; flush_volumes_matrix = 0,439,197,0
; flush_volumes_vector = 140,140,140,140,140,140,140,140
; full_fan_speed_layer = 0,0
; fuzzy_skin = none
; fuzzy_skin_first_layer = 0
; fuzzy_skin_mode = displacement
; fuzzy_skin_noise_type = classic
; fuzzy_skin_octaves = 4
; fuzzy_skin_persistence = 0.5
; fuzzy_skin_point_distance = 0.8
; fuzzy_skin_scale = 1
; fuzzy_skin_thickness = 0.3
; gap_infill_speed = 250
; gcode_add_line_number = 0
; gcode_flavor = marlin
; grab_length = 0
; group_algo_with_time = 0
; has_filament_switcher = 0
; has_scarf_joint_seam = 0
; head_wrap_detect_zone = 
; hole_coef_1 = 0,0
; hole_coef_2 = -0.008,-0.008
; hole_coef_3 = 0.23415,0.23415
; hole_limit_max = 0.22,0.22
; hole_limit_min = 0.088,0.088
; hot_plate_temp = 70,35
; hot_plate_temp_initial_layer = 70,35
; hotend_cooling_rate = 2
; hotend_heating_rate = 2
; impact_strength_z = 10,10
; independent_support_layer_height = 1
; infill_combination = 0
; infill_direction = 45
; infill_instead_top_bottom_surfaces = 0
; infill_jerk = 9
; infill_lock_depth = 1
; infill_rotate_step = 0
; infill_shift_step = 0.4
; infill_wall_overlap = 15%
; inherits_group = ;;;
; initial_layer_acceleration = 500
; initial_layer_flow_ratio = 1
; initial_layer_infill_speed = 25
; initial_layer_jerk = 9
; initial_layer_line_width = 0.5
; initial_layer_print_height = 0.2
; initial_layer_speed = 20
; initial_layer_travel_acceleration = 6000
; inner_wall_acceleration = 0
; inner_wall_jerk = 9
; inner_wall_line_width = 0.45
; inner_wall_speed = 80
; interface_shells = 0
; interlocking_beam = 0
; interlocking_beam_layer_count = 2
; interlocking_beam_width = 0.8
; interlocking_boundary_avoidance = 2
; interlocking_depth = 2
; interlocking_orientation = 22.5
; internal_bridge_support_thickness = 0.8
; internal_solid_infill_line_width = 0.42
; internal_solid_infill_pattern = zig-zag
; internal_solid_infill_speed = 80
; ironing_direction = 45
; ironing_fan_speed = -1
; ironing_flow = 10%
; ironing_inset = 0.21
; ironing_pattern = zig-zag
; ironing_spacing = 0.15
; ironing_speed = 30
; ironing_type = no ironing
; is_infill_first = 0
; layer_change_gcode = ;======== P2S layer_change gcode ==========\n;===== 2026/05/15 ====\n\n{if (layer_num + 1 == 1)}\n{if (overall_chamber_temperature >= 40)}\n    ;not reset filter fan in first layer\n    ;not reset fan\n{else}\n{if (min_vitrification_temperature > 50)}\n    ;not reset filter fan in first layer\n    ;not reset fan\n{endif}\n{endif}\n{endif}\n\n{if (layer_num + 1 <= close_additional_fan_first_x_layers[current_filament_id])}\n{if (overall_chamber_temperature < 40)}\n    {if (min_vitrification_temperature <= 50)}\n        M106 P2 S{first_x_layer_fan_speed[current_filament_id]*255.0/100.0}\n    {endif}\n{endif}\n    M622.1 S0\n    M1002 judge_flag ventobox_replace_aux1_fan_flag\n    M622 J0\n    M106 P10 S{first_x_layer_fan_speed[current_filament_id]*255.0/100.0}; set first x_layer left aux fan\n    M623\n;not reset fan\n{elsif (layer_num + 1 < additional_fan_full_speed_layer[current_filament_id] && additional_fan_full_speed_layer[current_filament_id] > close_additional_fan_first_x_layers[current_filament_id])}\n{if (overall_chamber_temperature < 40)}\n    {if (min_vitrification_temperature <= 50)}\n        M106 P2 S{(first_x_layer_fan_speed[current_filament_id] + (additional_cooling_fan_speed[current_filament_id] - first_x_layer_fan_speed[current_filament_id]) * (layer_num + 1 - close_additional_fan_first_x_layers[current_filament_id]) / max(additional_fan_full_speed_layer[current_filament_id] - close_additional_fan_first_x_layers[current_filament_id], 1)) * 255.0/100.0}\n    {endif}\n{endif}\n    M622.1 S0\n    M1002 judge_flag ventobox_replace_aux1_fan_flag\n    M622 J0\n    M106 P10 S{(first_x_layer_fan_speed[current_filament_id] + (additional_cooling_fan_speed[current_filament_id] - first_x_layer_fan_speed[current_filament_id]) * (layer_num + 1 - close_additional_fan_first_x_layers[current_filament_id]) / max(additional_fan_full_speed_layer[current_filament_id] - close_additional_fan_first_x_layers[current_filament_id], 1)) * 255.0/100.0}\n    M623\n;not reset fan\n{elsif (layer_num + 1 == max(close_additional_fan_first_x_layers[current_filament_id] + 1, additional_fan_full_speed_layer[current_filament_id]))}\n{if (overall_chamber_temperature < 40)}\n    ;updata chamber autocooling in Xth layer\n    {if (min_vitrification_temperature <= 50)}\n        {if (nozzle_diameter_at_nozzle_id[current_nozzle_id] == 0.2)}\n            M142 P1 R30 S40 U{max_additional_fan/100.0} V1.0 O45; set PLA/TPU ND0.2 chamber autocooling\n        {else}\n            M142 P1 R30 S40 U{max_additional_fan/100.0} V1.0 O45; set PLA/TPU ND0.4 chamber autocooling\n        {endif}\n    {else}\n            ;not reset filter fan in Xth layer\n    {endif}\n{else}\n        ;not reset filter fan in Xth layer\n{endif}\n    M622.1 S0\n    M1002 judge_flag ventobox_replace_aux1_fan_flag\n    M622 J0\n    M106 P10 S{additional_cooling_fan_speed[current_filament_id]*255.0/100.0}; set left aux fan\n    M623\n;not reset fan\n{endif}\n\n; update layer progress\nM73 L{layer_num+1}\nM991 S0 P{layer_num} ;notify layer change\n\n
; layer_height = 0.2
; line_width = 0.42
; locked_skeleton_infill_pattern = zigzag
; locked_skin_infill_pattern = crosszag
; long_retractions_when_cut = 0
; long_retractions_when_ec = 0,0
; machine_bed_mass_Y = 0
; machine_end_gcode = ;======== P2S end gcode ==========\n;===== 2026/05/18 =====\nM400 ; wait for buffer to clear\nG92 E0 ; zero the extruder\nM211 Z1\n\nG90\nG1 Z{max_layer_z + 0.4} F900 ; lower z a little\nM1002 judge_flag timelapse_record_flag\nM622 J1\n    G150.3\n    M400 ; wait all motion done\n    M991 S0 P-1 ;end smooth timelapse at safe pos\n    M400 S5 ;wait for last picture to be taken\nM623  ;end of \"timelapse_record_flag\n\nG90\nG1 Z{max_layer_z + 10} F900 ; lower z a little\n\nM140 S0 ; turn off bed\nM106 S0 ; turn off fan\nM106 P2 S0 ; turn off remote part cooling fan\nM106 P3 S0 ; turn off chamber cooling fan\nM106 P10 S0 ; turn off left aux fan\n\n; pull back filament to AMS\nM620 S65535\nT65535\nG150.1 F8000\nM621 S65535\n\nG150.3\nM104 S0 ; turn off hotend\nM400 ; wait all motion done\nM17 S\nM17 Z0.4 ; lower z motor current to reduce impact if there is something in the bottom\n{if (80.0 - max_layer_z/2) > 0}\n    {if (max_layer_z + 80.0 - max_layer_z/2) < 256}\n        G1 Z{max_layer_z + 80.0 - max_layer_z/2} F600\n        G1 Z{max_layer_z + 78.0 - max_layer_z/2}\n    {else}\n        G1 Z256 F600\n        G1 Z256\n    {endif}\n{else}\n    {if (max_layer_z + 4.0) < 256}\n        G1 Z{max_layer_z + 4.0} F600\n        G1 Z{max_layer_z + 2.0}\n    {else}\n        G1 Z256 F600\n        G1 Z256\n    {endif}\n{endif}\nM400 P100\nM17 R ; restore z current\n\n\nM220 S100  ; Reset feedrate magnitude\nM201.2 K1.0 ; Reset acc magnitude\nM73.2 R1.0 ;Reset left time magnitude\nM1002 set_gcode_claim_speed_level : 0\n\nM1015.3 S0 ;disable clog detect\nM1015.4 S0 K0 ;disable air printing detect\n\n;=====printer finish air purification=========\nM622.1 S0\nM1002 judge_flag print_finish_air_filt_flag\n\nM622 J1\nM1002 gcode_claim_action : 66\nM145 P1\nM106 P2 S255\nM400 S180\nM106 P2 S0\nM623\n\nM622 J2\nM1002 gcode_claim_action : 66\nM145 P0\nM106 P3 S255\nM400 S180\nM106 P3 S0\nM623\n;=====printer finish air purification=========\n\n;=====printer finish  sound=========\nM17\nM400 S1\nM1006 S1\nM1006 A53 B10 L50 C53 D10 M50 E53 F10 N50 \nM1006 A57 B10 L50 C57 D10 M50 E57 F10 N50 \nM1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 \nM1006 A53 B10 L50 C53 D10 M50 E53 F10 N50 \nM1006 A57 B10 L50 C57 D10 M50 E57 F10 N50 \nM1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 \nM1006 A48 B10 L50 C48 D10 M50 E48 F10 N50 \nM1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 \nM1006 A60 B10 L50 C60 D10 M50 E60 F10 N50 \nM1006 W\n;=====printer finish  sound=========\nM400\nM18\n
; machine_hotend_change_time = 0
; machine_load_filament_time = 26
; machine_max_acceleration_e = 5000,5000
; machine_max_acceleration_extruding = 20000,20000
; machine_max_acceleration_retracting = 5000,5000
; machine_max_acceleration_travel = 10000,10000
; machine_max_acceleration_x = 20000,20000
; machine_max_acceleration_y = 20000,20000
; machine_max_acceleration_z = 500,500
; machine_max_force_Y = 0
; machine_max_jerk_e = 2.5,2.5
; machine_max_jerk_x = 9,9
; machine_max_jerk_y = 9,9
; machine_max_jerk_z = 3,3
; machine_max_printed_mass = 0
; machine_max_speed_e = 30,30
; machine_max_speed_x = 600,600
; machine_max_speed_y = 600,600
; machine_max_speed_z = 20,20
; machine_min_extruding_rate = 0
; machine_min_travel_rate = 0
; machine_pause_gcode = M400 U1
; machine_prepare_compensation_time = 370
; machine_start_gcode = ;M1002 set_flag extrude_cali_flag=1\n;M1002 set_flag g29_before_print_flag=1\n;M1002 set_flag auto_cali_toolhead_offset_flag=1\n;M1002 set_flag build_plate_detect_flag=1\n\n;======== P2S start gcode==========\n;===== 2026/05/18 =====\n\n  M140 S[bed_temperature_initial_layer_single] ; heat heatbed first\n  M993 A0 B0 C0 ; nozzle cam detection not allowed.\n  M400\n\n;=====printer start sound ===================\nM17\nM400 S1\nM1006 S1\nM1006 A53 B9 L50 C53 D9 M50 E53 F9 N50\nM1006 A56 B9 L50 C56 D9 M50 E56 F9 N50\nM1006 A61 B9 L50 C61 D9 M50 E61 F9 N50\nM1006 A53 B9 L50 C53 D9 M50 E53 F9 N50\nM1006 A56 B9 L50 C56 D9 M50 E56 F9 N50\nM1006 A61 B18 L50 C61 D18 M50 E61 F18 N50\nM1006 W\n;=====printer start sound ===================\n\n  M620 M ;enable remap\n  G389\n\n;===== avoid end stop =================\n  G91\n  G380 S2 Z22 F1200\n  G380 S2 Z-12 F1200\n  G90\n;===== avoid end stop =================\n\n;===== reset machine status =================\n  M204 S10000\n  M630 S0 P1\n  G90\n  M17 D ; reset motor current to default\n  M960 S5 P1 ; turn on logo lamp\n  G90\n  M220 S100 ;Reset Feedrate\n  M1002 set_gcode_claim_speed_level: 5\n  M221 S100 ;Reset Flowrate\n  M73.2   R1.0 ;Reset left time magnitude\n  G29.1 Z{+0.0} ; clear z-trim value first\n  M983.1 M1\n  M982.2 S1 ; turn on cog noise reduction\n  M983.4 S0\n;===== reset machine status =================\n\n;==== set airduct mode ====\n;==== if Chamber Cooling is necessary ====\n{if (overall_chamber_temperature >= 40)}\nM145 P1 ; set airduct mode to heating mode for heating\nM106 P2 S255 ; turn on filter fan\nM622.1 S0\nM1002 judge_flag ventobox_replace_aux1_fan_flag\nM622 J0\nM106 P10 S0 ; turn off left aux fan\nM623\n{else}\n{if (min_vitrification_temperature <= 50)}\nM145 P0 ; set airduct mode to cooling mode for cooling\nM106 P2 S255 ; turn on auxiliary fan for cooling\nM106 P3 S127 ; turn on chamber fan for cooling\nM1002 gcode_claim_action : 29\nM191 S0 ; wait for chamber temp\nM106 P2 S102 ; turn on chamber cooling fan\nM622.1 S0\nM1002 judge_flag ventobox_replace_aux1_fan_flag\nM622 J0\nM106 P10 S0 ; turn off left aux fan\nM623\nM142 P6 R30 S40 U0.3 V0.8 ; set PETG exhaust chamber autocooling\n{else}\nM145 P1 ; set airduct mode to heating mode for heating\nM106 P2 S127 ; turn on 50% filter fan\nM142 P6 R30 S40 U0.3 V0.8 ; set PLA/TPU exhaust chamber autocooling\n{endif}\n{endif}\n;==== set airduct mode ====\n\n;===== start to heat heatbed & hotend==========\n  M1002 gcode_claim_action : 2\n  M1002 set_filament_type:{filament_type[initial_no_support_filament_id]}\n  M104 S140 A\n\n  G29.2 S0 ; avoid invalid abl data\n\n;===== first homing start =====\n  M1002 gcode_claim_action : 13\n  G28 X T300\n  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed\n  G150.3\n  M972 S24 P0\n  M972 S26 P0 C0\n  M972 S42 P0 T5000\n  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed\n  G90\n  G1 X128 Y128 F30000\n  G28 Z P0 T400\n  M400\n;===== first homign end =====\n\n;===== detection start =====\n  M1002 gcode_claim_action : 11\n  M104 S{nozzle_temperature_initial_layer[initial_no_support_filament_id]-80} A ; rise temp in advance\n  M972 S19 P0 T5000 ;plate type detection\n\n  {if max_print_z >= 145}\n    M1002 gcode_claim_action : 75 ;  Detect obstacles at the botton of the heated bed\n    G150.3\n    M104 S{nozzle_temperature_initial_layer[initial_no_support_filament_id]} ; rise temp in advance\n    G3811 Z{max_print_z}  ; Detect obstacles at the bottom of the heated bed\n  {endif}\n;===== detection end =====\n\n;===== prepare print temperature and material ==========\n  M400\n  M211 X0 Y0 Z0 ;turn off soft endstop\n  M975 S1 ; turn on input shaping\n\n  G29.2 S0 ; avoid invalid abl data\n  G150.3\n{if ((filament_type[initial_no_support_filament_id] == \"PLA\") || (filament_type[initial_no_support_filament_id] == \"PLA-CF\") || (filament_type[initial_no_support_filament_id] == \"PETG\")) && (nozzle_diameter_at_nozzle_id[initial_nozzle_id] == 0.2)}\nM620.10 A0 F74.8347 H{nozzle_diameter_at_nozzle_id[initial_nozzle_id]} T{flush_temperatures[initial_no_support_filament_id]} P{nozzle_temperature_initial_layer[initial_no_support_filament_id]} S1\nM620.10 A1 F74.8347 H{nozzle_diameter_at_nozzle_id[initial_nozzle_id]} T{flush_temperatures[initial_no_support_filament_id]} P{nozzle_temperature_initial_layer[initial_no_support_filament_id]} S1\n{else}\nM620.10 A0 F{flush_volumetric_speeds[initial_no_support_filament_id]/2.4053*60} H{nozzle_diameter_at_nozzle_id[initial_nozzle_id]} T{flush_temperatures[initial_no_support_filament_id]} P{nozzle_temperature_initial_layer[initial_no_support_filament_id]} S1\nM620.10 A1 F{flush_volumetric_speeds[initial_no_support_filament_id]/2.4053*60} H{nozzle_diameter_at_nozzle_id[initial_nozzle_id]} T{flush_temperatures[initial_no_support_filament_id]} P{nozzle_temperature_initial_layer[initial_no_support_filament_id]} S1\n{endif}\n\n M620.11 P0 L0 I[initial_no_support_filament_id] E0\n M620.11 K0 I[initial_no_support_filament_id] R0\n\n  M620 S[initial_no_support_filament_id]A   ; switch material if AMS exist\n  M1002 gcode_claim_action : 4\n  M1002 set_filament_type:UNKNOWN\n  M400\n  T[initial_no_support_filament_id]\n  M400\n  M628 S0\n  M629\n  M400\n  M1002 set_filament_type:{filament_type[initial_no_support_filament_id]}\n  M621 S[initial_no_support_filament_id]A\n  M104 S{nozzle_temperature_initial_layer[initial_no_support_filament_id]}\n  M400\n  M106 P1 S0\n  M400\n  G29.2 S1\n;===== prepare print temperature and material ==========\n\n\n;===== auto extrude cali start =========================\n  M975 S1\n  M1002 judge_flag extrude_cali_flag\n  M622 J0\n    M983.3 F{filament_max_volumetric_speed[initial_no_support_filament_id]/2.4} A0.4 ; cali dynamic extrusion compensation\n  M623\n\n  M622 J1\n    M1002 set_filament_type:{filament_type[initial_no_support_filament_id]}\n    M1002 gcode_claim_action : 8\n    M109 S{nozzle_temperature[initial_no_support_filament_id]}\n    G90\n    M83\n    M983.3 F{filament_max_volumetric_speed[initial_no_support_filament_id]/2.4} A0.4 ; cali dynamic extrusion compensation\n    M400\n    M106 P1 S255\n    M400 S5\n    M106 P1 S0\n    G150.3\n  M623\n\n  M622 J2\n    M1002 set_filament_type:{filament_type[initial_no_support_filament_id]}\n    M1002 gcode_claim_action : 8\n    M109 S{nozzle_temperature[initial_no_support_filament_id]}\n    G90\n    M83\n    M983.3 F{filament_max_volumetric_speed[initial_no_support_filament_id]/2.4} A0.4 ; cali dynamic extrusion compensation\n    M400\n    M106 P1 S255\n    M400 S5\n    M106 P1 S0\n    G150.3\n  M623\n;===== auto extrude cali end =========================\n\n  {if hold_chamber_temp_for_flat_print}\n    M1002 gcode_claim_action : 58\n    M104 S{first_layer_temperature[initial_no_support_filament_id]}\n    {if bed_temperature_initial_layer_single > 89}\n        M1030 S1800\n        SYNC R0 T1800\n    {else}\n        M1030 S300\n        SYNC R0 T300\n    {endif}\n    M1030 C\n  {endif}\n\n  {if filament_type[initial_filament_id] == \"TPU\" || filament_type[initial_filament_id] == \"PVA\"}\n  {else}\n    M83\n    G1 E-3 F1800\n    M400 P500\n  {endif}\n  G150.2\n  G150.1 F8000\n  G150.2\n  G150.1 F8000\n\n  G91\n  G1 Y-16 F12000 ; move away from the trash bin\n  G90\n  M400\n\n  M104 S{nozzle_temperature_initial_layer[initial_no_support_filament_id]-80} A\n\n;===== wipe right nozzle start =====\n  M1002 gcode_claim_action : 14\n  G150 T{nozzle_temperature_initial_layer[initial_no_support_filament_id]}\n  M400\n\n{if filament_type[initial_filament_id] == \"PC\"}\n  M109 S170 A\n{else}\n  M109 S140 A\n{endif}\n  G91\n  G1 Z5 F1200\n  G90\n  M400\n  G150.1\n;===== wipe left nozzle end =====\n\n\n;===== mech mode sweep start =====\n  M1002 gcode_claim_action : 3\n  G90\n  G1 X128 Y128 F20000\n  G1 Z5 F1200\n  M400 P200\n  M970.3 Q1 A5 K0 O1\n  M970.2 Q1 K1 W74 Z0.01\n  M974 Q1 S2 P0\n  M970.3 Q0 A7 K0 O1\n  M970.2 Q0 K1 W74 Z0.01\n  M974 Q0 S2 P0\n  M975 S1\n  M400\n;===== mech mode sweep end =====\n\n;===== bed leveling ==================================\n  M1002 gcode_claim_action : 54\n  M190 S[bed_temperature_initial_layer_single]; ensure bed temp\n  M109 S140 A\n  M106 S0 ; turn off fan , too noisy\n  M1002 judge_flag g29_before_print_flag\n  M622 J1\n    M1002 gcode_claim_action : 1\n    {if hold_chamber_temp_for_flat_print}\n      G29 H\n    {else}\n      G29 A1 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]}\n    {endif}\n    M400\n  M623\n\n  M622 J2\n    M1002 gcode_claim_action : 1\n    {if hold_chamber_temp_for_flat_print}\n      G29 H\n    {else}\n      G29 A2 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]}\n    {endif}\n    M400\n  M623\n\n  M622 J0\n    G28\n  M623\n  G29.2 S1\n  G28\n;===== bed leveling end ================================\n\n  M985.1 U0 E2\n  M985.1 U1 E2\n\n  M104 S{nozzle_temperature_initial_layer[initial_filament_id]} A\n  G150.3 ; move to garbage can to wait for temp\n\n;===== wait temperature reaching the reference value =======\n  M190 S[bed_temperature_initial_layer_single]\n\n  ;========turn off light and fans =============\n  M960 S1 P0 ; turn off laser\n  M960 S2 P0 ; turn off laser\n  M106 S0 ; turn off cooling fan\n\n;===== wait temperature reaching the reference value =======\n\n  M1002 gcode_claim_action : 255\n  M400\n  M975 S1 ; turn on mech mode supression\n\n;============switch again==================\n  M211 X0 Y0 Z0 ;turn off soft endstop\n  G91\n  G1 Z6 F1200\n  G90\n  M1002 set_filament_type:{filament_type[initial_no_support_filament_id]}\n  M620 S[initial_no_support_filament_id]A\n  M400\n  T[initial_no_support_filament_id]\n  M400\n  M628 S0\n  M629\n  M400\n  M621 S[initial_no_support_filament_id]A\n;============switch again==================\n\n;===== for Textured PEI Plate , lower the nozzle as the nozzle was touching topmost of the texture when homing ==\n  {if bed_temperature_initial_layer_single > 89}\n    {if curr_bed_type==\"Textured PEI Plate\"}\n      G29.1 Z{-0.02} ; for Textured PEI Plate\n    {else}\n      G29.1 Z{0.0}\n    {endif}\n  {else}\n    {if curr_bed_type==\"Textured PEI Plate\"}\n      G29.1 Z{0.01} ; for Textured PEI Plate\n    {else}\n      G29.1 Z{0.03}\n    {endif}\n  {endif}\n\n\n;===== nozzle load line ===============================\nM1002 gcode_claim_action : 51\n  G29.2 S1 ; ensure z comp turn on\n  G90\n  M83\n  M400 P50\n  M500 D1\n  M400 S3\n  M109 S{nozzle_temperature_initial_layer[initial_no_support_filament_id]}\n  G0 X100 Y0 F24000\n  M400\n  ;G130 O0 X100 Y-0.4 Z0.8 F{filament_max_volumetric_speed[initial_no_support_filament_id]/2/2.4053} L40 E20 D5\n  G130 O0 X100 Y-0.2 Z0.6 F{filament_max_volumetric_speed[initial_no_support_filament_id]/2/2.4053} L40 E12 D4\n  G90\n  M83\n  G1 Z1\n  M400\n;===== noozle load line end ===========================\nM1002 gcode_claim_action : 0\n  G29.99\n\n{if (filament_type[initial_no_support_filament_id] == \"TPU\") ||\n(filament_type[initial_no_support_filament_id] == \"PLA\") ||  (filament_type[initial_no_support_filament_id] == \"PETG\")}\nM1015.3 S1 H{nozzle_diameter_at_nozzle_id[initial_nozzle_id]};enable tpu, pla and petg clog detect\n{else}\nM1015.3 S0;disable clog detect\n{endif}\n\n{if (filament_type[initial_no_support_filament_id] == \"PLA\") ||  (filament_type[initial_no_support_filament_id] == \"PETG\")\n ||  (filament_type[initial_no_support_filament_id] == \"PLA-CF\")  ||  (filament_type[initial_no_support_filament_id] == \"PETG-CF\")}\nM1015.4 S1 K1 H{nozzle_diameter_at_nozzle_id[initial_nozzle_id]} ;enable E air printing detect\n{else}\nM1015.4 S0 K0 H{nozzle_diameter_at_nozzle_id[initial_nozzle_id]} ;disable E air printing detect\n{endif}\n\nM620.6 I[initial_no_support_filament_id] W1 ;enable ams air printing detect\n\nM1010 Q0 B0.023 S0.01\nM1010 Q1 B0.005 S0.01\nM1010.1 S1\n
; machine_switch_extruder_time = 0
; machine_unload_filament_time = 31
; master_extruder_id = 1
; max_bridge_length = 0
; max_layer_height = 0.28
; max_travel_detour_distance = 0
; min_bead_width = 85%
; min_feature_size = 25%
; min_layer_height = 0.08
; minimum_sparse_infill_area = 15
; mmu_segmented_region_interlocking_depth = 0
; mmu_segmented_region_max_width = 0
; monotonic_travel_into_wall = 45%
; no_slow_down_for_cooling_on_outwalls = 0,0
; nozzle_diameter = 0.4
; nozzle_flush_dataset = 0
; nozzle_height = 4.2
; nozzle_temperature = 255,240
; nozzle_temperature_initial_layer = 255,240
; nozzle_temperature_range_high = 270,250
; nozzle_temperature_range_low = 220,200
; nozzle_type = hardened_steel
; nozzle_volume = 110
; nozzle_volume_type = Standard
; only_one_wall_first_layer = 0
; ooze_prevention = 0
; other_layers_print_sequence = 0
; other_layers_print_sequence_nums = 0
; outer_wall_acceleration = 1000
; outer_wall_jerk = 9
; outer_wall_line_width = 0.42
; outer_wall_speed = 40
; overhang_1_4_speed = 0
; overhang_2_4_speed = 50
; overhang_3_4_speed = 30
; overhang_4_4_speed = 10
; overhang_fan_speed = 90,100
; overhang_fan_threshold = 10%,95%
; overhang_threshold_participating_cooling = 95%
; overhang_totally_speed = 10
; override_filament_scarf_seam_setting = 0
; override_process_overhang_speed = 0,0
; physical_extruder_map = 0
; post_process = 
; pre_start_fan_time = 0
; precise_outer_wall = 0
; precise_z_height = 0
; pressure_advance = 0.02
; prime_tower_brim_width = 3
; prime_tower_enable_framework = 0
; prime_tower_extra_rib_length = 0
; prime_tower_fillet_wall = 1
; prime_tower_flat_ironing = 1
; prime_tower_infill_gap = 150%
; prime_tower_lift_height = -1
; prime_tower_lift_speed = 90
; prime_tower_max_speed = 90
; prime_tower_rib_wall = 1
; prime_tower_rib_width = 8
; prime_tower_skip_points = 1
; prime_tower_width = 35
; prime_volume_mode = Default
; print_compatible_printers = "Bambu Lab P2S 0.4 nozzle"
; print_extruder_id = 1
; print_extruder_variant = "Direct Drive Standard"
; print_flow_ratio = 1
; print_in_clockwise = 1
; print_sequence = by layer
; print_settings_id = Orion marine prototype 0.20mm P2S
; printable_area = 0x0,256x0,256x256,0x256
; printable_height = 256
; printer_extruder_id = 1
; printer_extruder_variant = "Direct Drive Standard"
; printer_model = Bambu Lab P2S
; printer_notes = 
; printer_settings_id = Bambu Lab P2S 0.4 nozzle
; printer_structure = corexy
; printer_technology = FFF
; printer_variant = 0.4
; printing_by_object_gcode = 
; process_notes = 
; raft_contact_distance = 0.1
; raft_expansion = 1.5
; raft_first_layer_density = 90%
; raft_first_layer_expansion = -1
; raft_layers = 0
; reduce_crossing_wall = 0
; reduce_fan_stop_start_freq = 1,1
; reduce_infill_retraction_mode = Auto
; required_nozzle_HRC = 3,3
; resolution = 0.012
; retract_before_wipe = 0%
; retract_length_toolchange = 2
; retract_lift_above = 0
; retract_lift_below = 249
; retract_restart_extra = 0
; retract_restart_extra_toolchange = 0
; retract_when_changing_layer = 1
; retraction_distances_when_cut = 18
; retraction_distances_when_ec = 0,0
; retraction_length = 0.8
; retraction_minimum_travel = 1
; retraction_speed = 30
; role_base_wipe_speed = 1
; scan_first_layer = 0
; scarf_angle_threshold = 155
; seam_gap = 15%
; seam_placement_away_from_overhangs = 0
; seam_position = aligned
; seam_slope_conditional = 1
; seam_slope_entire_loop = 0
; seam_slope_gap = 0
; seam_slope_inner_walls = 1
; seam_slope_min_length = 10
; seam_slope_start_height = 10%
; seam_slope_steps = 10
; seam_slope_type = none
; silent_mode = 0
; single_extruder_multi_material = 1
; skeleton_infill_density = 15%
; skeleton_infill_line_width = 0.45
; skin_infill_density = 15%
; skin_infill_depth = 2
; skin_infill_line_width = 0.45
; skirt_distance = 2
; skirt_height = 1
; skirt_loops = 0
; skirt_per_object = 1
; slice_closing_radius = 0.049
; slicing_mode = regular
; slow_down_for_layer_cooling = 1,1
; slow_down_layer_time = 12,8
; slow_down_min_speed = 20,10
; slowdown_end_acc = 100000
; slowdown_end_height = 400
; slowdown_end_speed = 1000
; slowdown_start_acc = 100000
; slowdown_start_height = 0
; slowdown_start_speed = 1000
; small_perimeter_speed = 50%
; small_perimeter_threshold = 0
; smooth_coefficient = 4
; smooth_speed_discontinuity_area = 1
; solid_infill_filament = 0
; sparse_infill_acceleration = 100%
; sparse_infill_anchor = 400%
; sparse_infill_anchor_max = 20
; sparse_infill_density = 35%
; sparse_infill_filament = 0
; sparse_infill_lattice_angle_1 = -45
; sparse_infill_lattice_angle_2 = 45
; sparse_infill_line_width = 0.45
; sparse_infill_pattern = gyroid
; sparse_infill_speed = 100
; spiral_mode = 0
; spiral_mode_max_xy_smoothing = 200%
; spiral_mode_smooth = 0
; standby_temperature_delta = -5
; start_end_points = 30x-3,54x245
; supertack_plate_temp = 70,0
; supertack_plate_temp_initial_layer = 70,0
; support_air_filtration = 0
; support_angle = 0
; support_base_pattern = default
; support_base_pattern_spacing = 2.5
; support_bottom_interface_spacing = 0.5
; support_bottom_z_distance = 0.2
; support_chamber_temp_control = 0
; support_cooling_filter = 0
; support_critical_regions_only = 0
; support_expansion = 0
; support_fast_purge_mode = 0
; support_filament = 0
; support_interface_bottom_layers = 2
; support_interface_filament = 0
; support_interface_loop_pattern = 0
; support_interface_not_for_body = 1
; support_interface_pattern = auto
; support_interface_spacing = 0.5
; support_interface_speed = 80
; support_interface_top_layers = 2
; support_ironing_direction = 0
; support_ironing_flow = 10%
; support_ironing_inset = 0
; support_ironing_pattern = zig-zag
; support_ironing_spacing = 0.15
; support_ironing_speed = 30
; support_line_width = 0.42
; support_object_first_layer_gap = 0.2
; support_object_skip_flush = 1
; support_object_xy_distance = 0.35
; support_on_build_plate_only = 0
; support_remove_small_overhang = 1
; support_speed = 150
; support_style = default
; support_threshold_angle = 30
; support_top_z_distance = 0.2
; support_type = tree(auto)
; symmetric_infill_y_axis = 0
; temperature_vitrification = 70,30
; template_custom_gcode = 
; textured_plate_temp = 70,35
; textured_plate_temp_initial_layer = 70,35
; thick_bridges = 0
; thumbnail_size = 50x50
; time_lapse_gcode = ;======== P2S timelapes gcode ==========\n;===== 2025/06/16 ====\n; SKIPPABLE_START\n; SKIPTYPE: timelapse\nM622.1 S1 ; for prev firware, default turned on\n\nM1002 judge_flag timelapse_record_flag\nM622 J1\n{if timelapse_type == 0} ; timelapse without wipe tower\n  M971 S11 C10 O0\n  M1004 S5 P1  ; external shutter\n{elsif timelapse_type == 1} ; timelapse with wipe tower\n  G150.3 ; move to garbage can\n  M400\n  M1004 S5 P1  ; external shutter\n  M400 P300\n  M971 S11 C10 O0\n  M400 P350\n  \n  G90\n  G1 Z{max_layer_z + 3.0} F1200\n  G1 Y247 F30000\n  G1 Y217 F18000\n{endif}\nM623\n; SKIPPABLE_END\n
; timelapse_type = 0
; top_area_threshold = 200%
; top_color_penetration_layers = 5
; top_one_wall_type = all top
; top_shell_layers = 6
; top_shell_thickness = 1
; top_solid_infill_flow_ratio = 1
; top_surface_acceleration = 2000
; top_surface_density = 100%
; top_surface_jerk = 9
; top_surface_line_width = 0.42
; top_surface_pattern = monotonicline
; top_surface_speed = 35
; top_z_overrides_xy_distance = 0
; travel_acceleration = 10000
; travel_jerk = 9
; travel_short_distance_acceleration = 250
; travel_speed = 600
; travel_speed_z = 0
; tree_support_branch_angle = 45
; tree_support_branch_diameter = 2
; tree_support_branch_diameter_angle = 5
; tree_support_branch_distance = 5
; tree_support_wall_count = -1
; upward_compatible_machine = "Bambu Lab A1 0.4 nozzle";"Bambu Lab H2S 0.4 nozzle";"Bambu Lab H2D 0.4 nozzle";"Bambu Lab H2D Pro 0.4 nozzle";"Bambu Lab H2C 0.4 nozzle";"Bambu Lab X2D 0.4 nozzle";"Bambu Lab A2L 0.4 nozzle"
; use_firmware_retraction = 0
; use_relative_e_distances = 1
; vertical_shell_speed = 80%
; volumetric_speed_coefficients = "0 0 0 0 0 0";"0 0 0 0 0 0"
; wall_distribution_count = 1
; wall_filament = 0
; wall_generator = classic
; wall_loops = 5
; wall_sequence = inner wall/outer wall
; wall_transition_angle = 10
; wall_transition_filter_deviation = 25%
; wall_transition_length = 100%
; wipe = 1
; wipe_distance = 2
; wipe_speed = 80%
; wipe_tower_no_sparse_layers = 0
; wipe_tower_rotation_angle = 0
; wipe_tower_x = 15
; wipe_tower_y = 220
; wrapping_detection_gcode = ;======== P2S 20250822 clumping ========\n{if !spiral_mode}\n    M622.1 S0 ; for previous firmware, default turn off\n    M1002 set_flag g39_forced_detection_flag=1\n    M1002 judge_flag g39_forced_detection_flag\n    M622 J1\n        {if layer_num == 3 || layer_num == 10 || layer_num == 19}\n            M993 A2 B2 C2 ; nozzle cam detection allow status save.\n            M993 A0 B0 C0 ; nozzle cam detection not allowed.\n\n            M400 P100\n\n            G39\n\n            G90\n            G1 Y247 F30000\n            G1 Y217 F18000\n            \n            M993 A3 B3 C3 ; nozzle cam detection allow status restore.\n        {endif}\n    M623\n{endif}
; wrapping_detection_layers = 20
; wrapping_exclude_area = 153x256,216x256,216x235,153x235
; xy_contour_compensation = 0
; xy_hole_compensation = 0
; z_direction_outwall_speed_continuous = 0
; z_hop = 0.4
; z_hop_types = Auto Lift
; CONFIG_BLOCK_END

; EXECUTABLE_BLOCK_START
M73 P0 R48
M201 X20000 Y20000 Z500 E5000
M203 X600 Y600 Z20 E30
M204 P20000 R5000 T20000
M205 X9.00 Y9.00 Z3.00 E2.50
M106 S0
M106 P2 S0
; FEATURE: Custom
;M1002 set_flag extrude_cali_flag=1
;M1002 set_flag g29_before_print_flag=1
;M1002 set_flag auto_cali_toolhead_offset_flag=1
;M1002 set_flag build_plate_detect_flag=1

;======== P2S start gcode==========
;===== 2026/05/18 =====

  M140 S35 ; heat heatbed first
  M993 A0 B0 C0 ; nozzle cam detection not allowed.
  M400

;=====printer start sound ===================
M17
M400 S1
M1006 S1
M1006 A53 B9 L50 C53 D9 M50 E53 F9 N50
M1006 A56 B9 L50 C56 D9 M50 E56 F9 N50
M1006 A61 B9 L50 C61 D9 M50 E61 F9 N50
M1006 A53 B9 L50 C53 D9 M50 E53 F9 N50
M1006 A56 B9 L50 C56 D9 M50 E56 F9 N50
M1006 A61 B18 L50 C61 D18 M50 E61 F18 N50
M1006 W
;=====printer start sound ===================

  M620 M ;enable remap
  G389

;===== avoid end stop =================
  G91
  G380 S2 Z22 F1200
  G380 S2 Z-12 F1200
  G90
;===== avoid end stop =================

;===== reset machine status =================
  M204 S10000
  M630 S0 P1
  G90
  M17 D ; reset motor current to default
  M960 S5 P1 ; turn on logo lamp
  G90
  M220 S100 ;Reset Feedrate
  M1002 set_gcode_claim_speed_level: 5
  M221 S100 ;Reset Flowrate
  M73.2   R1.0 ;Reset left time magnitude
  G29.1 Z0 ; clear z-trim value first
  M983.1 M1
  M982.2 S1 ; turn on cog noise reduction
  M983.4 S0
;===== reset machine status =================

;==== set airduct mode ====
;==== if Chamber Cooling is necessary ====


M145 P0 ; set airduct mode to cooling mode for cooling
M106 P2 S255 ; turn on auxiliary fan for cooling
M106 P3 S127 ; turn on chamber fan for cooling
M1002 gcode_claim_action : 29
M191 S0 ; wait for chamber temp
M106 P2 S102 ; turn on chamber cooling fan
M622.1 S0
M1002 judge_flag ventobox_replace_aux1_fan_flag
M622 J0
M106 P10 S0 ; turn off left aux fan
M623
M142 P6 R30 S40 U0.3 V0.8 ; set PETG exhaust chamber autocooling


;==== set airduct mode ====

;===== start to heat heatbed & hotend==========
  M1002 gcode_claim_action : 2
  M1002 set_filament_type:TPU
  M104 S140 A

  G29.2 S0 ; avoid invalid abl data

;===== first homing start =====
  M1002 gcode_claim_action : 13
  G28 X T300
  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed
  G150.3
  M972 S24 P0
  M972 S26 P0 C0
  M972 S42 P0 T5000
  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed
  G90
  G1 X128 Y128 F30000
  G28 Z P0 T400
  M400
;===== first homign end =====

;===== detection start =====
  M1002 gcode_claim_action : 11
  M104 S160 A ; rise temp in advance
  M972 S19 P0 T5000 ;plate type detection

  
;===== detection end =====

;===== prepare print temperature and material ==========
  M400
  M211 X0 Y0 Z0 ;turn off soft endstop
  M975 S1 ; turn on input shaping

  G29.2 S0 ; avoid invalid abl data
  G150.3

M620.10 A0 F49.8898 H0.4 T250 P240 S1
M620.10 A1 F49.8898 H0.4 T250 P240 S1


 M620.11 P0 L0 I1 E0
 M620.11 K0 I1 R0

  M620 S1A   ; switch material if AMS exist
  M1002 gcode_claim_action : 4
  M1002 set_filament_type:UNKNOWN
  M400
  T1
  M400
  M628 S0
  M629
  M400
  M1002 set_filament_type:TPU
  M621 S1A
  M104 S240
  M400
  M106 P1 S0
  M400
  G29.2 S1
;===== prepare print temperature and material ==========


;===== auto extrude cali start =========================
  M975 S1
  M1002 judge_flag extrude_cali_flag
  M622 J0
    M983.3 F0.833333 A0.4 ; cali dynamic extrusion compensation
  M623

  M622 J1
    M1002 set_filament_type:TPU
    M1002 gcode_claim_action : 8
    M109 S240
    G90
    M83
    M983.3 F0.833333 A0.4 ; cali dynamic extrusion compensation
    M400
    M106 P1 S255
    M400 S5
    M106 P1 S0
    G150.3
  M623

  M622 J2
    M1002 set_filament_type:TPU
    M1002 gcode_claim_action : 8
    M109 S240
    G90
    M83
    M983.3 F0.833333 A0.4 ; cali dynamic extrusion compensation
    M400
    M106 P1 S255
    M400 S5
    M106 P1 S0
    G150.3
  M623
;===== auto extrude cali end =========================

  

  
  
  G150.2
  G150.1 F8000
  G150.2
  G150.1 F8000

  G91
  G1 Y-16 F12000 ; move away from the trash bin
  G90
  M400

  M104 S160 A

;===== wipe right nozzle start =====
  M1002 gcode_claim_action : 14
  G150 T240
  M400


  M109 S140 A

  G91
  G1 Z5 F1200
  G90
  M400
  G150.1
;===== wipe left nozzle end =====


;===== mech mode sweep start =====
  M1002 gcode_claim_action : 3
  G90
M73 P0 R47
  G1 X128 Y128 F20000
M73 P1 R47
  G1 Z5 F1200
  M400 P200
  M970.3 Q1 A5 K0 O1
  M970.2 Q1 K1 W74 Z0.01
  M974 Q1 S2 P0
  M970.3 Q0 A7 K0 O1
  M970.2 Q0 K1 W74 Z0.01
  M974 Q0 S2 P0
  M975 S1
  M400
;===== mech mode sweep end =====

;===== bed leveling ==================================
  M1002 gcode_claim_action : 54
  M190 S35; ensure bed temp
  M109 S140 A
  M106 S0 ; turn off fan , too noisy
  M1002 judge_flag g29_before_print_flag
  M622 J1
    M1002 gcode_claim_action : 1
    
      G29 A1 X20.0906 Y91.3053 I215.819 J73.3894
    
    M400
  M623

  M622 J2
    M1002 gcode_claim_action : 1
    
      G29 A2 X20.0906 Y91.3053 I215.819 J73.3894
    
    M400
  M623

  M622 J0
    G28
  M623
  G29.2 S1
  G28
;===== bed leveling end ================================

  M985.1 U0 E2
  M985.1 U1 E2

  M104 S240 A
  G150.3 ; move to garbage can to wait for temp

;===== wait temperature reaching the reference value =======
  M190 S35

  ;========turn off light and fans =============
  M960 S1 P0 ; turn off laser
  M960 S2 P0 ; turn off laser
  M106 S0 ; turn off cooling fan

;===== wait temperature reaching the reference value =======

  M1002 gcode_claim_action : 255
  M400
  M975 S1 ; turn on mech mode supression

;============switch again==================
  M211 X0 Y0 Z0 ;turn off soft endstop
  G91
  G1 Z6 F1200
  G90
  M1002 set_filament_type:TPU
  M620 S1A
  M400
  T1
  M400
  M628 S0
  M629
  M400
  M621 S1A
;============switch again==================

;===== for Textured PEI Plate , lower the nozzle as the nozzle was touching topmost of the texture when homing ==
  
    
      G29.1 Z0.01 ; for Textured PEI Plate
    
  


;===== nozzle load line ===============================
M1002 gcode_claim_action : 51
  G29.2 S1 ; ensure z comp turn on
  G90
  M83
  M400 P50
  M500 D1
  M400 S3
  M109 S240
  G0 X100 Y0 F24000
  M400
  ;G130 O0 X100 Y-0.4 Z0.8 F0.415749 L40 E20 D5
  G130 O0 X100 Y-0.2 Z0.6 F0.415749 L40 E12 D4
  G90
  M83
  G1 Z1
  M400
;===== noozle load line end ===========================
M1002 gcode_claim_action : 0
  G29.99


M1015.3 S1 H0.4;enable tpu, pla and petg clog detect



M1015.4 S0 K0 H0.4 ;disable E air printing detect


M620.6 I1 W1 ;enable ams air printing detect

M1010 Q0 B0.023 S0.01
M1010 Q1 B0.005 S0.01
M1010.1 S1
; MACHINE_START_GCODE_END
; filament start gcode
;VT1 H-1
G90
G21
M83 ; use relative distances for extrusion
M981 S1 P20000 ;open spaghetti detector
; CHANGE_LAYER
; Z_HEIGHT: 0.2
; LAYER_HEIGHT: 0.2
G1 E-.4 F1800
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====









    
        M106 P2 S102
    

    M622.1 S0
    M1002 judge_flag ventobox_replace_aux1_fan_flag
    M622 J0
    M106 P10 S102; set first x_layer left aux fan
    M623
;not reset fan


; update layer progress
M73 L1
M991 S0 P0 ;notify layer change


M106 S0
M204 S6000
M73 P14 R41
G1 Z.4 F36000
; object ids of layer 1 start: 7,8,9,10,11,12,13,14,15
M624 /wEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer1 end: 7,8,9,10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.101 Y93.26
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X228.993 Y93.288 E.00422
G2 X230.2 Y93.097 I1.208 J3.723 E.88801
G1 X229.999 Y93.102 E.00767
G2 X229.389 Y93.182 I.203 J3.909 E.02338
G1 X229.159 Y93.244 E.00908
M204 S6000
G1 X229.219 Y93.701 F36000
G1 F1200
M204 S500
G1 X229.135 Y93.723 E.00331
G2 X230.201 Y93.554 I1.067 J3.288 E.78429
G1 X230.022 Y93.559 E.00678
G2 X229.484 Y93.63 I.179 J3.452 E.02065
G1 X229.277 Y93.685 E.00817
M204 S6000
G1 X229.331 Y94.145 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X229.128 Y94.21 E.00812
G2 X230.201 Y94.012 I1.074 J2.801 E.6746
G1 X230.046 Y94.016 E.00588
G2 X229.427 Y94.113 I.156 J2.996 E.02388
G1 X229.388 Y94.126 E.00155
; WIPE_START
G1 X229.128 Y94.21 E-.05198
G1 X228.841 Y94.338 E-.05964
G1 X228.44 Y94.584 E-.08946
G1 X228.196 Y94.782 E-.05968
G1 X227.974 Y95.004 E-.05963
G1 X227.776 Y95.248 E-.0596
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X228.187 Y93.055 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G2 X230.436 Y92.576 I2.018 J3.956 E.97212
G1 X230.207 Y92.57 E.0087
G2 X228.241 Y93.028 I-.001 J4.441 E.0774
M204 S6000
G1 X227.964 Y92.655 F36000
G1 F1200
M204 S500
G1 X227.536 Y92.904 E.01884
G2 X230.46 Y92.119 I2.67 J4.106 E1.05269
G1 X230.207 Y92.113 E.0096
G2 X228.018 Y92.629 I-.001 J4.898 E.08625
M204 S6000
G1 X227.736 Y92.26 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X227.287 Y92.521 E.01974
G2 X230.484 Y91.663 I2.919 J4.49 E1.15094
G1 X230.207 Y91.656 E.01051
G2 X227.789 Y92.232 I-.001 J5.355 E.09536
; WIPE_START
G1 X227.287 Y92.521 E-.11008
G1 X226.832 Y92.849 E-.10651
G1 X226.416 Y93.224 E-.10652
G1 X226.215 Y93.447 E-.05689
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X228.306 Y93.289 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.112815
G1 F1200
M204 S500
G1 X227.927 Y93.508 E.00254
G1 X227.574 Y93.765 E.00254
G1 X227.249 Y94.057 E.00254
G1 X226.956 Y94.382 E.00254
G1 X226.699 Y94.736 E.00254
G1 X226.386 Y95.313 E.00382
G1 X226.229 Y95.72 E.00254
G1 X226.116 Y96.143 E.00254
G1 X226.048 Y96.575 E.00254
G1 X226.025 Y97.011 E.00253
G1 X226.048 Y97.448 E.00255
G1 X226.116 Y97.879 E.00254
G1 X226.303 Y98.51 E.00382
G1 X226.481 Y98.909 E.00254
G1 X226.699 Y99.287 E.00254
G1 X226.956 Y99.641 E.00254
G1 X227.249 Y99.966 E.00254
G1 X227.574 Y100.259 E.00254
G1 X227.927 Y100.515 E.00253
G1 X228.505 Y100.829 E.00383
G1 X228.912 Y100.985 E.00253
G1 X229.334 Y101.098 E.00254
G1 X229.766 Y101.167 E.00254
G1 X230.203 Y101.19 E.00254
G1 X230.64 Y101.167 E.00254
G1 X231.071 Y101.099 E.00254
G1 X231.701 Y100.912 E.00382
G1 X232.1 Y100.734 E.00254
G1 X232.479 Y100.516 E.00254
G1 X232.833 Y100.258 E.00254
G1 X233.157 Y99.966 E.00254
G1 X233.45 Y99.641 E.00254
G1 X233.707 Y99.287 E.00254
G1 X233.926 Y98.908 E.00254
G1 X234.103 Y98.51 E.00253
G1 X234.29 Y97.88 E.00382
G1 X234.358 Y97.448 E.00254
G1 X234.381 Y97.012 E.00254
G1 X234.358 Y96.575 E.00254
G1 X234.29 Y96.143 E.00254
G1 X234.177 Y95.721 E.00254
G1 X234.02 Y95.313 E.00254
G1 X233.707 Y94.735 E.00382
G1 X233.45 Y94.382 E.00254
G1 X233.157 Y94.057 E.00254
G1 X232.833 Y93.765 E.00254
G1 X232.479 Y93.507 E.00254
G1 X231.901 Y93.194 E.00382
G1 X231.494 Y93.038 E.00254
G1 X231.072 Y92.925 E.00254
G1 X230.64 Y92.856 E.00254
G1 X230.207 Y92.834 E.00252
G1 X229.55 Y92.885 E.00383
G1 X229.122 Y92.976 E.00254
G1 X228.705 Y93.111 E.00255
G1 X228.361 Y93.264 E.00219
; OBJECT_ID: 12
; WIPE_START
G1 X227.927 Y93.508 E-.09449
G1 X227.574 Y93.765 E-.08303
G1 X227.249 Y94.057 E-.08314
G1 X226.956 Y94.382 E-.08307
G1 X226.844 Y94.537 E-.03627
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S6000
G1 X219.607 Y96.963 Z.6 F36000
G1 X212.145 Y99.465 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X212.268 Y99.291 E.00806
G2 X208.775 Y92.86 I-3.492 J-2.267 E.33975
G1 X208.56 Y92.866 E.00817
G2 X212.012 Y99.644 I.216 J4.158 E.62984
G1 X212.11 Y99.513 E.00622
M204 S6000
G1 X211.776 Y99.196 F36000
G1 F1200
M204 S500
G1 X211.885 Y99.043 E.00715
G2 X208.775 Y93.317 I-3.109 J-2.018 E.30244
G1 X208.584 Y93.322 E.00727
G2 X211.657 Y99.356 I.192 J3.702 E.56069
G1 X211.74 Y99.244 E.00531
M204 S6000
G1 X211.407 Y98.928 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X211.501 Y98.794 E.00624
G2 X208.775 Y93.775 I-2.725 J-1.77 E.26514
G1 X208.607 Y93.779 E.00638
G2 X211.302 Y99.069 I.168 J3.245 E.49154
G1 X211.371 Y98.976 E.0044
; WIPE_START
G1 X211.501 Y98.794 E-.04258
G1 X211.673 Y98.5 E-.06463
G1 X211.812 Y98.189 E-.06464
G1 X211.957 Y97.7 E-.09689
M73 P15 R41
G1 X212.01 Y97.364 E-.06464
G1 X212.023 Y97.119 E-.04662
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X205.011 Y99.399 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G1 X205.044 Y99.449 E.0023
G2 X209.011 Y92.576 I3.736 J-2.425 E.69145
G1 X208.781 Y92.57 E.00873
G2 X204.811 Y99.046 I-.001 J4.454 E.34572
G1 X204.982 Y99.346 E.01314
M204 S6000
G1 X204.616 Y99.627 F36000
G1 F1200
M204 S500
G1 X204.661 Y99.698 E.00321
G2 X209.035 Y92.119 I4.119 J-2.674 E.76241
G1 X208.781 Y92.113 E.00963
G2 X204.404 Y99.253 I-.001 J4.911 E.3812
G1 X204.586 Y99.575 E.01405
M204 S6000
G1 X204.22 Y99.855 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X204.278 Y99.947 E.00411
G2 X209.059 Y91.663 I4.503 J-2.923 E.83338
G1 X208.781 Y91.656 E.01054
G2 X203.997 Y99.461 I-.001 J5.368 E.41668
G1 X204.191 Y99.803 E.01495
; OBJECT_ID: 11
; WIPE_START
G1 X204.278 Y99.947 E-.03194
G1 X204.605 Y100.403 E-.1067
G1 X204.981 Y100.821 E-.10681
G1 X205.399 Y101.197 E-.10681
G1 X205.514 Y101.286 E-.02773
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S6000
G1 X198.212 Y99.065 Z.6 F36000
G1 X184.09 Y94.768 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G1 X184.005 Y94.883 E.00544
G2 X187.321 Y93.082 I3.318 J2.155 E.79532
G1 X187.117 Y93.087 E.00776
M73 P15 R40
G2 X184.248 Y94.548 I.205 J3.951 E.12603
G1 X184.125 Y94.719 E.00802
M204 S6000
G1 X184.459 Y95.036 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X184.388 Y95.132 E.00454
G2 X187.322 Y93.539 I2.935 J1.906 E.70343
G1 X187.141 Y93.544 E.00686
G2 X184.603 Y94.836 I.182 J3.495 E.11147
G1 X184.494 Y94.988 E.0071
; WIPE_START
G1 X184.388 Y95.132 E-.03408
G1 X184.206 Y95.45 E-.06968
G1 X184.058 Y95.782 E-.06908
G1 X183.901 Y96.311 E-.1048
G1 X183.843 Y96.673 E-.0696
G1 X183.834 Y96.845 E-.03276
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X187.402 Y92.115 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G1 X187.328 Y92.113 E.00283
G2 X187.582 Y92.119 I-.002 J4.926 E1.16659
G1 X187.462 Y92.116 E.00455
M204 S6000
G1 X187.414 Y91.658 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X187.328 Y91.656 E.00327
G2 X187.606 Y91.663 I-.002 J5.383 E1.27485
G1 X187.474 Y91.659 E.00501
M204 S6000
G1 X187.425 Y92.602 F36000
; FEATURE: Gap infill
; LINE_WIDTH: 0.554718
G1 F1172.339
M204 S500
G1 X187.328 Y92.597 E.00413
G1 X186.86 Y92.622 E.01991
G1 X186.407 Y92.693 E.01952
G1 X186.168 Y92.751 E.01047
G1 X185.726 Y92.895 E.01977
G1 X185.307 Y93.082 E.01952
G1 X184.905 Y93.314 E.01976
G1 X184.529 Y93.587 E.0198
G1 X184.183 Y93.898 E.01979
G1 X183.872 Y94.244 E.01978
G1 X183.603 Y94.614 E.01949
G1 X183.474 Y94.824 E.01049
G1 X183.264 Y95.239 E.01977
G1 X183.1 Y95.667 E.01952
G1 X182.979 Y96.116 E.01978
G1 X182.907 Y96.575 E.0198
G1 X182.883 Y97.032 E.01948
G1 X182.906 Y97.497 E.0198
G1 X182.938 Y97.741 E.01047
G1 X183.034 Y98.189 E.0195
G1 X183.18 Y98.637 E.02006
G1 X183.367 Y99.056 E.01951
G1 X183.599 Y99.458 E.01979
G1 X183.872 Y99.835 E.0198
G1 X184.184 Y100.18 E.01979
G1 X184.529 Y100.491 E.01976
G1 X184.899 Y100.761 E.0195
G1 X185.109 Y100.889 E.01049
G1 X185.524 Y101.1 E.01979
G1 X185.952 Y101.264 E.01948
G1 X186.401 Y101.384 E.01978
G1 X186.86 Y101.457 E.01979
G1 X187.324 Y101.481 E.01979
G1 X187.789 Y101.457 E.01979
G1 X188.241 Y101.385 E.01949
G1 X188.481 Y101.328 E.01048
G1 X188.922 Y101.184 E.01978
G1 X189.341 Y100.997 E.01952
G1 X189.744 Y100.764 E.01978
G1 X190.12 Y100.491 E.01979
G1 X190.465 Y100.18 E.01978
G1 X190.776 Y99.834 E.01979
G1 X191.046 Y99.464 E.0195
G1 X191.174 Y99.254 E.01047
G1 X191.385 Y98.84 E.01978
G1 X191.549 Y98.412 E.0195
G1 X191.669 Y97.962 E.0198
G1 X191.742 Y97.503 E.01978
G1 X191.766 Y97.039 E.01979
G1 X191.742 Y96.575 E.01978
G1 X191.669 Y96.116 E.01978
G1 X191.549 Y95.666 E.0198
G1 X191.385 Y95.239 E.0195
G1 X191.174 Y94.824 E.01978
G1 X191.046 Y94.614 E.01048
G1 X190.776 Y94.244 E.0195
G1 X190.465 Y93.898 E.01976
G1 X190.12 Y93.587 E.01979
G1 X189.749 Y93.318 E.01951
G1 X189.347 Y93.085 E.01978
G1 X189.125 Y92.979 E.01048
G1 X188.697 Y92.815 E.01949
G1 X188.248 Y92.694 E.01979
G1 X187.789 Y92.622 E.01978
G1 X187.485 Y92.606 E.01295
; OBJECT_ID: 10
; WIPE_START
G1 X187.328 Y92.597 E-.02985
G1 X186.86 Y92.622 E-.08891
G1 X186.407 Y92.693 E-.08716
G1 X186.168 Y92.751 E-.04677
G1 X185.726 Y92.895 E-.08827
G1 X185.539 Y92.978 E-.03904
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S6000
G1 X177.909 Y93.196 Z.6 F36000
G1 X163.433 Y93.609 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X163.367 Y93.651 E.00299
G2 X165.838 Y92.848 I2.472 J3.404 E.90417
G1 X165.621 Y92.854 E.00825
G2 X163.736 Y93.411 I.218 J4.201 E.07537
G1 X163.484 Y93.576 E.01147
M204 S6000
G1 X163.682 Y93.991 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X163.636 Y94.021 E.00208
G2 X165.838 Y93.305 I2.203 J3.034 E.80591
G1 X165.644 Y93.31 E.00736
G2 X163.965 Y93.807 I.195 J3.744 E.06717
G1 X163.732 Y93.959 E.01057
; WIPE_START
G1 X163.636 Y94.021 E-.02179
G1 X163.331 Y94.268 E-.0746
G1 X163.054 Y94.546 E-.07458
G1 X162.695 Y95.013 E-.11178
G1 X162.499 Y95.353 E-.0746
G1 X162.451 Y95.462 E-.02264
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X163.989 Y101.634 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G1 X164.07 Y101.667 E.00333
G2 X166.099 Y92.119 I1.773 J-4.613 E.64921
G1 X165.844 Y92.113 E.00969
G2 X163.594 Y101.455 I-.002 J4.942 E.50137
G1 X163.934 Y101.609 E.01419
M204 S6000
G1 X163.797 Y102.047 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X164.173 Y102.188 E.01526
G2 X166.123 Y91.663 I1.67 J-5.134 E.6985
G1 X165.844 Y91.656 E.0106
G2 X163.646 Y101.986 I-.002 J5.399 E.55867
G1 X163.741 Y102.024 E.00393
M204 S6000
G1 X164.077 Y101.271 F36000
; FEATURE: Gap infill
; LINE_WIDTH: 0.32081
G1 F1200
M204 S500
G1 X164.198 Y101.325 E.00304
G1 X164.653 Y101.473 E.01107
G1 X164.893 Y101.531 E.00571
G1 X165.362 Y101.605 E.01098
G1 X165.84 Y101.63 E.01106
G1 X166.319 Y101.605 E.01107
G1 X166.792 Y101.53 E.01107
G1 X167.254 Y101.406 E.01106
G1 X167.698 Y101.236 E.01098
G1 X168.125 Y101.019 E.01106
G1 X168.335 Y100.89 E.00571
G1 X168.72 Y100.611 E.01098
G1 X169.076 Y100.29 E.01107
G1 X169.396 Y99.934 E.01105
G1 X169.677 Y99.547 E.01107
G1 X169.917 Y99.132 E.01106
G1 X170.11 Y98.698 E.01098
G1 X170.193 Y98.465 E.00571
G1 X170.316 Y98.003 E.01106
G1 X170.39 Y97.533 E.01099
G1 X170.415 Y97.055 E.01106
G1 X170.39 Y96.577 E.01106
G1 X170.315 Y96.104 E.01107
G1 X170.192 Y95.642 E.01106
G1 X170.022 Y95.2 E.01093
G1 X169.914 Y94.973 E.00583
G1 X169.675 Y94.56 E.01101
G1 X169.396 Y94.176 E.01098
G1 X169.076 Y93.82 E.01105
G1 X168.72 Y93.5 E.01107
G1 X168.335 Y93.221 E.01097
G1 X168.125 Y93.091 E.00572
G1 X167.698 Y92.874 E.01106
G1 X167.254 Y92.704 E.01099
G1 X166.792 Y92.58 E.01106
G1 X166.319 Y92.505 E.01106
G1 X165.844 Y92.48 E.01098
G1 X165.598 Y92.487 E.0057
G1 X165.121 Y92.537 E.01107
G1 X164.656 Y92.636 E.01098
G1 X164.198 Y92.785 E.01114
G1 X163.763 Y92.979 E.01099
G1 X163.349 Y93.218 E.01106
G1 X162.961 Y93.5 E.01106
G1 X162.606 Y93.82 E.01106
G1 X162.285 Y94.176 E.01107
G1 X162.004 Y94.564 E.01106
G1 X161.764 Y94.978 E.01106
G1 X161.571 Y95.412 E.01098
G1 X161.488 Y95.645 E.00571
G1 X161.365 Y96.107 E.01105
G1 X161.291 Y96.577 E.01099
G1 X161.266 Y97.055 E.01106
G1 X161.291 Y97.533 E.01107
G1 X161.364 Y98 E.01091
G1 X161.422 Y98.242 E.00576
G1 X161.571 Y98.698 E.01108
G1 X161.764 Y99.132 E.01098
G1 X162.004 Y99.547 E.01106
G1 X162.285 Y99.934 E.01106
G1 X162.606 Y100.29 E.01107
G1 X162.961 Y100.611 E.01106
G1 X163.349 Y100.892 E.01106
G1 X163.76 Y101.13 E.01098
G1 X164.023 Y101.247 E.00665
; OBJECT_ID: 9
; WIPE_START
G1 X164.198 Y101.325 E-.03638
G1 X164.653 Y101.473 E-.09099
G1 X164.893 Y101.531 E-.04692
G1 X165.362 Y101.605 E-.09028
G1 X165.84 Y101.63 E-.09098
G1 X165.969 Y101.623 E-.02445
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 9
M624 BAAAAAAAAAA=
M204 S6000
G1 X158.346 Y102.001 Z.6 F36000
G1 X147.792 Y102.524 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X147.905 Y102.445 E.00524
G2 X148.498 Y101.337 I-.833 J-1.158 E.04944
G1 X148.498 Y94.283 E.26811
G2 X147.122 Y92.898 I-1.426 J.041 E.08168
G1 X137.069 Y92.898 E.38208
G2 X135.684 Y94.221 I.025 J1.413 E.07998
G1 X135.684 Y101.379 E.27204
G2 X137.059 Y102.712 I1.426 J-.094 E.07976
G1 X147.122 Y102.712 E.38248
G2 X147.736 Y102.549 I-.051 J-1.426 E.02436
G1 X147.737 Y102.548 E.00004
M204 S6000
G1 X147.553 Y102.134 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X147.642 Y102.073 E.00411
G2 X148.041 Y101.319 I-.564 J-.78 E.03356
G1 X148.041 Y94.295 E.26695
G2 X147.104 Y93.355 I-.963 J.022 E.05563
G1 X137.081 Y93.355 E.38094
G2 X136.141 Y94.251 I.012 J.954 E.05427
G1 X136.141 Y101.355 E.26999
G2 X137.077 Y102.255 I.962 J-.064 E.05413
G1 X147.104 Y102.255 E.38112
G2 X147.499 Y102.159 I-.027 J-.963 E.01554
; WIPE_START
G1 X147.642 Y102.073 E-.0318
G1 X147.797 Y101.941 E-.03859
G1 X147.938 Y101.737 E-.04712
G1 X147.995 Y101.599 E-.02837
G1 X148.041 Y101.319 E-.0539
G1 X148.041 Y100.371 E-.18021
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X148.237 Y92.741 Z.6 F36000
G1 X148.244 Y92.444 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G1 X147.982 Y92.304 E.01131
G2 X147.093 Y92.113 I-.898 J2.008 E.03481
G1 X138.044 Y92.112 E.3439
G1 X137.101 Y92.112 E.03583
G2 X134.898 Y94.316 I-.003 J2.201 E.13162
G1 X134.898 Y101.294 E.26522
G2 X137.101 Y103.498 I2.201 J.003 E.13162
G1 X147.08 Y103.498 E.37924
G2 X149.284 Y101.294 I.003 J-2.201 E.13162
G1 X149.284 Y94.316 E.26522
G2 X148.295 Y92.476 I-2.2 J-.004 E.08272
M204 S6000
G1 X148.458 Y92.038 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X148.425 Y92.019 E.00147
G2 X147.099 Y91.656 I-1.342 J2.294 E.05286
G1 X138.044 Y91.655 E.34413
G1 X137.095 Y91.655 E.03606
G2 X134.441 Y94.31 I.004 J2.659 E.15842
G1 X134.441 Y101.3 E.26568
G2 X137.095 Y103.955 I2.659 J-.004 E.15842
G1 X147.086 Y103.955 E.3797
G2 X149.741 Y101.3 I-.004 J-2.659 E.15842
G1 X149.741 Y94.31 E.26568
G2 X148.646 Y92.164 I-2.658 J.004 E.09502
G1 X148.508 Y92.071 E.00631
M204 S6000
G1 X148.071 Y92.796 F36000
; FEATURE: Gap infill
; LINE_WIDTH: 0.371621
M73 P16 R40
G1 F1200
M204 S500
G2 X147.087 Y92.505 I-.981 J1.51 E.02842
G1 X138.044 Y92.505 E.24716
G2 X136.895 Y92.516 I-.469 J11.723 E.03143
G2 X135.291 Y94.322 I.198 J1.791 E.07234
G1 X135.292 Y101.391 E.19321
G1 X135.293 Y101.408 E.00047
G2 X137.107 Y103.105 I1.799 J-.105 E.07491
G1 X147.185 Y103.102 E.27545
G2 X148.891 Y101.289 I-.095 J-1.798 E.07512
G1 X148.89 Y94.267 E.19192
G2 X148.12 Y92.83 I-1.8 J.039 E.04625
; OBJECT_ID: 8
; WIPE_START
G1 X147.906 Y92.699 E-.04764
G1 X147.735 Y92.626 E-.03536
G1 X147.372 Y92.526 E-.07154
G1 X147.087 Y92.505 E-.05428
G1 X146.186 Y92.505 E-.17119
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 9
M625
; start printing object, unique label id: 8
M624 AgAAAAAAAAA=
M204 S6000
G1 X138.906 Y94.798 Z.6 F36000
G1 X99.919 Y107.075 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X100.059 Y107.248 E.00847
G2 X101.059 Y107.712 I1.058 J-.97 E.04299
G1 X121.122 Y107.712 E.76254
G2 X122.498 Y106.327 I-.05 J-1.425 E.08172
G1 X122.498 Y94.283 E.45774
G2 X121.122 Y92.898 I-1.434 J.049 E.08157
G1 X101.069 Y92.898 E.76214
G2 X99.684 Y94.284 I.047 J1.433 E.08201
G1 X99.684 Y106.337 E.45808
G2 X99.874 Y106.995 I1.434 J-.058 E.02632
G1 X99.89 Y107.022 E.00119
M204 S6000
G1 X100.287 Y106.807 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X100.393 Y106.939 E.00643
G2 X101.077 Y107.255 I.716 J-.653 E.0294
G1 X121.104 Y107.255 E.76118
G2 X122.041 Y106.315 I-.026 J-.962 E.05565
G1 X122.041 Y94.295 E.4568
G2 X121.104 Y93.355 I-.969 J.028 E.05554
G1 X101.081 Y93.355 E.761
G2 X100.141 Y94.296 I.028 J.968 E.05573
G1 X100.141 Y106.319 E.45695
G2 X100.26 Y106.754 I.969 J-.033 E.0173
; WIPE_START
G1 X100.393 Y106.939 E-.04338
G1 X100.577 Y107.105 E-.04699
G1 X100.704 Y107.174 E-.02747
G1 X100.84 Y107.222 E-.02745
G1 X101.077 Y107.255 E-.04543
G1 X102.073 Y107.255 E-.18928
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X108.233 Y102.749 Z.6 F36000
G1 X122.283 Y92.469 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G2 X121.093 Y92.113 I-1.2 J1.844 E.04788
G1 X102.067 Y92.112 E.72311
G1 X101.101 Y92.112 E.03669
G2 X98.898 Y94.316 I-.003 J2.201 E.13161
G1 X98.898 Y106.294 E.45525
G2 X101.101 Y108.498 I2.202 J.002 E.1316
G1 X121.08 Y108.498 E.7593
G2 X123.284 Y106.294 I.003 J-2.201 E.13162
G1 X123.284 Y94.316 E.45525
G2 X122.333 Y92.502 I-2.2 J-.003 E.08096
M204 S6000
G1 X122.546 Y92.092 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X122.532 Y92.086 E.00059
G2 X121.099 Y91.656 I-1.45 J2.228 E.05765
G1 X102.067 Y91.655 E.72334
G1 X101.095 Y91.655 E.03692
G2 X98.441 Y94.31 I.004 J2.659 E.15842
G1 X98.441 Y106.3 E.45571
G2 X101.095 Y108.955 I2.66 J-.005 E.15841
G1 X121.086 Y108.955 E.75976
G2 X123.741 Y106.3 I-.004 J-2.659 E.15842
G1 X123.741 Y94.31 E.45571
G2 X122.756 Y92.249 I-2.659 J.004 E.08975
G1 X122.594 Y92.128 E.00768
M204 S6000
G1 X122.07 Y92.797 F36000
; FEATURE: Gap infill
; LINE_WIDTH: 0.371561
G1 F1200
M204 S500
G2 X121.087 Y92.505 I-.984 J1.512 E.02841
G1 X102.067 Y92.505 E.51977
G2 X100.894 Y92.516 I-.48 J11.931 E.03206
G2 X99.291 Y94.269 I.203 J1.794 E.07085
G1 X99.292 Y106.358 E.33034
G2 X101.107 Y108.105 I1.804 J-.058 E.0762
G1 X121.144 Y108.104 E.54755
G2 X122.891 Y106.289 I-.058 J-1.803 E.07619
G1 X122.89 Y94.267 E.32852
G2 X122.12 Y92.831 I-1.803 J.042 E.04621
; OBJECT_ID: 7
; WIPE_START
G1 X121.823 Y92.66 E-.06497
G1 X121.465 Y92.545 E-.07153
G1 X121.087 Y92.505 E-.07214
G1 X120.185 Y92.505 E-.17136
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 8
M625
; start printing object, unique label id: 7
M624 AQAAAAAAAAA=
M204 S6000
G1 X115.69 Y98.674 Z.6 F36000
G1 X85.694 Y139.837 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X85.903 Y139.506 E.01486
G2 X86.498 Y137.316 I-3.826 J-2.215 E.08723
G1 X86.498 Y97.294 E1.52107
G2 X82.101 Y92.898 I-4.421 J.025 E.26205
G1 X26.08 Y92.898 E2.12918
G2 X21.684 Y97.294 I.027 J4.423 E.26203
G1 X21.684 Y137.316 E1.52107
G2 X26.08 Y141.712 I4.421 J-.025 E.26206
G1 X82.101 Y141.712 E2.12918
G2 X85.652 Y139.892 I-.025 J-4.421 E.15731
G1 X85.658 Y139.885 E.00037
M204 S6000
M73 P17 R40
G1 X85.307 Y139.59 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X85.399 Y139.454 E.00624
G2 X86.041 Y137.31 I-3.322 J-2.162 E.08623
G1 X86.041 Y97.301 E1.52061
G2 X82.095 Y93.355 I-3.963 J.018 E.23525
G1 X26.086 Y93.355 E2.12871
G2 X22.141 Y97.301 I.019 J3.964 E.23523
G1 X22.141 Y137.31 E1.52061
G2 X26.086 Y141.255 I3.963 J-.018 E.23525
M73 P17 R39
G1 X82.095 Y141.255 E2.12871
G2 X85.156 Y139.788 I-.018 J-3.963 E.13332
G1 X85.27 Y139.638 E.00718
; WIPE_START
G1 X85.399 Y139.454 E-.0426
G1 X85.699 Y138.912 E-.11772
G1 X85.847 Y138.526 E-.07855
G1 X85.954 Y138.127 E-.07856
G1 X86.006 Y137.801 E-.06258
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X78.396 Y138.391 Z.6 F36000
G1 X25.668 Y142.476 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G1 X26.102 Y142.498 E.0165
G1 X82.08 Y142.498 E2.12752
G2 X87.284 Y137.294 I-.007 J-5.211 E.31056
G1 X87.284 Y97.316 E1.51942
G2 X82.106 Y92.113 I-5.21 J.007 E.30956
G1 X27.082 Y92.112 E2.09125
G1 X26.102 Y92.112 E.03727
G2 X20.898 Y97.316 I.007 J5.211 E.31056
G1 X20.898 Y137.294 E1.51942
G2 X25.55 Y142.468 I5.211 J-.007 E.28954
G1 X25.608 Y142.472 E.00223
M204 S6000
G1 X25.644 Y142.932 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X26.095 Y142.955 E.01716
G1 X82.086 Y142.955 E2.12799
G2 X87.741 Y137.3 I-.014 J-5.669 E.33736
G1 X87.741 Y97.31 E1.51989
G2 X82.112 Y91.656 I-5.668 J.014 E.33637
G1 X27.082 Y91.655 E2.09148
G1 X26.095 Y91.655 E.0375
M73 P18 R39
G2 X20.441 Y97.31 I.014 J5.669 E.33736
G1 X20.441 Y137.3 E1.51989
G2 X25.501 Y142.923 I5.669 J-.014 E.31472
G1 X25.585 Y142.928 E.00319
M204 S6000
G1 X25.627 Y142.081 F36000
; FEATURE: Gap infill
; LINE_WIDTH: 0.371517
G1 F1200
M204 S500
G1 X26.107 Y142.105 E.01312
G1 X82.346 Y142.098 E1.53661
G2 X86.891 Y137.289 I-.255 J-4.793 E.19948
G1 X86.884 Y97.054 E1.09934
G1 X86.864 Y96.799 E.00698
G1 X86.786 Y96.312 E.01349
G1 X86.656 Y95.822 E.01384
G1 X86.474 Y95.349 E.01384
G1 X86.365 Y95.122 E.00688
G1 X86.118 Y94.695 E.01349
G1 X85.821 Y94.285 E.01384
G1 X85.482 Y93.908 E.01385
G1 X85.106 Y93.571 E.0138
G1 X84.709 Y93.282 E.01342
G1 X84.487 Y93.146 E.00711
G2 X82.1 Y92.506 I-2.407 J4.201 E.06827
G1 X27.082 Y92.505 E1.50326
G2 X25.336 Y92.565 I-.5 J10.926 E.0478
G1 X25.088 Y92.611 E.00687
G2 X21.291 Y97.287 I1.003 J4.695 E.17791
G1 X21.291 Y137.319 E1.09379
G1 X21.317 Y137.803 E.01324
G1 X21.35 Y138.056 E.00697
G1 X21.396 Y138.307 E.00698
G1 X21.524 Y138.784 E.0135
G1 X21.611 Y139.029 E.0071
G1 X21.812 Y139.481 E.01349
G1 X22.068 Y139.923 E.01396
G2 X25.568 Y142.076 I4.029 J-2.627 E.11601
; OBJECT_ID: 15
; WIPE_START
G1 X26.107 Y142.105 E-.1026
G1 X27.567 Y142.105 E-.2774
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 7
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S6000
G1 X32.742 Y147.716 Z.6 F36000
G1 X47.172 Y163.362 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X47.601 Y163.339 E.01632
G2 X47.372 Y154.576 I-.457 J-4.372 E.49883
G1 X47.145 Y154.57 E.00862
G2 X47.112 Y163.362 I-.001 J4.396 E.52377
M204 S6000
G1 X47.196 Y163.818 F36000
G1 F1200
M204 S500
G1 X47.649 Y163.793 E.01723
G2 X47.396 Y154.119 I-.505 J-4.827 E.5507
G1 X47.145 Y154.113 E.00952
G2 X47.136 Y163.82 I-.001 J4.853 E.57926
M204 S6000
G1 X47.22 Y164.274 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X47.697 Y164.248 E.01814
G2 X47.42 Y153.663 I-.553 J-5.282 E.60256
G1 X47.146 Y153.656 E.01042
G2 X47.142 Y164.277 I-.002 J5.311 E.63405
G1 X47.16 Y164.276 E.0007
; WIPE_START
G1 X47.697 Y164.248 E-.10207
G1 X48.242 Y164.163 E-.10488
G1 X48.783 Y164.019 E-.10632
G1 X49.049 Y163.924 E-.05369
G1 X49.112 Y163.896 E-.01303
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X50.9 Y157.075 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Bottom surface
; LINE_WIDTH: 0.51336
G1 F1275.402
M204 S500
G1 X49.773 Y155.948 E.06235
G2 X48.292 Y155.131 I-2.677 J3.106 E.06665
G1 X50.977 Y157.817 E.14856
G3 X51.135 Y158.64 I-4.672 J1.324 E.03284
G1 X47.472 Y154.977 E.20266
G2 X46.807 Y154.977 I-.33 J4.294 E.02603
G1 X51.131 Y159.301 E.23919
G3 X51.04 Y159.876 I-2.791 J-.146 E.0228
G1 X46.233 Y155.068 E.26597
G2 X45.72 Y155.22 I.467 J2.515 E.02097
G1 X50.888 Y160.389 E.28592
G3 X50.679 Y160.845 I-7.132 J-2.994 E.01963
G1 X45.262 Y155.428 E.29968
G2 X44.851 Y155.682 I1.41 J2.74 E.01893
G1 X50.425 Y161.257 E.30839
G3 X50.131 Y161.628 I-1.914 J-1.213 E.01856
G1 X44.477 Y155.974 E.31278
G2 X44.148 Y156.31 I2.15 J2.437 E.01842
G1 X49.801 Y161.963 E.31274
G3 X49.427 Y162.255 I-1.572 J-1.631 E.01858
M73 P19 R39
G1 X43.854 Y156.682 E.3083
G2 X43.601 Y157.094 I1.835 J1.411 E.01895
G1 X49.013 Y162.506 E.29937
G3 X48.554 Y162.712 I-1.211 J-2.078 E.01972
G1 X43.393 Y157.551 E.2855
G2 X43.241 Y158.065 I2.373 J.98 E.02099
G1 X48.045 Y162.868 E.26573
G3 X47.472 Y162.96 I-1.205 J-5.674 E.02272
G1 X43.152 Y158.64 E.23899
G2 X43.153 Y159.307 I4.268 J.325 E.0261
G1 X46.802 Y162.956 E.20186
G3 X45.978 Y162.797 I.369 J-4.137 E.03287
G1 X43.311 Y160.13 E.14753
G2 X44.153 Y161.638 I3.96 J-1.223 E.06804
G1 X45.244 Y162.728 E.06033
; OBJECT_ID: 14
; WIPE_START
G1 X44.153 Y161.638 E-.29304
G1 X43.875 Y161.274 E-.08696
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S6000
G1 X36.648 Y158.822 Z.6 F36000
G1 X26.892 Y155.512 Z.6
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.5
G1 F1200
M204 S500
G1 X26.734 Y155.461 E.00632
G2 X25.783 Y155.335 I-.95 J3.539 E.03656
G1 X25.594 Y155.34 E.00719
G2 X27.098 Y155.579 I.19 J3.659 E.81662
G1 X26.949 Y155.53 E.00597
M204 S6000
G1 X26.751 Y155.946 F36000
G1 F1200
M204 S500
G1 X26.616 Y155.902 E.00541
G2 X25.783 Y155.793 I-.831 J3.097 E.032
G1 X25.618 Y155.797 E.0063
G2 X26.935 Y156.006 I.166 J3.202 E.71472
G1 X26.808 Y155.965 E.00507
M204 S6000
G1 X26.61 Y156.38 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X26.497 Y156.344 E.00451
G2 X25.784 Y156.25 I-.713 J2.656 E.02743
G1 X25.641 Y156.254 E.0054
G2 X26.771 Y156.433 I.143 J2.746 E.61283
G1 X26.667 Y156.399 E.00416
; WIPE_START
G1 X26.497 Y156.344 E-.03394
G1 X26.217 Y156.284 E-.05439
G1 X25.784 Y156.25 E-.08262
G1 X25.641 Y156.254 E-.027
G1 X25.214 Y156.31 E-.08201
G1 X24.937 Y156.384 E-.05448
G1 X24.713 Y156.47 E-.04556
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X25.856 Y154.572 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1200
M204 S500
G1 X25.789 Y154.57 E.00255
G2 X26.017 Y154.576 I-.001 J4.429 E1.04905
G1 X25.916 Y154.573 E.00386
M204 S6000
G1 X25.868 Y154.115 F36000
G1 F1200
M204 S500
G1 X25.789 Y154.113 E.003
G2 X26.041 Y154.119 I-.001 J4.887 E1.15731
G1 X25.928 Y154.116 E.00431
M204 S6000
G1 X25.88 Y153.658 F36000
; FEATURE: Outer wall
G1 F1200
M204 S500
G1 X25.789 Y153.656 E.00344
G2 X26.065 Y153.663 I-.002 J5.344 E1.26558
M73 P19 R38
G1 X25.94 Y153.659 E.00477
; WIPE_START
G1 X25.789 Y153.656 E-.02862
G1 X25.505 Y153.663 E-.05394
G1 X24.945 Y153.722 E-.10705
G1 X24.402 Y153.838 E-.10551
G1 X23.977 Y153.976 E-.08488
; WIPE_END
G1 E-.02 F1800
M204 S6000
G1 X25.872 Y154.957 Z.6 F36000
G1 Z.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.351171
G1 F1200
M204 S500
G1 X25.789 Y154.953 E.00213
G1 X25.367 Y154.974 E.01083
G1 X24.948 Y155.04 E.01087
G1 X24.331 Y155.223 E.01648
G1 X23.947 Y155.394 E.01077
G1 X23.581 Y155.606 E.01085
G1 X23.238 Y155.855 E.01086
G1 X22.924 Y156.138 E.01085
G1 X22.64 Y156.453 E.01087
G1 X22.394 Y156.791 E.0107
G1 X22.086 Y157.358 E.01654
G1 X21.936 Y157.75 E.01075
G1 X21.826 Y158.159 E.01085
G1 X21.76 Y158.577 E.01086
G1 X21.738 Y159 E.01086
G1 X21.76 Y159.423 E.01086
G1 X21.826 Y159.842 E.01086
G1 X21.936 Y160.25 E.01085
G1 X22.085 Y160.64 E.0107
G1 X22.393 Y161.208 E.01655
G1 X22.64 Y161.547 E.01076
G1 X22.924 Y161.862 E.01086
G1 X23.238 Y162.145 E.01085
G1 X23.577 Y162.392 E.01075
G1 X24.145 Y162.7 E.01656
G1 X24.535 Y162.849 E.01069
G1 X24.944 Y162.959 E.01086
G1 X25.362 Y163.025 E.01086
G1 X25.785 Y163.047 E.01086
G1 X26.209 Y163.025 E.01086
G1 X26.627 Y162.959 E.01086
G1 X27.036 Y162.849 E.01084
G1 X27.428 Y162.699 E.01076
G1 X27.993 Y162.392 E.01648
G1 X28.333 Y162.145 E.01077
G1 X28.647 Y161.862 E.01084
G1 X28.931 Y161.547 E.01086
G1 X29.176 Y161.209 E.01071
G1 X29.485 Y160.64 E.01659
G1 X29.635 Y160.251 E.01069
G1 X29.744 Y159.841 E.01087
G1 X29.81 Y159.423 E.01085
G1 X29.833 Y159 E.01086
G1 X29.81 Y158.577 E.01085
G1 X29.744 Y158.158 E.01087
G1 X29.635 Y157.749 E.01085
G1 X29.485 Y157.359 E.0107
G1 X29.178 Y156.792 E.01653
G1 X28.931 Y156.453 E.01076
G1 X28.647 Y156.138 E.01086
G1 X28.333 Y155.855 E.01085
G1 X27.993 Y155.608 E.01076
G1 X27.428 Y155.301 E.01648
G1 X27.036 Y155.151 E.01077
G1 X26.627 Y155.041 E.01086
G1 X26.208 Y154.975 E.01086
G1 X25.932 Y154.96 E.00711
; CHANGE_LAYER
; Z_HEIGHT: 0.4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1200
G1 X25.789 Y154.953 E-.02718
G1 X25.367 Y154.974 E-.08029
G1 X24.948 Y155.04 E-.08058
G1 X24.331 Y155.223 E-.12218
G1 X23.996 Y155.372 E-.06977
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





    ;updata chamber autocooling in Xth layer
    
        
            M142 P1 R30 S40 U0.7 V1.0 O45; set PLA/TPU ND0.4 chamber autocooling
        
    

    M622.1 S0
    M1002 judge_flag ventobox_replace_aux1_fan_flag
    M622 J0
    M106 P10 S178.5; set left aux fan
    M623
;not reset fan


; update layer progress
M73 L2
M991 S0 P1 ;notify layer change


M106 S255
; open powerlost recovery
M1003 S1
M204 S10000
G17
G3 Z.6 I1.217 J0 P1  F36000
; object ids of layer 2 start: 7,8,9,10,11,12,13,14,15
M624 /wEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer2 end: 7,8,9,10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.108 Y93.529
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.714 Y93.667 E.01412
G2 X230.196 Y93.352 I1.485 J3.344 E.72649
G1 X230.012 Y93.357 E.00625
G2 X229.256 Y93.476 I.188 J3.654 E.02594
G1 X229.164 Y93.509 E.0033
M204 S10000
G1 X229.251 Y93.906 F36000
G1 F1473.913
M204 S3000
G1 X229.037 Y93.974 E.00761
G2 X230.196 Y93.759 I1.162 J3.037 E.65143
G1 X230.033 Y93.764 E.00554
G2 X229.361 Y93.869 I.167 J3.247 E.02305
G1 X229.308 Y93.887 E.00189
M204 S250
G1 X229.374 Y94.281 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.039 Y94.398 E.0111
G2 X230.197 Y94.152 I1.16 J2.614 E.52597
G1 X230.054 Y94.155 E.0045
G2 X229.463 Y94.248 I.146 J2.856 E.01878
G1 X229.43 Y94.26 E.00109
; WIPE_START
M204 S3000
G1 X229.039 Y94.398 E-.07869
G1 X228.773 Y94.535 E-.0569
G1 X228.522 Y94.698 E-.05693
G1 X228.289 Y94.886 E-.05685
G1 X228.078 Y95.098 E-.05688
G1 X227.841 Y95.406 E-.07376
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.072 Y92.829 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X230.449 Y92.321 I2.137 J4.182 E.91552
G1 X230.215 Y92.315 E.00792
G2 X228.126 Y92.802 I-.006 J4.696 E.07325
M204 S10000
G1 X227.884 Y92.465 F36000
G1 F1473.913
M204 S3000
G1 X227.425 Y92.734 E.01802
G2 X230.47 Y91.915 I2.784 J4.277 E.97681
G1 X230.215 Y91.908 E.00863
G2 X227.938 Y92.441 I-.006 J5.103 E.07989
M204 S250
G1 X227.689 Y92.126 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.212 Y92.405 E.01733
G2 X230.491 Y91.523 I2.998 J4.605 E.97435
G1 X230.216 Y91.516 E.00862
G2 X227.743 Y92.1 I-.006 J5.495 E.0804
; WIPE_START
M204 S3000
G1 X227.212 Y92.405 E-.11637
G1 X226.744 Y92.74 E-.10926
G1 X226.317 Y93.125 E-.10932
G1 X226.158 Y93.301 E-.04505
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.307 Y93.289 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672822
G1 F952.53
M204 S3000
G1 X227.927 Y93.508 E.02293
G1 X227.574 Y93.765 E.02289
G1 X227.248 Y94.057 E.02293
G1 X226.956 Y94.382 E.02288
G1 X226.699 Y94.736 E.0229
G1 X226.48 Y95.115 E.02293
G1 X226.306 Y95.506 E.02245
G1 X226.227 Y95.728 E.01234
G1 X226.115 Y96.151 E.02289
G1 X226.048 Y96.575 E.02247
G1 X226.025 Y97.012 E.02292
G1 X226.048 Y97.448 E.02291
G1 X226.115 Y97.872 E.02248
G1 X226.227 Y98.295 E.0229
G1 X226.306 Y98.517 E.01233
G1 X226.481 Y98.91 E.02254
G1 X226.699 Y99.287 E.02282
G1 X226.956 Y99.641 E.02292
G1 X227.249 Y99.966 E.0229
G1 X227.574 Y100.259 E.02291
G1 X227.921 Y100.511 E.02246
G1 X228.121 Y100.634 E.01232
G1 X228.511 Y100.832 E.0229
G1 X228.912 Y100.985 E.02247
G1 X229.334 Y101.098 E.02291
G1 X229.766 Y101.167 E.02292
G1 X230.203 Y101.19 E.02291
G1 X230.64 Y101.167 E.02292
G1 X231.057 Y101.101 E.02209
G1 X231.292 Y101.045 E.01265
G1 X231.711 Y100.908 E.02312
G1 X232.1 Y100.734 E.0223
G1 X232.479 Y100.516 E.02292
G1 X232.833 Y100.258 E.02291
G1 X233.157 Y99.966 E.02289
G1 X233.45 Y99.641 E.02291
G1 X233.702 Y99.294 E.02247
G1 X233.825 Y99.093 E.01232
G1 X234.023 Y98.704 E.02289
G1 X234.177 Y98.303 E.0225
G1 X234.29 Y97.88 E.02289
G1 X234.358 Y97.449 E.0229
G1 X234.381 Y97.012 E.02292
G1 X234.358 Y96.575 E.02292
G1 X234.291 Y96.151 E.02246
G1 X234.179 Y95.729 E.02289
G1 X234.1 Y95.506 E.01235
G1 X233.926 Y95.115 E.02246
G1 X233.707 Y94.736 E.02291
G1 X233.45 Y94.382 E.02289
G1 X233.158 Y94.057 E.02289
G1 X232.833 Y93.765 E.02291
G1 X232.486 Y93.512 E.02249
G1 X232.285 Y93.389 E.01234
G1 X231.895 Y93.191 E.0229
G1 X231.494 Y93.038 E.02248
G1 X231.072 Y92.925 E.0229
G1 X230.64 Y92.856 E.0229
G1 X230.214 Y92.834 E.02233
G1 X229.976 Y92.84 E.01247
G1 X229.541 Y92.886 E.0229
G1 X229.122 Y92.976 E.02246
G1 X228.698 Y93.114 E.02337
G1 X228.361 Y93.264 E.01931
; OBJECT_ID: 12
; WIPE_START
G1 X227.927 Y93.508 E-.09453
G1 X227.574 Y93.765 E-.08305
G1 X227.248 Y94.057 E-.08317
G1 X226.956 Y94.382 E-.08302
G1 X226.844 Y94.536 E-.03623
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.573 Y96.858 Z.8 F36000
G1 X211.963 Y99.288 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.159 Y98.977 E.01244
G2 X208.77 Y93.115 I-3.386 J-1.953 E.27718
G1 X208.573 Y93.12 E.00667
G2 X211.926 Y99.335 I.201 J3.904 E.533
M204 S10000
G1 X211.622 Y99.066 F36000
G1 F1473.913
M204 S3000
G1 X211.807 Y98.774 E.01172
G2 X208.77 Y93.523 I-3.033 J-1.749 E.2483
G1 X208.594 Y93.527 E.00596
G2 X211.584 Y99.113 I.179 J3.497 E.47671
M204 S250
G1 X211.29 Y98.85 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.716 E.00509
G2 X208.771 Y93.915 I-2.609 J-1.692 E.20935
G1 X208.615 Y93.919 E.00489
G2 X211.192 Y98.98 I.159 J3.105 E.38815
G1 X211.254 Y98.898 E.00322
; WIPE_START
M204 S3000
G1 X211.383 Y98.716 E-.04223
G1 X211.549 Y98.437 E-.0618
G1 X211.681 Y98.139 E-.06187
G1 X211.82 Y97.671 E-.0927
G1 X211.871 Y97.35 E-.06188
G1 X211.887 Y97.037 E-.05952
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.764 Y99.481 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.972 Y99.79 E.01259
G2 X209.024 Y92.321 I3.811 J-2.765 E.64293
G1 X208.789 Y92.315 E.00794
G2 X204.704 Y99.377 I-.006 J4.709 E.33396
G1 X204.734 Y99.429 E.00205
M204 S10000
G1 X204.423 Y99.702 F36000
G1 F1473.913
M204 S3000
G1 X204.643 Y100.029 E.01331
G2 X209.045 Y91.915 I4.141 J-3.005 E.69851
G1 X208.79 Y91.908 E.00865
G2 X204.352 Y99.58 I-.006 J5.116 E.36282
G1 X204.393 Y99.651 E.00277
M204 S250
G1 X204.094 Y99.915 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.163 Y100.022 E.00398
G2 X209.066 Y91.523 I4.621 J-2.998 E.70565
G1 X208.79 Y91.516 E.00864
G2 X203.875 Y99.523 I-.006 J5.508 E.35279
G1 X204.064 Y99.863 E.01221
; WIPE_START
M204 S3000
G1 X204.163 Y100.022 E-.03548
G1 X204.496 Y100.492 E-.10947
M73 P20 R38
G1 X204.882 Y100.92 E-.10959
G1 X205.31 Y101.306 E-.10955
G1 X205.378 Y101.355 E-.01591
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.101 Y99.264 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435961
G1 F1526.561
M204 S3000
G1 X205.163 Y99.372 E.00406
G1 X205.428 Y99.737 E.01474
G1 X205.73 Y100.072 E.01475
G1 X206.065 Y100.374 E.01472
G1 X206.43 Y100.639 E.01474
G1 X206.82 Y100.864 E.0147
G1 X207.228 Y101.046 E.01461
G1 X207.451 Y101.125 E.00772
G1 X207.887 Y101.241 E.01475
G1 X208.327 Y101.311 E.01456
G1 X208.777 Y101.334 E.01475
G1 X209.228 Y101.311 E.01475
G1 X209.661 Y101.242 E.01431
G1 X209.897 Y101.186 E.00793
G1 X210.332 Y101.044 E.01498
G1 X210.734 Y100.864 E.01438
G1 X211.125 Y100.639 E.01474
G1 X211.49 Y100.374 E.01474
G1 X211.825 Y100.072 E.01474
G1 X212.127 Y99.737 E.01474
G1 X212.392 Y99.372 E.01475
G1 X212.617 Y98.981 E.01473
G1 X212.799 Y98.574 E.01458
G1 X212.878 Y98.352 E.00771
G1 X212.994 Y97.917 E.0147
G1 X213.063 Y97.475 E.01461
G1 X213.087 Y97.025 E.01475
G1 X213.063 Y96.574 E.01475
G1 X212.994 Y96.134 E.01456
G1 X212.939 Y95.904 E.00772
G1 X212.799 Y95.475 E.01473
G1 X212.617 Y95.068 E.01458
G1 X212.392 Y94.677 E.01474
G1 X212.126 Y94.312 E.01476
G1 X211.825 Y93.977 E.01473
G1 X211.49 Y93.675 E.01475
G1 X211.129 Y93.413 E.01457
G1 X210.739 Y93.187 E.01474
G1 X210.525 Y93.085 E.00773
G1 X210.109 Y92.926 E.01456
G1 X209.674 Y92.809 E.01474
G1 X209.228 Y92.739 E.01474
G1 X208.789 Y92.715 E.01439
G1 X208.547 Y92.721 E.00791
G1 X208.098 Y92.769 E.01474
G1 X207.662 Y92.862 E.01458
G1 X207.228 Y93.003 E.01491
G1 X206.821 Y93.185 E.01458
G1 X206.43 Y93.41 E.01474
G1 X206.065 Y93.676 E.01475
G1 X205.73 Y93.977 E.01473
G1 X205.428 Y94.313 E.01475
G1 X205.166 Y94.673 E.01458
G1 X204.94 Y95.064 E.01474
G1 X204.838 Y95.277 E.00771
G1 X204.679 Y95.693 E.01457
G1 X204.562 Y96.128 E.01474
G1 X204.491 Y96.574 E.01474
G1 X204.468 Y97.019 E.01458
G1 X204.474 Y97.255 E.00771
G1 X204.522 Y97.704 E.01473
G1 X204.615 Y98.141 E.01463
G1 X204.756 Y98.574 E.01487
G1 X204.938 Y98.981 E.01458
G1 X205.071 Y99.212 E.00873
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.03499
G1 X205.428 Y99.737 E-.08571
G1 X205.73 Y100.072 E-.08575
G1 X206.065 Y100.374 E-.0856
G1 X206.43 Y100.639 E-.08571
G1 X206.44 Y100.645 E-.00223
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X199.061 Y98.694 Z.8 F36000
G1 X183.9 Y94.685 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.719 Y94.958 E.01109
G2 X187.316 Y92.88 I3.601 J2.08 E.73721
G1 X187.106 Y92.885 E.0071
G2 X183.957 Y94.593 I.213 J4.153 E.12537
G1 X183.932 Y94.634 E.00164
M204 S10000
G1 X184.241 Y94.907 F36000
G1 F1473.913
M204 S3000
G1 X184.072 Y95.162 E.01037
G2 X187.317 Y93.287 I3.248 J1.877 E.66505
G1 X187.128 Y93.292 E.00639
G2 X184.286 Y94.832 I.192 J3.747 E.1131
G1 X184.272 Y94.855 E.00092
M204 S250
G1 X184.57 Y95.121 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.504 Y95.208 E.00342
G2 X187.317 Y93.679 I2.816 J1.831 E.55718
G1 X187.148 Y93.684 E.00529
G2 X184.711 Y94.923 I.172 J3.355 E.0883
G1 X184.605 Y95.072 E.00573
; WIPE_START
M204 S3000
G1 X184.504 Y95.208 E-.03211
G1 X184.33 Y95.514 E-.06686
G1 X184.187 Y95.835 E-.06682
G1 X184.038 Y96.341 E-.10019
G1 X183.983 Y96.688 E-.06682
G1 X183.97 Y96.936 E-.04721
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.401 Y92.317 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.336 Y92.315 E.00219
G2 X187.571 Y92.321 I-.006 J4.724 E.99662
G1 X187.461 Y92.318 E.00375
M204 S10000
G1 X187.411 Y91.91 F36000
G1 F1473.913
M204 S3000
G1 X187.336 Y91.908 E.00253
G2 X187.593 Y91.915 I-.006 J5.131 E1.08251
G1 X187.471 Y91.911 E.00411
M204 S250
G1 X187.422 Y91.518 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.337 Y91.516 E.00266
G2 X187.613 Y91.523 I-.006 J5.523 E1.07935
G1 X187.482 Y91.519 E.00413
; WIPE_START
M204 S3000
G1 X187.337 Y91.516 E-.0275
G1 X187.035 Y91.523 E-.05734
G1 X186.46 Y91.583 E-.10985
G1 X185.895 Y91.704 E-.10987
G1 X185.517 Y91.826 E-.07544
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.425 Y92.602 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200568
G1 F3805.962
M204 S3000
G1 X187.336 Y92.598 E.00117
G1 X187.091 Y92.603 E.00321
G1 X186.628 Y92.652 E.00611
G1 X186.175 Y92.749 E.00607
G1 X185.73 Y92.893 E.00613
G1 X185.308 Y93.081 E.00606
G1 X184.905 Y93.314 E.0061
G1 X184.529 Y93.587 E.0061
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.00609
G1 X183.6 Y94.618 E.00607
G1 X183.367 Y95.021 E.0061
G1 X183.265 Y95.235 E.00311
G1 X183.1 Y95.667 E.00606
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.00609
G1 X182.882 Y97.037 E.00607
G1 X182.889 Y97.274 E.0031
G1 X182.937 Y97.736 E.00609
G1 X183.034 Y98.189 E.00607
G1 X183.178 Y98.633 E.00613
G1 X183.367 Y99.057 E.00609
G1 X183.599 Y99.459 E.00608
G1 X183.872 Y99.835 E.0061
G1 X184.184 Y100.18 E.0061
G1 X184.529 Y100.491 E.00609
G1 X184.903 Y100.763 E.00607
G1 X185.306 Y100.996 E.00609
G1 X185.528 Y101.101 E.00322
G1 X185.952 Y101.263 E.00595
G1 X186.401 Y101.384 E.00609
G1 X186.86 Y101.457 E.00609
G1 X187.323 Y101.481 E.00608
G1 X187.786 Y101.457 E.00608
G1 X188.021 Y101.426 E.00311
G1 X188.474 Y101.33 E.00606
G1 X188.918 Y101.185 E.00613
G1 X189.341 Y100.997 E.00606
G1 X189.744 Y100.764 E.0061
G1 X190.12 Y100.491 E.0061
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.00609
G1 X191.048 Y99.46 E.00607
G1 X191.281 Y99.058 E.0061
G1 X191.387 Y98.835 E.00323
G1 X191.549 Y98.412 E.00594
G1 X191.669 Y97.963 E.00609
G1 X191.742 Y97.504 E.00609
G1 X191.766 Y97.039 E.0061
G1 X191.742 Y96.575 E.0061
G1 X191.669 Y96.116 E.00609
G1 X191.549 Y95.666 E.0061
G1 X191.383 Y95.234 E.00606
G1 X191.172 Y94.82 E.0061
G1 X191.043 Y94.61 E.00322
G1 X190.776 Y94.244 E.00594
G1 X190.465 Y93.898 E.0061
G1 X190.12 Y93.587 E.00609
G1 X189.745 Y93.315 E.00607
G1 X189.343 Y93.082 E.00609
G1 X189.129 Y92.98 E.00311
G1 X188.697 Y92.815 E.00606
G1 X188.248 Y92.694 E.00609
G1 X187.789 Y92.622 E.0061
G1 X187.484 Y92.606 E.00399
; OBJECT_ID: 10
; WIPE_START
G1 X187.336 Y92.598 E-.02829
G1 X187.091 Y92.603 E-.04656
G1 X186.628 Y92.652 E-.0885
G1 X186.175 Y92.749 E-.08796
G1 X185.73 Y92.893 E-.08884
G1 X185.538 Y92.979 E-.03986
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.908 Y93.137 Z.8 F36000
G1 X163.321 Y93.441 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.247 Y93.486 E.00292
G2 X165.832 Y92.646 I2.589 J3.569 E.84412
G1 X165.61 Y92.652 E.00752
G2 X163.635 Y93.235 I.226 J4.403 E.07035
G1 X163.371 Y93.408 E.01068
M204 S10000
G1 X163.542 Y93.782 F36000
G1 F1473.913
M204 S3000
G1 X163.487 Y93.815 E.00219
G2 X165.832 Y93.053 I2.349 J3.239 E.76618
G1 X165.631 Y93.058 E.00681
G2 X163.838 Y93.587 I.205 J3.996 E.06385
G1 X163.592 Y93.749 E.00996
M204 S250
G1 X163.756 Y94.111 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.717 Y94.133 E.00139
G2 X165.833 Y93.445 I2.119 J2.922 E.64018
G1 X165.652 Y93.45 E.00568
G2 X164.035 Y93.927 I.185 J3.605 E.05336
G1 X163.806 Y94.078 E.00859
; WIPE_START
M204 S3000
G1 X163.717 Y94.133 E-.01981
G1 X163.425 Y94.372 E-.07183
G1 X163.158 Y94.64 E-.0718
G1 X162.92 Y94.933 E-.07181
G1 X162.714 Y95.25 E-.07178
G1 X162.549 Y95.597 E-.07298
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.074 Y101.451 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.143 Y101.477 E.00251
G2 X166.088 Y92.321 I1.703 J-4.423 E.55478
G1 X165.852 Y92.315 E.00799
G2 X163.69 Y101.275 I-.006 J4.74 E.42844
G1 X164.019 Y101.426 E.01224
M204 S10000
G1 X163.909 Y101.822 F36000
G1 F1473.913
M204 S3000
G1 X163.997 Y101.857 E.00322
G2 X166.11 Y91.915 I1.85 J-4.803 E.60243
G1 X165.853 Y91.908 E.0087
G2 X163.506 Y101.638 I-.006 J5.147 E.46523
G1 X163.854 Y101.797 E.01297
M204 S250
G1 X163.749 Y102.18 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.856 Y102.223 E.00363
G2 X166.13 Y91.523 I1.991 J-5.169 E.60055
G1 X165.853 Y91.516 E.00869
G2 X163.328 Y101.987 I-.006 J5.539 E.46376
G1 X163.695 Y102.155 E.01266
; OBJECT_ID: 9
; WIPE_START
M204 S3000
G1 X163.856 Y102.223 E-.03336
G1 X164.407 Y102.406 E-.11016
G1 X164.689 Y102.474 E-.05511
G1 X165.262 Y102.565 E-.11021
G1 X165.636 Y102.584 E-.07115
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 9
M624 BAAAAAAAAAA=
M204 S10000
G1 X158.003 Y102.63 Z.8 F36000
G1 X147.898 Y102.69 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X148.126 Y102.539 E.00923
G2 X148.7 Y101.345 I-1.032 J-1.231 E.04623
G1 X148.7 Y94.274 E.23934
G2 X147.13 Y92.696 I-1.631 J.052 E.0829
G1 X137.064 Y92.696 E.34074
G2 X135.482 Y94.204 I.031 J1.616 E.08121
G1 X135.482 Y101.39 E.24323
G2 X137.051 Y102.914 I1.631 J-.108 E.08112
G1 X147.117 Y102.914 E.34074
G2 X147.822 Y102.74 I-.023 J-1.606 E.02478
G1 X147.848 Y102.723 E.00107
M204 S10000
G1 X147.675 Y102.352 F36000
G1 F1473.913
M204 S3000
G1 X147.857 Y102.22 E.00759
G2 X148.293 Y101.329 I-.789 J-.938 E.03458
G1 X148.293 Y94.287 E.23838
G2 X147.114 Y93.103 I-1.218 J.034 E.06228
G1 X137.075 Y93.103 E.33983
G2 X135.889 Y94.232 I.019 J1.207 E.06088
G1 X135.889 Y101.368 E.24155
G2 X137.067 Y102.507 I1.218 J-.081 E.06079
G1 X147.107 Y102.507 E.33984
G2 X147.62 Y102.376 I-.039 J-1.225 E.0181
M204 S250
G1 X147.46 Y102.026 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X147.606 Y101.922 E.0056
G2 X147.901 Y101.314 I-.531 J-.633 E.02185
G1 X147.901 Y94.299 E.21995
G2 X147.099 Y93.495 I-.821 J.017 E.03929
G1 X137.085 Y93.495 E.31398
G2 X136.281 Y94.259 I.008 J.813 E.03826
G1 X136.281 Y101.348 E.22225
G2 X137.082 Y102.115 I.821 J-.054 E.03818
G1 X147.096 Y102.115 E.31398
G2 X147.407 Y102.046 I-.022 J-.826 E.01005
; WIPE_START
M204 S3000
G1 X147.606 Y101.922 E-.04442
G1 X147.691 Y101.849 E-.02138
G1 X147.813 Y101.673 E-.04064
G1 X147.862 Y101.556 E-.02417
G1 X147.901 Y101.314 E-.04661
G1 X147.901 Y100.246 E-.20277
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X148.142 Y92.618 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X147.899 Y92.489 E.00929
G2 X147.116 Y92.315 I-.815 J1.823 E.02732
G1 X137.104 Y92.314 E.33893
G2 X135.1 Y94.318 I-.005 J1.998 E.10663
G1 X135.1 Y101.292 E.23606
G2 X137.104 Y103.296 I1.998 J.006 E.10663
G1 X147.078 Y103.296 E.33761
G2 X149.081 Y101.292 I.006 J-1.998 E.10663
G1 X149.081 Y94.318 E.23606
G2 X148.192 Y92.65 I-1.997 J-.006 E.06665
M204 S10000
G1 X148.319 Y92.25 F36000
G1 F1473.913
M204 S3000
G2 X147.122 Y91.908 I-1.236 J2.063 E.04263
G1 X137.098 Y91.907 E.33929
G2 X134.693 Y94.313 I.001 J2.406 E.12789
G1 X134.693 Y101.298 E.23642
G2 X137.098 Y103.703 I2.406 J-.001 E.12789
G1 X147.083 Y103.703 E.33797
G2 X149.489 Y101.298 I-.001 J-2.406 E.12789
G1 X149.489 Y94.313 E.23642
G2 X148.37 Y92.281 I-2.405 J0 E.08191
M204 S250
G1 X148.528 Y91.916 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X148.517 Y91.912 E.00038
G2 X147.127 Y91.516 I-1.434 J2.403 E.04582
G1 X137.093 Y91.515 E.3146
G2 X134.301 Y94.308 I.007 J2.799 E.13745
G1 X134.301 Y101.303 E.21931
G2 X137.093 Y104.095 I2.799 J-.007 E.13745
G1 X147.088 Y104.095 E.31337
G2 X149.881 Y101.303 I-.007 J-2.799 E.13745
G1 X149.881 Y94.308 E.21931
G2 X148.728 Y92.051 I-2.798 J.006 E.08246
G1 X148.578 Y91.949 E.0057
; OBJECT_ID: 8
; WIPE_START
M204 S3000
G1 X148.517 Y91.912 E-.01362
G1 X148.225 Y91.757 E-.06269
G1 X147.953 Y91.652 E-.05549
M73 P21 R38
G1 X147.671 Y91.576 E-.05548
G1 X147.382 Y91.531 E-.05549
G1 X147.127 Y91.516 E-.04855
G1 X146.66 Y91.516 E-.08868
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 9
M625
; start printing object, unique label id: 8
M624 AgAAAAAAAAA=
M204 S10000
G1 X139.42 Y93.931 Z.8 F36000
G1 X99.74 Y107.167 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X99.903 Y107.393 E.00941
G2 X101.051 Y107.914 I1.185 J-1.085 E.04386
G1 X121.117 Y107.914 E.67923
G2 X122.7 Y106.332 I-.024 J-1.606 E.0838
G1 X122.7 Y94.274 E.40814
G2 X121.13 Y92.696 I-1.607 J.028 E.08321
G1 X101.064 Y92.696 E.67923
G2 X99.481 Y94.279 I.024 J1.606 E.0838
G1 X99.481 Y106.343 E.40835
G2 X99.682 Y107.086 I1.606 J-.034 E.02632
G1 X99.705 Y107.119 E.00135
M204 S10000
G1 X100.069 Y106.931 F36000
G1 F1473.913
M204 S3000
G1 X100.209 Y107.11 E.00769
G2 X101.067 Y107.507 I.905 J-.828 E.03285
G1 X121.107 Y107.507 E.67832
G2 X122.293 Y106.321 I-.039 J-1.225 E.06254
G1 X122.293 Y94.287 E.40735
G2 X121.114 Y93.103 I-1.225 J.042 E.06219
G1 X101.075 Y93.103 E.67832
G2 X99.889 Y94.289 I.039 J1.225 E.06254
G1 X99.889 Y106.328 E.40748
G2 X100.042 Y106.877 I1.226 J-.046 E.0195
M204 S250
G1 X100.386 Y106.704 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X100.495 Y106.845 E.00562
G2 X101.082 Y107.115 I.612 J-.556 E.02081
G1 X121.096 Y107.115 E.62752
G2 X121.901 Y106.311 I-.022 J-.826 E.03934
G1 X121.901 Y94.299 E.37663
G2 X121.099 Y93.495 I-.826 J.023 E.03922
G1 X101.085 Y93.495 E.62752
G2 X100.281 Y94.3 I.022 J.826 E.03934
G1 X100.281 Y106.313 E.37667
G2 X100.363 Y106.65 I.826 J-.024 E.01096
; WIPE_START
M204 S3000
G1 X100.495 Y106.845 E-.04473
G1 X100.651 Y106.986 E-.04002
G1 X100.76 Y107.046 E-.02356
G1 X100.966 Y107.106 E-.04063
G1 X101.082 Y107.115 E-.02223
G1 X102.181 Y107.115 E-.20882
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X108.362 Y102.638 Z.8 F36000
G1 X122.169 Y92.635 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X121.117 Y92.315 I-1.085 J1.677 E.03772
G1 X101.104 Y92.314 E.67741
G2 X99.1 Y94.318 I-.006 J1.998 E.10663
G1 X99.1 Y106.292 E.4053
G2 X101.104 Y108.296 I1.998 J.006 E.10663
G1 X121.078 Y108.296 E.6761
G2 X123.081 Y106.292 I.006 J-1.998 E.10663
G1 X123.081 Y94.318 E.4053
G2 X122.219 Y92.669 I-1.997 J-.006 E.06555
M204 S10000
G1 X122.392 Y92.295 F36000
G1 F1473.913
M204 S3000
M73 P21 R37
G2 X121.122 Y91.908 I-1.309 J2.018 E.04555
G1 X101.098 Y91.907 E.67777
G2 X98.693 Y94.313 I.001 J2.406 E.12789
G1 X98.693 Y106.298 E.40567
G2 X101.098 Y108.703 I2.406 J-.001 E.12789
G1 X121.083 Y108.703 E.67646
G2 X123.489 Y106.298 I-.001 J-2.406 E.12789
G1 X123.489 Y94.313 E.40567
G2 X122.442 Y92.329 I-2.405 J0 E.07899
M204 S250
G1 X122.595 Y91.957 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X122.224 Y91.759 E.01317
G2 X121.127 Y91.516 I-1.142 J2.555 E.03547
G1 X101.093 Y91.515 E.62814
G2 X98.301 Y94.308 I.007 J2.799 E.13745
G1 X98.301 Y106.303 E.37608
G2 X101.093 Y109.095 I2.799 J-.007 E.13745
G1 X121.088 Y109.095 E.62692
G2 X123.881 Y106.303 I-.007 J-2.799 E.13745
G1 X123.881 Y94.308 E.37608
G2 X122.643 Y91.992 I-2.798 J.006 E.0857
; OBJECT_ID: 7
; WIPE_START
M204 S3000
G1 X122.224 Y91.759 E-.09109
G1 X121.953 Y91.652 E-.05545
G1 X121.671 Y91.576 E-.05548
G1 X121.382 Y91.531 E-.05549
G1 X121.127 Y91.516 E-.04855
G1 X120.738 Y91.516 E-.07394
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 8
M625
; start printing object, unique label id: 7
M624 AQAAAAAAAAA=
M204 S10000
G1 X116.278 Y97.71 Z.8 F36000
G1 X85.842 Y139.98 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X86.078 Y139.607 E.01491
G2 X86.7 Y137.318 I-4.002 J-2.317 E.08119
G1 X86.7 Y97.292 E1.35485
G2 X82.104 Y92.696 I-4.624 J.028 E.24396
G1 X26.077 Y92.696 E1.89643
G2 X21.481 Y97.292 I.028 J4.624 E.24396
G1 X21.481 Y137.318 E1.35485
G2 X26.077 Y141.914 I4.624 J-.028 E.24397
G1 X82.104 Y141.914 E1.89643
G2 X85.804 Y140.026 I-.028 J-4.624 E.14584
M204 S10000
G1 X85.474 Y139.794 F36000
G1 F1473.913
M204 S3000
G1 X85.486 Y139.772 E.00085
G2 X86.293 Y137.313 I-3.409 J-2.48 E.08903
G1 X86.293 Y97.297 E1.35449
G2 X82.099 Y93.103 I-4.216 J.021 E.22269
G1 X26.083 Y93.103 E1.89607
G2 X21.889 Y97.297 I.022 J4.216 E.22269
G1 X21.889 Y137.313 E1.35449
G2 X26.083 Y141.507 I4.216 J-.021 E.22269
M73 P22 R37
G1 X82.099 Y141.507 E1.89607
G2 X85.058 Y140.273 I-.022 J-4.216 E.11135
G1 X85.435 Y139.839 E.01944
M204 S250
G1 X85.169 Y139.542 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G2 X85.901 Y137.308 I-3.091 J-2.249 E.0749
G1 X85.901 Y97.302 E1.25435
G2 X82.093 Y93.495 I-3.823 J.015 E.1873
G1 X26.088 Y93.495 E1.75602
G2 X22.281 Y97.302 I.015 J3.823 E.1873
G1 X22.281 Y137.308 E1.25435
G2 X26.088 Y141.115 I3.823 J-.015 E.1873
G1 X82.093 Y141.115 E1.75602
G2 X85.133 Y139.59 I-.015 J-3.823 E.11052
; WIPE_START
M204 S3000
G1 X85.39 Y139.21 E-.08707
G1 X85.571 Y138.855 E-.07576
G1 X85.714 Y138.483 E-.07581
G1 X85.817 Y138.097 E-.07577
G1 X85.871 Y137.756 E-.0656
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X78.261 Y138.329 Z.8 F36000
G1 X25.754 Y142.281 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.83 Y142.289 E.00258
G2 X26.104 Y142.296 I.266 J-4.989 E.00928
G1 X82.078 Y142.296 E1.89465
G2 X87.081 Y137.292 I.008 J-4.996 E.26617
G1 X87.081 Y97.318 E1.35307
G2 X82.156 Y92.316 I-4.993 J-.009 E.2635
G1 X26.104 Y92.314 E1.89731
G2 X21.1 Y97.318 I.004 J5.008 E.26599
G1 X21.1 Y137.292 E1.35307
G2 X25.31 Y142.234 I4.996 J.008 E.23919
G1 X25.694 Y142.275 E.01309
M204 S10000
G1 X25.711 Y142.685 F36000
G1 F1473.913
M204 S3000
G1 X25.808 Y142.696 E.0033
G2 X26.098 Y142.703 I.287 J-5.395 E.00982
G1 X82.083 Y142.703 E1.89502
G2 X87.489 Y137.298 I.003 J-5.403 E.28745
G1 X87.489 Y97.313 E1.35343
G2 X82.161 Y91.909 I-5.4 J-.004 E.28478
G1 X26.098 Y91.907 E1.89767
G2 X20.693 Y97.313 I.011 J5.416 E.28726
G1 X20.693 Y137.298 E1.35343
M73 P23 R37
G2 X25.246 Y142.636 I5.403 J.003 E.25849
G1 X25.652 Y142.679 E.01381
M204 S250
G1 X25.67 Y143.075 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.788 Y143.086 E.0037
G2 X26.093 Y143.095 I.322 J-5.8 E.00958
G1 X82.088 Y143.095 E1.75567
G2 X87.881 Y137.303 I-.017 J-5.809 E.28507
G1 X87.881 Y97.308 E1.254
G2 X82.166 Y91.517 I-5.792 J.001 E.2828
G1 X26.093 Y91.515 E1.75813
G2 X20.301 Y97.308 I.017 J5.809 E.28507
G1 X20.301 Y137.303 E1.254
G2 X25.185 Y143.021 I5.809 J-.017 E.25648
G1 X25.611 Y143.068 E.01343
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X25.788 Y143.086 E-.0338
M73 P23 R36
G1 X26.093 Y143.095 E-.05806
G1 X27.61 Y143.095 E-.28814
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 7
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X32.885 Y148.611 Z.8 F36000
G1 X47.231 Y163.613 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.611 E.00522
G2 X47.385 Y154.321 I-.238 J-4.645 E.47852
G1 X47.153 Y154.315 E.00784
G2 X46.898 Y163.611 I-.006 J4.651 E.48639
G1 X47.171 Y163.612 E.00921
M204 S10000
G1 X47.231 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00594
G2 X47.406 Y153.914 I-.258 J-5.052 E.5204
G1 X47.154 Y153.908 E.00855
G2 X46.877 Y164.017 I-.006 J5.058 E.52895
G1 X47.171 Y164.019 E.00993
M204 S250
G1 X47.231 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00615
G2 X47.427 Y153.523 I-.279 J-5.443 E.5194
G1 X47.154 Y153.516 E.00855
G2 X46.857 Y164.409 I-.006 J5.451 E.52794
G1 X47.171 Y164.411 E.00984
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.04867
G1 X47.994 Y164.351 E-.10845
G1 X48.553 Y164.233 E-.10846
G1 X49.095 Y164.056 E-.10837
G1 X49.124 Y164.043 E-.00606
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.292 Y162.905 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43458
G1 F1531.941
M204 S3000
G1 X50.415 Y161.782 E.05172
G2 X51.195 Y160.448 I-3.489 J-2.935 E.05056
G1 X48.623 Y163.02 E.11844
G3 X47.868 Y163.221 I-1.337 J-3.496 E.0255
G1 X51.396 Y159.693 E.1625
G2 X51.454 Y159.081 I-5.632 J-.843 E.02003
G1 X47.256 Y163.279 E.19336
G3 X46.722 Y163.259 I-.17 J-2.55 E.01742
G1 X51.433 Y158.548 E.21698
G2 X51.36 Y158.068 I-2.345 J.115 E.01584
G1 X46.243 Y163.185 E.23566
G3 X45.806 Y163.067 I.34 J-2.136 E.01475
G1 X51.242 Y157.631 E.25036
G2 X51.094 Y157.226 I-2.65 J.742 E.01407
G1 X45.405 Y162.914 E.26198
G3 X45.035 Y162.73 I.689 J-1.849 E.01348
G1 X50.907 Y156.858 E.27044
G2 X50.694 Y156.518 I-1.727 J.848 E.01311
G1 X44.693 Y162.519 E.27635
G3 X44.376 Y162.282 I1.347 J-2.141 E.0129
G1 X50.454 Y156.204 E.27992
G2 X50.189 Y155.915 I-1.506 J1.115 E.01279
G1 X44.09 Y162.014 E.28089
G3 X43.822 Y161.728 I1.682 J-1.843 E.01278
G1 X49.899 Y155.651 E.27989
G2 X49.587 Y155.409 I-1.693 J1.863 E.01287
G1 X43.586 Y161.41 E.27638
G3 X43.375 Y161.068 I1.525 J-1.178 E.01313
G1 X49.242 Y155.2 E.27024
G2 X48.872 Y155.017 I-1.057 J1.668 E.01349
G1 X43.191 Y160.697 E.26162
G3 X43.039 Y160.296 I1.83 J-.925 E.01401
G1 X48.47 Y154.864 E.25015
G2 X48.033 Y154.748 I-.773 J2.021 E.01476
G1 X42.922 Y159.858 E.23539
G3 X42.849 Y159.378 I2.246 J-.59 E.01585
G1 X47.553 Y154.674 E.21666
G2 X47.019 Y154.654 I-.36 J2.528 E.01745
G1 X42.829 Y158.844 E.19295
G3 X42.89 Y158.23 I5.561 J.237 E.02011
G1 X46.404 Y154.715 E.16188
G2 X45.647 Y154.918 I.588 J3.701 E.02558
G1 X43.094 Y157.471 E.11759
G3 X43.998 Y156.013 I4.132 J1.553 E.05624
G1 X44.972 Y155.039 E.04485
; OBJECT_ID: 14
; WIPE_START
G1 X43.998 Y156.013 E-.26165
G1 X43.786 Y156.249 E-.06043
G1 X43.606 Y156.496 E-.05792
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X35.981 Y156.158 Z.8 F36000
G1 X26.809 Y155.753 Z.8
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.668 Y155.708 E.00503
G2 X25.779 Y155.591 I-.886 J3.292 E.03043
G1 X25.607 Y155.595 E.00583
G2 X27.007 Y155.818 I.175 J3.404 E.67665
G1 X26.866 Y155.772 E.00502
M204 S10000
G1 X26.684 Y156.139 F36000
G1 F1473.913
M204 S3000
G1 X26.562 Y156.101 E.00432
G2 X25.779 Y155.998 I-.78 J2.899 E.02681
G1 X25.628 Y156.002 E.00511
G2 X26.861 Y156.198 I.154 J2.998 E.59584
G1 X26.741 Y156.158 E.00429
M204 S250
G1 X26.563 Y156.512 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.461 Y156.48 E.00335
G2 X25.78 Y156.39 I-.678 J2.52 E.0216
G1 X25.649 Y156.393 E.00411
G2 X26.72 Y156.564 I.134 J2.606 E.47983
G1 X26.619 Y156.531 E.00333
; WIPE_START
M204 S3000
G1 X26.461 Y156.48 E-.0317
G1 X26.194 Y156.422 E-.05189
G1 X25.78 Y156.39 E-.0789
G1 X25.649 Y156.393 E-.02488
M73 P24 R36
G1 X25.243 Y156.447 E-.07782
G1 X24.979 Y156.518 E-.05194
G1 X24.724 Y156.616 E-.05187
G1 X24.673 Y156.643 E-.01101
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.866 Y154.317 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.797 Y154.315 E.00234
G2 X26.03 Y154.321 I-.006 J4.684 E.98836
G1 X25.926 Y154.318 E.00352
M204 S10000
G1 X25.877 Y153.91 F36000
G1 F1473.913
M204 S3000
G1 X25.797 Y153.908 E.00269
G2 X26.052 Y153.915 I-.006 J5.092 E1.07425
G1 X25.937 Y153.912 E.00388
M204 S250
G1 X25.887 Y153.518 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.798 Y153.516 E.0028
G2 X26.072 Y153.523 I-.006 J5.484 E1.0717
G1 X25.947 Y153.52 E.00392
; WIPE_START
M204 S3000
G1 X25.798 Y153.516 E-.02838
G1 X25.498 Y153.523 E-.05694
G1 X24.927 Y153.583 E-.10908
G1 X24.366 Y153.702 E-.10905
G1 X23.983 Y153.827 E-.07654
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X24.644 Y154.911 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.47886
G1 F1376.337
M204 S3000
G1 X24.236 Y155.035 E.01547
G1 X23.676 Y155.3 E.02246
G2 X22.918 Y155.85 I4.551 J7.062 E.03395
G1 X22.355 Y156.479 E.03061
G2 X21.677 Y157.873 I4.206 J2.91 E.05639
G2 X21.534 Y158.801 I8.131 J1.731 E.03405
G1 X21.578 Y159.643 E.03058
G2 X21.82 Y160.547 I7.224 J-1.451 E.03394
G1 X22.206 Y161.304 E.03081
G1 X22.606 Y161.836 E.02414
G1 X22.965 Y162.187 E.0182
G1 X23.613 Y162.651 E.02889
G1 X23.873 Y162.804 E.01092
G2 X24.705 Y163.12 I3.519 J-8.022 E.03229
G1 X25.54 Y163.249 E.03061
G2 X26.474 Y163.2 I.082 J-7.367 E.03393
G1 X27.295 Y162.98 E.0308
G1 X27.752 Y162.774 E.0182
G2 X28.652 Y162.15 I-3.342 J-5.781 E.03974
G1 X29.215 Y161.52 E.03061
G2 X29.893 Y160.125 I-4.161 J-2.883 E.05647
G2 X30.04 Y159.2 I-8.211 J-1.776 E.03395
G1 X29.995 Y158.351 E.03083
G1 X29.842 Y157.709 E.0239
G2 X29.46 Y156.853 I-7.122 J2.664 E.03401
G1 X28.964 Y156.169 E.03062
G2 X28.268 Y155.542 I-5.277 J5.162 E.03399
G1 X27.532 Y155.118 E.03076
G1 X27.063 Y154.941 E.01819
G2 X25.985 Y154.746 I-1.725 J6.456 E.03975
G1 X25.142 Y154.792 E.0306
G1 X24.702 Y154.897 E.01639
; WIPE_START
G1 X25.142 Y154.792 E-.08592
G1 X25.985 Y154.746 E-.16039
G1 X26.282 Y154.781 E-.05677
G1 X26.679 Y154.862 E-.07693
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.589 Y161.083 Z.8 F36000
G1 Z.4
G1 E.4 F1800
; LINE_WIDTH: 0.471331
G1 F1400.527
M204 S3000
G1 X22.368 Y160.716 E.01523
G1 X22.098 Y160.011 E.02691
G1 X21.968 Y159.222 E.02847
G1 X22.006 Y158.421 E.02859
G1 X22.139 Y157.836 E.02137
G1 X22.463 Y157.107 E.02842
G1 X22.931 Y156.456 E.02854
G1 X23.363 Y156.039 E.02138
G3 X24.068 Y155.581 I3.72 J4.952 E.02999
G1 X24.775 Y155.312 E.02693
G1 X25.566 Y155.183 E.02856
G1 X26.166 Y155.193 E.02139
G1 X26.793 Y155.315 E.02276
G3 X27.716 Y155.7 I-1.405 J4.677 E.03569
G1 X28.327 Y156.144 E.02691
G1 X28.866 Y156.735 E.02848
G1 X29.269 Y157.425 E.02848
G1 X29.524 Y158.185 E.02856
G3 X29.274 Y160.544 I-3.725 J.798 E.08594
G1 X29.085 Y160.932 E.01536
G1 X28.64 Y161.544 E.02696
G1 X28.208 Y161.961 E.02139
G1 X27.678 Y162.318 E.02275
G3 X26.753 Y162.699 I-2.313 J-4.298 E.0357
G1 X26.008 Y162.817 E.02689
G1 X25.206 Y162.78 E.02859
G1 X24.621 Y162.644 E.02138
G1 X24.041 Y162.398 E.02246
G1 X23.366 Y161.956 E.02874
G1 X22.939 Y161.552 E.02094
G1 X22.625 Y161.131 E.01872
; CHANGE_LAYER
; Z_HEIGHT: 0.6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1400.527
G1 X22.939 Y161.552 E-.09984
G1 X23.366 Y161.956 E-.11171
G1 X24.041 Y162.398 E-.15328
G1 X24.115 Y162.429 E-.01517
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L3
M991 S0 P2 ;notify layer change


M204 S10000
G17
G3 Z.8 I1.217 J0 P1  F36000
; object ids of layer 3 start: 7,8,9,10,11,12,13,14,15
M624 /wEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer3 end: 7,8,9,10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.162 Y93.507
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X229.072 Y93.53 E.00313
G2 X230.191 Y93.352 I1.125 J3.482 E.73963
G1 X230.011 Y93.357 E.00609
G2 X229.442 Y93.431 I.185 J3.654 E.01946
G1 X229.22 Y93.491 E.0078
M204 S10000
G1 X229.267 Y93.9 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.917 E.00241
G2 X230.192 Y93.76 I1 J3.094 E.65734
G1 X230.033 Y93.764 E.00539
G2 X229.527 Y93.83 I.165 J3.247 E.0173
G1 X229.325 Y93.884 E.00708
M204 S250
G1 X229.368 Y94.278 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.29 E.00159
G2 X230.193 Y94.152 I.879 J2.721 E.53549
G1 X230.054 Y94.155 E.00437
G2 X229.608 Y94.213 I.144 J2.856 E.01409
G1 X229.426 Y94.263 E.00592
; WIPE_START
M204 S3000
G1 X229.319 Y94.29 E-.02106
G1 X229.04 Y94.399 E-.05688
G1 X228.773 Y94.535 E-.05687
G1 X228.522 Y94.698 E-.05687
G1 X228.181 Y94.989 E-.08531
G1 X227.889 Y95.331 E-.08528
G1 X227.838 Y95.409 E-.01772
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.073 Y92.831 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X230.449 Y92.321 I2.14 J4.18 E.91553
G1 X230.223 Y92.315 E.00765
G2 X228.127 Y92.804 I-.01 J4.696 E.0735
M204 S10000
G1 X227.888 Y92.468 F36000
G1 F1473.913
M204 S3000
G2 X230.47 Y91.915 I2.325 J4.543 E.9949
G1 X230.224 Y91.908 E.00835
G2 X227.942 Y92.441 I-.01 J5.103 E.08003
M204 S250
G1 X227.712 Y92.112 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.71 Y92.119 E.00022
G2 X230.491 Y91.523 I2.503 J4.892 E.9924
G1 X230.224 Y91.516 E.00836
G2 X228.235 Y91.885 I-.01 J5.495 E.06379
G1 X227.767 Y92.088 E.016
; WIPE_START
M204 S3000
G1 X227.71 Y92.119 E-.0123
G1 X227.209 Y92.402 E-.10931
G1 X226.744 Y92.74 E-.10927
G1 X226.317 Y93.125 E-.1093
G1 X226.176 Y93.281 E-.03982
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.307 Y93.29 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672829
G1 F952.519
M204 S3000
G2 X226.025 Y97.003 I1.899 J3.725 E.24014
G1 X226.049 Y97.456 E.02377
G1 X226.169 Y98.099 E.03423
G1 X226.386 Y98.711 E.03402
G1 X226.699 Y99.287 E.03434
G1 X227.098 Y99.807 E.03434
G1 X227.567 Y100.253 E.03391
G1 X228.107 Y100.626 E.03435
G1 X228.522 Y100.836 E.02438
G1 X229.122 Y101.047 E.03331
G1 X229.766 Y101.167 E.03431
G1 X230.421 Y101.184 E.03433
G1 X231.053 Y101.102 E.03339
G1 X231.502 Y100.982 E.02432
G1 X232.107 Y100.73 E.03432
G1 X232.659 Y100.392 E.03391
G1 X233.153 Y99.97 E.03403
G1 X233.578 Y99.474 E.03424
G1 X233.826 Y99.093 E.02377
G1 X234.104 Y98.509 E.03389
G1 X234.29 Y97.88 E.03433
G1 X234.375 Y97.239 E.03391
G1 X234.375 Y96.785 E.02378
G1 X234.29 Y96.143 E.0339
G1 X234.104 Y95.514 E.03434
G1 X233.825 Y94.93 E.0339
G1 X233.578 Y94.549 E.02377
G1 X233.157 Y94.057 E.03392
G1 X232.659 Y93.631 E.03434
G1 X232.1 Y93.289 E.03433
G1 X231.502 Y93.041 E.03393
G1 X230.865 Y92.886 E.03433
G1 X230.41 Y92.839 E.02393
G2 X228.361 Y93.263 I-.204 J4.176 E.1108
; OBJECT_ID: 12
; WIPE_START
G1 X227.928 Y93.508 E-.09451
G1 X227.574 Y93.765 E-.08308
G1 X227.255 Y94.052 E-.08156
G1 X226.956 Y94.382 E-.0846
G1 X226.844 Y94.536 E-.03625
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.577 Y96.87 Z1 F36000
G1 X211.932 Y99.325 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.051 Y99.15 E.00716
G2 X208.765 Y93.115 I-3.28 J-2.126 E.28412
G1 X208.573 Y93.12 E.0065
G2 X211.811 Y99.481 I.198 J3.904 E.52684
G1 X211.895 Y99.373 E.00465
M204 S10000
G1 X211.603 Y99.086 F36000
G1 F1473.913
M204 S3000
G1 X211.71 Y98.929 E.00644
G2 X208.766 Y93.523 I-2.938 J-1.904 E.25453
G1 X208.594 Y93.527 E.0058
G2 X211.495 Y99.225 I.177 J3.497 E.47198
G1 X211.566 Y99.134 E.00392
M204 S250
G1 X211.289 Y98.858 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.289 Y98.85 E.00026
G2 X208.766 Y93.915 I-2.517 J-1.825 E.21448
G1 X208.615 Y93.919 E.00475
G2 X211.085 Y99.102 I.157 J3.106 E.38316
G1 X211.251 Y98.904 E.00812
; WIPE_START
M204 S3000
G1 X211.289 Y98.85 E-.01261
G1 X211.471 Y98.58 E-.06182
G1 X211.623 Y98.279 E-.06397
G1 X211.735 Y97.986 E-.05973
G1 X211.82 Y97.671 E-.06185
G1 X211.871 Y97.35 E-.06183
G1 X211.879 Y97.044 E-.0582
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.758 Y99.471 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.974 Y99.788 E.01297
G2 X209.024 Y92.321 I3.813 J-2.763 E.64314
G1 X208.797 Y92.315 E.00767
G2 X204.707 Y99.375 I-.01 J4.709 E.33403
G1 X204.73 Y99.418 E.00166
M204 S10000
G1 X204.417 Y99.693 F36000
G1 F1473.913
M204 S3000
G1 X204.645 Y100.027 E.01369
G2 X209.045 Y91.915 I4.142 J-3.003 E.69872
G1 X208.798 Y91.908 E.00837
G2 X204.355 Y99.578 I-.01 J5.116 E.36288
G1 X204.388 Y99.64 E.00239
M204 S250
G1 X204.089 Y99.906 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.329 Y100.257 E.01333
G2 X209.066 Y91.523 I4.46 J-3.233 E.69683
G1 X208.799 Y91.516 E.00838
G2 X204.015 Y99.774 I-.01 J5.508 E.36188
G1 X204.06 Y99.854 E.00285
; WIPE_START
M204 S3000
G1 X204.329 Y100.257 E-.09212
G1 X204.683 Y100.711 E-.10946
G1 X204.882 Y100.92 E-.05482
G1 X205.31 Y101.306 E-.10956
G1 X205.37 Y101.35 E-.01404
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.097 Y99.257 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435941
G1 F1526.637
M204 S3000
G1 X205.163 Y99.372 E.00435
G1 X205.575 Y99.908 E.0221
G1 X206.051 Y100.362 E.0215
G1 X206.244 Y100.511 E.00797
G1 X206.618 Y100.754 E.01456
G1 X207.042 Y100.969 E.01555
G1 X207.663 Y101.188 E.02148
G1 X208.327 Y101.311 E.02208
G1 X209.003 Y101.328 E.0221
G1 X209.669 Y101.241 E.02195
G1 X210.117 Y101.121 E.01516
G1 X210.526 Y100.964 E.01431
G1 X210.739 Y100.862 E.00772
G1 X211.31 Y100.511 E.02192
G1 X211.821 Y100.076 E.02194
G1 X211.984 Y99.904 E.00771
G1 X212.261 Y99.562 E.0144
G1 X212.512 Y99.175 E.01508
G1 X212.801 Y98.569 E.02193
G1 X212.993 Y97.921 E.02209
G1 X213.081 Y97.255 E.02194
G1 X213.081 Y96.794 E.01508
G1 X212.993 Y96.129 E.02193
G1 X212.801 Y95.48 E.02211
G1 X212.51 Y94.87 E.02209
G1 X212.13 Y94.316 E.02194
G1 X211.821 Y93.974 E.01507
G1 X211.309 Y93.537 E.022
G1 X210.734 Y93.185 E.02203
G1 X210.114 Y92.928 E.02193
G1 X209.888 Y92.861 E.0077
G1 X209.456 Y92.769 E.01442
G1 X208.995 Y92.721 E.01516
G2 X204.468 Y97.025 I-.214 J4.307 E.22829
G1 X204.521 Y97.699 E.0221
G1 X204.677 Y98.351 E.02192
G1 X204.756 Y98.574 E.00772
G1 X204.934 Y98.974 E.01432
G1 X205.067 Y99.205 E.00868
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.03669
G1 X205.575 Y99.908 E-.1285
G1 X206.051 Y100.362 E-.12501
G1 X206.244 Y100.511 E-.04631
G1 X206.436 Y100.636 E-.04348
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X199.059 Y98.677 Z1 F36000
G1 X183.921 Y94.656 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.831 Y94.771 E.00494
G2 X187.311 Y92.88 I3.486 J2.268 E.74476
G1 X187.106 Y92.885 E.00692
G2 X184.088 Y94.419 I.211 J4.153 E.11803
G1 X183.956 Y94.607 E.00778
M204 S10000
G1 X184.25 Y94.895 F36000
G1 F1473.913
M204 S3000
G1 X184.173 Y94.993 E.00422
G2 X187.311 Y93.287 I3.144 J2.046 E.67187
G1 X187.128 Y93.292 E.00622
G2 X184.405 Y94.675 I.19 J3.747 E.10648
G1 X184.285 Y94.846 E.00706
M204 S250
G1 X184.567 Y95.124 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.41 Y95.357 E.00879
G2 X187.312 Y93.679 I2.908 J1.682 E.5518
G1 X187.148 Y93.684 E.00513
G2 X184.602 Y95.061 I.17 J3.355 E.09385
G1 X184.596 Y95.072 E.00037
; WIPE_START
M204 S3000
G1 X184.41 Y95.357 E-.06465
G1 X184.255 Y95.673 E-.0669
G1 X184.129 Y96.001 E-.06683
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06679
G1 X183.976 Y96.94 E-.048
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.404 Y92.317 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.344 Y92.315 E.00205
G2 X187.571 Y92.321 I-.01 J4.723 E.99688
G1 X187.464 Y92.318 E.00362
M204 S10000
G1 X187.415 Y91.91 F36000
G1 F1473.913
M204 S3000
G1 X187.345 Y91.908 E.00238
G2 X187.593 Y91.915 I-.01 J5.131 E1.08278
M73 P25 R36
G1 X187.475 Y91.912 E.00398
M204 S250
G1 X187.425 Y91.518 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.345 Y91.516 E.00251
G2 X187.613 Y91.523 I-.01 J5.523 E1.07961
G1 X187.485 Y91.52 E.00401
; WIPE_START
M204 S3000
G1 X187.345 Y91.516 E-.0266
G1 X187.035 Y91.523 E-.059
G1 X186.46 Y91.583 E-.10981
G1 X185.895 Y91.704 E-.10985
G1 X185.521 Y91.825 E-.07474
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.486 Y92.603 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200561
G1 F3806.129
M204 S3000
G1 X187.09 Y92.604 E.00519
G2 X182.882 Y97.037 I.238 J4.439 E.08834
G1 X182.889 Y97.274 E.00311
G1 X182.936 Y97.729 E.006
G1 X183.034 Y98.191 E.00618
G1 X183.177 Y98.629 E.00604
G1 X183.266 Y98.844 E.00305
G1 X183.367 Y99.058 E.0031
G1 X183.599 Y99.459 E.00607
G1 X183.732 Y99.652 E.00307
G1 X184.023 Y100.011 E.00607
G1 X184.185 Y100.182 E.00308
G1 X184.529 Y100.491 E.00606
G1 X184.715 Y100.634 E.00308
G1 X185.101 Y100.885 E.00604
G1 X185.535 Y101.104 E.00637
G1 X186.174 Y101.33 E.00888
G1 X186.403 Y101.384 E.00308
G1 X186.86 Y101.457 E.00606
G1 X187.322 Y101.481 E.00607
G1 X187.556 Y101.475 E.00307
G1 X187.791 Y101.456 E.00308
G1 X188.246 Y101.384 E.00604
G1 X188.699 Y101.263 E.00615
G1 X189.129 Y101.098 E.00604
G1 X189.343 Y100.996 E.0031
G1 X189.742 Y100.765 E.00604
G1 X189.935 Y100.633 E.00307
G1 X190.12 Y100.491 E.00305
G1 X190.464 Y100.181 E.00607
G1 X190.778 Y99.833 E.00615
G1 X191.048 Y99.46 E.00603
G1 X191.172 Y99.258 E.0031
G1 X191.284 Y99.052 E.00308
G1 X191.471 Y98.631 E.00604
G1 X191.549 Y98.41 E.00308
G1 X191.669 Y97.963 E.00606
G1 X191.742 Y97.506 E.00607
G1 X191.76 Y97.271 E.00308
G1 X191.766 Y97.037 E.00307
G1 X191.742 Y96.577 E.00604
G1 X191.669 Y96.114 E.00614
G1 X191.549 Y95.669 E.00604
G1 X191.471 Y95.447 E.00308
G1 X191.284 Y95.026 E.00604
G1 X191.172 Y94.82 E.00308
G1 X190.917 Y94.427 E.00615
G1 X190.626 Y94.068 E.00605
G1 X190.465 Y93.898 E.00307
G1 X190.295 Y93.737 E.00307
G1 X189.935 Y93.446 E.00607
G1 X189.742 Y93.313 E.00308
G1 X189.341 Y93.081 E.00607
G1 X189.129 Y92.98 E.00308
G1 X188.699 Y92.815 E.00604
G1 X188.472 Y92.748 E.0031
G1 X188.021 Y92.652 E.00605
G1 X187.552 Y92.603 E.00618
G1 X187.546 Y92.603 E.00008
; OBJECT_ID: 10
; WIPE_START
G1 X187.09 Y92.604 E-.08665
G1 X186.629 Y92.652 E-.08798
G1 X186.175 Y92.749 E-.08831
G1 X185.732 Y92.892 E-.08839
G1 X185.595 Y92.954 E-.02867
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.964 Y93.121 Z1 F36000
G1 X163.318 Y93.443 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.247 Y93.485 E.0028
G2 X165.826 Y92.646 I2.587 J3.57 E.8443
G1 X165.61 Y92.652 E.00733
G2 X163.634 Y93.234 I.223 J4.403 E.07036
G1 X163.368 Y93.41 E.0108
M204 S10000
G1 X163.549 Y93.78 F36000
G1 F1473.913
M204 S3000
G1 X163.486 Y93.814 E.00242
G2 X165.827 Y93.053 I2.348 J3.241 E.76635
G1 X165.631 Y93.058 E.00663
G2 X164.022 Y93.487 I.202 J3.996 E.05677
G1 X163.6 Y93.748 E.01682
M204 S250
G1 X163.753 Y94.113 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.717 Y94.132 E.00128
G2 X165.827 Y93.445 I2.117 J2.923 E.64032
G1 X165.652 Y93.45 E.00551
G2 X164.2 Y93.836 I.182 J3.605 E.04743
G1 X163.804 Y94.082 E.01462
; WIPE_START
M204 S3000
G1 X163.717 Y94.132 E-.01914
G1 X163.425 Y94.372 E-.07185
G1 X163.158 Y94.639 E-.07177
G1 X162.92 Y94.933 E-.0718
G1 X162.714 Y95.25 E-.07183
G1 X162.542 Y95.587 E-.0718
G1 X162.539 Y95.596 E-.0018
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.077 Y101.452 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.143 Y101.476 E.00238
G2 X166.088 Y92.321 I1.707 J-4.421 E.55503
G1 X165.86 Y92.315 E.00772
G2 X163.689 Y101.273 I-.01 J4.739 E.42839
G1 X164.023 Y101.427 E.01243
M204 S10000
G1 X163.912 Y101.823 F36000
G1 F1473.913
M204 S3000
G1 X163.997 Y101.856 E.0031
G2 X166.11 Y91.915 I1.853 J-4.801 E.60269
G1 X165.861 Y91.908 E.00842
G2 X163.505 Y101.636 I-.01 J5.147 E.4652
G1 X163.857 Y101.798 E.01313
M204 S250
G1 X163.752 Y102.181 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.857 Y102.222 E.00352
G2 X166.13 Y91.523 I1.994 J-5.167 E.60079
G1 X165.862 Y91.516 E.00842
G2 X163.328 Y101.985 I-.01 J5.539 E.46376
G1 X163.698 Y102.156 E.01277
; OBJECT_ID: 9
; WIPE_START
M204 S3000
G1 X163.857 Y102.222 E-.03274
G1 X164.407 Y102.406 E-.11015
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.639 Y102.587 E-.01674
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 9
M624 BAAAAAAAAAA=
M204 S10000
G1 X158.007 Y102.663 Z1 F36000
G1 X147.765 Y102.765 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X147.817 Y102.732 E.00211
G2 X148.7 Y101.345 I-.753 J-1.453 E.05828
G1 X148.7 Y94.279 E.2392
G2 X147.131 Y92.696 I-1.636 J.053 E.08297
G1 X137.064 Y92.696 E.34074
G2 X135.482 Y94.221 I.03 J1.614 E.08179
G1 X135.482 Y101.389 E.24264
G2 X137.051 Y102.914 I1.631 J-.108 E.08112
G1 X147.117 Y102.914 E.34074
G2 X147.63 Y102.814 I-.053 J-1.636 E.01776
G1 X147.709 Y102.786 E.00283
M204 S10000
G1 X147.669 Y102.356 F36000
G1 F1473.913
M204 S3000
G1 X147.886 Y102.196 E.00911
G2 X148.293 Y101.329 I-.815 J-.912 E.03332
G1 X148.293 Y94.289 E.23829
G2 X147.114 Y93.103 I-1.222 J.036 E.06231
G1 X137.075 Y93.103 E.33984
G2 X135.889 Y94.242 I.019 J1.206 E.06122
G1 X135.889 Y101.368 E.2412
G2 X137.067 Y102.507 I1.218 J-.081 E.06079
G1 X147.107 Y102.507 E.33984
G2 X147.614 Y102.38 I-.036 J-1.222 E.01784
M204 S250
G1 X147.45 Y102.031 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X147.456 Y102.023 E.00033
G2 X147.901 Y101.314 I-.38 J-.732 E.02752
G1 X147.901 Y94.3 E.21992
G2 X147.099 Y93.495 I-.824 J.02 E.03928
G1 X137.085 Y93.495 E.31398
G2 X136.281 Y94.263 I.008 J.813 E.03837
G1 X136.281 Y101.348 E.22213
G2 X137.082 Y102.115 I.821 J-.054 E.03817
G1 X147.096 Y102.115 E.31398
G2 X147.363 Y102.064 I-.02 J-.824 E.00854
M73 P25 R35
G1 X147.394 Y102.052 E.00104
; WIPE_START
M204 S3000
G1 X147.456 Y102.023 E-.01315
G1 X147.631 Y101.909 E-.0397
G1 X147.748 Y101.779 E-.03309
G1 X147.813 Y101.673 E-.02366
G1 X147.862 Y101.556 E-.02415
G1 X147.901 Y101.314 E-.04659
G1 X147.901 Y100.263 E-.19965
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X148.112 Y92.633 Z1 F36000
G1 X148.113 Y92.61 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X147.9 Y92.488 E.00831
G2 X147.143 Y92.316 I-.813 J1.821 E.02645
G1 X137.104 Y92.314 E.33981
G2 X135.1 Y94.318 I-.005 J1.998 E.10662
G1 X135.1 Y101.292 E.23606
G2 X137.104 Y103.296 I1.998 J.005 E.10662
G1 X147.078 Y103.296 E.33761
G2 X149.081 Y101.292 I.001 J-2.003 E.10655
G1 X149.081 Y94.318 E.23606
G2 X148.259 Y92.696 I-1.994 J-.009 E.06392
G1 X148.165 Y92.64 E.00372
M204 S10000
G1 X148.328 Y92.257 F36000
G1 F1473.913
M204 S3000
G1 X148.065 Y92.117 E.01008
G2 X147.148 Y91.909 I-.979 J2.194 E.03204
G1 X137.098 Y91.907 E.34017
G2 X134.693 Y94.313 I.001 J2.406 E.12789
G1 X134.693 Y101.298 E.23642
G2 X137.098 Y103.703 I2.406 J-.001 E.12789
G1 X147.083 Y103.703 E.33797
G2 X149.489 Y101.298 I-.006 J-2.412 E.12781
G1 X149.489 Y94.313 E.23643
G2 X148.395 Y92.296 I-2.402 J-.002 E.08095
G1 X148.38 Y92.287 E.00061
M204 S250
G1 X148.514 Y91.913 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X148.225 Y91.759 E.0103
G2 X147.153 Y91.517 I-1.139 J2.553 E.03466
G1 X137.093 Y91.515 E.31542
G2 X134.301 Y94.308 I.007 J2.799 E.13745
G1 X134.301 Y101.303 E.21931
G2 X137.093 Y104.095 I2.799 J-.007 E.13745
G1 X147.088 Y104.095 E.31337
G2 X149.881 Y101.303 I-.012 J-2.805 E.13738
G1 X149.881 Y94.308 E.21931
G2 X148.609 Y91.968 I-2.795 J.004 E.08705
G1 X148.566 Y91.943 E.00153
; OBJECT_ID: 8
; WIPE_START
M204 S3000
G1 X148.225 Y91.759 E-.0738
G1 X147.953 Y91.652 E-.05552
G1 X147.67 Y91.576 E-.05549
G1 X147.382 Y91.531 E-.05542
G1 X147.153 Y91.517 E-.04362
G1 X146.647 Y91.517 E-.09615
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 9
M625
; start printing object, unique label id: 8
M624 AgAAAAAAAAA=
M204 S10000
G1 X139.406 Y93.929 Z1 F36000
G1 X99.726 Y107.147 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X99.901 Y107.377 E.00978
G2 X101.051 Y107.914 I1.211 J-1.093 E.04412
G1 X121.117 Y107.914 E.67923
G2 X122.7 Y106.345 I-.051 J-1.634 E.08299
G1 X122.7 Y94.272 E.40866
G2 X121.117 Y92.696 I-1.605 J.029 E.0836
G1 X101.064 Y92.696 E.67878
G2 X99.481 Y94.279 I.046 J1.628 E.0835
G1 X99.481 Y106.332 E.40799
G2 X99.685 Y107.074 I1.631 J-.048 E.02629
G1 X99.697 Y107.095 E.00081
M204 S10000
G1 X100.056 Y106.912 F36000
G1 F1473.913
M204 S3000
G1 X100.202 Y107.106 E.0082
G2 X101.067 Y107.507 I.905 J-.816 E.03316
G1 X121.107 Y107.507 E.67832
G2 X122.293 Y106.329 I-.035 J-1.221 E.06232
G1 X122.293 Y94.285 E.40767
G2 X121.107 Y93.103 I-1.224 J.042 E.06241
G1 X101.075 Y93.103 E.67806
G2 X99.889 Y94.289 I.031 J1.217 E.06264
G1 X99.889 Y106.321 E.40727
G2 X100.029 Y106.859 I1.218 J-.032 E.01897
M204 S250
G1 X100.377 Y106.687 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X100.383 Y106.693 E.00027
G2 X101.082 Y107.115 I.718 J-.398 E.0268
G1 X121.096 Y107.115 E.62753
G2 X121.901 Y106.314 I-.019 J-.823 E.03929
M73 P26 R35
G1 X121.901 Y94.298 E.37674
G2 X121.096 Y93.495 I-.826 J.023 E.03929
G1 X101.085 Y93.495 E.62744
G2 X100.281 Y94.3 I.016 J.82 E.03941
G1 X100.281 Y106.311 E.37661
G2 X100.338 Y106.596 I.821 J-.016 E.00917
G1 X100.353 Y106.632 E.00122
; WIPE_START
M204 S3000
G1 X100.383 Y106.693 E-.01288
G1 X100.489 Y106.848 E-.03558
G1 X100.649 Y106.985 E-.04015
G1 X100.76 Y107.045 E-.024
G1 X100.965 Y107.106 E-.04063
G1 X101.082 Y107.115 E-.02232
G1 X102.158 Y107.115 E-.20445
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X108.342 Y102.642 Z1 F36000
G1 X122.173 Y92.638 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X121.143 Y92.316 I-1.089 J1.674 E.03701
G1 X101.104 Y92.314 E.6783
G2 X99.1 Y94.318 I-.005 J1.998 E.10662
G1 X99.1 Y106.292 E.4053
G2 X101.104 Y108.296 I1.998 J.006 E.10663
G1 X121.078 Y108.296 E.6761
G2 X123.081 Y106.292 I.005 J-1.998 E.10662
G1 X123.081 Y94.318 E.40531
G2 X122.223 Y92.671 I-1.997 J-.006 E.06538
M204 S10000
G1 X122.375 Y92.283 F36000
G1 F1473.913
M204 S3000
G1 X122.065 Y92.117 E.01191
G2 X121.148 Y91.909 I-.981 J2.196 E.03203
G1 X101.098 Y91.907 E.67866
G2 X98.693 Y94.313 I.001 J2.406 E.12789
G1 X98.693 Y106.298 E.40567
G2 X101.098 Y108.703 I2.406 J-.001 E.12789
G1 X121.083 Y108.703 E.67646
G2 X123.489 Y106.298 I-.001 J-2.406 E.12789
G1 X123.489 Y94.313 E.40567
G2 X122.425 Y92.317 I-2.405 J0 E.07971
M204 S250
G1 X122.562 Y91.939 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X122.224 Y91.76 E.01199
G2 X121.153 Y91.517 I-1.142 J2.555 E.03466
G1 X101.093 Y91.515 E.62897
G2 X98.301 Y94.308 I.007 J2.799 E.13745
G1 X98.301 Y106.303 E.37608
G2 X101.093 Y109.095 I2.799 J-.007 E.13745
G1 X121.088 Y109.095 E.62692
G2 X123.881 Y106.303 I-.007 J-2.799 E.13745
G1 X123.881 Y94.308 E.37608
G2 X122.612 Y91.971 I-2.798 J.006 E.08686
; OBJECT_ID: 7
; WIPE_START
M204 S3000
G1 X122.224 Y91.76 E-.08402
G1 X121.953 Y91.652 E-.05552
G1 X121.67 Y91.576 E-.05549
G1 X121.382 Y91.531 E-.05542
G1 X121.153 Y91.517 E-.04362
G1 X120.701 Y91.517 E-.08593
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 8
M625
; start printing object, unique label id: 7
M624 AQAAAAAAAAA=
M204 S10000
G1 X116.244 Y97.713 Z1 F36000
G1 X85.786 Y140.05 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X85.955 Y139.815 E.0098
G2 X86.7 Y137.318 I-3.868 J-2.513 E.08941
G1 X86.7 Y97.292 E1.35484
G2 X82.104 Y92.696 I-4.624 J.028 E.24396
G1 X26.077 Y92.696 E1.89643
G2 X21.481 Y97.292 I.016 J4.612 E.24413
G1 X21.481 Y137.318 E1.35485
G2 X26.077 Y141.914 I4.624 J-.028 E.24396
G1 X82.104 Y141.914 E1.89643
G2 X85.672 Y140.205 I-.016 J-4.612 E.1384
G1 X85.75 Y140.098 E.00449
M204 S10000
G1 X85.457 Y139.811 F36000
G1 F1473.913
M204 S3000
G1 X85.614 Y139.593 E.00908
G2 X86.293 Y137.313 I-3.526 J-2.291 E.08164
G1 X86.293 Y97.297 E1.35449
G2 X82.099 Y93.103 I-4.216 J.022 E.22269
G1 X26.083 Y93.103 E1.89607
G2 X21.889 Y97.297 I.011 J4.205 E.22284
G1 X21.889 Y137.313 E1.35449
G2 X26.083 Y141.507 I4.216 J-.022 E.22269
G1 X82.099 Y141.507 E1.89607
G2 X85.355 Y139.949 I-.011 J-4.205 E.12632
G1 X85.421 Y139.859 E.00377
M204 S250
G1 X85.14 Y139.581 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X85.285 Y139.38 E.00777
M73 P27 R35
G2 X85.901 Y137.308 I-3.197 J-2.077 E.0687
G1 X85.901 Y97.302 E1.25435
G2 X82.093 Y93.495 I-3.823 J.015 E.1873
G1 X26.088 Y93.495 E1.75602
G2 X22.281 Y97.302 I.006 J3.813 E.18743
G1 X22.281 Y137.308 E1.25435
G2 X26.088 Y141.115 I3.823 J-.015 E.1873
G1 X82.093 Y141.115 E1.75602
G2 X85.051 Y139.702 I-.006 J-3.813 E.10622
G1 X85.105 Y139.629 E.00285
; WIPE_START
M204 S3000
G1 X85.285 Y139.38 E-.05847
G1 X85.571 Y138.855 E-.11361
G1 X85.714 Y138.483 E-.07576
G1 X85.817 Y138.097 E-.07578
G1 X85.864 Y137.804 E-.05638
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X78.253 Y138.372 Z1 F36000
G1 X25.798 Y142.286 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.83 Y142.288 E.00109
G2 X26.104 Y142.296 I.278 J-5 E.00928
G1 X82.078 Y142.296 E1.89465
G2 X87.081 Y137.292 I-.004 J-5.008 E.26599
G1 X87.081 Y97.318 E1.35307
G2 X82.195 Y92.317 I-5.005 J.003 E.262
G1 X26.104 Y92.314 E1.89863
G2 X21.1 Y97.318 I-.008 J4.996 E.26617
G1 X21.1 Y137.292 E1.35307
G2 X25.31 Y142.232 I5.008 J-.004 E.23902
G1 X25.738 Y142.279 E.01457
M204 S10000
G1 X25.755 Y142.69 F36000
M73 P27 R34
G1 F1473.913
M204 S3000
G1 X25.808 Y142.695 E.00181
G2 X26.098 Y142.703 I.301 J-5.408 E.00982
G1 X82.083 Y142.703 E1.89502
G2 X87.489 Y137.298 I-.011 J-5.416 E.28726
G1 X87.489 Y97.313 E1.35343
G2 X82.206 Y91.911 I-5.414 J.01 E.28309
G1 X26.098 Y91.907 E1.89917
G2 X20.693 Y97.313 I-.003 J5.403 E.28745
G1 X20.693 Y137.298 E1.35343
G2 X25.246 Y142.634 I5.416 J-.011 E.2583
G1 X25.696 Y142.683 E.01529
M204 S250
G1 X25.714 Y143.08 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.788 Y143.086 E.00232
G2 X26.093 Y143.095 I.322 J-5.8 E.00958
M73 P28 R34
G1 X82.088 Y143.095 E1.75567
G2 X87.881 Y137.303 I-.017 J-5.809 E.28507
G1 X87.881 Y97.308 E1.254
G2 X82.216 Y91.519 I-5.807 J.016 E.28105
G1 X26.093 Y91.515 E1.75969
G2 X20.301 Y97.308 I.002 J5.795 E.28527
G1 X20.301 Y137.303 E1.254
G2 X25.185 Y143.021 I5.809 J-.017 E.25648
G1 X25.655 Y143.073 E.0148
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X25.788 Y143.086 E-.02544
G1 X26.093 Y143.095 E-.05807
G1 X27.654 Y143.095 E-.29649
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 7
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X32.917 Y148.623 Z1 F36000
G1 X47.193 Y163.616 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.593 E.01473
G2 X47.385 Y154.321 I-.477 J-4.627 E.47052
G1 X47.161 Y154.315 E.00758
G2 X47.133 Y163.618 I-.01 J4.651 E.49435
M204 S10000
G1 X47.235 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00581
G2 X47.406 Y153.914 I-.254 J-5.052 E.52066
G1 X47.162 Y153.908 E.00827
G2 X46.877 Y164.017 I-.01 J5.058 E.52895
G1 X47.175 Y164.019 E.01007
M204 S250
G1 X47.235 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00602
G2 X47.427 Y153.523 I-.274 J-5.444 E.51966
G1 X47.162 Y153.516 E.00829
G2 X46.857 Y164.409 I-.01 J5.45 E.52794
G1 X47.175 Y164.411 E.00997
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.0479
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.10847
G1 X48.826 Y164.152 E-.10831
G1 X49.126 Y164.037 E-.06105
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.213 Y161.127 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43458
G1 F1531.941
M204 S3000
G1 X44.307 Y162.221 E.05039
G2 X45.66 Y163.02 I2.937 J-3.427 E.05145
G1 X43.089 Y160.448 E.11844
G3 X42.887 Y159.693 I3.485 J-1.334 E.02551
G1 X46.416 Y163.221 E.16251
G2 X47.031 Y163.283 I.992 J-6.827 E.02014
G1 X42.829 Y159.081 E.19351
G3 X42.849 Y158.547 I2.55 J-.17 E.01742
G1 X47.565 Y163.263 E.21718
G2 X48.045 Y163.189 I-2.366 J-17.011 E.01582
G1 X42.919 Y158.063 E.23609
G3 X43.037 Y157.627 I2.148 J.346 E.01474
G1 X48.481 Y163.072 E.25076
G1 X48.882 Y162.918 E.01396
G1 X43.19 Y157.227 E.26213
G3 X43.376 Y156.858 I1.842 J.698 E.01346
G1 X49.25 Y162.733 E.27054
G2 X49.59 Y162.519 I-.845 J-1.722 E.01311
G1 X43.59 Y156.518 E.27636
G3 X43.83 Y156.204 I1.613 J.984 E.01289
G1 X49.904 Y162.279 E.27977
G2 X50.193 Y162.014 I-1.115 J-1.507 E.01279
G1 X44.094 Y155.915 E.28089
G3 X44.384 Y155.651 I1.402 J1.245 E.01279
G1 X50.458 Y161.725 E.27973
G2 X50.697 Y161.41 I-1.372 J-1.293 E.0129
G1 X44.698 Y155.411 E.27627
G3 X45.038 Y155.197 I1.532 J2.044 E.01309
G1 X50.91 Y161.069 E.27048
G2 X51.095 Y160.701 I-1.663 J-1.065 E.01346
G1 X45.411 Y155.017 E.26178
G3 X45.813 Y154.864 I.926 J1.834 E.01401
G1 X51.249 Y160.3 E.25037
G2 X51.361 Y159.858 I-3.893 J-1.221 E.01486
G1 X46.25 Y154.748 E.23539
G3 X46.73 Y154.674 I.591 J2.25 E.01585
G1 X51.435 Y159.378 E.21666
G2 X51.454 Y158.844 I-2.534 J-.36 E.01745
G1 X47.265 Y154.654 E.19295
G3 X47.879 Y154.715 I-.234 J5.537 E.02011
G1 X51.394 Y158.229 E.16187
G2 X51.185 Y157.467 I-3.535 J.557 E.02579
G1 X48.636 Y154.918 E.1174
G3 X50.096 Y155.824 I-1.565 J4.15 E.05631
G1 X51.064 Y156.792 E.04457
; OBJECT_ID: 14
; WIPE_START
G1 X50.096 Y155.824 E-.26002
G1 X49.859 Y155.611 E-.06056
G1 X49.606 Y155.427 E-.05942
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X41.975 Y155.535 Z1 F36000
G1 X26.805 Y155.751 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.667 Y155.708 E.00487
G2 X25.775 Y155.591 I-.888 J3.291 E.03057
G1 X25.607 Y155.595 E.00568
G2 X27.006 Y155.819 I.173 J3.404 E.67666
G1 X26.862 Y155.77 E.00517
M204 S10000
G1 X26.679 Y156.138 F36000
G1 F1473.913
M204 S3000
G1 X26.562 Y156.102 E.00415
G2 X25.775 Y155.998 I-.782 J2.898 E.02694
G1 X25.628 Y156.002 E.00498
G2 X26.86 Y156.199 I.152 J2.998 E.59585
G1 X26.736 Y156.157 E.00445
M204 S250
G1 X26.558 Y156.51 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.48 E.0032
G2 X25.776 Y156.39 I-.68 J2.519 E.02171
G1 X25.649 Y156.393 E.00399
G2 X26.72 Y156.565 I.132 J2.606 E.47983
G1 X26.615 Y156.53 E.00348
; WIPE_START
M204 S3000
G1 X26.46 Y156.48 E-.03079
G1 X26.193 Y156.422 E-.05193
G1 X25.776 Y156.39 E-.07955
G1 X25.649 Y156.393 E-.02418
G1 X25.377 Y156.422 E-.0519
G1 X25.11 Y156.479 E-.05193
G1 X24.85 Y156.563 E-.05191
G1 X24.668 Y156.644 E-.03782
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.87 Y154.317 Z1 F36000
G1 Z.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.805 Y154.315 E.0022
G2 X26.03 Y154.321 I-.01 J4.684 E.98862
G1 X25.93 Y154.319 E.0034
M204 S10000
G1 X25.881 Y153.91 F36000
G1 F1473.913
M204 S3000
G1 X25.806 Y153.908 E.00254
G2 X26.052 Y153.915 I-.01 J5.091 E1.07452
G1 X25.941 Y153.912 E.00376
M204 S250
G1 X25.891 Y153.518 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.806 Y153.516 E.00265
G2 X26.072 Y153.523 I-.01 J5.484 E1.07195
G1 X25.951 Y153.52 E.0038
; WIPE_START
M204 S3000
G1 X25.806 Y153.516 E-.02748
G1 X25.498 Y153.523 E-.05858
G1 X24.927 Y153.583 E-.10904
G1 X24.366 Y153.702 E-.10905
G1 X23.986 Y153.826 E-.07584
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.424 Y161.296 Z1 F36000
G1 X22.375 Y161.529 Z1
G1 Z.6
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.477906
G1 F1379.355
M204 S3000
G1 X22.638 Y161.865 E.01543
G1 X23.264 Y162.432 E.03054
G1 X24.038 Y162.883 E.0324
G1 X24.658 Y163.106 E.02385
G2 X25.586 Y163.252 I1.646 J-7.437 E.03398
G1 X26.434 Y163.207 E.03072
G1 X26.925 Y163.1 E.01817
G1 X27.664 Y162.81 E.02872
G1 X27.934 Y162.676 E.01091
G2 X29.105 Y161.667 I-3.405 J-5.136 E.05606
G2 X29.904 Y160.08 I-3.863 J-2.938 E.06462
G2 X30.04 Y159.2 I-8.579 J-1.774 E.03222
G1 X29.995 Y158.356 E.03055
G1 X29.769 Y157.496 E.0322
G1 X29.365 Y156.693 E.03251
G1 X28.961 Y156.164 E.02406
G1 X28.604 Y155.811 E.01815
G1 X27.957 Y155.349 E.02874
G1 X27.698 Y155.196 E.0109
G2 X25.985 Y154.746 I-2.071 J4.396 E.06441
G1 X25.142 Y154.792 E.03053
G2 X23.675 Y155.299 I.914 J5.023 E.05637
G2 X22.492 Y156.3 I2.757 J4.461 E.05625
G2 X21.981 Y157.088 I6.34 J4.668 E.03398
G2 X21.531 Y158.8 I4.399 J2.072 E.0644
G1 X21.578 Y159.643 E.03053
G2 X22.083 Y161.108 I5.026 J-.914 E.05626
G1 X22.341 Y161.48 E.01637
; WIPE_START
G1 X22.083 Y161.108 E-.08602
G1 X21.819 Y160.547 E-.11773
G1 X21.696 Y160.141 E-.08061
G1 X21.58 Y159.651 E-.09564
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.388 Y162.767 Z1 F36000
G1 Z.6
G1 E.4 F1800
; LINE_WIDTH: 0.474228
G1 F1391.118
M204 S3000
G1 X25.964 Y162.82 E.01533
G1 X25.209 Y162.78 E.02709
G1 X24.435 Y162.58 E.02869
G1 X23.719 Y162.218 E.02878
G1 X23.241 Y161.855 E.02153
G1 X22.703 Y161.263 E.02866
G1 X22.383 Y160.753 E.02161
G1 X22.098 Y160.011 E.02852
G1 X21.968 Y159.22 E.02875
G1 X21.978 Y158.619 E.02153
G1 X22.099 Y158.001 E.02261
G1 X22.387 Y157.256 E.02864
G1 X22.829 Y156.581 E.02894
G1 X22.945 Y156.435 E.00668
G1 X23.522 Y155.918 E.02778
G1 X24.03 Y155.599 E.02153
G1 X24.774 Y155.312 E.02858
M73 P29 R34
G1 X25.566 Y155.183 E.02877
G1 X26.166 Y155.193 E.02154
G1 X26.785 Y155.314 E.02262
G1 X27.529 Y155.602 E.02863
G1 X28.205 Y156.044 E.02893
G3 X29.27 Y157.424 I-2.967 J3.392 E.06293
G1 X29.522 Y158.185 E.02876
G3 X29.592 Y159.381 I-3.826 J.824 E.04311
G1 X29.471 Y160 E.02262
G1 X29.183 Y160.744 E.02863
G1 X28.743 Y161.418 E.02887
G1 X28.345 Y161.839 E.02079
G1 X27.685 Y162.313 E.02913
G1 X26.947 Y162.639 E.02894
G1 X26.446 Y162.754 E.01842
; CHANGE_LAYER
; Z_HEIGHT: 0.8
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1391.118
G1 X26.947 Y162.639 E-.09757
G1 X27.685 Y162.313 E-.1533
G1 X28.237 Y161.917 E-.12913
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L4
M991 S0 P3 ;notify layer change


M204 S10000
G17
G3 Z1 I1.217 J0 P1  F36000
; object ids of layer 4 start: 7,8,9,10,11,12,13,14,15
M624 /wEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer4 end: 7,8,9,10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.16 Y93.508
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X229.072 Y93.529 E.00309
G2 X230.187 Y93.353 I1.123 J3.482 E.73976
G1 X230.012 Y93.357 E.00594
G2 X229.442 Y93.431 I.183 J3.654 E.01947
G1 X229.218 Y93.492 E.00785
M204 S10000
G1 X229.265 Y93.9 F36000
G1 F1473.913
M204 S3000
G1 X229.197 Y93.917 E.00237
G2 X230.188 Y93.76 I.998 J3.095 E.65747
G1 X230.033 Y93.764 E.00525
G2 X229.527 Y93.829 I.162 J3.248 E.0173
G1 X229.323 Y93.885 E.00713
M204 S250
G1 X229.367 Y94.279 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.29 E.00154
G2 X230.189 Y94.152 I.877 J2.722 E.53561
G1 X230.054 Y94.155 E.00424
G2 X229.608 Y94.213 I.142 J2.856 E.01409
G1 X229.425 Y94.263 E.00597
; WIPE_START
M204 S3000
G1 X229.319 Y94.29 E-.02075
G1 X229.04 Y94.399 E-.0569
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05688
G1 X228.289 Y94.886 E-.05686
G1 X228.078 Y95.098 E-.05693
G1 X227.889 Y95.33 E-.05683
G1 X227.838 Y95.41 E-.01797
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.071 Y92.827 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X230.449 Y92.321 I2.133 J4.181 E.91499
G2 X229.955 Y92.321 I-.245 J5.194 E.01672
G2 X228.125 Y92.8 I.249 J4.687 E.06448
M204 S10000
G1 X227.898 Y92.458 F36000
G1 F1473.913
M204 S3000
G1 X227.886 Y92.464 E.00046
G2 X230.47 Y91.915 I2.317 J4.544 E.99432
G2 X229.935 Y91.915 I-.266 J5.631 E.01813
G2 X228.374 Y92.247 I.269 J5.093 E.05423
G1 X227.953 Y92.434 E.01559
M204 S250
G1 X227.739 Y92.101 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.708 Y92.115 E.00106
G2 X230.491 Y91.523 I2.495 J4.893 E.99182
G2 X229.915 Y91.523 I-.287 J6.053 E.01805
G2 X228.233 Y91.881 I.288 J5.485 E.05413
G1 X227.794 Y92.076 E.01509
; WIPE_START
M204 S3000
G1 X227.708 Y92.115 E-.01785
G1 X227.455 Y92.252 E-.05467
G1 X226.973 Y92.565 E-.1093
G1 X226.525 Y92.927 E-.10931
G1 X226.195 Y93.258 E-.08887
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.329 Y93.279 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672815
G1 F952.54
M204 S3000
G1 X228.307 Y93.29 E.0013
G2 X226.025 Y97.012 I1.899 J3.725 E.24057
G1 X226.075 Y97.657 E.0339
G1 X226.17 Y98.101 E.02379
G1 X226.386 Y98.711 E.03391
G1 X226.699 Y99.287 E.03434
G1 X227.098 Y99.807 E.03433
G1 X227.567 Y100.253 E.0339
G1 X228.107 Y100.626 E.03435
G1 X228.511 Y100.832 E.02377
G1 X229.122 Y101.047 E.0339
G1 X229.766 Y101.167 E.03434
G1 X230.421 Y101.184 E.03431
G1 X231.064 Y101.1 E.03393
G1 X231.693 Y100.915 E.03434
G1 X232.107 Y100.73 E.02377
G1 X232.659 Y100.392 E.0339
G1 X233.152 Y99.972 E.03393
G1 X233.578 Y99.474 E.03432
G1 X233.825 Y99.093 E.02378
G1 X234.104 Y98.509 E.03389
G1 X234.29 Y97.88 E.03434
G1 X234.375 Y97.23 E.03437
G1 X234.359 Y96.583 E.03389
G1 X234.288 Y96.135 E.02377
G1 X234.104 Y95.514 E.0339
G1 X233.821 Y94.922 E.03434
G1 X233.455 Y94.389 E.03389
G1 X233.151 Y94.051 E.02379
G1 X232.659 Y93.631 E.0339
G1 X232.1 Y93.289 E.03434
G1 X231.502 Y93.041 E.03391
G1 X230.865 Y92.886 E.03433
G1 X230.409 Y92.839 E.02402
G2 X228.706 Y93.112 I-.203 J4.176 E.09098
G1 X228.384 Y93.254 E.01844
; OBJECT_ID: 12
; WIPE_START
G1 X228.307 Y93.29 E-.01611
G1 X227.928 Y93.508 E-.08313
G1 X227.573 Y93.765 E-.08316
G1 X227.255 Y94.051 E-.08144
G1 X226.956 Y94.382 E-.08463
G1 X226.859 Y94.516 E-.03152
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.594 Y96.858 Z1.2 F36000
G1 X211.928 Y99.33 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.04 Y99.164 E.00677
G2 X208.76 Y93.116 I-3.271 J-2.139 E.28474
G1 X208.573 Y93.12 E.00634
G2 X211.81 Y99.48 I.196 J3.904 E.52698
G1 X211.891 Y99.377 E.00443
M204 S10000
G1 X211.6 Y99.091 F36000
G1 F1473.913
M204 S3000
G1 X211.699 Y98.941 E.00607
G2 X208.761 Y93.523 I-2.93 J-1.917 E.25511
G1 X208.594 Y93.527 E.00565
G2 X211.493 Y99.224 I.175 J3.497 E.47212
G1 X211.562 Y99.138 E.00373
M204 S250
G1 X211.283 Y98.86 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.371 Y98.727 E.00499
G2 X208.762 Y93.915 I-2.602 J-1.703 E.20989
G1 X208.615 Y93.919 E.00461
G2 X211.189 Y98.977 I.154 J3.106 E.38838
G1 X211.246 Y98.907 E.00283
; WIPE_START
M204 S3000
G1 X211.371 Y98.727 E-.0416
G1 X211.619 Y98.29 E-.09557
G1 X211.735 Y97.986 E-.06188
G1 X211.82 Y97.671 E-.06182
G1 X211.871 Y97.35 E-.06186
G1 X211.886 Y97.049 E-.05727
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.751 Y99.461 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.972 Y99.79 E.0134
G2 X209.024 Y92.321 I3.806 J-2.768 E.64225
G2 X208.529 Y92.321 I-.246 J5.203 E.01676
G2 X204.703 Y99.377 I.249 J4.7 E.32531
G1 X204.722 Y99.409 E.00124
M204 S10000
G1 X204.421 Y99.699 F36000
G1 F1473.913
M204 S3000
G1 X204.491 Y99.808 E.0044
G2 X209.045 Y91.915 I4.287 J-2.787 E.70682
G2 X208.508 Y91.915 I-.267 J5.642 E.01818
G2 X204.223 Y99.345 I.27 J5.106 E.34443
G1 X204.392 Y99.646 E.01168
M204 S250
G1 X204.082 Y99.896 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.325 Y100.259 E.01372
G2 X209.066 Y91.523 I4.452 J-3.238 E.69588
G2 X208.489 Y91.523 I-.288 J6.064 E.01809
G2 X204.011 Y99.776 I.289 J5.498 E.35258
G1 X204.051 Y99.844 E.00246
; WIPE_START
M204 S3000
G1 X204.325 Y100.259 E-.09453
G1 X204.683 Y100.711 E-.10956
G1 X205.091 Y101.119 E-.10953
G1 X205.363 Y101.339 E-.06639
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.108 Y99.27 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435943
G1 F1526.629
M204 S3000
G1 X205.163 Y99.372 E.00378
G1 X205.575 Y99.909 E.0221
G1 X206.061 Y100.371 E.02192
G1 X206.249 Y100.514 E.00771
G1 X206.618 Y100.754 E.01441
G1 X207.049 Y100.972 E.01577
G1 X207.662 Y101.187 E.02124
G1 X208.327 Y101.311 E.02208
G1 X209.003 Y101.328 E.0221
G1 X209.669 Y101.241 E.02195
G1 X210.314 Y101.051 E.02198
G1 X210.739 Y100.862 E.0152
G1 X211.311 Y100.511 E.02193
G1 X211.821 Y100.076 E.02193
G1 X212.13 Y99.733 E.01508
G1 X212.511 Y99.177 E.02201
G1 X212.801 Y98.569 E.02202
G1 X212.993 Y97.921 E.02208
G1 X213.081 Y97.255 E.02195
G1 X213.081 Y96.794 E.01508
G1 X212.993 Y96.128 E.02194
G1 X212.801 Y95.48 E.0221
G1 X212.511 Y94.872 E.02203
G1 X212.261 Y94.487 E.01498
G1 X211.825 Y93.977 E.02192
G1 X211.311 Y93.538 E.02211
G1 X210.734 Y93.185 E.0221
G1 X210.114 Y92.928 E.02193
G1 X209.888 Y92.861 E.0077
G1 X209.457 Y92.769 E.01442
G1 X208.994 Y92.721 E.01521
G2 X204.468 Y97.019 I-.213 J4.307 E.22808
G1 X204.492 Y97.48 E.01508
G1 X204.561 Y97.916 E.0144
G1 X204.616 Y98.145 E.00771
G1 X204.84 Y98.777 E.02193
G1 X205.079 Y99.217 E.01636
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.03339
G1 X205.575 Y99.909 E-.12851
G1 X206.061 Y100.371 E-.12747
G1 X206.249 Y100.514 E-.04482
G1 X206.451 Y100.645 E-.04581
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X199.074 Y98.685 Z1.2 F36000
G1 X183.919 Y94.659 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.83 Y94.77 E.00483
G2 X187.306 Y92.88 I3.485 J2.269 E.7449
G1 X187.106 Y92.885 E.00674
G2 X184.086 Y94.417 I.208 J4.153 E.11805
G1 X183.954 Y94.609 E.0079
M204 S10000
G1 X184.248 Y94.898 F36000
G1 F1473.913
M204 S3000
M73 P29 R33
G1 X184.172 Y94.992 E.00411
G2 X187.306 Y93.287 I3.144 J2.047 E.672
G1 X187.128 Y93.292 E.00605
G2 X184.403 Y94.674 I.187 J3.747 E.1065
G1 X184.283 Y94.848 E.00718
M204 S250
G1 X184.565 Y95.127 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.408 Y95.356 E.00869
G2 X187.307 Y93.68 I2.907 J1.683 E.55191
G1 X187.148 Y93.684 E.00498
G2 X184.601 Y95.06 I.167 J3.355 E.09388
G1 X184.593 Y95.074 E.00048
; WIPE_START
M204 S3000
G1 X184.408 Y95.356 E-.064
G1 X184.255 Y95.673 E-.06695
G1 X184.129 Y96 E-.06672
G1 X184.006 Y96.514 E-.10028
G1 X183.969 Y96.863 E-.06681
G1 X183.969 Y96.944 E-.01523
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.43 Y92.321 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.075 Y92.321 E.01202
G2 X187.571 Y92.321 I.25 J4.715 E.98727
G1 X187.49 Y92.321 E.00276
M204 S10000
G1 X187.43 Y91.915 F36000
G1 F1473.913
M204 S3000
G1 X187.054 Y91.915 E.01271
G2 X187.593 Y91.915 I.27 J5.121 E1.0724
G1 X187.49 Y91.915 E.00349
M204 S250
G1 X187.43 Y91.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.523 E.01238
G2 X187.613 Y91.523 I.29 J5.512 E1.06933
G1 X187.49 Y91.523 E.00388
; WIPE_START
M204 S3000
G1 X187.035 Y91.523 E-.08641
G1 X186.46 Y91.583 E-.10977
G1 X185.895 Y91.704 E-.10985
G1 X185.524 Y91.824 E-.07397
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.491 Y92.603 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200554
G1 F3806.304
M204 S3000
G1 X187.089 Y92.603 E.00527
G2 X182.882 Y97.039 I.235 J4.436 E.08837
G1 X182.889 Y97.274 E.00308
G1 X182.937 Y97.732 E.00604
G1 X183.034 Y98.191 E.00615
G1 X183.258 Y98.826 E.00883
G1 X183.368 Y99.059 E.00337
G1 X183.599 Y99.458 E.00605
G1 X183.871 Y99.833 E.00607
G1 X184.023 Y100.011 E.00307
G1 X184.185 Y100.182 E.00308
G1 X184.527 Y100.49 E.00604
G1 X184.715 Y100.634 E.00311
G1 X185.101 Y100.885 E.00604
G1 X185.52 Y101.097 E.00615
G2 X187.551 Y92.603 I1.804 J-4.059 E.20427
G1 X187.551 Y92.603 E.00001
; OBJECT_ID: 10
; WIPE_START
G1 X187.089 Y92.603 E-.08772
G1 X186.632 Y92.652 E-.08736
G1 X186.399 Y92.695 E-.04502
G1 X185.954 Y92.814 E-.08754
G1 X185.73 Y92.893 E-.045
G1 X185.599 Y92.952 E-.02736
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.968 Y93.129 Z1.2 F36000
G1 X163.282 Y93.471 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.062 Y93.624 E.00905
G2 X165.82 Y92.646 I2.768 J3.431 E.83664
G1 X165.61 Y92.652 E.00714
G2 X163.436 Y93.353 I.221 J4.403 E.07819
G1 X163.329 Y93.435 E.00456
M204 S10000
G1 X163.521 Y93.8 F36000
G1 F1473.913
M204 S3000
G1 X163.318 Y93.94 E.00833
G2 X165.821 Y93.053 I2.512 J3.115 E.75941
G1 X165.631 Y93.058 E.00644
G2 X163.658 Y93.695 I.2 J3.996 E.07098
G1 X163.568 Y93.764 E.00384
M204 S250
G1 X163.751 Y94.117 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.565 Y94.245 E.00708
G2 X165.822 Y93.446 I2.266 J2.81 E.63453
G1 X165.652 Y93.45 E.00535
G2 X163.872 Y94.024 I.179 J3.605 E.05931
G1 X163.798 Y94.08 E.00291
; WIPE_START
M204 S3000
G1 X163.565 Y94.245 E-.05426
G1 X163.158 Y94.639 E-.10772
M73 P30 R33
G1 X162.92 Y94.933 E-.07181
G1 X162.714 Y95.25 E-.07181
G1 X162.543 Y95.587 E-.07178
G1 X162.538 Y95.6 E-.00262
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.08 Y101.453 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.144 Y101.475 E.00228
G2 X166.088 Y92.321 I1.697 J-4.423 E.55413
G2 X165.59 Y92.321 I-.247 J5.237 E.01687
G2 X163.691 Y101.273 I.251 J4.73 E.41972
G1 X164.025 Y101.428 E.01245
M204 S10000
G1 X163.914 Y101.825 F36000
G1 F1473.913
M204 S3000
G1 X163.998 Y101.854 E.00301
G2 X166.11 Y91.915 I1.843 J-4.803 E.60171
G2 X165.57 Y91.915 I-.269 J5.674 E.01829
G2 X163.507 Y101.636 I.271 J5.137 E.45583
G1 X163.86 Y101.799 E.01318
M204 S250
G1 X163.756 Y102.181 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.131 Y102.317 E.0125
G2 X166.13 Y91.523 I1.71 J-5.265 E.59073
G2 X165.55 Y91.523 I-.29 J6.097 E.0182
G2 X163.59 Y102.109 I.291 J5.528 E.46354
G1 X163.701 Y102.157 E.00378
; OBJECT_ID: 9
; WIPE_START
M204 S3000
G1 X164.131 Y102.317 E-.08711
G1 X164.689 Y102.474 E-.11011
G1 X165.261 Y102.565 E-.11017
G1 X165.643 Y102.585 E-.07261
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 9
M624 BAAAAAAAAAA=
M204 S10000
G1 X158.011 Y102.668 Z1.2 F36000
G1 X147.717 Y102.78 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X147.822 Y102.74 E.00378
G2 X148.7 Y101.345 I-.728 J-1.432 E.05859
G1 X148.7 Y94.279 E.2392
G2 X147.131 Y92.696 I-1.606 J.024 E.08336
G1 X137.044 Y92.696 E.34141
G2 X135.482 Y94.208 I.051 J1.615 E.0807
G1 X135.482 Y101.39 E.24309
G2 X137.051 Y102.914 I1.631 J-.109 E.08111
G1 X147.117 Y102.914 E.34074
G2 X147.494 Y102.864 I-.023 J-1.606 E.01291
G1 X147.661 Y102.801 E.00603
M204 S10000
G1 X147.573 Y102.401 F36000
G1 F1473.913
M204 S3000
G1 X147.633 Y102.37 E.00229
G2 X148.293 Y101.329 I-.565 J-1.088 E.0437
G1 X148.293 Y94.289 E.23829
G2 X147.114 Y93.103 I-1.225 J.039 E.06227
G1 X137.063 Y93.103 E.34023
G2 X135.889 Y94.235 I.031 J1.206 E.06058
G1 X135.889 Y101.368 E.24146
G2 X137.067 Y102.507 I1.218 J-.081 E.06079
G1 X147.107 Y102.507 E.33984
G2 X147.393 Y102.464 I-.039 J-1.225 E.00982
G1 X147.516 Y102.421 E.00443
M204 S250
G1 X147.434 Y102.037 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X147.456 Y102.022 E.00083
G2 X147.901 Y101.314 I-.382 J-.733 E.0275
G1 X147.901 Y94.3 E.21992
G2 X147.099 Y93.495 I-.826 J.022 E.03925
G1 X137.081 Y93.495 E.31411
G2 X136.281 Y94.26 I.012 J.813 E.03816
G1 X136.281 Y101.348 E.22222
G2 X137.082 Y102.115 I.821 J-.054 E.03817
G1 X147.096 Y102.115 E.31398
G2 X147.297 Y102.085 I-.022 J-.826 E.00637
G1 X147.377 Y102.057 E.00268
; WIPE_START
M204 S3000
G1 X147.456 Y102.022 E-.0163
G1 X147.692 Y101.849 E-.05565
G1 X147.813 Y101.673 E-.04048
G1 X147.862 Y101.556 E-.02415
G1 X147.901 Y101.314 E-.04663
G1 X147.901 Y100.278 E-.19679
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X148.1 Y92.648 Z1.2 F36000
G1 X148.101 Y92.603 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X147.9 Y92.488 E.00785
G2 X147.15 Y92.317 I-.809 J1.819 E.0262
G1 X137.103 Y92.314 E.34006
G2 X135.1 Y94.318 I0 J2.003 E.10655
G1 X135.1 Y101.292 E.23606
G2 X137.104 Y103.296 I2.003 J.001 E.10655
G1 X147.078 Y103.296 E.33761
G2 X149.081 Y101.292 I.001 J-2.003 E.10655
G1 X149.081 Y94.318 E.23606
G2 X148.266 Y92.7 I-1.991 J-.011 E.06366
G1 X148.153 Y92.634 E.00446
M204 S10000
G1 X148.294 Y92.232 F36000
G1 F1473.913
M204 S3000
G1 X148.289 Y92.23 E.00019
G2 X147.163 Y91.91 I-1.199 J2.077 E.04003
G1 X137.098 Y91.907 E.34068
G2 X134.693 Y94.313 I.006 J2.412 E.12781
G1 X134.693 Y101.298 E.23642
G2 X137.098 Y103.703 I2.412 J-.006 E.12781
G1 X147.083 Y103.703 E.33797
G2 X149.489 Y101.298 I-.006 J-2.412 E.12781
G1 X149.489 Y94.313 E.23642
G2 X148.503 Y92.369 I-2.398 J-.006 E.07657
G1 X148.344 Y92.265 E.00643
M204 S250
G1 X148.508 Y91.904 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X148.485 Y91.89 E.00084
G2 X147.175 Y91.518 I-1.395 J2.417 E.04312
G1 X137.093 Y91.515 E.31612
G2 X134.301 Y94.308 I.012 J2.805 E.13738
G1 X134.301 Y101.303 E.21931
G2 X137.093 Y104.095 I2.805 J-.012 E.13738
G1 X147.088 Y104.095 E.31337
G2 X149.881 Y101.303 I-.012 J-2.805 E.13738
G1 X149.881 Y94.308 E.21931
G2 X148.731 Y92.05 I-2.791 J-.001 E.08246
G1 X148.558 Y91.937 E.00649
; OBJECT_ID: 8
; WIPE_START
M204 S3000
G1 X148.485 Y91.89 E-.01649
G1 X148.225 Y91.757 E-.05545
G1 X147.953 Y91.652 E-.05551
G1 X147.67 Y91.576 E-.05551
G1 X147.175 Y91.518 E-.09472
G1 X146.637 Y91.518 E-.10232
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 9
M625
; start printing object, unique label id: 8
M624 AgAAAAAAAAA=
M204 S10000
G1 X139.387 Y93.905 Z1.2 F36000
G1 X99.638 Y106.994 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X99.673 Y107.07 E.00281
G2 X101.064 Y107.914 I1.414 J-.76 E.05778
G1 X121.117 Y107.914 E.67878
G2 X122.7 Y106.345 I-.052 J-1.635 E.08298
G1 X122.7 Y94.279 E.40844
G2 X121.131 Y92.696 I-1.63 J.048 E.08304
G1 X101.044 Y92.696 E.67989
G2 X99.481 Y94.279 I.067 J1.629 E.08285
G1 X99.481 Y106.332 E.40799
G2 X99.589 Y106.889 I1.605 J-.022 E.01929
G1 X99.613 Y106.94 E.00191
M204 S10000
G1 X100.007 Y106.824 F36000
G1 F1473.913
M204 S3000
G1 X100.039 Y106.872 E.00194
G2 X101.075 Y107.507 I1.075 J-.589 E.04304
G1 X121.107 Y107.507 E.67806
G2 X122.293 Y106.329 I-.035 J-1.222 E.06232
G1 X122.293 Y94.289 E.40753
G2 X121.114 Y93.103 I-1.218 J.032 E.06236
G1 X101.063 Y93.103 E.67872
G2 X99.889 Y94.289 I.043 J1.217 E.06225
G1 X99.889 Y106.321 E.40727
G2 X99.976 Y106.737 I1.225 J-.039 E.01446
G1 X99.987 Y106.767 E.00109
M204 S250
G1 X100.363 Y106.659 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X100.382 Y106.686 E.00103
G2 X101.085 Y107.115 I.725 J-.397 E.02702
G1 X121.096 Y107.115 E.62744
G2 X121.901 Y106.314 I-.019 J-.823 E.03929
G1 X121.901 Y94.3 E.37669
G2 X121.099 Y93.495 I-.821 J.016 E.03932
G1 X101.081 Y93.495 E.62765
G2 X100.281 Y94.3 I.02 J.82 E.03928
G1 X100.281 Y106.311 E.37661
G2 X100.339 Y106.595 I.826 J-.022 E.00914
G1 X100.342 Y106.603 E.00028
; WIPE_START
M204 S3000
G1 X100.382 Y106.686 E-.0175
G1 X100.49 Y106.85 E-.03717
G1 X100.651 Y106.986 E-.04022
G1 X100.761 Y107.046 E-.02366
G1 X100.881 Y107.088 E-.02417
G1 X101.085 Y107.115 E-.03912
G1 X102.128 Y107.115 E-.19816
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X108.307 Y102.634 Z1.2 F36000
G1 X122.122 Y92.616 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X121.9 Y92.488 E.00867
G2 X121.15 Y92.317 I-.809 J1.819 E.0262
G1 X101.104 Y92.314 E.67855
G2 X99.1 Y94.318 I-.005 J1.998 E.10663
G1 X99.1 Y106.292 E.4053
G2 X101.104 Y108.296 I1.998 J.006 E.10663
G1 X121.078 Y108.296 E.6761
G2 X123.081 Y106.292 I.006 J-1.998 E.10663
G1 X123.081 Y94.318 E.4053
G2 X122.266 Y92.7 I-1.991 J-.011 E.06367
G1 X122.174 Y92.646 E.00363
M204 S10000
G1 X122.315 Y92.245 F36000
G1 F1473.913
M204 S3000
G1 X122.289 Y92.23 E.00101
G2 X121.163 Y91.91 I-1.199 J2.077 E.04003
G1 X101.098 Y91.907 E.67917
G2 X98.693 Y94.313 I.001 J2.406 E.12789
G1 X98.693 Y106.298 E.40567
G2 X101.098 Y108.703 I2.406 J-.001 E.12789
G1 X121.083 Y108.703 E.67646
G2 X123.489 Y106.298 I-.001 J-2.406 E.12789
M73 P31 R33
G1 X123.489 Y94.313 E.40567
G2 X122.503 Y92.369 I-2.398 J-.006 E.07658
G1 X122.365 Y92.278 E.0056
M204 S250
G1 X122.528 Y91.917 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X122.485 Y91.89 E.0016
G2 X121.175 Y91.518 I-1.395 J2.417 E.04312
G1 X101.093 Y91.515 E.62966
G2 X98.301 Y94.308 I.007 J2.799 E.13745
G1 X98.301 Y106.303 E.37608
G2 X101.093 Y109.095 I2.799 J-.007 E.13745
G1 X121.088 Y109.095 E.62692
G2 X123.881 Y106.303 I-.007 J-2.799 E.13745
G1 X123.881 Y94.308 E.37608
G2 X122.731 Y92.05 I-2.791 J-.001 E.08246
G1 X122.579 Y91.95 E.00572
; OBJECT_ID: 7
; WIPE_START
M204 S3000
G1 X122.485 Y91.89 E-.02109
G1 X122.225 Y91.757 E-.05545
G1 X121.953 Y91.652 E-.05551
G1 X121.67 Y91.576 E-.05551
G1 X121.175 Y91.518 E-.09472
G1 X120.661 Y91.518 E-.09772
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 8
M625
; start printing object, unique label id: 7
M624 AQAAAAAAAAA=
M204 S10000
G1 X116.207 Y97.716 Z1.2 F36000
G1 X85.732 Y140.123 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X85.818 Y140.014 E.0047
G2 X86.429 Y138.858 I-3.731 J-2.711 E.04438
G2 X86.7 Y137.318 I-4.38 J-1.564 E.05318
G1 X86.7 Y97.292 E1.35485
G2 X82.104 Y92.696 I-4.612 J.016 E.24413
G1 X26.077 Y92.696 E1.89643
G2 X21.481 Y97.292 I.028 J4.624 E.24396
G1 X21.481 Y137.318 E1.35485
G2 X26.077 Y141.914 I4.612 J-.016 E.24413
G1 X82.104 Y141.914 E1.89643
G2 X85.515 Y140.389 I-.016 J-4.611 E.13023
G1 X85.694 Y140.169 E.00959
M204 S10000
G1 X85.428 Y139.851 F36000
G1 F1473.913
M204 S3000
G1 X85.61 Y139.591 E.01074
G2 X86.293 Y137.313 I-3.533 J-2.299 E.0816
G1 X86.293 Y97.297 E1.35449
G2 X82.099 Y93.103 I-4.205 J.011 E.22284
G1 X26.083 Y93.103 E1.89607
G2 X21.889 Y97.297 I.021 J4.216 E.22269
G1 X21.889 Y137.313 E1.35449
G2 X26.083 Y141.507 I4.205 J-.011 E.22284
G1 X82.099 Y141.507 E1.89607
G2 X85.352 Y139.946 I-.021 J-4.216 E.12623
G1 X85.391 Y139.898 E.0021
M204 S250
G1 X85.111 Y139.621 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
M73 P31 R32
G1 F1500
M204 S1000
G1 X85.282 Y139.378 E.00931
G2 X85.901 Y137.308 I-3.204 J-2.085 E.06867
G1 X85.901 Y97.302 E1.25435
G2 X82.093 Y93.495 I-3.813 J.006 E.18743
G1 X26.088 Y93.495 E1.75602
G2 X22.281 Y97.302 I.015 J3.823 E.1873
G1 X22.281 Y137.308 E1.25435
G2 X26.088 Y141.115 I3.813 J-.006 E.18743
G1 X82.093 Y141.115 E1.75602
G2 X85.048 Y139.7 I-.015 J-3.823 E.10614
G1 X85.074 Y139.667 E.0013
; WIPE_START
M204 S3000
G1 X85.282 Y139.378 E-.06778
M73 P32 R32
G1 X85.571 Y138.855 E-.11353
G1 X85.714 Y138.483 E-.07579
G1 X85.817 Y138.097 E-.07578
G1 X85.856 Y137.852 E-.04712
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X78.245 Y138.415 Z1.2 F36000
G1 X25.83 Y142.289 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X26.104 Y142.296 I.266 J-4.989 E.00928
G1 X82.078 Y142.296 E1.89465
G2 X87.081 Y137.292 I.008 J-4.996 E.26617
G1 X87.081 Y97.318 E1.35307
G2 X87.04 Y96.68 I-5.451 J.033 E.02166
G2 X82.247 Y92.319 I-4.95 J.625 E.23873
G1 X26.104 Y92.314 E1.9004
G2 X21.1 Y97.318 I-.008 J4.996 E.26617
G1 X21.1 Y137.292 E1.35307
G2 X25.77 Y142.286 I4.996 J.008 E.25487
M204 S10000
G1 X25.801 Y142.695 F36000
G1 F1473.913
M204 S3000
G1 X25.808 Y142.696 E.00024
G2 X26.098 Y142.703 I.287 J-5.395 E.00982
G1 X82.083 Y142.703 E1.89502
G2 X87.489 Y137.298 I.003 J-5.403 E.28745
G1 X87.489 Y97.313 E1.35343
G2 X82.258 Y91.912 I-5.407 J.003 E.28141
G1 X26.098 Y91.907 E1.90094
G2 X20.693 Y97.313 I-.003 J5.403 E.28745
G1 X20.693 Y137.298 E1.35343
G2 X25.246 Y142.636 I5.403 J.003 E.25849
G1 X25.742 Y142.689 E.01687
M204 S250
G1 X25.76 Y143.084 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.788 Y143.087 E.00086
G2 X26.093 Y143.095 I.308 J-5.787 E.00958
G1 X82.088 Y143.095 E1.75567
G2 X87.881 Y137.303 I-.002 J-5.795 E.28527
G1 X87.881 Y97.308 E1.254
G2 X82.268 Y91.52 I-5.799 J.008 E.2795
G1 X26.093 Y91.515 E1.76133
G2 X20.301 Y97.308 I.002 J5.795 E.28527
G1 X20.301 Y137.303 E1.254
G2 X25.185 Y143.023 I5.795 J-.002 E.25667
G1 X25.701 Y143.078 E.01626
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X25.788 Y143.087 E-.01664
M73 P33 R32
G1 X26.093 Y143.095 E-.05807
G1 X27.7 Y143.095 E-.3053
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 7
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X32.958 Y148.628 Z1.2 F36000
G1 X47.199 Y163.616 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.594 E.01454
G2 X47.385 Y154.321 I-.488 J-4.627 E.46987
G2 X47.139 Y163.619 I-.242 J4.646 E.50274
M204 S10000
G1 X47.22 Y164.022 F36000
G1 F1473.913
M204 S3000
G1 X47.67 Y163.999 E.01526
G2 X47.406 Y153.914 I-.531 J-5.032 E.511
G2 X47.142 Y164.026 I-.263 J5.052 E.54685
G1 X47.16 Y164.025 E.00063
M204 S250
G1 X47.241 Y164.413 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.712 Y164.389 E.01478
G2 X47.427 Y153.523 I-.572 J-5.422 E.51003
G2 X47.142 Y164.418 I-.283 J5.444 E.54581
G1 X47.181 Y164.416 E.00123
; WIPE_START
M204 S3000
G1 X47.712 Y164.389 E-.10096
G1 X47.994 Y164.351 E-.05421
G1 X48.553 Y164.233 E-.10845
G1 X49.122 Y164.045 E-.11391
G1 X49.134 Y164.04 E-.00247
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.299 Y162.898 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X50.413 Y161.784 E.05128
G2 X51.194 Y160.449 I-3.487 J-2.937 E.05057
G1 X48.628 Y163.015 E.11811
G3 X47.873 Y163.217 I-1.509 J-4.133 E.02548
G1 X51.396 Y159.694 E.16214
G2 X51.454 Y159.082 I-5.614 J-.844 E.02001
G1 X47.257 Y163.279 E.19315
G3 X46.724 Y163.259 I-.158 J-2.898 E.0174
G1 X51.434 Y158.549 E.21678
G2 X51.365 Y158.065 I-3.975 J.323 E.01593
G1 X46.245 Y163.185 E.23565
G3 X45.808 Y163.068 I.338 J-2.134 E.01473
G1 X51.247 Y157.629 E.25034
G2 X51.094 Y157.229 I-2.017 J.545 E.01397
G1 X45.407 Y162.915 E.26171
G3 X45.037 Y162.732 I.691 J-1.856 E.01346
G1 X50.908 Y156.861 E.2702
G2 X50.695 Y156.521 I-1.664 J.806 E.0131
G1 X44.695 Y162.52 E.27613
G3 X44.379 Y162.283 I.973 J-1.624 E.01289
G1 X50.455 Y156.207 E.27965
G2 X50.191 Y155.918 I-1.507 J1.113 E.01277
G1 X44.085 Y162.018 E.28089
G3 X43.824 Y161.731 I2.611 J-2.63 E.01262
G1 X49.902 Y155.653 E.27972
G2 X49.588 Y155.414 I-1.297 J1.375 E.01288
G1 X43.588 Y161.413 E.27613
G3 X43.377 Y161.071 I1.523 J-1.178 E.01311
G1 X49.249 Y155.199 E.27028
G2 X48.876 Y155.018 I-1.331 J2.282 E.0135
G1 X43.193 Y160.701 E.26155
G3 X43.041 Y160.3 I1.823 J-.924 E.01398
G1 X48.475 Y154.866 E.25013
G2 X48.039 Y154.749 I-.775 J2.017 E.01473
G1 X42.923 Y159.864 E.23543
G3 X42.849 Y159.385 I2.24 J-.592 E.01581
G1 X47.559 Y154.675 E.21678
G2 X47.026 Y154.655 I-.362 J2.518 E.01741
G1 X42.829 Y158.851 E.19316
G3 X42.887 Y158.24 I6.975 J.347 E.01998
G1 X46.414 Y154.713 E.16237
G2 X45.659 Y154.914 I.581 J3.693 E.02548
G1 X43.089 Y157.485 E.11831
G3 X43.889 Y156.131 I4.228 J1.586 E.05143
G1 X44.981 Y155.038 E.05029
; OBJECT_ID: 14
; WIPE_START
G1 X43.889 Y156.131 E-.29358
G1 X43.648 Y156.429 E-.07276
G1 X43.609 Y156.489 E-.01365
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X35.984 Y156.154 Z1.2 F36000
G1 X26.8 Y155.75 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.667 Y155.709 E.0047
G2 X25.77 Y155.591 I-.889 J3.291 E.0307
G1 X25.607 Y155.595 E.00554
G2 X27.006 Y155.82 I.171 J3.405 E.67666
G1 X26.857 Y155.769 E.00534
M204 S10000
G1 X26.674 Y156.136 F36000
G1 F1473.913
M204 S3000
G1 X26.562 Y156.102 E.00398
G2 X25.771 Y155.998 I-.784 J2.898 E.02707
G1 X25.628 Y156.002 E.00485
G2 X26.86 Y156.2 I.15 J2.998 E.59585
G1 X26.731 Y156.156 E.00462
M204 S250
G1 X26.553 Y156.509 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.481 E.00304
G2 X25.772 Y156.39 I-.682 J2.519 E.02183
G1 X25.649 Y156.393 E.00387
G2 X26.72 Y156.566 I.13 J2.606 E.47983
G1 X26.61 Y156.528 E.00363
; WIPE_START
M204 S3000
G1 X26.46 Y156.481 E-.02984
G1 X26.194 Y156.422 E-.0519
G1 X25.772 Y156.39 E-.08028
G1 X25.649 Y156.393 E-.02346
G1 X25.243 Y156.447 E-.07782
G1 X24.979 Y156.518 E-.05191
G1 X24.724 Y156.616 E-.0519
G1 X24.663 Y156.646 E-.01288
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.895 Y154.321 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.538 Y154.321 E.01211
G2 X26.03 Y154.321 I.248 J4.675 E.97908
G1 X25.955 Y154.321 E.00254
M204 S10000
G1 X25.895 Y153.915 F36000
G1 F1473.913
M204 S3000
G1 X25.517 Y153.915 E.01279
G2 X26.052 Y153.915 I.268 J5.082 E1.06422
G1 X25.955 Y153.915 E.00327
M204 S250
G1 X25.895 Y153.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.498 Y153.523 E.01246
G2 X26.072 Y153.523 I.288 J5.473 E1.06175
G1 X25.955 Y153.523 E.00367
; WIPE_START
M204 S3000
G1 X25.498 Y153.523 E-.08687
G1 X24.927 Y153.583 E-.109
G1 X24.366 Y153.702 E-.10906
G1 X23.99 Y153.824 E-.07506
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.741 Y161.453 Z1.2 F36000
G1 X23.701 Y162.699 Z1.2
G1 Z.8
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.479013
G1 F1375.855
M204 S3000
G1 X24.078 Y162.899 E.01547
G1 X24.883 Y163.16 E.03071
G1 X25.537 Y163.253 E.02395
G2 X27.077 Y163.058 I.12 J-5.245 E.0565
G2 X27.934 Y162.676 I-2.774 J-7.364 E.03406
G2 X28.652 Y162.15 I-4.809 J-7.317 E.03228
G1 X29.215 Y161.521 E.03061
G2 X29.683 Y160.71 I-6.127 J-4.082 E.03397
G1 X29.946 Y159.902 E.03081
G1 X30.038 Y159.248 E.02394
G2 X29.875 Y157.858 I-4.749 J-.145 E.05093
G1 X29.751 Y157.453 E.01538
G1 X29.366 Y156.692 E.03092
G1 X28.961 Y156.164 E.02413
G1 X28.604 Y155.811 E.0182
G1 X27.957 Y155.349 E.02881
G1 X27.698 Y155.196 E.01093
G2 X25.985 Y154.746 I-2.071 J4.397 E.06457
G1 X25.142 Y154.792 E.03061
G2 X23.677 Y155.298 I.915 J5.029 E.05642
G2 X22.92 Y155.853 I4.524 J6.972 E.03406
G1 X22.355 Y156.48 E.03059
G2 X21.888 Y157.29 I6.137 J4.083 E.03395
G1 X21.625 Y158.098 E.03081
G1 X21.532 Y158.752 E.02394
G2 X21.585 Y159.689 I8.293 J.004 E.03404
G1 X21.803 Y160.504 E.0306
G2 X22.632 Y161.86 I4.714 J-1.949 E.05785
G1 X23.265 Y162.43 E.0309
G1 X23.65 Y162.667 E.0164
; WIPE_START
G1 X23.265 Y162.43 E-.08591
G1 X22.632 Y161.86 E-.16189
G1 X22.324 Y161.476 E-.09334
G1 X22.22 Y161.3 E-.03886
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.388 Y162.767 Z1.2 F36000
G1 Z.8
G1 E.4 F1800
; LINE_WIDTH: 0.470608
G1 F1402.893
M204 S3000
G3 X25.405 Y162.808 I-.634 J-3.36 E.03512
G1 X24.625 Y162.643 E.02834
G1 X23.893 Y162.322 E.02844
G1 X23.243 Y161.856 E.02842
G1 X22.701 Y161.265 E.02853
G1 X22.386 Y160.751 E.02144
G1 X22.098 Y160.011 E.02825
G1 X21.968 Y159.22 E.02852
G1 X21.977 Y158.617 E.02143
G1 X22.142 Y157.839 E.02827
G1 X22.463 Y157.107 E.02843
G1 X22.943 Y156.441 E.02921
G1 X23.522 Y155.918 E.02774
G1 X24.03 Y155.599 E.02133
G1 X24.774 Y155.312 E.02836
G1 X25.566 Y155.183 E.02852
G1 X26.166 Y155.193 E.02135
G1 X26.785 Y155.314 E.02243
G1 X27.53 Y155.602 E.0284
G1 X28.205 Y156.044 E.0287
G3 X29.202 Y157.284 I-3.025 J3.456 E.05687
G1 X29.473 Y157.989 E.02686
G1 X29.603 Y158.78 E.02852
G1 X29.594 Y159.381 E.02135
G1 X29.429 Y160.16 E.02834
G1 X29.115 Y160.879 E.02787
G1 X28.64 Y161.544 E.02906
G1 X28.208 Y161.961 E.02137
G1 X27.685 Y162.313 E.02242
G1 X26.947 Y162.639 E.02869
G1 X26.446 Y162.754 E.01827
; CHANGE_LAYER
; Z_HEIGHT: 1
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1402.893
G1 X26.947 Y162.639 E-.09759
G1 X27.685 Y162.313 E-.15327
G1 X28.208 Y161.961 E-.11978
G1 X28.243 Y161.927 E-.00936
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L5
M991 S0 P4 ;notify layer change


M204 S10000
G17
G3 Z1.2 I1.217 J0 P1  F36000
; object ids of layer 5 start: 7,8,9,10,11,12,13,14,15
M624 /wEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer5 end: 7,8,9,10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.16 Y93.508
M73 P33 R31
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X229.072 Y93.528 E.00308
G2 X230.182 Y93.353 I1.12 J3.483 E.73992
G1 X230.012 Y93.357 E.00578
G2 X229.442 Y93.43 I.18 J3.654 E.01946
G1 X229.218 Y93.492 E.00786
M204 S10000
G1 X229.239 Y93.914 F36000
G1 F1473.913
M204 S3000
G1 X228.879 Y94.037 E.01287
G2 X230.183 Y93.76 I1.314 J2.974 E.64608
G1 X230.033 Y93.764 E.0051
G2 X229.361 Y93.868 I.16 J3.248 E.02307
G1 X229.295 Y93.893 E.00238
M204 S250
G1 X229.368 Y94.28 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.177 Y94.339 E.00626
G2 X230.185 Y94.152 I1.016 J2.673 E.53103
G1 X230.054 Y94.155 E.00411
G2 X229.462 Y94.247 I.14 J2.856 E.01879
G1 X229.425 Y94.26 E.00126
; WIPE_START
M204 S3000
G1 X229.177 Y94.339 E-.04931
G1 X228.905 Y94.463 E-.05695
G1 X228.645 Y94.613 E-.05686
G1 X228.403 Y94.789 E-.05686
G1 X228.078 Y95.098 E-.08533
G1 X227.838 Y95.41 E-.0747
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.092 Y92.817 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.071 Y92.827 E.00077
G2 X230.449 Y92.321 I2.133 J4.181 E.91499
G2 X229.954 Y92.321 I-.245 J5.336 E.01674
G2 X228.52 Y92.627 I.249 J4.687 E.04984
G1 X228.146 Y92.793 E.01384
M204 S10000
G1 X227.926 Y92.446 F36000
G1 F1473.913
M204 S3000
G1 X227.886 Y92.464 E.00149
G2 X230.47 Y91.915 I2.317 J4.544 E.99432
G2 X229.934 Y91.915 I-.266 J5.787 E.01814
G2 X228.374 Y92.247 I.269 J5.093 E.05421
G1 X227.981 Y92.422 E.01457
M204 S250
G1 X227.767 Y92.088 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
M73 P34 R31
G1 X227.708 Y92.115 E.00202
G2 X230.491 Y91.523 I2.495 J4.893 E.99182
G2 X229.915 Y91.523 I-.287 J6.216 E.01805
G2 X228.233 Y91.881 I.288 J5.485 E.05413
G1 X227.822 Y92.064 E.01413
; WIPE_START
M204 S3000
G1 X227.708 Y92.115 E-.02366
G1 X227.21 Y92.402 E-.1093
G1 X226.744 Y92.74 E-.10934
G1 X226.525 Y92.927 E-.05464
G1 X226.216 Y93.236 E-.08306
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.356 Y93.266 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672814
G1 F952.542
M204 S3000
G1 X228.313 Y93.285 E.00245
G2 X226.025 Y97.003 I1.89 J3.726 E.2406
G1 X226.049 Y97.457 E.02378
G1 X226.17 Y98.101 E.03432
G1 X226.386 Y98.711 E.03391
G1 X226.699 Y99.287 E.03435
G1 X227.098 Y99.807 E.03434
G1 X227.567 Y100.253 E.03391
G1 X228.107 Y100.626 E.03433
G1 X228.512 Y100.831 E.02378
G2 X228.706 Y93.111 I1.691 J-3.82 E.85883
G1 X228.411 Y93.242 E.0169
; OBJECT_ID: 12
; WIPE_START
G1 X228.313 Y93.285 E-.0203
G1 X227.754 Y93.627 E-.12448
G1 X227.568 Y93.77 E-.04468
G1 X227.249 Y94.057 E-.08149
G1 X226.876 Y94.493 E-.10905
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.615 Y96.845 Z1.4 F36000
G1 X211.925 Y99.335 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.055 Y99.15 E.00767
G2 X208.979 Y93.12 I-3.277 J-2.128 E.27708
G2 X208.573 Y93.12 I-.201 J4.394 E.01376
G2 X211.813 Y99.483 I.205 J3.901 E.52611
G1 X211.888 Y99.383 E.00424
M204 S10000
G1 X211.586 Y99.114 F36000
G1 F1473.913
M204 S3000
G1 X211.603 Y99.078 E.00135
G2 X208.756 Y93.523 I-2.836 J-2.053 E.26079
G1 X208.594 Y93.527 E.00548
G2 X211.374 Y99.362 I.172 J3.497 E.46606
G1 X211.547 Y99.159 E.00903
M204 S250
G1 X211.282 Y98.867 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.286 Y98.847 E.00064
G2 X208.757 Y93.915 I-2.519 J-1.823 E.21452
G1 X208.615 Y93.919 E.00447
G2 X211.082 Y99.1 I.152 J3.106 E.3834
G1 X211.243 Y98.913 E.00772
; WIPE_START
M204 S3000
G1 X211.286 Y98.847 E-.01493
G1 X211.481 Y98.562 E-.06562
G1 X211.619 Y98.29 E-.05802
G1 X211.735 Y97.986 E-.06186
G1 X211.82 Y97.671 E-.06185
G1 X211.871 Y97.35 E-.06183
G1 X211.878 Y97.056 E-.05589
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.744 Y99.45 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.968 Y99.792 E.01384
G2 X209.27 Y101.709 I3.811 J-2.767 E.16693
G2 X209.024 Y92.321 I-.494 J-4.684 E.4757
G2 X204.7 Y99.379 I-.245 J4.703 E.34215
G1 X204.712 Y99.399 E.00081
M204 S10000
G1 X204.403 Y99.671 F36000
G1 F1473.913
M204 S3000
G1 X204.639 Y100.031 E.01456
G2 X209.312 Y102.114 I4.14 J-3.007 E.18135
G2 X209.045 Y91.915 I-.537 J-5.089 E.51684
G2 X204.347 Y99.582 I-.266 J5.11 E.37173
G1 X204.371 Y99.621 E.00153
M204 S250
G1 X204.075 Y99.885 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.322 Y100.262 E.01414
G2 X209.353 Y102.504 I4.458 J-3.237 E.18086
G2 X209.066 Y91.523 I-.578 J-5.479 E.51544
G2 X204.008 Y99.778 I-.286 J5.502 E.37073
G1 X204.043 Y99.834 E.00206
; WIPE_START
M204 S3000
G1 X204.322 Y100.262 E-.09707
G1 X204.683 Y100.711 E-.10951
G1 X205.091 Y101.119 E-.10964
G1 X205.352 Y101.33 E-.06378
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.083 Y99.232 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435954
G1 F1526.587
M204 S3000
G1 X205.167 Y99.376 E.00544
G2 X204.468 Y97.019 I3.611 J-2.352 E.80345
G1 X204.491 Y97.475 E.01492
G1 X204.562 Y97.921 E.01474
G1 X204.679 Y98.356 E.01474
G1 X204.833 Y98.76 E.0141
G2 X204.939 Y98.982 I3.944 J-1.736 E.00806
G1 X205.053 Y99.18 E.00746
; OBJECT_ID: 11
; WIPE_START
G1 X205.167 Y99.376 E-.04304
G1 X205.428 Y99.737 E-.08474
G1 X205.73 Y100.072 E-.08565
G1 X206.065 Y100.374 E-.08566
G1 X206.41 Y100.624 E-.08091
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X199.033 Y98.663 Z1.4 F36000
G1 X183.933 Y94.647 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.837 Y94.775 E.00538
G2 X187.539 Y92.885 I3.488 J2.262 E.73671
G2 X187.106 Y92.885 I-.214 J4.675 E.01465
G2 X184.234 Y94.257 I.219 J4.151 E.11056
G1 X183.969 Y94.6 E.01467
M204 S10000
G1 X184.235 Y94.917 F36000
G1 F1473.913
M204 S3000
G1 X184.076 Y95.164 E.00994
G2 X187.519 Y93.292 I3.249 J1.873 E.65791
G2 X187.128 Y93.292 I-.194 J4.221 E.01324
G2 X184.29 Y94.834 I.197 J3.745 E.11303
G1 X184.268 Y94.867 E.00132
M204 S250
G1 X184.563 Y95.13 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.407 Y95.355 E.00859
G2 X187.302 Y93.68 I2.907 J1.684 E.55202
G1 X187.148 Y93.684 E.00483
G2 X184.599 Y95.059 I.165 J3.355 E.0939
G1 X184.59 Y95.076 E.00061
; WIPE_START
M204 S3000
G1 X184.407 Y95.355 E-.06335
G1 X184.255 Y95.673 E-.06695
G1 X184.129 Y96.001 E-.06681
G1 X184.038 Y96.341 E-.06681
G1 X183.983 Y96.688 E-.06681
G1 X183.976 Y96.947 E-.04926
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.434 Y92.321 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.074 Y92.321 E.01218
G2 X187.571 Y92.321 I.251 J4.714 E.98725
G1 X187.494 Y92.321 E.00262
M204 S10000
G1 X187.434 Y91.915 F36000
G1 F1473.913
M204 S3000
G1 X187.054 Y91.915 E.01286
G2 X187.593 Y91.915 I.271 J5.121 E1.07239
G1 X187.494 Y91.915 E.00335
M204 S250
G1 X187.434 Y91.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.523 E.01251
G2 X187.613 Y91.523 I.29 J5.512 E1.06933
G1 X187.494 Y91.523 E.00375
; WIPE_START
M204 S3000
G1 X187.035 Y91.523 E-.0872
G1 X186.46 Y91.583 E-.10977
G1 X185.895 Y91.704 E-.10986
G1 X185.528 Y91.823 E-.07318
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.494 Y92.603 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200553
G1 F3806.327
M204 S3000
G1 X187.094 Y92.604 E.00524
G2 X182.882 Y97.039 I.23 J4.435 E.08843
G1 X182.907 Y97.504 E.0061
G1 X182.979 Y97.961 E.00606
G1 X183.034 Y98.191 E.00311
G1 X183.178 Y98.633 E.00609
G2 X187.556 Y92.604 I4.145 J-1.594 E.24989
G1 X187.554 Y92.604 E.00004
; OBJECT_ID: 10
; WIPE_START
G1 X187.094 Y92.604 E-.08738
G1 X186.86 Y92.622 E-.04457
G1 X186.403 Y92.694 E-.08794
G1 X186.172 Y92.749 E-.04502
G1 X185.732 Y92.892 E-.08789
G1 X185.602 Y92.95 E-.0272
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.971 Y93.12 Z1.4 F36000
G1 X163.312 Y93.447 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.249 Y93.489 E.00255
G2 X166.068 Y92.652 I2.592 J3.563 E.83567
G2 X165.61 Y92.652 I-.227 J4.955 E.01554
G2 X163.636 Y93.237 I.232 J4.4 E.07032
G1 X163.362 Y93.414 E.01105
M204 S10000
G1 X163.533 Y93.788 F36000
G1 F1473.913
M204 S3000
G1 X163.488 Y93.818 E.00183
G2 X166.048 Y93.058 I2.352 J3.235 E.75847
G2 X165.631 Y93.058 I-.207 J4.501 E.01413
G2 X163.84 Y93.59 I.21 J3.994 E.06383
G1 X163.584 Y93.755 E.01032
M204 S250
G1 X163.747 Y94.116 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.719 Y94.135 E.00105
G2 X166.029 Y93.45 I2.122 J2.918 E.6337
G2 X165.652 Y93.45 I-.188 J4.07 E.01183
G2 X164.036 Y93.929 I.189 J3.603 E.05334
G1 X163.797 Y94.084 E.00892
; WIPE_START
M204 S3000
G1 X163.719 Y94.135 E-.01774
G1 X163.288 Y94.503 E-.10766
G1 X163.035 Y94.783 E-.07176
G1 X162.813 Y95.089 E-.07178
G1 X162.624 Y95.416 E-.07181
G1 X162.54 Y95.605 E-.03925
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.084 Y101.455 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.144 Y101.475 E.00214
G2 X166.088 Y92.321 I1.697 J-4.423 E.55413
G2 X165.589 Y92.321 I-.247 J5.379 E.01689
G2 X163.691 Y101.273 I.252 J4.73 E.41968
G1 X164.029 Y101.43 E.01261
M204 S10000
G1 X163.918 Y101.826 F36000
G1 F1473.913
M204 S3000
G1 X163.998 Y101.854 E.00286
G2 X166.11 Y91.915 I1.843 J-4.803 E.60171
G2 X165.569 Y91.915 I-.269 J5.83 E.0183
G2 X163.506 Y101.636 I.272 J5.137 E.4558
G1 X163.864 Y101.801 E.01333
M204 S250
G1 X163.759 Y102.184 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.858 Y102.22 E.0033
G2 X166.13 Y91.523 I1.983 J-5.169 E.59981
G2 X165.55 Y91.523 I-.29 J6.257 E.0182
G2 X163.329 Y101.985 I.291 J5.528 E.45445
G1 X163.705 Y102.159 E.01299
; OBJECT_ID: 9
; WIPE_START
M204 S3000
G1 X163.858 Y102.22 E-.03134
G1 X164.129 Y102.324 E-.05512
G1 X164.689 Y102.474 E-.11015
G1 X165.262 Y102.565 E-.11028
G1 X165.646 Y102.585 E-.07311
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 9
M624 BAAAAAAAAAA=
M204 S10000
G1 X158.014 Y102.688 Z1.4 F36000
G1 X147.606 Y102.829 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X147.655 Y102.806 E.00183
G2 X148.7 Y101.345 I-.588 J-1.524 E.06435
G1 X148.7 Y94.279 E.23919
G2 X147.131 Y92.696 I-1.606 J.023 E.08337
G1 X137.064 Y92.696 E.34074
G2 X135.482 Y94.221 I.03 J1.614 E.08179
G1 X135.482 Y101.39 E.24264
G2 X137.051 Y102.914 I1.631 J-.109 E.08111
G1 X147.117 Y102.914 E.34074
G2 X147.451 Y102.869 I-.05 J-1.633 E.01143
G1 X147.548 Y102.844 E.0034
M204 S10000
G1 X147.56 Y102.408 F36000
G1 F1473.913
M204 S3000
G1 X147.777 Y102.284 E.00847
M73 P35 R31
G2 X148.293 Y101.329 I-.704 J-.997 E.03806
G1 X148.293 Y94.289 E.23829
G2 X147.114 Y93.103 I-1.225 J.039 E.06227
G1 X137.075 Y93.103 E.33984
G2 X135.889 Y94.242 I.019 J1.206 E.06123
G1 X135.889 Y101.368 E.2412
G2 X137.067 Y102.507 I1.218 J-.081 E.06079
G1 X147.107 Y102.507 E.33984
G2 X147.504 Y102.429 I-.034 J-1.22 E.01377
M204 S250
G1 X147.376 Y102.064 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X147.378 Y102.059 E.00015
G2 X147.901 Y101.314 I-.299 J-.766 E.03026
G1 X147.901 Y94.3 E.21992
G2 X147.099 Y93.495 I-.826 J.022 E.03925
G1 X137.085 Y93.495 E.31398
G2 X136.281 Y94.263 I.008 J.813 E.03837
G1 X136.281 Y101.348 E.22213
G2 X137.082 Y102.115 I.821 J-.055 E.03817
G1 X147.096 Y102.115 E.31398
G2 X147.27 Y102.093 I-.018 J-.822 E.00551
G1 X147.318 Y102.08 E.00155
; WIPE_START
M204 S3000
G1 X147.378 Y102.059 E-.01197
G1 X147.632 Y101.908 E-.05627
G1 X147.748 Y101.779 E-.03289
G1 X147.813 Y101.673 E-.0236
G1 X147.862 Y101.556 E-.02418
G1 X147.901 Y101.314 E-.04659
G1 X147.901 Y100.343 E-.1845
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X148.092 Y92.713 Z1.4 F36000
G1 X148.095 Y92.599 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X147.9 Y92.488 E.00759
G2 X147.161 Y92.317 I-.81 J1.82 E.02584
G1 X137.104 Y92.314 E.34042
G2 X135.1 Y94.318 I-.006 J1.998 E.10663
G1 X135.1 Y101.292 E.23606
G2 X137.104 Y103.296 I1.998 J.006 E.10663
G1 X147.078 Y103.296 E.33761
G2 X149.081 Y101.292 I.006 J-1.998 E.10663
G1 X149.081 Y94.318 E.23606
G2 X148.26 Y92.695 I-1.992 J-.011 E.06394
G1 X148.146 Y92.629 E.00446
M204 S10000
G1 X148.289 Y92.23 F36000
G1 F1473.913
M204 S3000
G2 X147.18 Y91.91 I-1.199 J2.078 E.03946
G1 X137.098 Y91.907 E.34125
G2 X134.693 Y94.313 I.001 J2.406 E.12789
G1 X134.693 Y101.298 E.23643
G2 X137.098 Y103.703 I2.406 J-.001 E.12789
G1 X147.083 Y103.703 E.33797
G2 X149.489 Y101.298 I-.001 J-2.406 E.12789
G1 X149.489 Y94.313 E.23643
G2 X148.341 Y92.26 I-2.399 J-.006 E.0832
M204 S250
G1 X148.499 Y91.898 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X148.485 Y91.89 E.00049
G2 X147.198 Y91.518 I-1.396 J2.417 E.04241
G1 X137.093 Y91.515 E.31684
G2 X134.301 Y94.308 I.007 J2.799 E.13745
G1 X134.301 Y101.303 E.21931
G2 X137.093 Y104.095 I2.799 J-.007 E.13745
G1 X147.088 Y104.095 E.31337
G2 X149.881 Y101.303 I-.007 J-2.799 E.13745
G1 X149.881 Y94.308 E.21931
G2 X148.73 Y92.049 I-2.791 J-.001 E.08251
G1 X148.549 Y91.931 E.00677
; OBJECT_ID: 8
; WIPE_START
M204 S3000
G1 X148.485 Y91.89 E-.01439
G1 X148.225 Y91.757 E-.05549
G1 X147.952 Y91.652 E-.05554
G1 X147.671 Y91.576 E-.05544
G1 X147.198 Y91.518 E-.09041
G1 X146.626 Y91.518 E-.10873
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 9
M625
; start printing object, unique label id: 8
M624 AgAAAAAAAAA=
M204 S10000
G1 X139.369 Y93.882 Z1.4 F36000
G1 X99.574 Y106.842 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X99.588 Y106.887 E.00158
G2 X101.064 Y107.914 I1.498 J-.577 E.06461
G1 X121.122 Y107.914 E.67893
G2 X122.7 Y106.345 I-.028 J-1.607 E.08321
G1 X122.7 Y94.268 E.4088
G2 X121.128 Y92.696 I-1.606 J.034 E.08309
G1 X101.064 Y92.696 E.67914
G2 X99.481 Y94.279 I.024 J1.606 E.0838
G1 X99.481 Y106.336 E.40814
G2 X99.532 Y106.712 I1.605 J-.026 E.01285
G1 X99.556 Y106.785 E.00261
M204 S10000
G1 X99.961 Y106.717 F36000
G1 F1473.913
M204 S3000
G1 X99.975 Y106.736 E.00081
G2 X101.075 Y107.507 I1.139 J-.454 E.04811
G1 X121.109 Y107.507 E.67814
G2 X122.293 Y106.329 I-.042 J-1.225 E.06219
G1 X122.293 Y94.283 E.40775
G2 X121.113 Y93.103 I-1.225 J.045 E.06211
G1 X101.075 Y93.103 E.67827
G2 X99.889 Y94.289 I.041 J1.227 E.06251
G1 X99.889 Y106.324 E.40735
G2 X99.932 Y106.609 I1.225 J-.042 E.00979
G1 X99.946 Y106.659 E.00174
M204 S250
G1 X100.334 Y106.594 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X100.339 Y106.595 E.00015
G2 X101.085 Y107.115 I.768 J-.306 E.0302
G1 X121.097 Y107.115 E.62747
G2 X121.901 Y106.314 I-.023 J-.826 E.03922
G1 X121.901 Y94.297 E.37676
G2 X121.098 Y93.495 I-.826 J.024 E.0392
G1 X101.085 Y93.495 E.62751
G2 X100.281 Y94.3 I.024 J.828 E.03932
G1 X100.281 Y106.312 E.37663
G1 X100.323 Y106.535 E.00714
; WIPE_START
M204 S3000
G1 X100.339 Y106.595 E-.01166
G1 X100.49 Y106.85 E-.05634
G1 X100.652 Y106.986 E-.04018
G1 X100.761 Y107.046 E-.02362
G1 X100.881 Y107.088 E-.02418
G1 X101.085 Y107.115 E-.03913
G1 X102.058 Y107.115 E-.18489
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X108.238 Y102.637 Z1.4 F36000
G1 X122.091 Y92.597 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X121.9 Y92.488 E.00747
G2 X121.161 Y92.317 I-.81 J1.82 E.02584
G1 X101.104 Y92.314 E.67891
G2 X99.1 Y94.318 I-.003 J2.001 E.10658
G1 X99.1 Y106.292 E.4053
G2 X101.104 Y108.296 I1.998 J.006 E.10663
G1 X121.078 Y108.296 E.6761
G2 X123.081 Y106.292 I.006 J-1.998 E.10663
G1 X123.081 Y94.318 E.4053
G2 X122.26 Y92.696 I-1.992 J-.011 E.06393
G1 X122.143 Y92.627 E.00458
M204 S10000
G1 X122.289 Y92.23 F36000
G1 F1473.913
M204 S3000
G2 X121.18 Y91.91 I-1.199 J2.078 E.03946
G1 X101.098 Y91.907 E.67974
G2 X98.693 Y94.313 I.004 J2.41 E.12784
G1 X98.693 Y106.298 E.40567
G2 X101.098 Y108.703 I2.406 J-.001 E.12789
G1 X121.083 Y108.703 E.67646
G2 X123.489 Y106.298 I-.001 J-2.406 E.12789
G1 X123.489 Y94.313 E.40567
G2 X122.341 Y92.26 I-2.399 J-.006 E.0832
M204 S250
G1 X122.496 Y91.896 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X122.485 Y91.89 E.00038
G2 X121.198 Y91.518 I-1.396 J2.417 E.04241
M73 P35 R30
G1 X101.093 Y91.515 E.63038
G2 X98.301 Y94.308 I.01 J2.803 E.13741
G1 X98.301 Y106.303 E.37608
G2 X101.093 Y109.095 I2.799 J-.007 E.13745
G1 X121.088 Y109.095 E.62692
G2 X123.881 Y106.303 I-.007 J-2.799 E.13745
G1 X123.881 Y94.308 E.37608
G2 X122.73 Y92.049 I-2.791 J-.001 E.08251
G1 X122.546 Y91.929 E.00689
; OBJECT_ID: 7
; WIPE_START
M204 S3000
G1 X122.485 Y91.89 E-.01372
G1 X122.225 Y91.757 E-.05549
G1 X121.952 Y91.652 E-.05554
G1 X121.671 Y91.576 E-.05544
G1 X121.198 Y91.518 E-.09041
G1 X120.623 Y91.518 E-.1094
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 8
M625
; start printing object, unique label id: 7
M624 AQAAAAAAAAA=
M204 S10000
G1 X116.171 Y97.718 Z1.4 F36000
G1 X85.703 Y140.159 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X85.815 Y140.011 E.00629
M73 P36 R30
G2 X86.7 Y137.318 I-3.739 J-2.721 E.09751
G1 X86.7 Y97.292 E1.35485
G2 X82.104 Y92.696 I-4.624 J.028 E.24396
G1 X26.077 Y92.696 E1.89643
G2 X21.481 Y97.292 I.028 J4.624 E.24396
G1 X21.481 Y137.318 E1.35485
G2 X26.077 Y141.914 I4.624 J-.028 E.24396
G1 X82.104 Y141.914 E1.89643
G2 X85.511 Y140.385 I-.028 J-4.624 E.13014
G1 X85.664 Y140.205 E.00799
M204 S10000
G1 X85.401 Y139.888 F36000
G1 F1473.913
M204 S3000
G1 X85.61 Y139.591 E.01231
G2 X86.293 Y137.313 I-3.533 J-2.299 E.0816
G1 X86.293 Y97.297 E1.35449
G2 X82.099 Y93.103 I-4.216 J.022 E.22269
G1 X26.083 Y93.103 E1.89607
G2 X21.889 Y97.297 I.021 J4.216 E.22269
G1 X21.889 Y137.313 E1.35449
G2 X26.083 Y141.507 I4.216 J-.021 E.22269
G1 X82.099 Y141.507 E1.89607
G2 X85.352 Y139.946 I-.021 J-4.216 E.12623
G1 X85.362 Y139.934 E.00053
M204 S250
G1 X85.084 Y139.658 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X85.282 Y139.378 E.01076
G2 X85.901 Y137.308 I-3.204 J-2.085 E.06866
G1 X85.901 Y97.302 E1.25435
G2 X82.093 Y93.495 I-3.823 J.015 E.1873
G1 X26.088 Y93.495 E1.75602
G2 X22.281 Y97.302 I.015 J3.823 E.1873
G1 X22.281 Y137.308 E1.25435
G2 X26.088 Y141.115 I3.823 J-.015 E.1873
G1 X82.093 Y141.115 E1.75602
G2 X85.045 Y139.703 I-.015 J-3.823 E.106
; WIPE_START
M204 S3000
G1 X85.282 Y139.378 E-.07657
G1 X85.571 Y138.855 E-.11354
G1 X85.714 Y138.483 E-.07577
G1 X85.817 Y138.097 E-.07576
G1 X85.849 Y137.898 E-.03836
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X78.237 Y138.455 Z1.4 F36000
G1 X25.83 Y142.288 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X26.104 Y142.296 I.278 J-5 E.00928
G1 X82.078 Y142.296 E1.89465
G2 X87.081 Y137.292 I.008 J-4.996 E.26617
G1 X87.081 Y97.318 E1.35307
G2 X82.3 Y92.32 I-4.994 J-.009 E.25863
G1 X26.104 Y92.314 E1.90218
G2 X21.1 Y97.318 I.004 J5.008 E.26599
M73 P37 R30
G1 X21.1 Y137.292 E1.35307
G2 X25.77 Y142.285 I5.008 J-.004 E.25469
M204 S10000
G1 X25.814 Y142.696 F36000
G1 F1473.913
M204 S3000
G1 X26.098 Y142.703 E.00963
G1 X82.083 Y142.703 E1.89502
G2 X87.489 Y137.298 I.003 J-5.403 E.28745
G1 X87.489 Y97.313 E1.35343
G2 X82.31 Y91.913 I-5.401 J-.004 E.27974
G1 X26.098 Y91.907 E1.90272
G2 X20.693 Y97.313 I.011 J5.416 E.28726
G1 X20.693 Y137.298 E1.35343
G2 X25.754 Y142.692 I5.416 J-.011 E.2756
M204 S250
G1 X25.804 Y143.088 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.093 Y143.095 E.00909
G1 X82.088 Y143.095 E1.75567
G2 X87.881 Y137.303 I-.017 J-5.809 E.28507
G1 X87.881 Y97.308 E1.254
G2 X82.321 Y91.521 I-5.793 J.001 E.27796
G1 X26.093 Y91.515 E1.76297
G2 X20.301 Y97.308 I.017 J5.809 E.28507
G1 X20.301 Y137.303 E1.254
G2 X25.744 Y143.084 I5.809 J-.017 E.27411
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X26.093 Y143.095 E-.06646
G1 X27.744 Y143.095 E-.31354
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 7
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X32.996 Y148.633 Z1.4 F36000
G1 X47.204 Y163.616 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.594 E.01438
G2 X47.385 Y154.321 I-.488 J-4.627 E.46987
G2 X47.142 Y163.619 I-.242 J4.646 E.50283
G1 X47.144 Y163.619 E.00008
M204 S10000
G1 X47.225 Y164.022 F36000
G1 F1473.913
M204 S3000
G1 X47.67 Y163.999 E.01509
G2 X47.406 Y153.914 I-.531 J-5.032 E.511
G2 X47.142 Y164.026 I-.263 J5.052 E.54685
G1 X47.165 Y164.025 E.0008
M204 S250
G1 X47.246 Y164.413 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.712 Y164.389 E.01463
M73 P37 R29
G2 X47.427 Y153.523 I-.572 J-5.422 E.51003
G2 X47.142 Y164.418 I-.283 J5.444 E.54581
G1 X47.186 Y164.416 E.00138
; WIPE_START
M204 S3000
G1 X47.712 Y164.389 E-.10004
G1 X47.994 Y164.351 E-.05421
G1 X48.553 Y164.233 E-.10845
M73 P38 R29
G1 X49.13 Y164.042 E-.11551
G1 X49.139 Y164.038 E-.00179
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.204 Y161.117 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X44.325 Y162.239 E.0516
G2 X45.659 Y163.02 I2.937 J-3.488 E.05057
G1 X43.089 Y160.449 E.1183
G3 X42.887 Y159.694 I3.49 J-1.336 E.02548
G1 X46.414 Y163.221 E.16232
G2 X47.029 Y163.283 I.991 J-6.791 E.02013
G1 X42.829 Y159.082 E.19331
G3 X42.849 Y158.549 I2.548 J-.171 E.0174
G1 X47.563 Y163.263 E.21696
G2 X48.043 Y163.19 I-2.365 J-17.093 E.01581
G1 X42.923 Y158.07 E.23565
G3 X43.036 Y157.629 I3.685 J.707 E.01482
G1 X48.48 Y163.072 E.25053
G1 X48.88 Y162.919 E.01395
G1 X43.19 Y157.229 E.26189
G3 X43.375 Y156.861 I1.836 J.693 E.01344
G1 X49.248 Y162.734 E.27031
G2 X49.588 Y162.52 I-.844 J-1.722 E.01309
G1 X43.588 Y156.521 E.27613
G3 X43.828 Y156.207 I1.615 J.983 E.01288
G1 X49.902 Y162.281 E.27956
G2 X50.192 Y162.024 I-1.486 J-1.971 E.01263
G1 X44.092 Y155.917 E.28089
G3 X44.381 Y155.653 I1.403 J1.243 E.01277
G1 X50.457 Y161.729 E.27965
G2 X50.695 Y161.413 I-1.386 J-1.288 E.01289
G1 X44.695 Y155.414 E.27613
G3 X45.035 Y155.2 I1.185 J1.51 E.01309
G1 X50.906 Y161.071 E.27021
G2 X51.09 Y160.701 I-1.674 J-1.061 E.01346
G1 X45.403 Y155.014 E.26174
G3 X45.808 Y154.866 I1.147 J2.505 E.01406
G1 X51.243 Y160.3 E.25013
G2 X51.36 Y159.864 I-2.016 J-.775 E.01473
G1 X46.245 Y154.749 E.23543
G3 X46.724 Y154.674 I.593 J2.245 E.01581
G1 X51.434 Y159.385 E.21678
G2 X51.454 Y158.851 I-2.526 J-.363 E.0174
G1 X47.257 Y154.654 E.19316
G3 X47.873 Y154.716 I-.009 J3.178 E.02016
G1 X51.396 Y158.24 E.16215
G2 X51.194 Y157.485 I-3.691 J.58 E.02548
G1 X48.628 Y154.918 E.11812
G3 X49.978 Y155.714 I-1.339 J3.812 E.05132
G1 X51.07 Y156.807 E.05028
; OBJECT_ID: 14
; WIPE_START
G1 X49.978 Y155.714 E-.29353
G1 X49.68 Y155.473 E-.07284
G1 X49.62 Y155.434 E-.01363
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X41.988 Y155.539 Z1.4 F36000
G1 X26.795 Y155.748 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.667 Y155.71 E.0045
G2 X25.766 Y155.591 I-.892 J3.29 E.03086
G1 X25.607 Y155.595 E.00539
G2 X27.006 Y155.821 I.169 J3.405 E.67666
G1 X26.851 Y155.767 E.00553
M204 S10000
G1 X26.669 Y156.135 F36000
G1 F1473.913
M204 S3000
G1 X26.562 Y156.103 E.00378
G2 X25.767 Y155.998 I-.786 J2.897 E.02721
G1 X25.628 Y156.002 E.00471
G2 X26.86 Y156.201 I.148 J2.998 E.59585
G1 X26.726 Y156.154 E.00481
M204 S250
G1 X26.548 Y156.507 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.481 E.00286
G2 X25.769 Y156.39 I-.683 J2.518 E.02194
G1 X25.649 Y156.393 E.00376
G2 X26.719 Y156.567 I.128 J2.606 E.47984
G1 X26.605 Y156.527 E.00381
; WIPE_START
M204 S3000
G1 X26.46 Y156.481 E-.02874
G1 X26.194 Y156.422 E-.05188
G1 X25.769 Y156.39 E-.081
G1 X25.649 Y156.393 E-.02275
G1 X25.377 Y156.422 E-.05194
G1 X25.11 Y156.479 E-.05191
G1 X24.85 Y156.563 E-.05188
G1 X24.658 Y156.649 E-.03989
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.899 Y154.321 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.537 Y154.321 E.01226
G2 X26.03 Y154.321 I.249 J4.675 E.97906
G1 X25.959 Y154.321 E.0024
M204 S10000
G1 X25.899 Y153.915 F36000
G1 F1473.913
M204 S3000
G1 X25.517 Y153.915 E.01293
G2 X26.052 Y153.915 I.269 J5.082 E1.06421
G1 X25.959 Y153.915 E.00314
M204 S250
G1 X25.899 Y153.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.498 Y153.523 E.01258
G2 X26.072 Y153.523 I.288 J5.473 E1.06175
G1 X25.959 Y153.523 E.00355
; WIPE_START
M204 S3000
G1 X25.498 Y153.523 E-.08761
G1 X24.927 Y153.583 E-.10899
G1 X24.366 Y153.702 E-.10907
G1 X23.994 Y153.823 E-.07434
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.742 Y161.451 Z1.4 F36000
G1 X23.701 Y162.699 Z1.4
G1 Z1
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.479122
G1 F1375.511
M204 S3000
G1 X24.078 Y162.899 E.01547
G1 X24.886 Y163.161 E.0308
G1 X25.54 Y163.253 E.02395
G2 X26.474 Y163.2 I.001 J-8.296 E.03396
G1 X27.295 Y162.98 E.03082
G1 X27.752 Y162.774 E.0182
G2 X28.653 Y162.149 I-3.346 J-5.785 E.03979
G1 X29.215 Y161.521 E.03061
G2 X29.948 Y159.9 I-4.102 J-2.829 E.06485
G1 X30.036 Y159.246 E.02394
G2 X29.996 Y158.356 I-9.377 J-.022 E.0323
G1 X29.766 Y157.488 E.03259
G1 X29.484 Y156.891 E.02393
G2 X28.933 Y156.134 I-6.417 J4.094 E.03398
G1 X28.306 Y155.57 E.0306
G2 X26.87 Y154.884 I-2.889 J4.197 E.05794
G1 X26.051 Y154.748 E.03014
G1 X25.548 Y154.749 E.01822
G1 X24.706 Y154.883 E.03092
G2 X23.299 Y155.539 I1.45 J4.944 E.05652
G1 X22.66 Y156.107 E.03101
G1 X22.226 Y156.662 E.02555
G1 X21.826 Y157.432 E.03149
G1 X21.668 Y157.91 E.01827
G2 X21.531 Y158.8 I8.677 J1.795 E.03267
G1 X21.578 Y159.643 E.03061
G2 X22.083 Y161.108 I5.027 J-.915 E.05644
G2 X22.638 Y161.866 I6.97 J-4.523 E.03407
G1 X23.265 Y162.43 E.0306
G1 X23.65 Y162.667 E.01641
; WIPE_START
G1 X23.265 Y162.43 E-.08598
G1 X22.638 Y161.866 E-.1603
G1 X22.375 Y161.529 E-.08111
G1 X22.217 Y161.302 E-.05262
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.158 Y162.56 Z1.4 F36000
G1 Z1
G1 E.4 F1800
; LINE_WIDTH: 0.469279
G1 F1407.266
M204 S3000
G1 X26.754 Y162.699 E.01517
G1 X26.005 Y162.817 E.02687
G1 X25.405 Y162.808 E.02129
G1 X24.625 Y162.643 E.02825
G1 X23.893 Y162.322 E.02833
G1 X23.243 Y161.856 E.02835
G1 X22.703 Y161.263 E.02843
G1 X22.384 Y160.755 E.02129
G1 X22.098 Y160.011 E.02825
G1 X21.968 Y159.22 E.02843
G1 X21.978 Y158.619 E.02129
G1 X22.101 Y157.991 E.02271
G3 X22.463 Y157.104 I4.157 J1.182 E.03401
G1 X22.927 Y156.453 E.02834
G3 X23.72 Y155.779 I3.046 J2.781 E.03701
G1 X24.394 Y155.438 E.02678
G1 X25.165 Y155.227 E.02835
G1 X25.96 Y155.175 E.02823
G1 X26.405 Y155.227 E.01588
G1 X27.138 Y155.421 E.02688
G1 X27.68 Y155.679 E.02129
G1 X28.328 Y156.144 E.02825
G1 X28.866 Y156.735 E.02833
G1 X29.272 Y157.424 E.02836
G1 X29.522 Y158.186 E.02845
G1 X29.603 Y158.781 E.02127
G1 X29.568 Y159.576 E.02824
G1 X29.363 Y160.352 E.02846
G1 X29.105 Y160.898 E.02138
G1 X28.64 Y161.544 E.02823
G1 X28.208 Y161.961 E.02128
G1 X27.678 Y162.318 E.02265
G1 X27.212 Y162.534 E.0182
; CHANGE_LAYER
; Z_HEIGHT: 1.2
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1407.266
G1 X27.678 Y162.318 E-.09756
G1 X28.208 Y161.961 E-.12141
G1 X28.64 Y161.544 E-.11402
G1 X28.784 Y161.343 E-.047
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L6
M991 S0 P5 ;notify layer change


M204 S10000
G17
G3 Z1.4 I1.217 J0 P1  F36000
; object ids of layer 6 start: 7,8,9,10,11,12,13,14,15
M624 /wEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer6 end: 7,8,9,10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.118 Y93.522
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.892 Y93.596 E.00804
G2 X230.391 Y93.357 I1.312 J3.413 E.726
G2 X230.011 Y93.357 I-.187 J4.199 E.01286
G2 X229.256 Y93.477 I.193 J3.652 E.02595
G1 X229.175 Y93.503 E.00288
M204 S10000
G1 X229.235 Y93.915 F36000
G1 F1473.913
M204 S3000
G1 X228.88 Y94.041 E.01275
G2 X230.371 Y93.764 I1.323 J2.968 E.63941
G2 X230.033 Y93.764 I-.167 J3.741 E.01145
G2 X229.361 Y93.87 I.171 J3.246 E.02306
G1 X229.292 Y93.895 E.00249
M204 S250
G1 X229.363 Y94.28 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.289 E.00143
G2 X230.181 Y94.152 I.873 J2.723 E.53586
G1 X230.054 Y94.155 E.00399
G2 X229.608 Y94.212 I.138 J2.856 E.01409
G1 X229.421 Y94.264 E.00608
; WIPE_START
M204 S3000
G1 X229.319 Y94.289 E-.02007
G1 X229.04 Y94.399 E-.05693
G1 X228.773 Y94.535 E-.05688
G1 X228.522 Y94.698 E-.05688
G1 X228.289 Y94.886 E-.05689
G1 X228.078 Y95.098 E-.0569
G1 X227.889 Y95.331 E-.05688
G1 X227.836 Y95.413 E-.01857
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.12 Y92.805 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.071 Y92.827 E.00183
G2 X230.449 Y92.321 I2.133 J4.181 E.915
G2 X229.954 Y92.321 I-.244 J5.473 E.01676
G2 X228.52 Y92.627 I.25 J4.687 E.04983
G1 X228.175 Y92.78 E.01277
M204 S10000
G1 X227.955 Y92.433 F36000
G1 F1473.913
M204 S3000
G1 X227.886 Y92.464 E.00255
G2 X230.47 Y91.915 I2.317 J4.544 E.99433
G2 X229.934 Y91.915 I-.266 J5.934 E.01816
G2 X228.374 Y92.247 I.27 J5.093 E.0542
G1 X228.01 Y92.409 E.01349
M204 S250
G1 X227.796 Y92.075 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.708 Y92.115 E.00301
G2 X230.491 Y91.523 I2.495 J4.893 E.99182
G2 X229.915 Y91.523 I-.287 J6.372 E.01806
G2 X228.234 Y91.881 I.289 J5.485 E.05412
G1 X227.851 Y92.051 E.01314
; WIPE_START
M204 S3000
G1 X227.708 Y92.115 E-.02964
G1 X227.21 Y92.402 E-.10932
G1 X226.744 Y92.74 E-.10932
G1 X226.317 Y93.125 E-.1093
G1 X226.235 Y93.211 E-.02243
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.385 Y93.254 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672787
G1 F952.583
M204 S3000
G1 X228.313 Y93.285 E.00409
G2 X226.025 Y97.012 I1.89 J3.726 E.24104
G1 X226.048 Y97.448 E.02292
G1 X226.116 Y97.881 E.02291
G1 X226.23 Y98.303 E.02289
G1 X226.386 Y98.711 E.02291
G1 X226.585 Y99.101 E.0229
G1 X226.823 Y99.467 E.02289
G1 X227.098 Y99.807 E.02291
G1 X227.414 Y100.122 E.02336
G2 X228.706 Y93.111 I2.789 J-3.111 E.92758
G1 X228.44 Y93.229 E.01524
; OBJECT_ID: 12
; WIPE_START
G1 X228.313 Y93.285 E-.02625
G1 X228.107 Y93.397 E-.04462
G1 X227.747 Y93.631 E-.08156
G1 X227.413 Y93.901 E-.0816
G1 X227.243 Y94.063 E-.04464
G1 X226.962 Y94.376 E-.07996
G1 X226.893 Y94.465 E-.02138
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.636 Y96.829 Z1.6 F36000
G1 X211.92 Y99.342 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.152 E.00786
G2 X208.979 Y93.12 I-3.275 J-2.13 E.27721
G2 X208.573 Y93.121 I-.2 J4.481 E.01374
G2 X211.813 Y99.483 I.206 J3.901 E.52609
G1 X211.883 Y99.39 E.00396
M204 S10000
G1 X211.591 Y99.103 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.93 E.00714
G2 X208.959 Y93.527 I-2.934 J-1.908 E.24828
G2 X208.594 Y93.527 I-.18 J4.029 E.01234
G2 X211.497 Y99.227 I.184 J3.495 E.47132
G1 X211.554 Y99.151 E.00323
M204 S250
G1 X211.274 Y98.873 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00597
G2 X208.939 Y93.919 I-2.606 J-1.694 E.20418
G2 X208.615 Y93.919 I-.162 J3.592 E.01018
G2 X211.192 Y98.98 I.163 J3.104 E.38772
G1 X211.237 Y98.92 E.00235
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.04755
G1 X211.549 Y98.437 E-.06179
G1 X211.681 Y98.139 E-.06185
G1 X211.82 Y97.671 E-.09276
M73 P39 R29
G1 X211.871 Y97.35 E-.06183
G1 X211.885 Y97.065 E-.05421
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.759 Y99.472 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.832 Y99.587 E.0046
G2 X209.024 Y92.321 I3.946 J-2.565 E.6506
G2 X208.527 Y92.321 I-.245 J5.492 E.0168
G2 X204.587 Y99.164 I.251 J4.7 E.31704
G1 X204.73 Y99.42 E.00992
M204 S10000
G1 X204.407 Y99.676 F36000
G1 F1473.913
M204 S3000
G1 X204.491 Y99.809 E.00532
G2 X209.045 Y91.915 I4.287 J-2.787 E.70683
G2 X208.507 Y91.915 I-.267 J5.953 E.0182
G2 X204.224 Y99.347 I.27 J5.106 E.34446
G1 X204.378 Y99.623 E.0107
M204 S250
G1 X204.068 Y99.871 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.162 Y100.022 E.00556
G2 X209.066 Y91.523 I4.616 J-3.001 E.70491
G2 X208.488 Y91.523 I-.288 J6.392 E.0181
G2 X203.874 Y99.524 I.289 J5.498 E.34355
G1 X204.039 Y99.819 E.0106
; WIPE_START
M204 S3000
G1 X204.162 Y100.022 E-.04511
G1 X204.496 Y100.492 E-.1095
G1 X204.882 Y100.92 E-.10956
G1 X205.31 Y101.306 E-.10958
G1 X205.337 Y101.326 E-.00625
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.076 Y99.221 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435934
G1 F1526.664
M204 S3000
G1 X205.16 Y99.367 E.00554
G2 X204.468 Y97.025 I3.616 J-2.343 E.8038
G1 X204.491 Y97.475 E.01475
G1 X204.561 Y97.916 E.01456
G1 X204.616 Y98.145 E.00771
G1 X204.756 Y98.574 E.01474
G2 X204.94 Y98.986 I4.021 J-1.549 E.01475
G1 X205.046 Y99.169 E.0069
; OBJECT_ID: 11
; WIPE_START
G1 X205.16 Y99.367 E-.04363
G1 X205.422 Y99.728 E-.08467
G1 X205.575 Y99.908 E-.04486
G1 X205.894 Y100.227 E-.08577
G1 X206.236 Y100.505 E-.08361
G1 X206.398 Y100.616 E-.03746
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X199.016 Y98.676 Z1.6 F36000
G1 X183.891 Y94.7 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.724 Y94.961 E.01049
G2 X187.538 Y92.885 I3.601 J2.076 E.72937
G2 X187.106 Y92.885 I-.213 J4.775 E.01463
G2 X183.961 Y94.595 I.219 J4.151 E.1253
G1 X183.924 Y94.65 E.00221
M204 S10000
G1 X184.232 Y94.921 F36000
G1 F1473.913
M204 S3000
G1 X184.076 Y95.164 E.00977
G2 X187.519 Y93.292 I3.249 J1.873 E.65792
G2 X187.128 Y93.292 I-.193 J4.317 E.01323
G2 X184.29 Y94.835 I.197 J3.745 E.11303
G1 X184.265 Y94.871 E.00149
M204 S250
G1 X184.56 Y95.135 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.21 E.00287
G2 X187.499 Y93.684 I2.817 J1.827 E.55121
G2 X187.148 Y93.684 I-.175 J3.879 E.011
G2 X184.714 Y94.925 I.176 J3.353 E.08825
G1 X184.596 Y95.087 E.00627
; WIPE_START
M204 S3000
G1 X184.507 Y95.21 E-.0288
G1 X184.255 Y95.672 E-.10015
G1 X184.129 Y96.001 E-.06686
G1 X184.038 Y96.341 E-.06681
G1 X183.983 Y96.688 E-.06682
G1 X183.969 Y96.954 E-.05057
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.438 Y92.321 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.073 Y92.322 E.01235
G2 X187.571 Y92.321 I.252 J4.714 E.98723
G1 X187.498 Y92.321 E.00247
M204 S10000
G1 X187.438 Y91.915 F36000
G1 F1473.913
M204 S3000
G1 X187.053 Y91.915 E.01302
G2 X187.593 Y91.915 I.271 J5.121 E1.07237
G1 X187.498 Y91.915 E.0032
M204 S250
G1 X187.438 Y91.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.034 Y91.523 E.01265
G2 X187.613 Y91.523 I.29 J5.512 E1.06932
G1 X187.498 Y91.523 E.00361
; WIPE_START
M204 S3000
G1 X187.034 Y91.523 E-.08805
G1 X186.46 Y91.583 E-.10973
G1 X185.895 Y91.704 E-.10984
G1 X185.532 Y91.821 E-.07238
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.527 Y92.604 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200556
G1 F3806.241
M204 S3000
G1 X186.86 Y92.623 E.00874
G2 X182.882 Y97.037 I.464 J4.417 E.08532
G1 X182.889 Y97.274 E.0031
G1 X182.937 Y97.732 E.00604
G1 X183.034 Y98.191 E.00615
G1 X183.254 Y98.816 E.00868
G1 X183.369 Y99.06 E.00353
G1 X183.598 Y99.457 E.00601
G1 X183.874 Y99.836 E.00614
G1 X184.182 Y100.179 E.00604
G1 X184.352 Y100.34 E.00308
G1 X184.531 Y100.493 E.00307
G1 X184.903 Y100.763 E.00603
G1 X185.314 Y101 E.00621
G2 X187.586 Y92.606 I2.01 J-3.96 E.20677
; OBJECT_ID: 10
; WIPE_START
G1 X186.86 Y92.623 E-.1381
G1 X186.403 Y92.694 E-.08789
G1 X186.173 Y92.749 E-.04498
G1 X185.734 Y92.892 E-.08753
G1 X185.63 Y92.935 E-.02151
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178 Y93.12 Z1.6 F36000
G1 X163.274 Y93.477 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.066 Y93.629 E.00872
G2 X166.068 Y92.651 I2.775 J3.423 E.82789
G2 X165.61 Y92.652 I-.226 J5.062 E.01551
G2 X163.439 Y93.358 I.232 J4.4 E.07815
G1 X163.323 Y93.442 E.00485
M204 S10000
G1 X163.513 Y93.806 F36000
G1 F1473.913
M204 S3000
G1 X163.322 Y93.946 E.008
G2 X166.048 Y93.058 I2.519 J3.107 E.75139
G2 X165.631 Y93.058 I-.206 J4.604 E.01411
G2 X163.661 Y93.699 I.21 J3.994 E.07094
G1 X163.562 Y93.771 E.00414
M204 S250
G1 X163.743 Y94.123 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.569 Y94.25 E.00677
G2 X166.029 Y93.45 I2.272 J2.803 E.62777
G2 X165.652 Y93.45 I-.188 J4.167 E.01182
G2 X163.874 Y94.028 I.189 J3.603 E.05927
G1 X163.792 Y94.088 E.00319
; WIPE_START
M204 S3000
G1 X163.569 Y94.25 E-.05243
G1 X163.288 Y94.502 E-.07176
G1 X163.035 Y94.783 E-.07185
G1 X162.813 Y95.089 E-.07175
G1 X162.624 Y95.416 E-.07182
G1 X162.537 Y95.61 E-.04039
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.067 Y101.45 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.144 Y101.475 E.00274
G2 X166.088 Y92.321 I1.697 J-4.423 E.55414
G2 X165.589 Y92.322 I-.247 J5.524 E.01691
G2 X163.918 Y101.381 I.252 J4.73 E.42817
G1 X164.012 Y101.425 E.00351
M204 S10000
G1 X163.903 Y101.818 F36000
G1 F1473.913
M204 S3000
G1 X164.252 Y101.944 E.01255
G2 X166.11 Y91.915 I1.589 J-4.893 E.5926
G2 X165.569 Y91.915 I-.268 J5.985 E.01831
G2 X163.752 Y101.752 I.272 J5.137 E.46497
G1 X163.848 Y101.794 E.00357
M204 S250
G1 X163.763 Y102.184 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.131 Y102.317 E.01226
G2 X166.13 Y91.523 I1.71 J-5.265 E.59073
G2 X165.55 Y91.523 I-.289 J6.423 E.0182
G2 X163.591 Y102.11 I.291 J5.528 E.46355
G1 X163.708 Y102.16 E.00399
; OBJECT_ID: 9
; WIPE_START
M204 S3000
G1 X164.131 Y102.317 E-.0857
G1 X164.689 Y102.474 E-.11011
G1 X165.261 Y102.565 E-.11017
G1 X165.65 Y102.585 E-.07401
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 9
M624 BAAAAAAAAAA=
M204 S10000
G1 X158.021 Y102.372 Z1.6 F36000
G1 X147.338 Y102.073 Z1.6
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X147.456 Y102.022 E.00403
G2 X147.901 Y101.314 I-.382 J-.733 E.0275
G1 X147.901 Y94.297 E.22
G2 X147.099 Y93.495 I-.826 J.025 E.03916
G1 X137.085 Y93.495 E.31398
G2 X136.281 Y94.263 I.008 J.813 E.03836
G1 X136.281 Y101.348 E.22214
G2 X137.082 Y102.115 I.82 J-.055 E.03817
G1 X147.099 Y102.115 E.31407
G2 X147.28 Y102.09 I-.025 J-.826 E.00576
; WIPE_START
M204 S3000
G1 X147.456 Y102.022 E-.0357
G1 X147.693 Y101.848 E-.05589
G1 X147.813 Y101.673 E-.04023
G1 X147.862 Y101.556 E-.02419
G1 X147.901 Y101.314 E-.04659
G1 X147.901 Y100.38 E-.1774
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X148.431 Y92.766 Z1.6 F36000
G1 X148.491 Y91.893 Z1.6
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X148.485 Y91.89 E.00022
G2 X147.224 Y91.519 I-1.396 J2.418 E.0416
G1 X137.093 Y91.515 E.31764
G2 X134.301 Y94.308 I.007 J2.799 E.13745
G1 X134.301 Y101.303 E.21931
G2 X137.093 Y104.095 I2.801 J-.008 E.13744
G1 X147.088 Y104.095 E.31337
G2 X149.881 Y101.303 I-.007 J-2.799 E.13745
G1 X149.881 Y94.308 E.21931
G2 X148.73 Y92.049 I-2.792 J0 E.08251
G1 X148.542 Y91.926 E.00706
; WIPE_START
M204 S3000
G1 X148.485 Y91.89 E-.01273
G1 X148.237 Y91.762 E-.053
G1 X147.813 Y91.61 E-.08562
G1 X147.527 Y91.55 E-.05548
G1 X147.224 Y91.519 E-.05789
G1 X146.617 Y91.519 E-.11529
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X147.167 Y99.131 Z1.6 F36000
G1 X147.508 Y103.853 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X149.635 Y101.726 E.09431
G1 X149.768 Y101.592
G1 X149.807 Y101.021
G1 X149.673 Y101.154
G1 X146.94 Y103.888 E.12121
G1 X146.806 Y104.022
G1 X146.273 Y104.021
G1 X146.407 Y103.888
G1 X149.673 Y100.621 E.14484
G1 X149.807 Y100.487
G1 X149.807 Y99.954
G1 X149.673 Y100.088
G1 X147.979 Y101.782 E.07511
G1 X147.846 Y101.915
G1 X147.974 Y101.253
G1 X148.108 Y101.12
G1 X149.673 Y99.555 E.06941
G1 X149.807 Y99.421
G1 X149.807 Y98.888
G1 X149.673 Y99.021
G1 X148.108 Y100.587 E.06941
G1 X147.974 Y100.72
G1 X147.974 Y100.187
G1 X148.108 Y100.053
G1 X149.673 Y98.488 E.06941
G1 X149.807 Y98.354
G1 X149.807 Y97.821
G1 X149.673 Y97.955
G1 X148.108 Y99.52 E.06941
G1 X147.974 Y99.654
G1 X147.974 Y99.12
G1 X148.108 Y98.987
G1 X149.673 Y97.422 E.06941
G1 X149.807 Y97.288
G1 X149.807 Y96.755
G1 X149.673 Y96.888
G1 X148.108 Y98.454 E.06941
G1 X147.974 Y98.587
G1 X147.974 Y98.054
G1 X148.108 Y97.92
G1 X149.673 Y96.355 E.06941
G1 X149.807 Y96.221
G1 X149.807 Y95.688
G1 X149.673 Y95.822
G1 X148.108 Y97.387 E.06941
G1 X147.974 Y97.521
G1 X147.974 Y96.987
G1 X148.108 Y96.854
G1 X149.673 Y95.289 E.06941
G1 X149.807 Y95.155
G1 X149.807 Y94.622
G1 X149.673 Y94.755
G1 X148.108 Y96.321 E.06941
G1 X147.974 Y96.454
G1 X147.974 Y95.921
G1 X148.108 Y95.787
G1 X149.666 Y94.229 E.0691
G1 X149.8 Y94.095
G1 X149.739 Y93.623
G1 X149.606 Y93.756
G1 X148.108 Y95.254 E.06642
G1 X147.974 Y95.388
G1 X147.974 Y94.854
G1 X148.108 Y94.721
G1 X149.484 Y93.345 E.06102
G1 X149.618 Y93.211
G1 X149.441 Y92.855
G1 X149.307 Y92.988
G1 X148.097 Y94.199 E.05368
G1 X147.963 Y94.333
G1 X147.833 Y93.929
G1 X147.967 Y93.795
G1 X149.09 Y92.673 E.04979
G1 X149.223 Y92.539
G1 X148.964 Y92.265
G1 X148.83 Y92.399
G1 X147.72 Y93.509 E.04922
G1 X147.586 Y93.643
G1 X147.234 Y93.462
G1 X147.367 Y93.328
G1 X148.53 Y92.165 E.05157
G1 X148.664 Y92.032
G1 X148.32 Y91.843
G1 X148.186 Y91.976
G1 X146.875 Y93.288 E.05816
G1 X146.741 Y93.422
G1 X146.208 Y93.422
G1 X146.341 Y93.288
G1 X147.799 Y91.831 E.06462
G1 X147.932 Y91.697
G1 X147.485 Y91.611
G1 X147.352 Y91.744
G1 X145.808 Y93.288 E.06844
G1 X145.674 Y93.422
G1 X145.141 Y93.422
G1 X145.275 Y93.288
G1 X146.836 Y91.726 E.06925
G1 X146.97 Y91.593
G1 X146.437 Y91.593
G1 X146.303 Y91.726
G1 X144.742 Y93.288 E.06925
G1 X144.608 Y93.422
G1 X144.075 Y93.422
G1 X144.208 Y93.288
G1 X145.77 Y91.726 E.06925
G1 X145.904 Y91.593
G1 X145.37 Y91.593
G1 X145.237 Y91.726
G1 X143.675 Y93.288 E.06925
G1 X143.541 Y93.422
G1 X143.008 Y93.422
G1 X143.142 Y93.288
G1 X144.703 Y91.726 E.06924
G1 X144.837 Y91.593
M73 P40 R29
G1 X144.304 Y91.593
G1 X144.17 Y91.726
G1 X142.608 Y93.288 E.06924
G1 X142.475 Y93.422
G1 X141.942 Y93.422
G1 X142.075 Y93.288
G1 X143.637 Y91.726 E.06924
G1 X143.77 Y91.593
G1 X143.237 Y91.593
G1 X143.104 Y91.726
G1 X141.542 Y93.288 E.06924
G1 X141.408 Y93.422
M73 P40 R28
G1 X140.875 Y93.422
G1 X141.009 Y93.288
G1 X142.57 Y91.726 E.06924
G1 X142.704 Y91.593
G1 X142.171 Y91.593
G1 X142.037 Y91.726
G1 X140.475 Y93.288 E.06924
G1 X140.342 Y93.422
G1 X139.809 Y93.422
G1 X139.942 Y93.288
G1 X141.504 Y91.726 E.06924
G1 X141.637 Y91.593
G1 X141.104 Y91.593
G1 X140.97 Y91.726
G1 X139.409 Y93.288 E.06924
G1 X139.275 Y93.422
G1 X138.742 Y93.422
G1 X138.876 Y93.288
G1 X140.437 Y91.726 E.06924
G1 X140.571 Y91.593
G1 X140.038 Y91.593
G1 X139.904 Y91.726
G1 X138.342 Y93.288 E.06924
G1 X138.209 Y93.422
G1 X137.676 Y93.422
G1 X137.809 Y93.288
G1 X139.371 Y91.726 E.06924
G1 X139.504 Y91.593
G1 X138.971 Y91.593
G1 X138.837 Y91.726
G1 X137.276 Y93.288 E.06924
G1 X137.142 Y93.422
G1 X136.498 Y93.533
G1 X136.631 Y93.399
G1 X138.304 Y91.726 E.07417
; WIPE_START
M204 S3000
G1 X136.89 Y93.141 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X142.7 Y98.09 Z1.6 F36000
G1 X147.545 Y102.216 Z1.6
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X145.874 Y103.887 E.07411
G1 X145.74 Y104.021
G1 X145.207 Y104.021
G1 X145.341 Y103.887
G1 X146.905 Y102.323 E.06938
G1 X147.039 Y102.189
G1 X146.506 Y102.189
G1 X146.372 Y102.323
G1 X144.808 Y103.887 E.06937
G1 X144.674 Y104.021
G1 X144.141 Y104.02
G1 X144.274 Y103.887
G1 X145.839 Y102.323 E.06936
G1 X145.972 Y102.189
G1 X145.439 Y102.189
G1 X145.305 Y102.323
G1 X143.741 Y103.887 E.06935
G1 X143.608 Y104.02
G1 X143.075 Y104.02
G1 X143.208 Y103.886
G1 X144.772 Y102.323 E.06934
G1 X144.906 Y102.189
G1 X144.373 Y102.189
G1 X144.239 Y102.323
G1 X142.675 Y103.886 E.06933
G1 X142.542 Y104.02
G1 X142.009 Y104.02
G1 X142.142 Y103.886
G1 X143.706 Y102.323 E.06932
G1 X143.839 Y102.189
G1 X143.306 Y102.189
G1 X143.172 Y102.323
G1 X141.609 Y103.886 E.06931
G1 X141.476 Y104.019
G1 X140.943 Y104.019
G1 X141.076 Y103.886
G1 X142.639 Y102.323 E.0693
G1 X142.773 Y102.189
G1 X142.239 Y102.189
G1 X142.106 Y102.323
G1 X140.543 Y103.885 E.0693
G1 X140.409 Y104.019
G1 X139.876 Y104.019
G1 X140.01 Y103.885
G1 X141.573 Y102.323 E.06929
G1 X141.706 Y102.189
G1 X141.173 Y102.189
G1 X141.039 Y102.323
G1 X139.477 Y103.885 E.06928
G1 X139.343 Y104.019
G1 X138.81 Y104.018
G1 X138.944 Y103.885
G1 X140.506 Y102.323 E.06927
G1 X140.64 Y102.189
G1 X140.106 Y102.189
G1 X139.973 Y102.323
G1 X138.411 Y103.885 E.06926
G1 X138.277 Y104.018
G1 X137.744 Y104.018
G1 X137.878 Y103.884
G1 X139.44 Y102.323 E.06925
G1 X139.573 Y102.189
G1 X139.04 Y102.189
G1 X138.906 Y102.323
G1 X137.345 Y103.884 E.06924
G1 X137.211 Y104.018
G1 X136.692 Y104.004
G1 X136.825 Y103.87
G1 X138.373 Y102.323 E.06863
G1 X138.507 Y102.189
G1 X137.973 Y102.189
G1 X137.84 Y102.323
G1 X136.379 Y103.784 E.06479
G1 X136.245 Y103.917
G1 X135.857 Y103.772
G1 X135.99 Y103.639
G1 X137.307 Y102.323 E.05836
G1 X137.44 Y102.189
G1 X136.947 Y102.148
G1 X136.814 Y102.282
G1 X135.651 Y103.445 E.05157
G1 X135.517 Y103.579
G1 X135.221 Y103.341
G1 X135.355 Y103.208
G1 X136.461 Y102.102 E.04905
G1 X136.595 Y101.968
G1 X136.345 Y101.685
G1 X136.211 Y101.818
G1 X135.091 Y102.938 E.04966
G1 X134.957 Y103.072
G1 X134.74 Y102.756
G1 X134.874 Y102.623
G1 X136.082 Y101.414 E.05359
G1 X136.216 Y101.281
G1 X136.208 Y100.755
G1 X136.074 Y100.889
G1 X134.696 Y102.267 E.06111
G1 X134.562 Y102.401
G1 X134.438 Y101.992
G1 X134.572 Y101.858
G1 X136.074 Y100.356 E.06662
G1 X136.208 Y100.222
G1 X136.208 Y99.689
G1 X136.074 Y99.822
G1 X134.515 Y101.382 E.06914
G1 X134.381 Y101.515
G1 X134.374 Y100.989
G1 X134.508 Y100.855
G1 X136.074 Y99.289 E.06944
G1 X136.208 Y99.155
G1 X136.208 Y98.622
G1 X136.074 Y98.756
G1 X134.508 Y100.322 E.06944
G1 X134.374 Y100.456
G1 X134.374 Y99.922
G1 X134.508 Y99.789
G1 X136.074 Y98.223 E.06944
G1 X136.208 Y98.089
G1 X136.208 Y97.556
G1 X136.074 Y97.689
G1 X134.508 Y99.255 E.06944
G1 X134.374 Y99.389
G1 X134.374 Y98.856
G1 X134.508 Y98.722
G1 X136.074 Y97.156 E.06944
G1 X136.208 Y97.022
G1 X136.208 Y96.489
G1 X136.074 Y96.623
G1 X134.508 Y98.189 E.06944
G1 X134.374 Y98.323
G1 X134.374 Y97.789
G1 X134.508 Y97.656
G1 X136.074 Y96.09 E.06944
G1 X136.208 Y95.956
G1 X136.208 Y95.423
G1 X136.074 Y95.556
G1 X134.508 Y97.122 E.06944
G1 X134.374 Y97.256
G1 X134.374 Y96.723
G1 X134.508 Y96.589
G1 X136.074 Y95.023 E.06944
G1 X136.208 Y94.889
G1 X136.208 Y94.356
G1 X136.074 Y94.49
G1 X134.508 Y96.056 E.06944
G1 X134.374 Y96.189
G1 X134.374 Y95.656
G1 X134.508 Y95.523
G1 X136.188 Y93.843 E.07449
; WIPE_START
M204 S3000
G1 X134.774 Y95.257 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X134.508 Y94.989 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X137.771 Y91.727 E.14468
G1 X137.904 Y91.593
G1 X137.371 Y91.593
G1 X137.238 Y91.727
G1 X134.508 Y94.456 E.12103
G1 X134.374 Y94.59
G1 X134.413 Y94.018
G1 X134.546 Y93.884
G1 X136.666 Y91.765 E.09398
; WIPE_START
M204 S3000
G1 X135.252 Y93.179 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X141.725 Y97.223 Z1.6 F36000
G1 X149.544 Y102.109 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.112764
G1 F8590.591
M204 S3000
G1 X149.47 Y102.22 E.00078
; LINE_WIDTH: 0.161946
G1 F5040.947
G1 X149.396 Y102.331 E.00132
; LINE_WIDTH: 0.211127
G1 F3567.041
G1 X149.322 Y102.442 E.00187
; LINE_WIDTH: 0.258743
G1 F2780.067
G1 X149.2 Y102.596 E.00352
; LINE_WIDTH: 0.304815
G1 F2290.997
G1 X149.079 Y102.75 E.00427
; LINE_WIDTH: 0.346542
G1 F1976.144
G3 X148.632 Y103.209 I-3.726 J-3.179 E.01619
; LINE_WIDTH: 0.324973
G1 F2127.265
G1 X148.436 Y103.377 E.00606
; LINE_WIDTH: 0.287594
G1 F2452.242
G1 X148.332 Y103.457 E.00267
; LINE_WIDTH: 0.253352
G1 F2851.276
G1 X148.228 Y103.537 E.0023
; LINE_WIDTH: 0.211688
G1 F3555.182
G1 X148.063 Y103.65 E.0028
; LINE_WIDTH: 0.1626
G1 F5013.404
G1 X147.899 Y103.763 E.00199
; WIPE_START
G1 X148.063 Y103.65 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X142.673 Y98.246 Z1.6 F36000
G1 X136.281 Y91.838 Z1.6
G1 Z1.2
G1 E.4 F1800
; LINE_WIDTH: 0.211578
G1 F3557.504
M204 S3000
G1 X136.064 Y91.995 E.00376
; LINE_WIDTH: 0.253178
G1 F2853.644
G1 X135.848 Y92.153 E.00468
; LINE_WIDTH: 0.287329
G1 F2454.904
G1 X135.748 Y92.233 E.0026
; LINE_WIDTH: 0.31406
G1 F2212.88
G1 X135.649 Y92.314 E.00288
; LINE_WIDTH: 0.342788
G1 F2000.885
G2 X135.102 Y92.861 I3.199 J3.748 E.01931
; LINE_WIDTH: 0.304737
G1 F2291.678
G1 X134.981 Y93.014 E.00426
; LINE_WIDTH: 0.258763
G1 F2779.798
G1 X134.86 Y93.168 E.00351
; LINE_WIDTH: 0.211186
G1 F3565.795
G1 X134.785 Y93.279 E.00187
; LINE_WIDTH: 0.161981
G1 F5039.47
G1 X134.711 Y93.39 E.00132
; LINE_WIDTH: 0.112775
G1 F8589.241
G1 X134.637 Y93.501 E.00078
; OBJECT_ID: 8
; WIPE_START
G1 X134.711 Y93.39 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 9
M625
; start printing object, unique label id: 8
M624 AgAAAAAAAAA=
M204 S10000
G1 X127.583 Y96.118 Z1.6 F36000
G1 X100.322 Y106.551 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X100.375 Y106.676 E.00425
G2 X101.082 Y107.115 I.727 J-.383 E.02737
G1 X121.099 Y107.115 E.62761
G2 X121.901 Y106.314 I-.026 J-.827 E.03916
G1 X121.901 Y94.297 E.37677
G2 X121.099 Y93.495 I-.826 J.025 E.03917
G1 X101.085 Y93.495 E.62753
G2 X100.281 Y94.3 I.016 J.82 E.03941
G1 X100.281 Y106.314 E.37669
G2 X100.305 Y106.494 I.821 J-.02 E.00572
; WIPE_START
M204 S3000
G1 X100.375 Y106.676 E-.03709
G1 X100.432 Y106.777 E-.02197
G1 X100.55 Y106.909 E-.03374
G1 X100.759 Y107.045 E-.04722
G1 X100.964 Y107.106 E-.04073
G1 X101.082 Y107.115 E-.02253
G1 X102.012 Y107.115 E-.17673
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X108.134 Y102.557 Z1.6 F36000
G1 X122.47 Y91.881 Z1.6
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X122.237 Y91.763 E.00821
G2 X121.224 Y91.519 I-1.148 J2.545 E.03286
G1 X101.093 Y91.515 E.63118
G2 X98.301 Y94.308 I.008 J2.801 E.13744
G1 X98.301 Y106.303 E.37608
G2 X101.093 Y109.095 I2.799 J-.007 E.13745
G1 X121.088 Y109.095 E.62692
G2 X123.881 Y106.303 I-.007 J-2.799 E.13745
G1 X123.881 Y94.308 E.37608
G2 X122.522 Y91.912 I-2.792 J0 E.09033
; WIPE_START
M204 S3000
G1 X122.237 Y91.763 E-.06114
G1 X121.813 Y91.61 E-.08561
G1 X121.527 Y91.55 E-.05548
G1 X121.224 Y91.519 E-.05789
G1 X120.593 Y91.519 E-.11988
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X120.978 Y99.141 Z1.6 F36000
G1 X121.469 Y108.857 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X123.644 Y106.683 E.09643
G1 X123.777 Y106.549
G1 X123.803 Y105.99
G1 X123.669 Y106.124
G1 X120.905 Y108.888 E.12257
G1 X120.772 Y109.022
G1 X120.238 Y109.022
G1 X120.372 Y108.888
G1 X123.67 Y105.59 E.14622
G1 X123.803 Y105.457
G1 X123.803 Y104.923
G1 X123.67 Y105.057
G1 X122.018 Y106.709 E.07324
G1 X121.884 Y106.842
G1 X121.974 Y106.219
G1 X122.108 Y106.085
G1 X123.67 Y104.523 E.06926
G1 X123.804 Y104.39
G1 X123.804 Y103.856
G1 X123.67 Y103.99
G1 X122.108 Y105.552 E.06927
G1 X121.974 Y105.686
G1 X121.974 Y105.153
G1 X122.108 Y105.019
G1 X123.67 Y103.457 E.06928
G1 X123.804 Y103.323
G1 X123.804 Y102.79
G1 X123.67 Y102.923
G1 X122.108 Y104.486 E.06928
G1 X121.974 Y104.619
G1 X121.974 Y104.086
G1 X122.108 Y103.952
G1 X123.671 Y102.39 E.06929
G1 X123.804 Y102.256
G1 X123.804 Y101.723
G1 X123.671 Y101.856
G1 X122.108 Y103.419 E.0693
G1 X121.974 Y103.553
G1 X121.974 Y103.02
G1 X122.108 Y102.886
G1 X123.671 Y101.323 E.06931
G1 X123.805 Y101.189
G1 X123.805 Y100.656
G1 X123.671 Y100.789
G1 X122.108 Y102.353 E.06931
G1 X121.974 Y102.486
G1 X121.974 Y101.953
G1 X122.108 Y101.819
G1 X123.671 Y100.256 E.06932
G1 X123.805 Y100.122
G1 X123.805 Y99.589
G1 X123.672 Y99.723
G1 X122.108 Y101.286 E.06933
G1 X121.974 Y101.42
G1 X121.974 Y100.887
G1 X122.108 Y100.753
G1 X123.672 Y99.189 E.06934
G1 X123.805 Y99.056
G1 X123.805 Y98.522
G1 X123.672 Y98.656
G1 X122.108 Y100.22 E.06934
G1 X121.974 Y100.353
G1 X121.974 Y99.82
G1 X122.108 Y99.686
G1 X123.672 Y98.122 E.06935
G1 X123.806 Y97.989
G1 X123.806 Y97.455
G1 X123.672 Y97.589
G1 X122.108 Y99.153 E.06936
G1 X121.974 Y99.287
G1 X121.974 Y98.753
G1 X122.108 Y98.62
G1 X123.672 Y97.055 E.06937
G1 X123.806 Y96.922
G1 X123.806 Y96.388
G1 X123.673 Y96.522
G1 X122.108 Y98.087 E.06937
G1 X121.974 Y98.22
G1 X121.974 Y97.687
G1 X122.108 Y97.553
G1 X123.673 Y95.989 E.06938
G1 X123.806 Y95.855
G1 X123.807 Y95.322
G1 X123.673 Y95.455
G1 X122.108 Y97.02 E.06939
G1 X121.974 Y97.154
G1 X121.974 Y96.62
G1 X122.108 Y96.487
G1 X123.673 Y94.922 E.0694
G1 X123.807 Y94.788
G1 X123.807 Y94.255
G1 X123.673 Y94.388
G1 X122.108 Y95.954 E.06941
G1 X121.974 Y96.087
G1 X121.974 Y95.554
G1 X122.108 Y95.42
G1 X123.636 Y93.892 E.06776
G1 X123.77 Y93.759
G1 X123.663 Y93.332
G1 X123.529 Y93.466
G1 X122.108 Y94.887 E.06301
G1 X121.974 Y95.021
G1 X121.974 Y94.487
G1 X122.108 Y94.354
G1 X123.367 Y93.095 E.05584
G1 X123.501 Y92.961
G1 X123.296 Y92.632
G1 X123.163 Y92.766
G1 X122.02 Y93.908 E.05065
G1 X121.887 Y94.042
G1 X121.674 Y93.721
G1 X121.807 Y93.588
G1 X122.914 Y92.482 E.04905
G1 X123.047 Y92.348
G1 X122.763 Y92.099
G1 X122.629 Y92.233
G1 X121.485 Y93.377 E.05074
G1 X121.351 Y93.511
G1 X120.907 Y93.422
G1 X121.041 Y93.288
G1 X122.299 Y92.03 E.05578
G1 X122.433 Y91.896
G1 X122.061 Y91.735
G1 X121.927 Y91.869
G1 X120.508 Y93.288 E.06294
G1 X120.374 Y93.422
G1 X119.841 Y93.422
G1 X119.974 Y93.288
G1 X121.499 Y91.763 E.0676
G1 X121.633 Y91.63
G1 X121.136 Y91.593
G1 X121.003 Y91.726
G1 X119.441 Y93.288 E.06925
G1 X119.307 Y93.422
G1 X118.774 Y93.422
G1 X118.908 Y93.288
G1 X120.47 Y91.726 E.06925
G1 X120.603 Y91.592
G1 X120.07 Y91.592
G1 X119.936 Y91.726
G1 X118.375 Y93.288 E.06926
G1 X118.241 Y93.422
G1 X117.708 Y93.422
G1 X117.841 Y93.288
G1 X119.403 Y91.726 E.06926
G1 X119.537 Y91.592
G1 X119.004 Y91.592
G1 X118.87 Y91.726
G1 X117.308 Y93.288 E.06927
G1 X117.174 Y93.422
G1 X116.641 Y93.422
G1 X116.775 Y93.288
G1 X118.337 Y91.726 E.06927
G1 X118.471 Y91.592
G1 X117.937 Y91.592
G1 X117.804 Y91.726
G1 X116.242 Y93.288 E.06927
G1 X116.108 Y93.422
G1 X115.575 Y93.422
G1 X115.708 Y93.288
G1 X117.271 Y91.726 E.06928
G1 X117.404 Y91.592
G1 X116.871 Y91.592
G1 X116.737 Y91.725
G1 X115.175 Y93.288 E.06928
G1 X115.041 Y93.422
G1 X114.508 Y93.422
G1 X114.642 Y93.288
G1 X116.204 Y91.725 E.06929
G1 X116.338 Y91.592
G1 X115.805 Y91.592
G1 X115.671 Y91.725
G1 X114.108 Y93.288 E.06929
G1 X113.975 Y93.422
G1 X113.442 Y93.422
G1 X113.575 Y93.288
G1 X115.138 Y91.725 E.0693
G1 X115.272 Y91.592
G1 X114.738 Y91.591
G1 X114.605 Y91.725
G1 X113.042 Y93.288 E.0693
G1 X112.908 Y93.422
G1 X112.375 Y93.422
G1 X112.509 Y93.288
G1 X114.072 Y91.725 E.0693
G1 X114.205 Y91.591
G1 X113.672 Y91.591
G1 X113.538 Y91.725
G1 X111.975 Y93.288 E.06931
G1 X111.842 Y93.422
G1 X111.309 Y93.422
G1 X111.442 Y93.288
G1 X113.005 Y91.725 E.06931
G1 X113.139 Y91.591
G1 X112.606 Y91.591
G1 X112.472 Y91.725
G1 X110.909 Y93.288 E.06932
G1 X110.775 Y93.422
G1 X110.242 Y93.422
G1 X110.376 Y93.288
G1 X111.939 Y91.725 E.06932
G1 X112.073 Y91.591
G1 X111.539 Y91.591
G1 X111.406 Y91.724
G1 X109.842 Y93.288 E.06932
G1 X109.709 Y93.422
G1 X109.176 Y93.422
G1 X109.309 Y93.288
G1 X110.873 Y91.724 E.06933
G1 X111.006 Y91.591
G1 X110.473 Y91.591
G1 X110.34 Y91.724
G1 X108.776 Y93.288 E.06933
G1 X108.642 Y93.422
G1 X108.109 Y93.422
G1 X108.243 Y93.288
G1 X109.806 Y91.724 E.06934
G1 X109.94 Y91.591
G1 X109.407 Y91.59
G1 X109.273 Y91.724
G1 X107.709 Y93.288 E.06934
G1 X107.576 Y93.422
G1 X107.042 Y93.422
G1 X107.176 Y93.288
G1 X108.74 Y91.724 E.06935
G1 X108.874 Y91.59
G1 X108.341 Y91.59
G1 X108.207 Y91.724
G1 X106.643 Y93.288 E.06935
G1 X106.509 Y93.422
G1 X105.976 Y93.422
G1 X106.11 Y93.288
G1 X107.674 Y91.724 E.06935
G1 X107.807 Y91.59
G1 X107.274 Y91.59
G1 X107.141 Y91.724
G1 X105.576 Y93.288 E.06936
G1 X105.443 Y93.422
G1 X104.909 Y93.422
G1 X105.043 Y93.288
G1 X106.607 Y91.724 E.06936
G1 X106.741 Y91.59
G1 X106.208 Y91.59
G1 X106.074 Y91.724
G1 X104.51 Y93.288 E.06937
G1 X104.376 Y93.422
G1 X103.843 Y93.422
G1 X103.977 Y93.288
G1 X105.541 Y91.723 E.06937
G1 X105.675 Y91.59
G1 X105.142 Y91.59
G1 X105.008 Y91.723
G1 X103.443 Y93.288 E.06938
G1 X103.31 Y93.422
G1 X102.776 Y93.422
G1 X102.91 Y93.288
G1 X104.475 Y91.723 E.06938
G1 X104.608 Y91.59
G1 X104.075 Y91.59
G1 X103.942 Y91.723
G1 X102.377 Y93.288 E.06938
G1 X102.243 Y93.422
G1 X101.71 Y93.422
G1 X101.844 Y93.288
G1 X103.408 Y91.723 E.06939
G1 X103.542 Y91.589
G1 X103.009 Y91.589
G1 X102.875 Y91.723
G1 X101.31 Y93.288 E.06939
G1 X101.177 Y93.422
G1 X100.563 Y93.502
G1 X100.697 Y93.368
G1 X102.342 Y91.723 E.07295
; WIPE_START
M204 S3000
G1 X100.928 Y93.137 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X106.793 Y98.022 Z1.6 F36000
G1 X119.839 Y108.888 Z1.6
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X121.49 Y107.237 E.0732
G1 X121.623 Y107.103
G1 X121.004 Y107.189
G1 X120.871 Y107.323
G1 X119.306 Y108.888 E.06941
G1 X119.172 Y109.022
G1 X118.639 Y109.022
G1 X118.772 Y108.888
G1 X120.337 Y107.323 E.0694
G1 X120.471 Y107.189
G1 X119.938 Y107.189
G1 X119.804 Y107.323
G1 X118.239 Y108.888 E.06941
G1 X118.105 Y109.022
G1 X117.572 Y109.022
G1 X117.706 Y108.888
G1 X119.271 Y107.323 E.06941
G1 X119.405 Y107.189
G1 X118.871 Y107.189
G1 X118.738 Y107.323
G1 X117.172 Y108.888 E.06941
G1 X117.039 Y109.022
G1 X116.506 Y109.022
G1 X116.639 Y108.888
G1 X118.204 Y107.323 E.0694
G1 X118.338 Y107.189
G1 X117.805 Y107.189
G1 X117.671 Y107.323
G1 X116.106 Y108.888 E.06941
G1 X115.972 Y109.022
G1 X115.439 Y109.022
G1 X115.573 Y108.888
G1 X117.138 Y107.323 E.06941
G1 X117.272 Y107.189
G1 X116.738 Y107.189
G1 X116.605 Y107.323
G1 X115.039 Y108.888 E.06941
G1 X114.906 Y109.022
G1 X114.373 Y109.022
G1 X114.506 Y108.888
G1 X116.071 Y107.323 E.06941
G1 X116.205 Y107.189
G1 X115.672 Y107.189
G1 X115.538 Y107.323
G1 X113.973 Y108.888 E.06941
G1 X113.839 Y109.022
G1 X113.306 Y109.022
G1 X113.44 Y108.888
G1 X115.005 Y107.323 E.06941
G1 X115.139 Y107.189
G1 X114.605 Y107.189
G1 X114.472 Y107.323
G1 X112.906 Y108.888 E.06941
G1 X112.773 Y109.022
G1 X112.24 Y109.022
G1 X112.373 Y108.888
G1 X113.938 Y107.323 E.06941
G1 X114.072 Y107.189
G1 X113.539 Y107.189
G1 X113.405 Y107.323
G1 X111.84 Y108.888 E.06941
G1 X111.706 Y109.022
G1 X111.173 Y109.022
G1 X111.307 Y108.888
G1 X112.872 Y107.323 E.06941
G1 X113.006 Y107.189
G1 X112.472 Y107.189
G1 X112.339 Y107.323
G1 X110.773 Y108.888 E.06941
G1 X110.64 Y109.022
G1 X110.106 Y109.022
G1 X110.24 Y108.888
G1 X111.805 Y107.323 E.06941
G1 X111.939 Y107.189
G1 X111.406 Y107.189
G1 X111.272 Y107.323
G1 X109.707 Y108.888 E.06941
G1 X109.573 Y109.022
G1 X109.04 Y109.022
G1 X109.174 Y108.888
G1 X110.739 Y107.323 E.06941
G1 X110.873 Y107.189
G1 X110.339 Y107.189
G1 X110.206 Y107.323
G1 X108.64 Y108.888 E.06941
G1 X108.507 Y109.022
G1 X107.973 Y109.022
G1 X108.107 Y108.888
G1 X109.672 Y107.323 E.06941
G1 X109.806 Y107.189
G1 X109.273 Y107.189
G1 X109.139 Y107.323
G1 X107.574 Y108.888 E.06941
G1 X107.44 Y109.022
G1 X106.907 Y109.022
G1 X107.041 Y108.888
G1 X108.606 Y107.323 E.06941
G1 X108.739 Y107.189
G1 X108.206 Y107.189
G1 X108.073 Y107.323
G1 X106.507 Y108.888 E.06941
G1 X106.374 Y109.022
G1 X105.84 Y109.022
G1 X105.974 Y108.888
G1 X107.539 Y107.323 E.06941
G1 X107.673 Y107.189
G1 X107.14 Y107.189
G1 X107.006 Y107.323
G1 X105.441 Y108.888 E.06941
G1 X105.307 Y109.022
G1 X104.774 Y109.022
G1 X104.908 Y108.888
G1 X106.473 Y107.323 E.06941
G1 X106.606 Y107.189
G1 X106.073 Y107.189
G1 X105.94 Y107.323
G1 X104.374 Y108.888 E.06941
G1 X104.241 Y109.022
G1 X103.707 Y109.022
G1 X103.841 Y108.888
G1 X105.406 Y107.323 E.06941
G1 X105.54 Y107.189
G1 X105.007 Y107.189
G1 X104.873 Y107.323
G1 X103.308 Y108.888 E.06941
G1 X103.174 Y109.022
G1 X102.641 Y109.022
G1 X102.775 Y108.888
G1 X104.34 Y107.323 E.06941
G1 X104.473 Y107.189
G1 X103.94 Y107.189
G1 X103.807 Y107.323
G1 X102.241 Y108.888 E.06941
G1 X102.108 Y109.022
G1 X101.574 Y109.022
G1 X101.708 Y108.888
G1 X103.273 Y107.323 E.06941
G1 X103.407 Y107.189
G1 X102.874 Y107.189
G1 X102.74 Y107.323
G1 X101.175 Y108.888 E.06941
M73 P41 R28
G1 X101.041 Y109.022
G1 X100.545 Y108.985
G1 X100.679 Y108.851
G1 X102.207 Y107.323 E.06776
G1 X102.34 Y107.189
G1 X101.807 Y107.189
G1 X101.673 Y107.323
G1 X100.252 Y108.744 E.06302
G1 X100.119 Y108.878
G1 X99.746 Y108.717
G1 X99.879 Y108.584
G1 X101.14 Y107.323 E.05591
G1 X101.274 Y107.189
G1 X100.828 Y107.102
G1 X100.694 Y107.236
G1 X99.554 Y108.376 E.05055
G1 X99.42 Y108.509
G1 X99.136 Y108.26
G1 X99.27 Y108.126
G1 X100.374 Y107.022 E.04895
G1 X100.508 Y106.889
G1 X100.292 Y106.571
G1 X100.159 Y106.704
G1 X99.019 Y107.844 E.05056
G1 X98.885 Y107.978
G1 X98.68 Y107.65
G1 X98.814 Y107.516
G1 X100.073 Y106.257 E.05585
G1 X100.207 Y106.123
G1 X100.207 Y105.59
G1 X100.073 Y105.723
G1 X98.652 Y107.144 E.06301
G1 X98.519 Y107.278
G1 X98.409 Y106.854
G1 X98.543 Y106.721
G1 X100.073 Y105.19 E.06787
G1 X100.207 Y105.056
G1 X100.207 Y104.523
G1 X100.073 Y104.657
G1 X98.512 Y106.218 E.06923
G1 X98.378 Y106.352
G1 X98.378 Y105.819
G1 X98.512 Y105.685
G1 X100.073 Y104.124 E.06923
G1 X100.207 Y103.99
G1 X100.207 Y103.457
G1 X100.073 Y103.59
G1 X98.512 Y105.152 E.06923
G1 X98.378 Y105.285
G1 X98.378 Y104.752
G1 X98.512 Y104.618
G1 X100.073 Y103.057 E.06923
G1 X100.207 Y102.923
G1 X100.207 Y102.39
G1 X100.073 Y102.524
G1 X98.512 Y104.085 E.06923
G1 X98.378 Y104.219
G1 X98.378 Y103.686
G1 X98.512 Y103.552
G1 X100.073 Y101.991 E.06923
G1 X100.207 Y101.857
G1 X100.207 Y101.324
G1 X100.073 Y101.457
G1 X98.512 Y103.019 E.06923
G1 X98.378 Y103.152
G1 X98.378 Y102.619
G1 X98.512 Y102.485
G1 X100.073 Y100.924 E.06923
G1 X100.207 Y100.79
G1 X100.207 Y100.257
G1 X100.073 Y100.391
G1 X98.512 Y101.952 E.06923
G1 X98.378 Y102.086
G1 X98.378 Y101.553
G1 X98.512 Y101.419
G1 X100.073 Y99.858 E.06923
G1 X100.207 Y99.724
G1 X100.207 Y99.191
G1 X100.073 Y99.324
G1 X98.512 Y100.886 E.06923
G1 X98.378 Y101.019
G1 X98.378 Y100.486
G1 X98.512 Y100.352
G1 X100.073 Y98.791 E.06923
G1 X100.207 Y98.657
G1 X100.207 Y98.124
G1 X100.073 Y98.258
G1 X98.512 Y99.819 E.06923
G1 X98.378 Y99.953
G1 X98.378 Y99.42
G1 X98.512 Y99.286
G1 X100.073 Y97.725 E.06923
G1 X100.207 Y97.591
G1 X100.207 Y97.058
G1 X100.073 Y97.191
G1 X98.512 Y98.753 E.06923
G1 X98.378 Y98.886
G1 X98.378 Y98.353
G1 X98.512 Y98.219
G1 X100.073 Y96.658 E.06923
G1 X100.207 Y96.524
G1 X100.207 Y95.991
G1 X100.073 Y96.125
G1 X98.512 Y97.686 E.06923
G1 X98.378 Y97.82
G1 X98.378 Y97.287
G1 X98.512 Y97.153
G1 X100.073 Y95.592 E.06923
G1 X100.207 Y95.458
G1 X100.207 Y94.925
G1 X100.073 Y95.058
G1 X98.512 Y96.62 E.06923
G1 X98.378 Y96.753
G1 X98.378 Y96.22
G1 X98.512 Y96.086
G1 X100.073 Y94.525 E.06923
G1 X100.207 Y94.391
G1 X100.287 Y93.778
G1 X100.153 Y93.912
G1 X98.512 Y95.553 E.07277
G1 X98.378 Y95.687
G1 X98.378 Y95.153
G1 X98.512 Y95.02
G1 X101.809 Y91.723 E.1462
G1 X101.943 Y91.589
G1 X101.409 Y91.589
G1 X101.276 Y91.723
G1 X98.512 Y94.487 E.12256
G1 X98.378 Y94.62
G1 X98.404 Y94.061
G1 X98.537 Y93.928
G1 X100.712 Y91.753 E.09643
M204 S10000
G1 X100.339 Y91.836 F36000
; FEATURE: Gap infill
; LINE_WIDTH: 0.0952769
G1 F11459.898
M204 S3000
G1 X100.296 Y91.86 E.00021
; LINE_WIDTH: 0.122154
G1 F7572.583
G1 X100.212 Y91.916 E.00067
; LINE_WIDTH: 0.161713
G1 F5050.824
G1 X100.128 Y91.973 E.001
; LINE_WIDTH: 0.201272
G1 F3789.031
G1 X100.043 Y92.029 E.00134
; LINE_WIDTH: 0.240832
G1 F3031.663
G1 X99.959 Y92.085 E.00167
; LINE_WIDTH: 0.283784
G1 F2491.038
G1 X99.804 Y92.207 E.00395
; LINE_WIDTH: 0.330103
G1 F2089.266
G1 X99.65 Y92.329 E.00471
; LINE_WIDTH: 0.372866
G1 F1818.484
G2 X99.278 Y92.683 I3.085 J3.613 E.01408
; LINE_WIDTH: 0.366001
G1 F1857.119
G1 X99.152 Y92.826 E.00512
; LINE_WIDTH: 0.340752
G1 F2014.563
G1 X99.027 Y92.97 E.00472
; LINE_WIDTH: 0.311372
G1 F2235.036
G1 X98.949 Y93.072 E.00287
; LINE_WIDTH: 0.277839
G1 F2554.071
G1 X98.87 Y93.174 E.00251
; LINE_WIDTH: 0.236627
G1 F3097.465
G1 X98.742 Y93.36 E.00364
; LINE_WIDTH: 0.187756
G1 F4142.628
G1 X98.614 Y93.546 E.00272
; WIPE_START
G1 X98.742 Y93.36 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X102.582 Y91.704 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; LINE_WIDTH: 0.106636
G1 F9416.911
M204 S3000
G1 X102.453 Y91.834 E.00097
; WIPE_START
G1 X102.582 Y91.704 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X108.738 Y96.216 Z1.6 F36000
G1 X123.566 Y107.083 Z1.6
G1 Z1.2
G1 E.4 F1800
; LINE_WIDTH: 0.237592
G1 F3082.12
M204 S3000
G1 X123.399 Y107.312 E.00459
; LINE_WIDTH: 0.278395
G1 F2548.041
G1 X123.232 Y107.542 E.00556
; LINE_WIDTH: 0.31232
G1 F2227.174
G1 X123.151 Y107.642 E.0029
; LINE_WIDTH: 0.339359
G1 F2024.028
G1 X123.069 Y107.743 E.00319
; LINE_WIDTH: 0.370818
G1 F1829.84
G3 X122.532 Y108.281 I-4.127 J-3.587 E.02076
; LINE_WIDTH: 0.330187
G1 F2088.654
G1 X122.219 Y108.527 E.0095
; LINE_WIDTH: 0.283838
G1 F2490.474
G1 X121.907 Y108.773 E.00797
; OBJECT_ID: 7
; WIPE_START
G1 X122.219 Y108.527 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 8
M625
; start printing object, unique label id: 7
M624 AQAAAAAAAAA=
M204 S10000
G1 X116.37 Y113.431 Z1.6 F36000
G1 X85.054 Y139.684 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X85.169 Y139.542 E.00573
G2 X85.901 Y137.308 I-3.091 J-2.249 E.07491
G1 X85.901 Y97.302 E1.25435
G2 X82.093 Y93.495 I-3.823 J.015 E.1873
G1 X26.088 Y93.495 E1.75602
G2 X22.281 Y97.302 I.015 J3.822 E.1873
G1 X22.281 Y137.308 E1.25435
G2 X26.088 Y141.115 I3.823 J-.015 E.1873
G1 X82.093 Y141.115 E1.75602
G2 X84.781 Y139.996 I-.015 J-3.823 E.09365
G1 X85.015 Y139.729 E.01112
; WIPE_START
M204 S3000
G1 X85.169 Y139.542 E-.0461
G1 X85.39 Y139.21 E-.07572
G1 X85.571 Y138.854 E-.07589
G1 X85.714 Y138.483 E-.0757
G1 X85.817 Y138.097 E-.07576
G1 X85.843 Y137.937 E-.03084
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X78.238 Y138.59 Z1.6 F36000
G1 X25.839 Y143.089 Z1.6
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X26.093 Y143.095 E.00799
G1 X82.088 Y143.095 E1.75567
G2 X87.881 Y137.303 I-.017 J-5.809 E.28507
G1 X87.881 Y97.308 E1.254
G2 X82.368 Y91.523 I-5.794 J.002 E.27648
G1 X26.093 Y91.515 E1.76445
G2 X20.301 Y97.308 I.017 J5.809 E.28507
G1 X20.301 Y137.303 E1.254
G2 X25.779 Y143.086 I5.809 J-.017 E.27521
; WIPE_START
M204 S3000
G1 X26.093 Y143.095 E-.0598
G1 X27.779 Y143.095 E-.32021
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X35.411 Y143.017 Z1.6 F36000
G1 X84.072 Y142.516 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X87.312 Y139.276 E.14365
G1 X87.445 Y139.143
G1 X87.664 Y138.39
G1 X87.531 Y138.524
G1 X83.309 Y142.745 E.18718
G1 X83.176 Y142.879
G1 X82.538 Y142.983
G1 X82.672 Y142.85
G1 X87.635 Y137.887 E.22006
G1 X87.768 Y137.753
G1 X87.799 Y137.189
G1 X87.665 Y137.323
G1 X85.343 Y139.645 E.10298
G1 X85.209 Y139.779
G1 X85.772 Y138.683
G1 X85.905 Y138.55
G1 X87.665 Y136.79 E.07804
G1 X87.799 Y136.656
G1 X87.799 Y136.123
G1 X87.665 Y136.256
G1 X86.065 Y137.856 E.07094
G1 X85.932 Y137.99
G1 X85.974 Y137.414
G1 X86.108 Y137.28
G1 X87.665 Y135.723 E.06905
G1 X87.799 Y135.59
G1 X87.799 Y135.056
G1 X87.665 Y135.19
G1 X86.108 Y136.747 E.06905
G1 X85.974 Y136.881
G1 X85.974 Y136.348
G1 X86.108 Y136.214
G1 X87.665 Y134.657 E.06905
G1 X87.799 Y134.523
G1 X87.799 Y133.99
G1 X87.665 Y134.123
G1 X86.108 Y135.681 E.06905
G1 X85.974 Y135.814
G1 X85.974 Y135.281
G1 X86.108 Y135.147
G1 X87.665 Y133.59 E.06905
G1 X87.799 Y133.457
G1 X87.799 Y132.923
G1 X87.665 Y133.057
G1 X86.108 Y134.614 E.06905
G1 X85.974 Y134.748
G1 X85.974 Y134.215
G1 X86.108 Y134.081
G1 X87.665 Y132.524 E.06905
G1 X87.799 Y132.39
G1 X87.799 Y131.857
G1 X87.665 Y131.99
G1 X86.108 Y133.548 E.06905
G1 X85.974 Y133.681
G1 X85.974 Y133.148
G1 X86.108 Y133.014
G1 X87.665 Y131.457 E.06905
G1 X87.799 Y131.323
G1 X87.799 Y130.79
G1 X87.665 Y130.924
G1 X86.108 Y132.481 E.06905
G1 X85.974 Y132.615
G1 X85.974 Y132.082
G1 X86.108 Y131.948
G1 X87.665 Y130.391 E.06905
G1 X87.799 Y130.257
G1 X87.799 Y129.724
G1 X87.665 Y129.857
G1 X86.108 Y131.415 E.06905
G1 X85.974 Y131.548
G1 X85.974 Y131.015
G1 X86.108 Y130.881
G1 X87.665 Y129.324 E.06905
G1 X87.799 Y129.19
G1 X87.799 Y128.657
G1 X87.665 Y128.791
G1 X86.108 Y130.348 E.06905
G1 X85.974 Y130.482
G1 X85.974 Y129.948
G1 X86.108 Y129.815
G1 X87.665 Y128.258 E.06905
G1 X87.799 Y128.124
G1 X87.799 Y127.591
G1 X87.665 Y127.724
G1 X86.108 Y129.282 E.06905
G1 X85.974 Y129.415
G1 X85.974 Y128.882
G1 X86.108 Y128.748
G1 X87.665 Y127.191 E.06905
G1 X87.799 Y127.057
G1 X87.799 Y126.524
G1 X87.665 Y126.658
G1 X86.108 Y128.215 E.06905
G1 X85.974 Y128.349
G1 X85.974 Y127.815
G1 X86.108 Y127.682
G1 X87.665 Y126.125 E.06905
G1 X87.799 Y125.991
G1 X87.799 Y125.458
G1 X87.665 Y125.591
G1 X86.108 Y127.149 E.06905
G1 X85.974 Y127.282
G1 X85.974 Y126.749
G1 X86.108 Y126.615
G1 X87.665 Y125.058 E.06905
G1 X87.799 Y124.924
G1 X87.799 Y124.391
G1 X87.665 Y124.525
G1 X86.108 Y126.082 E.06905
G1 X85.974 Y126.216
G1 X85.974 Y125.682
G1 X86.108 Y125.549
G1 X87.665 Y123.992 E.06905
G1 X87.799 Y123.858
G1 X87.799 Y123.325
G1 X87.665 Y123.458
G1 X86.108 Y125.016 E.06905
G1 X85.974 Y125.149
G1 X85.974 Y124.616
G1 X86.108 Y124.482
G1 X87.665 Y122.925 E.06905
G1 X87.799 Y122.791
G1 X87.799 Y122.258
G1 X87.665 Y122.392
G1 X86.108 Y123.949 E.06905
G1 X85.974 Y124.083
G1 X85.974 Y123.549
G1 X86.108 Y123.416
G1 X87.665 Y121.858 E.06905
G1 X87.799 Y121.725
G1 X87.799 Y121.192
G1 X87.665 Y121.325
G1 X86.108 Y122.883 E.06905
G1 X85.974 Y123.016
G1 X85.974 Y122.483
G1 X86.108 Y122.349
G1 X87.665 Y120.792 E.06905
G1 X87.799 Y120.658
G1 X87.799 Y120.125
G1 X87.665 Y120.259
G1 X86.108 Y121.816 E.06905
G1 X85.974 Y121.95
M73 P42 R28
G1 X85.974 Y121.416
G1 X86.108 Y121.283
G1 X87.665 Y119.725 E.06905
G1 X87.799 Y119.592
G1 X87.799 Y119.059
G1 X87.665 Y119.192
G1 X86.108 Y120.749 E.06905
G1 X85.974 Y120.883
G1 X85.974 Y120.35
G1 X86.108 Y120.216
G1 X87.665 Y118.659 E.06905
G1 X87.799 Y118.525
G1 X87.799 Y117.992
G1 X87.665 Y118.126
G1 X86.108 Y119.683 E.06905
G1 X85.974 Y119.817
G1 X85.974 Y119.283
G1 X86.108 Y119.15
G1 X87.665 Y117.592 E.06905
G1 X87.799 Y117.459
G1 X87.799 Y116.926
G1 X87.665 Y117.059
G1 X86.108 Y118.616 E.06905
G1 X85.974 Y118.75
G1 X85.974 Y118.217
G1 X86.108 Y118.083
G1 X87.665 Y116.526 E.06905
G1 X87.799 Y116.392
G1 X87.799 Y115.859
G1 X87.665 Y115.993
G1 X86.108 Y117.55 E.06905
G1 X85.974 Y117.684
G1 X85.974 Y117.15
G1 X86.108 Y117.017
G1 X87.665 Y115.459 E.06905
G1 X87.799 Y115.326
G1 X87.799 Y114.793
G1 X87.665 Y114.926
G1 X86.108 Y116.483 E.06905
G1 X85.974 Y116.617
G1 X85.974 Y116.084
G1 X86.108 Y115.95
G1 X87.665 Y114.393 E.06905
G1 X87.799 Y114.259
G1 X87.799 Y113.726
G1 X87.665 Y113.86
G1 X86.108 Y115.417 E.06905
G1 X85.974 Y115.551
G1 X85.974 Y115.017
G1 X86.108 Y114.884
G1 X87.665 Y113.326 E.06905
G1 X87.799 Y113.193
G1 X87.799 Y112.659
G1 X87.665 Y112.793
G1 X86.108 Y114.35 E.06905
G1 X85.974 Y114.484
G1 X85.974 Y113.951
G1 X86.108 Y113.817
G1 X87.665 Y112.26 E.06905
G1 X87.799 Y112.126
G1 X87.799 Y111.593
G1 X87.665 Y111.727
G1 X86.108 Y113.284 E.06905
G1 X85.974 Y113.418
G1 X85.974 Y112.884
G1 X86.108 Y112.751
G1 X87.665 Y111.193 E.06905
G1 X87.799 Y111.06
G1 X87.799 Y110.526
G1 X87.665 Y110.66
G1 X86.108 Y112.217 E.06905
G1 X85.974 Y112.351
M73 P42 R27
G1 X85.974 Y111.818
G1 X86.108 Y111.684
G1 X87.665 Y110.127 E.06905
G1 X87.799 Y109.993
G1 X87.799 Y109.46
G1 X87.665 Y109.594
G1 X86.108 Y111.151 E.06905
G1 X85.974 Y111.284
G1 X85.974 Y110.751
G1 X86.108 Y110.618
G1 X87.665 Y109.06 E.06905
G1 X87.799 Y108.927
G1 X87.799 Y108.393
G1 X87.665 Y108.527
G1 X86.108 Y110.084 E.06905
G1 X85.974 Y110.218
G1 X85.974 Y109.685
G1 X86.108 Y109.551
G1 X87.665 Y107.994 E.06905
G1 X87.799 Y107.86
G1 X87.799 Y107.327
G1 X87.665 Y107.461
G1 X86.108 Y109.018 E.06905
G1 X85.974 Y109.151
G1 X85.974 Y108.618
G1 X86.108 Y108.485
G1 X87.665 Y106.927 E.06905
G1 X87.799 Y106.794
G1 X87.799 Y106.26
G1 X87.665 Y106.394
G1 X86.108 Y107.951 E.06905
G1 X85.974 Y108.085
G1 X85.974 Y107.552
G1 X86.108 Y107.418
G1 X87.665 Y105.861 E.06905
G1 X87.799 Y105.727
G1 X87.799 Y105.194
G1 X87.665 Y105.328
G1 X86.108 Y106.885 E.06905
G1 X85.974 Y107.018
G1 X85.974 Y106.485
G1 X86.108 Y106.352
G1 X87.665 Y104.794 E.06905
G1 X87.799 Y104.661
G1 X87.799 Y104.127
G1 X87.665 Y104.261
G1 X86.108 Y105.818 E.06905
G1 X85.974 Y105.952
G1 X85.974 Y105.419
G1 X86.108 Y105.285
G1 X87.665 Y103.728 E.06905
G1 X87.799 Y103.594
G1 X87.799 Y103.061
G1 X87.665 Y103.194
G1 X86.108 Y104.752 E.06905
G1 X85.974 Y104.885
G1 X85.974 Y104.352
G1 X86.108 Y104.218
G1 X87.665 Y102.661 E.06905
G1 X87.799 Y102.528
G1 X87.799 Y101.994
G1 X87.665 Y102.128
G1 X86.108 Y103.685 E.06905
G1 X85.974 Y103.819
G1 X85.974 Y103.286
G1 X86.108 Y103.152
G1 X87.665 Y101.595 E.06905
G1 X87.799 Y101.461
G1 X87.799 Y100.928
G1 X87.665 Y101.061
G1 X86.108 Y102.619 E.06905
G1 X85.974 Y102.752
G1 X85.974 Y102.219
G1 X86.108 Y102.085
G1 X87.665 Y100.528 E.06905
G1 X87.799 Y100.395
G1 X87.799 Y99.861
G1 X87.665 Y99.995
G1 X86.108 Y101.552 E.06905
G1 X85.974 Y101.686
G1 X85.974 Y101.153
G1 X86.108 Y101.019
G1 X87.665 Y99.462 E.06905
G1 X87.799 Y99.328
G1 X87.799 Y98.795
G1 X87.665 Y98.928
G1 X86.108 Y100.486 E.06905
G1 X85.974 Y100.619
G1 X85.974 Y100.086
G1 X86.108 Y99.952
G1 X87.665 Y98.395 E.06905
G1 X87.799 Y98.262
G1 X87.799 Y97.728
G1 X87.665 Y97.862
G1 X86.108 Y99.419 E.06905
G1 X85.974 Y99.553
G1 X85.974 Y99.02
G1 X86.108 Y98.886
G1 X87.665 Y97.329 E.06905
G1 X87.799 Y97.195
G1 X87.783 Y96.677
G1 X87.65 Y96.811
G1 X86.108 Y98.353 E.06836
G1 X85.974 Y98.486
G1 X85.974 Y97.953
G1 X86.108 Y97.819
G1 X87.583 Y96.345 E.06539
G1 X87.716 Y96.211
G1 X87.621 Y95.773
G1 X87.487 Y95.907
G1 X86.107 Y97.287 E.06118
G1 X85.974 Y97.42
G1 X85.935 Y96.926
G1 X86.068 Y96.793
G1 X87.367 Y95.494 E.05757
G1 X87.5 Y95.361
G1 X87.352 Y94.975
G1 X87.219 Y95.109
G1 X85.987 Y96.34 E.0546
G1 X85.854 Y96.474
G1 X85.729 Y96.065
G1 X85.863 Y95.931
G1 X87.045 Y94.749 E.05241
G1 X87.179 Y94.616
G1 X86.989 Y94.273
G1 X86.855 Y94.406
G1 X85.704 Y95.557 E.05103
G1 X85.57 Y95.691
G1 X85.382 Y95.346
G1 X85.515 Y95.213
G1 X86.645 Y94.083 E.05009
G1 X86.779 Y93.949
G1 X86.545 Y93.649
G1 X86.412 Y93.783
G1 X85.299 Y94.895 E.04933
G1 X85.165 Y95.029
G1 X84.924 Y94.738
G1 X85.057 Y94.604
G1 X86.167 Y93.494 E.04922
G1 X86.301 Y93.36
G1 X86.031 Y93.097
G1 X85.897 Y93.231
G1 X84.791 Y94.337 E.04905
G1 X84.657 Y94.471
G1 X84.363 Y94.232
G1 X84.497 Y94.098
G1 X85.616 Y92.978 E.04965
G1 X85.75 Y92.845
G1 X85.443 Y92.619
G1 X85.309 Y92.752
G1 X84.18 Y93.881 E.05004
G1 X84.047 Y94.015
G1 X83.697 Y93.831
G1 X83.831 Y93.697
G1 X84.99 Y92.538 E.05141
G1 X85.124 Y92.404
G1 X84.778 Y92.217
G1 X84.645 Y92.35
G1 X83.461 Y93.534 E.05247
G1 X83.328 Y93.667
G1 X82.916 Y93.545
G1 X83.05 Y93.412
G1 X84.285 Y92.177 E.05477
G1 X84.419 Y92.043
G1 X84.034 Y91.895
G1 X83.9 Y92.029
G1 X82.604 Y93.324 E.05746
G1 X82.47 Y93.458
G1 X81.973 Y93.422
G1 X82.107 Y93.288
G1 X83.487 Y91.908 E.0612
G1 X83.621 Y91.775
G1 X83.183 Y91.679
G1 X83.049 Y91.813
G1 X81.574 Y93.288 E.0654
G1 X81.44 Y93.422
G1 X80.907 Y93.422
G1 X81.041 Y93.288
G1 X82.582 Y91.747 E.06835
G1 X82.716 Y91.613
G1 X82.199 Y91.596
G1 X82.066 Y91.73
G1 X80.508 Y93.288 E.06908
G1 X80.374 Y93.422
G1 X79.841 Y93.422
G1 X79.974 Y93.288
G1 X81.532 Y91.73 E.06908
G1 X81.666 Y91.596
G1 X81.133 Y91.596
G1 X80.999 Y91.73
G1 X79.441 Y93.288 E.06909
G1 X79.307 Y93.422
G1 X78.774 Y93.422
G1 X78.908 Y93.288
G1 X80.466 Y91.73 E.06909
G1 X80.6 Y91.596
G1 X80.066 Y91.596
G1 X79.933 Y91.73
G1 X78.375 Y93.288 E.06909
G1 X78.241 Y93.422
G1 X77.708 Y93.422
G1 X77.841 Y93.288
G1 X79.4 Y91.73 E.0691
G1 X79.533 Y91.596
G1 X79 Y91.596
G1 X78.866 Y91.73
G1 X77.308 Y93.288 E.0691
G1 X77.174 Y93.422
G1 X76.641 Y93.422
G1 X76.775 Y93.288
G1 X78.333 Y91.729 E.0691
G1 X78.467 Y91.596
G1 X77.934 Y91.596
G1 X77.8 Y91.729
G1 X76.242 Y93.288 E.06911
G1 X76.108 Y93.422
G1 X75.575 Y93.422
G1 X75.708 Y93.288
G1 X77.267 Y91.729 E.06911
G1 X77.4 Y91.596
G1 X76.867 Y91.596
G1 X76.734 Y91.729
G1 X75.175 Y93.288 E.06911
G1 X75.041 Y93.422
G1 X74.508 Y93.422
G1 X74.642 Y93.288
G1 X76.2 Y91.729 E.06912
G1 X76.334 Y91.596
G1 X75.801 Y91.595
G1 X75.667 Y91.729
G1 X74.108 Y93.288 E.06912
G1 X73.975 Y93.422
G1 X73.442 Y93.422
G1 X73.575 Y93.288
G1 X75.134 Y91.729 E.06912
G1 X75.268 Y91.595
G1 X74.735 Y91.595
G1 X74.601 Y91.729
G1 X73.042 Y93.288 E.06913
G1 X72.908 Y93.422
G1 X72.375 Y93.422
G1 X72.509 Y93.288
G1 X74.068 Y91.729 E.06913
G1 X74.201 Y91.595
G1 X73.668 Y91.595
G1 X73.535 Y91.729
G1 X71.975 Y93.288 E.06913
G1 X71.842 Y93.422
G1 X71.309 Y93.422
G1 X71.442 Y93.288
G1 X73.001 Y91.729 E.06913
G1 X73.135 Y91.595
G1 X72.602 Y91.595
G1 X72.468 Y91.729
G1 X70.909 Y93.288 E.06914
G1 X70.775 Y93.422
G1 X70.242 Y93.422
G1 X70.376 Y93.288
G1 X71.935 Y91.729 E.06914
G1 X72.069 Y91.595
G1 X71.535 Y91.595
G1 X71.402 Y91.729
G1 X69.842 Y93.288 E.06914
G1 X69.709 Y93.422
G1 X69.176 Y93.422
G1 X69.309 Y93.288
G1 X70.869 Y91.728 E.06915
G1 X71.002 Y91.595
G1 X70.469 Y91.595
G1 X70.335 Y91.728
G1 X68.776 Y93.288 E.06915
G1 X68.642 Y93.422
G1 X68.109 Y93.422
G1 X68.243 Y93.288
G1 X69.802 Y91.728 E.06915
G1 X69.936 Y91.595
G1 X69.403 Y91.595
G1 X69.269 Y91.728
G1 X67.709 Y93.288 E.06916
G1 X67.576 Y93.422
G1 X67.043 Y93.422
G1 X67.176 Y93.288
G1 X68.736 Y91.728 E.06916
G1 X68.869 Y91.595
G1 X68.336 Y91.595
G1 X68.203 Y91.728
G1 X66.643 Y93.288 E.06916
G1 X66.509 Y93.422
G1 X65.976 Y93.422
G1 X66.11 Y93.288
G1 X67.669 Y91.728 E.06917
G1 X67.803 Y91.594
G1 X67.27 Y91.594
G1 X67.136 Y91.728
G1 X65.576 Y93.288 E.06917
G1 X65.443 Y93.422
G1 X64.909 Y93.422
G1 X65.043 Y93.288
G1 X66.603 Y91.728 E.06917
G1 X66.737 Y91.594
G1 X66.204 Y91.594
G1 X66.07 Y91.728
G1 X64.51 Y93.288 E.06917
G1 X64.376 Y93.422
G1 X63.843 Y93.422
G1 X63.977 Y93.288
G1 X65.537 Y91.728 E.06918
G1 X65.67 Y91.594
G1 X65.137 Y91.594
G1 X65.004 Y91.728
G1 X63.443 Y93.288 E.06918
G1 X63.31 Y93.422
G1 X62.776 Y93.422
G1 X62.91 Y93.288
G1 X64.47 Y91.728 E.06918
G1 X64.604 Y91.594
G1 X64.071 Y91.594
G1 X63.937 Y91.728
G1 X62.377 Y93.288 E.06919
G1 X62.243 Y93.422
G1 X61.71 Y93.422
G1 X61.844 Y93.288
G1 X63.404 Y91.728 E.06919
G1 X63.538 Y91.594
G1 X63.004 Y91.594
G1 X62.871 Y91.727
G1 X61.31 Y93.288 E.06919
G1 X61.177 Y93.422
G1 X60.643 Y93.422
G1 X60.777 Y93.288
G1 X62.338 Y91.727 E.0692
G1 X62.471 Y91.594
G1 X61.938 Y91.594
G1 X61.804 Y91.727
G1 X60.244 Y93.288 E.0692
G1 X60.11 Y93.422
G1 X59.577 Y93.422
G1 X59.711 Y93.288
G1 X61.271 Y91.727 E.0692
G1 X61.405 Y91.594
G1 X60.872 Y91.594
G1 X60.738 Y91.727
G1 X59.177 Y93.288 E.06921
G1 X59.044 Y93.422
G1 X58.51 Y93.422
G1 X58.644 Y93.288
G1 X60.205 Y91.727 E.06921
G1 X60.338 Y91.593
G1 X59.805 Y91.593
G1 X59.672 Y91.727
G1 X58.111 Y93.288 E.06921
G1 X57.977 Y93.422
G1 X57.444 Y93.422
G1 X57.578 Y93.288
G1 X59.138 Y91.727 E.06921
G1 X59.272 Y91.593
G1 X58.739 Y91.593
G1 X58.605 Y91.727
G1 X57.044 Y93.288 E.06922
G1 X56.911 Y93.422
G1 X56.377 Y93.422
G1 X56.511 Y93.288
G1 X58.072 Y91.727 E.06922
G1 X58.206 Y91.593
G1 X57.673 Y91.593
G1 X57.539 Y91.727
G1 X55.978 Y93.288 E.06922
G1 X55.844 Y93.422
G1 X55.311 Y93.422
G1 X55.444 Y93.288
G1 X57.006 Y91.727 E.06923
G1 X57.139 Y91.593
G1 X56.606 Y91.593
G1 X56.473 Y91.727
G1 X54.911 Y93.288 E.06923
G1 X54.778 Y93.422
G1 X54.244 Y93.422
G1 X54.378 Y93.288
G1 X55.939 Y91.727 E.06923
G1 X56.073 Y91.593
G1 X55.54 Y91.593
G1 X55.406 Y91.726
G1 X53.845 Y93.288 E.06924
G1 X53.711 Y93.422
G1 X53.178 Y93.422
G1 X53.311 Y93.288
G1 X54.873 Y91.726 E.06924
G1 X55.007 Y91.593
G1 X54.473 Y91.593
G1 X54.34 Y91.726
G1 X52.778 Y93.288 E.06924
G1 X52.645 Y93.422
G1 X52.111 Y93.422
G1 X52.245 Y93.288
G1 X53.807 Y91.726 E.06925
G1 X53.94 Y91.593
G1 X53.407 Y91.593
G1 X53.273 Y91.726
G1 X51.712 Y93.288 E.06925
G1 X51.578 Y93.422
G1 X51.045 Y93.422
G1 X51.178 Y93.288
G1 X52.74 Y91.726 E.06925
G1 X52.874 Y91.592
G1 X52.341 Y91.592
G1 X52.207 Y91.726
G1 X50.645 Y93.288 E.06926
G1 X50.512 Y93.422
G1 X49.978 Y93.422
G1 X50.112 Y93.288
G1 X51.674 Y91.726 E.06926
G1 X51.807 Y91.592
G1 X51.274 Y91.592
G1 X51.141 Y91.726
G1 X49.579 Y93.288 E.06926
G1 X49.445 Y93.422
G1 X48.912 Y93.422
G1 X49.045 Y93.288
G1 X50.607 Y91.726 E.06926
G1 X50.741 Y91.592
G1 X50.208 Y91.592
G1 X50.074 Y91.726
G1 X48.512 Y93.288 E.06927
G1 X48.378 Y93.422
G1 X47.845 Y93.422
G1 X47.979 Y93.288
G1 X49.541 Y91.726 E.06927
G1 X49.675 Y91.592
G1 X49.142 Y91.592
G1 X49.008 Y91.726
G1 X47.446 Y93.288 E.06927
G1 X47.312 Y93.422
G1 X46.779 Y93.422
G1 X46.912 Y93.288
G1 X48.475 Y91.726 E.06928
G1 X48.608 Y91.592
G1 X48.075 Y91.592
G1 X47.941 Y91.726
G1 X46.379 Y93.288 E.06928
G1 X46.245 Y93.422
G1 X45.712 Y93.422
G1 X45.846 Y93.288
G1 X47.408 Y91.725 E.06928
G1 X47.542 Y91.592
G1 X47.009 Y91.592
G1 X46.875 Y91.725
G1 X45.313 Y93.288 E.06929
G1 X45.179 Y93.422
G1 X44.646 Y93.422
G1 X44.779 Y93.288
G1 X46.342 Y91.725 E.06929
G1 X46.476 Y91.592
G1 X45.942 Y91.592
G1 X45.809 Y91.725
G1 X44.246 Y93.288 E.06929
G1 X44.112 Y93.422
G1 X43.579 Y93.422
G1 X43.713 Y93.288
G1 X45.276 Y91.725 E.06929
G1 X45.409 Y91.592
G1 X44.876 Y91.591
G1 X44.742 Y91.725
G1 X43.18 Y93.288 E.0693
G1 X43.046 Y93.422
G1 X42.513 Y93.422
G1 X42.646 Y93.288
G1 X44.209 Y91.725 E.0693
G1 X44.343 Y91.591
G1 X43.81 Y91.591
G1 X43.676 Y91.725
G1 X42.113 Y93.288 E.0693
G1 X41.979 Y93.422
G1 X41.446 Y93.422
G1 X41.58 Y93.288
G1 X43.143 Y91.725 E.06931
G1 X43.276 Y91.591
G1 X42.743 Y91.591
G1 X42.61 Y91.725
G1 X41.047 Y93.288 E.06931
G1 X40.913 Y93.422
G1 X40.38 Y93.422
G1 X40.513 Y93.288
G1 X42.076 Y91.725 E.06931
G1 X42.21 Y91.591
G1 X41.677 Y91.591
G1 X41.543 Y91.725
G1 X39.98 Y93.288 E.06932
G1 X39.846 Y93.422
G1 X39.313 Y93.422
G1 X39.447 Y93.288
G1 X41.01 Y91.725 E.06932
G1 X41.144 Y91.591
G1 X40.611 Y91.591
G1 X40.477 Y91.725
G1 X38.913 Y93.288 E.06932
G1 X38.78 Y93.422
G1 X38.247 Y93.422
G1 X38.38 Y93.288
G1 X39.944 Y91.724 E.06933
G1 X40.077 Y91.591
G1 X39.544 Y91.591
G1 X39.41 Y91.724
G1 X37.847 Y93.288 E.06933
G1 X37.713 Y93.422
G1 X37.18 Y93.422
G1 X37.314 Y93.288
G1 X38.877 Y91.724 E.06933
G1 X39.011 Y91.591
G1 X38.478 Y91.591
G1 X38.344 Y91.724
G1 X36.78 Y93.288 E.06933
G1 X36.647 Y93.422
G1 X36.114 Y93.422
G1 X36.247 Y93.288
G1 X37.811 Y91.724 E.06934
G1 X37.945 Y91.591
G1 X37.411 Y91.59
G1 X37.278 Y91.724
G1 X35.714 Y93.288 E.06934
G1 X35.58 Y93.422
G1 X35.047 Y93.422
G1 X35.181 Y93.288
G1 X36.745 Y91.724 E.06934
G1 X36.878 Y91.59
G1 X36.345 Y91.59
G1 X36.211 Y91.724
G1 X34.647 Y93.288 E.06935
G1 X34.514 Y93.422
G1 X33.981 Y93.422
G1 X34.114 Y93.288
G1 X35.678 Y91.724 E.06935
G1 X35.812 Y91.59
G1 X35.279 Y91.59
G1 X35.145 Y91.724
G1 X33.581 Y93.288 E.06935
G1 X33.447 Y93.422
G1 X32.914 Y93.422
G1 X33.048 Y93.288
G1 X34.612 Y91.724 E.06936
G1 X34.745 Y91.59
G1 X34.212 Y91.59
G1 X34.079 Y91.724
G1 X32.514 Y93.288 E.06936
G1 X32.381 Y93.422
G1 X31.847 Y93.422
G1 X31.981 Y93.288
G1 X33.545 Y91.724 E.06936
G1 X33.679 Y91.59
G1 X33.146 Y91.59
G1 X33.012 Y91.724
G1 X31.448 Y93.288 E.06937
G1 X31.314 Y93.422
G1 X30.781 Y93.422
G1 X30.915 Y93.288
G1 X32.479 Y91.723 E.06937
G1 X32.613 Y91.59
G1 X32.079 Y91.59
G1 X31.946 Y91.723
G1 X30.381 Y93.288 E.06937
G1 X30.248 Y93.422
G1 X29.714 Y93.422
G1 X29.848 Y93.288
G1 X31.413 Y91.723 E.06938
G1 X31.546 Y91.59
G1 X31.013 Y91.59
G1 X30.879 Y91.723
G1 X29.315 Y93.288 E.06938
G1 X29.181 Y93.422
G1 X28.648 Y93.422
G1 X28.782 Y93.288
G1 X30.346 Y91.723 E.06938
G1 X30.48 Y91.59
G1 X29.947 Y91.59
G1 X29.813 Y91.723
G1 X28.248 Y93.288 E.06938
G1 X28.115 Y93.422
G1 X27.581 Y93.422
G1 X27.715 Y93.288
G1 X29.28 Y91.723 E.06939
G1 X29.414 Y91.589
G1 X28.88 Y91.589
G1 X28.747 Y91.723
G1 X27.182 Y93.288 E.06939
G1 X27.048 Y93.422
G1 X26.515 Y93.422
G1 X26.649 Y93.288
G1 X28.214 Y91.723 E.06939
G1 X28.347 Y91.589
G1 X27.814 Y91.589
G1 X27.68 Y91.723
G1 X26.115 Y93.288 E.0694
G1 X25.982 Y93.422
G1 X25.406 Y93.464
G1 X25.54 Y93.33
G1 X27.147 Y91.723 E.07128
G1 X27.281 Y91.589
G1 X26.748 Y91.589
G1 X26.614 Y91.723
G1 X24.838 Y93.499 E.07874
G1 X24.705 Y93.632
G1 X23.642 Y94.162
G1 X23.776 Y94.028
G1 X26.08 Y91.723 E.1022
; WIPE_START
M204 S3000
G1 X24.666 Y93.137 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X30.435 Y98.134 Z1.6 F36000
G1 X82.101 Y142.888 Z1.6
G1 Z1.2
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X84.405 Y140.583 E.10218
G1 X84.539 Y140.449
G1 X83.469 Y140.986
G1 X83.335 Y141.12
G1 X81.567 Y142.888 E.07841
G1 X81.433 Y143.022
G1 X80.9 Y143.022
G1 X81.034 Y142.888
G1 X82.642 Y141.28 E.0713
G1 X82.775 Y141.146
G1 X82.199 Y141.189
G1 X82.066 Y141.323
G1 X80.501 Y142.888 E.06941
G1 X80.367 Y143.022
G1 X79.834 Y143.022
G1 X79.967 Y142.888
G1 X81.533 Y141.323 E.06941
G1 X81.666 Y141.189
G1 X81.133 Y141.189
G1 X80.999 Y141.323
G1 X79.434 Y142.888 E.06941
G1 X79.3 Y143.022
G1 X78.767 Y143.022
G1 X78.901 Y142.888
G1 X80.466 Y141.323 E.06941
G1 X80.6 Y141.189
G1 X80.066 Y141.189
G1 X79.933 Y141.323
G1 X78.367 Y142.888 E.06941
G1 X78.234 Y143.022
G1 X77.701 Y143.022
G1 X77.834 Y142.888
G1 X79.399 Y141.323 E.06941
G1 X79.533 Y141.189
G1 X79 Y141.189
G1 X78.866 Y141.323
G1 X77.301 Y142.888 E.06941
G1 X77.167 Y143.022
G1 X76.634 Y143.022
G1 X76.768 Y142.888
G1 X78.333 Y141.323 E.06941
G1 X78.467 Y141.189
G1 X77.933 Y141.189
G1 X77.8 Y141.323
G1 X76.234 Y142.888 E.06941
G1 X76.101 Y143.022
G1 X75.568 Y143.022
G1 X75.701 Y142.888
G1 X77.266 Y141.323 E.06941
G1 X77.4 Y141.189
G1 X76.867 Y141.189
G1 X76.733 Y141.323
G1 X75.168 Y142.888 E.06941
G1 X75.034 Y143.022
G1 X74.501 Y143.022
G1 X74.635 Y142.888
G1 X76.2 Y141.323 E.06941
G1 X76.334 Y141.189
G1 X75.8 Y141.189
G1 X75.667 Y141.323
G1 X74.101 Y142.888 E.06941
G1 X73.968 Y143.022
G1 X73.435 Y143.022
G1 X73.568 Y142.888
G1 X75.133 Y141.323 E.06941
G1 X75.267 Y141.189
G1 X74.734 Y141.189
G1 X74.6 Y141.323
G1 X73.035 Y142.888 E.06941
G1 X72.901 Y143.022
G1 X72.368 Y143.022
G1 X72.502 Y142.888
G1 X74.067 Y141.323 E.06941
G1 X74.201 Y141.189
G1 X73.667 Y141.189
G1 X73.534 Y141.323
G1 X71.968 Y142.888 E.06941
G1 X71.835 Y143.022
G1 X71.301 Y143.022
G1 X71.435 Y142.888
G1 X73 Y141.323 E.06941
G1 X73.134 Y141.189
G1 X72.601 Y141.189
G1 X72.467 Y141.323
G1 X70.902 Y142.888 E.06941
G1 X70.768 Y143.022
G1 X70.235 Y143.022
G1 X70.369 Y142.888
G1 X71.934 Y141.323 E.06941
G1 X72.068 Y141.189
G1 X71.534 Y141.189
G1 X71.401 Y141.323
G1 X69.835 Y142.888 E.06941
G1 X69.702 Y143.022
G1 X69.168 Y143.022
G1 X69.302 Y142.888
G1 X70.867 Y141.323 E.06941
G1 X71.001 Y141.189
G1 X70.468 Y141.189
G1 X70.334 Y141.323
G1 X68.769 Y142.888 E.06941
G1 X68.635 Y143.022
G1 X68.102 Y143.022
G1 X68.236 Y142.888
G1 X69.801 Y141.323 E.06941
G1 X69.934 Y141.189
G1 X69.401 Y141.189
G1 X69.268 Y141.323
G1 X67.702 Y142.888 E.06941
G1 X67.569 Y143.022
G1 X67.035 Y143.022
G1 X67.169 Y142.888
G1 X68.734 Y141.323 E.06941
G1 X68.868 Y141.189
G1 X68.335 Y141.189
G1 X68.201 Y141.323
G1 X66.636 Y142.888 E.06941
G1 X66.502 Y143.022
G1 X65.969 Y143.022
G1 X66.103 Y142.888
G1 X67.668 Y141.323 E.06941
G1 X67.801 Y141.189
G1 X67.268 Y141.189
G1 X67.135 Y141.323
G1 X65.569 Y142.888 E.06941
G1 X65.436 Y143.022
G1 X64.902 Y143.022
G1 X65.036 Y142.888
G1 X66.601 Y141.323 E.06941
G1 X66.735 Y141.189
G1 X66.202 Y141.189
G1 X66.068 Y141.323
G1 X64.503 Y142.888 E.06941
G1 X64.369 Y143.022
G1 X63.836 Y143.022
G1 X63.97 Y142.888
G1 X65.535 Y141.323 E.06941
G1 X65.668 Y141.189
G1 X65.135 Y141.189
G1 X65.002 Y141.323
G1 X63.436 Y142.888 E.06941
G1 X63.303 Y143.022
G1 X62.769 Y143.022
G1 X62.903 Y142.888
G1 X64.468 Y141.323 E.06941
G1 X64.602 Y141.189
G1 X64.069 Y141.189
G1 X63.935 Y141.323
G1 X62.37 Y142.888 E.06941
G1 X62.236 Y143.022
G1 X61.703 Y143.022
G1 X61.836 Y142.888
G1 X63.402 Y141.323 E.06941
G1 X63.535 Y141.189
G1 X63.002 Y141.189
G1 X62.868 Y141.323
G1 X61.303 Y142.888 E.06941
G1 X61.17 Y143.022
G1 X60.636 Y143.022
G1 X60.77 Y142.888
G1 X62.335 Y141.323 E.06941
G1 X62.469 Y141.189
G1 X61.936 Y141.189
G1 X61.802 Y141.323
G1 X60.237 Y142.888 E.06941
G1 X60.103 Y143.022
G1 X59.57 Y143.022
G1 X59.703 Y142.888
G1 X61.269 Y141.323 E.06941
G1 X61.402 Y141.189
G1 X60.869 Y141.189
G1 X60.735 Y141.323
G1 X59.17 Y142.888 E.06941
G1 X59.037 Y143.022
G1 X58.503 Y143.022
G1 X58.637 Y142.888
G1 X60.202 Y141.323 E.06941
G1 X60.336 Y141.189
G1 X59.803 Y141.189
G1 X59.669 Y141.323
G1 X58.104 Y142.888 E.06941
G1 X57.97 Y143.022
G1 X57.437 Y143.022
G1 X57.57 Y142.888
G1 X59.136 Y141.323 E.06941
G1 X59.269 Y141.189
G1 X58.736 Y141.189
G1 X58.602 Y141.323
G1 X57.037 Y142.888 E.06941
G1 X56.904 Y143.022
G1 X56.37 Y143.022
G1 X56.504 Y142.888
G1 X58.069 Y141.323 E.06941
M73 P43 R27
G1 X58.203 Y141.189
G1 X57.67 Y141.189
G1 X57.536 Y141.323
G1 X55.971 Y142.888 E.06941
G1 X55.837 Y143.022
G1 X55.304 Y143.022
G1 X55.437 Y142.888
G1 X57.003 Y141.323 E.06941
G1 X57.136 Y141.189
G1 X56.603 Y141.189
G1 X56.469 Y141.323
G1 X54.904 Y142.888 E.06941
G1 X54.771 Y143.022
G1 X54.237 Y143.022
G1 X54.371 Y142.888
G1 X55.936 Y141.323 E.06941
G1 X56.07 Y141.189
G1 X55.537 Y141.189
G1 X55.403 Y141.323
G1 X53.838 Y142.888 E.06941
G1 X53.704 Y143.022
G1 X53.171 Y143.022
G1 X53.304 Y142.888
G1 X54.87 Y141.323 E.06941
G1 X55.003 Y141.189
G1 X54.47 Y141.189
G1 X54.336 Y141.323
G1 X52.771 Y142.888 E.06941
G1 X52.637 Y143.022
G1 X52.104 Y143.022
G1 X52.238 Y142.888
G1 X53.803 Y141.323 E.06941
G1 X53.937 Y141.189
G1 X53.403 Y141.189
G1 X53.27 Y141.323
G1 X51.705 Y142.888 E.06941
G1 X51.571 Y143.022
G1 X51.038 Y143.022
G1 X51.171 Y142.888
G1 X52.737 Y141.323 E.06941
G1 X52.87 Y141.189
G1 X52.337 Y141.189
G1 X52.203 Y141.323
G1 X50.638 Y142.888 E.06941
G1 X50.504 Y143.022
G1 X49.971 Y143.022
G1 X50.105 Y142.888
G1 X51.67 Y141.323 E.06941
G1 X51.804 Y141.189
G1 X51.27 Y141.189
G1 X51.137 Y141.323
G1 X49.572 Y142.888 E.06941
G1 X49.438 Y143.022
G1 X48.905 Y143.022
G1 X49.038 Y142.888
G1 X50.604 Y141.323 E.06941
G1 X50.737 Y141.189
G1 X50.204 Y141.189
G1 X50.07 Y141.323
G1 X48.505 Y142.888 E.06941
G1 X48.371 Y143.022
G1 X47.838 Y143.022
G1 X47.972 Y142.888
G1 X49.537 Y141.323 E.06941
G1 X49.671 Y141.189
G1 X49.137 Y141.189
G1 X49.004 Y141.323
G1 X47.439 Y142.888 E.06941
G1 X47.305 Y143.022
G1 X46.772 Y143.022
G1 X46.905 Y142.888
G1 X48.471 Y141.323 E.06941
G1 X48.604 Y141.189
G1 X48.071 Y141.189
G1 X47.937 Y141.323
G1 X46.372 Y142.888 E.06941
G1 X46.238 Y143.022
G1 X45.705 Y143.022
G1 X45.839 Y142.888
G1 X47.404 Y141.323 E.06941
G1 X47.538 Y141.189
G1 X47.004 Y141.189
G1 X46.871 Y141.323
G1 X45.306 Y142.888 E.06941
G1 X45.172 Y143.022
G1 X44.639 Y143.022
G1 X44.772 Y142.888
G1 X46.338 Y141.323 E.06941
G1 X46.471 Y141.189
G1 X45.938 Y141.189
G1 X45.804 Y141.323
G1 X44.239 Y142.888 E.06941
G1 X44.105 Y143.022
G1 X43.572 Y143.022
G1 X43.706 Y142.888
G1 X45.271 Y141.323 E.06941
G1 X45.405 Y141.189
G1 X44.871 Y141.189
G1 X44.738 Y141.323
G1 X43.172 Y142.888 E.06941
G1 X43.039 Y143.022
G1 X42.506 Y143.022
G1 X42.639 Y142.888
G1 X44.204 Y141.323 E.06941
G1 X44.338 Y141.189
G1 X43.805 Y141.189
G1 X43.671 Y141.323
G1 X42.106 Y142.888 E.06941
G1 X41.972 Y143.022
G1 X41.439 Y143.022
G1 X41.573 Y142.888
G1 X43.138 Y141.323 E.06941
G1 X43.272 Y141.189
G1 X42.738 Y141.189
G1 X42.605 Y141.323
G1 X41.039 Y142.888 E.06941
G1 X40.906 Y143.022
G1 X40.373 Y143.022
G1 X40.506 Y142.888
G1 X42.071 Y141.323 E.06941
G1 X42.205 Y141.189
G1 X41.672 Y141.189
G1 X41.538 Y141.323
G1 X39.973 Y142.888 E.06941
G1 X39.839 Y143.022
G1 X39.306 Y143.022
G1 X39.44 Y142.888
G1 X41.005 Y141.323 E.06941
G1 X41.139 Y141.189
G1 X40.605 Y141.189
G1 X40.472 Y141.323
G1 X38.906 Y142.888 E.06941
G1 X38.773 Y143.022
G1 X38.24 Y143.022
G1 X38.373 Y142.888
G1 X39.938 Y141.323 E.06941
G1 X40.072 Y141.189
G1 X39.539 Y141.189
G1 X39.405 Y141.323
G1 X37.84 Y142.888 E.06941
G1 X37.706 Y143.022
G1 X37.173 Y143.022
G1 X37.307 Y142.888
G1 X38.872 Y141.323 E.06941
G1 X39.006 Y141.189
G1 X38.472 Y141.189
G1 X38.339 Y141.323
G1 X36.773 Y142.888 E.06941
G1 X36.64 Y143.022
G1 X36.106 Y143.022
G1 X36.24 Y142.888
G1 X37.805 Y141.323 E.06941
G1 X37.939 Y141.189
G1 X37.406 Y141.189
G1 X37.272 Y141.323
G1 X35.707 Y142.888 E.06941
G1 X35.573 Y143.022
G1 X35.04 Y143.022
G1 X35.174 Y142.888
G1 X36.739 Y141.323 E.06941
G1 X36.873 Y141.189
G1 X36.339 Y141.189
G1 X36.206 Y141.323
G1 X34.64 Y142.888 E.06941
G1 X34.507 Y143.022
G1 X33.973 Y143.022
G1 X34.107 Y142.888
G1 X35.672 Y141.323 E.06941
G1 X35.806 Y141.189
G1 X35.273 Y141.189
G1 X35.139 Y141.323
G1 X33.574 Y142.888 E.06941
G1 X33.44 Y143.022
G1 X32.907 Y143.022
G1 X33.041 Y142.888
G1 X34.606 Y141.323 E.06941
G1 X34.739 Y141.189
G1 X34.206 Y141.189
G1 X34.073 Y141.323
G1 X32.507 Y142.888 E.06941
G1 X32.374 Y143.022
G1 X31.84 Y143.022
G1 X31.974 Y142.888
G1 X33.539 Y141.323 E.06941
G1 X33.673 Y141.189
G1 X33.14 Y141.189
G1 X33.006 Y141.323
G1 X31.441 Y142.888 E.06941
G1 X31.307 Y143.022
G1 X30.774 Y143.022
G1 X30.908 Y142.888
G1 X32.473 Y141.323 E.06941
G1 X32.606 Y141.189
G1 X32.073 Y141.189
G1 X31.94 Y141.323
G1 X30.374 Y142.888 E.06941
G1 X30.241 Y143.022
G1 X29.707 Y143.022
G1 X29.841 Y142.888
G1 X31.406 Y141.323 E.06941
G1 X31.54 Y141.189
G1 X31.007 Y141.189
G1 X30.873 Y141.323
G1 X29.308 Y142.888 E.06941
G1 X29.174 Y143.022
G1 X28.641 Y143.022
G1 X28.775 Y142.888
G1 X30.34 Y141.323 E.06941
G1 X30.473 Y141.189
G1 X29.94 Y141.189
G1 X29.807 Y141.323
G1 X28.241 Y142.888 E.06941
G1 X28.108 Y143.022
G1 X27.574 Y143.022
G1 X27.708 Y142.888
G1 X29.273 Y141.323 E.06941
G1 X29.407 Y141.189
G1 X28.874 Y141.189
G1 X28.74 Y141.323
G1 X27.175 Y142.888 E.06941
G1 X27.041 Y143.022
G1 X26.508 Y143.022
G1 X26.641 Y142.888
G1 X28.207 Y141.323 E.06941
G1 X28.34 Y141.189
G1 X27.807 Y141.189
G1 X27.673 Y141.323
G1 X26.108 Y142.888 E.06941
G1 X25.975 Y143.022
G1 X25.467 Y142.996
G1 X25.601 Y142.862
G1 X27.14 Y141.323 E.06825
G1 X27.274 Y141.189
G1 X26.741 Y141.189
G1 X26.607 Y141.323
G1 X25.132 Y142.798 E.0654
G1 X24.998 Y142.931
G1 X24.56 Y142.836
G1 X24.694 Y142.702
G1 X26.074 Y141.322 E.0612
G1 X26.208 Y141.189
G1 X25.711 Y141.153
G1 X25.577 Y141.286
G1 X24.281 Y142.582 E.05746
G1 X24.148 Y142.716
G1 X23.762 Y142.568
G1 X23.896 Y142.434
G1 X25.131 Y141.199 E.05477
G1 X25.265 Y141.065
G1 X24.853 Y140.943
G1 X24.72 Y141.077
G1 X23.536 Y142.26 E.05247
G1 X23.403 Y142.394
G1 X23.059 Y142.204
G1 X23.193 Y142.07
G1 X24.35 Y140.914 E.0513
G1 X24.483 Y140.78
G1 X24.135 Y140.595
G1 X24.002 Y140.728
G1 X22.87 Y141.86 E.0502
G1 X22.736 Y141.994
G1 X22.431 Y141.766
G1 X22.565 Y141.632
G1 X23.685 Y140.512 E.04967
G1 X23.819 Y140.378
G1 X23.524 Y140.139
G1 X23.39 Y140.273
G1 X22.284 Y141.379 E.04905
G1 X22.151 Y141.513
G1 X21.884 Y141.246
G1 X22.018 Y141.113
G1 X23.124 Y140.007 E.04906
G1 X23.257 Y139.873
G1 X23.016 Y139.581
G1 X22.882 Y139.715
G1 X21.765 Y140.832 E.04954
G1 X21.631 Y140.966
G1 X21.403 Y140.661
G1 X21.536 Y140.528
G1 X22.666 Y139.398 E.05009
G1 X22.8 Y139.264
G1 X22.611 Y138.92
G1 X22.477 Y139.054
G1 X21.326 Y140.204 E.05103
G1 X21.193 Y140.338
G1 X20.998 Y139.999
G1 X21.132 Y139.865
G1 X22.318 Y138.679 E.05261
G1 X22.452 Y138.545
G1 X22.327 Y138.137
G1 X22.194 Y138.27
G1 X20.965 Y139.499 E.05449
G1 X20.831 Y139.633
G1 X20.679 Y139.252
G1 X20.812 Y139.118
G1 X22.11 Y137.82 E.05755
G1 X22.244 Y137.687
G1 X22.212 Y137.186
G1 X22.078 Y137.319
G1 X20.694 Y138.704 E.06139
G1 X20.56 Y138.837
G1 X20.465 Y138.4
G1 X20.598 Y138.266
G1 X22.078 Y136.786 E.06563
G1 X22.212 Y136.652
G1 X22.212 Y136.119
G1 X22.078 Y136.253
G1 X20.532 Y137.799 E.06855
G1 X20.399 Y137.932
G1 X20.382 Y137.415
G1 X20.516 Y137.282
G1 X22.078 Y135.719 E.06928
G1 X22.212 Y135.586
G1 X22.212 Y135.052
G1 X22.078 Y135.186
G1 X20.516 Y136.749 E.06929
G1 X20.382 Y136.882
G1 X20.382 Y136.349
G1 X20.516 Y136.216
G1 X22.078 Y134.653 E.06929
G1 X22.212 Y134.519
G1 X22.212 Y133.986
G1 X22.078 Y134.12
G1 X20.516 Y135.682 E.0693
G1 X20.382 Y135.816
G1 X20.382 Y135.283
G1 X20.515 Y135.149
G1 X22.078 Y133.586 E.0693
G1 X22.212 Y133.453
G1 X22.212 Y132.919
G1 X22.078 Y133.053
G1 X20.515 Y134.616 E.06931
G1 X20.382 Y134.75
G1 X20.382 Y134.217
G1 X20.515 Y134.083
G1 X22.078 Y132.52 E.06931
G1 X22.212 Y132.386
G1 X22.212 Y131.853
G1 X22.078 Y131.987
G1 X20.515 Y133.55 E.06932
G1 X20.382 Y133.683
G1 X20.381 Y133.15
G1 X20.515 Y133.017
G1 X22.078 Y131.453 E.06932
G1 X22.212 Y131.32
G1 X22.212 Y130.786
G1 X22.078 Y130.92
G1 X20.515 Y132.483 E.06933
G1 X20.381 Y132.617
G1 X20.381 Y132.084
G1 X20.515 Y131.95
G1 X22.078 Y130.387 E.06933
G1 X22.212 Y130.253
G1 X22.212 Y129.72
G1 X22.078 Y129.854
G1 X20.515 Y131.417 E.06933
G1 X20.381 Y131.551
G1 X20.381 Y131.018
G1 X20.515 Y130.884
G1 X22.078 Y129.32 E.06934
G1 X22.212 Y129.187
G1 X22.212 Y128.653
G1 X22.078 Y128.787
G1 X20.515 Y130.351 E.06934
G1 X20.381 Y130.485
G1 X20.381 Y129.951
G1 X20.514 Y129.818
G1 X22.078 Y128.254 E.06935
G1 X22.212 Y128.12
G1 X22.212 Y127.587
G1 X22.078 Y127.721
G1 X20.514 Y129.285 E.06935
G1 X20.381 Y129.418
G1 X20.381 Y128.885
G1 X20.514 Y128.751
G1 X22.078 Y127.187 E.06936
G1 X22.212 Y127.054
G1 X22.212 Y126.52
G1 X22.078 Y126.654
G1 X20.514 Y128.218 E.06936
G1 X20.38 Y128.352
G1 X20.38 Y127.819
G1 X20.514 Y127.685
G1 X22.078 Y126.121 E.06937
G1 X22.212 Y125.987
G1 X22.212 Y125.454
G1 X22.078 Y125.587
G1 X20.514 Y127.152 E.06937
G1 X20.38 Y127.286
G1 X20.38 Y126.752
G1 X20.514 Y126.619
G1 X22.078 Y125.054 E.06938
G1 X22.212 Y124.921
G1 X22.212 Y124.387
G1 X22.078 Y124.521
G1 X20.514 Y126.086 E.06938
G1 X20.38 Y126.219
G1 X20.38 Y125.686
G1 X20.514 Y125.553
G1 X22.078 Y123.988 E.06939
G1 X22.212 Y123.854
G1 X22.212 Y123.321
G1 X22.078 Y123.454
G1 X20.513 Y125.019 E.06939
G1 X20.38 Y125.153
G1 X20.38 Y124.62
G1 X20.513 Y124.486
G1 X22.078 Y122.921 E.0694
G1 X22.212 Y122.788
G1 X22.212 Y122.254
G1 X22.078 Y122.388
G1 X20.513 Y123.953 E.0694
G1 X20.38 Y124.087
G1 X20.38 Y123.554
G1 X20.513 Y123.42
G1 X22.078 Y121.855 E.0694
G1 X22.212 Y121.721
G1 X22.212 Y121.188
G1 X22.078 Y121.321
G1 X20.513 Y122.887 E.06941
G1 X20.379 Y123.02
G1 X20.379 Y122.487
G1 X20.513 Y122.354
G1 X22.078 Y120.788 E.06941
G1 X22.212 Y120.655
G1 X22.212 Y120.121
G1 X22.078 Y120.255
G1 X20.513 Y121.82 E.06942
G1 X20.379 Y121.954
G1 X20.379 Y121.421
G1 X20.513 Y121.287
G1 X22.078 Y119.722 E.06942
G1 X22.212 Y119.588
G1 X22.212 Y119.055
G1 X22.078 Y119.188
G1 X20.513 Y120.754 E.06943
G1 X20.379 Y120.888
G1 X20.379 Y120.355
G1 X20.512 Y120.221
G1 X22.078 Y118.655 E.06943
G1 X22.212 Y118.521
G1 X22.212 Y117.988
G1 X22.078 Y118.122
G1 X20.512 Y119.688 E.06944
G1 X20.379 Y119.821
G1 X20.379 Y119.288
G1 X20.512 Y119.155
G1 X22.078 Y117.589 E.06944
G1 X22.212 Y117.455
G1 X22.212 Y116.922
G1 X22.078 Y117.055
G1 X20.512 Y118.622 E.06945
G1 X20.379 Y118.755
G1 X20.378 Y118.222
G1 X20.512 Y118.088
G1 X22.078 Y116.522 E.06945
G1 X22.212 Y116.388
G1 X22.212 Y115.855
G1 X22.078 Y115.989
G1 X20.512 Y117.555 E.06946
G1 X20.378 Y117.689
G1 X20.378 Y117.156
G1 X20.512 Y117.022
G1 X22.078 Y115.456 E.06946
G1 X22.212 Y115.322
G1 X22.212 Y114.789
G1 X22.078 Y114.922
G1 X20.512 Y116.489 E.06947
G1 X20.378 Y116.623
G1 X20.378 Y116.089
G1 X20.512 Y115.956
G1 X22.078 Y114.389 E.06947
G1 X22.212 Y114.255
G1 X22.212 Y113.722
G1 X22.078 Y113.856
G1 X20.512 Y115.423 E.06947
G1 X20.378 Y115.556
G1 X20.378 Y115.023
G1 X20.511 Y114.889
G1 X22.078 Y113.323 E.06948
G1 X22.212 Y113.189
G1 X22.212 Y112.656
G1 X22.078 Y112.789
G1 X20.511 Y114.356 E.06948
G1 X20.378 Y114.49
G1 X20.378 Y113.957
G1 X20.511 Y113.823
G1 X22.078 Y112.256 E.06949
G1 X22.212 Y112.122
G1 X22.212 Y111.589
G1 X22.078 Y111.723
G1 X20.511 Y113.29 E.06949
G1 X20.377 Y113.424
G1 X20.377 Y112.891
G1 X20.511 Y112.757
G1 X22.078 Y111.19 E.0695
G1 X22.212 Y111.056
G1 X22.212 Y110.523
G1 X22.078 Y110.656
G1 X20.511 Y112.224 E.0695
G1 X20.377 Y112.357
G1 X20.377 Y111.824
G1 X20.511 Y111.691
G1 X22.078 Y110.123 E.06951
G1 X22.212 Y109.989
G1 X22.212 Y109.456
G1 X22.078 Y109.59
G1 X20.511 Y111.157 E.06951
G1 X20.377 Y111.291
G1 X20.377 Y110.758
G1 X20.511 Y110.624
G1 X22.078 Y109.057 E.06952
G1 X22.212 Y108.923
G1 X22.212 Y108.39
G1 X22.078 Y108.523
G1 X20.51 Y110.091 E.06952
G1 X20.377 Y110.225
G1 X20.377 Y109.692
G1 X20.51 Y109.558
G1 X22.078 Y107.99 E.06953
G1 X22.212 Y107.856
G1 X22.212 Y107.323
G1 X22.078 Y107.457
G1 X20.51 Y109.025 E.06953
G1 X20.377 Y109.158
G1 X20.377 Y108.625
G1 X20.51 Y108.492
G1 X22.078 Y106.923 E.06954
G1 X22.212 Y106.79
G1 X22.212 Y106.257
G1 X22.078 Y106.39
G1 X20.51 Y107.959 E.06954
G1 X20.376 Y108.092
G1 X20.376 Y107.559
G1 X20.51 Y107.425
G1 X22.078 Y105.857 E.06955
G1 X22.212 Y105.723
G1 X22.212 Y105.19
G1 X22.078 Y105.324
G1 X20.51 Y106.892 E.06955
G1 X20.376 Y107.026
G1 X20.376 Y106.493
G1 X20.51 Y106.359
G1 X22.078 Y104.79 E.06955
G1 X22.212 Y104.657
G1 X22.212 Y104.124
G1 X22.078 Y104.257
G1 X20.51 Y105.826 E.06956
G1 X20.376 Y105.96
G1 X20.376 Y105.426
G1 X20.51 Y105.293
G1 X22.078 Y103.724 E.06956
G1 X22.212 Y103.59
G1 X22.212 Y103.057
G1 X22.078 Y103.191
G1 X20.509 Y104.76 E.06957
G1 X20.376 Y104.893
G1 X20.376 Y104.36
G1 X20.509 Y104.226
G1 X22.078 Y102.657 E.06957
G1 X22.212 Y102.524
G1 X22.212 Y101.991
G1 X22.078 Y102.124
G1 X20.509 Y103.693 E.06958
G1 X20.376 Y103.827
G1 X20.375 Y103.294
G1 X20.509 Y103.16
G1 X22.078 Y101.591 E.06958
G1 X22.212 Y101.457
G1 X22.212 Y100.924
G1 X22.078 Y101.058
G1 X20.509 Y102.627 E.06959
G1 X20.375 Y102.761
G1 X20.375 Y102.227
G1 X20.509 Y102.094
G1 X22.078 Y100.524 E.06959
G1 X22.212 Y100.391
G1 X22.212 Y99.857
G1 X22.078 Y99.991
G1 X20.509 Y101.561 E.0696
G1 X20.375 Y101.694
G1 X20.375 Y101.161
G1 X20.509 Y101.028
G1 X22.078 Y99.458 E.0696
G1 X22.212 Y99.324
G1 X22.212 Y98.791
G1 X22.078 Y98.925
G1 X20.509 Y100.494 E.06961
G1 X20.375 Y100.628
G1 X20.375 Y100.095
G1 X20.508 Y99.961
G1 X22.078 Y98.391 E.06961
G1 X22.212 Y98.258
G1 X22.212 Y97.724
G1 X22.078 Y97.858
G1 X20.508 Y99.428 E.06962
G1 X20.375 Y99.562
G1 X20.375 Y99.029
G1 X20.508 Y98.895
G1 X22.078 Y97.325 E.06962
G1 X22.212 Y97.191
G1 X22.258 Y96.612
G1 X22.124 Y96.746
G1 X20.508 Y98.362 E.07165
G1 X20.375 Y98.495
G1 X20.374 Y97.962
G1 X20.508 Y97.829
G1 X22.268 Y96.068 E.07805
G1 X22.402 Y95.935
G1 X22.938 Y94.866
G1 X22.804 Y94.999
G1 X20.509 Y97.294 E.10177
G1 X20.375 Y97.428
G1 X20.405 Y96.865
G1 X20.538 Y96.732
G1 X25.509 Y91.761 E.22041
G1 X25.643 Y91.627
G1 X25.005 Y91.732
G1 X24.872 Y91.865
G1 X20.644 Y96.093 E.18745
G1 X20.511 Y96.226
G1 X20.746 Y95.457
G1 X20.88 Y95.324
G1 X24.11 Y92.094 E.1432
; WIPE_START
M204 S3000
G1 X22.695 Y93.508 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.443 Y94.208 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.195211
G1 F3939.837
M204 S3000
G1 X23.225 Y94.414 E.0038
G2 X22.988 Y94.669 I3.883 J3.842 E.00441
; WIPE_START
G1 X23.225 Y94.414 E-.20405
G1 X23.443 Y94.208 E-.17595
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.583 Y92.327 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; LINE_WIDTH: 0.111601
G1 F8736.127
M204 S3000
G1 X23.453 Y92.421 E.00092
; LINE_WIDTH: 0.158508
G1 F5190.856
G1 X23.323 Y92.516 E.00155
; LINE_WIDTH: 0.199835
G1 F3823.737
G1 X23.201 Y92.612 E.00202
; LINE_WIDTH: 0.235601
G1 F3113.955
G1 X23.08 Y92.708 E.00248
; LINE_WIDTH: 0.275196
G1 F2583.134
G1 X22.868 Y92.889 E.00539
; LINE_WIDTH: 0.318652
G1 F2176.027
G1 X22.656 Y93.071 E.0064
; LINE_WIDTH: 0.358542
G1 F1901.008
G2 X22.047 Y93.664 I7.259 J8.056 E.02232
; LINE_WIDTH: 0.347117
G1 F1972.407
G1 X21.856 Y93.877 E.00724
; LINE_WIDTH: 0.317163
G1 F2187.841
G1 X21.664 Y94.089 E.00652
; LINE_WIDTH: 0.282048
G1 F2509.12
G1 X21.543 Y94.239 E.00383
; LINE_WIDTH: 0.24174
G1 F3017.818
G1 X21.421 Y94.389 E.00319
; LINE_WIDTH: 0.201431
G1 F3785.234
G1 X21.3 Y94.539 E.00254
; LINE_WIDTH: 0.157987
G1 F5214.386
G1 X21.206 Y94.668 E.00153
; LINE_WIDTH: 0.111442
G1 F8756.297
G1 X21.112 Y94.798 E.00091
; WIPE_START
G1 X21.206 Y94.668 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.434 Y99.081 Z1.6 F36000
G1 X85.163 Y139.979 Z1.6
G1 Z1.2
G1 E.4 F1800
; LINE_WIDTH: 0.192631
G1 F4007.743
M204 S3000
G1 X84.738 Y140.403 E.00748
; WIPE_START
G1 X85.163 Y139.979 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X87.084 Y139.797 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; LINE_WIDTH: 0.0925996
G1 F12077.47
M204 S3000
G1 X87.057 Y139.836 E.00019
; LINE_WIDTH: 0.116116
G1 F8197.25
G1 X86.968 Y139.952 E.00089
; LINE_WIDTH: 0.154248
G1 F5389.491
G1 X86.879 Y140.068 E.00135
; LINE_WIDTH: 0.192381
G1 F4014.445
G1 X86.79 Y140.184 E.00182
; LINE_WIDTH: 0.230513
G1 F3198.418
G1 X86.701 Y140.3 E.00228
; LINE_WIDTH: 0.272132
G1 F2617.666
G1 X86.515 Y140.518 E.00548
; LINE_WIDTH: 0.31722
G1 F2187.39
G1 X86.328 Y140.737 E.00655
; LINE_WIDTH: 0.354697
G1 F1924.457
G3 X85.522 Y141.543 I-8.095 J-7.289 E.02956
; LINE_WIDTH: 0.31723
G1 F2187.31
G1 X85.303 Y141.729 E.00656
; LINE_WIDTH: 0.272101
G1 F2618.019
G1 X85.085 Y141.916 E.00548
; LINE_WIDTH: 0.225225
G1 F3291.192
G1 X84.936 Y142.03 E.00284
; LINE_WIDTH: 0.176588
G1 F4488.741
G1 X84.788 Y142.144 E.00208
; LINE_WIDTH: 0.127951
G1 F7056.273
G1 X84.639 Y142.258 E.00132
; LINE_WIDTH: 0.0958956
G1 F11326.043
G1 X84.583 Y142.298 E.0003
; OBJECT_ID: 15
; WIPE_START
G1 X84.639 Y142.258 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 7
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X78.01 Y146.041 Z1.6 F36000
G1 X47.209 Y163.615 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.627 Y163.587 E.01419
G2 X47.385 Y154.321 I-.485 J-4.624 E.46971
G2 X46.895 Y154.321 I-.242 J5.419 E.0166
G2 X47.142 Y163.613 I.248 J4.642 E.48594
G1 X47.149 Y163.613 E.00025
M204 S10000
G1 X47.23 Y164.022 F36000
G1 F1473.913
M204 S3000
G1 X47.67 Y163.992 E.01491
G2 X47.406 Y153.914 I-.527 J-5.028 E.51081
G2 X46.875 Y153.915 I-.264 J5.879 E.018
G2 X47.142 Y164.019 I.267 J5.049 E.52856
G1 X47.17 Y164.02 E.00097
M204 S250
G1 X47.251 Y164.413 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.711 Y164.381 E.01446
G2 X47.427 Y153.523 I-.569 J-5.418 E.50982
G2 X46.856 Y153.523 I-.285 J6.32 E.01791
G2 X47.142 Y164.411 I.286 J5.44 E.52764
G1 X47.191 Y164.412 E.00154
; WIPE_START
M204 S3000
G1 X47.711 Y164.381 E-.09897
G1 X48.275 Y164.299 E-.10835
G1 X48.826 Y164.152 E-.10829
G1 X49.138 Y164.039 E-.06307
G1 X49.144 Y164.036 E-.00132
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.299 Y162.898 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X50.413 Y161.784 E.05129
G2 X51.194 Y160.449 I-3.487 J-2.937 E.05057
G1 X48.628 Y163.015 E.11811
G3 X47.873 Y163.217 I-1.504 J-4.111 E.02548
G1 X51.396 Y159.694 E.16215
G2 X51.454 Y159.082 I-5.611 J-.843 E.02001
G1 X47.257 Y163.279 E.19316
G3 X46.724 Y163.259 I-.158 J-2.9 E.0174
G1 X51.434 Y158.549 E.21678
G2 X51.36 Y158.07 I-2.317 J.113 E.01581
G1 X46.245 Y163.185 E.23543
G3 X45.808 Y163.068 I.338 J-2.134 E.01473
G1 X51.243 Y157.633 E.25013
G2 X51.09 Y157.233 I-1.972 J.522 E.01398
G1 X45.407 Y162.915 E.26154
G3 X45.037 Y162.732 I.691 J-1.858 E.01347
G1 X50.906 Y156.863 E.27012
G2 X50.697 Y156.518 I-2.297 J1.159 E.01313
G1 X44.695 Y162.52 E.27624
G3 X44.378 Y162.284 I1.342 J-2.136 E.01289
G1 X50.455 Y156.207 E.27971
G2 X50.191 Y155.917 I-1.507 J1.113 E.01277
G1 X44.092 Y162.016 E.28069
G3 X43.828 Y161.727 I1.242 J-1.402 E.01277
M73 P44 R27
G1 X49.905 Y155.65 E.27971
G2 X49.588 Y155.414 I-1.658 J1.897 E.01289
G1 X43.586 Y161.416 E.27624
G3 X43.377 Y161.071 I2.083 J-1.5 E.01313
G1 X49.246 Y155.202 E.27011
G2 X48.876 Y155.018 I-1.054 J1.658 E.01346
G1 X43.193 Y160.701 E.26155
G3 X43.041 Y160.3 I1.832 J-.928 E.01398
G1 X48.475 Y154.866 E.25013
G2 X48.039 Y154.749 I-.775 J2.018 E.01473
G1 X42.923 Y159.864 E.23543
G3 X42.849 Y159.385 I2.243 J-.593 E.01581
G1 X47.559 Y154.675 E.21678
G2 X47.026 Y154.655 I-.361 J2.516 E.01741
G1 X42.829 Y158.851 E.19315
G3 X42.887 Y158.24 I5.667 J.231 E.02001
G1 X46.414 Y154.713 E.16232
G2 X45.659 Y154.914 I.58 J3.69 E.02548
G1 X43.093 Y157.481 E.11812
G3 X43.889 Y156.131 I4.137 J1.531 E.05128
G1 X44.981 Y155.039 E.05026
; OBJECT_ID: 14
; WIPE_START
G1 X43.889 Y156.131 E-.29345
G1 X43.613 Y156.493 E-.08655
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X35.988 Y156.149 Z1.6 F36000
G1 X26.751 Y155.734 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00899
G2 X25.96 Y155.595 I-.708 J3.333 E.01825
G2 X25.607 Y155.595 I-.173 J3.915 E.01197
G2 X26.839 Y155.757 I.18 J3.402 E.68233
G1 X26.809 Y155.749 E.00106
M204 S10000
G1 X26.664 Y156.133 F36000
G1 F1473.913
M204 S3000
G1 X26.562 Y156.103 E.00362
G2 X25.763 Y155.998 I-.787 J2.897 E.02733
M73 P44 R26
G1 X25.628 Y156.002 E.00458
G2 X26.86 Y156.201 I.146 J2.998 E.59585
G1 X26.721 Y156.153 E.00497
M204 S250
G1 X26.543 Y156.506 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.482 E.00271
G2 X25.765 Y156.39 I-.685 J2.518 E.02206
G1 X25.649 Y156.393 E.00364
G2 X26.719 Y156.567 I.126 J2.606 E.47984
G1 X26.6 Y156.525 E.00396
; WIPE_START
M204 S3000
G1 X26.46 Y156.482 E-.02781
G1 X26.194 Y156.422 E-.0519
G1 X25.765 Y156.39 E-.08169
G1 X25.649 Y156.393 E-.02205
G1 X25.377 Y156.422 E-.05192
G1 X25.11 Y156.479 E-.05193
G1 X24.85 Y156.563 E-.0519
G1 X24.654 Y156.651 E-.0408
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.904 Y154.321 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.537 Y154.322 E.01242
G2 X26.275 Y163.66 I.25 J4.678 E.5063
G2 X26.03 Y154.321 I-.491 J-4.66 E.47321
G1 X25.964 Y154.321 E.00225
M204 S10000
G1 X25.903 Y153.915 F36000
G1 F1473.913
M204 S3000
G1 X25.517 Y153.915 E.01309
G2 X26.318 Y164.065 I.27 J5.085 E.55036
G2 X26.052 Y153.915 I-.534 J-5.065 E.51435
G1 X25.963 Y153.915 E.00299
M204 S250
G1 X25.903 Y153.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.498 Y153.523 E.01272
G2 X26.359 Y164.455 I.289 J5.477 E.54912
G2 X26.072 Y153.523 I-.575 J-5.455 E.51313
G1 X25.963 Y153.523 E.00341
; WIPE_START
M204 S3000
G1 X25.498 Y153.523 E-.08848
G1 X25.212 Y153.545 E-.05444
G1 X24.645 Y153.635 E-.10907
G1 X24.09 Y153.784 E-.10907
G1 X23.997 Y153.819 E-.01893
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.743 Y161.448 Z1.6 F36000
G1 X23.702 Y162.699 Z1.6
G1 Z1.2
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.479326
G1 F1374.869
M204 S3000
G1 X24.079 Y162.899 E.01548
G1 X24.886 Y163.161 E.03079
G1 X25.54 Y163.253 E.02397
G2 X26.474 Y163.2 I.001 J-8.286 E.03398
G1 X27.298 Y162.982 E.03095
G1 X27.894 Y162.699 E.02393
G2 X28.651 Y162.147 I-4.09 J-6.411 E.03399
G1 X29.215 Y161.52 E.03062
G2 X29.683 Y160.71 I-6.134 J-4.081 E.03398
G1 X29.946 Y159.902 E.03081
G1 X30.038 Y159.248 E.02396
G2 X29.875 Y157.859 I-4.747 J-.145 E.05096
G1 X29.751 Y157.45 E.01549
G1 X29.488 Y156.893 E.02236
G2 X28.933 Y156.135 I-6.977 J4.524 E.03412
G1 X28.299 Y155.565 E.03092
G1 X27.74 Y155.216 E.02394
G2 X26.865 Y154.881 I-3.238 J7.154 E.03399
G2 X25.985 Y154.746 I-1.774 J8.58 E.03232
G1 X25.143 Y154.792 E.03063
G2 X23.642 Y155.322 I.924 J5.009 E.05799
G1 X22.954 Y155.822 E.03084
G2 X22.328 Y156.517 I5.155 J5.27 E.03398
G1 X21.904 Y157.253 E.03083
G1 X21.726 Y157.722 E.01821
G2 X21.531 Y158.8 I6.453 J1.725 E.03979
G1 X21.578 Y159.643 E.03063
G2 X22.085 Y161.109 I4.979 J-.903 E.05654
G2 X22.636 Y161.867 I7.059 J-4.548 E.03399
G1 X23.265 Y162.43 E.03064
G1 X23.651 Y162.668 E.01644
; WIPE_START
G1 X23.265 Y162.43 E-.08607
G1 X22.636 Y161.867 E-.16046
G1 X22.223 Y161.298 E-.13347
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.298 Y157.454 Z1.6 F36000
G1 Z1.2
G1 E.4 F1800
; LINE_WIDTH: 0.469983
G1 F1404.947
M204 S3000
G1 X22.485 Y157.069 E.01519
G1 X22.929 Y156.458 E.02682
G1 X23.52 Y155.92 E.02839
G1 X24.211 Y155.512 E.02848
G1 X24.777 Y155.311 E.02133
G1 X25.566 Y155.183 E.02838
G1 X26.166 Y155.193 E.02133
G1 X26.785 Y155.314 E.02239
G1 X27.535 Y155.605 E.02857
G3 X28.36 Y156.173 I-2.33 J4.263 E.03565
G1 X28.867 Y156.737 E.02692
G1 X29.188 Y157.248 E.02144
G1 X29.473 Y157.989 E.02819
G1 X29.603 Y158.78 E.02847
G1 X29.594 Y159.381 E.02132
G1 X29.429 Y160.16 E.0283
G1 X29.108 Y160.892 E.02837
G1 X28.642 Y161.542 E.02841
G1 X28.05 Y162.081 E.0284
G1 X27.36 Y162.488 E.02846
G1 X26.794 Y162.689 E.02133
G1 X26.005 Y162.817 E.02838
G1 X25.405 Y162.808 E.02133
G1 X24.625 Y162.643 E.02829
G1 X23.893 Y162.323 E.02837
G1 X23.241 Y161.855 E.0285
G1 X22.824 Y161.423 E.02132
G1 X22.469 Y160.895 E.02261
G3 X22.086 Y159.968 I4.272 J-2.305 E.03565
G1 X21.968 Y159.22 E.02691
G1 X21.978 Y158.619 E.02133
G1 X22.101 Y157.992 E.02268
G1 X22.277 Y157.51 E.01823
; CHANGE_LAYER
; Z_HEIGHT: 1.4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1404.947
G1 X22.101 Y157.992 E-.09756
G1 X21.978 Y158.619 E-.12138
G1 X21.968 Y159.22 E-.11411
G1 X22.006 Y159.464 E-.04696
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L7
M991 S0 P6 ;notify layer change


M204 S10000
G17
G3 Z1.6 I1.217 J0 P1  F36000
; object ids of layer 7 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer7 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.098 Y93.533
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.715 Y93.669 E.01375
G2 X230.39 Y93.357 I1.489 J3.34 E.71954
G2 X230.011 Y93.357 I-.186 J4.315 E.01283
G2 X229.256 Y93.477 I.193 J3.652 E.02594
G1 X229.154 Y93.513 E.00364
M204 S10000
G1 X229.233 Y93.915 F36000
G1 F1473.913
M204 S3000
G1 X228.881 Y94.041 E.01267
G2 X230.371 Y93.764 I1.323 J2.968 E.63944
G2 X230.033 Y93.764 I-.167 J3.839 E.01144
G2 X229.361 Y93.87 I.171 J3.246 E.02306
G1 X229.29 Y93.896 E.00256
M204 S250
G1 X229.362 Y94.28 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.292 E.00137
G2 X230.352 Y94.155 I.884 J2.718 E.53023
G2 X230.054 Y94.155 I-.148 J3.388 E.00936
G2 X229.609 Y94.214 I.15 J2.854 E.01409
G1 X229.419 Y94.265 E.00614
; WIPE_START
M204 S3000
G1 X229.319 Y94.292 E-.0197
G1 X229.04 Y94.399 E-.05686
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05688
G1 X228.181 Y94.989 E-.08528
G1 X227.889 Y95.33 E-.08527
G1 X227.834 Y95.415 E-.01911
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.15 Y92.791 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.071 Y92.827 E.00292
G2 X230.449 Y92.321 I2.133 J4.181 E.915
G2 X229.953 Y92.322 I-.244 J5.604 E.01677
G2 X228.52 Y92.627 I.251 J4.687 E.04981
G1 X228.205 Y92.767 E.01167
M204 S10000
G1 X227.985 Y92.42 F36000
G1 F1473.913
M204 S3000
G1 X227.886 Y92.464 E.00365
G2 X230.47 Y91.915 I2.317 J4.544 E.99433
G2 X229.934 Y91.915 I-.266 J6.08 E.01816
G2 X228.374 Y92.247 I.27 J5.093 E.05419
G1 X228.04 Y92.396 E.01239
M204 S250
G1 X227.825 Y92.062 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.708 Y92.115 E.00403
G2 X230.491 Y91.523 I2.495 J4.893 E.99182
G2 X229.915 Y91.523 I-.287 J6.534 E.01806
G2 X228.234 Y91.881 I.289 J5.485 E.05412
G1 X227.88 Y92.038 E.01212
; WIPE_START
M204 S3000
G1 X227.708 Y92.115 E-.03582
G1 X227.455 Y92.252 E-.05469
G1 X226.973 Y92.565 E-.10927
G1 X226.525 Y92.927 E-.10935
G1 X226.262 Y93.191 E-.07088
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.416 Y93.24 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672828
G1 F952.52
M204 S3000
G1 X228.306 Y93.287 E.00629
G2 X226.025 Y97.012 I1.897 J3.722 E.24069
G1 X226.048 Y97.449 E.02292
G1 X226.116 Y97.88 E.0229
G1 X226.23 Y98.303 E.02291
G1 X226.377 Y98.688 E.02159
G2 X228.697 Y93.113 I3.826 J-1.678 E1.02141
G1 X228.471 Y93.215 E.01301
; OBJECT_ID: 12
; WIPE_START
G1 X228.306 Y93.287 E-.03421
G1 X227.935 Y93.503 E-.08165
G1 X227.741 Y93.636 E-.04466
G1 X227.407 Y93.907 E-.08159
G1 X227.098 Y94.216 E-.08306
G1 X226.916 Y94.44 E-.05484
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.662 Y96.813 Z1.8 F36000
G1 X211.916 Y99.347 Z1.8
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.152 E.00809
G2 X208.978 Y93.12 I-3.275 J-2.13 E.27724
G2 X208.573 Y93.12 I-.199 J4.619 E.01372
G2 X211.813 Y99.483 I.206 J3.901 E.52609
G1 X211.88 Y99.395 E.00373
M204 S10000
G1 X211.587 Y99.108 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.93 E.00737
G2 X208.958 Y93.527 I-2.934 J-1.908 E.2483
G2 X208.594 Y93.527 I-.18 J4.144 E.01233
G2 X211.497 Y99.227 I.184 J3.495 E.47131
G1 X211.55 Y99.156 E.00301
M204 S250
G1 X211.27 Y98.878 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00618
G2 X208.939 Y93.919 I-2.606 J-1.694 E.20419
G2 X208.615 Y93.919 I-.161 J3.694 E.01018
G2 X211.192 Y98.98 I.163 J3.104 E.38771
G1 X211.233 Y98.926 E.00214
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.04883
G1 X211.549 Y98.436 E-.06195
G1 X211.681 Y98.139 E-.06169
G1 X211.82 Y97.671 E-.09275
G1 X211.871 Y97.35 E-.06184
G1 X211.885 Y97.072 E-.05294
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.729 Y99.427 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.968 Y99.792 E.01479
G2 X209.27 Y101.709 I3.811 J-2.768 E.16692
G2 X209.024 Y92.321 I-.494 J-4.684 E.4757
G2 X204.698 Y99.375 I-.245 J4.703 E.34201
M204 S10000
G1 X204.4 Y99.663 F36000
G1 F1473.913
M204 S3000
G1 X204.487 Y99.811 E.00578
G2 X209.312 Y102.114 I4.292 J-2.786 E.19042
G2 X209.045 Y91.915 I-.537 J-5.089 E.51683
G2 X204.219 Y99.347 I-.266 J5.11 E.36266
G1 X204.371 Y99.611 E.01032
M204 S250
G1 X204.061 Y99.859 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.158 Y100.024 E.006
G2 X209.353 Y102.504 I4.621 J-3 E.18991
G2 X209.066 Y91.523 I-.578 J-5.479 E.51544
G2 X203.87 Y99.525 I-.286 J5.502 E.36169
G1 X204.031 Y99.807 E.01019
; WIPE_START
M204 S3000
G1 X204.158 Y100.024 E-.04776
G1 X204.496 Y100.492 E-.10957
G1 X204.882 Y100.921 E-.10974
M73 P45 R26
G1 X205.31 Y101.306 E-.10941
G1 X205.325 Y101.317 E-.00353
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.068 Y99.207 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435945
G1 F1526.62
M204 S3000
G1 X205.167 Y99.376 E.00637
G2 X204.468 Y97.019 I3.611 J-2.353 E.80342
G1 X204.491 Y97.475 E.01492
G1 X204.562 Y97.921 E.01474
G1 X204.679 Y98.356 E.01473
G1 X204.829 Y98.75 E.01376
G2 X204.938 Y98.981 I3.948 J-1.727 E.00835
G1 X205.039 Y99.155 E.00658
; OBJECT_ID: 11
; WIPE_START
G1 X205.167 Y99.376 E-.04846
G1 X205.428 Y99.737 E-.08468
G1 X205.734 Y100.076 E-.0867
G1 X206.065 Y100.374 E-.08473
G1 X206.386 Y100.607 E-.07543
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X199.007 Y98.657 Z1.8 F36000
G1 X183.912 Y94.669 Z1.8
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.838 Y94.775 E.00439
G2 X187.538 Y92.885 I3.488 J2.261 E.73676
G2 X187.106 Y92.885 I-.212 J4.905 E.01461
G2 X184.093 Y94.423 I.219 J4.151 E.11792
G1 X183.948 Y94.621 E.00831
M204 S10000
G1 X184.241 Y94.908 F36000
G1 F1473.913
M204 S3000
G1 X184.179 Y94.997 E.00367
G2 X187.518 Y93.292 I3.146 J2.04 E.66459
G2 X187.128 Y93.292 I-.193 J4.43 E.01322
G2 X184.409 Y94.679 I.197 J3.745 E.10639
G1 X184.277 Y94.859 E.00759
M204 S250
G1 X184.558 Y95.138 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.21 E.00275
G2 X187.499 Y93.684 I2.817 J1.827 E.55122
G2 X187.148 Y93.684 I-.175 J3.979 E.011
G2 X184.714 Y94.925 I.176 J3.353 E.08825
G1 X184.593 Y95.09 E.00639
; WIPE_START
M204 S3000
G1 X184.507 Y95.21 E-.02809
G1 X184.255 Y95.672 E-.10014
G1 X184.129 Y96.001 E-.06685
G1 X184.038 Y96.341 E-.06681
G1 X183.983 Y96.688 E-.06682
G1 X183.968 Y96.958 E-.0513
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.443 Y92.321 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.073 Y92.322 E.01252
G2 X187.571 Y92.321 I.252 J4.714 E.98721
G1 X187.503 Y92.321 E.00232
M204 S10000
G1 X187.442 Y91.915 F36000
G1 F1473.913
M204 S3000
G1 X187.053 Y91.915 E.01317
G2 X187.593 Y91.915 I.272 J5.121 E1.07237
G1 X187.502 Y91.915 E.00305
M204 S250
G1 X187.442 Y91.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.034 Y91.523 E.01279
G2 X187.613 Y91.523 I.29 J5.512 E1.06932
G1 X187.502 Y91.523 E.00348
; WIPE_START
M204 S3000
G1 X187.034 Y91.523 E-.0889
G1 X186.46 Y91.583 E-.10972
G1 X185.895 Y91.704 E-.10985
G1 X185.537 Y91.82 E-.07154
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.504 Y92.603 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200528
G1 F3806.93
M204 S3000
G1 X187.086 Y92.6 E.00547
G2 X182.882 Y97.039 I.238 J4.435 E.08837
G1 X182.907 Y97.503 E.00609
G1 X182.973 Y97.929 E.00565
G2 X187.564 Y92.6 I4.351 J-.894 E.25936
; OBJECT_ID: 10
; WIPE_START
G1 X187.086 Y92.6 E-.09069
G1 X186.629 Y92.652 E-.08745
G1 X186.175 Y92.749 E-.08828
G1 X185.732 Y92.892 E-.08841
G1 X185.611 Y92.946 E-.02516
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.981 Y93.119 Z1.8 F36000
G1 X163.305 Y93.451 Z1.8
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.246 Y93.491 E.00241
G2 X166.067 Y92.651 I2.596 J3.561 E.83558
G2 X165.61 Y92.652 I-.225 J5.209 E.01549
G2 X163.636 Y93.237 I.232 J4.4 E.07033
G1 X163.355 Y93.419 E.01131
M204 S10000
G1 X163.527 Y93.792 F36000
G1 F1473.913
M204 S3000
G1 X163.487 Y93.819 E.00163
G2 X166.047 Y93.058 I2.355 J3.233 E.75842
G2 X165.631 Y93.058 I-.206 J4.735 E.0141
G2 X163.84 Y93.59 I.21 J3.994 E.06384
G1 X163.577 Y93.76 E.01059
M204 S250
G1 X163.74 Y94.121 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.718 Y94.136 E.00082
G2 X166.028 Y93.45 I2.122 J2.917 E.63368
G2 X165.652 Y93.45 I-.188 J4.284 E.01182
G2 X164.036 Y93.929 I.189 J3.603 E.05334
G1 X163.79 Y94.088 E.00917
; WIPE_START
M204 S3000
G1 X163.718 Y94.136 E-.01638
G1 X163.288 Y94.502 E-.10747
G1 X162.92 Y94.933 E-.10764
G1 X162.714 Y95.25 E-.07181
G1 X162.543 Y95.587 E-.07178
G1 X162.533 Y95.611 E-.00491
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.053 Y101.44 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.376 Y101.563 E.01168
G2 X166.336 Y101.77 I1.466 J-4.508 E.06721
G2 X166.088 Y92.321 I-.497 J-4.714 E.47879
G2 X163.913 Y101.385 I-.246 J4.734 E.44517
G1 X163.997 Y101.418 E.00308
M204 S10000
G1 X163.908 Y101.82 F36000
G1 F1473.913
M204 S3000
G1 X164.25 Y101.95 E.01241
G2 X166.379 Y102.175 I1.592 J-4.895 E.07298
G2 X166.11 Y91.915 I-.54 J-5.119 E.51992
G2 X163.747 Y101.757 I-.268 J5.141 E.48341
G1 X163.852 Y101.798 E.0038
M204 S250
G1 X163.766 Y102.187 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.855 Y102.226 E.00306
G2 X166.42 Y102.565 I1.987 J-5.171 E.08185
G2 X166.13 Y91.523 I-.581 J-5.509 E.51829
G2 X163.326 Y101.99 I-.288 J5.532 E.47281
G1 X163.711 Y102.163 E.01324
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.855 Y102.226 E-.02994
G1 X164.407 Y102.406 E-.11019
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.653 Y102.587 E-.01949
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.869 Y106.083 Z1.8 F36000
G1 X47.214 Y163.615 Z1.8
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.627 Y163.587 E.01402
G2 X47.385 Y154.321 I-.485 J-4.624 E.46971
G2 X46.894 Y154.321 I-.242 J5.544 E.01662
G2 X47.142 Y163.613 I.248 J4.642 E.48592
G1 X47.154 Y163.613 E.00042
M204 S10000
G1 X47.245 Y164.024 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.012 E.00544
G2 X47.406 Y153.914 I-.264 J-5.049 E.51977
G2 X46.874 Y153.915 I-.264 J6.019 E.01801
G2 X47.142 Y164.019 I.268 J5.049 E.52855
G1 X47.186 Y164.021 E.00149
M204 S250
G1 X47.256 Y164.412 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.711 Y164.381 E.01429
G2 X47.427 Y153.523 I-.569 J-5.418 E.50982
G2 X46.856 Y153.523 I-.285 J6.472 E.01792
G2 X47.142 Y164.411 I.286 J5.44 E.52764
G1 X47.196 Y164.412 E.0017
; WIPE_START
M204 S3000
G1 X47.711 Y164.381 E-.09798
G1 X48.275 Y164.299 E-.10833
G1 X48.826 Y164.152 E-.10841
G1 X49.147 Y164.029 E-.06528
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.295 Y163.264 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X46.254 Y163.172 I-.127 J-4.466 E.03544
G1 X48.476 Y154.882 E.29051
G2 X47.893 Y154.733 I-.998 J2.698 E.02039
G1 X44.378 Y155.675 E.12318
G1 X44.496 Y155.58 E.00513
G1 X43.156 Y160.58 E.17524
G3 X43.099 Y160.433 I.668 J-.341 E.00535
G1 X45.676 Y163.009 E.12332
G3 X45.528 Y162.953 I.193 J-.725 E.00535
G1 X50.532 Y161.612 E.17534
G3 X50.432 Y161.735 I-.633 J-.412 E.00535
G1 X51.375 Y158.215 E.12332
G3 X51.4 Y158.371 I-.729 J.196 E.00535
G1 X47.737 Y154.708 E.17535
G1 X47.471 Y154.68 E.00905
M204 S10000
G1 X47.268 Y154.669 F36000
G1 F1473.913
M204 S3000
G1 X45.103 Y162.752 E.28324
M204 S10000
G1 X44.739 Y162.534 F36000
G1 F1473.913
M204 S3000
G3 X44.154 Y162.057 I1.909 J-2.942 E.02561
G1 X51.276 Y160.148 E.2496
G2 X51.313 Y160.011 I-.633 J-.243 E.0048
G1 X46.097 Y154.795 E.24968
G2 X45.96 Y154.832 I.106 J.669 E.0048
G1 X44.052 Y161.955 E.2496
G3 X43.582 Y161.376 I3.241 J-3.112 E.02525
M204 S10000
G1 X43.354 Y161.007 F36000
G1 F1473.913
M204 S3000
G1 X51.439 Y158.84 E.28334
; WIPE_START
G1 X49.507 Y159.358 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.669 Y154.945 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X49.592 Y155.434 I-2.826 J6.443 E.03539
G1 X47.498 Y163.251 E.27392
G1 X47.63 Y163.237 E.00451
G1 X42.872 Y158.478 E.22778
G1 X42.858 Y158.611 E.00451
G1 X50.674 Y156.517 E.27388
G1 X50.595 Y156.409 E.00451
G1 X48.853 Y162.909 E.22778
G1 X48.975 Y162.855 E.00451
G1 X43.253 Y157.133 E.2739
G1 X43.199 Y157.255 E.00454
G1 X49.704 Y155.512 E.22798
G3 X50.475 Y156.245 I-3.115 J4.048 E.03605
M204 S10000
G1 X50.787 Y156.686 F36000
G1 F1473.913
M204 S3000
G3 X51.227 Y157.633 I-3.825 J2.352 E.03543
G1 X42.937 Y159.854 E.29051
G3 X42.844 Y158.814 I4.37 J-.913 E.03544
; WIPE_START
G1 X42.937 Y159.854 E-.19845
G1 X43.86 Y159.607 E-.18155
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.343 Y156.951 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X43.939 Y156.092 I4.431 J2.439 E.03545
G1 X50.016 Y162.169 E.2909
G3 X49.159 Y162.767 I-3.402 J-3.961 E.03545
; WIPE_START
G1 X50.016 Y162.169 E-.19868
G1 X49.342 Y161.494 E-.18132
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.8 Y161.225 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X44.884 Y155.309 E.28321
; OBJECT_ID: 14
; WIPE_START
G1 X46.298 Y156.723 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X38.675 Y156.337 Z1.8 F36000
G1 X26.748 Y155.733 Z1.8
G1 Z1.4
M73 P46 R26
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00889
G2 X25.96 Y155.595 I-.708 J3.333 E.01827
G2 X25.607 Y155.595 I-.172 J4.02 E.01195
G2 X26.839 Y155.757 I.18 J3.402 E.68233
G1 X26.806 Y155.748 E.00116
M204 S10000
G1 X26.642 Y156.126 F36000
G1 F1473.913
M204 S3000
G1 X26.409 Y156.063 E.00817
G2 X25.94 Y156.002 I-.623 J2.935 E.01605
G2 X25.628 Y156.002 I-.153 J3.544 E.01056
G2 X26.713 Y156.144 I.158 J2.996 E.60084
G1 X26.7 Y156.141 E.00044
M204 S250
G1 X26.541 Y156.504 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00692
G2 X25.921 Y156.393 I-.542 J2.551 E.01288
G2 X25.649 Y156.393 I-.135 J3.093 E.00854
G2 X26.599 Y156.52 I.137 J2.605 E.48362
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.05333
G1 X25.921 Y156.393 E-.078
G1 X25.649 Y156.393 E-.05171
G1 X25.377 Y156.422 E-.05193
G1 X25.11 Y156.479 E-.05189
G1 X24.724 Y156.616 E-.07781
G1 X24.653 Y156.654 E-.01534
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.908 Y154.321 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.536 Y154.322 E.01259
G2 X26.275 Y163.66 I.251 J4.678 E.50628
G2 X26.03 Y154.321 I-.492 J-4.66 E.47321
G1 X25.968 Y154.321 E.0021
M204 S10000
G1 X25.908 Y153.915 F36000
G1 F1473.913
M204 S3000
G1 X25.516 Y153.915 E.01325
G2 X26.318 Y164.065 I.271 J5.085 E.55035
G2 X26.052 Y153.915 I-.534 J-5.065 E.51435
G1 X25.968 Y153.915 E.00284
M204 S250
G1 X25.908 Y153.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.498 Y153.523 E.01286
G2 X26.072 Y153.523 I.288 J5.473 E1.06174
G1 X25.968 Y153.523 E.00328
; WIPE_START
M204 S3000
G1 X25.498 Y153.523 E-.08932
G1 X24.927 Y153.583 E-.10894
G1 X24.366 Y153.702 E-.10905
G1 X24.002 Y153.82 E-.07268
; WIPE_END
M73 P46 R25
G1 E-.02 F1800
M204 S10000
G1 X25.921 Y154.67 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.765 Y155.251 E.02038
M204 S10000
G1 X25.2 Y155.288 F36000
G1 F1473.913
M204 S3000
G1 X24.713 Y154.801 E.02332
G2 X24.614 Y154.827 I.077 J.483 E.00347
G1 X24.436 Y155.493 E.02332
M204 S10000
G1 X23.925 Y155.74 F36000
G1 F1473.913
M204 S3000
G1 X23.504 Y155.318 E.0202
; WIPE_START
G1 X23.925 Y155.74 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.455 Y158.856 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X21.548 Y159.896 I4.482 J.12 E.03542
G1 X22.107 Y159.746 E.01957
G1 X22.074 Y159.59 E.00541
G1 X21.786 Y160.664 E.03765
G3 X21.691 Y160.415 I1.14 J-.574 E.00905
G1 X24.374 Y163.097 E.1284
G1 X24.12 Y163 E.00919
G1 X25.207 Y162.708 E.03809
G1 X25.038 Y162.682 E.0058
G1 X24.888 Y163.242 E.01966
G2 X25.929 Y163.331 I.874 J-4.128 E.03546
M204 S10000
G1 X25.409 Y162.739 F36000
G1 F1473.913
M204 S3000
G1 X25.752 Y162.748 E.01162
G1 X26.304 Y163.3 E.02644
G1 X26.132 Y163.318 E.00585
G1 X26.292 Y162.72 E.02094
G2 X27.207 Y162.476 I-2.284 J-10.38 E.03207
G1 X27.644 Y162.913 E.02092
G1 X27.486 Y162.983 E.00585
G1 X27.688 Y162.229 E.02644
G1 X27.981 Y162.049 E.01162
M204 S10000
G1 X27.826 Y162.822 F36000
G1 F1473.913
M204 S3000
G2 X28.684 Y162.226 I-3.939 J-6.58 E.0354
G1 X28.273 Y161.815 E.01967
G1 X28.14 Y161.923 E.0058
G1 X29.226 Y161.631 E.03807
G3 X29.055 Y161.848 I-1.464 J-.987 E.00935
G1 X30.038 Y158.178 E.12859
G3 X30.081 Y158.442 I-1.232 J.337 E.00905
G1 X29.295 Y157.655 E.03765
G1 X29.344 Y157.807 E.00541
G1 X29.902 Y157.657 E.01957
G2 X29.463 Y156.711 I-5.371 J1.922 E.03536
M204 S10000
G1 X29.212 Y157.469 F36000
G1 F1473.913
M204 S3000
G2 X29.048 Y157.153 I-1.275 J.461 E.01208
G1 X29.251 Y156.398 E.02646
G3 X29.352 Y156.541 I-.629 J.553 E.00593
G1 X28.753 Y156.701 E.02099
G2 X28.084 Y156.032 I-3.048 J2.379 E.03209
G1 X28.246 Y155.43 E.0211
G3 X28.387 Y155.535 I-.593 J.953 E.00597
G1 X27.643 Y155.734 E.02609
G1 X27.328 Y155.574 E.01194
M204 S10000
G1 X28.074 Y155.321 F36000
G1 F1473.913
M204 S3000
G2 X27.128 Y154.883 I-2.336 J3.801 E.03537
G1 X26.979 Y155.438 E.01946
G1 X27.139 Y155.5 E.0058
G1 X26.344 Y154.704 E.03807
G3 X26.607 Y154.747 I-.073 J1.274 E.00905
G1 X22.943 Y155.729 E.1284
G1 X23.154 Y155.558 E.00918
G1 X22.863 Y156.645 E.03808
G1 X22.971 Y156.512 E.00578
G1 X22.564 Y156.106 E.01946
G2 X21.963 Y156.959 I3.34 J2.99 E.03541
M204 S10000
G1 X22.736 Y156.804 F36000
G1 F1473.913
M204 S3000
G1 X22.544 Y157.1 E.01196
G1 X21.801 Y157.3 E.02603
G1 X21.872 Y157.141 E.00588
G1 X22.311 Y157.579 E.02099
G2 X22.066 Y158.493 I3.585 J1.45 E.03209
G1 X21.467 Y158.653 E.02097
G1 X21.485 Y158.481 E.00585
G1 X22.036 Y159.032 E.02635
G2 X22.052 Y159.387 I1.357 J.116 E.01208
; WIPE_START
G1 X22.036 Y159.032 E-.06762
G1 X21.485 Y158.481 E-.14793
G1 X21.467 Y158.653 E-.03283
G1 X22.066 Y158.493 E-.11771
G1 X22.085 Y158.422 E-.0139
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.964 Y161.049 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.55 Y160.892 E.02052
M204 S10000
G1 X22.865 Y161.357 F36000
G1 F1473.913
M204 S3000
G1 X22.686 Y162.025 E.0234
G1 X22.761 Y162.1 E.00359
G1 X23.428 Y161.921 E.0234
M204 S10000
G1 X23.891 Y162.245 F36000
G1 F1473.913
M204 S3000
G1 X23.738 Y162.817 E.02005
; WIPE_START
G1 X23.891 Y162.245 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.468 Y161.282 Z1.8 F36000
G1 Z1.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X29.048 Y160.863 E.02008
M204 S10000
G1 X29.287 Y160.351 F36000
G1 F1473.913
M204 S3000
G1 X29.958 Y160.171 E.02353
G2 X29.985 Y160.072 I-.456 J-.175 E.00347
G1 X29.493 Y159.581 E.02353
M204 S10000
G1 X29.533 Y159.021 F36000
G1 F1473.913
M204 S3000
G1 X30.116 Y158.864 E.02042
; CHANGE_LAYER
; Z_HEIGHT: 1.6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X29.533 Y159.021 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L8
M991 S0 P7 ;notify layer change


M204 S10000
G17
G3 Z1.8 I1.217 J0 P1  F36000
; object ids of layer 8 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer8 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.153 Y93.51
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.073 Y93.531 E.00282
G2 X230.39 Y93.357 I1.132 J3.478 E.73254
G2 X230.012 Y93.357 I-.185 J4.41 E.01281
G2 X229.442 Y93.432 I.193 J3.652 E.01946
G1 X229.211 Y93.494 E.0081
M204 S10000
G1 X229.258 Y93.902 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.919 E.0021
G2 X230.37 Y93.764 I1.005 J3.091 E.65098
G2 X230.033 Y93.764 I-.166 J3.935 E.01143
G2 X229.527 Y93.831 I.171 J3.246 E.01729
G1 X229.316 Y93.887 E.00738
M204 S250
G1 X229.36 Y94.281 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.292 E.0013
G2 X230.352 Y94.155 I.884 J2.718 E.53023
G2 X230.054 Y94.155 I-.148 J3.474 E.00935
G2 X229.609 Y94.214 I.15 J2.854 E.01409
G1 X229.418 Y94.265 E.0062
; WIPE_START
M204 S3000
G1 X229.319 Y94.292 E-.01931
G1 X229.04 Y94.399 E-.05691
G1 X228.773 Y94.535 E-.05687
G1 X228.522 Y94.698 E-.05685
G1 X228.289 Y94.886 E-.05691
G1 X228.078 Y95.098 E-.05688
G1 X227.833 Y95.416 E-.07627
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.18 Y92.778 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.07 Y92.825 E.00406
G2 X230.241 Y92.316 I2.126 J4.185 E.92202
G2 X229.712 Y92.34 I-.002 J5.604 E.01792
G2 X228.519 Y92.625 I.484 J4.669 E.04163
G1 X228.235 Y92.753 E.01055
M204 S10000
G1 X228.015 Y92.406 F36000
G1 F1473.913
M204 S3000
G1 X227.885 Y92.461 E.00479
G2 X230.251 Y91.909 I2.309 J4.551 E1.00231
G2 X229.67 Y91.936 I-.018 J5.964 E.01972
G2 X228.373 Y92.244 I.524 J5.076 E.04524
G1 X228.07 Y92.382 E.01127
M204 S250
G1 X227.854 Y92.045 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.706 Y92.111 E.00508
G2 X230.262 Y91.517 I2.486 J4.901 E.99956
G2 X229.629 Y91.545 I-.032 J6.321 E.01988
G2 X227.966 Y91.988 I.564 J5.466 E.05415
G1 X227.907 Y92.018 E.00207
; WIPE_START
M204 S3000
G1 X227.706 Y92.111 E-.04215
G1 X227.455 Y92.252 E-.0547
G1 X226.972 Y92.565 E-.10931
G1 X226.525 Y92.927 E-.10929
G1 X226.285 Y93.167 E-.06455
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.496 Y93.198 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672827
G1 F952.522
M204 S3000
G2 X226.025 Y97.012 I1.707 J3.813 E.25163
G1 X226.049 Y97.457 E.02334
G1 X226.167 Y98.093 E.03389
G1 X226.383 Y98.703 E.03392
G1 X226.589 Y99.108 E.02376
G1 X226.956 Y99.641 E.03393
G1 X227.401 Y100.111 E.0339
G1 X227.754 Y100.396 E.02377
G1 X228.306 Y100.734 E.03391
G1 X228.904 Y100.983 E.03391
G1 X229.343 Y101.1 E.02376
G1 X229.985 Y101.184 E.03393
G1 X230.632 Y101.167 E.03389
G1 X231.08 Y101.096 E.02378
G1 X231.7 Y100.912 E.03389
G1 X232.285 Y100.634 E.03391
G1 X232.672 Y100.382 E.02419
G2 X228.551 Y93.174 I-2.469 J-3.37 E.63809
; OBJECT_ID: 12
; WIPE_START
G1 X227.934 Y93.503 E-.13277
G1 X227.567 Y93.77 E-.08624
G1 X227.104 Y94.21 E-.12132
G1 X226.972 Y94.372 E-.03966
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.726 Y96.769 Z2 F36000
G1 X211.911 Y99.354 Z2
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.152 E.00838
G2 X208.977 Y93.12 I-3.275 J-2.13 E.27726
G2 X208.573 Y93.12 I-.198 J4.713 E.0137
G2 X211.813 Y99.483 I.206 J3.901 E.52609
G1 X211.875 Y99.402 E.00343
M204 S10000
G1 X211.582 Y99.115 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.93 E.00765
G2 X208.958 Y93.527 I-2.934 J-1.908 E.24832
G2 X208.594 Y93.527 I-.179 J4.238 E.01232
G2 X211.497 Y99.227 I.184 J3.495 E.47132
G1 X211.545 Y99.163 E.00271
M204 S250
G1 X211.265 Y98.885 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00644
G2 X208.939 Y93.919 I-2.605 J-1.694 E.2042
G2 X208.615 Y93.919 I-.161 J3.776 E.01018
G2 X211.192 Y98.98 I.163 J3.104 E.38771
G1 X211.228 Y98.932 E.00187
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.05042
G1 X211.631 Y98.259 E-.09902
G1 X211.735 Y97.986 E-.0555
G1 X211.82 Y97.671 E-.06182
G1 X211.871 Y97.35 E-.06187
G1 X211.885 Y97.08 E-.05137
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.745 Y99.447 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.823 Y99.593 E.00558
G2 X208.815 Y92.316 I3.947 J-2.568 E.65765
G2 X208.285 Y92.341 I-.002 J5.623 E.01797
G2 X204.576 Y99.166 I.485 J4.684 E.30917
G1 X204.714 Y99.396 E.00909
M204 S10000
G1 X204.38 Y99.636 F36000
G1 F1473.913
M204 S3000
G1 X204.632 Y100.036 E.01602
G2 X208.826 Y91.909 I4.136 J-3.011 E.70514
G2 X208.243 Y91.936 I-.018 J5.973 E.01977
G2 X204.34 Y99.587 I.526 J5.089 E.34502
G1 X204.342 Y99.589 E.00011
M204 S250
G1 X204.052 Y99.849 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.314 Y100.267 E.01548
G2 X208.836 Y91.517 I4.453 J-3.243 E.70298
G2 X208.202 Y91.546 I-.032 J6.333 E.01992
G2 X203.999 Y99.783 I.565 J5.479 E.34412
G1 X204.014 Y99.802 E.00075
; WIPE_START
M204 S3000
G1 X204.314 Y100.267 E-.10517
G1 X204.683 Y100.711 E-.10966
G1 X205.091 Y101.119 E-.10957
G1 X205.311 Y101.306 E-.05485
G1 X205.314 Y101.309 E-.00074
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.062 Y99.197 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435999
G1 F1526.41
M204 S3000
G1 X205.165 Y99.371 E.0066
G2 X204.468 Y97.019 I3.612 J-2.35 E.80372
G1 X204.491 Y97.475 E.01492
G1 X204.556 Y97.886 E.01359
G2 X204.939 Y98.981 I4.222 J-.865 E.03802
G1 X205.032 Y99.145 E.00617
; OBJECT_ID: 11
; WIPE_START
G1 X205.165 Y99.371 E-.04975
G1 X205.428 Y99.737 E-.08576
G1 X205.726 Y100.068 E-.08466
G1 X205.898 Y100.231 E-.04485
G1 X206.248 Y100.514 E-.08566
G1 X206.378 Y100.598 E-.02933
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.994 Y98.665 Z2 F36000
G1 X183.885 Y94.709 Z2
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.724 Y94.961 E.01011
G2 X187.537 Y92.885 I3.601 J2.076 E.72942
G2 X187.106 Y92.885 I-.211 J5.015 E.01458
G2 X183.961 Y94.596 I.219 J4.151 E.12529
G1 X183.918 Y94.659 E.00259
M204 S10000
G1 X184.226 Y94.93 F36000
G1 F1473.913
M204 S3000
G1 X184.076 Y95.164 E.00939
G2 X187.518 Y93.292 I3.249 J1.873 E.65795
G2 X187.128 Y93.292 I-.192 J4.54 E.0132
G2 X184.29 Y94.835 I.197 J3.745 E.11303
G1 X184.259 Y94.88 E.00187
M204 S250
G1 X184.554 Y95.144 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
M73 P47 R25
G1 X184.416 Y95.36 E.00806
G2 X187.499 Y93.684 I2.909 J1.677 E.54571
G2 X187.148 Y93.684 I-.174 J4.079 E.011
G2 X184.607 Y95.065 I.176 J3.353 E.09376
G1 X184.588 Y95.094 E.00109
; WIPE_START
M204 S3000
G1 X184.416 Y95.36 E-.06022
G1 X184.255 Y95.672 E-.06678
G1 X184.129 Y96.001 E-.06686
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.968 Y96.964 E-.05252
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.404 Y92.318 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.362 Y92.316 E.0014
G2 X186.83 Y92.341 I-.002 J5.643 E.01802
G2 X187.818 Y92.342 I.486 J4.696 E.97057
G1 X187.463 Y92.322 E.01202
M204 S10000
G1 X187.426 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.373 Y91.909 E.00179
G2 X185.282 Y101.746 I-.048 J5.131 E.47608
G2 X192.031 Y99.081 I2.041 J-4.709 E.27276
G2 X187.861 Y91.937 I-4.708 J-2.041 E.32567
G1 X187.485 Y91.915 E.01272
M204 S250
G1 X187.447 Y91.52 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.383 Y91.517 E.00201
G2 X186.747 Y91.546 I-.032 J6.361 E.01998
G2 X187.901 Y91.548 I.567 J5.494 E1.05179
G1 X187.507 Y91.524 E.01239
; WIPE_START
M204 S3000
G1 X187.383 Y91.517 E-.02358
G1 X186.747 Y91.546 E-.12101
G1 X186.176 Y91.636 E-.10986
G1 X185.617 Y91.786 E-.10984
G1 X185.539 Y91.813 E-.01571
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.507 Y92.603 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200601
G1 F3805.152
M204 S3000
G1 X187.092 Y92.605 E.00544
G2 X182.882 Y97.037 I.232 J4.435 E.08839
G1 X182.889 Y97.274 E.0031
G1 X182.937 Y97.734 E.00606
G1 X183.032 Y98.181 E.00599
G1 X183.1 Y98.412 E.00316
G1 X183.178 Y98.633 E.00307
G1 X183.367 Y99.056 E.00607
G1 X183.598 Y99.457 E.00607
G1 X183.731 Y99.65 E.00308
G1 X184.022 Y100.01 E.00606
G1 X184.183 Y100.18 E.00308
G1 X184.354 Y100.342 E.00308
G1 X184.714 Y100.633 E.00607
G1 X184.907 Y100.766 E.00307
G1 X185.307 Y100.997 E.00606
G1 X185.731 Y101.185 E.00607
G1 X185.954 Y101.264 E.0031
G1 X186.399 Y101.384 E.00604
G1 X186.63 Y101.426 E.00308
G1 X186.862 Y101.457 E.00307
G1 X187.324 Y101.481 E.00607
G1 X187.787 Y101.457 E.00607
G1 X188.019 Y101.426 E.00307
G1 X188.472 Y101.33 E.00607
G1 X188.699 Y101.263 E.0031
G1 X189.129 Y101.098 E.00604
G1 X189.341 Y100.997 E.00308
G1 X189.742 Y100.765 E.00607
G1 X189.937 Y100.631 E.0031
G1 X190.295 Y100.341 E.00604
G1 X190.467 Y100.179 E.0031
G1 X190.776 Y99.835 E.00607
G1 X191.027 Y99.491 E.00558
G2 X187.567 Y92.605 I-3.704 J-2.451 E.12232
; OBJECT_ID: 10
; WIPE_START
G1 X187.092 Y92.605 E-.09024
G1 X186.629 Y92.652 E-.08839
G1 X186.175 Y92.749 E-.08825
G1 X185.731 Y92.893 E-.08878
G1 X185.614 Y92.945 E-.02434
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.983 Y93.128 Z2 F36000
G1 X163.269 Y93.48 Z2
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.066 Y93.629 E.00851
G2 X166.067 Y92.651 I2.775 J3.423 E.82793
G2 X165.61 Y92.652 I-.224 J5.318 E.01547
G2 X163.404 Y93.381 I.232 J4.4 E.07959
G1 X163.317 Y93.445 E.00363
M204 S10000
G1 X163.508 Y93.808 F36000
G1 F1473.913
M204 S3000
G1 X163.322 Y93.946 E.00782
G2 X166.047 Y93.058 I2.519 J3.107 E.75142
G2 X165.631 Y93.058 I-.205 J4.843 E.01409
G2 X163.627 Y93.722 I.21 J3.994 E.07231
G1 X163.557 Y93.773 E.00294
M204 S250
G1 X163.74 Y94.125 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.569 Y94.25 E.00664
G2 X166.028 Y93.45 I2.272 J2.803 E.62778
G2 X165.652 Y93.45 I-.187 J4.381 E.01182
G2 X163.842 Y94.049 I.189 J3.603 E.06049
G1 X163.788 Y94.089 E.0021
; WIPE_START
M204 S3000
G1 X163.569 Y94.25 E-.05163
G1 X163.288 Y94.503 E-.07181
G1 X163.035 Y94.783 E-.07177
G1 X162.813 Y95.089 E-.07181
G1 X162.624 Y95.416 E-.07177
G1 X162.535 Y95.614 E-.04121
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.075 Y101.453 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.482 E.00245
G2 X165.878 Y92.316 I1.692 J-4.427 E.561
G2 X165.345 Y92.341 I-.002 J5.656 E.01809
G2 X163.912 Y101.387 I.488 J4.714 E.42046
G1 X164.019 Y101.431 E.00392
M204 S10000
G1 X163.929 Y101.831 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.00248
G2 X165.889 Y91.909 I1.836 J-4.808 E.60887
G2 X165.302 Y91.936 I-.018 J6.015 E.01989
G2 X163.502 Y101.644 I.529 J5.119 E.44752
G1 X163.874 Y101.807 E.01374
M204 S250
G1 X163.77 Y102.189 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.23 E.00294
G2 X165.899 Y91.517 I1.976 J-5.175 E.60677
G2 X165.261 Y91.546 I-.032 J6.373 E.02003
G2 X163.323 Y101.995 I.568 J5.51 E.4462
G1 X163.715 Y102.165 E.01338
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.23 E-.02922
G1 X164.407 Y102.406 E-.11024
G1 X164.974 Y102.527 E-.11015
G1 X165.551 Y102.587 E-.11021
G1 X165.657 Y102.587 E-.02018
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.873 Y106.084 Z2 F36000
G1 X47.261 Y163.613 Z2
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.606 E.00417
G2 X47.179 Y154.316 I-.25 J-4.642 E.48437
G2 X46.655 Y154.34 I-.002 J5.561 E.01774
G2 X46.899 Y163.607 I.479 J4.624 E.47012
G1 X47.201 Y163.612 E.01025
M204 S10000
G1 X47.261 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.0049
G2 X47.189 Y153.909 I-.273 J-5.051 E.52676
G2 X46.613 Y153.935 I-.017 J5.919 E.01954
G2 X46.877 Y164.019 I.52 J5.032 E.51165
G1 X47.201 Y164.019 E.01098
M204 S250
G1 X47.261 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00518
G2 X47.2 Y153.517 I-.296 J-5.442 E.52544
G2 X46.572 Y153.545 I-.031 J6.277 E.01971
G2 X46.857 Y164.41 I.559 J5.421 E.51068
G1 X47.201 Y164.411 E.01081
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.0428
G1 X47.712 Y164.389 E-.05426
G1 X48.275 Y164.299 E-.10841
G1 X48.826 Y164.152 E-.10841
G1 X49.151 Y164.027 E-.06612
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X45.502 Y162.941 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X45.761 Y163.037 I.584 J-1.181 E.00934
G1 X50.373 Y161.801 E.16162
G2 X50.548 Y161.589 I-.921 J-.943 E.00934
; WIPE_START
G1 X50.373 Y161.801 E-.05233
G1 X48.707 Y162.247 E-.32767
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X51.407 Y158.406 Z2 F36000
G1 Z1.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X51.357 Y158.128 I-1.789 J.181 E.00956
G1 X47.977 Y154.748 E.16179
G3 X48.192 Y154.799 I-.136 J1.05 E.00751
G1 X44.142 Y155.885 E.14192
G2 X44.038 Y155.991 I.453 J.547 E.00504
G1 X50.118 Y162.07 E.29101
G2 X50.224 Y161.966 I-.441 J-.557 E.00504
G1 X51.311 Y157.911 E.14212
G2 X51.271 Y157.768 I-.701 J.119 E.00504
G1 X42.966 Y159.993 E.29101
G2 X43.003 Y160.137 I.704 J-.104 E.00504
G1 X45.972 Y163.105 E.14212
G2 X46.115 Y163.145 I.323 J-.891 E.00503
G1 X48.341 Y154.839 E.29106
G3 X49.469 Y155.348 I-1.702 J5.277 E.04197
G1 X47.349 Y163.259 E.27724
G2 X47.806 Y163.213 I.006 J-2.199 E.01559
G1 X42.896 Y158.302 E.23506
G2 X42.849 Y158.76 I2.155 J.451 E.01559
G1 X50.76 Y156.64 E.27724
G2 X50.488 Y156.262 I-1.935 J1.106 E.0158
G1 X48.687 Y162.982 E.23549
G2 X49.112 Y162.792 I-5.35 J-12.512 E.01575
G1 X43.317 Y156.996 E.27741
G2 X43.127 Y157.421 I12.29 J5.761 E.01575
G1 X49.847 Y155.62 E.23549
G3 X50.352 Y156.11 I-4.048 J4.683 E.02383
; WIPE_START
G1 X49.847 Y155.62 E-.13372
G1 X48.595 Y155.956 E-.24629
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.461 Y154.718 Z2 F36000
G1 Z1.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X47.123 Y154.665 I.936 J7.548 E.02248
G1 X44.976 Y162.679 E.28082
G3 X44.277 Y162.17 I2.171 J-3.718 E.02931
G1 X51.231 Y160.307 E.24371
G2 X51.353 Y159.851 I-33.912 J-9.278 E.01597
G1 X46.262 Y154.76 E.24368
G2 X45.8 Y154.884 I.358 J2.26 E.01622
G1 X43.938 Y161.832 E.24347
G3 X43.43 Y161.133 I3.21 J-2.87 E.02931
G1 X51.444 Y158.985 E.28084
G3 X51.385 Y159.65 I-3.191 J.049 E.02262
M204 S10000
G1 X51.163 Y160.499 F36000
G1 F1473.913
M204 S3000
G3 X50.873 Y161.098 I-5.903 J-2.484 E.02257
G1 X45.01 Y155.235 E.28067
G3 X45.606 Y154.947 I3.002 J5.452 E.02243
; WIPE_START
G1 X45.01 Y155.235 E-.12586
G1 X45.956 Y156.181 E-.25415
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X44.519 Y155.56 Z2 F36000
G1 Z1.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X44.307 Y155.736 I.73 J1.096 E.00934
G1 X43.072 Y160.348 E.16161
G2 X43.167 Y160.606 I1.276 J-.326 E.00934
; OBJECT_ID: 14
; WIPE_START
G1 X43.072 Y160.348 E-.05235
G1 X43.518 Y158.682 E-.32765
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X36.001 Y157.36 Z2 F36000
G1 X26.742 Y155.731 Z2
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00868
G2 X25.959 Y155.595 I-.708 J3.333 E.0183
G2 X25.607 Y155.595 I-.172 J4.098 E.01193
G2 X26.839 Y155.757 I.18 J3.402 E.68234
G1 X26.8 Y155.747 E.00135
M204 S10000
G1 X26.637 Y156.124 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.063 E.00797
G2 X25.94 Y156.002 I-.624 J2.935 E.01606
G2 X25.628 Y156.002 I-.153 J3.623 E.01055
G2 X26.713 Y156.144 I.158 J2.996 E.60084
G1 X26.695 Y156.14 E.00063
M204 S250
G1 X26.536 Y156.503 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00674
G2 X25.921 Y156.393 I-.542 J2.551 E.01289
G2 X25.649 Y156.393 I-.135 J3.161 E.00853
G2 X26.594 Y156.518 I.137 J2.605 E.4838
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.05224
G1 X25.921 Y156.393 E-.07801
G1 X25.649 Y156.393 E-.0517
G1 X25.243 Y156.447 E-.07782
G1 X24.979 Y156.518 E-.05193
G1 X24.724 Y156.616 E-.05188
G1 X24.647 Y156.655 E-.01642
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.869 Y154.318 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.823 Y154.316 E.00155
G2 X25.295 Y154.34 I-.001 J5.605 E.01787
G2 X26.275 Y154.342 I.483 J4.659 E.96305
G1 X25.928 Y154.322 E.01175
M204 S10000
G1 X25.891 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.833 Y153.909 E.00194
G2 X25.253 Y153.935 I-.017 J5.952 E.01967
M73 P48 R25
G2 X26.317 Y153.937 I.523 J5.065 E1.04675
G1 X25.95 Y153.916 E.01244
M204 S250
G1 X25.912 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.844 Y153.517 E.00215
G2 X25.212 Y153.545 I-.031 J6.311 E.01984
G2 X26.358 Y153.548 I.563 J5.455 E1.04433
G1 X25.972 Y153.524 E.01214
; WIPE_START
M204 S3000
G1 X25.844 Y153.517 E-.02443
G1 X25.212 Y153.545 E-.12015
G1 X24.645 Y153.635 E-.10907
G1 X24.366 Y153.702 E-.05455
G1 X24.006 Y153.819 E-.07181
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.703 Y154.763 Z2 F36000
G1 Z1.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X26.581 Y154.741 I-.162 J.57 E.00421
G1 X27.502 Y155.663 E.04409
G2 X26.843 Y155.398 I-1.779 J3.476 E.02405
G1 X26.993 Y154.84 E.01955
G1 X26.9 Y154.815 E.00326
G2 X24.749 Y155.392 I11.11 J45.764 E.07539
G1 X22.717 Y155.936 E.07121
G1 X22.659 Y156.001 E.00292
G1 X23.068 Y156.41 E.01959
G2 X22.63 Y156.968 I2.837 J2.677 E.02405
G1 X22.967 Y155.71 E.04407
G1 X22.868 Y155.8 E.00452
M204 S10000
G1 X22.523 Y156.152 F36000
G1 F1473.913
M204 S3000
G2 X21.936 Y157.005 I3.517 J3.043 E.03512
G1 X22.369 Y157.438 E.02071
G1 X22.454 Y157.271 E.00634
G1 X21.731 Y157.465 E.02535
G2 X21.511 Y158.307 I3.53 J1.373 E.02952
G1 X22.032 Y158.828 E.02497
G3 X22.049 Y158.644 I.885 J-.013 E.00628
G1 X21.459 Y158.802 E.02067
G2 X21.536 Y159.835 I5.686 J.099 E.03512
M204 S10000
G1 X21.658 Y160.312 F36000
G1 F1473.913
M204 S3000
G1 X21.7 Y160.44 E.00453
G1 X22.032 Y159.198 E.04351
G2 X22.136 Y159.885 I3.321 J-.152 E.02355
G1 X21.578 Y160.034 E.01958
G1 X21.596 Y160.119 E.00292
G1 X24.667 Y163.19 E.14699
G1 X24.751 Y163.207 E.00292
G1 X24.901 Y162.648 E.01959
G2 X25.62 Y162.744 I.81 J-3.338 E.02461
G1 X24.346 Y163.086 E.04466
G1 X24.473 Y163.127 E.00453
M204 S10000
G1 X24.95 Y163.25 F36000
G1 F1473.913
M204 S3000
G2 X25.983 Y163.326 I.934 J-5.606 E.03512
G1 X26.143 Y162.733 E.0208
G3 X25.957 Y162.753 I-.157 J-.575 E.00634
G1 X26.479 Y163.275 E.02497
G2 X27.322 Y163.049 I-.696 J-4.284 E.0296
G1 X27.514 Y162.331 E.02515
G1 X27.347 Y162.416 E.00634
G1 X27.777 Y162.846 E.02055
G2 X28.634 Y162.263 I-2.765 J-4.986 E.03512
M204 S10000
G1 X28.985 Y161.918 F36000
G1 F1473.913
M204 S3000
G1 X29.075 Y161.818 E.00452
G1 X27.817 Y162.155 E.04407
G2 X28.376 Y161.717 I-2.116 J-3.271 E.02405
G1 X28.785 Y162.127 E.01959
G1 X28.849 Y162.069 E.00292
G1 X29.973 Y157.874 E.14699
G1 X29.946 Y157.792 E.00292
G1 X29.388 Y157.942 E.01957
G2 X29.134 Y157.295 I-3.204 J.882 E.02356
G1 X30.044 Y158.204 E.04353
G2 X30.021 Y158.072 I-.852 J.078 E.00455
M204 S10000
G1 X29.883 Y157.598 F36000
G1 F1473.913
M204 S3000
G2 X29.437 Y156.664 I-4.393 J1.524 E.03512
G1 X28.846 Y156.823 E.02072
G1 X28.946 Y156.987 E.00651
G1 X29.142 Y156.256 E.0256
G2 X28.529 Y155.643 I-3.227 J2.613 E.0294
G1 X27.806 Y155.837 E.02535
G1 X27.963 Y155.939 E.00634
G1 X28.121 Y155.348 E.02071
G2 X27.187 Y154.9 I-2.266 J3.52 E.03515
; WIPE_START
G1 X28.121 Y155.348 E-.19683
G1 X27.963 Y155.939 E-.11625
G1 X27.806 Y155.837 E-.03561
G1 X27.965 Y155.794 E-.03132
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.077 Y154.723 Z2 F36000
G1 Z1.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X25.776 Y154.665 I.893 J6.491 E.02374
G1 X25.62 Y155.247 E.0204
M204 S10000
G1 X25.381 Y155.269 F36000
G1 F1473.913
M204 S3000
G1 X24.878 Y154.766 E.02409
G2 X24.454 Y154.879 I.328 J2.072 E.01489
G1 X24.271 Y155.561 E.02389
M204 S10000
G1 X24.055 Y155.67 F36000
G1 F1473.913
M204 S3000
G1 X23.629 Y155.244 E.02036
G3 X24.26 Y154.942 I2.693 J4.814 E.02369
; WIPE_START
G1 X23.629 Y155.244 E-.20429
G1 X24.055 Y155.67 E-.17571
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.436 Y161.752 Z2 F36000
G1 Z1.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.04 Y161.175 I4.352 J-3.405 E.02369
G1 X22.621 Y161.019 E.02036
M204 S10000
G1 X22.755 Y161.221 F36000
G1 F1473.913
M204 S3000
G1 X22.572 Y161.903 E.0239
G2 X22.882 Y162.213 I1.633 J-1.322 E.01489
G1 X23.564 Y162.031 E.0239
M204 S10000
G1 X23.766 Y162.164 F36000
G1 F1473.913
M204 S3000
G1 X23.611 Y162.745 E.02036
G3 X23.034 Y162.35 I2.827 J-4.746 E.02369
; WIPE_START
G1 X23.611 Y162.745 E-.20429
G1 X23.766 Y162.164 E-.17571
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.843 Y160.525 Z2 F36000
G1 Z1.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X29.541 Y161.156 I-5.103 J-2.056 E.02369
G1 X29.116 Y160.73 E.02036
M204 S10000
G1 X29.224 Y160.514 F36000
G1 F1473.913
M204 S3000
G1 X29.906 Y160.331 E.0239
G2 X30.02 Y159.907 I-1.96 J-.752 E.01489
G1 X29.521 Y159.408 E.0239
M204 S10000
G1 X29.529 Y159.168 F36000
G1 F1473.913
M204 S3000
G1 X30.121 Y159.009 E.02074
G3 X30.062 Y159.708 I-4.264 J-.01 E.02377
; CHANGE_LAYER
; Z_HEIGHT: 1.8
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X30.121 Y159.009 E-.2028
G1 X29.529 Y159.168 E-.1772
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L9
M991 S0 P8 ;notify layer change


M204 S10000
G17
G3 Z2 I1.217 J0 P1  F36000
; object ids of layer 9 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer9 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.112 Y93.524
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X228.892 Y93.596 E.00784
G2 X230.389 Y93.357 I1.312 J3.413 E.72607
G2 X230.011 Y93.357 I-.184 J4.48 E.0128
G2 X229.256 Y93.477 I.193 J3.652 E.02594
G1 X229.169 Y93.505 E.00308
M204 S10000
G1 X229.238 Y93.91 F36000
G1 F1473.913
M204 S3000
M73 P48 R24
G1 X229.038 Y93.976 E.00712
G2 X230.37 Y93.763 I1.166 J3.034 E.64522
G2 X230.033 Y93.764 I-.166 J3.999 E.01142
G2 X229.361 Y93.87 I.171 J3.246 E.02306
G1 X229.295 Y93.892 E.00236
M204 S250
G1 X229.358 Y94.281 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.292 E.00125
G2 X230.352 Y94.155 I.884 J2.718 E.53023
G2 X230.054 Y94.155 I-.148 J3.544 E.00935
G2 X229.608 Y94.214 I.15 J2.854 E.01409
G1 X229.416 Y94.266 E.00626
; WIPE_START
M204 S3000
G1 X229.319 Y94.292 E-.01895
G1 X229.04 Y94.399 E-.05688
G1 X228.773 Y94.535 E-.05688
G1 X228.522 Y94.698 E-.05688
G1 X228.289 Y94.886 E-.05689
G1 X228.078 Y95.098 E-.0569
G1 X227.832 Y95.418 E-.07662
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.213 Y92.763 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.069 Y92.824 E.00527
G2 X230.249 Y92.316 I2.125 J4.188 E.92227
G2 X229.712 Y92.34 I-.019 J5.462 E.0182
G2 X228.519 Y92.625 I.483 J4.671 E.04163
G1 X228.267 Y92.739 E.00936
M204 S10000
G1 X228.047 Y92.392 F36000
G1 F1473.913
M204 S3000
G1 X227.884 Y92.461 E.00599
G2 X230.26 Y91.909 I2.309 J4.551 E1.00199
G2 X229.67 Y91.936 I-.033 J5.846 E.02
G2 X228.373 Y92.244 I.523 J5.076 E.04524
G1 X228.102 Y92.367 E.01008
M204 S250
G1 X227.887 Y92.032 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.454 Y92.249 E.01519
G2 X230.27 Y91.517 I2.742 J4.762 E.99019
G2 X229.343 Y91.583 I.145 J8.585 E.02915
G2 X227.967 Y91.989 I.852 J5.429 E.04512
G1 X227.939 Y92.003 E.00097
; WIPE_START
M204 S3000
G1 X227.454 Y92.249 E-.10347
G1 X226.973 Y92.565 E-.10931
G1 X226.525 Y92.927 E-.10934
G1 X226.31 Y93.143 E-.05788
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.477 Y93.213 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672819
G1 F952.534
M204 S3000
G1 X228.313 Y93.284 E.00936
G2 X226.025 Y97.012 I1.89 J3.726 E.24108
G1 X226.048 Y97.449 E.02292
G1 X226.115 Y97.872 E.02247
G1 X226.17 Y98.101 E.01231
G1 X226.303 Y98.509 E.02249
G1 X226.477 Y98.901 E.02246
G1 X226.589 Y99.108 E.01231
G1 X226.823 Y99.467 E.02247
G1 X227.075 Y99.78 E.02107
G2 X228.706 Y93.11 I3.127 J-2.77 E.95274
G1 X228.532 Y93.188 E.00999
; OBJECT_ID: 12
; WIPE_START
G1 X228.313 Y93.284 E-.04537
G1 X228.107 Y93.397 E-.04465
G1 X227.748 Y93.631 E-.08148
G1 X227.414 Y93.901 E-.08162
G1 X226.956 Y94.382 E-.12605
G1 X226.954 Y94.386 E-.00083
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.707 Y96.781 Z2.2 F36000
G1 X211.907 Y99.359 Z2.2
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.152 E.00858
G2 X208.977 Y93.12 I-3.275 J-2.13 E.27729
G2 X208.573 Y93.12 I-.197 J4.799 E.01368
G2 X211.813 Y99.483 I.206 J3.901 E.52609
G1 X211.871 Y99.407 E.00323
M204 S10000
G1 X211.578 Y99.12 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.93 E.00786
G2 X208.958 Y93.527 I-2.934 J-1.908 E.24833
G2 X208.594 Y93.527 I-.179 J4.319 E.0123
G2 X211.497 Y99.227 I.184 J3.495 E.47131
G1 X211.542 Y99.168 E.00251
M204 S250
G1 X211.261 Y98.89 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00663
G2 X208.939 Y93.919 I-2.606 J-1.694 E.20419
G2 X208.615 Y93.919 I-.161 J3.864 E.01017
G2 X211.192 Y98.98 I.163 J3.104 E.38771
G1 X211.225 Y98.937 E.00169
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.05158
G1 X211.619 Y98.29 E-.09268
G1 X211.735 Y97.986 E-.06185
G1 X211.82 Y97.671 E-.06186
G1 X211.871 Y97.35 E-.06182
G1 X211.884 Y97.086 E-.0502
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.713 Y99.401 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.962 Y99.797 E.01584
G2 X208.824 Y92.316 I3.807 J-2.772 E.64898
G2 X208.285 Y92.341 I-.02 J5.474 E.01826
G2 X204.676 Y99.354 I.484 J4.684 E.31646
M204 S10000
G1 X204.372 Y99.623 F36000
G1 F1473.913
M204 S3000
G1 X204.632 Y100.037 E.01656
G2 X208.834 Y91.909 I4.136 J-3.012 E.70481
G2 X208.243 Y91.936 I-.034 J5.857 E.02006
G2 X204.333 Y99.577 I.525 J5.089 E.34467
M204 S250
G1 X204.046 Y99.833 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.152 Y100.028 E.00696
G2 X208.845 Y91.517 I4.617 J-3.003 E.71187
G2 X207.916 Y91.583 I.145 J8.604 E.02922
G2 X203.863 Y99.528 I.854 J5.441 E.32589
G1 X204.015 Y99.782 E.00926
; WIPE_START
M204 S3000
G1 X204.152 Y100.028 E-.05358
G1 X204.32 Y100.263 E-.05489
G1 X204.683 Y100.711 E-.10952
G1 X205.091 Y101.119 E-.10962
G1 X205.305 Y101.292 E-.05238
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.053 Y99.182 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435983
G1 F1526.473
M204 S3000
G1 X205.164 Y99.371 E.00717
G2 X204.468 Y97.019 I3.613 J-2.349 E.80368
G1 X204.474 Y97.255 E.00771
G1 X204.521 Y97.699 E.01457
G1 X204.668 Y98.318 E.02081
G2 X204.941 Y98.985 I4.11 J-1.296 E.0236
G1 X205.024 Y99.13 E.00543
; OBJECT_ID: 11
; WIPE_START
G1 X205.164 Y99.371 E-.05306
G1 X205.428 Y99.737 E-.08579
G1 X205.727 Y100.068 E-.08466
G1 X205.898 Y100.231 E-.04486
G1 X206.244 Y100.511 E-.08473
G1 X206.363 Y100.588 E-.02691
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.979 Y98.657 Z2.2 F36000
G1 X183.884 Y94.709 Z2.2
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.724 Y94.961 E.01008
G2 X187.537 Y92.885 I3.601 J2.076 E.72944
G2 X187.106 Y92.885 I-.21 J5.099 E.01457
G2 X183.961 Y94.596 I.219 J4.151 E.12529
G1 X183.918 Y94.66 E.00262
M204 S10000
G1 X184.236 Y94.914 F36000
G1 F1473.913
M204 S3000
G1 X184.179 Y94.996 E.00339
G2 X187.517 Y93.292 I3.146 J2.04 E.66461
G2 X187.128 Y93.292 I-.192 J4.619 E.01319
G2 X184.409 Y94.679 I.197 J3.745 E.10639
G1 X184.272 Y94.866 E.00786
M204 S250
G1 X184.553 Y95.145 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.21 E.00251
G2 X187.499 Y93.684 I2.817 J1.827 E.55122
G2 X187.148 Y93.684 I-.174 J4.163 E.01099
G2 X184.714 Y94.925 I.176 J3.353 E.08826
G1 X184.589 Y95.096 E.00664
; WIPE_START
M204 S3000
G1 X184.507 Y95.21 E-.02658
G1 X184.255 Y95.672 E-.10013
G1 X184.129 Y96.001 E-.06685
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.968 Y96.965 E-.05281
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.408 Y92.318 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.371 Y92.316 E.00125
G2 X186.83 Y92.341 I-.02 J5.494 E.01831
G2 X187.818 Y92.342 I.485 J4.699 E.97115
G1 X187.468 Y92.322 E.01188
M204 S10000
G1 X187.43 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.381 Y91.909 E.00165
G2 X186.788 Y91.936 I-.034 J5.878 E.02012
M73 P49 R24
G2 X187.86 Y91.938 I.526 J5.104 E1.05485
G1 X187.49 Y91.915 E.01257
M204 S250
G1 X187.452 Y91.52 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.392 Y91.517 E.00189
G2 X186.46 Y91.583 I.145 J8.624 E.02929
G2 X187.901 Y91.548 I.856 J5.456 E1.04263
G1 X187.512 Y91.524 E.01225
; WIPE_START
M204 S3000
G1 X187.392 Y91.517 E-.02283
G1 X187.035 Y91.523 E-.0677
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10985
G1 X185.617 Y91.786 E-.05492
G1 X185.545 Y91.814 E-.01481
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.512 Y92.603 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200584
G1 F3805.559
M204 S3000
G1 X187.092 Y92.603 E.0055
G2 X182.882 Y97.039 I.232 J4.435 E.08843
G1 X182.907 Y97.502 E.00607
G1 X182.937 Y97.734 E.00308
G1 X182.98 Y97.965 E.00307
G1 X183.099 Y98.41 E.00604
G1 X183.267 Y98.848 E.00615
G1 X183.477 Y99.258 E.00604
G1 X183.599 Y99.459 E.00308
G1 X183.871 Y99.833 E.00607
G1 X184.023 Y100.012 E.00308
G1 X184.185 Y100.182 E.00307
G1 X184.527 Y100.49 E.00604
G1 X184.715 Y100.634 E.0031
G1 X185.102 Y100.885 E.00604
G1 X185.52 Y101.097 E.00615
G2 X187.572 Y92.604 I1.804 J-4.058 E.20401
; OBJECT_ID: 10
; WIPE_START
G1 X187.092 Y92.603 E-.09114
G1 X186.86 Y92.622 E-.04424
G1 X186.403 Y92.694 E-.08791
G1 X186.172 Y92.749 E-.04501
G1 X185.735 Y92.892 E-.08748
G1 X185.617 Y92.94 E-.02422
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.986 Y93.125 Z2.2 F36000
G1 X163.268 Y93.481 Z2.2
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.066 Y93.629 E.00849
G2 X166.066 Y92.651 I2.775 J3.423 E.82795
G2 X165.61 Y92.652 I-.223 J5.409 E.01545
G2 X163.44 Y93.358 I.232 J4.4 E.07814
G1 X163.317 Y93.446 E.0051
M204 S10000
G1 X163.507 Y93.81 F36000
G1 F1473.913
M204 S3000
G1 X163.322 Y93.946 E.00777
G2 X166.047 Y93.058 I2.519 J3.107 E.75143
G2 X165.631 Y93.058 I-.205 J4.929 E.01408
G2 X163.661 Y93.699 I.21 J3.994 E.07093
G1 X163.556 Y93.775 E.00437
M204 S250
G1 X163.738 Y94.127 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.569 Y94.25 E.00655
G2 X166.028 Y93.45 I2.272 J2.803 E.62778
G2 X165.652 Y93.45 I-.187 J4.473 E.01181
G2 X163.875 Y94.028 I.189 J3.603 E.05927
G1 X163.786 Y94.092 E.00341
; WIPE_START
M204 S3000
G1 X163.569 Y94.25 E-.05111
G1 X163.158 Y94.639 E-.1076
G1 X162.813 Y95.089 E-.10767
G1 X162.624 Y95.416 E-.07179
G1 X162.534 Y95.617 E-.04184
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.098 Y101.461 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.483 E.00162
G2 X165.887 Y92.316 I1.691 J-4.428 E.56069
G2 X165.345 Y92.341 I-.02 J5.515 E.01838
G2 X163.687 Y101.282 I.487 J4.715 E.41215
G1 X164.043 Y101.437 E.01316
M204 S10000
G1 X163.933 Y101.833 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.864 E.00234
G2 X165.898 Y91.909 I1.836 J-4.808 E.60857
G2 X165.302 Y91.936 I-.034 J5.89 E.02018
G2 X163.502 Y101.645 I.528 J5.12 E.44761
G1 X163.878 Y101.809 E.01388
M204 S250
G1 X163.773 Y102.191 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.855 Y102.228 E.00281
G2 X165.908 Y91.517 I1.978 J-5.173 E.60661
G2 X164.974 Y91.584 I.146 J8.655 E.02938
G2 X163.324 Y101.993 I.859 J5.472 E.43691
G1 X163.719 Y102.166 E.0135
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.855 Y102.228 E-.02841
G1 X164.407 Y102.406 E-.11022
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.661 Y102.587 E-.02101
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.877 Y106.084 Z2.2 F36000
G1 X47.267 Y163.613 Z2.2
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.611 E.00399
G2 X47.187 Y154.316 I-.252 J-4.644 E.48427
G2 X46.655 Y154.34 I-.019 J5.417 E.01803
G2 X46.898 Y163.612 I.478 J4.627 E.47045
G1 X47.207 Y163.613 E.01044
M204 S10000
G1 X47.267 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00471
G2 X47.198 Y153.909 I-.274 J-5.051 E.52637
G2 X46.613 Y153.935 I-.033 J5.792 E.01983
G2 X46.877 Y164.019 I.519 J5.032 E.51168
G1 X47.207 Y164.019 E.01117
M204 S250
G1 X47.267 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00501
G2 X47.208 Y153.517 I-.293 J-5.443 E.52539
G2 X46.289 Y153.582 I.144 J8.515 E.02891
G2 X46.857 Y164.411 I.845 J5.385 E.50161
G1 X47.207 Y164.411 E.01099
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.04175
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.1084
G1 X48.826 Y164.152 E-.1084
G1 X49.156 Y164.025 E-.06718
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.778 Y163.217 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X47.2 Y163.267 I-.527 J-2.722 E.01966
G1 X49.342 Y155.275 E.28007
G3 X49.973 Y155.733 I-2.26 J3.774 E.02642
G1 X43.068 Y157.583 E.24195
G2 X42.923 Y158.13 I7.124 J2.183 E.01914
G1 X47.979 Y163.185 E.24201
G2 X48.525 Y163.04 I-1.633 J-7.258 E.01914
G1 X50.375 Y156.136 E.24195
G3 X50.834 Y156.767 I-3.319 J2.893 E.02642
G1 X42.841 Y158.908 E.28007
G3 X42.891 Y158.331 I2.773 J-.051 E.01966
M204 S10000
G1 X43.138 Y157.392 F36000
G1 F1473.913
M204 S3000
G3 X43.39 Y156.87 I5.703 J2.435 E.01964
G1 X49.239 Y162.718 E.27998
G3 X48.717 Y162.971 I-2.953 J-5.442 E.01964
; WIPE_START
G1 X49.239 Y162.718 E-.11021
G1 X48.235 Y161.714 E-.26979
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.81 Y162.34 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X50.028 Y162.151 I-.792 J-1.132 E.0098
G1 X51.236 Y157.643 E.15797
G2 X51.132 Y157.371 I-1.348 J.358 E.00986
; WIPE_START
G1 X51.236 Y157.643 E-.05527
G1 X50.794 Y159.294 E-.32473
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X45.833 Y154.873 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X46.427 Y154.725 I1.001 J2.75 E.02076
G1 X51.38 Y159.678 E.23709
G2 X51.436 Y159.134 I-2.563 J-.54 E.01856
G1 X43.503 Y161.26 E.27801
G2 X43.826 Y161.707 I6.012 J-3.999 E.01866
G1 X45.64 Y154.936 E.23725
G2 X45.137 Y155.162 I2.7 J6.686 E.01866
G1 X50.946 Y160.972 E.2781
G2 X51.169 Y160.47 I-3.258 J-1.742 E.01859
G1 X44.402 Y162.283 E.23712
G2 X44.849 Y162.606 I4.435 J-5.674 E.01866
G1 X46.976 Y154.668 E.27815
G3 X48.007 Y154.753 I.113 J4.932 E.03508
M204 S10000
G1 X48.737 Y154.976 F36000
G1 F1473.913
M204 S3000
G2 X48.466 Y154.873 I-.632 J1.25 E.00987
G1 X43.958 Y156.08 E.15797
G2 X43.768 Y156.299 I.942 J1.01 E.0098
; WIPE_START
G1 X43.958 Y156.08 E-.05492
G1 X45.61 Y155.638 E-.32508
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X42.884 Y159.587 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X42.941 Y159.875 I1.855 J-.219 E.00994
G1 X46.241 Y163.175 E.15797
G1 X46.017 Y163.115 E.00786
G1 X50.219 Y161.971 E.14741
G1 X44.114 Y155.91 E.2912
G1 X43.001 Y160.13 E.14774
G1 X51.296 Y157.867 E.29104
G1 X48.204 Y154.803 E.14736
G1 X45.98 Y163.105 E.29093
G3 X45.025 Y162.707 I1.668 J-5.352 E.03504
; OBJECT_ID: 14
; WIPE_START
G1 X45.98 Y163.105 E-.19641
G1 X46.23 Y162.171 E-.1836
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X38.983 Y159.777 Z2.2 F36000
G1 X26.736 Y155.73 Z2.2
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00849
G2 X25.958 Y155.595 I-.708 J3.333 E.01831
G2 X25.607 Y155.595 I-.171 J4.17 E.01191
G2 X26.839 Y155.757 I.18 J3.402 E.68233
G1 X26.794 Y155.745 E.00156
M204 S10000
G1 X26.631 Y156.123 F36000
G1 F1473.913
M204 S3000
G1 X26.409 Y156.063 E.00777
G2 X25.939 Y156.002 I-.623 J2.935 E.01607
G2 X25.628 Y156.002 I-.153 J3.689 E.01053
G2 X26.713 Y156.144 I.158 J2.996 E.60084
G1 X26.689 Y156.138 E.00083
M204 S250
G1 X26.53 Y156.501 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00656
G2 X25.921 Y156.393 I-.542 J2.551 E.01289
G2 X25.649 Y156.393 I-.135 J3.234 E.00853
G2 X26.592 Y156.518 I.137 J2.605 E.48386
G1 X26.588 Y156.517 E.00013
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.05112
G1 X25.921 Y156.393 E-.07803
G1 X25.649 Y156.393 E-.05168
G1 X25.377 Y156.422 E-.05192
G1 X25.11 Y156.479 E-.0519
G1 X24.85 Y156.563 E-.05191
G1 X24.641 Y156.656 E-.04344
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.873 Y154.318 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.831 Y154.316 E.0014
G2 X25.295 Y154.34 I-.019 J5.455 E.01816
G2 X26.275 Y154.342 I.481 J4.659 E.963
G1 X25.933 Y154.322 E.01161
M204 S10000
G1 X25.895 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.842 Y153.909 E.0018
G2 X25.253 Y153.935 I-.034 J5.829 E.01996
G2 X26.317 Y153.938 I.522 J5.064 E1.0467
G1 X25.955 Y153.916 E.0123
M204 S250
G1 X25.917 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.852 Y153.517 E.00202
G2 X24.927 Y153.583 I.145 J8.567 E.02909
G2 X26.358 Y153.547 I.85 J5.417 E1.0352
G1 X25.977 Y153.524 E.012
; WIPE_START
M204 S3000
G1 X25.852 Y153.517 E-.02366
G1 X25.498 Y153.523 E-.06722
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10907
M73 P50 R24
G1 X24.011 Y153.818 E-.07093
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.641 Y154.751 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.628 Y154.668 I-.907 J4.843 E.03444
G1 X25.47 Y155.259 E.02073
G1 X25.562 Y155.25 E.00314
G1 X25.043 Y154.73 E.02485
G2 X24.294 Y154.931 I.579 J3.661 E.02631
G1 X24.103 Y155.641 E.02485
G1 X24.188 Y155.603 E.00314
G1 X23.756 Y155.171 E.02067
G2 X22.925 Y155.748 I2.158 J3.996 E.03432
M204 S10000
G1 X22.617 Y156.047 F36000
G1 F1473.913
M204 S3000
G1 X22.543 Y156.129 E.00377
G1 X23.871 Y155.773 E.04654
G2 X23.172 Y156.314 I1.644 J2.848 E.03
G1 X22.757 Y155.899 E.01986
G1 X22.341 Y157.501 E.05602
G3 X22.368 Y157.44 I.298 J.098 E.00224
G1 X21.673 Y157.627 E.02435
G2 X21.538 Y158.134 I10.085 J2.953 E.01777
G1 X22.046 Y158.642 E.02433
G3 X22.053 Y158.576 I.254 J-.009 E.00225
G1 X21.613 Y160.171 E.05602
G1 X22.171 Y160.022 E.01957
G2 X22.52 Y160.843 I3.441 J-.978 E.03029
G1 X21.542 Y159.865 E.04684
G1 X21.565 Y159.974 E.00377
M204 S10000
G1 X21.682 Y160.386 F36000
G1 F1473.913
M204 S3000
G2 X22.114 Y161.302 I4.301 J-1.468 E.03432
G1 X22.704 Y161.143 E.02069
G1 X22.652 Y161.058 E.00338
G1 X22.459 Y161.778 E.02521
G2 X23.008 Y162.326 I2.884 J-2.336 E.02631
G1 X23.722 Y162.135 E.02503
G1 X23.642 Y162.083 E.00324
G1 X23.483 Y162.674 E.02071
G2 X24.402 Y163.107 I2.656 J-4.436 E.03443
M204 S10000
G1 X24.811 Y163.222 F36000
G1 F1473.913
M204 S3000
G2 X24.925 Y163.248 I.18 J-.528 E.00397
G1 X23.958 Y162.281 E.0463
G2 X24.764 Y162.612 I1.893 J-3.466 E.02955
G1 X24.597 Y163.165 E.01956
G1 X26.231 Y162.727 E.05727
G1 X26.14 Y162.736 E.00308
G1 X26.651 Y163.247 E.02446
G2 X27.159 Y163.111 I-2.126 J-8.949 E.01779
G1 X27.346 Y162.414 E.02444
G1 X27.267 Y162.449 E.00292
G1 X28.901 Y162.011 E.05726
G1 X28.473 Y161.615 E.01974
G2 X29.008 Y160.929 I-2.598 J-2.576 E.02951
G1 X28.656 Y162.243 E.04603
G1 X28.739 Y162.168 E.00377
M204 S10000
G1 X29.037 Y161.86 F36000
G1 F1473.913
M204 S3000
G2 X29.613 Y161.027 I-4.464 J-3.699 E.03431
G1 X29.183 Y160.598 E.02055
G1 X29.14 Y160.683 E.00324
G1 X29.851 Y160.493 E.02492
G2 X30.053 Y159.74 I-4.179 J-1.523 E.0264
G1 X29.528 Y159.216 E.0251
G1 X29.526 Y159.315 E.00338
G1 X30.114 Y159.158 E.0206
G2 X30.034 Y158.145 I-4.618 J-.149 E.03447
M204 S10000
G1 X29.929 Y157.732 F36000
G1 F1473.913
M204 S3000
G2 X29.894 Y157.621 I-.549 J.108 E.00397
G1 X29.535 Y158.963 E.04704
G2 X29.512 Y158.55 I-1.58 J-.119 E.01405
; WIPE_START
G1 X29.535 Y158.963 E-.08188
G1 X29.894 Y157.621 E-.27498
G1 X29.929 Y157.732 E-.02314
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.699 Y155.768 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X27.838 Y155.858 E.00559
G1 X27.995 Y155.271 E.02056
G3 X28.502 Y155.621 I-1.754 J3.086 E.02087
M204 S10000
G1 X29.164 Y156.283 F36000
G1 F1473.913
M204 S3000
G3 X29.51 Y156.791 I-2.241 J1.899 E.02084
G1 X28.923 Y156.948 E.02059
G1 X29.012 Y157.094 E.0058
M204 S10000
G1 X29.319 Y157.73 F36000
G1 F1473.913
M204 S3000
G3 X29.426 Y158.078 I-1.598 J.683 E.01233
G1 X29.987 Y157.947 E.01948
G1 X28.806 Y156.766 E.05652
G3 X28.845 Y156.82 I-.185 J.173 E.00226
G1 X29.029 Y156.131 E.02416
G2 X28.654 Y155.756 I-1.97 J1.595 E.01798
G1 X27.965 Y155.941 E.02415
G3 X28.019 Y155.98 I-.158 J.276 E.00225
G1 X26.838 Y154.799 E.05652
G1 X26.707 Y155.361 E.01956
G3 X27.056 Y155.468 I-.33 J1.712 E.01237
M204 S10000
G1 X27.053 Y154.856 F36000
G1 F1473.913
M204 S3000
G3 X27.165 Y154.891 I-.108 J.549 E.00397
G1 X25.816 Y155.252 E.04727
G3 X26.225 Y155.27 I.138 J1.559 E.01389
; WIPE_START
G1 X25.816 Y155.252 E-.08087
G1 X27.165 Y154.891 E-.27601
G1 X27.053 Y154.856 E-.02312
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.512 Y157.158 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.437 Y157.305 E.00561
G1 X22.01 Y156.879 E.02044
G2 X21.742 Y157.435 I4.878 J2.684 E.02092
M204 S10000
G1 X21.506 Y158.335 F36000
G1 F1473.913
M204 S3000
G2 X21.451 Y158.95 I2.9 J.568 E.02095
G1 X22.042 Y158.792 E.02071
G1 X22.038 Y158.963 E.0058
; WIPE_START
G1 X22.042 Y158.792 E-.04647
G1 X21.451 Y158.95 E-.16593
G1 X21.506 Y158.335 E-.1676
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.991 Y162.752 Z2.2 F36000
G1 Z1.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X25.835 Y163.334 E.02039
G2 X26.45 Y163.279 I.047 J-2.959 E.02095
M204 S10000
G1 X27.349 Y163.038 F36000
G1 F1473.913
M204 S3000
G2 X27.909 Y162.778 I-.957 J-2.793 E.02095
G1 X27.483 Y162.352 E.02039
; CHANGE_LAYER
; Z_HEIGHT: 2
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X27.909 Y162.778 E-.18758
G1 X27.349 Y163.038 E-.19242
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L10
M991 S0 P9 ;notify layer change


M204 S10000
G17
G3 Z2.2 I1.217 J0 P1  F36000
; object ids of layer 10 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer10 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.149 Y93.511
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.072 Y93.532 E.00269
G2 X230.389 Y93.357 I1.132 J3.477 E.73256
G2 X230.012 Y93.357 I-.183 J4.613 E.01278
G2 X229.443 Y93.432 I.193 J3.652 E.01945
G1 X229.207 Y93.495 E.00825
M204 S10000
G1 X229.254 Y93.903 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.919 E.00197
G2 X230.37 Y93.763 I1.006 J3.091 E.65099
G2 X230.033 Y93.764 I-.165 J4.109 E.01141
G2 X229.527 Y93.831 I.171 J3.246 E.01729
G1 X229.312 Y93.888 E.00752
M204 S250
G1 X229.356 Y94.282 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.292 E.00118
G2 X230.352 Y94.155 I.884 J2.718 E.53024
G2 X230.054 Y94.155 I-.148 J3.629 E.00935
G2 X229.609 Y94.214 I.15 J2.854 E.01409
G1 X229.414 Y94.266 E.00632
; WIPE_START
M204 S3000
G1 X229.319 Y94.292 E-.01856
G1 X229.04 Y94.399 E-.05687
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05688
G1 X228.289 Y94.886 E-.05689
G1 X228.078 Y95.098 E-.05688
G1 X227.889 Y95.33 E-.05688
G1 X227.831 Y95.419 E-.02014
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.245 Y92.749 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.069 Y92.824 E.00647
G2 X230.258 Y92.316 I2.124 J4.188 E.92196
G2 X229.712 Y92.34 I-.035 J5.346 E.01849
G2 X228.519 Y92.624 I.481 J4.671 E.04162
G1 X228.3 Y92.724 E.00816
M204 S10000
G1 X228.08 Y92.378 F36000
G1 F1473.913
M204 S3000
G1 X227.884 Y92.46 E.00719
G2 X230.268 Y91.909 I2.308 J4.551 E1.00168
G2 X229.67 Y91.936 I-.048 J5.748 E.0203
G2 X228.373 Y92.244 I.523 J5.076 E.04524
G1 X228.134 Y92.353 E.00888
M204 S250
G1 X227.918 Y92.016 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.454 Y92.249 E.0163
G2 X230.279 Y91.517 I2.741 J4.762 E.98992
G2 X229.343 Y91.583 I.122 J8.428 E.02942
G2 X227.971 Y91.987 I.851 J5.429 E.04499
; WIPE_START
M204 S3000
G1 X227.454 Y92.249 E-.11015
G1 X226.973 Y92.565 E-.10932
G1 X226.525 Y92.927 E-.10935
M73 P50 R23
G1 X226.335 Y93.118 E-.05119
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.511 Y93.198 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672848
G1 F952.491
M204 S3000
G1 X228.305 Y93.287 E.01173
G2 X226.025 Y97.012 I1.897 J3.722 E.24069
G1 X226.048 Y97.449 E.02292
G1 X226.116 Y97.881 E.02292
G1 X226.23 Y98.303 E.02291
G1 X226.371 Y98.674 E.02079
G2 X228.697 Y93.112 I3.832 J-1.665 E1.02218
G1 X228.565 Y93.173 E.0076
; OBJECT_ID: 12
; WIPE_START
G1 X228.305 Y93.287 E-.05396
G1 X227.927 Y93.508 E-.08313
G1 X227.58 Y93.759 E-.08148
G1 X227.401 Y93.912 E-.04472
G1 X227.098 Y94.216 E-.08154
G1 X226.982 Y94.36 E-.03517
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.738 Y96.764 Z2.4 F36000
G1 X211.903 Y99.365 Z2.4
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.152 E.00882
G2 X208.977 Y93.12 I-3.275 J-2.13 E.27731
G2 X208.573 Y93.12 I-.196 J4.932 E.01367
G2 X211.813 Y99.483 I.206 J3.901 E.52606
G1 X211.867 Y99.413 E.003
M204 S10000
G1 X211.574 Y99.126 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.931 E.0081
G2 X208.957 Y93.527 I-2.934 J-1.908 E.24834
G2 X208.594 Y93.527 I-.178 J4.427 E.0123
G2 X211.497 Y99.227 I.184 J3.495 E.4713
G1 X211.538 Y99.173 E.00228
M204 S250
G1 X211.257 Y98.895 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00686
G2 X208.939 Y93.919 I-2.606 J-1.694 E.2042
G2 X208.615 Y93.919 I-.161 J3.946 E.01017
G2 X211.192 Y98.98 I.163 J3.104 E.38771
G1 X211.22 Y98.943 E.00146
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.05294
G1 X211.619 Y98.29 E-.09269
G1 X211.735 Y97.986 E-.06184
G1 X211.82 Y97.671 E-.06186
G1 X211.871 Y97.35 E-.06183
G1 X211.884 Y97.093 E-.04884
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.704 Y99.388 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.962 Y99.797 E.01635
G2 X208.832 Y92.316 I3.806 J-2.772 E.6486
G2 X208.285 Y92.341 I-.035 J5.365 E.01855
G2 X204.669 Y99.343 I.483 J4.684 E.31603
M204 S10000
G1 X204.363 Y99.61 F36000
G1 F1473.913
M204 S3000
G1 X204.631 Y100.037 E.01707
G2 X208.843 Y91.909 I4.135 J-3.012 E.70448
G2 X208.243 Y91.936 I-.048 J5.765 E.02035
G2 X204.325 Y99.565 I.524 J5.089 E.34422
M204 S250
G1 X204.039 Y99.82 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.152 Y100.028 E.00744
G2 X208.853 Y91.517 I4.617 J-3.004 E.71158
G2 X207.916 Y91.583 I.123 J8.451 E.02949
G2 X203.863 Y99.529 I.853 J5.442 E.32592
G1 X204.008 Y99.769 E.00878
; WIPE_START
M204 S3000
G1 X204.152 Y100.028 E-.05646
G1 X204.32 Y100.263 E-.05486
G1 X204.683 Y100.711 E-.1096
G1 X205.091 Y101.119 E-.10955
G1 X205.294 Y101.283 E-.04954
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.043 Y99.175 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435992
G1 F1526.441
M204 S3000
G1 X205.166 Y99.376 E.00772
G1 X205.432 Y99.741 E.01475
G1 X205.73 Y100.072 E.01457
G1 X206.061 Y100.37 E.01457
G1 X206.249 Y100.514 E.00772
G1 X206.622 Y100.757 E.01457
G1 X207.02 Y100.959 E.01457
G1 X207.238 Y101.05 E.00772
G1 X207.662 Y101.187 E.01458
G1 X208.059 Y101.273 E.01326
G2 X204.468 Y97.019 I.718 J-4.249 E.68703
G1 X204.474 Y97.255 E.00771
G1 X204.521 Y97.699 E.01457
G1 X204.613 Y98.135 E.01459
G1 X204.68 Y98.361 E.00771
G1 X204.84 Y98.777 E.01457
G1 X205.015 Y99.121 E.01261
; OBJECT_ID: 11
; WIPE_START
G1 X205.166 Y99.376 E-.05622
G1 X205.432 Y99.741 E-.08572
G1 X205.73 Y100.072 E-.08469
G1 X206.061 Y100.37 E-.08471
G1 X206.249 Y100.514 E-.04488
G1 X206.354 Y100.582 E-.02378
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.972 Y98.641 Z2.4 F36000
G1 X183.905 Y94.679 Z2.4
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.838 Y94.775 E.00397
G2 X187.536 Y92.885 I3.488 J2.261 E.73682
G2 X187.106 Y92.885 I-.21 J5.238 E.01456
G2 X184.093 Y94.423 I.219 J4.151 E.11792
G1 X183.941 Y94.63 E.00872
M204 S10000
G1 X184.234 Y94.918 F36000
G1 F1473.913
M204 S3000
G1 X184.179 Y94.996 E.00325
G2 X187.517 Y93.292 I3.146 J2.04 E.66463
G2 X187.128 Y93.292 I-.191 J4.732 E.01319
G2 X184.41 Y94.679 I.197 J3.745 E.10638
G1 X184.269 Y94.869 E.008
M204 S250
G1 X184.551 Y95.148 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.21 E.00237
G2 X187.499 Y93.684 I2.817 J1.827 E.55123
G2 X187.148 Y93.684 I-.174 J4.252 E.01099
G2 X184.714 Y94.925 I.176 J3.353 E.08825
G1 X184.586 Y95.099 E.00677
; WIPE_START
M204 S3000
G1 X184.507 Y95.21 E-.02577
G1 X184.255 Y95.673 E-.10019
G1 X184.129 Y96.001 E-.06681
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.968 Y96.97 E-.0536
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.412 Y92.318 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.379 Y92.316 E.00111
G2 X186.83 Y92.341 I-.035 J5.384 E.0186
G2 X187.818 Y92.343 I.484 J4.699 E.97113
G1 X187.472 Y92.322 E.01173
M204 S10000
G1 X187.434 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.39 Y91.909 E.00151
G2 X186.788 Y91.936 I-.048 J5.778 E.02041
G2 X187.86 Y91.938 I.525 J5.104 E1.05484
G1 X187.494 Y91.915 E.01241
M204 S250
G1 X187.456 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.4 Y91.517 E.00176
G2 X186.46 Y91.583 I.123 J8.472 E.02956
G2 X187.901 Y91.548 I.856 J5.456 E1.04263
G1 X187.516 Y91.524 E.0121
; WIPE_START
M204 S3000
G1 X187.4 Y91.517 E-.02209
G1 X187.035 Y91.523 E-.06933
G1 X186.46 Y91.583 E-.1099
G1 X185.895 Y91.704 E-.10986
G1 X185.55 Y91.816 E-.06882
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.516 Y92.603 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200603
M73 P51 R23
G1 F3805.116
M204 S3000
G1 X187.094 Y92.601 E.00554
G2 X182.882 Y97.039 I.23 J4.436 E.08849
G1 X182.907 Y97.503 E.0061
G1 X182.979 Y97.963 E.0061
G1 X183.1 Y98.412 E.00609
G1 X183.247 Y98.8 E.00544
G2 X187.576 Y92.602 I4.077 J-1.763 E.24735
; OBJECT_ID: 10
; WIPE_START
G1 X187.094 Y92.601 E-.09166
G1 X186.86 Y92.622 E-.04463
G1 X186.401 Y92.694 E-.08831
G1 X185.954 Y92.814 E-.08794
G1 X185.622 Y92.941 E-.06745
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.992 Y93.118 Z2.4 F36000
G1 X163.295 Y93.457 Z2.4
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.25 Y93.489 E.00188
G2 X166.066 Y92.651 I2.592 J3.563 E.83578
G2 X165.61 Y92.652 I-.223 J5.555 E.01545
G2 X163.636 Y93.237 I.232 J4.4 E.07033
G1 X163.346 Y93.425 E.0117
M204 S10000
G1 X163.503 Y93.813 F36000
G1 F1473.913
M204 S3000
G1 X163.322 Y93.946 E.00758
G2 X166.047 Y93.058 I2.519 J3.107 E.75143
G2 X165.631 Y93.058 I-.205 J5.049 E.01407
G2 X163.661 Y93.699 I.21 J3.994 E.07093
G1 X163.552 Y93.778 E.00457
M204 S250
G1 X163.733 Y94.13 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.569 Y94.25 E.00638
G2 X166.028 Y93.45 I2.272 J2.802 E.62778
G2 X165.652 Y93.45 I-.187 J4.568 E.01181
G2 X163.875 Y94.028 I.189 J3.603 E.05927
G1 X163.782 Y94.095 E.00359
; WIPE_START
M204 S3000
G1 X163.569 Y94.25 E-.05004
G1 X163.288 Y94.502 E-.07177
G1 X162.92 Y94.933 E-.10764
G1 X162.714 Y95.25 E-.07179
G1 X162.543 Y95.587 E-.0718
G1 X162.529 Y95.621 E-.00697
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.102 Y101.463 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.483 E.00147
G2 X165.896 Y92.316 I1.69 J-4.428 E.56032
G2 X165.345 Y92.341 I-.035 J5.399 E.01867
G2 X163.687 Y101.282 I.486 J4.715 E.41222
G1 X164.047 Y101.439 E.01331
M204 S10000
G1 X163.927 Y101.832 F36000
G1 F1473.913
M204 S3000
G1 X163.994 Y101.864 E.00253
G2 X165.906 Y91.909 I1.835 J-4.809 E.60821
G2 X165.302 Y91.936 I-.048 J5.8 E.02047
G2 X163.745 Y101.761 I.527 J5.12 E.4568
G1 X163.871 Y101.81 E.00457
M204 S250
G1 X163.777 Y102.195 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.229 E.00266
G2 X165.917 Y91.517 I1.977 J-5.174 E.6063
G2 X164.974 Y91.584 I.123 J8.498 E.02965
G2 X163.586 Y102.118 I.858 J5.472 E.44606
G1 X163.721 Y102.172 E.00455
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.229 E-.02753
G1 X164.407 Y102.406 E-.11022
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.666 Y102.587 E-.02188
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.882 Y106.084 Z2.4 F36000
G1 X47.272 Y163.613 Z2.4
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.0038
G2 X47.196 Y154.316 I-.253 J-4.645 E.48393
G2 X46.655 Y154.34 I-.034 J5.307 E.01831
G2 X46.898 Y163.613 I.477 J4.627 E.47053
G1 X47.212 Y163.613 E.01063
M204 S10000
G1 X47.272 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00453
G2 X47.206 Y153.909 I-.275 J-5.051 E.52602
G2 X46.613 Y153.935 I-.047 J5.7 E.02012
G2 X46.877 Y164.019 I.518 J5.032 E.51174
G1 X47.212 Y164.019 E.01135
M204 S250
G1 X47.272 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00484
G2 X47.217 Y153.517 I-.294 J-5.443 E.52508
G2 X46.289 Y153.582 I.121 J8.364 E.02918
G2 X46.857 Y164.411 I.844 J5.385 E.50164
G1 X47.212 Y164.411 E.01116
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.04071
G1 X47.994 Y164.351 E-.10845
G1 X48.553 Y164.233 E-.10842
G1 X48.826 Y164.152 E-.0542
G1 X49.161 Y164.023 E-.06823
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.054 Y163.266 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X49.215 Y155.202 E.28259
M204 S10000
G1 X49.395 Y155.306 F36000
G1 F1473.913
M204 S3000
G3 X50.098 Y155.846 I-2.465 J3.934 E.03006
G1 X43.021 Y157.742 E.248
G2 X42.961 Y157.967 I1.04 J.399 E.0079
G1 X48.141 Y163.148 E.248
G2 X48.366 Y163.088 I-.174 J-1.099 E.0079
G1 X50.263 Y156.011 E.248
G3 X50.803 Y156.714 I-3.395 J3.169 E.03006
M204 S10000
G1 X50.907 Y156.893 F36000
G1 F1473.913
M204 S3000
G1 X42.843 Y159.054 E.28259
; WIPE_START
G1 X44.775 Y158.537 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.03 Y154.667 Z2.4 F36000
G1 Z2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X48.067 Y154.766 I-.578 J11.59 E.0353
G1 X45.844 Y163.064 E.29079
G3 X44.896 Y162.633 I1.335 J-4.193 E.03534
; WIPE_START
G1 X45.844 Y163.064 E-.19793
G1 X46.092 Y162.138 E-.18207
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.476 Y161.213 Z2.4 F36000
G1 Z2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X43.041 Y160.266 I5.867 J-3.271 E.03532
G1 X51.339 Y158.042 E.29079
G2 X51.21 Y157.581 I-2.257 J.381 E.01623
G1 X48.523 Y154.894 E.12864
G1 X48.691 Y154.959 E.00611
G1 X43.787 Y156.273 E.17185
G3 X43.907 Y156.136 I.708 J.504 E.00616
G1 X42.924 Y159.807 E.12864
G1 X42.895 Y159.629 E.00611
G1 X46.479 Y163.213 E.17157
G1 X46.301 Y163.185 E.00611
G1 X49.972 Y162.201 E.12864
G3 X49.836 Y162.321 I-.639 J-.586 E.00616
G1 X51.152 Y157.409 E.17214
G1 X51.04 Y157.157 E.00935
; WIPE_START
G1 X51.152 Y157.409 E-.05249
G1 X50.706 Y159.074 E-.32751
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X51.381 Y158.241 Z2.4 F36000
G1 Z2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X51.428 Y159.282 I-6.284 J.809 E.03532
G1 X43.586 Y161.384 E.27484
G1 X43.717 Y161.565 E.00757
G1 X45.475 Y155.005 E.22988
G1 X45.271 Y155.096 E.00757
G1 X51.013 Y160.838 E.27488
G1 X51.104 Y160.634 E.00757
G1 X44.544 Y162.391 E.22988
G1 X44.725 Y162.523 E.00757
G1 X46.827 Y154.679 E.27488
G1 X46.604 Y154.702 E.00757
G1 X51.407 Y159.506 E.22993
G3 X51.182 Y160.446 I-5.002 J-.702 E.03278
M204 S10000
G1 X50.919 Y161.019 F36000
G1 F1473.913
M204 S3000
G3 X50.314 Y161.866 I-3.858 J-2.116 E.03534
G1 X44.242 Y155.795 E.29064
G3 X45.09 Y155.189 I2.963 J3.252 E.03534
; WIPE_START
G1 X44.242 Y155.795 E-.19793
G1 X44.92 Y156.472 E-.18207
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.463 Y156.743 Z2.4 F36000
G1 Z2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X49.366 Y162.645 E.28254
; OBJECT_ID: 14
; WIPE_START
G1 X47.951 Y161.231 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X40.563 Y159.315 Z2.4 F36000
G1 X26.731 Y155.728 Z2.4
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00829
G2 X25.951 Y155.594 I-.709 J3.333 E.01857
G1 X25.62 Y155.594 E.01119
G2 X26.839 Y155.757 I.165 J3.403 E.68281
G1 X26.789 Y155.744 E.00176
M204 S10000
G1 X26.625 Y156.121 F36000
G1 F1473.913
M204 S3000
G1 X26.409 Y156.063 E.00757
G2 X25.935 Y156.001 I-.624 J2.935 E.01623
G1 X25.636 Y156.001 E.0101
G2 X26.713 Y156.145 I.149 J2.997 E.60113
G1 X26.683 Y156.137 E.00104
M204 S250
G1 X26.524 Y156.5 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00637
G2 X25.919 Y156.393 I-.543 J2.551 E.01294
G1 X25.652 Y156.393 E.00839
G2 X26.592 Y156.518 I.134 J2.605 E.48395
G1 X26.582 Y156.515 E.00032
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.04999
G1 X25.919 Y156.393 E-.07834
G1 X25.652 Y156.393 E-.05084
G1 X25.243 Y156.447 E-.07835
G1 X24.979 Y156.518 E-.05189
G1 X24.724 Y156.616 E-.05192
G1 X24.637 Y156.662 E-.01867
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.877 Y154.318 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.84 Y154.316 E.00126
G2 X25.295 Y154.34 I-.034 J5.344 E.01845
G2 X26.275 Y154.342 I.48 J4.659 E.96299
G1 X25.937 Y154.322 E.01147
M204 S10000
G1 X25.899 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.85 Y153.909 E.00166
G2 X25.253 Y153.935 I-.048 J5.736 E.02025
G2 X26.317 Y153.938 I.521 J5.065 E1.04678
G1 X25.959 Y153.916 E.01214
M204 S250
G1 X25.921 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.861 Y153.517 E.0019
G2 X24.927 Y153.583 I.122 J8.414 E.02935
G2 X26.358 Y153.548 I.85 J5.418 E1.03532
G1 X25.981 Y153.524 E.01185
; WIPE_START
M204 S3000
G1 X25.861 Y153.517 E-.02293
G1 X25.498 Y153.523 E-.06883
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10909
G1 X24.015 Y153.816 E-.07003
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.682 Y154.667 Z2.4 F36000
G1 Z2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X26.72 Y154.767 I-.623 J11.906 E.03529
G1 X26.569 Y155.33 E.01972
G2 X26.269 Y155.277 I-.397 J1.387 E.01032
G1 X27.389 Y154.977 E.03925
G2 X27.111 Y154.872 I-.638 J1.268 E.01007
G1 X29.913 Y157.674 E.13412
G2 X29.808 Y157.396 I-1.372 J.36 E.01007
G1 X29.508 Y158.516 E.03924
G2 X29.456 Y158.216 I-1.452 J.1 E.01031
G1 X30.018 Y158.066 E.01972
G3 X30.116 Y159.103 I-12.918 J1.745 E.03529
M204 S10000
G1 X29.529 Y158.718 F36000
G1 F1473.913
M204 S3000
G3 X29.533 Y159.021 I-1.147 J.166 E.01027
G1 X30.083 Y159.571 E.02631
G2 X30.106 Y159.306 I-1.67 J-.277 E.00898
G1 X29.511 Y159.466 E.02083
G3 X29.246 Y160.461 I-4.004 J-.536 E.03495
G1 X29.681 Y160.896 E.02086
G1 X29.789 Y160.656 E.00891
G1 X29.053 Y160.853 E.02576
G3 X28.886 Y161.116 I-1.251 J-.609 E.0106
M204 S10000
G1 X29.587 Y161.076 F36000
G1 F1473.913
M204 S3000
G3 X28.981 Y161.923 I-3.872 J-2.132 E.03532
G1 X28.576 Y161.517 E.0194
G2 X28.767 Y161.281 I-1.048 J-1.046 E.01031
G1 X28.466 Y162.405 E.03938
G2 X28.686 Y162.215 I-.792 J-1.141 E.00985
G1 X24.868 Y163.238 E.13378
G2 X25.163 Y163.286 I.451 J-1.856 E.01011
G1 X24.345 Y162.468 E.03914
G1 X24.628 Y162.575 E.01022
G1 X24.479 Y163.129 E.01941
G3 X23.531 Y162.699 I1.34 J-4.213 E.03532
M204 S10000
G1 X24.161 Y162.382 F36000
G1 F1473.913
M204 S3000
G3 X23.881 Y162.239 I.495 J-1.307 E.01067
G1 X23.146 Y162.436 E.02576
G1 X23.359 Y162.59 E.00891
G1 X23.519 Y161.994 E.02089
G3 X22.791 Y161.266 I2.424 J-3.152 E.03493
G1 X22.195 Y161.426 E.02089
G1 X22.35 Y161.639 E.00891
G1 X22.547 Y160.904 E.02576
G3 X22.404 Y160.63 I1.234 J-.818 E.01047
M204 S10000
G1 X22.086 Y161.254 F36000
G1 F1473.913
M204 S3000
G3 X21.652 Y160.307 I5.867 J-3.262 E.0353
G1 X22.219 Y160.155 E.01987
G1 X22.322 Y160.445 E.01039
G1 X21.499 Y159.622 E.03936
G2 X21.547 Y159.915 I1.42 J-.082 E.01007
G1 X22.57 Y156.099 E.13373
G2 X22.38 Y156.319 I.953 J1.013 E.00985
G1 X23.504 Y156.018 E.03938
G2 X23.268 Y156.21 I.81 J1.239 E.01031
G1 X22.863 Y155.804 E.01941
G3 X23.709 Y155.198 I2.978 J3.264 E.03532
M204 S10000
G1 X23.669 Y155.899 F36000
G1 F1473.913
M204 S3000
G3 X23.933 Y155.732 I.932 J1.176 E.01059
G1 X24.13 Y154.997 E.02576
G1 X23.889 Y155.104 E.00891
G1 X24.326 Y155.54 E.02089
G3 X25.317 Y155.282 I1.378 J3.262 E.03481
G1 X25.479 Y154.678 E.02119
G1 X25.218 Y154.705 E.00891
G1 X25.758 Y155.246 E.02588
G3 X26.067 Y155.256 I.105 J1.484 E.01047
; WIPE_START
G1 X25.758 Y155.246 E-.05865
M73 P52 R23
G1 X25.218 Y154.705 E-.14527
G1 X25.479 Y154.678 E-.05
G1 X25.317 Y155.282 E-.11893
G1 X25.281 Y155.292 E-.00715
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.868 Y155.202 Z2.4 F36000
G1 Z2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X27.713 Y155.777 E.02016
M204 S10000
G1 X28.105 Y156.049 F36000
G1 F1473.913
M204 S3000
G1 X28.78 Y155.869 E.02363
G3 X28.916 Y156.006 I-.582 J.719 E.00656
G1 X28.736 Y156.68 E.02363
M204 S10000
G1 X29.008 Y157.072 F36000
G1 F1473.913
M204 S3000
G1 X29.585 Y156.917 E.0202
; WIPE_START
G1 X29.008 Y157.072 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.034 Y162.702 Z2.4 F36000
G1 Z2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X27.612 Y162.281 E.02016
M204 S10000
G1 X27.181 Y162.481 F36000
G1 F1473.913
M204 S3000
G1 X27 Y163.158 E.02372
G1 X26.812 Y163.208 E.00658
G1 X26.321 Y162.717 E.02349
M204 S10000
G1 X25.845 Y162.75 F36000
G1 F1473.913
M204 S3000
G1 X25.689 Y163.331 E.02037
; WIPE_START
G1 X25.845 Y162.75 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.454 Y159.096 Z2.4 F36000
G1 Z2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.038 Y158.939 E.02048
M204 S10000
G1 X22.07 Y158.466 F36000
G1 F1473.913
M204 S3000
G1 X21.577 Y157.973 E.0236
G1 X21.627 Y157.785 E.00658
G1 X22.301 Y157.605 E.02359
M204 S10000
G1 X22.504 Y157.173 F36000
G1 F1473.913
M204 S3000
G1 X22.083 Y156.752 E.02016
; CHANGE_LAYER
; Z_HEIGHT: 2.2
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X22.504 Y157.173 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L11
M991 S0 P10 ;notify layer change


M204 S10000
G17
G3 Z2.4 I1.217 J0 P1  F36000
; object ids of layer 11 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer11 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.09 Y93.536
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X228.715 Y93.669 E.01349
G2 X230.389 Y93.357 I1.49 J3.34 E.71959
G2 X230.012 Y93.357 I-.183 J4.689 E.01277
G2 X229.256 Y93.477 I.193 J3.652 E.02594
G1 X229.147 Y93.516 E.00392
M204 S10000
G1 X229.252 Y93.904 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.919 E.0019
G2 X230.37 Y93.763 I1.006 J3.09 E.651
G2 X230.033 Y93.764 I-.165 J4.197 E.0114
G2 X229.527 Y93.831 I.171 J3.246 E.01729
G1 X229.31 Y93.888 E.00759
M204 S250
G1 X229.354 Y94.282 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.292 E.00112
G2 X230.351 Y94.155 I.884 J2.718 E.53024
G2 X230.054 Y94.155 I-.148 J3.717 E.00934
G2 X229.609 Y94.214 I.15 J2.854 E.01409
G1 X229.412 Y94.267 E.00639
; WIPE_START
M204 S3000
G1 X229.319 Y94.292 E-.01817
G1 X229.04 Y94.399 E-.05688
G1 X228.773 Y94.535 E-.05688
G1 X228.521 Y94.698 E-.05711
G1 X228.289 Y94.886 E-.05666
G1 X228.078 Y95.098 E-.05687
G1 X227.83 Y95.421 E-.07742
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.278 Y92.734 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.069 Y92.823 E.00769
G2 X230.266 Y92.316 I2.124 J4.188 E.92166
G2 X229.712 Y92.34 I-.049 J5.26 E.01878
G2 X228.519 Y92.624 I.481 J4.671 E.04163
G1 X228.333 Y92.709 E.00693
M204 S10000
G1 X228.113 Y92.363 F36000
G1 F1473.913
M204 S3000
G1 X227.885 Y92.462 E.00841
G2 X230.277 Y91.909 I2.31 J4.55 E1.00134
G2 X229.405 Y91.97 I.104 J7.77 E.02961
G2 X228.373 Y92.245 I.79 J5.041 E.03619
G1 X228.167 Y92.338 E.00765
M204 S250
G1 X227.95 Y91.999 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.453 Y92.249 E.01743
G2 X230.287 Y91.518 I2.741 J4.763 E.98964
G2 X229.343 Y91.583 I.101 J8.294 E.02968
G2 X228.003 Y91.972 I.851 J5.429 E.04387
; WIPE_START
M204 S3000
G1 X227.453 Y92.249 E-.11695
G1 X226.973 Y92.565 E-.10933
G1 X226.525 Y92.927 E-.1093
G1 X226.356 Y93.088 E-.04442
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.496 Y93.198 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672846
G1 F952.493
M204 S3000
G2 X226.025 Y97.012 I1.707 J3.813 E.25166
G1 X226.048 Y97.449 E.02292
G1 X226.118 Y97.888 E.02332
G1 X226.232 Y98.31 E.02291
G1 X226.477 Y98.901 E.03348
G1 X226.699 Y99.287 E.02333
G1 X226.956 Y99.641 E.02293
G1 X227.249 Y99.966 E.02288
G1 X227.574 Y100.258 E.02291
G1 X227.928 Y100.516 E.02293
G1 X228.306 Y100.734 E.02288
G1 X228.706 Y100.912 E.0229
G1 X229.13 Y101.049 E.02335
G1 X229.55 Y101.138 E.02248
G1 X229.993 Y101.184 E.02333
G1 X230.43 Y101.183 E.02292
G1 X231.028 Y101.106 E.03158
G2 X228.551 Y93.174 I-.825 J-4.095 E.7329
; OBJECT_ID: 12
; WIPE_START
G1 X227.928 Y93.507 E-.13427
G1 X227.414 Y93.901 E-.12307
G1 X227.093 Y94.222 E-.08615
G1 X226.976 Y94.374 E-.03651
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.731 Y96.775 Z2.6 F36000
G1 X211.898 Y99.371 Z2.6
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.152 E.00909
G2 X208.976 Y93.12 I-3.275 J-2.13 E.27733
G2 X208.573 Y93.12 I-.196 J5.013 E.01365
G2 X211.813 Y99.483 I.206 J3.901 E.52607
G1 X211.862 Y99.419 E.00272
M204 S10000
G1 X211.569 Y99.132 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.931 E.00836
G2 X208.957 Y93.527 I-2.934 J-1.908 E.24836
G2 X208.594 Y93.527 I-.178 J4.521 E.01229
G2 X211.497 Y99.227 I.184 J3.495 E.4713
G1 X211.533 Y99.18 E.002
M204 S250
G1 X211.252 Y98.902 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.0071
G2 X208.939 Y93.919 I-2.605 J-1.694 E.20421
G2 X208.615 Y93.919 I-.161 J4.041 E.01016
G2 X211.192 Y98.98 I.163 J3.104 E.38771
M73 P52 R22
G1 X211.216 Y98.949 E.00121
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.05444
G1 X211.619 Y98.29 E-.09272
G1 X211.735 Y97.986 E-.06184
G1 X211.82 Y97.671 E-.06183
G1 X211.871 Y97.35 E-.06185
G1 X211.884 Y97.101 E-.04732
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.722 Y99.408 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.821 Y99.594 E.00713
G2 X208.841 Y92.316 I3.946 J-2.569 E.65665
G2 X208.285 Y92.341 I-.049 J5.272 E.01884
G2 X204.573 Y99.166 I.482 J4.684 E.30929
G1 X204.691 Y99.357 E.00758
M204 S10000
G1 X204.37 Y99.611 F36000
G1 F1473.913
M204 S3000
G1 X204.481 Y99.815 E.00784
G2 X208.852 Y91.909 I4.288 J-2.79 E.71336
G2 X207.977 Y91.971 I.105 J7.789 E.02969
G2 X204.213 Y99.35 I.792 J5.054 E.3268
G1 X204.339 Y99.56 E.00829
M204 S250
G1 X204.031 Y99.807 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.152 Y100.029 E.00791
G2 X208.862 Y91.518 I4.617 J-3.004 E.71128
G2 X207.916 Y91.583 I.101 J8.313 E.02975
G2 X203.863 Y99.529 I.853 J5.442 E.32593
G1 X204 Y99.756 E.00832
; WIPE_START
M204 S3000
G1 X204.152 Y100.029 E-.05934
G1 X204.32 Y100.263 E-.05481
G1 X204.683 Y100.711 E-.10962
G1 X205.091 Y101.119 E-.10955
G1 X205.282 Y101.274 E-.04669
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.038 Y99.155 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435995
G1 F1526.426
M204 S3000
G1 X205.167 Y99.376 E.00836
G2 X204.468 Y97.025 I3.61 J-2.354 E.80368
G1 X204.491 Y97.475 E.01475
G1 X204.562 Y97.921 E.01474
G1 X204.679 Y98.356 E.01473
G1 X204.821 Y98.731 E.0131
G2 X204.938 Y98.98 I3.956 J-1.709 E.00901
G1 X205.008 Y99.103 E.00462
; OBJECT_ID: 11
; WIPE_START
G1 X205.167 Y99.376 E-.05997
G1 X205.428 Y99.737 E-.08465
G1 X205.73 Y100.072 E-.08571
G1 X206.065 Y100.374 E-.08565
G1 X206.338 Y100.572 E-.06402
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.955 Y98.634 Z2.6 F36000
G1 X183.902 Y94.682 Z2.6
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.838 Y94.775 E.00383
G2 X187.536 Y92.885 I3.488 J2.261 E.73684
G2 X187.106 Y92.885 I-.209 J5.338 E.01454
G2 X184.094 Y94.423 I.219 J4.151 E.11791
G1 X183.938 Y94.634 E.00888
M204 S10000
G1 X184.231 Y94.921 F36000
G1 F1473.913
M204 S3000
G1 X184.179 Y94.997 E.0031
G2 X187.517 Y93.292 I3.146 J2.04 E.66463
G2 X187.128 Y93.292 I-.191 J4.846 E.01318
G2 X184.41 Y94.679 I.197 J3.745 E.10638
G1 X184.267 Y94.873 E.00815
M204 S250
G1 X184.548 Y95.151 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.21 E.00224
G2 X187.499 Y93.684 I2.817 J1.827 E.55123
G2 X187.148 Y93.684 I-.174 J4.366 E.01099
G2 X184.714 Y94.925 I.176 J3.353 E.08825
G1 X184.584 Y95.103 E.00691
; WIPE_START
M204 S3000
G1 X184.507 Y95.21 E-.02496
G1 X184.33 Y95.514 E-.06679
G1 X184.207 Y95.788 E-.0572
G1 X184.129 Y96 E-.04284
G1 X184.038 Y96.341 E-.06705
G1 X183.983 Y96.688 E-.06681
G1 X183.968 Y96.974 E-.05436
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.416 Y92.318 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.388 Y92.316 E.00097
G2 X186.83 Y92.341 I-.049 J5.299 E.0189
G2 X187.818 Y92.343 I.484 J4.699 E.97112
G1 X187.476 Y92.322 E.01158
M204 S10000
G1 X187.439 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.399 Y91.909 E.00138
G2 X186.521 Y91.971 I.105 J7.815 E.02978
G2 X187.86 Y91.938 I.795 J5.068 E1.04566
G1 X187.499 Y91.915 E.01225
M204 S250
G1 X187.461 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.409 Y91.518 E.00165
G2 X186.46 Y91.583 I.102 J8.338 E.02983
G2 X187.901 Y91.548 I.855 J5.456 E1.04263
G1 X187.521 Y91.524 E.01194
; WIPE_START
M204 S3000
G1 X187.409 Y91.518 E-.0214
G1 X187.035 Y91.523 E-.07096
G1 X186.46 Y91.583 E-.1099
G1 X186.176 Y91.636 E-.05494
G1 X185.617 Y91.786 E-.10984
G1 X185.554 Y91.81 E-.01296
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.522 Y92.603 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200621
G1 F3804.672
M204 S3000
G1 X187.092 Y92.605 E.00564
G2 X182.882 Y97.039 I.231 J4.435 E.08844
G1 X182.907 Y97.506 E.00613
G1 X182.937 Y97.736 E.00304
G1 X183.033 Y98.187 E.00605
G1 X183.177 Y98.631 E.00612
G1 X183.367 Y99.056 E.0061
G1 X183.6 Y99.46 E.00613
G1 X183.871 Y99.833 E.00603
G1 X184.022 Y100.01 E.00306
G1 X184.352 Y100.34 E.00612
G1 X184.713 Y100.633 E.0061
G1 X185.105 Y100.887 E.00612
G1 X185.31 Y100.998 E.00305
G1 X185.73 Y101.185 E.00604
G1 X186.175 Y101.33 E.00613
G1 X186.629 Y101.426 E.00609
G1 X187.094 Y101.475 E.00613
G1 X187.326 Y101.481 E.00305
G1 X187.787 Y101.457 E.00604
G1 X188.248 Y101.384 E.00613
G1 X188.707 Y101.26 E.00623
G2 X187.582 Y92.606 I-1.383 J-4.221 E.16113
; OBJECT_ID: 10
; WIPE_START
G1 X187.092 Y92.605 E-.09309
G1 X186.858 Y92.622 E-.04467
G1 X186.403 Y92.694 E-.08754
G1 X185.95 Y92.815 E-.08915
G1 X185.627 Y92.939 E-.06556
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.997 Y93.117 Z2.6 F36000
G1 X163.291 Y93.461 Z2.6
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.25 Y93.489 E.00168
G2 X166.065 Y92.651 I2.592 J3.563 E.8358
G2 X165.61 Y92.652 I-.222 J5.662 E.01543
G2 X163.636 Y93.237 I.232 J4.4 E.07032
G1 X163.341 Y93.428 E.0119
M204 S10000
G1 X163.512 Y93.802 F36000
G1 F1473.913
M204 S3000
G1 X163.489 Y93.818 E.00097
G2 X166.046 Y93.058 I2.353 J3.234 E.75854
G2 X165.631 Y93.058 I-.204 J5.17 E.01406
G2 X163.84 Y93.59 I.21 J3.994 E.06383
G1 X163.562 Y93.769 E.01118
M204 S250
G1 X163.725 Y94.13 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.719 Y94.135 E.00025
G2 X166.028 Y93.45 I2.122 J2.918 E.63372
G2 X165.652 Y93.45 I-.187 J4.69 E.01181
G2 X164.036 Y93.929 I.189 J3.603 E.05334
M73 P53 R22
G1 X163.776 Y94.098 E.00971
; WIPE_START
M204 S3000
G1 X163.719 Y94.135 E-.01291
G1 X163.288 Y94.502 E-.10766
G1 X163.035 Y94.783 E-.07177
G1 X162.813 Y95.089 E-.07181
G1 X162.624 Y95.416 E-.07178
G1 X162.529 Y95.628 E-.04407
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.086 Y101.458 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.484 E.00203
G2 X165.904 Y92.316 I1.69 J-4.428 E.55997
G2 X165.345 Y92.341 I-.049 J5.314 E.01896
G2 X163.911 Y101.389 I.485 J4.715 E.42067
G1 X164.031 Y101.436 E.00435
M204 S10000
G1 X163.941 Y101.836 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.862 E.00205
G2 X165.915 Y91.909 I1.837 J-4.807 E.60803
G2 X165.035 Y91.971 I.105 J7.835 E.02987
G2 X163.503 Y101.644 I.797 J5.084 E.43832
G1 X163.886 Y101.812 E.01417
M204 S250
G1 X163.781 Y102.194 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.855 Y102.229 E.00254
G2 X165.925 Y91.518 I1.977 J-5.173 E.60597
G2 X164.974 Y91.584 I.102 J8.363 E.02992
G2 X163.324 Y101.993 I.858 J5.471 E.43696
G1 X163.726 Y102.17 E.01377
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.855 Y102.229 E-.02678
G1 X164.407 Y102.406 E-.11022
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.67 Y102.587 E-.02263
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.886 Y106.084 Z2.6 F36000
G1 X47.278 Y163.613 Z2.6
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.0036
G2 X47.204 Y154.316 I-.253 J-4.644 E.48358
G2 X46.655 Y154.34 I-.048 J5.222 E.0186
G2 X46.898 Y163.613 I.476 J4.627 E.47059
G1 X47.218 Y163.613 E.01083
M204 S10000
G1 X47.278 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00432
G2 X47.215 Y153.909 I-.272 J-5.051 E.52591
G2 X46.35 Y153.97 I.103 J7.699 E.02935
G2 X46.877 Y164.019 I.784 J4.997 E.50256
G1 X47.218 Y164.019 E.01155
M204 S250
G1 X47.278 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00465
G2 X47.225 Y153.518 I-.294 J-5.442 E.52475
G2 X46.289 Y153.582 I.1 J8.227 E.02944
G2 X46.857 Y164.41 I.844 J5.385 E.50163
G1 X47.218 Y164.411 E.01135
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.03956
G1 X47.712 Y164.389 E-.05426
G1 X48.275 Y164.299 E-.1084
G1 X48.826 Y164.152 E-.1084
G1 X49.167 Y164.021 E-.06937
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.91 Y163.258 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X49.088 Y155.129 E.28488
; WIPE_START
G1 X48.571 Y157.061 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.148 Y155.891 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X48.209 Y163.13 E.25367
M204 S10000
G1 X48.299 Y163.106 F36000
G1 F1473.913
M204 S3000
G1 X43.003 Y157.809 E.25354
M204 S10000
G1 X42.978 Y157.9 F36000
G1 F1473.913
M204 S3000
G1 X50.217 Y155.96 E.25367
; WIPE_START
G1 X48.286 Y156.478 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.979 Y157.02 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X42.85 Y159.199 E.28486
G1 X42.861 Y159.394 E.00663
G1 X46.714 Y163.248 E.18447
G3 X46.645 Y163.239 I.006 J-.336 E.00238
G1 X49.699 Y162.421 E.10704
G1 X49.654 Y162.453 E.00188
G1 X51.061 Y157.204 E.18396
G1 X51.083 Y157.255 E.00188
G1 X48.847 Y155.018 E.10704
G1 X48.913 Y155.045 E.00242
G1 X43.655 Y156.454 E.18427
G1 X43.688 Y156.409 E.00188
G1 X42.868 Y159.468 E.10718
G2 X43.088 Y160.399 I4.951 J-.679 E.03244
G1 X51.368 Y158.181 E.29014
G3 X51.437 Y159.121 I-6.167 J.925 E.03195
; WIPE_START
G1 X51.368 Y158.181 E-.17918
G1 X50.347 Y158.454 E-.20082
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.941 Y160.981 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X50.409 Y161.761 I-4.105 J-2.231 E.03203
G1 X44.348 Y155.7 E.29014
G3 X45.126 Y155.168 I3.009 J3.571 E.03196
M204 S10000
G1 X45.595 Y154.951 F36000
G1 F1473.913
M204 S3000
G3 X46.676 Y154.695 I3.034 J10.374 E.03762
G1 X44.602 Y162.434 E.2712
G1 X44.691 Y162.498 E.00372
G1 X51.033 Y160.799 E.22223
G1 X51.077 Y160.703 E.0036
G1 X45.409 Y155.034 E.27135
G1 X45.309 Y155.079 E.00372
G1 X43.61 Y161.418 E.22213
G1 X43.675 Y161.506 E.00372
G1 X51.419 Y159.431 E.27139
G2 X51.426 Y159.324 I-.505 J-.087 E.00363
G1 X46.785 Y154.683 E.22217
G3 X47.928 Y154.74 I.296 J5.536 E.0388
G1 X45.709 Y163.021 E.29017
G3 X44.86 Y162.612 I1.366 J-3.924 E.03198
; WIPE_START
G1 X45.709 Y163.021 E-.17914
G1 X45.983 Y162 E-.20086
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.492 Y162.571 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X43.537 Y156.617 E.28505
; OBJECT_ID: 14
; WIPE_START
G1 X44.951 Y158.031 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.379 Y157.074 Z2.6 F36000
G1 X26.725 Y155.727 Z2.6
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00808
G2 X25.951 Y155.594 I-.709 J3.333 E.01858
G1 X25.62 Y155.594 E.01119
G2 X26.839 Y155.757 I.165 J3.403 E.68281
G1 X26.783 Y155.742 E.00197
M204 S10000
G1 X26.619 Y156.12 F36000
G1 F1473.913
M204 S3000
G1 X26.409 Y156.063 E.00736
G2 X25.935 Y156.001 I-.624 J2.935 E.01623
G1 X25.636 Y156.001 E.0101
G2 X26.713 Y156.145 I.149 J2.997 E.60113
G1 X26.677 Y156.135 E.00124
M204 S250
G1 X26.518 Y156.498 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00618
G2 X25.919 Y156.393 I-.543 J2.551 E.01294
G1 X25.652 Y156.393 E.00839
G2 X26.592 Y156.518 I.134 J2.605 E.48395
G1 X26.576 Y156.513 E.00051
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.04882
G1 X25.919 Y156.393 E-.07834
G1 X25.652 Y156.393 E-.05083
G1 X25.243 Y156.447 E-.07834
G1 X24.979 Y156.518 E-.05189
G1 X24.724 Y156.616 E-.0519
G1 X24.632 Y156.666 E-.01987
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.881 Y154.318 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.848 Y154.316 E.00112
G2 X25.296 Y154.34 I-.048 J5.256 E.01873
G2 X26.275 Y154.343 I.48 J4.659 E.96299
G1 X25.941 Y154.322 E.01132
M204 S10000
G1 X25.904 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.859 Y153.909 E.00153
G2 X24.989 Y153.97 I.104 J7.749 E.02954
G2 X26.317 Y153.938 I.789 J5.03 E1.03776
G1 X25.964 Y153.916 E.01199
M204 S250
G1 X25.926 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.869 Y153.518 E.00179
G2 X24.927 Y153.583 I.101 J8.279 E.02962
G2 X26.358 Y153.548 I.849 J5.418 E1.03531
G1 X25.986 Y153.525 E.0117
; WIPE_START
M204 S3000
G1 X25.869 Y153.518 E-.02223
G1 X25.498 Y153.523 E-.07045
G1 X24.927 Y153.583 E-.10911
G1 X24.366 Y153.702 E-.1091
G1 X24.02 Y153.815 E-.06912
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.367 Y155.276 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X25.958 Y155.246 I.41 J2.25 E.02008
G1 X25.399 Y154.686 E.02679
G1 X25.329 Y154.694 E.00238
G1 X25.166 Y155.302 E.02133
G2 X24.47 Y155.485 I.511 J3.361 E.02439
G1 X24.028 Y155.042 E.02119
G1 X23.963 Y155.071 E.00238
G1 X23.757 Y155.842 E.02703
G3 X24.28 Y155.558 I2.616 J4.192 E.02017
; WIPE_START
G1 X23.757 Y155.842 E-.11317
G1 X23.963 Y155.071 E-.15171
G1 X24.028 Y155.042 E-.01335
G1 X24.406 Y155.421 E-.10176
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.099 Y156.378 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X22.578 Y157.047 I2.788 J2.708 E.02876
G1 X22.157 Y156.626 E.02016
G1 X22.248 Y156.501 E.00523
G1 X23.243 Y156.234 E.03488
G3 X23.378 Y156.12 I.612 J.585 E.006
G1 X22.968 Y155.71 E.01965
G2 X22.355 Y156.353 I3.075 J3.539 E.03012
G1 X21.492 Y159.576 E.11292
G2 X21.7 Y160.441 I3.731 J-.44 E.03019
G1 X22.259 Y160.291 E.01957
G1 X22.206 Y160.129 E.00577
G1 X21.469 Y159.392 E.03526
G1 X21.461 Y159.24 E.00515
G1 X22.035 Y159.087 E.02008
G2 X22.147 Y159.934 I3.81 J-.075 E.02899
; WIPE_START
G1 X22.035 Y159.087 E-.16241
G1 X21.461 Y159.24 E-.11273
G1 X21.469 Y159.392 E-.02891
G1 X21.752 Y159.675 E-.07595
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.763 Y161.225 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.448 Y160.726 I2.218 J-1.748 E.02001
G1 X22.243 Y161.492 E.02684
G1 X22.284 Y161.549 E.00238
G1 X22.885 Y161.388 E.02106
G2 X23.399 Y161.897 I2.191 J-1.697 E.02455
G1 X23.237 Y162.501 E.02118
G1 X23.294 Y162.542 E.00238
G1 X24.065 Y162.336 E.02704
G3 X23.557 Y162.025 I2.263 J-4.271 E.02019
; WIPE_START
G1 X24.065 Y162.336 E-.11323
G1 X23.294 Y162.542 E-.1518
G1 X23.237 Y162.501 E-.01335
G1 X23.375 Y161.985 E-.10162
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X24.858 Y162.637 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X25.7 Y162.746 I.859 J-3.315 E.02881
G1 X25.545 Y163.324 E.02024
G1 X25.393 Y163.316 E.00515
G1 X24.661 Y162.584 E.03502
G3 X24.495 Y162.525 I.2 J-.823 E.006
G1 X24.344 Y163.086 E.01965
G2 X25.21 Y163.293 I1.514 J-4.396 E.03017
G1 X28.437 Y162.429 E.11308
G2 X29.076 Y161.818 I-3.129 J-3.912 E.02997
G1 X28.665 Y161.407 E.01965
G3 X28.551 Y161.541 I-.566 J-.367 E.00598
G1 X28.282 Y162.544 E.03513
G1 X28.156 Y162.625 E.00508
G1 X27.738 Y162.207 E.02004
G2 X28.403 Y161.681 I-1.846 J-3.026 E.02877
; WIPE_START
G1 X27.738 Y162.207 E-.16112
G1 X28.156 Y162.625 E-.11247
G1 X28.282 Y162.544 E-.02853
G1 X28.389 Y162.148 E-.07788
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.228 Y160.505 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X28.943 Y161.029 I-4.384 J-2.045 E.02019
G1 X29.718 Y160.821 E.02715
G1 X29.747 Y160.764 E.00218
G1 X29.301 Y160.315 E.02142
G2 X29.487 Y159.619 I-3.542 J-1.322 E.02445
G1 X30.098 Y159.453 E.02142
G1 X30.101 Y159.389 E.00218
G1 X29.538 Y158.826 E.02695
G3 X29.519 Y159.418 I-2.253 J.222 E.02009
; WIPE_START
G1 X29.538 Y158.826 E-.11246
G1 X30.101 Y159.389 E-.15129
G1 X30.098 Y159.453 E-.01222
G1 X29.57 Y159.596 E-.10403
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.403 Y157.99 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X29.077 Y157.2 I-3.671 J1.053 E.029
G1 X29.656 Y157.045 E.02029
G1 X29.72 Y157.179 E.00503
G1 X29.45 Y158.188 E.03536
G1 X29.485 Y158.355 E.00577
G1 X30.044 Y158.205 E.01958
G2 X29.791 Y157.352 I-4.564 J.887 E.03017
G1 X27.433 Y154.994 E.11287
G2 X26.58 Y154.741 I-1.74 J4.309 E.03017
G1 X26.43 Y155.3 E.01958
G1 X26.597 Y155.336 E.00577
G1 X27.603 Y155.066 E.03526
G1 X27.739 Y155.135 E.00515
G1 X27.586 Y155.706 E.02
G2 X26.795 Y155.382 I-1.938 J3.602 E.02898
; WIPE_START
G1 X27.586 Y155.706 E-.16237
G1 X27.739 Y155.135 E-.11228
G1 X27.603 Y155.066 E-.02891
G1 X27.215 Y155.17 E-.07645
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.24 Y156.16 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X28.897 Y155.984 E.02303
G2 X28.802 Y155.886 I-.669 J.554 E.00461
G1 X28.626 Y156.544 E.02306
; WIPE_START
G1 X28.802 Y155.886 E-.17282
G1 X28.897 Y155.984 E-.03454
G1 X28.24 Y156.16 E-.17264
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.018 Y162.543 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X26.842 Y163.2 E.02302
G1 X26.97 Y163.166 E.00447
G1 X26.491 Y162.687 E.02293
; WIPE_START
G1 X26.97 Y163.166 E-.17282
G1 X26.842 Y163.2 E-.03371
G1 X27.018 Y162.543 E-.17347
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.097 Y158.293 Z2.6 F36000
G1 Z2.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X21.617 Y157.813 E.02297
G2 X21.58 Y157.944 I.811 J.302 E.00461
G1 X22.238 Y157.768 E.02306
; CHANGE_LAYER
; Z_HEIGHT: 2.4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X21.58 Y157.944 E-.17302
G1 X21.617 Y157.813 E-.03458
G1 X22.097 Y158.293 E-.1724
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L12
M991 S0 P11 ;notify layer change


M204 S10000
G17
G3 Z2.6 I1.217 J0 P1  F36000
; object ids of layer 12 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer12 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.089 Y93.536
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X228.715 Y93.669 E.01345
G2 X230.388 Y93.357 I1.49 J3.34 E.71962
G2 X230.012 Y93.357 I-.182 J4.784 E.01275
G2 X229.256 Y93.477 I.193 J3.652 E.02594
G1 X229.146 Y93.516 E.00395
M204 S10000
G1 X229.252 Y93.904 F36000
G1 F1473.913
M204 S3000
M73 P54 R22
G1 X229.198 Y93.919 E.00187
G2 X230.369 Y93.763 I1.006 J3.09 E.65101
G2 X230.033 Y93.764 I-.164 J4.271 E.01139
G2 X229.527 Y93.831 I.171 J3.246 E.0173
G1 X229.31 Y93.889 E.00761
M204 S250
G1 X229.355 Y94.287 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.04 Y94.399 E.01049
G2 X230.351 Y94.155 I1.164 J2.611 E.52085
G2 X230.054 Y94.155 I-.148 J3.79 E.00934
G2 X229.463 Y94.249 I.15 J2.854 E.01878
G1 X229.412 Y94.267 E.0017
; WIPE_START
M204 S3000
G1 X229.04 Y94.399 E-.07499
G1 X228.773 Y94.535 E-.05686
G1 X228.522 Y94.698 E-.05687
G1 X228.289 Y94.886 E-.05692
G1 X228.078 Y95.098 E-.05685
G1 X227.829 Y95.421 E-.07752
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.312 Y92.719 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.069 Y92.823 E.00894
G2 X230.275 Y92.317 I2.123 J4.188 E.92134
G2 X229.712 Y92.34 I-.062 J5.193 E.01907
G2 X228.519 Y92.624 I.48 J4.671 E.04163
G1 X228.366 Y92.694 E.00569
M204 S10000
G1 X228.135 Y92.346 F36000
G1 F1473.913
M204 S3000
G1 X228.126 Y92.347 E.00029
G2 X230.285 Y91.91 I2.068 J4.665 E1.01021
G2 X229.405 Y91.97 I.084 J7.637 E.0299
G2 X228.373 Y92.245 I.79 J5.042 E.03619
G1 X228.19 Y92.322 E.00674
M204 S250
G1 X227.987 Y91.99 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.707 Y92.112 E.00959
G2 X230.296 Y91.518 I2.487 J4.9 E.99851
G2 X229.343 Y91.583 I.082 J8.174 E.02995
G2 X228.233 Y91.879 I.85 J5.429 E.0361
G1 X228.042 Y91.965 E.00658
; WIPE_START
M204 S3000
G1 X227.707 Y92.112 E-.06952
G1 X227.21 Y92.402 E-.10932
G1 X226.973 Y92.565 E-.05464
G1 X226.525 Y92.927 E-.10935
G1 X226.387 Y93.065 E-.03717
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.578 Y93.168 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672861
G1 F952.471
M204 S3000
G1 X228.306 Y93.289 E.01558
G2 X226.025 Y97.012 I1.896 J3.722 E.24065
G1 X226.048 Y97.449 E.02292
G1 X226.116 Y97.88 E.0229
G1 X226.23 Y98.303 E.02291
G1 X226.395 Y98.729 E.02394
G2 X228.698 Y93.114 I3.808 J-1.718 E1.01896
G1 X228.633 Y93.143 E.00376
; OBJECT_ID: 12
; WIPE_START
G1 X228.306 Y93.289 E-.06791
G1 X227.928 Y93.508 E-.08311
G1 X227.58 Y93.76 E-.08153
G1 X227.401 Y93.912 E-.04471
G1 X227.098 Y94.216 E-.08153
G1 X227.03 Y94.305 E-.02121
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.793 Y96.73 Z2.8 F36000
G1 X211.894 Y99.377 Z2.8
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.153 E.00935
G2 X208.976 Y93.12 I-3.275 J-2.131 E.27736
G2 X208.573 Y93.12 I-.195 J5.127 E.01364
G2 X211.814 Y99.483 I.206 J3.901 E.52607
G1 X211.857 Y99.425 E.00246
M204 S10000
G1 X211.565 Y99.138 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.931 E.00863
G2 X208.957 Y93.527 I-2.934 J-1.908 E.24837
G2 X208.594 Y93.527 I-.177 J4.616 E.01228
G2 X211.497 Y99.227 I.184 J3.495 E.4713
G1 X211.528 Y99.186 E.00174
M204 S250
G1 X211.248 Y98.908 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00735
G2 X208.939 Y93.919 I-2.605 J-1.694 E.20421
G2 X208.615 Y93.919 I-.161 J4.136 E.01016
G2 X211.192 Y98.98 I.163 J3.104 E.38771
G1 X211.211 Y98.955 E.00097
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.0559
G1 X211.619 Y98.29 E-.0927
G1 X211.735 Y97.986 E-.06184
G1 X211.82 Y97.671 E-.06187
G1 X211.871 Y97.35 E-.06183
G1 X211.883 Y97.109 E-.04586
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.691 Y99.384 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X208.849 Y92.317 I4.075 J-2.359 E.66468
G2 X208.285 Y92.341 I-.062 J5.206 E.01913
G2 X204.661 Y99.332 I.481 J4.684 E.31566
M204 S10000
G1 X204.341 Y99.586 F36000
G1 F1473.913
M204 S3000
G2 X208.86 Y91.91 I4.428 J-2.562 E.72213
G2 X207.977 Y91.971 I.084 J7.663 E.02998
G2 X204.311 Y99.534 I.792 J5.054 E.33388
M204 S250
G1 X204.018 Y99.798 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.315 Y100.267 E.01739
G2 X208.87 Y91.518 I4.453 J-3.242 E.70194
G2 X207.916 Y91.583 I.082 J8.194 E.03002
G2 X203.982 Y99.751 I.852 J5.442 E.33387
; WIPE_START
M204 S3000
G1 X204.315 Y100.267 E-.11659
G1 X204.683 Y100.711 E-.10964
G1 X205.091 Y101.119 E-.10956
M73 P54 R21
G1 X205.268 Y101.27 E-.04422
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.043 Y99.175 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436012
G1 F1526.363
M204 S3000
G1 X205.048 Y99.184 E.00032
G1 X205.291 Y99.557 E.01457
G1 X205.539 Y99.866 E.01295
G2 X204.468 Y97.019 I3.238 J-2.843 E.78339
G1 X204.474 Y97.255 E.00771
G1 X204.522 Y97.704 E.01473
G1 X204.615 Y98.14 E.01458
G1 X204.754 Y98.569 E.01475
G1 X204.935 Y98.976 E.01457
G1 X205.014 Y99.122 E.00543
; OBJECT_ID: 11
; WIPE_START
G1 X205.048 Y99.184 E-.01327
G1 X205.291 Y99.557 E-.08468
G1 X205.539 Y99.866 E-.07527
G1 X205.73 Y100.072 E-.05346
G1 X206.065 Y100.374 E-.08565
G1 X206.353 Y100.583 E-.06766
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.968 Y98.657 Z2.8 F36000
G1 X183.877 Y94.72 Z2.8
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.725 Y94.961 E.00964
G2 X187.535 Y92.885 I3.601 J2.076 E.7295
G2 X187.106 Y92.885 I-.208 J5.448 E.01452
G2 X183.961 Y94.596 I.22 J4.151 E.12528
G1 X183.911 Y94.67 E.00305
M204 S10000
G1 X184.218 Y94.942 F36000
G1 F1473.913
M204 S3000
G1 X184.077 Y95.164 E.00893
G2 X187.517 Y93.292 I3.249 J1.873 E.658
G2 X187.128 Y93.292 I-.19 J4.936 E.01317
G2 X184.29 Y94.835 I.197 J3.745 E.11303
G1 X184.252 Y94.892 E.00232
M204 S250
G1 X184.546 Y95.155 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.21 E.0021
G2 X187.499 Y93.684 I2.817 J1.827 E.55124
G2 X187.148 Y93.684 I-.174 J4.455 E.01098
G2 X184.714 Y94.925 I.176 J3.353 E.08825
G1 X184.581 Y95.106 E.00704
; WIPE_START
M204 S3000
G1 X184.507 Y95.21 E-.02415
G1 X184.255 Y95.673 E-.10019
G1 X184.129 Y96.001 E-.06681
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.967 Y96.978 E-.05521
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.421 Y92.318 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.396 Y92.317 E.00083
G2 X186.83 Y92.341 I-.062 J5.226 E.01919
G2 X187.818 Y92.343 I.483 J4.699 E.97111
G1 X187.481 Y92.322 E.01144
M204 S10000
G1 X187.444 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.407 Y91.91 E.00124
G2 X186.521 Y91.971 I.085 J7.684 E.03007
G2 X187.86 Y91.938 I.794 J5.069 E1.04566
G1 X187.504 Y91.916 E.0121
M204 S250
G1 X187.466 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.417 Y91.518 E.00153
G2 X186.46 Y91.583 I.082 J8.214 E.0301
G2 X187.901 Y91.548 I.855 J5.456 E1.04263
G1 X187.526 Y91.524 E.01179
; WIPE_START
M204 S3000
G1 X187.417 Y91.518 E-.02069
G1 X187.035 Y91.523 E-.07259
G1 X186.46 Y91.583 E-.1099
G1 X186.176 Y91.636 E-.05494
G1 X185.617 Y91.786 E-.10983
G1 X185.558 Y91.808 E-.01205
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.551 Y92.603 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200614
G1 F3804.836
M204 S3000
G2 X182.882 Y97.037 I-.227 J4.436 E.09444
G1 X182.907 Y97.506 E.00615
G1 X182.979 Y97.961 E.00604
G1 X183.033 Y98.187 E.00305
G1 X183.177 Y98.631 E.00613
G1 X183.368 Y99.058 E.00612
G1 X183.598 Y99.457 E.00604
G1 X183.73 Y99.648 E.00305
G1 X184.023 Y100.011 E.00612
G1 X184.354 Y100.342 E.00613
G1 X184.712 Y100.632 E.00604
G1 X184.905 Y100.764 E.00307
G1 X185.105 Y100.887 E.00308
G1 X185.516 Y101.096 E.00604
G1 X185.952 Y101.264 E.00613
G1 X186.403 Y101.384 E.00612
G1 X186.632 Y101.427 E.00305
G1 X187.09 Y101.475 E.00604
G1 X187.559 Y101.475 E.00615
G1 X187.791 Y101.456 E.00305
G1 X188.246 Y101.384 E.00604
G1 X188.697 Y101.264 E.00612
G1 X189.141 Y101.093 E.00624
G2 X187.611 Y92.606 I-1.817 J-4.053 E.15468
; OBJECT_ID: 10
; WIPE_START
G1 X186.862 Y92.621 E-.14232
G1 X186.401 Y92.694 E-.08875
G1 X186.173 Y92.749 E-.04454
G1 X185.734 Y92.892 E-.08763
G1 X185.653 Y92.928 E-.01676
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.023 Y93.119 Z2.8 F36000
G1 X163.256 Y93.49 Z2.8
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.067 Y93.63 E.00799
G2 X166.065 Y92.651 I2.776 J3.422 E.82799
G2 X165.61 Y92.652 I-.221 J5.778 E.01541
G2 X163.44 Y93.358 I.233 J4.4 E.07814
G1 X163.305 Y93.455 E.0056
M204 S10000
G1 X163.495 Y93.819 F36000
G1 F1473.913
M204 S3000
G1 X163.322 Y93.946 E.00727
G2 X166.046 Y93.058 I2.519 J3.107 E.75145
G2 X165.631 Y93.058 I-.204 J5.266 E.01405
G2 X163.661 Y93.699 I.21 J3.994 E.07093
G1 X163.544 Y93.784 E.00488
M204 S250
G1 X163.726 Y94.136 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.569 Y94.25 E.00609
G2 X166.028 Y93.45 I2.272 J2.802 E.62779
G2 X165.652 Y93.45 I-.187 J4.786 E.0118
G2 X163.875 Y94.028 I.189 J3.603 E.05927
G1 X163.774 Y94.1 E.00388
; WIPE_START
M204 S3000
G1 X163.569 Y94.25 E-.04831
G1 X163.288 Y94.502 E-.07174
G1 X163.035 Y94.783 E-.07185
G1 X162.813 Y95.089 E-.07178
G1 X162.624 Y95.416 E-.07178
G1 X162.529 Y95.63 E-.04455
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.09 Y101.459 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.14 Y101.484 E.0019
G2 X165.913 Y92.317 I1.689 J-4.428 E.55963
G2 X165.345 Y92.341 I-.062 J5.241 E.01925
G2 X163.911 Y101.389 I.484 J4.715 E.42071
G1 X164.034 Y101.437 E.00448
M204 S10000
G1 X163.934 Y101.835 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.864 E.00226
G2 X165.924 Y91.91 I1.837 J-4.808 E.60781
M73 P55 R21
G2 X165.035 Y91.971 I.084 J7.702 E.03016
G2 X163.745 Y101.761 I.797 J5.085 E.44753
G1 X163.878 Y101.813 E.00484
M204 S250
G1 X163.784 Y102.198 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.23 E.00241
G2 X165.934 Y91.518 I1.977 J-5.174 E.60578
G2 X164.974 Y91.584 I.082 J8.24 E.03019
G2 X163.586 Y102.12 I.857 J5.472 E.44615
G1 X163.728 Y102.176 E.0048
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.23 E-.02602
G1 X164.407 Y102.406 E-.11023
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.674 Y102.587 E-.02338
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.89 Y106.084 Z2.8 F36000
G1 X47.284 Y163.613 Z2.8
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.0034
G2 X47.213 Y154.317 I-.254 J-4.645 E.48326
G2 X46.655 Y154.34 I-.061 J5.146 E.01888
G2 X46.898 Y163.613 I.475 J4.627 E.47065
G1 X47.224 Y163.613 E.01103
M204 S10000
G1 X47.284 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00412
G2 X47.223 Y153.91 I-.273 J-5.051 E.5256
G2 X46.35 Y153.97 I.083 J7.577 E.02964
G2 X46.877 Y164.019 I.783 J4.997 E.50263
G1 X47.224 Y164.019 E.01176
M204 S250
G1 X47.284 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00446
G2 X47.233 Y153.518 I-.294 J-5.443 E.52448
G2 X46.289 Y153.582 I.081 J8.106 E.02971
G2 X46.857 Y164.411 I.843 J5.385 E.50169
G1 X47.224 Y164.411 E.01153
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.03845
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.1084
G1 X48.826 Y164.152 E-.1084
G1 X49.172 Y164.019 E-.07048
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.129 Y163.27 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X48.051 Y163.172 I-4.664 J-48.65 E.03139
G1 X50.03 Y155.785 E.25888
G3 X50.324 Y156.078 I-1.248 J1.541 E.01407
G1 X42.935 Y158.058 E.2589
G3 X43.049 Y157.656 I2.609 J.52 E.01417
G1 X48.457 Y163.064 E.25888
G2 X49.297 Y162.685 I-2.733 J-7.182 E.0312
M204 S10000
G1 X49.772 Y162.367 F36000
G1 F1473.913
M204 S3000
G2 X50.501 Y161.654 I-9.472 J-10.405 E.03454
G1 X44.455 Y155.607 E.28945
G2 X43.741 Y156.336 I9.707 J10.217 E.03454
; WIPE_START
G1 X44.455 Y155.607 E-.19385
G1 X45.148 Y156.3 E-.18616
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X42.878 Y159.545 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X43.135 Y160.533 I16.365 J-3.72 E.03455
G1 X51.39 Y158.321 E.2893
G3 X51.436 Y159.134 I-4.303 J.65 E.02762
G1 X46.97 Y154.668 E.21379
G2 X46.525 Y154.711 I.01 J2.481 E.01515
G1 X44.48 Y162.345 E.26753
G2 X44.845 Y162.603 I1.412 J-1.609 E.01519
G1 X50.949 Y160.968 E.21388
G2 X51.136 Y160.561 I-1.845 J-1.096 E.01519
G1 X45.547 Y154.973 E.26753
G2 X45.14 Y155.16 I.689 J2.031 E.01519
G1 X43.505 Y161.263 E.21388
G2 X43.764 Y161.629 I1.868 J-1.047 E.01519
G1 X51.4 Y159.583 E.26759
G3 X51.204 Y160.37 I-5.348 J-.91 E.02747
; WIPE_START
G1 X51.4 Y159.583 E-.15408
G1 X50.251 Y159.891 E-.22592
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X51.359 Y158.12 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X51.042 Y157.15 I-15.108 J4.399 E.03454
G1 X42.858 Y159.343 E.28678
G1 X42.85 Y159.183 E.00542
G1 X46.925 Y163.259 E.1951
G1 X46.766 Y163.251 E.00542
G1 X48.958 Y155.067 E.28678
G3 X49.108 Y155.14 I-.388 J.984 E.00563
G1 X43.525 Y156.636 E.19563
G3 X43.621 Y156.501 I.692 J.391 E.00561
G1 X49.608 Y162.487 E.28656
G3 X49.473 Y162.583 I-.525 J-.593 E.00561
G1 X50.969 Y157.001 E.19563
G2 X50.46 Y156.23 I-4.805 J2.618 E.03131
; WIPE_START
G1 X50.969 Y157.001 E-.17556
G1 X50.69 Y158.04 E-.20444
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.77 Y154.989 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X47.787 Y154.718 I-1.646 J4.056 E.03459
G1 X45.575 Y162.974 E.2893
G2 X46.564 Y163.226 I2.183 J-6.481 E.03456
; OBJECT_ID: 14
; WIPE_START
G1 X45.575 Y162.974 E-.19382
G1 X45.829 Y162.027 E-.18618
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X38.581 Y159.637 Z2.8 F36000
G1 X26.719 Y155.725 Z2.8
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00787
G2 X25.951 Y155.594 I-.709 J3.335 E.01858
G1 X25.62 Y155.594 E.01119
G2 X26.839 Y155.757 I.165 J3.405 E.68318
G1 X26.777 Y155.741 E.00218
M204 S10000
G1 X26.613 Y156.118 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.063 E.00715
G2 X25.935 Y156.001 I-.624 J2.936 E.01623
G1 X25.636 Y156.001 E.0101
G2 X26.713 Y156.144 I.149 J2.998 E.60145
G1 X26.671 Y156.133 E.00146
M204 S250
G1 X26.512 Y156.496 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00598
G2 X25.919 Y156.393 I-.543 J2.553 E.01294
G1 X25.652 Y156.393 E.00839
G2 X26.592 Y156.518 I.134 J2.606 E.48421
G1 X26.57 Y156.512 E.0007
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.04763
G1 X25.919 Y156.393 E-.07835
G1 X25.652 Y156.393 E-.05083
G1 X25.243 Y156.447 E-.07834
G1 X24.979 Y156.518 E-.0519
G1 X24.724 Y156.616 E-.05192
G1 X24.627 Y156.669 E-.02103
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.886 Y154.318 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.857 Y154.317 E.00097
G2 X25.296 Y154.34 I-.061 J5.182 E.01902
G2 X26.275 Y154.343 I.479 J4.66 E.96306
G1 X25.945 Y154.322 E.01117
M204 S10000
G1 X25.909 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.867 Y153.91 E.00139
G2 X24.989 Y153.97 I.084 J7.623 E.02983
G2 X26.317 Y153.938 I.788 J5.03 E1.03764
G1 X25.968 Y153.916 E.01183
M204 S250
G1 X25.931 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.878 Y153.518 E.00167
G2 X24.927 Y153.583 I.082 J8.16 E.02989
G2 X26.358 Y153.548 I.849 J5.417 E1.03519
G1 X25.991 Y153.525 E.01155
; WIPE_START
M204 S3000
G1 X25.878 Y153.518 E-.02153
G1 X25.498 Y153.523 E-.07207
G1 X24.927 Y153.583 E-.10911
G1 X24.366 Y153.702 E-.1091
G1 X24.024 Y153.813 E-.0682
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.423 Y154.99 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X26.44 Y154.719 I-1.652 J4.077 E.03459
G1 X26.29 Y155.279 E.01963
G1 X26.18 Y155.268 E.00372
G1 X25.581 Y154.669 E.02868
G2 X25.178 Y154.709 I.022 J2.247 E.01374
G1 X25.014 Y155.322 E.02146
G2 X24.615 Y155.429 I6.151 J23.68 E.014
G1 X24.166 Y154.981 E.02148
G2 X23.796 Y155.148 I.61 J1.84 E.01376
G1 X23.579 Y155.958 E.02838
G1 X23.489 Y156.03 E.00393
G1 X23.075 Y155.617 E.01982
G2 X22.361 Y156.346 I10.312 J10.809 E.03454
M204 S10000
G1 X22.772 Y156.758 F36000
G1 F1473.913
M204 S3000
G3 X23.043 Y156.434 I1.676 J1.131 E.01433
G1 X22.124 Y156.681 E.03222
G3 X22.241 Y156.51 I.869 J.473 E.00702
G1 X22.657 Y156.926 E.0199
G2 X22.251 Y157.735 I3.198 J2.113 E.03072
M204 S10000
G1 X22.092 Y158.328 F36000
G1 F1473.913
M204 S3000
G2 X22.036 Y159.233 I5.533 J.796 E.03072
G1 X21.469 Y159.385 E.01987
G1 X21.458 Y159.181 E.0069
G1 X22.13 Y159.853 E.03214
G3 X22.057 Y159.435 I1.948 J-.553 E.01436
M204 S10000
G1 X21.494 Y159.587 F36000
G1 F1473.913
M204 S3000
G2 X21.75 Y160.574 I4.456 J-.628 E.0346
G1 X22.31 Y160.424 E.01964
G1 X22.355 Y160.526 E.00378
G1 X22.137 Y161.342 E.02859
G2 X22.373 Y161.671 I1.687 J-.96 E.01376
G1 X22.986 Y161.507 E.02148
G2 X23.278 Y161.799 I14.622 J-14.329 E.01399
G1 X23.114 Y162.412 E.02148
G2 X23.444 Y162.649 I1.29 J-1.451 E.01376
G1 X24.258 Y162.43 E.02855
G2 X24.362 Y162.475 I.274 J-.494 E.00381
G1 X24.21 Y163.039 E.01978
G2 X25.199 Y163.292 I2.23 J-6.671 E.03456
M204 S10000
G1 X25.351 Y162.731 F36000
G1 F1473.913
M204 S3000
G3 X24.934 Y162.657 I.142 J-2.02 E.01436
G1 X25.604 Y163.327 E.03205
G1 X25.4 Y163.316 E.0069
G1 X25.554 Y162.742 E.02011
G2 X26.457 Y162.694 I.252 J-3.748 E.03067
M204 S10000
G1 X27.051 Y162.535 F36000
G1 F1473.913
M204 S3000
G2 X27.856 Y162.125 I-1.279 J-3.51 E.03067
G1 X28.275 Y162.544 E.02005
G3 X28.105 Y162.661 I-.643 J-.751 E.00702
G1 X28.351 Y161.741 E.03224
G3 X28.027 Y162.015 I-1.477 J-1.419 E.01438
M204 S10000
G1 X28.44 Y162.424 F36000
G1 F1473.913
M204 S3000
G2 X29.169 Y161.711 I-10.096 J-11.043 E.03454
G1 X28.755 Y161.297 E.01982
G1 X28.828 Y161.206 E.00394
G1 X29.637 Y160.989 E.02838
G2 X29.803 Y160.618 I-2.88 J-1.506 E.01377
G1 X29.356 Y160.171 E.0214
G2 X29.463 Y159.771 I-19.422 J-5.419 E.01399
G1 X30.074 Y159.608 E.0214
G2 X30.111 Y159.199 I-1.929 J-.385 E.01392
G1 X29.518 Y158.605 E.02843
G1 X29.506 Y158.496 E.00373
G1 X30.066 Y158.346 E.01963
G2 X29.795 Y157.363 I-4.348 J.669 E.03459
M204 S10000
G1 X29.233 Y157.511 F36000
G1 F1473.913
M204 S3000
G1 X29.376 Y157.915 E.0145
G1 X29.625 Y156.989 E.03246
G3 X29.718 Y157.175 I-1.135 J.686 E.00705
G1 X29.145 Y157.328 E.02006
G2 X28.648 Y156.572 I-3.297 J1.627 E.03072
M204 S10000
G1 X28.214 Y156.137 F36000
G1 F1473.913
M204 S3000
G2 X27.456 Y155.645 I-2.244 J2.626 E.03068
G1 X27.611 Y155.067 E.02025
G3 X27.797 Y155.161 I-.5 J1.228 E.00705
G1 X26.875 Y155.408 E.03231
G3 X27.272 Y155.558 I-.37 J1.583 E.01442
M204 S10000
G1 X27.973 Y155.263 F36000
G1 F1473.913
M204 S3000
G3 X28.684 Y155.782 I-2.194 J3.745 E.02985
G1 X28.513 Y156.42 E.02234
G1 X28.366 Y156.273 E.00704
G1 X29.003 Y156.102 E.02234
G3 X29.523 Y156.812 I-3.227 J2.906 E.02985
; WIPE_START
G1 X29.003 Y156.102 E-.16727
G1 X28.366 Y156.273 E-.12541
G1 X28.513 Y156.42 E-.03954
G1 X28.578 Y156.177 E-.04778
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.928 Y162.763 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X27.123 Y163.119 I-2.145 J-3.769 E.02985
G1 X26.656 Y162.652 E.02235
G2 X26.857 Y162.598 I-.156 J-.985 E.00707
G1 X26.685 Y163.242 E.02257
G3 X25.807 Y163.335 I-.883 J-4.129 E.02992
; WIPE_START
G1 X26.685 Y163.242 E-.16765
G1 X26.857 Y162.598 E-.12671
G1 X26.656 Y162.652 E-.0396
G1 X26.827 Y162.823 E-.04604
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.45 Y158.978 Z2.8 F36000
G1 Z2.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X21.543 Y158.101 I4.223 J.005 E.02992
G1 X22.187 Y157.928 E.02256
G1 X22.133 Y158.129 E.00704
G1 X21.662 Y157.656 E.0226
G3 X22.022 Y156.857 I4.747 J1.658 E.02969
; CHANGE_LAYER
; Z_HEIGHT: 2.6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X21.662 Y157.656 E-.16646
G1 X22.133 Y158.129 E-.12687
G1 X22.187 Y157.928 E-.03953
G1 X21.947 Y157.992 E-.04713
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L13
M991 S0 P12 ;notify layer change


M204 S10000
G17
G3 Z2.8 I1.217 J0 P1  F36000
; object ids of layer 13 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer13 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.143 Y93.512
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.072 Y93.531 E.00248
G2 X230.381 Y93.356 I1.131 J3.478 E.73285
G1 X230.025 Y93.356 E.01207
G2 X229.442 Y93.432 I.178 J3.653 E.01991
G1 X229.201 Y93.497 E.00845
M204 S10000
G1 X229.248 Y93.905 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.918 E.00176
G2 X230.365 Y93.763 I1.005 J3.091 E.65116
G1 X230.041 Y93.763 E.01099
G2 X229.527 Y93.83 I.162 J3.246 E.01756
G1 X229.306 Y93.889 E.00773
M204 S250
G1 X229.35 Y94.283 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.291 E.00098
G2 X230.35 Y94.155 I.884 J2.718 E.5303
G1 X230.056 Y94.155 E.00921
G2 X229.609 Y94.214 I.147 J2.854 E.01417
G1 X229.408 Y94.268 E.00652
; WIPE_START
M204 S3000
G1 X229.319 Y94.291 E-.01735
G1 X229.04 Y94.399 E-.0569
G1 X228.773 Y94.535 E-.05686
G1 X228.522 Y94.698 E-.05687
G1 X228.181 Y94.989 E-.08527
G1 X227.889 Y95.33 E-.08531
G1 X227.828 Y95.425 E-.02144
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.346 Y92.704 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.07 Y92.825 E.0102
G2 X230.283 Y92.317 I2.125 J4.185 E.92053
G2 X229.468 Y92.373 I.067 J6.973 E.02767
G2 X228.519 Y92.625 I.727 J4.637 E.0333
G1 X228.4 Y92.679 E.00443
M204 S10000
G1 X228.18 Y92.333 F36000
G1 F1473.913
M204 S3000
G1 X227.885 Y92.461 E.01092
G2 X230.294 Y91.91 I2.31 J4.551 E1.00086
G2 X229.405 Y91.97 I.065 J7.528 E.03019
G2 X228.373 Y92.245 I.79 J5.042 E.03619
G1 X228.235 Y92.308 E.00515
M204 S250
G1 X228.021 Y91.975 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
M73 P56 R21
G1 X227.706 Y92.112 E.01076
G2 X230.304 Y91.518 I2.487 J4.9 E.99818
G2 X229.343 Y91.583 I.063 J8.065 E.03022
G2 X228.233 Y91.879 I.85 J5.429 E.0361
G1 X228.076 Y91.95 E.00541
; WIPE_START
M204 S3000
G1 X227.706 Y92.112 E-.07662
G1 X227.21 Y92.402 E-.10929
G1 X226.973 Y92.565 E-.05467
G1 X226.525 Y92.927 E-.1093
G1 X226.413 Y93.039 E-.03012
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.611 Y93.153 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672844
G1 F952.496
M204 S3000
G1 X228.307 Y93.29 E.0175
G2 X226.025 Y97.012 I1.893 J3.721 E.24062
G1 X226.076 Y97.665 E.03433
G1 X226.227 Y98.295 E.03392
G1 X226.477 Y98.901 E.03433
G1 X226.704 Y99.294 E.02379
G1 X227.098 Y99.807 E.0339
G1 X227.573 Y100.258 E.03433
G1 X228.114 Y100.63 E.03435
G1 X228.698 Y100.909 E.03391
G1 X229.129 Y101.049 E.02376
G1 X229.775 Y101.167 E.03435
G1 X230.421 Y101.184 E.03389
G1 X231.072 Y101.098 E.03438
G1 X231.701 Y100.912 E.03433
G1 X232.285 Y100.634 E.0339
G1 X232.665 Y100.387 E.02374
G1 X233.158 Y99.966 E.03395
G1 X233.583 Y99.467 E.03434
G1 X233.922 Y98.916 E.0339
G1 X234.106 Y98.501 E.02376
G1 X234.29 Y97.881 E.0339
G1 X234.375 Y97.23 E.03438
G1 X234.359 Y96.583 E.03389
G1 X234.288 Y96.135 E.02376
G1 X234.104 Y95.514 E.03391
G1 X233.826 Y94.93 E.0339
G1 X233.578 Y94.549 E.02377
G1 X233.157 Y94.057 E.03392
G1 X232.659 Y93.631 E.03435
G1 X232.1 Y93.289 E.03433
G1 X231.494 Y93.038 E.03434
G1 X230.857 Y92.885 E.03435
G1 X230.27 Y92.836 E.03084
G2 X228.706 Y93.112 I-.07 J4.174 E.08366
G1 X228.666 Y93.129 E.00228
; OBJECT_ID: 12
; WIPE_START
G1 X228.307 Y93.29 E-.07486
G1 X227.928 Y93.508 E-.08306
G1 X227.574 Y93.765 E-.08311
G1 X227.249 Y94.057 E-.08305
G1 X227.052 Y94.276 E-.05591
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.819 Y96.712 Z3 F36000
G1 X211.89 Y99.383 Z3
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.152 E.00958
G2 X208.975 Y93.12 I-3.275 J-2.131 E.27737
G2 X208.573 Y93.12 I-.194 J5.225 E.01362
G2 X211.814 Y99.483 I.206 J3.901 E.52606
G1 X211.853 Y99.431 E.00223
M204 S10000
G1 X211.561 Y99.144 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.931 E.00886
G2 X208.957 Y93.527 I-2.934 J-1.908 E.24838
G2 X208.594 Y93.527 I-.177 J4.713 E.01227
G2 X211.497 Y99.227 I.184 J3.495 E.4713
G1 X211.524 Y99.191 E.00151
M204 S250
G1 X211.244 Y98.914 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00756
G2 X208.939 Y93.919 I-2.605 J-1.694 E.20421
G2 X208.615 Y93.919 I-.161 J4.213 E.01016
G2 X211.192 Y98.98 I.163 J3.104 E.38771
G1 X211.207 Y98.961 E.00075
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.05723
G1 X211.619 Y98.29 E-.09268
G1 X211.735 Y97.986 E-.06186
G1 X211.82 Y97.671 E-.06185
G1 X211.871 Y97.35 E-.06183
G1 X211.883 Y97.116 E-.04456
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.707 Y99.381 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.822 Y99.593 E.00817
G2 X208.858 Y92.317 I3.947 J-2.568 E.65623
G2 X208.041 Y92.373 I.068 J6.992 E.02775
G2 X204.575 Y99.166 I.729 J4.653 E.30083
G1 X204.676 Y99.33 E.00652
M204 S10000
G1 X204.355 Y99.584 F36000
G1 F1473.913
M204 S3000
G1 X204.48 Y99.815 E.0089
G2 X208.869 Y91.91 I4.288 J-2.79 E.71279
G2 X207.977 Y91.971 I.065 J7.547 E.03027
G2 X204.212 Y99.351 I.792 J5.055 E.32684
G1 X204.323 Y99.533 E.00724
M204 S250
G1 X204.01 Y99.785 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.314 Y100.267 E.0179
G2 X208.879 Y91.518 I4.453 J-3.242 E.70174
G2 X207.916 Y91.583 I.063 J8.084 E.03029
G2 X203.975 Y99.74 I.852 J5.442 E.33349
; WIPE_START
M204 S3000
G1 X204.314 Y100.267 E-.11911
G1 X204.683 Y100.711 E-.10969
G1 X205.091 Y101.119 E-.10955
G1 X205.258 Y101.261 E-.04165
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.037 Y99.164 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436003
G1 F1526.395
M204 S3000
G1 X205.048 Y99.184 E.00075
G1 X205.291 Y99.558 E.01458
G1 X205.536 Y99.862 E.01277
G2 X204.468 Y97.019 I3.242 J-2.839 E.78354
G1 X204.474 Y97.255 E.00771
G1 X204.522 Y97.704 E.01473
G1 X204.615 Y98.14 E.01458
G1 X204.754 Y98.569 E.01475
G1 X204.935 Y98.977 E.01457
G1 X205.008 Y99.111 E.005
; OBJECT_ID: 11
; WIPE_START
G1 X205.048 Y99.184 E-.01576
G1 X205.291 Y99.558 E-.08475
G1 X205.536 Y99.862 E-.07423
G1 X205.73 Y100.072 E-.05427
G1 X206.065 Y100.374 E-.08573
G1 X206.348 Y100.568 E-.06525
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.962 Y98.646 Z3 F36000
G1 X183.877 Y94.721 Z3
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.728 Y94.955 E.00939
G2 X187.535 Y92.885 I3.598 J2.081 E.72974
G2 X187.106 Y92.885 I-.207 J5.553 E.01451
G2 X183.961 Y94.596 I.22 J4.151 E.1253
G1 X183.91 Y94.671 E.00306
M204 S10000
G1 X184.218 Y94.943 F36000
G1 F1473.913
M204 S3000
G1 X184.079 Y95.161 E.00874
G2 X187.516 Y93.292 I3.247 J1.876 E.65815
G2 X187.128 Y93.292 I-.19 J5.04 E.01316
G2 X184.29 Y94.835 I.197 J3.745 E.11304
G1 X184.251 Y94.893 E.00236
M204 S250
G1 X184.546 Y95.156 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.416 Y95.359 E.00753
G2 X187.499 Y93.684 I2.908 J1.678 E.54577
G2 X187.148 Y93.684 I-.174 J4.539 E.01098
G2 X184.607 Y95.065 I.176 J3.353 E.09377
G1 X184.579 Y95.106 E.00156
; WIPE_START
M204 S3000
G1 X184.416 Y95.359 E-.05705
G1 X184.187 Y95.835 E-.10042
G1 X184.038 Y96.341 E-.10019
G1 X183.983 Y96.688 E-.06681
G1 X183.967 Y96.98 E-.05553
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.425 Y92.318 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.405 Y92.317 E.00069
G2 X186.585 Y92.373 I.068 J7.017 E.02783
G2 X187.818 Y92.343 I.731 J4.667 E.96274
G1 X187.485 Y92.322 E.01128
M204 S10000
G1 X187.449 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.416 Y91.91 E.00112
G2 X186.521 Y91.971 I.066 J7.571 E.03036
M73 P56 R20
G2 X187.86 Y91.938 I.794 J5.069 E1.04572
G1 X187.508 Y91.916 E.01193
M204 S250
G1 X187.471 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.426 Y91.518 E.00142
G2 X186.46 Y91.583 I.064 J8.107 E.03037
G2 X187.901 Y91.548 I.854 J5.456 E1.04269
G1 X187.531 Y91.524 E.01164
; WIPE_START
M204 S3000
G1 X187.426 Y91.518 E-.02002
G1 X187.035 Y91.523 E-.07422
G1 X186.46 Y91.583 E-.10989
G1 X186.176 Y91.636 E-.05495
G1 X185.617 Y91.786 E-.10983
G1 X185.563 Y91.807 E-.0111
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.531 Y92.603 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200671
G1 F3803.479
M204 S3000
G1 X187.094 Y92.601 E.00574
G2 X182.882 Y97.037 I.23 J4.436 E.08851
G1 X182.907 Y97.503 E.00613
G1 X182.979 Y97.963 E.0061
G1 X183.1 Y98.412 E.0061
G1 X183.241 Y98.785 E.00523
G2 X187.591 Y92.603 I4.083 J-1.749 E.24747
; OBJECT_ID: 10
; WIPE_START
G1 X187.094 Y92.601 E-.09445
G1 X186.86 Y92.622 E-.04462
G1 X186.401 Y92.694 E-.08832
G1 X185.953 Y92.814 E-.08796
G1 X185.73 Y92.893 E-.04495
G1 X185.636 Y92.935 E-.0197
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.006 Y93.132 Z3 F36000
G1 X163.216 Y93.514 Z3
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.891 Y93.78 E.01419
G2 X166.064 Y92.651 I2.951 J3.272 E.8202
G2 X165.61 Y92.652 I-.22 J5.891 E.01539
G2 X163.264 Y93.479 I.233 J4.4 E.08535
M204 S10000
G1 X163.472 Y93.831 F36000
G1 F1473.913
M204 S3000
G1 X163.163 Y94.082 E.01347
G2 X166.046 Y93.058 I2.678 J2.97 E.74438
G2 X165.631 Y93.058 I-.203 J5.378 E.01404
G2 X163.52 Y93.795 I.211 J3.994 E.0767
M204 S250
G1 X163.718 Y94.135 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.425 Y94.373 E.01183
G2 X166.028 Y93.45 I2.415 J2.68 E.62187
G2 X165.652 Y93.45 I-.187 J4.877 E.0118
G2 X163.767 Y94.101 I.189 J3.603 E.06333
; WIPE_START
M204 S3000
G1 X163.425 Y94.373 E-.08302
G1 X163.158 Y94.64 E-.07181
G1 X162.813 Y95.089 E-.1076
G1 X162.624 Y95.416 E-.0718
G1 X162.525 Y95.636 E-.04578
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.114 Y101.468 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.482 E.00103
G2 X165.922 Y92.317 I1.691 J-4.427 E.55949
G2 X165.099 Y92.373 I.068 J7.039 E.02792
G2 X163.687 Y101.281 I.733 J4.682 E.4037
G1 X164.059 Y101.444 E.01373
M204 S10000
G1 X163.939 Y101.837 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.0021
G2 X165.932 Y91.91 I1.837 J-4.808 E.60742
G2 X165.035 Y91.971 I.066 J7.593 E.03045
G2 X163.746 Y101.76 I.796 J5.084 E.44751
G1 X163.883 Y101.815 E.005
M204 S250
G1 X163.791 Y102.194 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.128 Y102.326 E.01135
G2 X165.942 Y91.518 I1.703 J-5.27 E.59632
G2 X164.974 Y91.584 I.064 J8.134 E.03046
G2 X163.586 Y102.119 I.857 J5.472 E.44612
G1 X163.734 Y102.173 E.00496
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.128 Y102.326 E-.08017
G1 X164.407 Y102.406 E-.05513
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.679 Y102.587 E-.02433
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.895 Y106.084 Z3 F36000
G1 X47.29 Y163.613 Z3
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.607 E.0032
G2 X47.221 Y154.317 I-.251 J-4.642 E.48287
G2 X46.414 Y154.372 I.067 J6.911 E.02739
G2 X46.899 Y163.608 I.719 J4.593 E.46195
G1 X47.23 Y163.612 E.01123
M204 S10000
G1 X47.29 Y164.019 F36000
G1 F1473.913
M204 S3000
M73 P57 R20
G1 X47.406 Y164.018 E.00392
G2 X47.232 Y153.91 I-.273 J-5.051 E.5253
G2 X46.35 Y153.97 I.065 J7.465 E.02992
G2 X46.877 Y164.019 I.783 J4.998 E.50265
G1 X47.23 Y164.019 E.01196
M204 S250
G1 X47.29 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00428
G2 X47.242 Y153.518 I-.295 J-5.443 E.5242
G2 X46.289 Y153.582 I.063 J8.001 E.02997
G2 X46.857 Y164.411 I.843 J5.385 E.50171
G1 X47.23 Y164.411 E.01172
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.03731
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.10842
G1 X48.826 Y164.152 E-.10839
G1 X49.178 Y164.017 E-.07162
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.696 Y163.23 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X47.136 Y163.27 I-.837 J-7.795 E.01901
G1 X42.839 Y158.972 E.20574
G2 X42.871 Y159.486 I3.279 J.053 E.01745
G1 X51.098 Y157.282 E.28831
G2 X50.869 Y156.828 I-2.8 J1.128 E.01723
G1 X49.3 Y162.683 E.2052
G2 X49.724 Y162.403 I-1.121 J-2.156 E.01723
G1 X43.706 Y156.385 E.28808
G2 X43.425 Y156.809 I1.877 J1.546 E.01723
G1 X49.281 Y155.24 E.2052
G2 X48.827 Y155.011 I-1.578 J2.563 E.01723
G1 X46.623 Y163.238 E.28831
G3 X45.632 Y162.995 I.727 J-5.103 E.03458
; WIPE_START
G1 X46.623 Y163.238 E-.19381
G1 X46.876 Y162.291 E-.18619
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.95 Y160.965 Z3 F36000
G1 Z2.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X51.192 Y160.417 I-6.381 J-3.143 E.02027
G1 X45.694 Y154.919 E.26321
G3 X46.372 Y154.737 I1.203 J3.135 E.02381
G1 X44.36 Y162.245 E.2631
G3 X43.863 Y161.749 I2.114 J-2.61 E.02381
G1 X51.371 Y159.737 E.26308
G2 X51.444 Y158.942 I-5.457 J-.902 E.02705
G1 X47.168 Y154.666 E.20469
G3 X47.647 Y154.696 I-.167 J6.495 E.01626
G1 X45.445 Y162.916 E.28804
G3 X45.018 Y162.703 I.796 J-2.134 E.01614
G1 X50.849 Y161.141 E.2043
G3 X50.586 Y161.538 I-2.019 J-1.053 E.01614
G1 X44.571 Y155.523 E.28794
G3 X44.967 Y155.26 I1.449 J1.755 E.01614
G1 X43.405 Y161.09 E.2043
G3 X43.193 Y160.664 I1.922 J-1.223 E.01614
G1 X51.413 Y158.461 E.28804
G2 X51.171 Y157.472 I-4.49 J.572 E.03457
M204 S10000
G1 X50.767 Y156.651 F36000
G1 F1473.913
M204 S3000
G2 X50.43 Y156.196 I-5.632 J3.822 E.01918
G1 X42.909 Y158.211 E.26356
G3 X43.098 Y157.505 I3.457 J.548 E.02482
G1 X48.604 Y163.011 E.26358
G3 X47.897 Y163.198 I-1.602 J-4.615 E.02478
G1 X49.912 Y155.679 E.2635
G2 X49.457 Y155.342 I-4.278 J5.296 E.01918
; OBJECT_ID: 14
; WIPE_START
G1 X49.912 Y155.679 E-.10761
G1 X49.541 Y157.064 E-.27239
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X41.922 Y156.616 Z3 F36000
G1 X26.712 Y155.723 Z3
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00764
G2 X25.951 Y155.594 I-.709 J3.333 E.01857
G1 X25.62 Y155.594 E.01119
G2 X26.839 Y155.757 I.165 J3.403 E.68281
G1 X26.77 Y155.739 E.00241
M204 S10000
G1 X26.607 Y156.116 F36000
G1 F1473.913
M204 S3000
G1 X26.409 Y156.063 E.00692
G2 X25.935 Y156.001 I-.624 J2.935 E.01623
G1 X25.636 Y156.001 E.0101
G2 X26.713 Y156.145 I.149 J2.997 E.60113
G1 X26.665 Y156.132 E.00169
M204 S250
G1 X26.505 Y156.495 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00576
G2 X25.919 Y156.393 I-.543 J2.551 E.01294
G1 X25.652 Y156.393 E.00839
G2 X26.592 Y156.518 I.134 J2.605 E.48395
G1 X26.563 Y156.51 E.00092
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.04632
G1 X25.919 Y156.393 E-.07835
G1 X25.652 Y156.393 E-.05083
G1 X25.243 Y156.447 E-.07834
G1 X24.979 Y156.518 E-.0519
G1 X24.724 Y156.616 E-.05194
G1 X24.62 Y156.672 E-.02231
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.89 Y154.318 Z3 F36000
G1 Z2.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.865 Y154.317 E.00084
G2 X25.052 Y154.372 I.068 J6.96 E.0276
G2 X26.275 Y154.343 I.725 J4.628 E.9547
G1 X25.95 Y154.322 E.01102
M204 S10000
G1 X25.913 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.876 Y153.91 E.00127
G2 X24.989 Y153.97 I.065 J7.515 E.03012
G2 X26.317 Y153.938 I.788 J5.03 E1.03768
G1 X25.973 Y153.916 E.01167
M204 S250
G1 X25.936 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.886 Y153.518 E.00156
G2 X24.927 Y153.583 I.063 J8.051 E.03015
G2 X26.358 Y153.548 I.848 J5.417 E1.03523
G1 X25.996 Y153.525 E.01139
; WIPE_START
M204 S3000
G1 X25.886 Y153.518 E-.02085
G1 X25.498 Y153.523 E-.07368
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10909
G1 X24.029 Y153.812 E-.06726
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.607 Y160.554 Z3 F36000
G1 X28.552 Y162.336 Z3
G1 Z2.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X29.253 Y161.595 I-2.966 J-3.506 E.0346
G1 X28.843 Y161.185 E.01963
G3 X28.677 Y161.393 I-1.078 J-.69 E.00903
G1 X29.537 Y161.162 E.03016
G2 X29.86 Y160.474 I-4.122 J-2.35 E.02574
G1 X29.399 Y160.014 E.02205
G1 X29.422 Y159.929 E.00298
G1 X30.049 Y159.761 E.02199
G2 X30.121 Y159.009 I-3.543 J-.719 E.02561
G1 X29.49 Y158.378 E.03023
G3 X29.521 Y158.638 I-1.222 J.278 E.0089
G1 X30.088 Y158.486 E.01988
G2 X29.774 Y157.306 I-4.604 J.596 E.04146
G1 X29.207 Y157.458 E.01986
G3 X29.297 Y157.664 I-.936 J.534 E.00762
G1 X29.525 Y156.815 E.02972
G2 X29.109 Y156.22 I-4.227 J2.504 E.0246
G1 X28.481 Y156.388 E.02202
G1 X28.397 Y156.304 E.00401
G1 X28.566 Y155.676 E.02202
G2 X27.97 Y155.261 I-3.102 J3.815 E.0246
G1 X27.122 Y155.488 E.02972
G3 X27.327 Y155.578 I-.326 J1.021 E.00762
G1 X27.479 Y155.012 E.01986
G2 X26.299 Y154.697 I-1.777 J4.291 E.04146
G1 X26.147 Y155.264 E.01989
G3 X26.408 Y155.295 I-.016 J1.245 E.0089
G1 X25.779 Y154.666 E.03012
G2 X25.025 Y154.734 I.09 J5.208 E.02564
G1 X24.856 Y155.363 E.02205
G1 X24.771 Y155.386 E.00298
G1 X24.311 Y154.926 E.02205
G2 X23.623 Y155.248 I1.663 J4.445 E.02574
G1 X23.392 Y156.108 E.03015
G3 X23.601 Y155.943 I.89 J.911 E.00903
G1 X23.191 Y155.532 E.01967
G2 X22.326 Y156.394 I4.843 J5.725 E.04138
G1 X22.736 Y156.805 E.01964
G3 X22.88 Y156.625 I.934 J.598 E.00781
G1 X22.024 Y156.854 E.02999
G2 X21.716 Y157.511 I4.279 J2.407 E.0246
G1 X22.178 Y157.974 E.02216
G1 X22.152 Y158.084 E.00382
G1 X21.519 Y158.254 E.02218
G2 X21.45 Y158.973 I3.392 J.687 E.02452
G1 X22.076 Y159.599 E.02994
G3 X22.051 Y159.375 I1.051 J-.229 E.00762
G1 X21.484 Y159.527 E.01986
G2 X21.804 Y160.706 I5.356 J-.822 E.04143
G1 X22.369 Y160.554 E.01979
G3 X22.266 Y160.313 I1.095 J-.612 E.0089
G1 X22.037 Y161.168 E.02996
G2 X22.471 Y161.791 I4.095 J-2.394 E.02574
G1 X23.107 Y161.621 E.02229
G1 X23.164 Y161.68 E.00277
G1 X22.994 Y162.314 E.02221
G2 X23.617 Y162.749 I3.02 J-3.665 E.02574
G1 X24.477 Y162.518 E.03015
G3 X24.23 Y162.42 I.344 J-1.227 E.00903
G1 X24.08 Y162.981 E.01967
G2 X25.258 Y163.301 I2.002 J-5.04 E.04143
G1 X25.409 Y162.739 E.01971
G3 X25.181 Y162.704 I.017 J-.881 E.00782
G1 X25.812 Y163.335 E.0302
G2 X26.532 Y163.266 I.032 J-3.46 E.02452
G1 X26.699 Y162.643 E.02185
G2 X26.816 Y162.611 I-.09 J-.569 E.0041
G1 X27.272 Y163.068 E.02185
G2 X27.931 Y162.761 I-1.067 J-3.157 E.02466
G1 X28.161 Y161.906 E.02999
G3 X27.981 Y162.05 I-.638 J-.614 E.00782
G1 X28.391 Y162.46 E.01964
G3 X28.108 Y162.66 I-1.091 J-1.245 E.01176
; CHANGE_LAYER
; Z_HEIGHT: 2.8
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X28.391 Y162.46 E-.06588
G1 X27.981 Y162.05 E-.11024
G1 X28.161 Y161.906 E-.04376
G1 X27.942 Y162.72 E-.16012
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L14
M991 S0 P13 ;notify layer change


M204 S10000
G17
G3 Z3 I1.217 J0 P1  F36000
; object ids of layer 14 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer14 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.141 Y93.513
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.072 Y93.531 E.00241
G2 X230.381 Y93.356 I1.131 J3.48 E.73324
G1 X230.025 Y93.356 E.01207
G2 X229.442 Y93.432 I.178 J3.655 E.0199
G1 X229.199 Y93.497 E.00853
M204 S10000
G1 X229.246 Y93.906 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.918 E.00169
G2 X230.365 Y93.763 I1.005 J3.093 E.65151
G1 X230.041 Y93.763 E.01099
G2 X229.527 Y93.83 I.162 J3.248 E.01756
G1 X229.304 Y93.89 E.00781
M204 S250
G1 X229.348 Y94.284 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.291 E.00092
G2 X230.35 Y94.155 I.884 J2.72 E.53058
G1 X230.056 Y94.155 E.00921
G2 X229.609 Y94.214 I.147 J2.856 E.01417
G1 X229.406 Y94.268 E.00659
; WIPE_START
M204 S3000
G1 X229.319 Y94.291 E-.01696
G1 X229.04 Y94.399 E-.05684
G1 X228.771 Y94.536 E-.05741
G1 X228.524 Y94.696 E-.05586
G1 X228.181 Y94.989 E-.0858
G1 X227.98 Y95.212 E-.05691
G1 X227.825 Y95.426 E-.05022
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.38 Y92.689 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.07 Y92.824 E.01147
G2 X230.292 Y92.317 I2.125 J4.188 E.92084
G2 X229.468 Y92.373 I.05 J6.871 E.02796
G2 X228.519 Y92.625 I.726 J4.64 E.0333
G1 X228.435 Y92.664 E.00315
M204 S10000
G1 X228.215 Y92.317 F36000
G1 F1473.913
M204 S3000
G1 X227.885 Y92.461 E.01219
G2 X230.303 Y91.91 I2.309 J4.551 E1.00057
G2 X229.405 Y91.97 I.047 J7.425 E.03048
G2 X228.373 Y92.245 I.789 J5.042 E.03618
G1 X228.269 Y92.292 E.00388
M204 S250
G1 X228.056 Y91.96 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.706 Y92.112 E.01194
G2 X230.313 Y91.518 I2.487 J4.901 E.99797
G2 X229.343 Y91.583 I.046 J7.971 E.03049
G2 X228.233 Y91.878 I.85 J5.429 E.03609
G1 X228.11 Y91.935 E.00423
; WIPE_START
M204 S3000
G1 X227.706 Y92.112 E-.08376
G1 X227.21 Y92.402 E-.10929
G1 X226.744 Y92.74 E-.10932
G1 X226.525 Y92.927 E-.05467
G1 X226.44 Y93.013 E-.02297
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.583 Y93.164 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.67288
G1 F952.441
M204 S3000
G1 X228.503 Y93.194 E.00444
G2 X226.025 Y97.012 I1.699 J3.816 E.25216
G1 X226.076 Y97.665 E.03433
G1 X226.23 Y98.303 E.03437
G1 X226.48 Y98.908 E.03432
G1 X226.79 Y99.419 E.03128
G2 X228.904 Y93.04 I3.412 J-2.409 E.96574
G1 X228.639 Y93.142 E.01488
; OBJECT_ID: 12
; WIPE_START
G1 X228.503 Y93.194 E-.0275
G1 X228.114 Y93.393 E-.08319
G1 X227.574 Y93.765 E-.12456
G1 X227.255 Y94.051 E-.08149
G1 X227.093 Y94.222 E-.04469
G1 X227.031 Y94.298 E-.01858
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.797 Y96.73 Z3.2 F36000
G1 X211.885 Y99.389 Z3.2
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.054 Y99.153 E.00984
G2 X208.975 Y93.12 I-3.275 J-2.131 E.27741
G2 X208.573 Y93.12 I-.193 J5.337 E.01361
G2 X211.814 Y99.483 I.207 J3.901 E.52605
G1 X211.849 Y99.437 E.00196
M204 S10000
G1 X211.556 Y99.15 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.931 E.00912
G2 X208.956 Y93.527 I-2.934 J-1.909 E.2484
M73 P58 R20
G2 X208.594 Y93.527 I-.176 J4.802 E.01226
G2 X211.497 Y99.227 I.185 J3.495 E.47129
G1 X211.52 Y99.198 E.00124
M204 S250
G1 X211.239 Y98.92 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.0078
G2 X208.939 Y93.919 I-2.605 J-1.694 E.20422
G2 X208.615 Y93.919 I-.16 J4.294 E.01016
G2 X211.192 Y98.98 I.163 J3.104 E.38771
G1 X211.202 Y98.967 E.00051
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.05867
G1 X211.619 Y98.29 E-.09271
G1 X211.735 Y97.986 E-.06185
G1 X211.82 Y97.671 E-.06184
G1 X211.871 Y97.35 E-.06183
G1 X211.882 Y97.123 E-.04309
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.699 Y99.366 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.822 Y99.593 E.00873
G2 X208.867 Y92.317 I3.947 J-2.568 E.65584
G2 X208.041 Y92.373 I.05 J6.889 E.02804
G2 X204.575 Y99.166 I.728 J4.652 E.30085
G1 X204.667 Y99.315 E.00593
M204 S10000
G1 X204.346 Y99.57 F36000
G1 F1473.913
M204 S3000
G1 X204.48 Y99.815 E.00946
G2 X208.877 Y91.91 I4.288 J-2.79 E.71244
G2 X207.977 Y91.971 I.048 J7.448 E.03056
G2 X204.212 Y99.351 I.791 J5.054 E.32685
G1 X204.315 Y99.519 E.00666
M204 S250
G1 X204.007 Y99.766 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.151 Y100.029 E.00941
G2 X208.887 Y91.518 I4.617 J-3.004 E.71043
G2 X207.916 Y91.583 I.046 J7.989 E.03056
G2 X203.862 Y99.53 I.852 J5.442 E.32598
G1 X203.976 Y99.715 E.00681
; WIPE_START
M204 S3000
G1 X204.151 Y100.029 E-.0684
G1 X204.32 Y100.263 E-.0549
G1 X204.683 Y100.711 E-.10952
G1 X205.091 Y101.119 E-.1096
G1 X205.245 Y101.243 E-.03757
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.005 Y99.092 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436004
G1 F1526.394
M204 S3000
G1 X205.254 Y99.504 E.01576
G2 X204.468 Y97.019 I3.523 J-2.482 E.79843
G1 X204.474 Y97.255 E.00771
G1 X204.521 Y97.699 E.01457
G1 X204.679 Y98.356 E.02211
G1 X204.938 Y98.981 E.02211
G1 X204.973 Y99.04 E.00226
; OBJECT_ID: 11
; WIPE_START
G1 X205.254 Y99.504 E-.10304
G1 X205.428 Y99.737 E-.05516
G1 X205.73 Y100.072 E-.08571
G1 X206.244 Y100.511 E-.12846
G1 X206.278 Y100.533 E-.00764
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.894 Y98.6 Z3.2 F36000
G1 X183.909 Y94.678 Z3.2
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.838 Y94.775 E.00408
G2 X187.535 Y92.885 I3.488 J2.261 E.7369
G2 X187.106 Y92.885 I-.206 J5.684 E.01449
G2 X184.235 Y94.258 I.22 J4.151 E.11055
G1 X183.946 Y94.63 E.01596
M204 S10000
G1 X184.224 Y94.932 F36000
G1 F1473.913
M204 S3000
G1 X184.179 Y94.997 E.00267
G2 X187.516 Y93.292 I3.146 J2.04 E.66467
G2 X187.128 Y93.292 I-.189 J5.149 E.01315
G2 X184.41 Y94.679 I.198 J3.745 E.10637
G1 X184.259 Y94.883 E.0086
M204 S250
G1 X184.541 Y95.162 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.21 E.00183
G2 X187.499 Y93.684 I2.817 J1.827 E.55124
G2 X187.148 Y93.684 I-.173 J4.642 E.01098
G2 X184.714 Y94.925 I.176 J3.353 E.08825
G1 X184.576 Y95.114 E.00732
; WIPE_START
M204 S3000
G1 X184.507 Y95.21 E-.02246
G1 X184.33 Y95.514 E-.06683
G1 X184.212 Y95.775 E-.05445
G1 X184.129 Y95.999 E-.04551
G1 X184.038 Y96.341 E-.06711
G1 X183.983 Y96.688 E-.06681
G1 X183.967 Y96.987 E-.05683
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.43 Y92.318 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.414 Y92.317 E.00055
G2 X186.585 Y92.373 I.05 J6.912 E.02812
G2 X187.818 Y92.343 I.731 J4.666 E.96268
G1 X187.49 Y92.322 E.01113
M204 S10000
G1 X187.453 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.424 Y91.91 E.00099
G2 X186.521 Y91.971 I.048 J7.471 E.03065
G2 X187.86 Y91.938 I.794 J5.069 E1.04565
G1 X187.513 Y91.916 E.01177
M204 S250
G1 X187.476 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.435 Y91.518 E.00131
G2 X186.46 Y91.583 I.046 J8.011 E.03064
G2 X187.901 Y91.548 I.854 J5.456 E1.04262
G1 X187.536 Y91.525 E.01148
; WIPE_START
M204 S3000
G1 X187.435 Y91.518 E-.01935
G1 X187.035 Y91.523 E-.07585
G1 X186.46 Y91.583 E-.10989
G1 X186.176 Y91.636 E-.05494
G1 X185.617 Y91.786 E-.10983
G1 X185.568 Y91.805 E-.01014
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.537 Y92.603 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200627
G1 F3804.528
M204 S3000
G1 X187.092 Y92.604 E.00584
G2 X182.882 Y97.039 I.231 J4.435 E.08845
G1 X182.907 Y97.502 E.00607
G1 X182.937 Y97.734 E.00307
G1 X183.033 Y98.187 E.00608
G1 X183.1 Y98.414 E.0031
G1 X183.266 Y98.846 E.00607
G1 X183.476 Y99.258 E.00607
G1 X183.6 Y99.46 E.0031
G1 X183.872 Y99.835 E.00607
G1 X184.182 Y100.179 E.00607
G1 X184.353 Y100.341 E.0031
G1 X184.713 Y100.633 E.00607
G1 X185.103 Y100.886 E.0061
G1 X185.516 Y101.096 E.00607
G1 X185.734 Y101.187 E.00311
G1 X186.175 Y101.33 E.00607
G1 X186.559 Y101.413 E.00516
G2 X187.597 Y92.606 I.764 J-4.375 E.18942
; OBJECT_ID: 10
; WIPE_START
G1 X187.092 Y92.604 E-.09598
G1 X186.858 Y92.622 E-.04467
G1 X186.401 Y92.694 E-.08797
G1 X186.172 Y92.749 E-.04457
G1 X185.734 Y92.892 E-.08758
G1 X185.641 Y92.93 E-.01923
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.011 Y93.123 Z3.2 F36000
G1 X163.249 Y93.495 Z3.2
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.07 Y93.634 E.00766
G2 X166.53 Y92.7 I2.779 J3.419 E.81218
G2 X165.746 Y92.648 I-.807 J6.268 E.02663
G2 X163.442 Y93.362 I.103 J4.405 E.08269
G1 X163.298 Y93.461 E.0059
M204 S10000
G1 X163.488 Y93.824 F36000
G1 F1473.913
M204 S3000
G1 X163.327 Y93.951 E.00694
G2 X166.259 Y93.075 I2.524 J3.105 E.74473
G2 X165.756 Y93.055 I-.42 J4.29 E.01704
G2 X163.664 Y93.704 I.095 J4 E.0751
G1 X163.538 Y93.79 E.00519
M204 S250
G1 X163.718 Y94.141 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.573 Y94.255 E.00579
G2 X166.218 Y93.465 I2.277 J2.8 E.62224
G2 X165.766 Y93.447 I-.379 J3.879 E.01418
G2 X163.878 Y94.033 I.084 J3.608 E.0628
G1 X163.768 Y94.107 E.00416
; WIPE_START
M204 S3000
G1 X163.573 Y94.255 E-.04644
G1 X163.288 Y94.502 E-.07171
M73 P58 R19
G1 X163.035 Y94.783 E-.07183
G1 X162.813 Y95.089 E-.07176
G1 X162.624 Y95.416 E-.0718
G1 X162.523 Y95.639 E-.04646
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.118 Y101.47 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.483 E.00087
G2 X165.93 Y92.317 I1.691 J-4.427 E.55922
G2 X165.099 Y92.373 I.05 J6.93 E.02822
G2 X163.687 Y101.282 I.733 J4.682 E.40373
G1 X164.063 Y101.446 E.0139
M204 S10000
G1 X163.953 Y101.842 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.00159
G2 X165.941 Y91.91 I1.837 J-4.808 E.60715
G2 X165.035 Y91.971 I.048 J7.49 E.03074
G2 X163.502 Y101.645 I.796 J5.085 E.43842
G1 X163.898 Y101.818 E.01462
M204 S250
G1 X163.794 Y102.2 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.23 E.00212
G2 X165.951 Y91.518 I1.976 J-5.174 E.60516
G2 X164.974 Y91.584 I.046 J8.036 E.03073
G2 X163.324 Y101.995 I.857 J5.472 E.43705
G1 X163.739 Y102.176 E.01419
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.23 E-.02424
G1 X164.407 Y102.406 E-.11023
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.683 Y102.587 E-.02516
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.899 Y106.084 Z3.2 F36000
G1 X47.296 Y163.613 Z3.2
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.607 E.003
G2 X47.229 Y154.317 I-.251 J-4.642 E.48259
G2 X46.414 Y154.372 I.049 J6.803 E.02769
G2 X46.899 Y163.608 I.719 J4.593 E.46198
G1 X47.236 Y163.612 E.01143
M204 S10000
G1 X47.296 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.019 E.00372
G2 X47.24 Y153.91 I-.274 J-5.051 E.52502
G2 X46.35 Y153.97 I.047 J7.369 E.03021
G2 X46.877 Y164.02 I.782 J4.998 E.5027
G1 X47.236 Y164.019 E.01216
M204 S250
G1 X47.296 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00409
G2 X47.25 Y153.518 I-.295 J-5.443 E.52394
G2 X46.289 Y153.582 I.046 J7.907 E.03024
G2 X46.857 Y164.411 I.843 J5.385 E.50175
G1 X47.236 Y164.411 E.01191
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.03619
G1 X47.994 Y164.351 E-.10845
G1 X48.553 Y164.233 E-.10843
G1 X48.826 Y164.152 E-.05419
G1 X49.184 Y164.014 E-.07274
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.558 Y163.025 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X47.745 Y163.222 I-1.248 J-3.374 E.0284
G1 X49.792 Y155.581 E.26779
G2 X49.456 Y155.339 I-1.697 J2.009 E.01402
G1 X43.325 Y156.982 E.21484
G2 X43.153 Y157.36 I1.713 J1.01 E.01407
G1 X48.749 Y162.955 E.26787
G2 X49.127 Y162.783 I-.632 J-1.886 E.01407
G1 X50.769 Y156.654 E.21477
G2 X50.528 Y156.316 I-1.727 J.976 E.01407
G1 X42.881 Y158.365 E.26795
G2 X42.848 Y158.782 I2.632 J.421 E.01415
G1 X47.327 Y163.261 E.21441
G3 X46.483 Y163.214 I-.183 J-4.315 E.02867
G1 X48.694 Y154.96 E.28924
G2 X47.706 Y154.705 I-1.581 J4.094 E.03461
; WIPE_START
M73 P59 R19
G1 X48.694 Y154.96 E-.19383
G1 X48.441 Y155.906 E-.18617
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X45.651 Y154.933 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X44.794 Y155.361 I11.105 J23.308 E.03243
G1 X43.305 Y160.916 E.19468
G1 X43.251 Y160.795 E.0045
G1 X51.426 Y158.604 E.28647
G1 X51.433 Y158.731 E.00429
G1 X47.376 Y154.674 E.19418
G1 X47.504 Y154.682 E.00434
G1 X45.314 Y162.857 E.28649
G1 X45.192 Y162.803 E.0045
G1 X50.748 Y161.315 E.19468
G1 X50.67 Y161.422 E.0045
G1 X44.686 Y155.439 E.28642
G2 X43.79 Y156.269 I5.578 J6.923 E.0414
G1 X49.839 Y162.319 E.2896
G2 X50.55 Y161.587 I-10.122 J-10.539 E.03454
M204 S10000
G1 X50.85 Y161.139 F36000
G1 F1473.913
M204 S3000
G2 X51.242 Y160.268 I-6.195 J-3.313 E.03236
G1 X45.844 Y154.87 E.25839
G3 X46.216 Y154.77 I.661 J1.721 E.01306
G1 X44.242 Y162.139 E.25822
G3 X43.97 Y161.867 I1.158 J-1.43 E.01306
G1 X51.343 Y159.891 E.25839
G2 X51.443 Y158.934 I-23.243 J-2.917 E.03256
M204 S10000
G1 X51.405 Y158.402 F36000
G1 F1473.913
M204 S3000
G2 X51.154 Y157.413 I-11.387 J2.362 E.03455
G1 X42.889 Y159.627 E.28962
G2 X43.168 Y160.609 I15.059 J-3.755 E.03454
; OBJECT_ID: 14
; WIPE_START
G1 X42.889 Y159.627 E-.19386
G1 X43.836 Y159.374 E-.18614
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X36.371 Y157.782 Z3.2 F36000
G1 X26.706 Y155.722 Z3.2
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00743
G2 X25.951 Y155.594 I-.709 J3.333 E.01858
G1 X25.62 Y155.594 E.01119
G2 X26.839 Y155.757 I.165 J3.403 E.68281
G1 X26.764 Y155.737 E.00261
M204 S10000
G1 X26.601 Y156.115 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.063 E.00671
G2 X25.935 Y156.001 I-.624 J2.935 E.01623
G1 X25.636 Y156.001 E.0101
G2 X26.713 Y156.145 I.149 J2.997 E.60113
G1 X26.659 Y156.13 E.00189
M204 S250
G1 X26.5 Y156.493 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00558
G2 X25.919 Y156.393 I-.543 J2.551 E.01294
G1 X25.652 Y156.393 E.00839
G2 X26.592 Y156.518 I.134 J2.605 E.48395
G1 X26.558 Y156.509 E.0011
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.04521
G1 X25.919 Y156.393 E-.07834
G1 X25.652 Y156.393 E-.05084
G1 X25.243 Y156.447 E-.07838
G1 X24.979 Y156.518 E-.05187
G1 X24.724 Y156.616 E-.05192
G1 X24.615 Y156.674 E-.02345
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.895 Y154.318 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.874 Y154.317 E.0007
G2 X25.052 Y154.372 I.05 J6.858 E.02788
G2 X26.275 Y154.343 I.725 J4.628 E.9547
G1 X25.954 Y154.322 E.01087
M204 S10000
G1 X25.918 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.885 Y153.91 E.00114
G2 X24.989 Y153.97 I.047 J7.413 E.03041
G2 X26.317 Y153.938 I.788 J5.03 E1.03767
G1 X25.978 Y153.916 E.01151
M204 S250
G1 X25.941 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.895 Y153.518 E.00145
G2 X24.927 Y153.583 I.046 J7.957 E.03042
G2 X26.358 Y153.548 I.848 J5.417 E1.03523
G1 X26.001 Y153.525 E.01123
; WIPE_START
M204 S3000
G1 X25.895 Y153.518 E-.02019
G1 X25.498 Y153.523 E-.0753
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10909
G1 X24.034 Y153.81 E-.0663
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X24.87 Y154.767 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X24.699 Y155.406 E.02237
G1 X24.929 Y155.344 E.00808
G1 X24.462 Y154.877 E.02237
; WIPE_START
G1 X24.929 Y155.344 E-.16094
G1 X24.699 Y155.406 E-.05812
G1 X24.87 Y154.767 E-.16093
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.45 Y158.986 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X21.507 Y159.668 I5.993 J-.159 E.02315
G1 X22.066 Y159.518 E.01961
G1 X22.051 Y159.374 E.00489
G1 X21.46 Y158.783 E.02828
G3 X21.495 Y158.406 I1.812 J-.024 E.01283
G1 X22.114 Y158.24 E.0217
G3 X22.219 Y157.815 I1.679 J.188 E.01488
G1 X21.772 Y157.368 E.02141
G3 X21.924 Y157.027 I1.683 J.548 E.01265
G1 X22.732 Y156.811 E.02832
G3 X22.824 Y156.693 I.605 J.379 E.00506
G1 X22.41 Y156.279 E.01984
G3 X23.306 Y155.448 I6.639 J6.27 E.0414
G1 X23.723 Y155.864 E.01993
G2 X23.201 Y156.277 I2.184 J3.3 E.02253
G1 X23.45 Y155.348 E.03255
G1 X25.985 Y154.672 E.0888
G1 X26.662 Y155.349 E.03241
G2 X26.005 Y155.25 I-.799 J3.051 E.02253
G1 X26.157 Y154.682 E.01988
G3 X27.347 Y154.961 I-1.214 J7.874 E.0414
G1 X27.196 Y155.521 E.01965
G1 X27.321 Y155.581 E.00469
G1 X28.143 Y155.361 E.0288
G3 X28.445 Y155.58 I-.88 J1.532 E.01265
G1 X28.281 Y156.192 E.02145
G3 X28.594 Y156.504 I-6.612 J6.924 E.01497
G1 X29.206 Y156.34 E.02145
G3 X29.425 Y156.642 I-1.329 J1.193 E.01264
G1 X29.207 Y157.453 E.02841
G3 X29.265 Y157.589 I-.649 J.357 E.005
G1 X29.83 Y157.437 E.01979
G3 X30.102 Y158.629 I-3.97 J1.535 E.04151
G1 X29.536 Y158.78 E.01985
G2 X29.436 Y158.124 I-3.177 J.148 E.02253
G1 X30.111 Y158.799 E.03233
G1 X29.437 Y161.335 E.08884
G1 X28.509 Y161.584 E.03255
G2 X28.921 Y161.063 I-2.886 J-2.704 E.02253
G1 X29.337 Y161.479 E.01993
G3 X28.507 Y162.376 I-7.101 J-5.743 E.0414
G1 X28.092 Y161.961 E.01984
G3 X27.975 Y162.053 I-.405 J-.396 E.00507
G1 X27.76 Y162.854 E.02807
G3 X27.417 Y163.012 I-.924 J-1.553 E.01283
G1 X26.965 Y162.561 E.02163
G3 X26.544 Y162.676 I-.703 J-1.744 E.01481
G1 X26.379 Y163.291 E.02154
G3 X26.002 Y163.325 I-.353 J-1.776 E.01283
G1 X25.411 Y162.734 E.02828
G1 X25.268 Y162.719 E.00489
G1 X25.118 Y163.279 E.01961
G3 X23.948 Y162.924 I1.687 J-7.67 E.0414
G1 X24.102 Y162.352 E.02006
G2 X24.724 Y162.598 I1.416 J-2.664 E.0227
G1 X23.797 Y162.847 E.0325
G1 X21.937 Y160.995 E.08884
G1 X22.186 Y160.064 E.03262
G2 X22.427 Y160.685 I3.225 J-.892 E.02259
G1 X21.863 Y160.837 E.01977
G3 X21.538 Y159.869 I6.267 J-2.638 E.03458
; WIPE_START
G1 X21.863 Y160.837 E-.19394
G1 X22.427 Y160.685 E-.11099
G1 X22.284 Y160.317 E-.07508
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.578 Y161.909 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X23.216 Y161.738 E.02237
G1 X23.047 Y161.569 E.00808
G1 X22.876 Y162.208 E.02237
; WIPE_START
G1 X23.047 Y161.569 E-.16094
G1 X23.216 Y161.738 E-.05812
G1 X22.578 Y161.909 E-.16094
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.909 Y160.323 Z3.2 F36000
G1 Z2.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X29.435 Y159.85 E.02269
G1 X29.378 Y160.087 E.00828
G1 X30.024 Y159.914 E.02267
; CHANGE_LAYER
; Z_HEIGHT: 3
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X29.378 Y160.087 E-.16063
G1 X29.435 Y159.85 E-.05863
G1 X29.909 Y160.323 E-.16074
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L15
M991 S0 P14 ;notify layer change


M204 S10000
G17
G3 Z3.2 I1.217 J0 P1  F36000
; object ids of layer 15 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer15 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.139 Y93.513
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.072 Y93.531 E.00234
G2 X230.381 Y93.356 I1.131 J3.478 E.73284
G1 X230.025 Y93.356 E.01207
G2 X229.442 Y93.432 I.178 J3.653 E.01991
G1 X229.197 Y93.498 E.0086
M204 S10000
G1 X229.244 Y93.906 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.918 E.00161
G2 X230.365 Y93.763 I1.005 J3.091 E.65116
G1 X230.041 Y93.763 E.01099
G2 X229.527 Y93.83 I.162 J3.246 E.01756
G1 X229.302 Y93.891 E.00788
M204 S250
G1 X229.345 Y94.284 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.291 E.00085
G2 X230.35 Y94.155 I.884 J2.718 E.53029
G1 X230.056 Y94.155 E.00921
G2 X229.609 Y94.214 I.147 J2.854 E.01417
G1 X229.403 Y94.269 E.00666
; WIPE_START
M204 S3000
G1 X229.319 Y94.291 E-.01653
G1 X229.04 Y94.399 E-.0569
G1 X228.773 Y94.535 E-.05688
G1 X228.52 Y94.699 E-.05741
G1 X228.181 Y94.989 E-.08475
G1 X227.889 Y95.33 E-.08526
G1 X227.825 Y95.429 E-.02228
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.415 Y92.673 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.07 Y92.824 E.01276
G2 X230.3 Y92.317 I2.125 J4.187 E.92044
G2 X229.468 Y92.373 I.032 J6.775 E.02825
G2 X228.519 Y92.625 I.726 J4.639 E.0333
G1 X228.469 Y92.648 E.00186
M204 S10000
G1 X228.25 Y92.302 F36000
G1 F1473.913
M204 S3000
G1 X227.884 Y92.461 E.01348
G2 X230.311 Y91.91 I2.309 J4.55 E1.00017
G2 X229.405 Y91.97 I.031 J7.339 E.03077
G2 X228.373 Y92.245 I.789 J5.041 E.03619
G1 X228.304 Y92.277 E.00259
M204 S250
G1 X228.09 Y91.944 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.706 Y92.112 E.01313
G2 X230.321 Y91.518 I2.487 J4.9 E.99759
G2 X229.343 Y91.583 I.03 J7.888 E.03075
G2 X228.233 Y91.878 I.85 J5.429 E.0361
G1 X228.145 Y91.919 E.00304
; WIPE_START
M204 S3000
G1 X227.706 Y92.112 E-.09099
G1 X227.21 Y92.402 E-.10931
G1 X226.973 Y92.565 E-.05463
G1 X226.525 Y92.927 E-.10932
G1 X226.467 Y92.986 E-.01575
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.68 Y93.122 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672893
G1 F952.423
M204 S3000
G1 X228.307 Y93.29 E.02146
G2 X226.025 Y97.012 I1.893 J3.721 E.24064
G1 X226.076 Y97.665 E.03434
G1 X226.227 Y98.294 E.0339
G1 X226.39 Y98.718 E.02377
G1 X226.704 Y99.294 E.03436
G1 X227.098 Y99.807 E.03391
G1 X227.574 Y100.258 E.03433
G1 X228.114 Y100.63 E.03436
G1 X228.698 Y100.909 E.03391
G1 X229.13 Y101.049 E.02376
G1 X229.775 Y101.167 E.03434
G1 X230.421 Y101.184 E.03389
G1 X231.072 Y101.098 E.03437
G1 X231.7 Y100.912 E.03433
G1 X232.285 Y100.634 E.03391
G1 X232.666 Y100.387 E.02377
G1 X233.157 Y99.966 E.03391
G1 X233.578 Y99.474 E.03391
G1 X233.826 Y99.093 E.02378
G1 X234.104 Y98.509 E.03389
G1 X234.29 Y97.881 E.03434
G1 X234.375 Y97.23 E.03438
G1 X234.359 Y96.583 E.03389
G1 X234.288 Y96.135 E.02376
G1 X234.104 Y95.514 E.03391
G1 X233.825 Y94.93 E.03391
G1 X233.578 Y94.549 E.02377
G1 X233.157 Y94.057 E.03391
G1 X232.659 Y93.631 E.03434
G1 X232.1 Y93.289 E.03434
G1 X231.494 Y93.038 E.03434
G1 X230.857 Y92.885 E.03435
G1 X230.287 Y92.837 E.02996
G2 X228.736 Y93.101 I-.087 J4.174 E.08288
; OBJECT_ID: 12
; WIPE_START
G1 X228.307 Y93.29 E-.08921
G1 X227.927 Y93.508 E-.08309
G1 X227.575 Y93.766 E-.08307
G1 X227.248 Y94.057 E-.08313
G1 X227.102 Y94.22 E-.0415
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.876 Y96.677 Z3.4 F36000
G1 X211.88 Y99.396 Z3.4
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.053 Y99.152 E.01012
G2 X208.969 Y93.119 I-3.275 J-2.13 E.2775
G1 X208.586 Y93.119 E.01296
G2 X211.812 Y99.482 I.191 J3.902 E.52662
G1 X211.843 Y99.443 E.00169
M204 S10000
G1 X211.551 Y99.157 F36000
G1 F1473.913
M204 S3000
G1 X211.712 Y98.93 E.00939
G2 X208.953 Y93.527 I-2.934 J-1.908 E.24846
G1 X208.602 Y93.527 E.01187
G2 X211.496 Y99.226 I.175 J3.496 E.47163
G1 X211.514 Y99.204 E.00097
M204 S250
G1 X211.235 Y98.927 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.383 Y98.717 E.00806
G2 X208.937 Y93.919 I-2.606 J-1.694 E.20424
G1 X208.618 Y93.919 E.01003
G2 X211.192 Y98.98 I.16 J3.104 E.38782
G1 X211.197 Y98.973 E.00026
; WIPE_START
M204 S3000
G1 X211.383 Y98.717 E-.06022
G1 X211.619 Y98.29 E-.09271
G1 X211.735 Y97.986 E-.06183
G1 X211.82 Y97.671 E-.06187
G1 X211.871 Y97.35 E-.06183
G1 X211.882 Y97.131 E-.04155
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.69 Y99.352 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.822 Y99.593 E.00931
G2 X208.875 Y92.317 I3.946 J-2.569 E.65553
G2 X208.041 Y92.373 I.033 J6.802 E.02832
G2 X204.575 Y99.166 I.728 J4.652 E.30085
G1 X204.659 Y99.301 E.00537
M204 S10000
G1 X204.338 Y99.555 F36000
G1 F1473.913
M204 S3000
G1 X204.48 Y99.815 E.01004
G2 X208.886 Y91.91 I4.288 J-2.791 E.71213
G2 X207.977 Y91.971 I.031 J7.364 E.03085
G2 X204.212 Y99.351 I.791 J5.054 E.32686
G1 X204.306 Y99.504 E.0061
M204 S250
G1 X203.993 Y99.754 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
M73 P60 R19
G1 X204 Y99.783 E.00092
G2 X208.896 Y91.518 I4.768 J-2.758 E.71921
G2 X207.916 Y91.583 I.03 J7.907 E.03083
G2 X203.862 Y99.529 I.852 J5.442 E.32598
G1 X203.963 Y99.702 E.00628
; WIPE_START
M204 S3000
G1 X204 Y99.783 E-.01685
G1 X204.32 Y100.263 E-.10969
G1 X204.683 Y100.711 E-.1096
G1 X205.091 Y101.119 E-.10955
G1 X205.232 Y101.233 E-.03432
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.996 Y99.078 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436052
G1 F1526.207
M204 S3000
G1 X205.251 Y99.5 E.01613
G2 X204.468 Y97.019 I3.525 J-2.477 E.79855
G1 X204.474 Y97.255 E.00771
G1 X204.521 Y97.699 E.01457
G1 X204.679 Y98.356 E.02211
G1 X204.938 Y98.981 E.02212
G1 X204.965 Y99.026 E.00172
; OBJECT_ID: 11
; WIPE_START
G1 X205.251 Y99.5 E-.10518
G1 X205.428 Y99.737 E-.05613
G1 X205.73 Y100.072 E-.08572
G1 X206.244 Y100.511 E-.12852
G1 X206.264 Y100.524 E-.00445
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.875 Y98.613 Z3.4 F36000
G1 X183.87 Y94.731 Z3.4
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.729 Y94.963 E.0092
G2 X187.975 Y92.931 I3.603 J2.076 E.71509
G2 X187.23 Y92.882 I-.757 J5.866 E.02529
G2 X183.965 Y94.599 I.102 J4.157 E.12936
G1 X183.905 Y94.683 E.00347
M204 S10000
G1 X184.221 Y94.935 F36000
G1 F1473.913
M204 S3000
G1 X184.182 Y94.998 E.00252
G2 X183.639 Y97.737 I3.151 J2.048 E.09682
G2 X187.24 Y93.289 I3.686 J-.697 E.57742
G2 X184.412 Y94.681 I.093 J3.757 E.11009
G1 X184.257 Y94.887 E.00874
M204 S250
G1 X184.538 Y95.165 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.514 Y95.214 E.0017
G2 X187.676 Y93.698 I2.819 J1.824 E.54582
G2 X187.25 Y93.681 I-.352 J3.599 E.01335
G2 X184.72 Y94.93 I.083 J3.357 E.09132
G1 X184.575 Y95.118 E.00745
; WIPE_START
M204 S3000
G1 X184.514 Y95.214 E-.0216
G1 X184.255 Y95.673 E-.10009
G1 X184.129 Y96.001 E-.06681
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.967 Y96.992 E-.05786
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.434 Y92.318 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.422 Y92.317 E.00042
G2 X186.585 Y92.373 I.033 J6.819 E.02841
G2 X187.818 Y92.343 I.73 J4.666 E.96268
G1 X187.494 Y92.322 E.01097
M204 S10000
G1 X187.458 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.433 Y91.91 E.00087
G2 X186.522 Y91.971 I.031 J7.387 E.03093
G2 X187.86 Y91.938 I.793 J5.069 E1.04566
G1 X187.518 Y91.916 E.01161
M204 S250
G1 X187.481 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.443 Y91.518 E.00121
G2 X186.46 Y91.583 I.03 J7.929 E.03091
G2 X187.901 Y91.548 I.854 J5.456 E1.04268
G1 X187.541 Y91.525 E.01131
; WIPE_START
M204 S3000
G1 X187.443 Y91.518 E-.0187
G1 X187.035 Y91.523 E-.07747
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10987
G1 X185.617 Y91.786 E-.05491
G1 X185.572 Y91.803 E-.00916
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.485 Y92.606 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200575
G1 F3805.777
M204 S3000
G1 X187.324 Y92.597 E.00211
G1 X186.86 Y92.622 E.00609
G1 X186.403 Y92.694 E.00607
G1 X186.173 Y92.749 E.0031
G1 X185.73 Y92.893 E.0061
G1 X185.308 Y93.081 E.00607
G1 X184.905 Y93.314 E.0061
G1 X184.529 Y93.587 E.0061
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.00609
G1 X183.6 Y94.618 E.00606
G1 X183.476 Y94.82 E.00311
G1 X183.266 Y95.234 E.00609
G1 X183.1 Y95.667 E.00607
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.0061
G1 X182.882 Y97.037 E.00607
G1 X182.906 Y97.501 E.00609
G1 X182.937 Y97.736 E.0031
G1 X183.034 Y98.189 E.00607
G1 X183.178 Y98.633 E.00612
G1 X183.366 Y99.056 E.00607
G1 X183.599 Y99.458 E.0061
G1 X183.872 Y99.835 E.0061
G1 X184.183 Y100.18 E.00609
G1 X184.529 Y100.491 E.00609
G1 X184.903 Y100.763 E.00607
G1 X185.105 Y100.887 E.00311
G1 X185.52 Y101.098 E.00609
G1 X185.952 Y101.264 E.00607
G1 X186.401 Y101.384 E.00609
G1 X186.86 Y101.457 E.0061
G1 X187.324 Y101.481 E.00609
G1 X187.789 Y101.457 E.00609
G1 X188.246 Y101.384 E.00607
G1 X188.476 Y101.329 E.0031
G1 X188.918 Y101.185 E.00609
G1 X189.341 Y100.997 E.00607
G1 X189.744 Y100.764 E.0061
G1 X190.12 Y100.491 E.0061
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.0061
G1 X191.05 Y99.458 E.0061
G1 X191.282 Y99.056 E.00609
G1 X191.417 Y98.762 E.00424
G1 X191.549 Y98.412 E.00491
G1 X191.669 Y97.963 E.00609
G1 X191.742 Y97.503 E.0061
G1 X191.766 Y97.039 E.00609
G1 X191.742 Y96.575 E.00609
G1 X191.669 Y96.116 E.0061
G1 X191.549 Y95.667 E.00609
G1 X191.383 Y95.234 E.00607
G1 X191.281 Y95.02 E.00311
G1 X191.048 Y94.618 E.00609
G1 X190.776 Y94.244 E.00607
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.00609
G1 X189.745 Y93.315 E.00607
G1 X189.543 Y93.191 E.00311
G1 X189.129 Y92.98 E.00609
G1 X188.697 Y92.815 E.00607
G1 X188.248 Y92.694 E.00609
G1 X187.789 Y92.622 E.0061
G1 X187.545 Y92.609 E.0032
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.04191
G1 X186.86 Y92.622 E-.08833
G1 X186.403 Y92.694 E-.08796
G1 X186.173 Y92.749 E-.04496
G1 X185.73 Y92.893 E-.08836
G1 X185.593 Y92.954 E-.02848
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.963 Y93.14 Z3.4 F36000
G1 X163.245 Y93.498 Z3.4
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.07 Y93.633 E.0075
G2 X166.53 Y92.7 I2.779 J3.422 E.81264
G2 X165.74 Y92.648 I-.803 J6.223 E.0268
G2 X163.442 Y93.362 I.108 J4.407 E.08251
G1 X163.294 Y93.464 E.00607
M204 S10000
G1 X163.484 Y93.827 F36000
G1 F1473.913
M204 S3000
G1 X163.327 Y93.951 E.00678
G2 X166.259 Y93.075 I2.525 J3.105 E.74473
G2 X165.751 Y93.055 I-.419 J4.278 E.01721
G2 X163.664 Y93.704 I.1 J4 E.07493
G1 X163.534 Y93.793 E.00535
M204 S250
G1 X163.714 Y94.144 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.573 Y94.255 E.00564
G2 X166.218 Y93.465 I2.277 J2.8 E.62224
G2 X165.761 Y93.447 I-.379 J3.866 E.01434
G2 X163.878 Y94.033 I.089 J3.608 E.06264
G1 X163.764 Y94.11 E.00431
; WIPE_START
M204 S3000
G1 X163.573 Y94.255 E-.04556
G1 X163.288 Y94.502 E-.07169
G1 X162.92 Y94.933 E-.10769
G1 X162.714 Y95.25 E-.07177
G1 X162.543 Y95.587 E-.0718
G1 X162.521 Y95.643 E-.01149
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.085 Y101.452 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.375 Y101.565 E.01054
G2 X165.939 Y92.317 I1.457 J-4.51 E.55046
G2 X165.099 Y92.373 I.033 J6.843 E.02851
G2 X163.911 Y101.388 I.733 J4.682 E.41214
G1 X164.029 Y101.431 E.00424
M204 S10000
G1 X163.947 Y101.841 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.00179
G2 X165.949 Y91.91 I1.836 J-4.808 E.60681
G2 X165.035 Y91.971 I.031 J7.405 E.03103
G2 X163.746 Y101.76 I.796 J5.084 E.44754
G1 X163.891 Y101.818 E.0053
M204 S250
G1 X163.799 Y102.197 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.128 Y102.326 E.01107
G2 X165.96 Y91.518 I1.702 J-5.27 E.59575
G2 X164.974 Y91.584 I.03 J7.952 E.031
G2 X163.586 Y102.119 I.856 J5.472 E.44615
G1 X163.743 Y102.177 E.00524
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.128 Y102.326 E-.07845
G1 X164.407 Y102.406 E-.05513
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.688 Y102.587 E-.02604
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.904 Y106.085 Z3.4 F36000
G1 X47.303 Y163.613 Z3.4
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.00279
G2 X47.238 Y154.317 I-.252 J-4.644 E.48253
G2 X46.414 Y154.372 I.033 J6.719 E.02797
G2 X46.898 Y163.613 I.719 J4.595 E.46222
G1 X47.243 Y163.613 E.01165
M204 S10000
G1 X47.303 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.019 E.00351
G2 X47.249 Y153.91 I-.274 J-5.051 E.52472
G2 X46.35 Y153.97 I.031 J7.28 E.0305
M73 P60 R18
G2 X46.877 Y164.02 I.782 J4.998 E.5027
G1 X47.243 Y164.019 E.01237
M204 S250
G1 X47.303 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00389
G2 X47.259 Y153.518 I-.295 J-5.442 E.52364
G2 X46.289 Y153.582 I.029 J7.823 E.0305
G2 X46.857 Y164.411 I.843 J5.385 E.50173
G1 X47.243 Y164.411 E.0121
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.03499
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.1084
G1 X48.826 Y164.152 E-.1084
G1 X49.189 Y164.012 E-.07394
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.314 Y163.261 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X46.342 Y163.19 I-.053 J-5.974 E.033
G1 X48.561 Y154.909 E.29022
G2 X47.671 Y154.7 I-1.525 J4.495 E.03101
G1 X44.554 Y155.535 E.10922
G1 X44.612 Y155.493 E.00242
G1 X43.214 Y160.711 E.18286
G1 X43.185 Y160.645 E.00242
G1 X45.463 Y162.924 E.10906
G1 X45.398 Y162.895 E.00242
G1 X50.616 Y161.496 E.18286
G1 X50.574 Y161.554 E.00242
G1 X51.409 Y158.438 E.10922
G1 X51.422 Y158.52 E.00281
G1 X47.589 Y154.687 E.18348
G1 X47.36 Y154.673 E.00774
G1 X45.212 Y162.812 E.28492
; WIPE_START
G1 X45.722 Y160.878 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.297 Y160.897 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X51.432 Y158.723 E.28504
; WIPE_START
G1 X49.5 Y159.239 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.778 Y156.67 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X51.203 Y157.546 I-4.417 J2.682 E.033
G1 X42.917 Y159.766 E.29034
G3 X42.847 Y158.795 I4.387 J-.804 E.03304
M204 S10000
G1 X42.888 Y158.315 F36000
G1 F1473.913
M204 S3000
G3 X43.215 Y157.221 I9.812 J2.334 E.03866
G1 X48.889 Y162.895 E.2716
G1 X48.959 Y162.863 E.00261
G1 X50.663 Y156.502 E.2229
G1 X50.617 Y156.439 E.00266
G1 X42.862 Y158.517 E.27176
G1 X42.858 Y158.591 E.00253
G1 X47.517 Y163.251 E.22303
G1 X47.592 Y163.247 E.00253
G1 X49.67 Y155.492 E.27176
G1 X49.606 Y155.445 E.00266
G1 X43.247 Y157.149 E.22286
G3 X43.883 Y156.163 I6.974 J3.803 E.03978
G1 X49.946 Y162.225 E.29019
G3 X49.142 Y162.774 I-3.011 J-3.543 E.03302
; WIPE_START
G1 X49.946 Y162.225 E-.18502
G1 X49.22 Y161.499 E-.19498
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.735 Y161.332 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X44.777 Y155.373 E.28524
; WIPE_START
G1 X46.191 Y156.787 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X45.995 Y154.821 Z3.4 F36000
G1 Z3
G1 E.4 F1800
M73 P61 R18
G1 F1473.913
M204 S3000
G1 X51.288 Y160.113 E.25335
M204 S10000
G1 X51.305 Y160.047 F36000
G1 F1473.913
M204 S3000
G1 X44.076 Y161.985 E.25335
M204 S10000
G1 X44.124 Y162.033 F36000
G1 F1473.913
M204 S3000
G1 X46.061 Y154.803 E.25335
; OBJECT_ID: 14
; WIPE_START
G1 X45.544 Y156.735 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.922 Y156.327 Z3.4 F36000
G1 X26.738 Y155.729 Z3.4
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.667 Y155.71 E.00249
G2 X25.709 Y155.592 I-.892 J3.29 E.03277
G1 X25.438 Y155.608 E.00918
G2 X27.006 Y155.821 I.337 J3.392 E.67097
G1 X26.795 Y155.749 E.00755
M204 S10000
G1 X26.612 Y156.116 F36000
G1 F1473.913
M204 S3000
G1 X26.561 Y156.103 E.00177
G2 X25.719 Y155.999 I-.786 J2.897 E.02884
G1 X25.477 Y156.013 E.00819
G2 X26.86 Y156.201 I.298 J2.987 E.59074
G1 X26.669 Y156.136 E.00683
M204 S250
G1 X26.491 Y156.489 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.482 E.001
G2 X25.728 Y156.391 I-.684 J2.518 E.0232
G1 X25.514 Y156.404 E.00671
G2 X26.719 Y156.567 I.261 J2.596 E.47562
G1 X26.548 Y156.508 E.00568
; WIPE_START
M204 S3000
G1 X26.46 Y156.482 E-.0174
G1 X26.194 Y156.422 E-.0519
G1 X25.728 Y156.391 E-.08862
G1 X25.514 Y156.404 E-.04068
G1 X25.11 Y156.479 E-.07822
G1 X24.85 Y156.563 E-.0519
G1 X24.603 Y156.673 E-.05128
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.899 Y154.318 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.882 Y154.317 E.00056
G2 X25.052 Y154.372 I.033 J6.762 E.02817
G2 X26.275 Y154.343 I.724 J4.628 E.9548
G1 X25.959 Y154.322 E.01072
M204 S10000
G1 X25.923 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.893 Y153.91 E.00101
G2 X24.989 Y153.97 I.031 J7.326 E.0307
G2 X26.317 Y153.938 I.787 J5.03 E1.03773
G1 X25.983 Y153.916 E.01135
M204 S250
G1 X25.946 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.903 Y153.518 E.00134
G2 X24.927 Y153.583 I.03 J7.874 E.03069
G2 X26.358 Y153.548 I.848 J5.418 E1.03529
G1 X26.006 Y153.525 E.01108
; WIPE_START
M204 S3000
G1 X25.903 Y153.518 E-.01953
G1 X25.498 Y153.523 E-.07692
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10906
G1 X24.09 Y153.784 E-.05457
G1 X24.037 Y153.804 E-.0108
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.738 Y155.37 Z3.4 F36000
G1 Z3
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.858 Y155.249 I-.932 J3.534 E.03014
G1 X26.013 Y154.674 E.02017
G1 X26.197 Y154.685 E.00625
G1 X26.935 Y155.423 E.03532
G3 X27.063 Y155.473 I-.128 J.509 E.00467
G1 X27.214 Y154.91 E.01975
G2 X26.393 Y154.712 I-1.505 J4.438 E.02861
G1 X23.109 Y155.592 E.1151
G2 X22.504 Y156.173 I3.116 J3.851 E.02842
G1 X22.913 Y156.582 E.01957
G1 X22.998 Y156.486 E.00434
G1 X23.269 Y155.475 E.03544
G1 X23.422 Y155.364 E.0064
G1 X23.845 Y155.787 E.02023
G2 X23.135 Y156.336 I2.143 J3.502 E.03043
; WIPE_START
G1 X23.845 Y155.787 E-.17048
G1 X23.422 Y155.364 E-.11357
G1 X23.269 Y155.475 E-.03591
G1 X23.188 Y155.78 E-.06005
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.353 Y157.482 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.622 Y156.986 I1.808 J.66 E.01917
G1 X21.849 Y157.194 E.02709
G1 X22.274 Y157.669 E.02158
G2 X22.081 Y158.396 I3.78 J1.39 E.02547
G1 X21.472 Y158.559 E.02135
G1 X22.035 Y159.158 E.02785
G3 X22.049 Y158.597 I5.393 J-.147 E.01902
; WIPE_START
G1 X22.035 Y159.158 E-.10674
G1 X21.472 Y158.559 E-.1563
G1 X22.067 Y158.4 E-.11696
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.165 Y159.99 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X22.497 Y160.813 I3.744 J-1.031 E.03011
G1 X21.921 Y160.967 E.02019
G1 X21.844 Y160.795 E.0064
G1 X22.112 Y159.793 E.0351
G3 X22.09 Y159.658 I.63 J-.175 E.00465
G1 X21.529 Y159.808 E.01965
G2 X21.763 Y160.613 I8.036 J-1.903 E.0284
G1 X24.168 Y163.018 E.1151
G2 X24.977 Y163.257 I1.725 J-4.356 E.02861
G1 X25.129 Y162.689 E.01987
G1 X25.012 Y162.668 E.00404
G1 X23.984 Y162.943 E.03602
G1 X23.819 Y162.861 E.00623
G1 X23.973 Y162.287 E.02013
G2 X24.812 Y162.63 I1.816 J-3.243 E.03076
; WIPE_START
G1 X23.973 Y162.287 E-.17226
G1 X23.819 Y162.861 E-.11299
G1 X23.984 Y162.943 E-.03499
G1 X24.288 Y162.862 E-.05977
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.189 Y162.736 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X25.627 Y162.75 I-.415 J-5.379 E.01902
G1 X26.226 Y163.313 E.02785
G1 X26.39 Y162.704 E.02135
G2 X27.114 Y162.51 I-.606 J-3.712 E.02543
G1 X27.592 Y162.936 E.02167
G1 X27.797 Y162.168 E.02691
G3 X27.304 Y162.437 I-2.828 J-4.604 E.01902
; WIPE_START
G1 X27.797 Y162.168 E-.10674
G1 X27.592 Y162.936 E-.15103
G1 X27.114 Y162.51 E-.12161
G1 X27.111 Y162.511 E-.00062
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.449 Y161.637 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X28.999 Y160.94 I-1.924 J-2.083 E.03014
G1 X29.421 Y161.363 E.02023
G1 X29.31 Y161.516 E.0064
G1 X28.309 Y161.784 E.03508
G3 X28.203 Y161.872 I-.385 J-.36 E.00467
G1 X28.613 Y162.282 E.01962
G2 X29.194 Y161.677 I-3.277 J-3.728 E.02842
G1 X30.074 Y158.392 E.1151
G2 X29.876 Y157.572 I-4.628 J.682 E.02861
G1 X29.315 Y157.722 E.01965
G3 X29.363 Y157.85 I-.585 J.292 E.00465
G1 X30.1 Y158.588 E.0353
G1 X30.11 Y158.773 E.00628
G1 X29.54 Y158.926 E.01998
G2 X29.415 Y158.047 I-3.883 J.101 E.03011
; WIPE_START
G1 X29.54 Y158.926 E-.16865
G1 X30.11 Y158.773 E-.11217
G1 X30.1 Y158.588 E-.03525
G1 X29.862 Y158.35 E-.06393
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.819 Y156.783 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X29.112 Y157.262 I-4.463 J3.056 E.01902
G1 X29.318 Y156.494 E.02691
G1 X28.691 Y156.625 E.02167
G2 X28.162 Y156.089 I-2.296 J1.741 E.02555
G1 X28.291 Y155.468 E.0215
G1 X27.527 Y155.672 E.02675
G3 X27.998 Y155.969 I-1.174 J2.386 E.01887
; WIPE_START
G1 X27.527 Y155.672 E-.10572
G1 X28.291 Y155.468 E-.15018
G1 X28.162 Y156.089 E-.12068
G1 X28.175 Y156.102 E-.00342
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.101 Y155.316 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X24.613 Y154.828 E.02338
G3 X24.714 Y154.8 I.181 J.471 E.00357
G1 X24.538 Y155.459 E.02309
; WIPE_START
G1 X24.714 Y154.8 E-.17535
G1 X24.613 Y154.828 E-.02705
G1 X25.101 Y155.316 E-.1776
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.934 Y161.443 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.758 Y162.102 E.02307
G3 X22.684 Y162.027 I.317 J-.391 E.00357
G1 X23.345 Y161.85 E.02317
; WIPE_START
G1 X22.684 Y162.027 E-.1768
G1 X22.758 Y162.102 E-.02717
G1 X22.934 Y161.443 E-.17603
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.328 Y160.247 Z3.4 F36000
G1 Z3
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X29.981 Y160.072 E.0229
G1 X29.955 Y160.17 E.00344
G1 X29.476 Y159.69 E.02295
; CHANGE_LAYER
; Z_HEIGHT: 3.2
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X29.955 Y160.17 E-.17695
G1 X29.981 Y160.072 E-.0265
G1 X29.328 Y160.247 E-.17655
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L16
M991 S0 P15 ;notify layer change


M204 S10000
G17
G3 Z3.4 I1.217 J0 P1  F36000
; object ids of layer 16 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer16 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.137 Y93.514
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.072 Y93.531 E.00226
G2 X230.381 Y93.356 I1.131 J3.48 E.73325
G1 X230.025 Y93.356 E.01208
G2 X229.442 Y93.432 I.178 J3.655 E.01991
G1 X229.195 Y93.498 E.00867
M204 S10000
G1 X229.242 Y93.907 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.918 E.00153
G2 X230.365 Y93.763 I1.005 J3.093 E.65151
G1 X230.041 Y93.763 E.01099
G2 X229.527 Y93.83 I.162 J3.248 E.01756
G1 X229.3 Y93.891 E.00795
M204 S250
G1 X229.343 Y94.285 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.291 E.00078
G2 X230.35 Y94.155 I.884 J2.72 E.53058
G1 X230.056 Y94.155 E.00921
G2 X229.608 Y94.214 I.147 J2.856 E.01418
G1 X229.401 Y94.269 E.00672
; WIPE_START
M204 S3000
G1 X229.319 Y94.291 E-.01611
G1 X229.04 Y94.399 E-.05688
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05685
G1 X228.181 Y94.989 E-.08533
G1 X227.889 Y95.33 E-.08525
G1 X227.824 Y95.431 E-.02268
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.413 Y92.675 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.292 Y92.719 E.00437
G2 X230.309 Y92.318 I1.902 J4.293 E.92848
G2 X229.468 Y92.373 I.017 J6.7 E.02853
G2 X228.751 Y92.543 I.726 J4.639 E.02498
G1 X228.469 Y92.653 E.01024
M204 S10000
G1 X228.268 Y92.295 F36000
G1 F1473.913
M204 S3000
G1 X228.126 Y92.347 E.00509
G2 X230.32 Y91.911 I2.067 J4.665 E1.00893
G2 X229.405 Y91.97 I.015 J7.26 E.03106
G2 X228.625 Y92.156 I.789 J5.041 E.02714
G1 X228.324 Y92.273 E.01096
M204 S250
G1 X228.127 Y91.929 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.967 Y91.988 E.00536
G2 X230.33 Y91.519 I2.226 J5.024 E1.00635
G2 X229.343 Y91.583 I.014 J7.811 E.03102
G2 X228.504 Y91.783 I.85 J5.429 E.02707
G1 X228.183 Y91.908 E.0108
; WIPE_START
M204 S3000
G1 X227.967 Y91.988 E-.04391
G1 X227.455 Y92.252 E-.10931
G1 X226.972 Y92.565 E-.10938
G1 X226.525 Y92.927 E-.10927
G1 X226.495 Y92.957 E-.00813
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.655 Y93.137 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672905
G1 F952.404
M204 S3000
G1 X228.503 Y93.193 E.00849
G2 X226.025 Y97.012 I1.7 J3.817 E.25218
G1 X226.047 Y97.44 E.02248
G1 X226.082 Y97.697 E.01358
G2 X228.911 Y93.036 I4.121 J-.687 E1.06394
G1 X228.711 Y93.115 E.01128
; OBJECT_ID: 12
; WIPE_START
G1 X228.503 Y93.193 E-.04219
G1 X228.114 Y93.393 E-.08309
G1 X227.754 Y93.626 E-.08148
G1 X227.567 Y93.77 E-.04489
G1 X227.243 Y94.063 E-.08296
G1 X227.083 Y94.241 E-.04539
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.856 Y96.694 Z3.6 F36000
G1 X211.876 Y99.402 Z3.6
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.055 Y99.153 E.01038
G2 X208.969 Y93.119 I-3.278 J-2.13 E.27759
G1 X208.586 Y93.119 E.01296
G2 X211.815 Y99.484 I.191 J3.904 E.52695
G1 X211.84 Y99.45 E.00144
M204 S10000
G1 X211.547 Y99.163 F36000
G1 F1473.913
M204 S3000
G1 X211.714 Y98.932 E.00965
G2 X208.953 Y93.527 I-2.937 J-1.908 E.24854
G1 X208.602 Y93.527 E.01187
G2 X211.498 Y99.228 I.175 J3.497 E.47192
G1 X211.511 Y99.211 E.00072
M204 S250
G1 X211.23 Y98.933 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.385 Y98.718 E.0083
G2 X208.937 Y93.919 I-2.608 J-1.694 E.20431
G1 X208.618 Y93.919 E.01003
G2 X211.194 Y98.981 I.16 J3.105 E.38806
G1 X211.194 Y98.981 E.00003
; WIPE_START
M204 S3000
G1 X211.385 Y98.718 E-.06167
G1 X211.549 Y98.437 E-.06184
G1 X211.681 Y98.139 E-.06186
G1 X211.82 Y97.671 E-.09274
G1 X211.871 Y97.35 E-.06182
G1 X211.882 Y97.139 E-.04006
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.688 Y99.359 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.692 Y99.383 E.00081
G2 X208.884 Y92.318 I4.076 J-2.358 E.66365
G2 X208.041 Y92.373 I.017 J6.719 E.02861
G2 X204.575 Y99.166 I.728 J4.652 E.30086
G1 X204.657 Y99.307 E.00554
M204 S10000
G1 X204.33 Y99.542 F36000
G1 F1473.913
M204 S3000
G1 X204.48 Y99.816 E.01057
G2 X208.894 Y91.911 I4.288 J-2.791 E.71187
G2 X207.977 Y91.971 I.015 J7.285 E.03114
G2 X204.211 Y99.351 I.791 J5.055 E.32687
G1 X204.298 Y99.491 E.00557
M204 S250
G1 X203.985 Y99.74 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X203.999 Y99.783 E.00141
G2 X208.905 Y91.519 I4.768 J-2.758 E.71898
G2 X207.916 Y91.583 I.014 J7.829 E.03109
G2 X203.861 Y99.53 I.852 J5.442 E.32599
G1 X203.955 Y99.689 E.00579
; WIPE_START
M204 S3000
G1 X203.999 Y99.783 E-.01984
G1 X204.32 Y100.263 E-.10969
G1 X204.683 Y100.711 E-.1096
G1 X205.091 Y101.119 E-.10955
G1 X205.219 Y101.223 E-.03132
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X205.041 Y99.171 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.43608
G1 F1526.1
M204 S3000
G1 X205.045 Y99.179 E.0003
G1 X205.291 Y99.558 E.01477
G1 X205.526 Y99.851 E.01229
G2 X204.468 Y97.019 I3.25 J-2.828 E.78403
G1 X204.474 Y97.255 E.00771
G1 X204.522 Y97.704 E.01473
G1 X204.615 Y98.14 E.01459
G1 X204.754 Y98.569 E.01475
G1 X205.015 Y99.116 E.01983
; OBJECT_ID: 11
; WIPE_START
M73 P62 R18
G1 X205.045 Y99.179 E-.01317
G1 X205.291 Y99.558 E-.08582
G1 X205.526 Y99.851 E-.07145
G1 X205.73 Y100.072 E-.05707
G1 X206.065 Y100.374 E-.08573
G1 X206.355 Y100.573 E-.06676
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.967 Y98.655 Z3.6 F36000
G1 X183.868 Y94.735 Z3.6
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.729 Y94.963 E.00904
G2 X187.975 Y92.931 I3.603 J2.076 E.71504
G2 X187.225 Y92.882 I-.754 J5.829 E.02545
G2 X183.965 Y94.599 I.107 J4.157 E.12918
G1 X183.903 Y94.686 E.00365
M204 S10000
G1 X184.209 Y94.957 F36000
G1 F1473.913
M204 S3000
G1 X184.083 Y95.168 E.00832
G2 X187.717 Y93.307 I3.251 J1.872 E.65176
G2 X187.235 Y93.289 I-.393 J4.004 E.01631
G2 X184.296 Y94.839 I.099 J3.75 E.11653
G1 X184.244 Y94.909 E.00293
M204 S250
G1 X184.535 Y95.169 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.514 Y95.214 E.00156
G2 X187.676 Y93.698 I2.819 J1.823 E.54578
G2 X187.246 Y93.681 I-.352 J3.59 E.01349
G2 X184.72 Y94.93 I.088 J3.356 E.09117
G1 X184.572 Y95.122 E.00759
; WIPE_START
M204 S3000
G1 X184.514 Y95.214 E-.02073
G1 X184.33 Y95.514 E-.06676
G1 X184.187 Y95.835 E-.06682
G1 X184.038 Y96.341 E-.10019
G1 X183.983 Y96.688 E-.06681
G1 X183.966 Y96.996 E-.05869
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.439 Y92.318 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.431 Y92.318 E.00028
G2 X186.585 Y92.373 I.017 J6.737 E.0287
G2 X187.818 Y92.343 I.73 J4.666 E.96268
G1 X187.499 Y92.322 E.01082
M204 S10000
G1 X187.463 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.441 Y91.911 E.00074
G2 X186.522 Y91.971 I.016 J7.308 E.03122
G2 X187.86 Y91.938 I.793 J5.069 E1.04566
G1 X187.523 Y91.916 E.01144
M204 S250
G1 X187.487 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.452 Y91.519 E.0011
G2 X186.46 Y91.583 I.014 J7.852 E.03117
G2 X187.901 Y91.548 I.854 J5.456 E1.04262
G1 X187.546 Y91.525 E.01115
; WIPE_START
M204 S3000
G1 X187.452 Y91.519 E-.01805
G1 X187.035 Y91.523 E-.0791
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10986
G1 X185.579 Y91.806 E-.06309
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.49 Y92.606 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200577
G1 F3805.736
M204 S3000
G1 X187.324 Y92.597 E.00217
G1 X186.86 Y92.622 E.00609
G1 X186.401 Y92.694 E.0061
G1 X185.952 Y92.815 E.00609
G1 X185.519 Y92.98 E.00607
G1 X185.306 Y93.082 E.0031
G1 X184.904 Y93.315 E.00609
G1 X184.529 Y93.587 E.00607
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.0061
G1 X183.6 Y94.618 E.00607
G1 X183.367 Y95.021 E.0061
G1 X183.266 Y95.234 E.0031
G1 X183.1 Y95.667 E.00607
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.0061
G1 X182.882 Y97.037 E.00607
G1 X182.907 Y97.503 E.00612
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.0061
G1 X183.178 Y98.633 E.0031
G1 X183.367 Y99.056 E.00607
G1 X183.599 Y99.458 E.00609
G1 X183.872 Y99.835 E.0061
G1 X184.183 Y100.18 E.00609
G1 X184.529 Y100.491 E.0061
G1 X184.903 Y100.763 E.00607
G1 X185.306 Y100.996 E.00609
G1 X185.52 Y101.098 E.00311
G1 X185.952 Y101.264 E.00606
G1 X186.401 Y101.384 E.00609
G1 X186.86 Y101.457 E.0061
G1 X187.324 Y101.481 E.00609
G1 X187.789 Y101.457 E.00609
G1 X188.248 Y101.384 E.0061
G1 X188.697 Y101.264 E.00609
G1 X189.129 Y101.098 E.00607
G1 X189.343 Y100.996 E.00311
G1 X189.745 Y100.763 E.0061
G1 X190.12 Y100.491 E.00607
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.0061
G1 X191.048 Y99.46 E.00607
G1 X191.172 Y99.258 E.00311
G1 X191.383 Y98.844 E.00609
G1 X191.549 Y98.412 E.00607
G1 X191.669 Y97.963 E.00609
G1 X191.742 Y97.503 E.0061
G1 X191.766 Y97.039 E.00609
G1 X191.742 Y96.575 E.00609
G1 X191.67 Y96.118 E.00607
G1 X191.614 Y95.887 E.0031
G1 X191.47 Y95.445 E.00609
G1 X191.282 Y95.023 E.00607
G1 X191.05 Y94.62 E.00609
G1 X190.776 Y94.244 E.0061
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.0061
G1 X189.746 Y93.315 E.00606
G1 X189.543 Y93.191 E.00311
G1 X189.129 Y92.98 E.00609
G1 X188.697 Y92.815 E.00607
G1 X188.248 Y92.694 E.00609
G1 X187.789 Y92.622 E.0061
G1 X187.55 Y92.609 E.00314
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.04289
G1 X186.86 Y92.622 E-.08832
G1 X186.401 Y92.694 E-.08834
G1 X185.952 Y92.815 E-.08833
G1 X185.597 Y92.951 E-.07212
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.967 Y93.139 Z3.6 F36000
G1 X163.24 Y93.502 Z3.6
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.07 Y93.633 E.00729
G2 X166.53 Y92.7 I2.779 J3.422 E.81268
G2 X165.735 Y92.648 I-.8 J6.181 E.02698
G2 X163.442 Y93.362 I.114 J4.407 E.08232
G1 X163.289 Y93.467 E.00629
M204 S10000
G1 X163.453 Y93.847 F36000
G1 F1473.913
M204 S3000
G1 X163.017 Y94.231 E.01969
G2 X166.259 Y93.075 I2.835 J2.824 E.73058
G2 X165.746 Y93.055 I-.419 J4.272 E.01739
G2 X163.504 Y93.815 I.105 J4 E.08134
M204 S250
G1 X163.707 Y94.144 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.293 Y94.508 E.01728
G2 X166.218 Y93.465 I2.557 J2.548 E.61042
G2 X165.756 Y93.447 I-.378 J3.858 E.0145
G2 X163.758 Y94.114 I.094 J3.608 E.06701
; WIPE_START
M204 S3000
G1 X163.293 Y94.508 E-.11578
G1 X163.035 Y94.783 E-.07179
G1 X162.813 Y95.089 E-.07176
G1 X162.624 Y95.416 E-.0718
G1 X162.518 Y95.65 E-.04887
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.107 Y101.466 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.483 E.00126
G2 X165.947 Y92.318 I1.691 J-4.427 E.55857
G2 X165.099 Y92.373 I.017 J6.759 E.0288
G2 X163.911 Y101.388 I.733 J4.682 E.41214
G1 X164.052 Y101.444 E.00511
M204 S10000
G1 X163.961 Y101.846 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.00129
G2 X165.958 Y91.911 I1.836 J-4.808 E.6065
G2 X165.035 Y91.971 I.015 J7.325 E.03132
G2 X163.502 Y101.645 I.796 J5.084 E.43841
G1 X163.906 Y101.821 E.01493
M204 S250
G1 X163.802 Y102.203 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.229 E.00183
G2 X165.968 Y91.519 I1.976 J-5.174 E.60457
G2 X164.974 Y91.584 I.014 J7.875 E.03127
G2 X163.324 Y101.994 I.856 J5.472 E.43704
G1 X163.747 Y102.179 E.01448
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.229 E-.02249
G1 X164.407 Y102.406 E-.11022
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.692 Y102.587 E-.02691
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.908 Y106.085 Z3.6 F36000
G1 X47.309 Y163.613 Z3.6
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.00258
G2 X47.246 Y154.317 I-.252 J-4.644 E.48224
G2 X46.414 Y154.372 I.017 J6.636 E.02826
G2 X46.898 Y163.613 I.719 J4.595 E.46222
G1 X47.249 Y163.613 E.01185
M204 S10000
G1 X47.309 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.0033
G2 X47.257 Y153.911 I-.274 J-5.051 E.5244
G2 X46.35 Y153.97 I.016 J7.206 E.03078
G2 X46.877 Y164.019 I.782 J4.998 E.50269
G1 X47.249 Y164.019 E.01257
M204 S250
G1 X47.309 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.0037
G2 X47.267 Y153.519 I-.295 J-5.442 E.52336
G2 X46.289 Y153.582 I.014 J7.75 E.03077
G2 X46.857 Y164.411 I.843 J5.385 E.50174
G1 X47.249 Y164.411 E.01229
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.03385
G1 X47.994 Y164.351 E-.10845
G1 X48.553 Y164.233 E-.10843
G1 X48.826 Y164.152 E-.05419
G1 X49.195 Y164.01 E-.07509
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.24 Y163.265 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X46.204 Y163.161 I.065 J-5.859 E.03529
G1 X48.428 Y154.862 E.29081
G3 X49.375 Y155.294 I-2.201 J6.087 E.03529
; WIPE_START
G1 X48.428 Y154.862 E-.19786
G1 X48.179 Y155.788 E-.18214
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.383 Y161.052 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X51.441 Y158.893 E.28237
M204 S10000
G1 X51.423 Y158.551 F36000
G1 F1473.913
M204 S3000
G2 X51.384 Y158.282 I-1.299 J.051 E.00922
G1 X47.826 Y154.724 E.17033
G1 X48.014 Y154.754 E.00645
G1 X44.289 Y155.752 E.13053
G1 X44.43 Y155.626 E.0064
G1 X43.123 Y160.505 E.17098
G1 X43.064 Y160.325 E.0064
G1 X45.784 Y163.044 E.13018
G1 X45.604 Y162.986 E.0064
M73 P62 R17
G1 X50.483 Y161.678 E.17098
G1 X50.356 Y161.819 E.0064
G1 X51.354 Y158.094 E.13053
G2 X51.246 Y157.681 I-2.019 J.308 E.01448
G1 X42.947 Y159.905 E.29081
G3 X42.843 Y158.869 I5.766 J-1.102 E.03529
M204 S10000
G1 X42.91 Y158.211 F36000
G1 F1473.913
M204 S3000
G3 X43.169 Y157.317 I10.091 J2.439 E.03153
G1 X49.753 Y155.552 E.23072
G1 X49.547 Y155.403 E.00863
G1 X47.443 Y163.254 E.27515
G2 X47.699 Y163.233 I-.009 J-1.639 E.00871
G1 X42.878 Y158.412 E.23077
G2 X42.854 Y158.665 I1.194 J.243 E.00863
G1 X50.706 Y156.561 E.27515
G1 X50.556 Y156.355 E.00863
G1 X48.793 Y162.936 E.23061
G1 X49.026 Y162.832 E.00863
G1 X43.276 Y157.082 E.27525
G3 X43.978 Y156.058 I6.731 J3.862 E.0421
G1 X50.051 Y162.13 E.29069
G3 X49.206 Y162.738 I-2.965 J-3.235 E.03531
; WIPE_START
G1 X50.051 Y162.13 E-.19775
G1 X49.373 Y161.452 E-.18225
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.827 Y161.179 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X44.929 Y155.282 E.2823
M204 S10000
G1 X45.106 Y155.18 F36000
G1 F1473.913
M204 S3000
G3 X45.902 Y154.851 I2.172 J4.128 E.0292
G1 X44.01 Y161.911 E.24742
G2 X44.197 Y162.098 I.983 J-.796 E.00897
G1 X51.257 Y160.207 E.24742
G2 X51.326 Y159.951 I-1.181 J-.453 E.00897
G1 X46.157 Y154.783 E.24742
G3 X47.012 Y154.668 I1.069 J4.741 E.02923
M204 S10000
G1 X47.216 Y154.666 F36000
G1 F1473.913
M204 S3000
G1 X45.056 Y162.725 E.28242
; OBJECT_ID: 14
; WIPE_START
G1 X45.574 Y160.793 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X38.203 Y158.812 Z3.6 F36000
G1 X26.732 Y155.727 Z3.6
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.667 Y155.71 E.00227
G2 X25.705 Y155.592 I-.892 J3.29 E.03292
G1 X25.438 Y155.608 E.00903
G2 X27.006 Y155.821 I.337 J3.392 E.67095
G1 X26.788 Y155.747 E.00777
M204 S10000
G1 X26.606 Y156.114 F36000
G1 F1473.913
M204 S3000
G1 X26.561 Y156.103 E.00155
G2 X25.715 Y155.999 I-.786 J2.897 E.02898
M73 P63 R17
G1 X25.477 Y156.013 E.00806
G2 X26.86 Y156.201 I.298 J2.987 E.5907
G1 X26.663 Y156.134 E.00705
M204 S250
G1 X26.485 Y156.487 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.482 E.00079
G2 X25.724 Y156.391 I-.685 J2.518 E.02332
G1 X25.514 Y156.404 E.0066
G2 X26.719 Y156.568 I.261 J2.596 E.47558
G1 X26.542 Y156.506 E.00588
; WIPE_START
M204 S3000
G1 X26.46 Y156.482 E-.01616
G1 X26.194 Y156.422 E-.05191
G1 X25.724 Y156.391 E-.08933
G1 X25.514 Y156.404 E-.03998
G1 X25.11 Y156.479 E-.07821
G1 X24.85 Y156.563 E-.05189
G1 X24.6 Y156.674 E-.05191
G1 X24.598 Y156.676 E-.00061
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.903 Y154.318 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.891 Y154.318 E.00043
G2 X25.052 Y154.372 I.017 J6.685 E.02846
G2 X26.275 Y154.343 I.724 J4.628 E.95474
G1 X25.963 Y154.322 E.01057
M204 S10000
G1 X25.928 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.902 Y153.911 E.00089
G2 X24.989 Y153.97 I.015 J7.246 E.03099
G2 X26.317 Y153.938 I.787 J5.03 E1.03772
G1 X25.988 Y153.916 E.01119
M204 S250
G1 X25.951 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.912 Y153.519 E.00123
G2 X24.927 Y153.583 I.014 J7.796 E.03095
G2 X26.358 Y153.548 I.848 J5.418 E1.03528
G1 X26.011 Y153.525 E.01092
; WIPE_START
M204 S3000
G1 X25.912 Y153.519 E-.01887
G1 X25.498 Y153.523 E-.07854
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10906
G1 X24.043 Y153.807 E-.06442
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.868 Y154.666 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.714 Y155.244 E.02025
M204 S10000
G1 X25.27 Y155.285 F36000
G1 F1473.913
M204 S3000
G1 X24.773 Y154.788 E.02379
G2 X24.556 Y154.846 I.168 J1.062 E.00763
G1 X24.375 Y155.52 E.0236
M204 S10000
G1 X23.972 Y155.713 F36000
G1 F1473.913
M204 S3000
G1 X23.549 Y155.291 E.02024
; WIPE_START
G1 X23.972 Y155.713 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.994 Y161.094 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.575 Y160.938 E.02037
M204 S10000
G1 X22.824 Y161.311 F36000
G1 F1473.913
M204 S3000
G1 X22.644 Y161.983 E.02355
G2 X22.803 Y162.142 I.837 J-.678 E.00763
G1 X23.478 Y161.961 E.02365
M204 S10000
G1 X23.846 Y162.214 F36000
G1 F1473.913
M204 S3000
G1 X23.691 Y162.791 E.02024
; WIPE_START
G1 X23.846 Y162.214 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.535 Y162.745 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X25.833 Y162.756 I.199 J-1.411 E.01009
G1 X26.369 Y163.292 E.02567
G3 X26.078 Y163.321 I-.284 J-1.372 E.00993
G1 X26.237 Y162.727 E.02081
G2 X27.259 Y162.455 I-.649 J-4.487 E.03588
G1 X27.696 Y162.892 E.02092
G3 X27.426 Y163.009 I-.879 J-1.659 E.00998
G1 X27.623 Y162.272 E.02581
G2 X27.871 Y162.123 I-.579 J-1.245 E.00982
M204 S10000
G1 X27.874 Y162.794 F36000
G1 F1473.913
M204 S3000
G2 X28.718 Y162.187 I-2.137 J-3.857 E.03527
G1 X28.309 Y161.778 E.01957
G3 X28.036 Y162.004 I-1.213 J-1.188 E.01202
G1 X29.178 Y161.698 E.04002
G3 X28.981 Y161.922 I-1.168 J-.824 E.01013
G1 X30.017 Y158.056 E.13549
G3 X30.068 Y158.355 I-1.882 J.471 E.01029
G1 X29.225 Y157.513 E.04033
G3 X29.364 Y157.855 I-1.23 J.698 E.01253
G1 X29.918 Y157.706 E.01943
G2 X29.491 Y156.758 I-4.207 J1.324 E.03529
M204 S10000
G1 X29.147 Y157.325 F36000
G1 F1473.913
M204 S3000
G2 X29.013 Y157.085 I-.977 J.388 E.00934
G1 X29.211 Y156.347 E.02584
G1 X29.384 Y156.585 E.00997
G1 X28.783 Y156.747 E.02107
G2 X28.04 Y155.999 I-3.94 J3.171 E.03574
G1 X28.2 Y155.401 E.02094
G1 X28.438 Y155.575 E.00997
G1 X27.701 Y155.772 E.02584
G2 X27.46 Y155.638 I-.629 J.844 E.00934
M204 S10000
G1 X28.027 Y155.294 F36000
G1 F1473.913
M204 S3000
G2 X27.08 Y154.864 I-3.161 J5.702 E.03527
G1 X26.93 Y155.421 E.01955
G3 X27.272 Y155.56 I-.356 J1.369 E.01253
G1 X26.43 Y154.718 E.04033
G3 X26.726 Y154.769 I-.096 J1.436 E.0102
G1 X22.863 Y155.804 E.13539
G3 X23.088 Y155.607 I1.049 J.97 E.01013
G1 X22.779 Y156.758 E.04034
G3 X23.007 Y156.476 I1.186 J.727 E.01232
G1 X22.599 Y156.067 E.01957
G2 X21.991 Y156.911 I3.252 J2.983 E.03529
M204 S10000
G1 X22.664 Y156.926 F36000
G1 F1473.913
M204 S3000
G2 X22.509 Y157.163 I.824 J.707 E.00961
G1 X21.775 Y157.36 E.02572
G1 X21.895 Y157.091 E.00997
G1 X22.331 Y157.527 E.02086
G2 X22.057 Y158.549 I3.715 J1.543 E.03592
G1 X21.464 Y158.707 E.02077
G3 X21.493 Y158.416 I1.4 J-.007 E.00993
G1 X22.03 Y158.953 E.02567
G2 X22.04 Y159.25 I1.421 J.098 E.01009
M204 S10000
G1 X21.453 Y158.911 F36000
G1 F1473.913
M204 S3000
G2 X21.554 Y159.948 I14.081 J-.845 E.03527
G1 X22.114 Y159.798 E.0196
G3 X22.057 Y159.453 I1.613 J-.441 E.01186
G1 X21.753 Y160.589 E.03983
G3 X21.656 Y160.306 I1.3 J-.6 E.01013
G1 X24.479 Y163.129 E.13511
G3 X24.196 Y163.033 I.316 J-1.394 E.01013
G1 X25.333 Y162.728 E.03983
G3 X24.988 Y162.672 I.096 J-1.671 E.01186
G1 X24.838 Y163.231 E.0196
G2 X25.875 Y163.332 I1.882 J-13.977 E.03527
; WIPE_START
G1 X24.838 Y163.231 E-.19794
G1 X24.988 Y162.672 E-.11003
G1 X25.333 Y162.728 E-.06644
G1 X25.304 Y162.736 E-.00559
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.498 Y161.239 Z3.6 F36000
G1 Z3.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X29.074 Y160.816 E.02027
M204 S10000
G1 X29.264 Y160.411 F36000
G1 F1473.913
M204 S3000
G1 X29.939 Y160.23 E.02367
G1 X29.997 Y160.012 E.00762
G1 X29.503 Y159.518 E.02366
M204 S10000
G1 X29.54 Y159.072 F36000
G1 F1473.913
M204 S3000
G1 X30.118 Y158.917 E.02025
; CHANGE_LAYER
; Z_HEIGHT: 3.4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X29.54 Y159.072 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L17
M991 S0 P16 ;notify layer change


M204 S10000
G17
G3 Z3.6 I1.217 J0 P1  F36000
; object ids of layer 17 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer17 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.135 Y93.514
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.072 Y93.531 E.00218
G2 X230.381 Y93.356 I1.131 J3.48 E.73325
G1 X230.025 Y93.356 E.01207
G2 X229.442 Y93.432 I.178 J3.655 E.0199
G1 X229.193 Y93.499 E.00875
M204 S10000
G1 X229.24 Y93.907 F36000
G1 F1473.913
M204 S3000
G1 X229.198 Y93.918 E.00146
G2 X230.365 Y93.763 I1.005 J3.093 E.65152
G1 X230.041 Y93.763 E.01099
G2 X229.527 Y93.83 I.162 J3.248 E.01756
G1 X229.298 Y93.892 E.00803
M204 S250
G1 X229.341 Y94.286 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.319 Y94.291 E.00071
G2 X230.35 Y94.155 I.884 J2.72 E.53058
G1 X230.056 Y94.155 E.00921
G2 X229.609 Y94.214 I.147 J2.856 E.01417
G1 X229.399 Y94.27 E.0068
; WIPE_START
M204 S3000
G1 X229.319 Y94.291 E-.01571
G1 X229.04 Y94.399 E-.05686
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05685
G1 X228.181 Y94.989 E-.08531
G1 X227.98 Y95.212 E-.05691
G1 X227.821 Y95.431 E-.05147
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.486 Y92.642 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.069 Y92.824 E.01539
G2 X230.317 Y92.318 I2.125 J4.187 E.91986
G2 X229.468 Y92.373 I.002 J6.627 E.02882
G2 X228.54 Y92.617 I.726 J4.639 E.03254
M204 S10000
G1 X228.303 Y92.281 F36000
G1 F1473.913
M204 S3000
G1 X228.126 Y92.347 E.0064
G2 X230.328 Y91.911 I2.067 J4.665 E1.00864
G2 X229.405 Y91.97 I0 J7.193 E.03135
G2 X228.626 Y92.156 I.789 J5.041 E.02713
G1 X228.359 Y92.259 E.00967
M204 S250
G1 X228.163 Y91.915 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.967 Y91.988 E.00656
G2 X230.338 Y91.519 I2.226 J5.024 E1.00609
G2 X229.343 Y91.583 I0 J7.744 E.03129
G2 X228.504 Y91.783 I.85 J5.429 E.02707
G1 X228.219 Y91.894 E.00959
; WIPE_START
M204 S3000
G1 X227.967 Y91.988 E-.05117
G1 X227.455 Y92.252 E-.10936
G1 X226.973 Y92.565 E-.10929
G1 X226.525 Y92.927 E-.10935
G1 X226.522 Y92.93 E-.00083
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.698 Y93.114 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672868
G1 F952.459
M204 S3000
G2 X226.025 Y97.003 I1.505 J3.897 E.26266
G1 X226.048 Y97.449 E.02335
G1 X226.115 Y97.872 E.02246
G1 X226.227 Y98.295 E.0229
G1 X226.315 Y98.539 E.0136
G2 X228.754 Y93.093 I3.888 J-1.528 E1.02666
; OBJECT_ID: 12
; WIPE_START
G1 X228.306 Y93.289 E-.0929
G1 X227.927 Y93.508 E-.08307
G1 X227.58 Y93.76 E-.08157
G1 X227.401 Y93.912 E-.04458
G1 X227.112 Y94.202 E-.07788
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.889 Y96.669 Z3.8 F36000
G1 X211.872 Y99.408 Z3.8
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.063 Y99.158 E.01065
G2 X209.186 Y93.137 I-3.275 J-2.133 E.27071
G2 X208.68 Y93.118 I-.409 J4.167 E.01717
G2 X211.822 Y99.49 I.108 J3.907 E.52954
G1 X211.84 Y99.459 E.00121
M204 S10000
G1 X211.543 Y99.169 F36000
G1 F1473.913
M204 S3000
G1 X211.721 Y98.936 E.00993
G2 X209.144 Y93.542 I-2.934 J-1.911 E.24251
G2 X208.69 Y93.525 I-.366 J3.733 E.01537
G2 X211.505 Y99.233 I.097 J3.5 E.47439
G1 X211.512 Y99.22 E.00049
M204 S250
G1 X211.226 Y98.939 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.391 Y98.722 E.00855
G2 X209.103 Y93.932 I-2.605 J-1.697 E.19948
G2 X208.7 Y93.917 I-.325 J3.314 E.01263
G2 X211.195 Y98.99 I.085 J3.108 E.39005
; WIPE_START
M204 S3000
G1 X211.391 Y98.722 E-.0631
G1 X211.549 Y98.437 E-.06191
G1 X211.681 Y98.139 E-.06185
G1 X211.782 Y97.83 E-.06183
G1 X211.849 Y97.511 E-.06189
G1 X211.883 Y97.187 E-.06186
G1 X211.882 Y97.148 E-.00755
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.674 Y99.324 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.822 Y99.593 E.0104
G2 X208.892 Y92.318 I3.947 J-2.568 E.65495
G2 X208.041 Y92.373 I.002 J6.65 E.0289
G2 X204.575 Y99.166 I.728 J4.652 E.30086
G1 X204.642 Y99.273 E.00427
M204 S10000
G1 X204.322 Y99.539 F36000
G1 F1473.913
M204 S3000
G1 X204.34 Y99.587 E.00174
G2 X208.903 Y91.911 I4.428 J-2.562 E.72062
G2 X207.977 Y91.971 I.001 J7.218 E.03143
G2 X204.212 Y99.351 I.791 J5.054 E.32687
G1 X204.291 Y99.487 E.00533
M204 S250
G1 X203.977 Y99.726 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204 Y99.783 E.00193
G2 X208.913 Y91.519 I4.768 J-2.758 E.71866
G2 X207.916 Y91.583 I0 J7.763 E.03136
G2 X203.862 Y99.53 I.852 J5.442 E.326
G1 X203.947 Y99.674 E.00525
; WIPE_START
M204 S3000
G1 X204 Y99.783 E-.02304
G1 X204.32 Y100.263 E-.10968
G1 X204.683 Y100.711 E-.10951
G1 X205.091 Y101.119 E-.10963
G1 X205.206 Y101.212 E-.02815
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.99 Y99.072 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435963
G1 F1526.554
M204 S3000
G1 X205.163 Y99.372 E.01132
G1 X205.428 Y99.737 E.01476
G1 X205.73 Y100.072 E.01473
G1 X206.065 Y100.374 E.01473
G1 X206.43 Y100.639 E.01475
G1 X206.821 Y100.864 E.01474
G1 X207.228 Y101.046 E.01458
G1 X207.657 Y101.186 E.01473
G1 X207.887 Y101.241 E.00772
G1 X208.327 Y101.311 E.01456
G1 X208.777 Y101.334 E.01475
G1 X209.228 Y101.311 E.01475
G1 X209.674 Y101.24 E.01474
G1 X210.109 Y101.123 E.01474
G1 X210.526 Y100.964 E.01457
G1 X210.928 Y100.76 E.01473
G1 X211.129 Y100.636 E.00772
G1 X211.49 Y100.374 E.01458
G1 X211.825 Y100.072 E.01473
G1 X212.127 Y99.737 E.01475
G1 X212.392 Y99.372 E.01475
G1 X212.617 Y98.981 E.01473
G1 X212.756 Y98.677 E.01092
G1 X212.876 Y98.357 E.01119
G1 X212.993 Y97.921 E.01474
G1 X213.063 Y97.475 E.01475
G1 X213.087 Y97.025 E.01475
G1 X213.063 Y96.574 E.01475
G1 X212.993 Y96.128 E.01474
G1 X212.876 Y95.693 E.01475
G1 X212.717 Y95.277 E.01456
G1 X212.512 Y94.874 E.01475
G1 X212.389 Y94.673 E.00771
G1 X212.127 Y94.312 E.01458
G1 X211.825 Y93.977 E.01474
G1 X211.49 Y93.676 E.01474
G1 X211.124 Y93.41 E.01476
G1 X210.734 Y93.185 E.01473
G1 X210.327 Y93.003 E.01458
G1 X210.104 Y92.924 E.00771
G1 X209.669 Y92.808 E.01474
G1 X209.228 Y92.739 E.01457
G1 X208.777 Y92.715 E.01476
G1 X208.327 Y92.739 E.01474
G1 X207.881 Y92.809 E.01474
G1 X207.446 Y92.926 E.01474
G1 X207.029 Y93.086 E.01456
G1 X206.627 Y93.29 E.01474
G1 X206.426 Y93.413 E.00773
G1 X206.065 Y93.675 E.01457
G1 X205.73 Y93.977 E.01474
G1 X205.428 Y94.312 E.01474
G1 X205.166 Y94.673 E.01457
G1 X205.043 Y94.874 E.00773
G1 X204.838 Y95.276 E.01474
G1 X204.679 Y95.693 E.01457
G1 X204.562 Y96.128 E.01474
G1 X204.491 Y96.574 E.01474
G1 X204.468 Y97.019 E.01458
G1 X204.491 Y97.475 E.01492
G1 X204.561 Y97.915 E.01456
G1 X204.616 Y98.145 E.00772
G1 X204.756 Y98.574 E.01474
G1 X204.938 Y98.981 E.01459
G1 X204.96 Y99.02 E.00145
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.07719
G1 X205.428 Y99.737 E-.0858
G1 X205.73 Y100.072 E-.08566
G1 X206.065 Y100.374 E-.08564
G1 X206.26 Y100.515 E-.0457
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.872 Y98.596 Z3.8 F36000
G1 X183.887 Y94.704 Z3.8
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.844 Y94.78 E.00295
G2 X187.759 Y92.902 I3.491 J2.26 E.72984
G2 X187.22 Y92.882 I-.435 J4.439 E.01827
G2 X184.099 Y94.427 I.115 J4.157 E.12162
G1 X183.923 Y94.656 E.00976
M204 S10000
G1 X184.216 Y94.943 F36000
G1 F1473.913
M204 S3000
G1 X184.185 Y95.001 E.00223
G2 X187.717 Y93.307 I3.149 J2.039 E.65839
G2 X187.231 Y93.289 I-.392 J3.999 E.01646
G2 X184.415 Y94.683 I.103 J3.75 E.10973
G1 X184.252 Y94.895 E.00904
M204 S250
G1 X184.533 Y95.173 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.514 Y95.214 E.00143
G2 X187.676 Y93.698 I2.819 J1.823 E.54578
G2 X187.241 Y93.681 I-.351 J3.582 E.01364
G2 X184.72 Y94.93 I.092 J3.356 E.09103
G1 X184.569 Y95.125 E.00773
; WIPE_START
M204 S3000
G1 X184.514 Y95.214 E-.01992
G1 X184.33 Y95.514 E-.06671
M73 P64 R17
G1 X184.219 Y95.758 E-.05104
G1 X184.129 Y96.001 E-.04924
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.966 Y97 E-.05946
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.444 Y92.318 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.439 Y92.318 E.00015
G2 X186.585 Y92.373 I.002 J6.67 E.02899
G2 X187.818 Y92.343 I.73 J4.667 E.96273
G1 X187.503 Y92.322 E.01066
M204 S10000
G1 X187.468 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.45 Y91.911 E.00062
G2 X186.522 Y91.971 I.001 J7.241 E.03151
G2 X187.86 Y91.938 I.793 J5.069 E1.04571
G1 X187.528 Y91.916 E.01128
M204 S250
G1 X187.492 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.46 Y91.519 E.00099
G2 X186.46 Y91.583 I0 J7.785 E.03144
G2 X187.901 Y91.548 I.854 J5.456 E1.04267
G1 X187.552 Y91.525 E.01099
; WIPE_START
M204 S3000
G1 X187.46 Y91.519 E-.0174
G1 X187.035 Y91.523 E-.08073
G1 X186.46 Y91.583 E-.10989
G1 X186.176 Y91.636 E-.05495
G1 X185.617 Y91.786 E-.10982
G1 X185.582 Y91.799 E-.0072
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.495 Y92.606 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200581
G1 F3805.631
M204 S3000
G1 X187.324 Y92.597 E.00224
G1 X186.86 Y92.622 E.00609
G1 X186.403 Y92.694 E.00607
G1 X185.954 Y92.814 E.0061
G1 X185.73 Y92.893 E.0031
G1 X185.308 Y93.081 E.00607
G1 X184.905 Y93.314 E.0061
G1 X184.529 Y93.587 E.00609
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.0061
G1 X183.6 Y94.618 E.00607
G1 X183.367 Y95.021 E.00609
G1 X183.266 Y95.234 E.0031
G1 X183.1 Y95.667 E.00607
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.0061
G1 X182.882 Y97.037 E.00607
G1 X182.907 Y97.503 E.00612
G1 X182.979 Y97.961 E.00607
G1 X183.034 Y98.191 E.0031
G1 X183.178 Y98.633 E.0061
G1 X183.367 Y99.056 E.00607
G1 X183.599 Y99.459 E.0061
G1 X183.872 Y99.835 E.00609
G1 X184.183 Y100.18 E.00609
G1 X184.529 Y100.491 E.0061
G1 X184.903 Y100.763 E.00606
G1 X185.306 Y100.996 E.0061
G1 X185.52 Y101.098 E.0031
G1 X185.952 Y101.264 E.00607
G1 X186.401 Y101.384 E.00609
G1 X186.86 Y101.457 E.0061
G1 X187.324 Y101.481 E.00609
G1 X187.789 Y101.457 E.0061
G1 X188.246 Y101.384 E.00607
G1 X188.476 Y101.329 E.0031
G1 X188.918 Y101.185 E.00609
G1 X189.341 Y100.997 E.00607
G1 X189.744 Y100.764 E.0061
G1 X190.12 Y100.491 E.00609
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.00609
G1 X191.05 Y99.458 E.0061
G1 X191.282 Y99.056 E.0061
G1 X191.47 Y98.633 E.00607
G1 X191.614 Y98.191 E.00609
G1 X191.67 Y97.961 E.0031
G1 X191.742 Y97.503 E.00607
G1 X191.766 Y97.039 E.00609
G1 X191.742 Y96.575 E.0061
G1 X191.669 Y96.116 E.0061
G1 X191.549 Y95.667 E.00609
G1 X191.383 Y95.234 E.00607
G1 X191.281 Y95.021 E.0031
G1 X191.048 Y94.618 E.0061
G1 X190.776 Y94.244 E.00607
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.00609
G1 X189.744 Y93.314 E.0061
G1 X189.341 Y93.081 E.00609
G1 X188.918 Y92.893 E.00607
G1 X188.476 Y92.749 E.00609
G1 X188.246 Y92.694 E.0031
G1 X187.789 Y92.622 E.00607
G1 X187.555 Y92.609 E.00307
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.04387
G1 X186.86 Y92.622 E-.08833
G1 X186.403 Y92.694 E-.08796
G1 X185.954 Y92.814 E-.08834
G1 X185.73 Y92.893 E-.04498
G1 X185.603 Y92.95 E-.02652
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.973 Y93.139 Z3.8 F36000
G1 X163.237 Y93.504 Z3.8
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.069 Y93.634 E.00718
G2 X166.53 Y92.7 I2.779 J3.422 E.81263
G2 X165.73 Y92.649 I-.796 J6.142 E.02714
G2 X163.442 Y93.362 I.118 J4.407 E.08216
G1 X163.287 Y93.469 E.0064
M204 S10000
G1 X163.487 Y93.831 F36000
G1 F1473.913
M204 S3000
G1 X163.323 Y93.946 E.0068
G2 X164.305 Y100.75 I2.518 J3.109 E.27991
G2 X165.741 Y93.056 I1.532 J-3.695 E.48187
G2 X163.84 Y93.59 I.1 J4 E.06754
G1 X163.537 Y93.797 E.01242
M204 S250
G1 X163.706 Y94.149 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.573 Y94.255 E.00534
G2 X166.218 Y93.465 I2.277 J2.8 E.62224
G2 X165.751 Y93.447 I-.377 J3.848 E.01466
G2 X163.878 Y94.033 I.099 J3.608 E.06232
G1 X163.756 Y94.116 E.00461
; WIPE_START
M204 S3000
G1 X163.573 Y94.255 E-.04371
G1 X163.288 Y94.502 E-.07174
G1 X163.035 Y94.783 E-.0718
G1 X162.813 Y95.089 E-.07178
G1 X162.624 Y95.416 E-.0718
G1 X162.517 Y95.652 E-.04917
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.131 Y101.476 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.14 Y101.484 E.00043
G2 X165.956 Y92.318 I1.691 J-4.428 E.55835
G2 X165.099 Y92.373 I.002 J6.693 E.02909
G2 X163.687 Y101.282 I.733 J4.683 E.40378
G1 X164.076 Y101.452 E.01436
M204 S10000
G1 X163.955 Y101.844 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.864 E.00148
G2 X165.967 Y91.911 I1.836 J-4.808 E.60625
G2 X165.035 Y91.971 I.001 J7.259 E.03162
G2 X163.745 Y101.761 I.796 J5.085 E.44757
G1 X163.9 Y101.822 E.00562
M204 S250
G1 X163.808 Y102.201 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.128 Y102.327 E.01078
G2 X165.977 Y91.519 I1.703 J-5.271 E.59527
G2 X164.974 Y91.584 I0 J7.809 E.03154
G2 X163.586 Y102.12 I.856 J5.472 E.44619
G1 X163.751 Y102.18 E.00553
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.128 Y102.327 E-.07673
G1 X164.407 Y102.406 E-.05514
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.697 Y102.587 E-.02776
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.913 Y106.085 Z3.8 F36000
G1 X47.315 Y163.613 Z3.8
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.611 E.00237
G2 X47.255 Y154.318 I-.252 J-4.644 E.48192
G2 X46.414 Y154.372 I.002 J6.568 E.02855
G2 X46.898 Y163.612 I.719 J4.595 E.4622
G1 X47.255 Y163.613 E.01207
M204 S10000
G1 X47.315 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00309
G2 X47.266 Y153.911 I-.274 J-5.051 E.52408
G2 X46.35 Y153.97 I.001 J7.139 E.03107
G2 X46.877 Y164.019 I.782 J4.997 E.50266
G1 X47.255 Y164.019 E.01279
M204 S250
G1 X47.315 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.0035
G2 X47.276 Y153.519 I-.295 J-5.442 E.52304
G2 X46.289 Y153.582 I0 J7.683 E.03103
G2 X46.857 Y164.41 I.843 J5.384 E.50169
G1 X47.255 Y164.411 E.01249
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.03264
G1 X47.712 Y164.389 E-.05426
G1 X48.275 Y164.299 E-.10841
G1 X48.826 Y164.152 E-.10839
G1 X49.201 Y164.008 E-.07631
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.435 Y163.065 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X47.872 Y163.205 I-.947 J-2.61 E.01969
G1 X42.903 Y158.237 E.23783
G2 X42.846 Y158.814 I3.301 J.618 E.01965
G1 X50.787 Y156.686 E.27827
G2 X50.447 Y156.216 I-5.18 J3.384 E.01966
G1 X48.629 Y163.002 E.23783
G2 X49.158 Y162.765 I-2.264 J-5.76 E.01966
G1 X43.344 Y156.95 E.27835
G2 X43.106 Y157.48 I5.517 J2.792 E.01966
G1 X49.893 Y155.661 E.23783
G2 X49.422 Y155.321 I-3.856 J4.841 E.01966
G1 X47.293 Y163.267 E.27843
G3 X46.073 Y163.133 I.031 J-5.929 E.04165
G1 X42.98 Y160.041 E.14802
G1 X51.282 Y157.816 E.29093
G1 X50.151 Y162.04 E.14802
G1 X44.068 Y155.958 E.29117
G1 X48.292 Y154.826 E.14802
G1 X46.065 Y163.132 E.29106
G3 X45.851 Y163.066 I.204 J-1.054 E.00761
G1 X50.309 Y161.871 E.15624
G2 X50.508 Y161.644 I-.979 J-1.059 E.01025
; WIPE_START
G1 X50.309 Y161.871 E-.05741
G1 X48.669 Y162.311 E-.32259
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X51.393 Y158.335 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X51.343 Y158.041 I-1.426 J.091 E.01013
G1 X48.068 Y154.766 E.15676
G2 X47.773 Y154.716 I-.386 J1.376 E.01014
; WIPE_START
G1 X48.068 Y154.766 E-.0568
G1 X49.271 Y155.969 E-.3232
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X44.464 Y155.6 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X44.237 Y155.799 I.833 J1.179 E.01025
G1 X43.04 Y160.265 E.1565
G2 X43.145 Y160.553 I1.535 J-.394 E.01038
; WIPE_START
G1 X43.04 Y160.265 E-.05819
G1 X43.479 Y158.629 E-.32181
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.765 Y161.631 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X43.456 Y161.179 I1.997 J-1.696 E.01858
G1 X51.441 Y159.039 E.27981
G3 X51.394 Y159.587 I-2.626 J.051 E.01863
; WIPE_START
G1 X51.441 Y159.039 E-.10438
G1 X50.04 Y159.415 E-.27562
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X51.137 Y160.557 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X50.9 Y161.052 I-3.84 J-1.533 E.01861
G1 X45.056 Y155.209 E.27974
G3 X45.742 Y154.903 I2.157 J3.92 E.02543
G1 X43.897 Y161.786 E.2412
G2 X44.322 Y162.211 I2.236 J-1.81 E.02039
G1 X51.209 Y160.366 E.24131
G2 X51.363 Y159.788 I-5.756 J-1.844 E.02026
G1 X46.322 Y154.748 E.24128
G3 X47.069 Y154.668 I.873 J4.64 E.02544
G1 X44.93 Y162.652 E.27979
G3 X44.477 Y162.343 I1.244 J-2.306 E.01858
; OBJECT_ID: 14
; WIPE_START
G1 X44.93 Y162.652 E-.10408
G1 X45.305 Y161.249 E-.27592
; WIPE_END
M73 P64 R16
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.989 Y159.074 Z3.8 F36000
G1 X26.725 Y155.725 Z3.8
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.667 Y155.71 E.00204
G2 X25.701 Y155.592 I-.892 J3.29 E.03307
G1 X25.438 Y155.608 E.00891
G2 X27.005 Y155.821 I.337 J3.392 E.67094
G1 X26.782 Y155.745 E.00799
M204 S10000
G1 X26.6 Y156.112 F36000
G1 F1473.913
M204 S3000
G1 X26.562 Y156.104 E.00132
G2 X25.711 Y155.999 I-.787 J2.897 E.02911
G1 X25.477 Y156.013 E.00794
G2 X26.86 Y156.201 I.298 J2.987 E.59075
G1 X26.656 Y156.132 E.00727
M204 S250
G1 X26.479 Y156.485 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.482 E.00059
G2 X25.721 Y156.391 I-.685 J2.518 E.02343
G1 X25.514 Y156.404 E.00648
G2 X26.719 Y156.568 I.261 J2.597 E.47563
G1 X26.535 Y156.504 E.00609
; WIPE_START
M204 S3000
G1 X26.46 Y156.482 E-.0149
G1 X26.194 Y156.422 E-.05189
G1 X25.721 Y156.391 E-.09003
G1 X25.514 Y156.404 E-.03929
G1 X25.11 Y156.479 E-.07819
G1 X24.85 Y156.563 E-.0519
G1 X24.6 Y156.674 E-.05191
G1 X24.592 Y156.68 E-.00188
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.908 Y154.318 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.899 Y154.318 E.00029
G2 X25.052 Y154.372 I.002 J6.617 E.02875
G2 X26.275 Y154.343 I.724 J4.628 E.95465
G1 X25.968 Y154.322 E.01042
M204 S10000
G1 X25.932 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.91 Y153.911 E.00076
G2 X24.989 Y153.97 I.001 J7.178 E.03127
G2 X26.317 Y153.938 I.787 J5.03 E1.03763
G1 X25.992 Y153.916 E.01102
M204 S250
G1 X25.956 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.92 Y153.519 E.00113
G2 X24.927 Y153.583 I0 J7.729 E.03122
M73 P65 R16
G2 X26.358 Y153.548 I.848 J5.417 E1.03518
G1 X26.016 Y153.525 E.01076
; WIPE_START
M204 S3000
G1 X25.92 Y153.519 E-.01822
G1 X25.498 Y153.523 E-.08016
G1 X24.927 Y153.583 E-.10911
G1 X24.366 Y153.702 E-.10907
G1 X24.048 Y153.805 E-.06345
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.747 Y154.774 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X26.668 Y154.755 I-.13 J.366 E.00275
G1 X27.651 Y155.738 E.04706
G2 X27.278 Y155.553 I-1.067 J1.678 E.01411
M204 S10000
G1 X27.194 Y154.902 F36000
G1 F1473.913
M204 S3000
G3 X28.075 Y155.321 I-1.269 J3.801 E.03311
G1 X27.915 Y155.917 E.02087
G1 X27.857 Y155.877 E.00241
G1 X28.575 Y155.684 E.02516
G3 X29.101 Y156.211 I-2.242 J2.768 E.02524
G1 X28.911 Y156.918 E.02479
G1 X28.879 Y156.867 E.00205
G1 X29.464 Y156.71 E.02051
G3 X29.885 Y157.591 I-4.372 J2.634 E.03309
M204 S10000
G1 X30.011 Y158.039 F36000
G1 F1473.913
M204 S3000
G3 X30.03 Y158.118 I-.366 J.13 E.00275
G1 X29.047 Y157.134 E.04709
G3 X29.232 Y157.506 I-1.667 J1.063 E.0141
; WIPE_START
G1 X29.047 Y157.134 E-.08369
G1 X30.03 Y158.118 E-.27996
G1 X30.011 Y158.039 E-.01635
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.032 Y160.892 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X29.138 Y160.68 I-.67 J-.469 E.00806
G1 X29.568 Y161.11 E.02056
G2 X29.821 Y160.582 I-2.379 J-1.468 E.01984
M204 S10000
G1 X30.067 Y159.649 F36000
G1 F1473.913
M204 S3000
G2 X30.119 Y159.064 I-2.761 J-.537 E.01992
G1 X29.532 Y159.221 E.02055
G2 X29.541 Y158.958 I-1.242 J-.176 E.0089
M204 S10000
G1 X29.475 Y158.304 F36000
G1 F1473.913
M204 S3000
G2 X29.401 Y157.992 I-1.523 J.197 E.0109
G1 X29.958 Y157.842 E.01955
G1 X29.943 Y157.786 E.00198
G1 X29.525 Y159.345 E.05464
G1 X30.035 Y159.85 E.02429
G3 X29.887 Y160.39 I-3.285 J-.611 E.01897
G1 X29.203 Y160.549 E.02378
G1 X28.779 Y162.132 E.05547
G1 X28.823 Y162.092 E.00203
G1 X28.41 Y161.678 E.0198
G3 X27.677 Y162.246 I-2.612 J-2.612 E.03145
G1 X29.012 Y161.889 E.04675
G1 X28.962 Y161.944 E.0025
M204 S10000
G1 X28.627 Y162.268 F36000
G1 F1473.913
M204 S3000
G3 X27.825 Y162.821 I-3.824 J-4.693 E.03301
G1 X27.396 Y162.392 E.02055
G1 X27.453 Y162.363 E.00216
G1 X27.263 Y163.072 E.02484
G3 X26.542 Y163.265 I-1.53 J-4.268 E.02529
G1 X26.023 Y162.746 E.02484
G1 X26.086 Y162.742 E.00216
G1 X25.929 Y163.329 E.02055
G3 X24.956 Y163.253 I-.132 J-4.6 E.0331
M204 S10000
G1 X24.505 Y163.14 F36000
G1 F1473.913
M204 S3000
G3 X24.427 Y163.117 I.07 J-.38 E.00275
G1 X25.77 Y162.757 E.04706
G3 X25.355 Y162.732 I-.085 J-1.988 E.01411
; WIPE_START
G1 X25.77 Y162.757 E-.08378
G1 X24.427 Y163.117 E-.27988
G1 X24.505 Y163.14 E-.01634
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.082 Y162.384 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X23.564 Y162.721 I1.846 J-2.122 E.01993
G1 X23.722 Y162.129 E.02074
G1 X23.897 Y162.249 E.00717
M204 S10000
G1 X24.544 Y162.545 F36000
G1 F1473.913
M204 S3000
G2 X24.851 Y162.635 I.621 J-1.546 E.01085
G1 X24.701 Y163.193 E.01955
G1 X24.758 Y163.208 E.00198
G1 X23.584 Y162.034 E.05622
G1 X23.631 Y162.066 E.00195
G1 X22.924 Y162.256 E.02476
G3 X22.531 Y161.857 I2.173 J-2.541 E.01897
G1 X22.719 Y161.17 E.02414
G1 X21.577 Y160.027 E.05468
G1 X21.592 Y160.084 E.00198
G1 X22.15 Y159.934 E.01955
G2 X22.242 Y160.242 I1.511 J-.283 E.0109
M204 S10000
G1 X22.512 Y160.843 F36000
G1 F1473.913
M204 S3000
G2 X22.651 Y161.064 I1.115 J-.545 E.00887
G1 X22.067 Y161.221 E.02047
G2 X22.397 Y161.704 I2.463 J-1.328 E.01984
; WIPE_START
G1 X22.067 Y161.221 E-.15319
G1 X22.651 Y161.064 E-.15833
G1 X22.512 Y160.843 E-.06848
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.054 Y159.431 Z3.8 F36000
G1 Z3.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.028 Y159.015 I1.961 J-.33 E.01411
G1 X21.668 Y160.359 E.04707
G3 X21.645 Y160.28 I.392 J-.157 E.00277
M204 S10000
G1 X21.532 Y159.829 F36000
G1 F1473.913
M204 S3000
G3 X21.456 Y158.856 I4.524 J-.842 E.0331
G1 X22.043 Y158.699 E.02055
G1 X22.04 Y158.763 E.00216
G1 X21.521 Y158.244 E.02484
G3 X21.712 Y157.523 I4.704 J.864 E.02526
G1 X22.427 Y157.332 E.02505
G1 X22.397 Y157.393 E.0023
G1 X21.963 Y156.959 E.02076
G3 X22.517 Y156.158 I4.01 J2.18 E.03303
M204 S10000
G1 X22.842 Y155.823 F36000
G1 F1473.913
M204 S3000
G1 X22.896 Y155.774 E.00249
G1 X22.539 Y157.107 E.04673
G3 X23.102 Y156.371 I3.08 J1.772 E.03147
G1 X22.693 Y155.962 E.01957
G1 X22.653 Y156.007 E.00203
G1 X24.23 Y155.584 E.05527
G1 X24.395 Y154.898 E.02388
G3 X24.938 Y154.753 I.962 J2.507 E.01905
G1 X25.444 Y155.259 E.02422
G1 X27 Y154.842 E.05451
G1 X26.943 Y154.827 E.00198
G1 X26.794 Y155.385 E.01955
G2 X26.481 Y155.31 I-.51 J1.45 E.0109
M204 S10000
G1 X25.835 Y155.249 F36000
G1 F1473.913
M204 S3000
G2 X25.565 Y155.251 I-.122 J1.358 E.00915
G1 X25.721 Y154.668 E.02045
G2 X25.138 Y154.714 I-.051 J3.084 E.01985
M204 S10000
G1 X24.203 Y154.964 F36000
G1 F1473.913
M204 S3000
G2 X23.676 Y155.217 I.943 J2.637 E.01984
G1 X24.1 Y155.642 E.02032
G2 X23.888 Y155.765 I.411 J.955 E.00834
; CHANGE_LAYER
; Z_HEIGHT: 3.6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X24.1 Y155.642 E-.06524
G1 X23.676 Y155.217 E-.15943
G1 X24.203 Y154.964 E-.15534
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L18
M991 S0 P17 ;notify layer change


M204 S10000
G17
G3 Z3.8 I1.217 J0 P1  F36000
; object ids of layer 18 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer18 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.095 Y93.529
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X228.892 Y93.595 E.00722
G2 X230.386 Y93.356 I1.311 J3.414 E.72619
G2 X229.829 Y93.371 I-.174 J3.995 E.01887
G2 X229.256 Y93.477 I.374 J3.638 E.01975
G1 X229.152 Y93.511 E.00371
M204 S10000
G1 X229.22 Y93.916 F36000
G1 F1473.913
M204 S3000
G1 X229.038 Y93.975 E.0065
G2 X230.368 Y93.763 I1.165 J3.034 E.64529
G2 X229.868 Y93.776 I-.156 J3.584 E.01694
G2 X229.361 Y93.87 I.335 J3.233 E.01747
G1 X229.277 Y93.897 E.00298
M204 S250
G1 X229.341 Y94.288 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.178 Y94.342 E.00538
G2 X230.351 Y94.155 I1.025 J2.668 E.52556
G2 X229.906 Y94.167 I-.139 J3.192 E.01397
G2 X229.463 Y94.249 I.297 J2.843 E.01415
G1 X229.398 Y94.27 E.00212
; WIPE_START
M204 S3000
G1 X229.178 Y94.342 E-.044
G1 X228.905 Y94.463 E-.05689
G1 X228.521 Y94.699 E-.08561
G1 X228.346 Y94.837 E-.04232
G1 X228.078 Y95.098 E-.07107
G1 X227.889 Y95.331 E-.05691
G1 X227.823 Y95.433 E-.02321
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.484 Y92.647 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.293 Y92.721 E.00695
G2 X230.694 Y101.683 I1.912 J4.29 E.4494
G2 X230.449 Y92.321 I-.493 J-4.671 E.47438
G2 X228.752 Y92.545 I-.244 J4.69 E.05827
G1 X228.54 Y92.626 E.00765
M204 S10000
G1 X228.339 Y92.268 F36000
G1 F1473.913
M204 S3000
G1 X228.127 Y92.349 E.00767
G2 X230.737 Y102.088 I2.077 J4.662 E.48836
G2 X230.47 Y91.915 I-.535 J-5.076 E.51552
G2 X228.626 Y92.158 I-.265 J5.097 E.06332
G1 X228.395 Y92.246 E.00838
M204 S250
G1 X228.195 Y91.897 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.708 Y92.115 E.01673
G2 X230.778 Y102.478 I2.497 J4.896 E.47811
G2 X230.491 Y91.523 I-.577 J-5.466 E.51422
G2 X228.251 Y91.874 I-.286 J5.489 E.0716
; WIPE_START
M204 S3000
G1 X227.708 Y92.115 E-.11278
G1 X227.21 Y92.402 E-.10928
G1 X226.744 Y92.74 E-.10931
G1 X226.554 Y92.911 E-.04862
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.706 Y93.112 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672874
G1 F952.451
M204 S3000
G2 X226.025 Y97.003 I1.499 J3.903 E.26307
G1 X226.049 Y97.457 E.02378
G1 X226.17 Y98.101 E.03434
G1 X226.386 Y98.711 E.03391
G1 X226.699 Y99.287 E.03433
G1 X227.098 Y99.807 E.03435
G1 X227.567 Y100.253 E.03391
G1 X228.107 Y100.626 E.03435
G1 X228.511 Y100.832 E.02377
G1 X229.122 Y101.047 E.03392
G1 X229.766 Y101.167 E.03432
G1 X230.421 Y101.184 E.03433
G1 X231.064 Y101.1 E.03393
G1 X231.502 Y100.982 E.02378
G1 X232.107 Y100.73 E.03435
G1 X232.659 Y100.392 E.03391
G1 X233.151 Y99.972 E.0339
G1 X233.578 Y99.474 E.03435
G1 X233.825 Y99.093 E.02377
G1 X234.104 Y98.509 E.03391
G1 X234.29 Y97.881 E.03432
G1 X234.375 Y97.23 E.03438
G1 X234.359 Y96.583 E.03389
G1 X234.288 Y96.135 E.02377
G1 X234.104 Y95.514 E.03391
G1 X233.821 Y94.922 E.03434
G1 X233.455 Y94.389 E.03391
G1 X233.152 Y94.052 E.02376
G1 X232.659 Y93.631 E.03393
G1 X232.1 Y93.289 E.03433
G1 X231.502 Y93.041 E.03391
G1 X230.864 Y92.886 E.03435
G1 X230.398 Y92.838 E.02459
G2 X228.763 Y93.091 I-.192 J4.176 E.08724
; OBJECT_ID: 12
; WIPE_START
G1 X228.306 Y93.289 E-.09451
G1 X227.928 Y93.507 E-.08303
G1 X227.575 Y93.766 E-.08314
G1 X227.266 Y94.04 E-.07845
G1 X227.118 Y94.196 E-.04087
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.9 Y96.676 Z4 F36000
G1 X211.841 Y99.445 Z4
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.946 Y99.327 E.00535
G2 X209.186 Y93.137 I-3.159 J-2.302 E.27765
G2 X208.675 Y93.118 I-.409 J4.165 E.01732
G2 X211.688 Y99.645 I.113 J3.907 E.52244
G1 X211.805 Y99.493 E.00651
M204 S10000
G1 X211.525 Y99.189 F36000
G1 F1473.913
M204 S3000
G1 X211.616 Y99.087 E.00463
G2 X209.144 Y93.542 I-2.83 J-2.062 E.24873
G2 X208.686 Y93.525 I-.366 J3.73 E.01551
G2 X211.385 Y99.372 I.101 J3.5 E.46803
G1 X211.489 Y99.237 E.00578
M204 S250
G1 X211.221 Y98.943 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.296 Y98.855 E.00363
G2 X209.103 Y93.932 I-2.511 J-1.832 E.20452
G2 X208.696 Y93.917 I-.325 J3.308 E.01276
G2 X211.091 Y99.108 I.09 J3.106 E.38473
G1 X211.184 Y98.99 E.0047
; WIPE_START
M204 S3000
G1 X211.296 Y98.855 E-.03342
G1 X211.471 Y98.58 E-.06189
G1 X211.619 Y98.29 E-.06187
G1 X211.735 Y97.986 E-.06184
G1 X211.82 Y97.671 E-.06186
G1 X211.883 Y97.187 E-.09273
G1 X211.882 Y97.154 E-.00639
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.672 Y99.33 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.693 Y99.383 E.00193
G2 X208.901 Y92.318 I4.076 J-2.358 E.66305
G2 X208.041 Y92.373 I-.012 J6.588 E.02919
G2 X204.574 Y99.166 I.728 J4.652 E.30086
G1 X204.641 Y99.278 E.00443
M204 S10000
G1 X204.314 Y99.524 F36000
G1 F1473.913
M204 S3000
G1 X204.339 Y99.587 E.00229
G2 X208.911 Y91.911 I4.429 J-2.562 E.72043
G2 X207.977 Y91.971 I-.013 J7.155 E.03172
G2 X204.211 Y99.351 I.791 J5.055 E.32688
G1 X204.283 Y99.473 E.00479
M204 S250
G1 X203.969 Y99.711 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X203.999 Y99.783 E.00244
G2 X208.922 Y91.519 I4.768 J-2.758 E.71844
G2 X207.916 Y91.583 I-.015 J7.701 E.03163
G2 X203.861 Y99.53 I.852 J5.442 E.32599
G1 X203.939 Y99.66 E.00475
; WIPE_START
M204 S3000
G1 X203.999 Y99.783 E-.02615
G1 X204.32 Y100.263 E-.10965
G1 X204.683 Y100.711 E-.10962
G1 X205.091 Y101.119 E-.10955
G1 X205.194 Y101.202 E-.02504
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.982 Y99.058 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435961
G1 F1526.561
M204 S3000
G1 X205.163 Y99.372 E.01186
G1 X205.428 Y99.737 E.01474
G1 X205.73 Y100.072 E.01474
G1 X206.065 Y100.374 E.01473
G1 X206.431 Y100.639 E.01476
G1 X206.821 Y100.864 E.01472
G1 X207.228 Y101.046 E.01458
G1 X207.45 Y101.125 E.0077
G1 X207.886 Y101.241 E.01474
G1 X208.327 Y101.311 E.01457
G1 X208.777 Y101.334 E.01475
G1 X209.228 Y101.311 E.01475
G1 X209.674 Y101.24 E.01474
G1 X210.109 Y101.123 E.01473
G1 X210.526 Y100.964 E.01458
G1 X210.928 Y100.759 E.01474
G1 X211.129 Y100.636 E.0077
G1 X211.49 Y100.374 E.01459
G1 X211.825 Y100.072 E.01474
G1 X212.127 Y99.737 E.01474
G1 X212.392 Y99.372 E.01475
G1 X212.618 Y98.981 E.01474
G1 X212.799 Y98.574 E.01457
G1 X212.878 Y98.352 E.0077
G1 X212.994 Y97.916 E.01474
G1 X213.063 Y97.475 E.01457
G1 X213.087 Y97.025 E.01475
G1 X213.063 Y96.574 E.01475
G1 X212.993 Y96.128 E.01474
G1 X212.876 Y95.693 E.01475
G1 X212.716 Y95.276 E.01457
G1 X212.512 Y94.874 E.01474
G1 X212.389 Y94.673 E.00771
G1 X212.127 Y94.312 E.01459
G1 X211.825 Y93.977 E.01474
G1 X211.49 Y93.675 E.01474
G1 X211.125 Y93.41 E.01474
G1 X210.734 Y93.185 E.01474
G1 X210.327 Y93.003 E.01458
G1 X210.104 Y92.924 E.0077
G1 X209.669 Y92.808 E.01474
G1 X209.228 Y92.739 E.01457
G1 X208.777 Y92.715 E.01476
G1 X208.327 Y92.739 E.01475
G1 X207.886 Y92.808 E.01457
G1 X207.451 Y92.924 E.01474
G1 X207.228 Y93.003 E.00772
G1 X206.821 Y93.185 E.01456
G1 X206.43 Y93.41 E.01475
G1 X206.065 Y93.675 E.01474
G1 X205.73 Y93.977 E.01474
G1 X205.428 Y94.313 E.01474
G1 X205.163 Y94.677 E.01474
G1 X204.938 Y95.068 E.01474
G1 X204.756 Y95.475 E.01458
G1 X204.677 Y95.698 E.00771
G1 X204.561 Y96.133 E.01474
G1 X204.491 Y96.574 E.01457
G1 X204.468 Y97.025 E.01475
G1 X204.491 Y97.475 E.01475
G1 X204.561 Y97.916 E.01457
G1 X204.677 Y98.351 E.01474
G1 X204.756 Y98.574 E.00772
G1 X204.937 Y98.981 E.01456
G1 X204.952 Y99.006 E.00093
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.08035
G1 X205.428 Y99.737 E-.08572
G1 X205.73 Y100.072 E-.08571
G1 X206.065 Y100.374 E-.08565
G1 X206.246 Y100.505 E-.04257
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.855 Y98.602 Z4 F36000
G1 X183.863 Y94.743 Z4
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.723 Y94.96 E.00875
G2 X187.324 Y92.88 I3.602 J2.078 E.73705
G1 X187.106 Y92.885 E.00738
G2 X183.959 Y94.595 I.218 J4.153 E.12532
G1 X183.896 Y94.693 E.00395
M204 S10000
G1 X184.221 Y94.939 F36000
G1 F1473.913
M204 S3000
G1 X184.178 Y94.996 E.0024
G2 X187.324 Y93.287 I3.147 J2.043 E.67155
G1 X187.128 Y93.292 E.00665
G2 X184.536 Y94.529 I.197 J3.746 E.09975
G1 X184.257 Y94.891 E.01549
M204 S250
G1 X184.53 Y95.176 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.507 Y95.209 E.00127
G2 X187.324 Y93.679 I2.818 J1.829 E.55704
G1 X187.148 Y93.684 E.00551
G2 X184.713 Y94.925 I.176 J3.355 E.08825
G1 X184.565 Y95.128 E.00788
; WIPE_START
M204 S3000
G1 X184.507 Y95.209 E-.01909
G1 X184.255 Y95.673 E-.10019
G1 X184.129 Y96.001 E-.06683
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.966 Y97.005 E-.06026
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.448 Y92.318 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.585 Y92.373 I-.012 J6.606 E.02928
G2 X187.508 Y92.32 I.73 J4.666 E.9732
M204 S10000
G1 X187.473 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.459 Y91.911 E.00049
G2 X186.522 Y91.971 I-.013 J7.178 E.0318
G2 X187.86 Y91.938 I.793 J5.069 E1.04566
G1 X187.533 Y91.916 E.01111
M204 S250
G1 X187.497 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.469 Y91.519 E.00088
G2 X186.46 Y91.583 I-.015 J7.723 E.03171
M73 P66 R16
G2 X187.901 Y91.548 I.854 J5.456 E1.04262
G1 X187.557 Y91.525 E.01083
; WIPE_START
M204 S3000
G1 X187.469 Y91.519 E-.01676
G1 X187.035 Y91.523 E-.08236
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10985
G1 X185.617 Y91.786 E-.05496
G1 X185.587 Y91.797 E-.00618
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.5 Y92.606 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.20058
G1 F3805.659
M204 S3000
G1 X187.324 Y92.597 E.00231
G1 X186.86 Y92.622 E.00609
G1 X186.403 Y92.694 E.00607
G1 X186.173 Y92.749 E.0031
G1 X185.73 Y92.893 E.0061
G1 X185.308 Y93.081 E.00607
G1 X184.905 Y93.314 E.0061
G1 X184.529 Y93.587 E.0061
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.0061
G1 X183.599 Y94.62 E.00609
G1 X183.367 Y95.022 E.00609
G1 X183.178 Y95.445 E.00607
G1 X183.099 Y95.668 E.0031
G1 X182.979 Y96.118 E.0061
G1 X182.907 Y96.575 E.00607
G1 X182.882 Y97.039 E.00609
G1 X182.907 Y97.503 E.0061
G1 X182.979 Y97.961 E.00607
G1 X183.034 Y98.191 E.0031
G1 X183.178 Y98.633 E.0061
G1 X183.367 Y99.056 E.00607
G1 X183.599 Y99.459 E.0061
G1 X183.872 Y99.835 E.0061
G1 X184.183 Y100.18 E.00609
G1 X184.529 Y100.491 E.0061
G1 X184.903 Y100.763 E.00606
G1 X185.105 Y100.887 E.00311
G1 X185.519 Y101.098 E.00609
G1 X185.952 Y101.264 E.00607
G1 X186.401 Y101.384 E.00609
G1 X186.86 Y101.457 E.0061
G1 X187.324 Y101.481 E.00609
G1 X187.789 Y101.457 E.00609
G1 X188.246 Y101.384 E.00607
G1 X188.476 Y101.329 E.0031
G1 X188.918 Y101.185 E.0061
G1 X189.341 Y100.997 E.00607
G1 X189.744 Y100.764 E.00609
G1 X190.12 Y100.491 E.0061
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.0061
G1 X191.05 Y99.458 E.0061
G1 X191.282 Y99.056 E.00609
G1 X191.47 Y98.633 E.00607
G1 X191.614 Y98.191 E.0061
G1 X191.67 Y97.961 E.0031
G1 X191.742 Y97.503 E.00607
G1 X191.766 Y97.039 E.00609
G1 X191.742 Y96.575 E.00609
G1 X191.67 Y96.118 E.00607
G1 X191.614 Y95.887 E.0031
G1 X191.47 Y95.445 E.0061
G1 X191.282 Y95.022 E.00607
G1 X191.049 Y94.62 E.00609
G1 X190.776 Y94.243 E.0061
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.0061
G1 X189.745 Y93.315 E.00607
G1 X189.343 Y93.082 E.0061
G1 X189.129 Y92.98 E.0031
G1 X188.697 Y92.815 E.00607
G1 X188.248 Y92.694 E.00609
G1 X187.789 Y92.622 E.0061
G1 X187.56 Y92.61 E.003
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.04486
G1 X186.86 Y92.622 E-.08832
G1 X186.403 Y92.694 E-.08795
G1 X186.173 Y92.749 E-.04497
G1 X185.73 Y92.893 E-.08836
G1 X185.608 Y92.948 E-.02553
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.978 Y93.146 Z4 F36000
G1 X163.197 Y93.53 Z4
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.894 Y93.783 E.01337
G2 X161.47 Y96.48 I2.963 J3.288 E.10538
G2 X165.265 Y101.425 I4.383 J.566 E.23421
G2 X170.211 Y97.631 I.575 J-4.37 E.23437
G2 X166.416 Y92.685 I-4.383 J-.566 E.23421
G2 X165.61 Y92.652 I-.656 J6.129 E.02734
G2 X163.252 Y93.492 I.248 J4.42 E.08589
G1 X163.247 Y93.496 E.00022
M204 S10000
G1 X163.467 Y93.847 F36000
G1 F1473.913
M204 S3000
G1 X163.166 Y94.085 E.01298
G2 X161.874 Y96.533 I2.689 J2.985 E.09565
G2 X165.318 Y101.022 I3.978 J.514 E.21258
G2 X169.807 Y97.577 I.514 J-3.978 E.21258
G2 X166.363 Y93.088 I-3.978 J-.514 E.21258
G2 X165.631 Y93.058 I-.596 J5.564 E.02481
G2 X163.663 Y93.703 I.225 J4.011 E.07088
G1 X163.515 Y93.812 E.00622
M204 S250
G1 X163.699 Y94.15 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.425 Y94.373 E.01108
G2 X165.84 Y93.445 I2.416 J2.682 E.62811
G1 X165.652 Y93.45 E.00592
G2 X163.747 Y94.114 I.189 J3.605 E.06408
; WIPE_START
M204 S3000
G1 X163.425 Y94.373 E-.07852
G1 X163.158 Y94.64 E-.07179
G1 X162.813 Y95.089 E-.10762
G1 X162.624 Y95.416 E-.0718
G1 X162.516 Y95.658 E-.05027
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.135 Y101.478 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.141 Y101.483 E.00027
G2 X165.965 Y92.318 I1.691 J-4.427 E.55799
G2 X165.099 Y92.373 I-.012 J6.628 E.02938
G2 X163.687 Y101.282 I.733 J4.682 E.40373
G1 X164.08 Y101.454 E.01451
M204 S10000
G1 X163.969 Y101.849 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.00098
G2 X165.975 Y91.911 I1.836 J-4.808 E.60592
G2 X165.035 Y91.971 I-.014 J7.197 E.03191
G2 X163.502 Y101.645 I.796 J5.084 E.43841
G1 X163.914 Y101.825 E.01524
M204 S250
G1 X163.812 Y102.202 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.128 Y102.326 E.01063
G2 X165.985 Y91.519 I1.702 J-5.27 E.59493
G2 X164.974 Y91.584 I-.014 J7.747 E.0318
G2 X163.586 Y102.119 I.856 J5.472 E.44615
G1 X163.756 Y102.182 E.00567
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.128 Y102.326 E-.07584
G1 X164.407 Y102.406 E-.05513
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.702 Y102.587 E-.02866
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.917 Y106.085 Z4 F36000
G1 X47.321 Y163.613 Z4
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.00216
G2 X47.263 Y154.318 I-.252 J-4.644 E.48166
G2 X46.414 Y154.372 I-.012 J6.504 E.02883
G2 X46.898 Y163.613 I.719 J4.595 E.46223
G1 X47.261 Y163.613 E.01228
M204 S10000
G1 X47.321 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00288
G2 X47.274 Y153.911 I-.274 J-5.051 E.52382
G2 X46.35 Y153.97 I-.014 J7.071 E.03136
G2 X46.877 Y164.019 I.782 J4.998 E.50268
G1 X47.261 Y164.019 E.013
M204 S250
G1 X47.321 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00331
G2 X47.284 Y153.519 I-.295 J-5.442 E.52283
G2 X46.289 Y153.582 I-.015 J7.62 E.0313
G2 X46.857 Y164.411 I.843 J5.385 E.50173
G1 X47.261 Y164.411 E.01268
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.03147
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.10841
G1 X48.826 Y164.152 E-.10841
G1 X49.207 Y164.006 E-.07744
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.837 Y163.212 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X47.146 Y163.27 I-.708 J-4.32 E.02351
G1 X49.296 Y155.248 E.28111
G3 X50.018 Y155.774 I-2.152 J3.716 E.03031
G1 X43.054 Y157.64 E.24405
G2 X42.933 Y158.067 I2.648 J.98 E.01502
G1 X48.037 Y163.17 E.2443
G2 X48.468 Y163.055 I-.334 J-2.111 E.01515
G1 X50.334 Y156.09 E.24405
G3 X50.86 Y156.813 I-3.194 J2.877 E.03031
G1 X42.838 Y158.962 E.28111
G3 X42.901 Y158.268 I3.337 J-.048 E.02365
M204 S10000
G1 X43.117 Y157.447 F36000
G1 F1473.913
M204 S3000
G3 X43.417 Y156.823 I5.22 J2.128 E.02343
G1 X49.285 Y162.692 E.28091
G3 X48.662 Y162.992 I-2.755 J-4.927 E.02343
; WIPE_START
G1 X49.285 Y162.692 E-.13144
G1 X48.36 Y161.767 E-.24856
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.745 Y162.387 Z4 F36000
G1 Z3.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X49.958 Y162.214 I-.718 J-1.099 E.00931
G1 X51.204 Y157.563 E.163
G2 X51.106 Y157.306 I-1.268 J.336 E.0093
; WIPE_START
G1 X51.204 Y157.563 E-.05213
G1 X50.757 Y159.23 E-.32787
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X45.773 Y154.893 Z4 F36000
G1 Z3.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X46.489 Y154.714 I1.714 J5.349 E.02499
G1 X51.395 Y159.62 E.23484
G2 X51.433 Y159.188 I-2.729 J-.46 E.01471
G1 X43.53 Y161.306 E.27697
G2 X43.785 Y161.658 I1.803 J-1.037 E.01476
G1 X45.58 Y154.958 E.23481
G2 X45.183 Y155.135 I.637 J1.958 E.01476
G1 X50.973 Y160.925 E.27717
G2 X51.151 Y160.528 I-1.786 J-1.036 E.01476
G1 X44.45 Y162.323 E.23481
G2 X44.803 Y162.579 I1.379 J-1.532 E.01476
G1 X46.922 Y154.669 E.27718
G3 X48.154 Y154.789 I-.037 J6.775 E.04196
G1 X45.93 Y163.092 E.29095
G2 X46.114 Y163.142 I.331 J-.851 E.00648
G1 X50.119 Y162.069 E.14035
G2 X50.254 Y161.933 I-.577 J-.707 E.00648
G1 X44.175 Y155.855 E.29096
G2 X44.04 Y155.989 I.572 J.713 E.00648
G1 X42.965 Y160 E.14054
G2 X43.017 Y160.179 I1.16 J-.238 E.00631
G1 X51.32 Y157.954 E.29096
G2 X51.271 Y157.769 I-.902 J.139 E.00648
G1 X48.341 Y154.839 E.14027
G3 X48.549 Y154.904 I-.204 J1.021 E.00737
G1 X43.894 Y156.151 E.1631
G2 X43.721 Y156.364 I.925 J.931 E.00931
; WIPE_START
G1 X43.894 Y156.151 E-.05216
G1 X45.561 Y155.704 E-.32784
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X42.878 Y159.519 Z4 F36000
G1 Z3.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X42.919 Y159.78 E.00894
G1 X46.326 Y163.187 E.1631
G2 X46.604 Y163.236 I.447 J-1.741 E.00956
; OBJECT_ID: 14
; WIPE_START
G1 X46.326 Y163.187 E-.0536
G1 X45.112 Y161.972 E-.3264
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.885 Y159.517 Z4 F36000
G1 X26.719 Y155.723 Z4
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.667 Y155.71 E.00182
G2 X25.696 Y155.592 I-.892 J3.29 E.03323
G1 X25.438 Y155.608 E.00876
G2 X27.005 Y155.821 I.337 J3.392 E.67087
G1 X26.776 Y155.743 E.0082
M204 S10000
G1 X26.593 Y156.11 F36000
G1 F1473.913
M204 S3000
G1 X26.561 Y156.104 E.00111
G2 X25.707 Y155.999 I-.787 J2.897 E.02925
G1 X25.477 Y156.013 E.0078
G2 X26.859 Y156.201 I.298 J2.987 E.59069
G1 X26.65 Y156.13 E.00749
M204 S250
G1 X26.472 Y156.483 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.482 E.00039
G2 X25.717 Y156.392 I-.685 J2.518 E.02355
G1 X25.514 Y156.404 E.00637
G2 X26.719 Y156.568 I.261 J2.597 E.47562
G1 X26.529 Y156.502 E.0063
; WIPE_START
M204 S3000
G1 X26.46 Y156.482 E-.01368
G1 X26.194 Y156.422 E-.05189
G1 X25.717 Y156.392 E-.09074
G1 X25.514 Y156.404 E-.0386
G1 X25.11 Y156.479 E-.07819
G1 X24.85 Y156.563 E-.05189
G1 X24.6 Y156.674 E-.05191
G1 X24.586 Y156.683 E-.00312
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.94 Y154.319 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.785 Y154.315 E.00525
G2 X26.03 Y154.321 I0 J4.682 E.98747
G1 X26 Y154.32 E.00101
M204 S10000
G1 X25.961 Y153.915 F36000
G1 F1473.913
M204 S3000
G1 X25.519 Y153.915 E.01497
G2 X26.318 Y164.065 I.273 J5.085 E.55007
G2 X26.052 Y153.915 I-.534 J-5.065 E.51435
G1 X26.021 Y153.915 E.00103
M204 S250
G1 X25.961 Y153.523 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.499 Y153.524 E.01451
M73 P66 R15
G2 X26.359 Y164.455 I.294 J5.476 E.54877
G2 X26.072 Y153.523 I-.575 J-5.455 E.51313
G1 X26.021 Y153.523 E.00159
; WIPE_START
M204 S3000
G1 X25.499 Y153.524 E-.09934
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10906
G1 X24.053 Y153.804 E-.06249
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.608 Y154.747 Z4 F36000
G1 Z3.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.575 Y154.669 I-.87 J4.634 E.03514
G1 X25.416 Y155.26 E.02071
G1 X25.633 Y155.247 E.00733
G1 X25.103 Y154.718 E.02535
G2 X24.235 Y154.95 I.672 J4.243 E.03047
G1 X24.041 Y155.673 E.02533
G3 X24.239 Y155.58 I.54 J.893 E.00739
G1 X23.806 Y155.148 E.0207
G2 X22.946 Y155.727 I2.06 J3.99 E.03519
M204 S10000
G1 X22.557 Y156.106 F36000
G1 F1473.913
M204 S3000
G1 X22.481 Y156.199 E.00408
G1 X23.707 Y155.871 E.04298
M73 P67 R15
G2 X23.205 Y156.273 I1.666 J2.595 E.02185
G1 X22.796 Y155.865 E.01956
G1 X22.7 Y155.961 E.0046
G1 X21.591 Y160.098 E.14497
G2 X21.628 Y160.221 I.601 J-.115 E.00434
G1 X22.188 Y160.071 E.01961
G2 X22.42 Y160.67 I3.13 J-.865 E.02177
G1 X21.522 Y159.772 E.04296
G1 X21.549 Y159.899 E.00438
M204 S10000
G1 X21.691 Y160.414 F36000
G1 F1473.913
M204 S3000
G2 X22.145 Y161.346 I5.334 J-2.022 E.03515
G1 X22.736 Y161.188 E.02069
G3 X22.612 Y161.009 I.784 J-.678 E.00739
G1 X22.42 Y161.725 E.02509
G2 X23.06 Y162.366 I3.366 J-2.725 E.03071
G1 X23.776 Y162.174 E.0251
G3 X23.597 Y162.049 I.499 J-.909 E.00739
G1 X23.439 Y162.64 E.0207
G2 X24.371 Y163.096 I2.425 J-3.778 E.03519
M204 S10000
G1 X24.893 Y163.243 F36000
G1 F1473.913
M204 S3000
G1 X25.012 Y163.262 E.00408
G1 X24.116 Y162.366 E.0429
G2 X24.715 Y162.597 I1.461 J-2.892 E.02177
G1 X24.565 Y163.156 E.0196
G1 X24.696 Y163.192 E.0046
G1 X28.824 Y162.085 E.14466
G1 X28.92 Y161.989 E.0046
G1 X28.512 Y161.581 E.01955
G2 X28.915 Y161.078 I-2.193 J-2.169 E.02185
G1 X28.586 Y162.304 E.04298
G1 X28.68 Y162.229 E.00408
M204 S10000
G1 X29.058 Y161.84 F36000
G1 F1473.913
M204 S3000
G2 X29.637 Y160.979 I-3.41 J-2.919 E.03519
G1 X29.206 Y160.548 E.02062
G3 X29.112 Y160.744 I-1.072 J-.397 E.00737
G1 X29.828 Y160.552 E.0251
G2 X30.063 Y159.677 I-4.042 J-1.552 E.03071
G1 X29.536 Y159.15 E.02522
G1 X29.524 Y159.369 E.00742
G1 X30.116 Y159.211 E.02073
G2 X30.038 Y158.178 I-4.711 J-.164 E.03514
M204 S10000
G1 X29.903 Y157.66 F36000
G1 F1473.913
M204 S3000
G1 X29.863 Y157.537 E.00438
G1 X29.532 Y158.775 E.04338
G2 X29.435 Y158.129 I-2.502 J.045 E.02218
G1 X29.996 Y157.979 E.01965
G2 X29.966 Y157.854 I-.608 J.077 E.00434
G1 X26.931 Y154.819 E.14529
G2 X26.807 Y154.79 I-.201 J.577 E.00434
G1 X26.657 Y155.348 E.01957
G2 X26.003 Y155.255 I-.846 J3.613 E.02238
G1 X27.248 Y154.922 E.04362
G1 X27.125 Y154.882 E.00439
; WIPE_START
G1 X27.248 Y154.922 E-.02462
G1 X26.003 Y155.255 E-.24486
G1 X26.579 Y155.337 E-.11052
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.549 Y155.666 Z4 F36000
G1 Z3.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X27.95 Y155.242 I-3.903 J4.89 E.02485
G1 X27.793 Y155.826 E.02044
M204 S10000
G1 X28.015 Y155.981 F36000
G1 F1473.913
M204 S3000
G1 X28.705 Y155.796 E.0242
G1 X28.99 Y156.08 E.01361
G1 X28.805 Y156.771 E.0242
M204 S10000
G1 X28.96 Y156.992 F36000
G1 F1473.913
M204 S3000
G1 X29.543 Y156.836 E.02044
G2 X29.12 Y156.236 I-5.268 J3.27 E.02485
; WIPE_START
G1 X29.543 Y156.836 E-.20843
G1 X28.96 Y156.992 E-.17157
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.294 Y163.062 Z4 F36000
G1 Z3.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X27.957 Y162.753 I-2.508 J-6.249 E.02479
G1 X27.53 Y162.326 E.02044
M204 S10000
G1 X27.285 Y162.443 F36000
G1 F1473.913
M204 S3000
G1 X27.101 Y163.128 E.02399
G3 X26.708 Y163.231 I-.733 J-1.99 E.01377
G1 X26.209 Y162.732 E.02387
M204 S10000
G1 X25.938 Y162.75 F36000
G1 F1473.913
M204 S3000
G1 X25.782 Y163.331 E.02034
G2 X26.509 Y163.273 I-.042 J-5.186 E.02469
; WIPE_START
G1 X25.782 Y163.331 E-.20829
G1 X25.938 Y162.75 E-.17171
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.512 Y158.276 Z4 F36000
G1 Z3.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X21.455 Y159.003 I5.128 J.769 E.02469
G1 X22.035 Y158.847 E.02034
M204 S10000
G1 X22.053 Y158.576 F36000
G1 F1473.913
M204 S3000
G1 X21.554 Y158.077 E.02387
G3 X21.66 Y157.684 I1.924 J.305 E.01382
G1 X22.342 Y157.501 E.02391
M204 S10000
G1 X22.459 Y157.255 F36000
G1 F1473.913
M204 S3000
G1 X22.032 Y156.828 E.02045
G2 X21.723 Y157.49 I17.766 J8.713 E.02474
; CHANGE_LAYER
; Z_HEIGHT: 3.8
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X22.032 Y156.828 E-.20804
G1 X22.459 Y157.255 E-.17196
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L19
M991 S0 P18 ;notify layer change


M204 S10000
G17
G3 Z4 I1.217 J0 P1  F36000
; object ids of layer 19 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer19 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.13 Y93.516
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.073 Y93.535 E.00203
G2 X230.585 Y93.372 I1.138 J3.477 E.72623
G2 X230.085 Y93.355 I-.383 J3.899 E.01695
G2 X229.443 Y93.435 I.126 J3.656 E.02194
G1 X229.188 Y93.501 E.00891
M204 S10000
G1 X229.235 Y93.908 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.922 E.00131
G2 X230.543 Y93.777 I1.012 J3.09 E.64542
G2 X230.103 Y93.762 I-.34 J3.46 E.0149
G2 X229.528 Y93.833 I.108 J3.25 E.01966
G1 X229.294 Y93.893 E.00818
M204 S250
G1 X229.337 Y94.287 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.32 Y94.294 E.00057
G2 X230.502 Y94.167 I.89 J2.717 E.52575
G2 X230.121 Y94.154 I-.299 J3.039 E.01198
G2 X229.609 Y94.216 I.09 J2.858 E.01618
G1 X229.395 Y94.272 E.00694
; WIPE_START
M204 S3000
G1 X229.32 Y94.294 E-.0148
G1 X229.04 Y94.399 E-.05684
G1 X228.645 Y94.613 E-.0853
G1 X228.403 Y94.789 E-.05689
G1 X228.181 Y94.989 E-.05686
G1 X227.98 Y95.212 E-.0569
G1 X227.818 Y95.435 E-.0524
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.52 Y92.634 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.294 Y92.722 E.00822
G2 X231.762 Y101.44 I1.909 J4.289 E.48653
G2 X230.335 Y92.318 I-1.559 J-4.429 E.44103
G2 X228.752 Y92.546 I-.131 J4.693 E.05438
G1 X228.576 Y92.612 E.00636
M204 S10000
G1 X228.374 Y92.254 F36000
G1 F1473.913
M204 S3000
G1 X228.128 Y92.35 E.00895
G2 X231.898 Y101.824 I2.075 J4.661 E.52873
G2 X230.345 Y91.911 I-1.695 J-4.812 E.47927
G2 X228.626 Y92.159 I-.142 J5.1 E.05907
G1 X228.43 Y92.233 E.00709
M204 S250
G1 X228.234 Y91.888 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.967 Y91.988 E.00894
G2 X230.355 Y91.519 I2.226 J5.024 E1.00561
G2 X229.343 Y91.583 I-.028 J7.63 E.03182
G2 X228.504 Y91.783 I.85 J5.429 E.02707
G1 X228.29 Y91.866 E.00721
; WIPE_START
M204 S3000
G1 X227.967 Y91.988 E-.06559
G1 X227.455 Y92.252 E-.10938
G1 X227.21 Y92.402 E-.05469
G1 X226.744 Y92.74 E-.10929
G1 X226.584 Y92.885 E-.04105
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.728 Y93.104 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672899
G1 F952.413
M204 S3000
G1 X228.698 Y93.114 E.00165
G2 X226.025 Y97.012 I1.504 J3.897 E.26315
G1 X226.048 Y97.449 E.02292
G1 X226.115 Y97.872 E.02246
G1 X226.227 Y98.295 E.02291
G1 X226.311 Y98.531 E.01313
G2 X228.92 Y93.035 I3.891 J-1.52 E1.01797
G1 X228.785 Y93.083 E.00752
; OBJECT_ID: 12
; WIPE_START
G1 X228.698 Y93.114 E-.01739
G1 X228.306 Y93.289 E-.08163
G1 X227.928 Y93.507 E-.083
G1 X227.58 Y93.76 E-.08155
G1 X227.401 Y93.912 E-.04469
G1 X227.135 Y94.179 E-.07174
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.92 Y96.669 Z4.2 F36000
G1 X211.819 Y99.464 Z4.2
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.937 Y99.321 E.00629
G2 X208.671 Y93.118 I-3.165 J-2.295 E.2943
G2 X205.248 Y98.703 I.114 J3.911 E.26274
G2 X210.456 Y100.554 I3.529 J-1.679 E.2078
G2 X211.54 Y99.787 I-1.684 J-3.528 E.04516
G1 X211.78 Y99.51 E.01242
M204 S10000
G1 X211.539 Y99.171 F36000
G1 F1473.913
M204 S3000
G1 X211.817 Y98.78 E.01626
G2 X209.144 Y93.542 I-3.03 J-1.755 E.23629
G2 X208.682 Y93.525 I-.366 J3.727 E.01566
G2 X211.504 Y99.233 I.105 J3.5 E.4741
G1 X211.51 Y99.224 E.00036
M204 S250
G1 X211.216 Y98.949 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.298 Y98.856 E.00389
G2 X209.103 Y93.932 I-2.513 J-1.831 E.20459
G2 X208.692 Y93.917 I-.325 J3.308 E.0129
G2 X211.093 Y99.109 I.094 J3.108 E.38486
G1 X211.179 Y98.996 E.00446
; WIPE_START
M204 S3000
G1 X211.298 Y98.856 E-.03494
G1 X211.471 Y98.58 E-.06195
G1 X211.619 Y98.29 E-.06186
G1 X211.735 Y97.986 E-.06184
G1 X211.82 Y97.671 E-.06186
G1 X211.883 Y97.187 E-.09273
G1 X211.883 Y97.162 E-.00482
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.664 Y99.316 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.695 Y99.382 E.00246
G2 X208.909 Y92.318 I4.074 J-2.358 E.66252
G2 X208.041 Y92.373 I-.026 J6.537 E.02948
G2 X204.576 Y99.165 I.728 J4.651 E.3008
G1 X204.634 Y99.264 E.00388
M204 S10000
G1 X204.305 Y99.499 F36000
G1 F1473.913
M204 S3000
G1 X204.48 Y99.815 E.01223
G2 X208.92 Y91.911 I4.288 J-2.79 E.71102
G2 X207.977 Y91.971 I-.027 J7.103 E.03201
G2 X204.211 Y99.351 I.791 J5.055 E.32686
G1 X204.273 Y99.448 E.00391
M204 S250
G1 X203.962 Y99.697 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X203.999 Y99.783 E.00295
G2 X208.93 Y91.519 I4.768 J-2.758 E.71817
G2 X207.916 Y91.583 I-.028 J7.649 E.0319
G2 X203.861 Y99.529 I.852 J5.442 E.32598
G1 X203.931 Y99.646 E.00425
; WIPE_START
M204 S3000
G1 X203.999 Y99.783 E-.02919
G1 X204.32 Y100.263 E-.10966
G1 X204.683 Y100.711 E-.10954
G1 X205.091 Y101.119 E-.1096
G1 X205.181 Y101.192 E-.02201
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.974 Y99.044 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435962
G1 F1526.556
M204 S3000
G1 X205.163 Y99.372 E.01239
G1 X205.428 Y99.737 E.01474
G1 X205.73 Y100.072 E.01474
G1 X206.065 Y100.374 E.01474
G1 X206.426 Y100.636 E.01458
G1 X206.627 Y100.759 E.00771
G1 X207.029 Y100.964 E.01473
G1 X207.446 Y101.123 E.01458
G1 X207.881 Y101.24 E.01474
G1 X208.327 Y101.311 E.01474
G1 X208.777 Y101.334 E.01475
G1 X209.228 Y101.311 E.01475
G1 X209.674 Y101.24 E.01474
G1 X210.109 Y101.123 E.01473
G1 X210.525 Y100.964 E.01456
G1 X210.739 Y100.862 E.00773
G1 X211.129 Y100.636 E.01474
G1 X211.49 Y100.374 E.01458
G1 X211.825 Y100.072 E.01474
G1 X212.127 Y99.737 E.01474
G1 X212.392 Y99.372 E.01475
G1 X212.617 Y98.982 E.01473
G1 X212.799 Y98.574 E.01458
G1 X212.878 Y98.352 E.00771
G1 X212.994 Y97.916 E.01474
G1 X213.063 Y97.475 E.01457
G1 X213.087 Y97.025 E.01475
G1 X213.063 Y96.574 E.01475
G1 X212.993 Y96.128 E.01474
G1 X212.876 Y95.693 E.01474
G1 X212.716 Y95.276 E.01458
G1 X212.512 Y94.874 E.01473
G1 X212.389 Y94.673 E.00771
G1 X212.127 Y94.312 E.01458
G1 X211.825 Y93.977 E.01474
G1 X211.49 Y93.675 E.01474
G1 X211.124 Y93.41 E.01476
G1 X210.734 Y93.185 E.01473
G1 X210.327 Y93.003 E.01458
G1 X210.104 Y92.924 E.0077
G1 X209.669 Y92.808 E.01474
G1 X209.228 Y92.739 E.01457
G1 X208.777 Y92.715 E.01476
G1 X208.327 Y92.739 E.01474
G1 X207.881 Y92.809 E.01474
G1 X207.445 Y92.926 E.01475
G1 X207.029 Y93.086 E.01456
G1 X206.627 Y93.29 E.01475
G1 X206.426 Y93.413 E.00771
G1 X206.065 Y93.676 E.01458
G1 X205.73 Y93.977 E.01473
G1 X205.428 Y94.312 E.01473
G1 X205.163 Y94.678 E.01476
G1 X204.938 Y95.068 E.01474
G1 X204.756 Y95.475 E.01456
G1 X204.677 Y95.698 E.00772
G1 X204.561 Y96.133 E.01473
G1 X204.491 Y96.574 E.01457
G1 X204.468 Y97.025 E.01475
G1 X204.491 Y97.475 E.01475
G1 X204.561 Y97.916 E.01457
G1 X204.677 Y98.352 E.01474
G1 X204.756 Y98.574 E.0077
G1 X204.937 Y98.981 E.01457
G1 X204.944 Y98.992 E.00041
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.08342
G1 X205.428 Y99.737 E-.08569
G1 X205.73 Y100.072 E-.08567
G1 X206.065 Y100.374 E-.08572
G1 X206.233 Y100.496 E-.0395
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.844 Y98.584 Z4.2 F36000
G1 X183.882 Y94.711 Z4.2
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.844 Y94.779 E.00263
G2 X187.759 Y92.902 I3.491 J2.261 E.72991
G2 X187.211 Y92.883 I-.435 J4.434 E.01859
G2 X184.099 Y94.427 I.125 J4.157 E.1213
G1 X183.918 Y94.663 E.01006
M204 S10000
G1 X184.211 Y94.95 F36000
G1 F1473.913
M204 S3000
G1 X184.185 Y95 E.00191
G2 X187.717 Y93.307 I3.149 J2.038 E.6583
G2 X187.221 Y93.29 I-.392 J3.993 E.01679
G2 X184.415 Y94.683 I.113 J3.749 E.10941
G1 X184.247 Y94.902 E.00934
M204 S250
G1 X184.527 Y95.18 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.513 Y95.214 E.00114
G2 X187.676 Y93.698 I2.82 J1.825 E.54605
G2 X187.232 Y93.682 I-.351 J3.578 E.01394
G2 X184.719 Y94.929 I.101 J3.357 E.09074
G1 X184.564 Y95.132 E.00801
; WIPE_START
M204 S3000
G1 X184.513 Y95.214 E-.01815
G1 X184.33 Y95.514 E-.06677
G1 X184.187 Y95.835 E-.06685
G1 X184.038 Y96.341 E-.10018
G1 X183.983 Y96.688 E-.06681
G1 X183.966 Y97.01 E-.06124
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.456 Y92.318 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.585 Y92.373 I-.026 J6.558 E.02957
G2 X187.516 Y92.32 I.73 J4.666 E.97287
M204 S10000
G1 X187.478 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.467 Y91.911 E.00037
G2 X186.521 Y91.971 I-.027 J7.124 E.0321
G2 X187.86 Y91.938 I.793 J5.068 E1.0456
G1 X187.538 Y91.916 E.01095
M204 S250
G1 X187.502 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.477 Y91.519 E.00078
G2 X186.46 Y91.583 I-.028 J7.67 E.03198
G2 X187.901 Y91.548 I.854 J5.456 E1.04257
G1 X187.562 Y91.525 E.01067
; WIPE_START
M204 S3000
G1 X187.477 Y91.519 E-.01611
G1 X187.035 Y91.523 E-.08399
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10986
G1 X185.593 Y91.801 E-.06015
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.505 Y92.607 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200581
G1 F3805.652
M204 S3000
G1 X187.324 Y92.597 E.00238
G1 X186.86 Y92.622 E.0061
G1 X186.403 Y92.694 E.00607
G1 X186.173 Y92.749 E.0031
G1 X185.73 Y92.893 E.0061
G1 X185.308 Y93.081 E.00607
G1 X184.905 Y93.314 E.0061
G1 X184.529 Y93.587 E.00609
G1 X184.183 Y93.898 E.0061
G1 X183.872 Y94.244 E.00609
G1 X183.6 Y94.618 E.00607
G1 X183.368 Y95.021 E.00609
G1 X183.265 Y95.235 E.00311
G1 X183.1 Y95.667 E.00606
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.0061
G1 X182.882 Y97.039 E.00609
G1 X182.907 Y97.503 E.00609
G1 X182.979 Y97.963 E.0061
G1 X183.1 Y98.412 E.00609
G1 X183.266 Y98.844 E.00607
G1 X183.368 Y99.058 E.00311
G1 X183.6 Y99.46 E.0061
G1 X183.872 Y99.835 E.00606
G1 X184.183 Y100.18 E.0061
G1 X184.529 Y100.491 E.0061
G1 X184.905 Y100.765 E.0061
G1 X185.308 Y100.997 E.00609
G1 X185.73 Y101.185 E.00606
G1 X185.954 Y101.264 E.00311
G1 X186.403 Y101.384 E.0061
G1 X186.86 Y101.457 E.00607
G1 X187.324 Y101.481 E.0061
G1 X187.789 Y101.457 E.00609
G1 X188.246 Y101.384 E.00607
G1 X188.476 Y101.329 E.0031
G1 X188.918 Y101.185 E.00609
G1 X189.341 Y100.997 E.00607
G1 X189.744 Y100.764 E.0061
G1 X190.12 Y100.491 E.00609
G1 X190.465 Y100.18 E.0061
G1 X190.776 Y99.835 E.0061
G1 X191.049 Y99.459 E.00609
G1 X191.282 Y99.056 E.0061
G1 X191.47 Y98.633 E.00606
G1 X191.549 Y98.41 E.0031
G1 X191.67 Y97.961 E.0061
G1 X191.742 Y97.503 E.00607
G1 X191.766 Y97.039 E.00609
G1 X191.742 Y96.575 E.00609
G1 X191.67 Y96.118 E.00607
G1 X191.614 Y95.887 E.0031
G1 X191.47 Y95.446 E.00609
G1 X191.282 Y95.023 E.00607
G1 X191.05 Y94.62 E.00609
G1 X190.776 Y94.244 E.0061
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.00609
G1 X189.745 Y93.315 E.00607
G1 X189.343 Y93.082 E.0061
G1 X189.129 Y92.98 E.00311
G1 X188.697 Y92.815 E.00607
G1 X188.248 Y92.694 E.00609
G1 X187.789 Y92.622 E.0061
G1 X187.565 Y92.61 E.00293
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.04583
G1 X186.86 Y92.622 E-.08838
G1 X186.403 Y92.694 E-.08791
G1 X186.173 Y92.749 E-.04497
G1 X185.73 Y92.893 E-.08834
G1 X185.612 Y92.946 E-.02457
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.982 Y93.145 Z4.2 F36000
G1 X163.193 Y93.533 Z4.2
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.894 Y93.783 E.0132
G2 X166.53 Y92.7 I2.954 J3.272 E.80483
G2 X165.72 Y92.649 I-.79 J6.079 E.02751
G2 X163.252 Y93.493 I.129 J4.407 E.08962
G1 X163.243 Y93.499 E.00038
M204 S10000
G1 X163.442 Y93.856 F36000
G1 F1473.913
M204 S3000
M73 P68 R15
G1 X163.012 Y94.226 E.01921
G2 X165.323 Y101.023 I2.829 J2.829 E.30154
G2 X167.558 Y100.669 I.501 J-4.069 E.07761
G2 X165.731 Y93.056 I-1.723 J-3.612 E.36883
G2 X163.489 Y93.818 I.11 J3.999 E.08137
G1 X163.489 Y93.818 E0
M204 S250
G1 X163.696 Y94.154 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.293 Y94.508 E.01682
G2 X166.218 Y93.465 I2.557 J2.548 E.61042
G2 X165.741 Y93.448 I-.377 J3.844 E.01497
G2 X163.747 Y94.122 I.109 J3.608 E.06697
; WIPE_START
M204 S3000
G1 X163.293 Y94.508 E-.11316
G1 X163.035 Y94.783 E-.07179
G1 X162.813 Y95.089 E-.07176
G1 X162.543 Y95.587 E-.10765
G1 X162.513 Y95.664 E-.01564
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.483 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X165.973 Y92.318 I1.691 J-4.427 E.55771
G2 X165.099 Y92.373 I-.026 J6.579 E.02967
G2 X164.085 Y101.461 I.733 J4.682 E.41851
M204 S10000
G1 X163.974 Y101.851 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.00081
G2 X165.984 Y91.911 I1.836 J-4.808 E.60564
G2 X165.035 Y91.971 I-.027 J7.145 E.0322
G2 X163.502 Y101.645 I.796 J5.084 E.4384
G1 X163.919 Y101.827 E.01541
M204 S250
G1 X163.814 Y102.209 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.229 E.00139
G2 X165.994 Y91.519 I1.976 J-5.174 E.60377
G2 X164.974 Y91.584 I-.028 J7.695 E.03207
G2 X163.462 Y102.062 I.856 J5.472 E.44186
G1 X163.759 Y102.186 E.0101
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.229 E-.01984
G1 X164.407 Y102.406 E-.11023
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.706 Y102.587 E-.02956
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.922 Y106.084 Z4.2 F36000
G1 X47.285 Y163.611 Z4.2
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.627 Y163.588 E.0116
G2 X47.272 Y154.318 I-.488 J-4.623 E.4733
G2 X42.755 Y160.511 I-.121 J4.655 E.30476
G2 X47.142 Y163.614 I4.384 J-1.546 E.1939
G1 X47.225 Y163.612 E.00284
M204 S10000
G1 X47.327 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00267
G2 X47.283 Y153.911 I-.274 J-5.051 E.52354
G2 X46.35 Y153.97 I-.027 J7.024 E.03164
G2 X46.877 Y164.019 I.782 J4.998 E.50268
G1 X47.267 Y164.019 E.01321
M204 S250
G1 X47.327 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00312
G2 X47.293 Y153.519 I-.295 J-5.442 E.52257
G2 X46.289 Y153.582 I-.028 J7.569 E.03156
G2 X46.857 Y164.411 I.843 J5.385 E.50173
G1 X47.267 Y164.411 E.01288
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.03029
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.10842
G1 X48.826 Y164.152 E-.10839
G1 X49.213 Y164.003 E-.07864
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.001 Y163.264 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X49.168 Y155.176 E.28343
M204 S10000
G1 X49.604 Y155.442 F36000
G1 F1473.913
M204 S3000
G3 X50.14 Y155.888 I-2.821 J3.935 E.02362
G1 X43.002 Y157.801 E.25015
G2 X42.973 Y157.907 I.493 J.189 E.00373
G1 X48.202 Y163.135 E.25027
G2 X48.307 Y163.109 I-.115 J-.685 E.00369
G1 X50.221 Y155.968 E.25022
G3 X50.676 Y156.513 I-3.871 J3.695 E.02406
M204 S10000
G1 X50.934 Y156.94 F36000
G1 F1473.913
M204 S3000
G1 X42.844 Y159.107 E.28348
M204 S10000
G1 X42.857 Y159.31 F36000
G1 F1473.913
M204 S3000
G1 X42.881 Y159.542 E.00788
G1 X46.567 Y163.228 E.17645
G3 X46.419 Y163.207 I.025 J-.716 E.00508
G1 X49.88 Y162.279 E.1213
G1 X49.77 Y162.368 E.00479
G1 X51.119 Y157.334 E.17641
G3 X51.175 Y157.473 I-.632 J.336 E.00508
G1 X48.641 Y154.939 E.12129
G1 X48.773 Y154.99 E.00479
G1 X43.74 Y156.339 E.17637
G1 X43.829 Y156.229 E.00479
G1 X42.902 Y159.69 E.1213
G2 X43.061 Y160.314 I3.045 J-.443 E.02182
G1 X51.349 Y158.093 E.29046
G3 X51.439 Y159.134 I-4.407 J.905 E.03547
; WIPE_START
G1 X51.349 Y158.093 E-.19863
G1 X50.427 Y158.34 E-.18137
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.947 Y160.971 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X50.348 Y161.828 I-3.962 J-2.129 E.03547
G1 X44.277 Y155.757 E.29063
G3 X45.138 Y155.161 I2.806 J3.138 E.03551
; WIPE_START
G1 X44.277 Y155.757 E-.1988
G1 X44.952 Y156.431 E-.1812
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.974 Y154.669 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X48.017 Y154.755 I.146 J4.616 E.03549
G1 X45.795 Y163.048 E.29063
G3 X44.68 Y162.492 I1.774 J-4.957 E.04228
G1 X46.772 Y154.685 E.2736
G1 X46.67 Y154.695 E.00346
G1 X51.413 Y159.438 E.22705
G1 X51.424 Y159.337 E.00346
G1 X43.618 Y161.428 E.27354
G1 X43.678 Y161.511 E.00346
G1 X45.414 Y155.032 E.22705
G1 X45.321 Y155.073 E.00346
G1 X51.035 Y160.788 E.27354
G1 X51.077 Y160.694 E.00346
G1 X44.592 Y162.432 E.22725
G3 X43.798 Y161.676 I4.695 J-5.726 E.03715
; WIPE_START
G1 X44.592 Y162.432 E-.20833
G1 X45.465 Y162.198 E-.17168
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.491 Y156.698 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X49.411 Y162.617 E.28337
; OBJECT_ID: 14
; WIPE_START
G1 X47.997 Y161.203 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X40.605 Y159.299 Z4.2 F36000
G1 X26.713 Y155.721 Z4.2
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.667 Y155.71 E.00161
G2 X25.692 Y155.592 I-.892 J3.29 E.03336
G1 X25.437 Y155.608 E.00864
G2 X27.006 Y155.821 I.338 J3.392 E.67096
G1 X26.77 Y155.741 E.00844
M204 S10000
G1 X26.587 Y156.108 F36000
G1 F1473.913
M204 S3000
G1 X26.561 Y156.104 E.00089
G2 X25.703 Y156 I-.787 J2.897 E.02938
G1 X25.476 Y156.014 E.00768
G2 X26.86 Y156.201 I.298 J2.987 E.59074
G1 X26.644 Y156.128 E.00771
M204 S250
G1 X26.466 Y156.481 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.46 Y156.483 E.00021
G2 X25.713 Y156.392 I-.685 J2.518 E.02367
G1 X25.514 Y156.404 E.00625
G2 X26.719 Y156.568 I.26 J2.597 E.47562
G1 X26.523 Y156.5 E.0065
; WIPE_START
M204 S3000
G1 X26.46 Y156.483 E-.01244
G1 X26.194 Y156.422 E-.0519
G1 X25.713 Y156.392 E-.09145
G1 X25.514 Y156.404 E-.03789
G1 X25.11 Y156.479 E-.07818
G1 X24.85 Y156.563 E-.05189
G1 X24.6 Y156.674 E-.05191
G1 X24.581 Y156.686 E-.00435
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.916 Y154.318 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.052 Y154.372 I-.026 J6.499 E.02933
G2 X25.976 Y154.32 I.724 J4.626 E.96456
M204 S10000
G1 X25.942 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.927 Y153.911 E.00051
G2 X24.989 Y153.97 I-.027 J7.066 E.03185
G2 X26.317 Y153.938 I.787 J5.03 E1.03772
G1 X26.002 Y153.916 E.0107
M204 S250
G1 X25.966 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.937 Y153.519 E.00091
G2 X24.927 Y153.583 I-.028 J7.616 E.03176
G2 X26.358 Y153.548 I.848 J5.418 E1.03534
G1 X26.026 Y153.525 E.01044
; WIPE_START
M204 S3000
G1 X25.937 Y153.519 E-.01692
G1 X25.498 Y153.523 E-.08339
G1 X24.927 Y153.583 E-.10912
G1 X24.645 Y153.635 E-.05455
G1 X24.09 Y153.784 E-.10908
G1 X24.056 Y153.797 E-.00694
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.627 Y154.669 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X26.669 Y154.755 I.139 J4.635 E.03548
G1 X26.519 Y155.316 E.01965
G1 X26.395 Y155.297 E.00424
G1 X27.471 Y155.008 E.0377
G1 X27.227 Y154.915 E.00885
G1 X29.87 Y157.558 E.12651
G2 X29.778 Y157.31 I-1.621 J.463 E.00896
G1 X29.489 Y158.39 E.03784
G1 X29.469 Y158.266 E.00424
G1 X30.025 Y158.117 E.01949
G3 X30.116 Y159.158 I-4.421 J.911 E.03545
M204 S10000
G1 X29.52 Y158.591 F36000
G1 F1473.913
M204 S3000
G3 X29.541 Y158.956 I-1.716 J.281 E.0124
G1 X30.087 Y159.502 E.02612
G1 X30.102 Y159.361 E.00479
G1 X29.503 Y159.521 E.021
G3 X29.26 Y160.402 I-3.403 J-.462 E.03101
G1 X29.706 Y160.848 E.02133
G1 X29.763 Y160.716 E.00487
G1 X29.012 Y160.917 E.02633
G3 X28.807 Y161.226 I-1.569 J-.819 E.01256
M204 S10000
G1 X29.614 Y161.029 F36000
G1 F1473.913
M204 S3000
G3 X29.019 Y161.888 I-4.28 J-2.327 E.03543
G1 X28.607 Y161.475 E.01974
G1 X28.685 Y161.388 E.00397
G1 X28.4 Y162.453 E.03732
G2 X28.609 Y162.289 I-.936 J-1.413 E.00902
G1 X24.992 Y163.259 E.12676
G2 X25.248 Y163.298 I.315 J-1.198 E.00878
G1 X24.462 Y162.512 E.03761
G1 X24.579 Y162.557 E.00424
G1 X24.43 Y163.113 E.01948
G3 X23.485 Y162.67 I1.922 J-5.326 E.03539
M204 S10000
G1 X24.272 Y162.439 F36000
G1 F1473.913
M204 S3000
G3 X23.946 Y162.275 I.617 J-1.632 E.0124
G1 X23.196 Y162.476 E.02626
G2 X23.314 Y162.559 I.455 J-.521 E.0049
G1 X23.475 Y161.959 E.02102
G3 X22.825 Y161.311 I6.466 J-7.132 E.03109
G1 X22.226 Y161.471 E.02098
G2 X22.31 Y161.589 I.604 J-.337 E.0049
G1 X22.512 Y160.836 E.0264
G2 X22.705 Y161.146 I1.572 J-.767 E.0124
M204 S10000
G1 X22.116 Y161.3 F36000
G1 F1473.913
M204 S3000
G3 X21.672 Y160.355 I4.879 J-2.866 E.03539
G1 X22.229 Y160.206 E.01951
G1 X22.281 Y160.331 E.00456
G1 X21.487 Y159.537 E.03797
G2 X21.527 Y159.793 I1.237 J-.059 E.00878
G1 X22.494 Y156.183 E.12651
G1 X22.33 Y156.386 E.00885
G1 X23.397 Y156.1 E.03741
G1 X23.31 Y156.179 E.00397
G1 X22.897 Y155.766 E.01974
G3 X23.757 Y155.173 I3.072 J3.533 E.03544
M204 S10000
G1 X23.56 Y155.978 F36000
G1 F1473.913
M204 S3000
G3 X23.868 Y155.773 I1.128 J1.364 E.01256
G1 X24.071 Y155.018 E.02648
G2 X23.939 Y155.081 I.334 J.869 E.00495
G1 X24.377 Y155.519 E.02098
G3 X25.263 Y155.286 I1.424 J3.619 E.03108
G1 X25.424 Y154.684 E.02112
G1 X25.284 Y154.698 E.00479
G1 X25.834 Y155.249 E.02637
G2 X25.464 Y155.258 I-.143 J1.862 E.01256
; WIPE_START
G1 X25.834 Y155.249 E-.07038
G1 X25.284 Y154.698 E-.14802
G1 X25.424 Y154.684 E-.0269
G1 X25.263 Y155.286 E-.11853
G1 X25.181 Y155.308 E-.01617
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.821 Y155.177 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X27.668 Y155.747 E.01998
M204 S10000
G1 X28.161 Y156.088 F36000
G1 F1473.913
M204 S3000
G1 X28.821 Y155.911 E.02314
G1 X28.874 Y155.964 E.00255
G1 X28.696 Y156.63 E.02333
M204 S10000
G1 X29.038 Y157.117 F36000
G1 F1473.913
M204 S3000
G1 X29.608 Y156.964 E.02
; WIPE_START
G1 X29.038 Y157.117 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.08 Y162.676 Z4.2 F36000
G1 Z3.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X27.657 Y162.253 E.02024
M204 S10000
G1 X27.122 Y162.502 F36000
G1 F1473.913
M204 S3000
G1 X26.941 Y163.178 E.02368
G3 X26.873 Y163.196 I-.121 J-.315 E.0024
G1 X26.382 Y162.705 E.02349
M204 S10000
G1 X25.79 Y162.758 F36000
G1 F1473.913
M204 S3000
G1 X25.636 Y163.331 E.02006
; WIPE_START
G1 X25.79 Y162.758 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.455 Y159.149 Z4.2 F36000
M73 P68 R14
G1 Z3.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.027 Y158.996 E.02006
M204 S10000
G1 X22.08 Y158.403 F36000
G1 F1473.913
M204 S3000
G1 X21.589 Y157.912 E.02349
G3 X21.608 Y157.844 I.334 J.053 E.0024
G1 X22.278 Y157.664 E.02349
M204 S10000
G1 X22.529 Y157.125 F36000
G1 F1473.913
M204 S3000
G1 X22.111 Y156.707 E.02
; CHANGE_LAYER
; Z_HEIGHT: 4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X22.529 Y157.125 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L20
M991 S0 P19 ;notify layer change


M204 S10000
G17
G3 Z4.2 I1.217 J0 P1  F36000
; object ids of layer 20 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer20 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.128 Y93.516
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.074 Y93.534 E.00194
G2 X230.586 Y93.372 I1.138 J3.477 E.72624
M73 P69 R14
G2 X230.081 Y93.355 I-.383 J3.909 E.01711
G2 X229.443 Y93.435 I.131 J3.656 E.02179
G1 X229.186 Y93.501 E.00897
M204 S10000
G1 X229.233 Y93.909 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.921 E.00122
G2 X230.543 Y93.777 I1.012 J3.09 E.64542
G2 X230.099 Y93.762 I-.34 J3.472 E.01505
G2 X229.527 Y93.833 I.112 J3.249 E.01952
G1 X229.291 Y93.894 E.00825
M204 S250
G1 X229.335 Y94.287 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.32 Y94.294 E.0005
G2 X230.502 Y94.167 I.89 J2.717 E.52576
G2 X230.117 Y94.154 I-.299 J3.044 E.0121
G2 X229.609 Y94.216 I.094 J2.858 E.01605
G1 X229.393 Y94.272 E.00701
; WIPE_START
M204 S3000
G1 X229.32 Y94.294 E-.01439
G1 X229.04 Y94.399 E-.05686
G1 X228.645 Y94.613 E-.08527
G1 X228.403 Y94.789 E-.05689
G1 X228.181 Y94.989 E-.05685
G1 X227.889 Y95.33 E-.0853
G1 X227.819 Y95.438 E-.02444
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.519 Y92.625 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X230.343 Y92.318 I1.675 J4.387 E.93576
G2 X229.468 Y92.373 I-.038 J6.467 E.02969
G2 X228.575 Y92.604 I.726 J4.64 E.03127
M204 S10000
G1 X228.39 Y92.241 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.245 E.00057
G2 X230.354 Y91.911 I1.821 J4.768 E1.01694
G2 X229.405 Y91.97 I-.04 J7.034 E.03221
G2 X228.882 Y92.081 I.789 J5.042 E.01809
G1 X228.447 Y92.223 E.01549
M204 S250
G1 X228.27 Y91.874 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.967 Y91.988 E.01015
G2 X230.364 Y91.52 I2.226 J5.024 E1.00535
G2 X229.343 Y91.583 I-.041 J7.584 E.03209
G2 X228.504 Y91.783 I.85 J5.429 E.02707
G1 X228.326 Y91.853 E.00601
; WIPE_START
M204 S3000
G1 X227.967 Y91.988 E-.0729
G1 X227.455 Y92.252 E-.10936
G1 X226.973 Y92.565 E-.10931
G1 X226.611 Y92.858 E-.08842
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.734 Y93.102 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672858
G1 F952.475
M204 S3000
G1 X228.698 Y93.114 E.00198
G2 X226.025 Y97.003 I1.505 J3.897 E.26266
G1 X226.076 Y97.665 E.03477
G1 X226.23 Y98.303 E.03435
G1 X226.48 Y98.909 E.03434
G1 X226.823 Y99.467 E.03432
G1 X227.249 Y99.966 E.03436
G1 X227.747 Y100.392 E.03434
G1 X228.306 Y100.734 E.03432
G1 X228.912 Y100.985 E.03436
G1 X229.55 Y101.138 E.03434
G1 X230.203 Y101.19 E.03433
G1 X230.857 Y101.138 E.03433
G1 X231.494 Y100.985 E.03435
G1 X232.1 Y100.734 E.03434
G1 X232.659 Y100.392 E.03434
G1 X233.158 Y99.966 E.03436
G1 X233.445 Y99.647 E.02247
G1 X233.597 Y99.449 E.01308
G2 X229.122 Y92.976 I-3.393 J-2.437 E.53733
G1 X228.791 Y93.084 E.01825
; OBJECT_ID: 12
; WIPE_START
G1 X228.698 Y93.114 E-.01857
G1 X228.121 Y93.389 E-.12141
G1 X227.747 Y93.631 E-.08465
G1 X227.408 Y93.906 E-.083
G1 X227.139 Y94.176 E-.07238
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.923 Y96.665 Z4.4 F36000
G1 X211.832 Y99.457 Z4.4
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.946 Y99.326 E.00585
G2 X209.186 Y93.137 I-3.159 J-2.302 E.27756
G2 X208.648 Y93.119 I-.41 J4.182 E.01824
G2 X211.692 Y99.638 I.139 J3.906 E.52183
G1 X211.796 Y99.504 E.00573
M204 S10000
G1 X211.516 Y99.201 F36000
G1 F1473.913
M204 S3000
G1 X211.616 Y99.086 E.00516
G2 X209.144 Y93.542 I-2.83 J-2.062 E.24866
G2 X208.666 Y93.525 I-.366 J3.739 E.01619
G2 X211.387 Y99.368 I.12 J3.499 E.46754
G1 X211.479 Y99.249 E.00509
M204 S250
G1 X211.211 Y98.955 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.298 Y98.856 E.00414
G2 X209.103 Y93.932 I-2.513 J-1.831 E.20456
G2 X208.684 Y93.917 I-.325 J3.311 E.01316
G2 X211.094 Y99.108 I.102 J3.108 E.38464
G1 X211.174 Y99.003 E.00416
; WIPE_START
M204 S3000
G1 X211.298 Y98.856 E-.03649
G1 X211.471 Y98.58 E-.06189
G1 X211.619 Y98.29 E-.06185
G1 X211.735 Y97.986 E-.06184
G1 X211.82 Y97.671 E-.06187
G1 X211.883 Y97.187 E-.09273
G1 X211.883 Y97.17 E-.00333
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.649 Y99.282 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.823 Y99.593 E.01207
G2 X208.918 Y92.318 I3.946 J-2.568 E.65406
G2 X208.041 Y92.373 I-.038 J6.491 E.02977
G2 X204.576 Y99.166 I.728 J4.652 E.30083
G1 X204.617 Y99.231 E.00262
M204 S10000
G1 X204.297 Y99.485 F36000
G1 F1473.913
M204 S3000
G1 X204.481 Y99.815 E.01279
G2 X208.929 Y91.911 I4.288 J-2.79 E.71066
G2 X207.977 Y91.971 I-.04 J7.056 E.0323
G2 X204.212 Y99.351 I.791 J5.054 E.32684
G1 X204.265 Y99.434 E.00334
M204 S250
G1 X203.958 Y99.681 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.151 Y100.029 E.01249
G2 X208.939 Y91.52 I4.616 J-3.004 E.70878
G2 X207.916 Y91.583 I-.041 J7.602 E.03217
G2 X203.862 Y99.529 I.852 J5.441 E.32597
G1 X203.926 Y99.63 E.00374
; WIPE_START
M204 S3000
G1 X204.151 Y100.029 E-.08707
G1 X204.32 Y100.263 E-.0548
G1 X204.683 Y100.711 E-.10963
G1 X205.091 Y101.119 E-.10952
G1 X205.169 Y101.182 E-.01898
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.966 Y99.03 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436037
G1 F1526.265
M204 S3000
G1 X205.163 Y99.372 E.01292
G2 X204.468 Y97.019 I3.613 J-2.347 E.80365
G1 X204.491 Y97.475 E.01492
G1 X204.561 Y97.916 E.01458
G1 X204.677 Y98.352 E.01474
G1 X204.761 Y98.586 E.00812
G2 X204.936 Y98.978 I4.016 J-1.561 E.01404
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.08651
G1 X205.428 Y99.737 E-.08561
G1 X205.727 Y100.068 E-.08476
G1 X205.907 Y100.239 E-.0473
G1 X206.218 Y100.49 E-.07581
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.829 Y98.579 Z4.4 F36000
G1 X183.879 Y94.714 Z4.4
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.844 Y94.779 E.00249
G2 X187.759 Y92.902 I3.491 J2.26 E.72979
G2 X187.206 Y92.883 I-.435 J4.433 E.01875
G2 X184.099 Y94.427 I.129 J4.156 E.12114
G1 X183.915 Y94.667 E.01022
M204 S10000
G1 X184.208 Y94.953 F36000
G1 F1473.913
M204 S3000
G1 X184.185 Y95 E.00177
G2 X187.717 Y93.307 I3.149 J2.039 E.65834
G2 X187.217 Y93.29 I-.392 J3.993 E.01694
G2 X184.415 Y94.683 I.117 J3.749 E.10925
G1 X184.244 Y94.906 E.0095
M204 S250
G1 X184.525 Y95.184 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.513 Y95.213 E.001
G2 X187.676 Y93.698 I2.82 J1.826 E.54609
G2 X187.227 Y93.682 I-.351 J3.577 E.01408
G2 X184.719 Y94.929 I.106 J3.358 E.09059
G1 X184.561 Y95.136 E.00815
; WIPE_START
M204 S3000
G1 X184.513 Y95.213 E-.01732
G1 X184.33 Y95.514 E-.06675
G1 X184.187 Y95.835 E-.06684
G1 X184.038 Y96.341 E-.10019
G1 X183.983 Y96.688 E-.06681
G1 X183.965 Y97.014 E-.06208
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.465 Y92.318 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.585 Y92.373 I-.038 J6.51 E.02986
G2 X187.525 Y92.321 I.731 J4.666 E.97262
M204 S10000
G1 X187.483 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.476 Y91.912 E.00024
G2 X186.522 Y91.971 I-.039 J7.081 E.03238
G2 X187.86 Y91.938 I.793 J5.069 E1.04566
G1 X187.543 Y91.916 E.01078
M204 S250
G1 X187.507 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.486 Y91.52 E.00067
G2 X186.46 Y91.583 I-.041 J7.625 E.03225
G2 X187.901 Y91.548 I.854 J5.456 E1.04262
G1 X187.567 Y91.525 E.01051
; WIPE_START
M204 S3000
G1 X187.486 Y91.52 E-.01546
G1 X187.035 Y91.523 E-.08562
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10985
G1 X185.598 Y91.8 E-.05919
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.51 Y92.607 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200579
G1 F3805.698
M204 S3000
G1 X187.324 Y92.597 E.00245
G1 X186.86 Y92.622 E.00609
G1 X186.403 Y92.694 E.00607
G1 X185.954 Y92.814 E.00609
G1 X185.73 Y92.893 E.00311
G1 X185.308 Y93.081 E.00606
G1 X184.905 Y93.314 E.0061
G1 X184.529 Y93.587 E.00609
G1 X184.184 Y93.898 E.00609
G1 X183.872 Y94.244 E.0061
G1 X183.6 Y94.618 E.00607
G1 X183.367 Y95.021 E.0061
G1 X183.266 Y95.234 E.0031
G1 X183.1 Y95.667 E.00607
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.0061
G1 X182.882 Y97.039 E.00609
G1 X182.907 Y97.503 E.00609
G1 X182.979 Y97.961 E.00607
G1 X183.034 Y98.191 E.0031
G1 X183.178 Y98.633 E.00609
G1 X183.366 Y99.056 E.00607
G1 X183.599 Y99.458 E.00609
G1 X183.872 Y99.835 E.0061
G1 X184.183 Y100.18 E.00609
G1 X184.529 Y100.491 E.0061
G1 X184.905 Y100.765 E.0061
G1 X185.308 Y100.997 E.00609
G1 X185.73 Y101.185 E.00607
G1 X185.954 Y101.264 E.0031
G1 X186.403 Y101.384 E.00609
G1 X186.86 Y101.457 E.00607
G1 X187.324 Y101.481 E.00609
G1 X187.789 Y101.457 E.0061
G1 X188.248 Y101.384 E.0061
G1 X188.697 Y101.264 E.00609
G1 X189.129 Y101.098 E.00607
G1 X189.543 Y100.887 E.0061
G1 X189.745 Y100.763 E.00311
G1 X190.12 Y100.491 E.00607
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.0061
G1 X191.05 Y99.458 E.0061
G1 X191.282 Y99.056 E.00609
G1 X191.47 Y98.633 E.00606
G1 X191.549 Y98.41 E.00311
G1 X191.67 Y97.961 E.00609
G1 X191.742 Y97.503 E.00607
G1 X191.766 Y97.039 E.00609
G1 X191.742 Y96.575 E.00609
G1 X191.669 Y96.116 E.0061
G1 X191.549 Y95.667 E.00609
G1 X191.383 Y95.234 E.00607
G1 X191.281 Y95.021 E.0031
G1 X191.049 Y94.618 E.00609
G1 X190.776 Y94.244 E.00607
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.0061
G1 X189.743 Y93.314 E.0061
G1 X189.341 Y93.081 E.00609
G1 X188.918 Y92.893 E.00607
G1 X188.476 Y92.749 E.0061
G1 X188.246 Y92.694 E.0031
G1 X187.789 Y92.622 E.00607
G1 X187.57 Y92.61 E.00286
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.04685
G1 X186.86 Y92.622 E-.0883
G1 X186.403 Y92.694 E-.08795
G1 X185.954 Y92.814 E-.08834
G1 X185.73 Y92.893 E-.04505
G1 X185.617 Y92.944 E-.02351
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.987 Y93.141 Z4.4 F36000
G1 X163.202 Y93.524 Z4.4
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.07 Y93.633 E.00583
G2 X166.53 Y92.7 I2.779 J3.422 E.81264
G2 X165.715 Y92.649 I-.787 J6.046 E.02766
G2 X163.253 Y93.492 I.134 J4.406 E.08942
M204 S10000
G1 X163.436 Y93.862 F36000
G1 F1473.913
M204 S3000
G1 X163.017 Y94.231 E.01892
G2 X166.259 Y93.075 I2.834 J2.824 E.73052
G2 X165.726 Y93.056 I-.418 J4.256 E.01807
G2 X163.492 Y93.823 I.125 J3.999 E.08113
G1 X163.485 Y93.828 E.00028
M204 S250
G1 X163.691 Y94.161 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.573 Y94.255 E.00474
G2 X166.218 Y93.465 I2.277 J2.801 E.62225
G2 X165.736 Y93.448 I-.377 J3.843 E.01513
G2 X163.877 Y94.033 I.114 J3.608 E.06185
G1 X163.74 Y94.127 E.00522
; WIPE_START
M204 S3000
G1 X163.573 Y94.255 E-.04007
G1 X163.288 Y94.502 E-.07172
G1 X162.92 Y94.933 E-.10769
G1 X162.714 Y95.25 E-.07177
G1 X162.543 Y95.587 E-.0718
G1 X162.511 Y95.67 E-.01695
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.108 Y101.461 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.375 Y101.565 E.00969
G2 X165.982 Y92.318 I1.457 J-4.51 E.54903
G2 X165.099 Y92.373 I-.039 J6.529 E.02996
G2 X163.912 Y101.388 I.733 J4.682 E.41213
G1 X164.052 Y101.44 E.00507
M204 S10000
G1 X163.979 Y101.854 F36000
G1 F1473.913
M204 S3000
M73 P70 R14
G1 X163.995 Y101.863 E.00061
G2 X165.992 Y91.912 I1.836 J-4.808 E.60537
G2 X165.035 Y91.971 I-.04 J7.096 E.03249
G2 X163.502 Y101.645 I.796 J5.084 E.4384
G1 X163.924 Y101.83 E.01561
M204 S250
G1 X163.82 Y102.211 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.229 E.00121
G2 X166.003 Y91.52 I1.976 J-5.174 E.60351
G2 X164.974 Y91.584 I-.041 J7.646 E.03234
G2 X163.324 Y101.994 I.857 J5.472 E.43703
G1 X163.765 Y102.187 E.0151
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.229 E-.01871
G1 X164.129 Y102.324 E-.05513
G1 X164.407 Y102.406 E-.05512
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.712 Y102.587 E-.03067
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.928 Y106.085 Z4.4 F36000
G1 X47.333 Y163.613 Z4.4
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.00174
G2 X47.28 Y154.318 I-.252 J-4.644 E.48111
G2 X46.414 Y154.372 I-.038 J6.412 E.0294
G2 X46.898 Y163.613 I.719 J4.595 E.46221
G1 X47.273 Y163.613 E.01269
M204 S10000
G1 X47.333 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00247
G2 X47.291 Y153.911 I-.274 J-5.051 E.52328
G2 X46.35 Y153.97 I-.039 J6.977 E.03193
G2 X46.877 Y164.019 I.782 J4.998 E.50267
G1 X47.273 Y164.019 E.01341
M204 S250
G1 X47.333 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00293
G2 X47.836 Y164.372 I-.28 J-5.442 E.01289
G1 X47.994 Y164.351 E.00501
G2 X47.301 Y153.52 I-.86 J-5.383 E.50466
G2 X46.857 Y164.408 I-.154 J5.447 E.53251
G1 X47.273 Y164.411 E.01306
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.02913
G1 X47.836 Y164.372 E-.07812
G1 X47.994 Y164.351 E-.03034
G1 X48.275 Y164.299 E-.05423
G1 X48.826 Y164.152 E-.10839
G1 X49.218 Y164.001 E-.0798
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.151 Y163.146 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X50.105 Y155.853 E.25557
M204 S10000
G1 X50.256 Y156.003 F36000
G1 F1473.913
M204 S3000
G1 X42.963 Y157.958 E.25557
M204 S10000
G1 X43.018 Y157.751 F36000
G1 F1473.913
M204 S3000
G1 X48.357 Y163.091 E.25558
; WIPE_START
G1 X46.943 Y161.676 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X45.854 Y163.067 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X46.79 Y163.251 I1.311 J-4.198 E.03237
G1 X42.857 Y159.318 E.18827
G1 X43.604 Y156.525 E.09787
G1 X48.981 Y155.081 E.18846
G1 X51.028 Y157.128 E.09799
G1 X49.588 Y162.502 E.18831
G1 X46.797 Y163.252 E.09783
G1 X46.857 Y163.258 E.00203
G1 X49.04 Y155.111 E.2855
G3 X49.344 Y155.273 I-.619 J1.529 E.01171
M204 S10000
G1 X48.795 Y154.998 F36000
G1 F1473.913
M204 S3000
G2 X47.877 Y154.732 I-1.695 J4.133 E.03242
G1 X45.66 Y163.004 E.28987
G3 X44.748 Y162.536 I2.39 J-5.786 E.03474
G1 X51.003 Y160.861 E.21919
G1 X51.097 Y160.649 E.00783
G1 X45.459 Y155.012 E.26986
G1 X45.248 Y155.106 E.00783
G1 X43.571 Y161.364 E.2193
G1 X43.707 Y161.551 E.00783
G1 X51.408 Y159.488 E.26986
G1 X51.432 Y159.257 E.00783
G1 X46.851 Y154.676 E.2193
G1 X46.621 Y154.7 E.00783
G1 X44.557 Y162.404 E.26994
G3 X43.83 Y161.713 I3.105 J-4 E.03399
; WIPE_START
G1 X44.557 Y162.404 E-.1905
G1 X44.815 Y161.44 E-.18951
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X42.879 Y159.52 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X43.104 Y160.448 I4.618 J-.632 E.03238
G1 X51.379 Y158.231 E.28996
G2 X51.11 Y157.314 I-3.887 J.64 E.03244
M204 S10000
G1 X50.835 Y156.764 F36000
G1 F1473.913
M204 S3000
G3 X50.998 Y157.069 I-1.368 J.925 E.01171
G1 X42.85 Y159.252 E.2855
G3 X42.844 Y158.907 I1.64 J-.203 E.01172
; WIPE_START
G1 X42.85 Y159.252 E-.06564
G1 X44.449 Y158.824 E-.31436
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.386 Y156.87 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X43.57 Y156.576 I1.641 J.824 E.01173
G1 X49.534 Y162.541 E.28551
G3 X49.238 Y162.719 I-.994 J-1.316 E.01171
M204 S10000
G1 X49.753 Y162.382 F36000
G1 F1473.913
M204 S3000
G2 X50.445 Y161.724 I-4.455 J-5.38 E.03235
G1 X44.384 Y155.664 E.2901
G2 X43.726 Y156.357 I3.294 J3.793 E.03241
; OBJECT_ID: 14
; WIPE_START
G1 X44.384 Y155.664 E-.18165
G1 X45.123 Y156.402 E-.19835
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.496 Y156.117 Z4.4 F36000
G1 X26.668 Y155.712 Z4.4
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.665 E.00611
G2 X25.954 Y155.594 I-.709 J3.335 E.01844
G2 X25.437 Y155.608 I-.161 J3.707 E.01754
G2 X26.839 Y155.757 I.349 J3.391 E.67695
G1 X26.726 Y155.727 E.00394
M204 S10000
G1 X26.563 Y156.105 F36000
G1 F1473.913
M204 S3000
G1 X26.409 Y156.063 E.00539
G2 X25.937 Y156.001 I-.624 J2.936 E.01615
G2 X25.476 Y156.014 I-.144 J3.297 E.01561
G2 X26.713 Y156.145 I.309 J2.986 E.59602
G1 X26.621 Y156.12 E.00322
M204 S250
G1 X26.462 Y156.483 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00435
G2 X25.92 Y156.393 I-.543 J2.553 E.01292
G2 X25.514 Y156.404 I-.127 J2.905 E.01274
G2 X26.592 Y156.518 I.271 J2.596 E.47989
G1 X26.52 Y156.498 E.00234
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.03775
G1 X25.92 Y156.393 E-.07819
G1 X25.514 Y156.404 E-.07712
G1 X25.11 Y156.479 E-.07815
G1 X24.85 Y156.563 E-.0519
G1 X24.6 Y156.674 E-.05191
G1 X24.578 Y156.688 E-.00498
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.925 Y154.318 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.052 Y154.372 I-.038 J6.453 E.02962
G2 X25.985 Y154.321 I.725 J4.628 E.9646
M204 S10000
G1 X25.947 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.936 Y153.911 E.00038
G2 X24.989 Y153.97 I-.04 J7.02 E.03214
G2 X26.317 Y153.938 I.788 J5.03 E1.03773
G1 X26.007 Y153.916 E.01054
M204 S250
G1 X25.971 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.946 Y153.52 E.0008
G2 X24.927 Y153.583 I-.041 J7.569 E.03202
G2 X26.358 Y153.548 I.848 J5.418 E1.03529
G1 X26.031 Y153.525 E.01028
; WIPE_START
M204 S3000
G1 X25.946 Y153.52 E-.01626
G1 X25.498 Y153.523 E-.08501
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10906
G1 X24.063 Y153.801 E-.06055
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.309 Y155.278 Z4.4 F36000
G1 Z4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X26.042 Y155.257 I.455 J3.144 E.02488
G1 X25.465 Y154.679 E.02766
G1 X25.274 Y154.699 E.00649
G1 X25.109 Y155.315 E.02156
G2 X24.522 Y155.464 I.272 J2.29 E.02055
G1 X24.078 Y155.02 E.02127
G1 X23.903 Y155.098 E.00649
G1 X23.693 Y155.881 E.02745
G3 X24.333 Y155.538 I2.341 J3.602 E.02462
; WIPE_START
G1 X23.693 Y155.881 E-.13801
G1 X23.903 Y155.098 E-.1541
G1 X24.078 Y155.02 E-.03646
G1 X24.269 Y155.211 E-.05143
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.026 Y156.456 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X22.606 Y157.001 I3.161 J2.869 E.02332
G1 X22.19 Y156.586 E.01991
G1 X23.166 Y156.309 E.03434
G1 X23.415 Y156.084 E.01137
G1 X23.005 Y155.674 E.01965
G2 X22.275 Y156.454 I10.949 J10.965 E.03618
G1 X21.477 Y159.434 E.10442
G2 X21.716 Y160.49 I4.481 J-.461 E.03674
G1 X22.275 Y160.34 E.01957
G1 X22.171 Y160.021 E.01137
G1 X21.462 Y159.294 E.03438
G1 X22.041 Y159.139 E.02028
G2 X22.127 Y159.823 I2.187 J.072 E.02343
; WIPE_START
G1 X22.041 Y159.139 E-.13096
G1 X21.462 Y159.294 E-.11386
G1 X21.958 Y159.803 E-.13518
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.113 Y158.236 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X21.635 Y157.758 E.02288
M204 S10000
G1 X21.57 Y158 F36000
G1 F1473.913
M204 S3000
G1 X22.221 Y157.826 E.02278
; WIPE_START
G1 X21.57 Y158 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.797 Y161.272 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.414 Y160.655 I3.445 J-2.566 E.02462
G1 X22.204 Y161.437 E.02741
G2 X22.314 Y161.594 I.804 J-.442 E.0065
G1 X22.924 Y161.431 E.02138
G2 X23.355 Y161.862 I2.263 J-1.832 E.02067
G1 X23.191 Y162.472 E.02138
G2 X23.349 Y162.581 I.6 J-.695 E.0065
G1 X24.134 Y162.371 E.02752
G3 X23.515 Y161.986 I1.15 J-2.543 E.02473
; WIPE_START
G1 X24.134 Y162.371 E-.13842
G1 X23.349 Y162.581 E-.15447
G1 X23.191 Y162.472 E-.03641
G1 X23.26 Y162.214 E-.0507
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X24.958 Y162.664 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X25.645 Y162.751 I.891 J-4.274 E.02348
G1 X25.471 Y163.321 E.02019
G1 X24.761 Y162.611 E.03401
G3 X24.446 Y162.506 I.342 J-1.55 E.01125
G1 X24.295 Y163.069 E.01974
G2 X25.351 Y163.309 I1.516 J-4.239 E.03674
G1 X28.331 Y162.51 E.10441
G2 X29.109 Y161.777 I-8.283 J-9.567 E.03618
G1 X28.701 Y161.37 E.01949
G1 X28.477 Y161.62 E.01137
G1 X28.2 Y162.596 E.03434
G1 X27.784 Y162.18 E.01991
G2 X28.329 Y161.76 I-2.323 J-3.58 E.02332
; WIPE_START
G1 X27.784 Y162.18 E-.13078
G1 X28.2 Y162.596 E-.11173
G1 X28.397 Y161.9 E-.13749
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.959 Y162.565 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X26.785 Y163.215 E.02278
M204 S10000
G1 X27.027 Y163.15 F36000
G1 F1473.913
M204 S3000
G1 X26.547 Y162.67 E.02298
; WIPE_START
G1 X27.027 Y163.15 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.247 Y160.452 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X28.904 Y161.093 I-3.946 J-1.701 E.02462
G1 X29.686 Y160.883 E.02741
G2 X29.768 Y160.71 I-.784 J-.474 E.0065
G1 X29.321 Y160.263 E.02138
G2 X29.471 Y159.676 I-2.153 J-.862 E.02055
G1 X30.089 Y159.511 E.02165
G2 X30.109 Y159.323 I-1.183 J-.219 E.00638
G1 X29.53 Y158.745 E.02769
G3 X29.508 Y159.476 I-3.791 J.252 E.0248
; WIPE_START
G1 X29.53 Y158.745 E-.13901
G1 X30.109 Y159.323 E-.15543
G1 X30.089 Y159.511 E-.0358
G1 X29.836 Y159.578 E-.04976
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.372 Y157.885 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X29.104 Y157.246 I-4.142 J1.363 E.02348
G1 X29.684 Y157.113 E.02016
G1 X29.425 Y158.082 E.03394
G3 X29.491 Y158.407 I-1.512 J.478 E.01125
G1 X30.054 Y158.256 E.01974
G2 X29.745 Y157.233 I-7.185 J1.614 E.0362
G1 X27.553 Y155.04 E.10496
G2 X26.529 Y154.733 I-4.133 J11.922 E.03618
G1 X26.378 Y155.299 E.01981
G1 X26.707 Y155.36 E.01134
G1 X27.692 Y155.111 E.03439
G1 X27.54 Y155.679 E.01991
G2 X26.902 Y155.417 I-1.939 J3.801 E.02338
; WIPE_START
G1 X27.54 Y155.679 E-.13108
G1 X27.692 Y155.111 E-.11174
G1 X26.992 Y155.288 E-.13717
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.292 Y156.199 Z4.4 F36000
G1 Z4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X28.936 Y156.027 E.02259
M204 S10000
G1 X28.759 Y155.849 F36000
G1 F1473.913
M204 S3000
G1 X28.586 Y156.494 E.02262
; CHANGE_LAYER
; Z_HEIGHT: 4.2
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X28.759 Y155.849 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L21
M991 S0 P20 ;notify layer change


M204 S10000
G17
G3 Z4.4 I1.217 J0 P1  F36000
; object ids of layer 21 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer21 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.126 Y93.517
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.074 Y93.534 E.00188
G2 X230.586 Y93.372 I1.138 J3.477 E.72623
G2 X230.077 Y93.355 I-.383 J3.913 E.01725
G2 X229.443 Y93.435 I.135 J3.656 E.02165
G1 X229.184 Y93.502 E.00905
M204 S10000
G1 X229.231 Y93.91 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.921 E.00116
G2 X230.543 Y93.777 I1.011 J3.09 E.64542
G2 X230.095 Y93.762 I-.34 J3.471 E.01519
G2 X229.528 Y93.833 I.116 J3.249 E.01938
G1 X229.289 Y93.895 E.00833
M204 S250
G1 X229.333 Y94.288 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.321 Y94.295 E.00044
G2 X230.353 Y94.155 I.894 J2.716 E.5305
G2 X230.112 Y94.154 I-.135 J2.283 E.00754
G2 X229.609 Y94.217 I.102 J2.858 E.01592
G1 X229.391 Y94.273 E.00707
; WIPE_START
M204 S3000
G1 X229.321 Y94.295 E-.01399
G1 X229.04 Y94.399 E-.05685
M73 P71 R14
G1 X228.773 Y94.535 E-.05688
G1 X228.522 Y94.698 E-.05688
G1 X228.181 Y94.989 E-.08528
G1 X227.944 Y95.259 E-.06808
G1 X227.816 Y95.438 E-.04205
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.592 Y92.606 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.292 Y92.719 E.01084
G2 X230.352 Y92.319 I1.903 J4.293 E.927
G2 X229.468 Y92.373 I-.051 J6.43 E.02998
G2 X228.751 Y92.543 I.727 J4.639 E.02498
G1 X228.648 Y92.584 E.00377
M204 S10000
G1 X228.446 Y92.226 F36000
G1 F1473.913
M204 S3000
M73 P71 R13
G1 X228.126 Y92.347 E.01156
G2 X230.362 Y91.912 I2.068 J4.665 E1.00745
G2 X229.405 Y91.97 I-.052 J6.994 E.0325
G2 X228.625 Y92.156 I.79 J5.041 E.02714
G1 X228.502 Y92.205 E.00449
M204 S250
G1 X228.306 Y91.861 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.967 Y91.988 E.01135
G2 X230.373 Y91.52 I2.227 J5.023 E1.00498
G2 X229.343 Y91.583 I-.053 J7.543 E.03236
G2 X228.504 Y91.783 I.85 J5.428 E.02707
G1 X228.361 Y91.839 E.00481
; WIPE_START
M204 S3000
G1 X227.967 Y91.988 E-.08018
G1 X227.455 Y92.252 E-.10936
G1 X226.973 Y92.565 E-.1093
G1 X226.744 Y92.74 E-.0547
G1 X226.641 Y92.833 E-.02647
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.8 Y93.078 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672881
G1 F952.44
M204 S3000
G1 X228.698 Y93.114 E.00569
G2 X226.025 Y97.003 I1.505 J3.897 E.26268
G1 X226.048 Y97.449 E.02335
G1 X226.116 Y97.881 E.02291
G1 X226.23 Y98.303 E.0229
G1 X226.386 Y98.711 E.02289
G1 X226.585 Y99.101 E.02292
G1 X226.823 Y99.467 E.02289
G1 X227.098 Y99.807 E.02291
G1 X227.424 Y100.131 E.02406
G2 X228.92 Y93.035 I2.779 J-3.12 E.91511
G1 X228.857 Y93.058 E.00351
; OBJECT_ID: 12
; WIPE_START
G1 X228.698 Y93.114 E-.03202
G1 X228.306 Y93.289 E-.08154
G1 X227.935 Y93.503 E-.08145
G1 X227.741 Y93.636 E-.04469
G1 X227.407 Y93.907 E-.08153
G1 X227.189 Y94.125 E-.05877
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.976 Y96.621 Z4.6 F36000
G1 X211.856 Y99.43 Z4.6
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.062 Y99.157 E.01155
G2 X209.186 Y93.137 I-3.275 J-2.133 E.27062
G2 X208.643 Y93.119 I-.41 J4.182 E.0184
G2 X211.82 Y99.489 I.143 J3.906 E.52835
G1 X211.825 Y99.481 E.00029
M204 S10000
G1 X211.527 Y99.191 F36000
G1 F1473.913
M204 S3000
G1 X211.72 Y98.935 E.01084
G2 X209.144 Y93.542 I-2.934 J-1.911 E.24245
G2 X208.662 Y93.525 I-.367 J3.74 E.01634
G2 X211.496 Y99.242 I.124 J3.499 E.47302
M204 S250
G1 X211.21 Y98.961 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.39 Y98.722 E.00939
G2 X209.103 Y93.932 I-2.605 J-1.697 E.19944
G2 X208.679 Y93.917 I-.325 J3.314 E.01329
G2 X211.178 Y99.01 I.106 J3.107 E.38855
; WIPE_START
M204 S3000
G1 X211.39 Y98.722 E-.06817
G1 X211.549 Y98.437 E-.06192
G1 X211.681 Y98.139 E-.06186
G1 X211.782 Y97.83 E-.06182
G1 X211.849 Y97.511 E-.06189
G1 X211.883 Y97.187 E-.06186
G1 X211.883 Y97.174 E-.00248
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.641 Y99.267 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.822 Y99.593 E.01262
G2 X208.926 Y92.319 I3.947 J-2.568 E.65386
G2 X208.041 Y92.373 I-.051 J6.449 E.03006
G2 X204.575 Y99.166 I.729 J4.652 E.30084
G1 X204.609 Y99.217 E.00208
M204 S10000
G1 X204.289 Y99.471 F36000
G1 F1473.913
M204 S3000
G1 X204.48 Y99.815 E.01334
G2 X208.937 Y91.912 I4.288 J-2.79 E.71047
G2 X207.977 Y91.971 I-.052 J7.015 E.03259
G2 X204.212 Y99.351 I.792 J5.055 E.32684
G1 X204.257 Y99.42 E.0028
M204 S250
G1 X203.946 Y99.669 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X203.999 Y99.783 E.00396
G2 X208.947 Y91.52 I4.768 J-2.758 E.71771
G2 X207.916 Y91.583 I-.053 J7.559 E.03243
G2 X203.861 Y99.529 I.852 J5.442 E.32598
G1 X203.915 Y99.617 E.00323
; WIPE_START
M204 S3000
G1 X203.999 Y99.783 E-.03536
G1 X204.32 Y100.263 E-.10964
G1 X204.683 Y100.711 E-.10955
G1 X205.091 Y101.119 E-.10963
G1 X205.156 Y101.171 E-.01582
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.989 Y99.07 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436008
G1 F1526.377
M204 S3000
G1 X205.049 Y99.177 E.00401
G2 X204.468 Y97.019 I3.727 J-2.161 E.81095
G1 X204.512 Y97.629 E.01998
G2 X204.844 Y98.776 I4.265 J-.613 E.03916
G1 X204.963 Y99.016 E.00875
; OBJECT_ID: 11
; WIPE_START
G1 X205.049 Y99.177 E-.03471
G1 X205.288 Y99.553 E-.08466
G1 X205.432 Y99.741 E-.04488
G1 X205.73 Y100.072 E-.08477
G1 X206.065 Y100.374 E-.08562
G1 X206.258 Y100.514 E-.04536
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.87 Y98.601 Z4.6 F36000
G1 X183.876 Y94.718 Z4.6
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.844 Y94.779 E.00234
G2 X187.759 Y92.902 I3.491 J2.26 E.72979
G2 X187.201 Y92.883 I-.435 J4.431 E.0189
G2 X184.099 Y94.427 I.134 J4.156 E.121
G1 X183.913 Y94.67 E.01036
M204 S10000
G1 X184.195 Y94.986 F36000
G1 F1473.913
M204 S3000
G1 X183.985 Y95.337 E.01384
G2 X183.607 Y96.536 I3.351 J1.714 E.04272
G2 X186.849 Y100.76 I3.717 J.504 E.2004
G2 X191.041 Y97.543 I.467 J-3.731 E.19835
G2 X187.212 Y93.29 I-3.717 J-.504 E.22034
G2 X184.292 Y94.837 I.123 J3.762 E.11578
G1 X184.228 Y94.936 E.00402
M204 S250
G1 X184.522 Y95.187 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.513 Y95.213 E.00087
G2 X187.676 Y93.698 I2.82 J1.826 E.54608
G2 X187.222 Y93.682 I-.351 J3.58 E.01423
G2 X184.719 Y94.929 I.11 J3.357 E.09045
G1 X184.559 Y95.14 E.00829
; WIPE_START
M204 S3000
G1 X184.513 Y95.213 E-.0165
G1 X184.255 Y95.673 E-.10011
G1 X184.129 Y96.001 E-.06681
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.965 Y97.019 E-.06296
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.474 Y92.319 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.585 Y92.373 I-.051 J6.468 E.03016
G2 X187.534 Y92.321 I.731 J4.667 E.97244
M204 S10000
G1 X187.488 Y91.912 F36000
G1 F1473.913
M204 S3000
G1 X187.484 Y91.912 E.00011
G2 X186.522 Y91.971 I-.052 J7.037 E.03267
G2 X187.86 Y91.938 I.794 J5.069 E1.04572
G1 X187.547 Y91.916 E.01062
M204 S250
G1 X187.512 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.495 Y91.52 E.00056
G2 X186.46 Y91.583 I-.053 J7.581 E.03252
G2 X187.901 Y91.548 I.854 J5.456 E1.04269
G1 X187.572 Y91.525 E.01035
; WIPE_START
M204 S3000
G1 X187.495 Y91.52 E-.01481
G1 X187.035 Y91.523 E-.08725
G1 X186.46 Y91.583 E-.10989
G1 X186.176 Y91.636 E-.05495
G1 X185.617 Y91.786 E-.10982
G1 X185.601 Y91.792 E-.00328
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.515 Y92.607 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200577
G1 F3805.727
M204 S3000
G1 X187.324 Y92.597 E.00251
G1 X186.86 Y92.622 E.00609
G1 X186.401 Y92.694 E.00609
G1 X185.952 Y92.815 E.00609
G1 X185.519 Y92.981 E.00607
G1 X185.306 Y93.082 E.0031
G1 X184.903 Y93.315 E.0061
G1 X184.529 Y93.587 E.00607
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.00609
G1 X183.6 Y94.618 E.00607
G1 X183.367 Y95.021 E.0061
G1 X183.265 Y95.235 E.00311
G1 X183.1 Y95.667 E.00606
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.0061
G1 X182.882 Y97.037 E.00607
G1 X182.907 Y97.503 E.00612
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.0061
G1 X183.178 Y98.633 E.0031
G1 X183.367 Y99.056 E.00607
G1 X183.599 Y99.458 E.00609
G1 X183.872 Y99.835 E.0061
G1 X184.184 Y100.18 E.0061
G1 X184.529 Y100.491 E.00609
G1 X184.905 Y100.765 E.0061
G1 X185.308 Y100.997 E.00609
G1 X185.73 Y101.185 E.00607
G1 X186.173 Y101.329 E.0061
G1 X186.403 Y101.384 E.0031
G1 X186.86 Y101.457 E.00607
G1 X187.324 Y101.481 E.00609
G1 X187.789 Y101.457 E.00609
G1 X188.246 Y101.384 E.00607
G1 X188.695 Y101.264 E.0061
G1 X188.918 Y101.185 E.0031
G1 X189.341 Y100.997 E.00607
G1 X189.744 Y100.764 E.00609
G1 X190.12 Y100.491 E.0061
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.00609
G1 X191.05 Y99.458 E.0061
G1 X191.282 Y99.056 E.00609
G1 X191.47 Y98.633 E.00607
G1 X191.614 Y98.191 E.00609
G1 X191.67 Y97.961 E.0031
G1 X191.742 Y97.503 E.00607
G1 X191.766 Y97.039 E.00609
G1 X191.742 Y96.575 E.00609
G1 X191.67 Y96.118 E.00607
G1 X191.614 Y95.888 E.0031
G1 X191.47 Y95.446 E.00609
G1 X191.282 Y95.023 E.00607
G1 X191.05 Y94.62 E.00609
G1 X190.776 Y94.243 E.0061
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.0061
G1 X189.744 Y93.314 E.00609
G1 X189.341 Y93.081 E.00609
G1 X188.918 Y92.893 E.00607
G1 X188.476 Y92.749 E.00609
G1 X188.246 Y92.694 E.0031
G1 X187.789 Y92.622 E.00607
G1 X187.575 Y92.61 E.0028
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.04779
G1 X186.86 Y92.622 E-.08833
G1 X186.401 Y92.694 E-.08834
G1 X185.952 Y92.815 E-.08833
G1 X185.621 Y92.941 E-.06722
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X177.991 Y93.137 Z4.6 F36000
G1 X163.219 Y93.517 Z4.6
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.067 Y93.629 E.0064
G2 X169.812 Y95.144 I2.774 J3.426 E.66848
G2 X165.71 Y92.649 I-3.972 J1.912 E.17187
G2 X163.44 Y93.358 I.131 J4.406 E.08152
G1 X163.267 Y93.482 E.00718
M204 S10000
G1 X163.458 Y93.846 F36000
G1 F1473.913
M204 S3000
G1 X163.326 Y93.951 E.00567
G2 X166.259 Y93.075 I2.524 J3.105 E.74473
G2 X165.721 Y93.056 I-.418 J4.26 E.01825
G2 X163.664 Y93.704 I.13 J3.999 E.07389
G1 X163.507 Y93.812 E.00646
M204 S250
G1 X163.688 Y94.163 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.573 Y94.255 E.00461
G2 X166.218 Y93.465 I2.276 J2.798 E.62186
G2 X165.731 Y93.448 I-.377 J3.847 E.01529
G2 X163.878 Y94.033 I.119 J3.605 E.06169
G1 X163.737 Y94.129 E.00534
; WIPE_START
M204 S3000
G1 X163.573 Y94.255 E-.0393
G1 X163.288 Y94.502 E-.07174
G1 X163.035 Y94.783 E-.07183
G1 X162.813 Y95.089 E-.07178
G1 X162.624 Y95.416 E-.0718
G1 X162.509 Y95.674 E-.05355
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.483 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X165.99 Y92.319 I1.692 J-4.427 E.5572
G2 X165.099 Y92.373 I-.051 J6.492 E.03025
G2 X164.085 Y101.461 I.733 J4.682 E.4185
M204 S10000
G1 X163.984 Y101.856 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.00046
G2 X166.001 Y91.912 I1.837 J-4.808 E.60514
G2 X165.035 Y91.971 I-.052 J7.056 E.03278
G2 X163.502 Y101.645 I.796 J5.085 E.4384
G1 X163.929 Y101.831 E.01576
M204 S250
G1 X163.824 Y102.213 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.23 E.00107
G2 X166.011 Y91.52 I1.977 J-5.174 E.6033
G2 X164.974 Y91.584 I-.053 J7.604 E.03261
G2 X163.324 Y101.995 I.857 J5.472 E.43703
G1 X163.769 Y102.189 E.01525
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.23 E-.01784
G1 X164.129 Y102.324 E-.05513
M73 P72 R13
G1 X164.407 Y102.406 E-.05512
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.717 Y102.587 E-.03153
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.933 Y106.085 Z4.6 F36000
G1 X47.34 Y163.613 Z4.6
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.612 E.00153
G2 X47.289 Y154.319 I-.251 J-4.644 E.48085
G2 X46.414 Y154.372 I-.05 J6.373 E.02969
G2 X46.898 Y163.613 I.72 J4.595 E.46219
G1 X47.28 Y163.613 E.0129
M204 S10000
G1 X47.34 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00225
G2 X47.299 Y153.912 I-.273 J-5.051 E.52301
G2 X46.35 Y153.97 I-.051 J6.937 E.03222
G2 X46.877 Y164.019 I.783 J4.998 E.50265
G1 X47.28 Y164.019 E.01363
M204 S250
G1 X47.34 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00273
G2 X47.31 Y153.52 I-.295 J-5.443 E.52208
G2 X46.289 Y153.582 I-.053 J7.48 E.03209
G2 X46.857 Y164.411 I.843 J5.385 E.5017
G1 X47.28 Y164.411 E.01327
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.02794
G1 X47.712 Y164.389 E-.05427
G1 X48.275 Y164.299 E-.1084
G1 X48.826 Y164.152 E-.1084
G1 X49.224 Y163.999 E-.08099
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.236 Y162.723 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X48.511 Y163.044 I-1.893 J-3.29 E.02691
G1 X43.067 Y157.601 E.2606
G2 X42.93 Y158.113 I2.368 J.909 E.01799
G1 X50.366 Y156.12 E.2606
G2 X49.988 Y155.742 I-5.902 J5.523 E.0181
G1 X47.994 Y163.184 E.2608
G3 X47.004 Y163.264 I-.899 J-4.957 E.03369
G1 X42.844 Y159.105 E.19912
G2 X42.865 Y159.394 I1.389 J.044 E.00985
G1 X51.059 Y157.199 E.28712
G2 X50.932 Y156.938 I-1.306 J.47 E.00985
G1 X49.41 Y162.618 E.19905
G1 X49.653 Y162.46 E.00981
G1 X43.649 Y156.455 E.28745
G1 X43.491 Y156.698 E.00981
G1 X49.169 Y155.177 E.19898
G1 X48.911 Y155.045 E.00981
G1 X46.714 Y163.243 E.28728
G3 X45.528 Y162.952 I1.244 J-7.645 E.04139
G1 X47.736 Y154.71 E.28884
G3 X48.722 Y154.97 I-.614 J4.322 E.03458
; WIPE_START
G1 X47.736 Y154.71 E-.19364
G1 X47.482 Y155.657 E-.18636
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X51.141 Y157.385 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X51.4 Y158.372 I-13.179 J3.983 E.03454
G1 X43.156 Y160.581 E.2889
G2 X43.469 Y161.2 I3.103 J-1.178 E.02352
G1 X45.078 Y155.194 E.21046
G3 X45.597 Y154.95 I1.998 J3.573 E.01945
G1 X51.159 Y160.511 E.2662
G3 X50.915 Y161.03 I-3.817 J-1.473 E.01944
G1 X44.908 Y162.64 E.21048
G3 X44.435 Y162.312 I1.323 J-2.418 E.01952
G1 X46.47 Y154.716 E.26619
G3 X47.043 Y154.668 I.529 J2.886 E.01949
G1 X51.439 Y159.064 E.21043
G3 X51.392 Y159.638 I-2.754 J.064 E.01952
G1 X43.802 Y161.672 E.26597
G2 X44.284 Y162.176 I2.558 J-1.959 E.02364
; WIPE_START
G1 X43.802 Y161.672 E-.13245
G1 X45.061 Y161.335 E-.24755
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.813 Y162.334 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X50.531 Y161.61 I-2.719 J-3.417 E.03458
G1 X44.498 Y155.578 E.28878
G2 X43.775 Y156.296 I2.691 J3.434 E.03458
; OBJECT_ID: 14
; WIPE_START
G1 X44.498 Y155.578 E-.19364
G1 X45.192 Y156.271 E-.18636
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.563 Y156.035 Z4.6 F36000
G1 X26.622 Y155.697 Z4.6
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.318 Y155.635 E.0105
G2 X25.683 Y155.593 I-.543 J3.365 E.02156
G1 X25.436 Y155.608 E.00838
G2 X26.68 Y155.714 I.339 J3.391 E.68239
M204 S10000
G1 X26.557 Y156.103 F36000
G1 F1473.913
M204 S3000
G1 X26.409 Y156.063 E.00516
G2 X25.937 Y156.001 I-.624 J2.936 E.01616
G2 X25.476 Y156.014 I-.143 J3.292 E.01561
G2 X26.713 Y156.144 I.31 J2.986 E.596
G1 X26.615 Y156.118 E.00345
M204 S250
G1 X26.455 Y156.481 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00413
G2 X25.92 Y156.393 I-.543 J2.553 E.01292
G2 X25.514 Y156.404 I-.127 J2.901 E.01274
G2 X26.592 Y156.518 I.271 J2.596 E.47988
G1 X26.513 Y156.497 E.00255
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.03645
G1 X25.92 Y156.393 E-.0782
G1 X25.514 Y156.404 E-.07712
G1 X25.11 Y156.479 E-.07813
G1 X24.85 Y156.563 E-.0519
G1 X24.6 Y156.674 E-.05191
G1 X24.572 Y156.691 E-.00628
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.933 Y154.319 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.052 Y154.372 I-.05 J6.414 E.0299
G2 X25.993 Y154.321 I.725 J4.628 E.9643
M204 S10000
G1 X25.952 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.944 Y153.912 E.00025
G2 X24.989 Y153.97 I-.052 J6.98 E.03243
G2 X26.317 Y153.938 I.788 J5.03 E1.03774
G1 X26.011 Y153.916 E.01038
M204 S250
G1 X25.976 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.954 Y153.52 E.00069
G2 X24.927 Y153.583 I-.053 J7.529 E.03229
G2 X26.358 Y153.548 I.848 J5.417 E1.03523
G1 X26.036 Y153.525 E.01012
; WIPE_START
M204 S3000
G1 X25.954 Y153.52 E-.0156
G1 X25.498 Y153.523 E-.08663
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10906
G1 X24.068 Y153.799 E-.05959
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.462 Y155.307 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X26.971 Y155.435 I-1.043 J5.231 E.01779
G1 X27.86 Y155.197 E.03116
G1 X27.563 Y155.046 E.01129
G1 X27.41 Y155.617 E.02004
G3 X28.26 Y156.178 I-3.147 J5.697 E.03448
M204 S10000
G1 X28.608 Y156.526 F36000
G1 F1473.913
M204 S3000
G3 X29.168 Y157.375 I-5.407 J4.178 E.03448
G1 X29.735 Y157.223 E.01985
G2 X29.588 Y156.926 I-1.49 J.548 E.01126
G1 X29.35 Y157.814 E.03113
G3 X29.478 Y158.324 I-5.088 J1.549 E.01779
; WIPE_START
G1 X29.35 Y157.814 E-.09982
G1 X29.588 Y156.926 E-.17477
G1 X29.735 Y157.223 E-.06309
G1 X29.52 Y157.281 E-.04233
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.644 Y161.432 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X28.279 Y161.81 I-1.616 J-1.193 E.01781
G1 X28.041 Y162.699 E.03115
G1 X28.321 Y162.517 E.01129
G1 X27.904 Y162.099 E.01998
G3 X26.995 Y162.556 I-2.221 J-3.29 E.03452
M204 S10000
G1 X26.516 Y162.684 F36000
G1 F1473.913
M204 S3000
G3 X25.501 Y162.743 I-.737 J-3.899 E.03452
G1 X25.348 Y163.314 E.02001
G2 X25.68 Y163.331 I.27 J-2.106 E.01129
G1 X25.03 Y162.68 E.03113
G3 X24.525 Y162.536 I1.211 J-5.208 E.01779
; WIPE_START
G1 X25.03 Y162.68 E-.09984
G1 X25.68 Y163.331 E-.17474
G1 X25.348 Y163.314 E-.06332
G1 X25.405 Y163.1 E-.04211
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.249 Y160.26 Z4.6 F36000
G1 Z4.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.105 Y159.755 I5.068 J-1.718 E.01779
G1 X21.455 Y159.105 E.03113
G2 X21.477 Y159.436 I1.588 J.061 E.01126
G1 X22.044 Y159.284 E.01989
G3 X22.107 Y158.269 I3.339 J-.304 E.03455
M204 S10000
G1 X22.231 Y157.793 F36000
G1 F1473.913
M204 S3000
G3 X22.686 Y156.881 I6.587 J2.713 E.0345
G1 X22.268 Y156.464 E.01997
G1 X22.087 Y156.744 E.01129
G1 X22.982 Y156.504 E.03139
G3 X23.352 Y156.14 I1.913 J1.576 E.01759
M204 S10000
G1 X22.395 Y156.305 F36000
G1 F1473.913
M204 S3000
G3 X23.117 Y155.586 I4.716 J4.01 E.03453
G1 X23.511 Y156.013 E.01968
G1 X23.733 Y155.184 E.02905
G3 X24.216 Y154.958 I1.318 J2.187 E.01809
G1 X24.673 Y155.415 E.02187
G3 X24.955 Y155.343 I.413 J1.027 E.00987
G1 X25.123 Y154.715 E.022
G3 X25.654 Y154.669 I.501 J2.671 E.01807
G1 X26.261 Y155.275 E.02904
G1 X26.389 Y154.711 E.01959
G3 X27.374 Y154.971 I-.621 J4.347 E.03457
M204 S10000
G1 X28.037 Y155.298 F36000
G1 F1473.913
M204 S3000
G3 X28.641 Y155.74 I-1.801 J3.099 E.0254
G1 X28.471 Y156.374 E.02222
G2 X28.411 Y156.314 I-.317 J.257 E.0029
G1 X29.047 Y156.143 E.02229
G3 X29.486 Y156.749 I-4.094 J3.431 E.02535
M204 S10000
G1 X29.818 Y157.409 F36000
G1 F1473.913
M204 S3000
G3 X30.076 Y158.396 I-13.948 J4.184 E.03454
G1 X29.51 Y158.525 E.01966
G1 X30.116 Y159.131 E.02901
G3 X30.07 Y159.662 I-2.553 J.048 E.01809
G1 X29.444 Y159.83 E.02193
G3 X29.37 Y160.112 I-1.235 J-.173 E.0099
G1 X29.827 Y160.569 E.02188
G3 X29.602 Y161.052 I-3.549 J-1.362 E.01805
G1 X28.772 Y161.274 E.02909
G1 X29.198 Y161.667 E.01961
G3 X28.48 Y162.39 I-3.452 J-2.708 E.03457
M204 S10000
G1 X27.865 Y162.8 F36000
G1 F1473.913
M204 S3000
G3 X27.178 Y163.101 I-1.723 J-3.006 E.02544
G1 X26.714 Y162.637 E.02222
G1 X26.8 Y162.614 E.00301
G1 X26.63 Y163.248 E.02222
G3 X25.884 Y163.331 I-.873 J-4.469 E.02543
M204 S10000
G1 X25.146 Y163.283 F36000
G1 F1473.913
M204 S3000
G3 X24.163 Y163.016 I.652 J-4.34 E.03457
G1 X24.335 Y162.463 E.01959
G1 X23.508 Y162.685 E.02897
G3 X23.071 Y162.374 I1.259 J-2.236 E.01819
G1 X23.238 Y161.752 E.02179
G3 X23.027 Y161.549 I.913 J-1.155 E.00991
G1 X22.406 Y161.716 E.02179
G3 X22.1 Y161.278 I1.928 J-1.672 E.01809
G1 X22.322 Y160.451 E.02901
G1 X21.767 Y160.623 E.01966
G3 X21.498 Y159.639 I13.93 J-4.341 E.03454
M204 S10000
G1 X21.455 Y158.901 F36000
G1 F1473.913
M204 S3000
G3 X21.537 Y158.156 I4.553 J.128 E.02543
G1 X22.168 Y157.987 E.02211
G2 X22.146 Y158.069 I.341 J.134 E.00291
G1 X21.684 Y157.607 E.02212
G3 X21.984 Y156.919 I4.156 J1.399 E.02543
; CHANGE_LAYER
; Z_HEIGHT: 4.4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X21.684 Y157.607 E-.14256
G1 X22.146 Y158.069 E-.12417
G1 X22.168 Y157.987 E-.01631
G1 X21.675 Y158.119 E-.09696
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L22
M991 S0 P21 ;notify layer change


M204 S10000
G17
G3 Z4.6 I1.217 J0 P1  F36000
; object ids of layer 22 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer22 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.124 Y93.517
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.073 Y93.534 E.00181
G2 X230.586 Y93.372 I1.138 J3.477 E.72623
G2 X230.072 Y93.356 I-.384 J3.924 E.0174
G2 X229.443 Y93.434 I.139 J3.656 E.02149
G1 X229.182 Y93.502 E.00913
M204 S10000
G1 X229.229 Y93.91 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.921 E.00109
G2 X230.543 Y93.777 I1.011 J3.09 E.64542
G2 X230.091 Y93.762 I-.341 J3.483 E.01533
G2 X229.528 Y93.833 I.12 J3.249 E.01923
G1 X229.287 Y93.895 E.0084
M204 S250
G1 X229.331 Y94.288 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.321 Y94.295 E.00038
G2 X230.353 Y94.155 I.893 J2.716 E.5305
G2 X230.108 Y94.154 I-.136 J2.324 E.00766
G2 X229.609 Y94.217 I.105 J2.858 E.0158
G1 X229.389 Y94.274 E.00714
; WIPE_START
M204 S3000
G1 X229.321 Y94.295 E-.01357
G1 X229.04 Y94.399 E-.05684
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05688
G1 X228.181 Y94.989 E-.08527
G1 X227.888 Y95.332 E-.08557
G1 X227.817 Y95.442 E-.02497
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.627 Y92.592 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.293 Y92.722 E.01212
G2 X231.738 Y101.449 I1.91 J4.289 E.48565
G2 X230.36 Y92.319 I-1.541 J-4.436 E.44075
G2 X228.752 Y92.546 I-.157 J4.693 E.05525
G1 X228.683 Y92.572 E.00248
M204 S10000
G1 X228.481 Y92.213 F36000
G1 F1473.913
M204 S3000
G1 X228.126 Y92.347 E.01285
G2 X230.371 Y91.912 I2.068 J4.665 E1.00721
G2 X229.405 Y91.97 I-.064 J6.956 E.03279
G2 X228.625 Y92.156 I.79 J5.041 E.02714
G1 X228.537 Y92.191 E.00321
M204 S250
G1 X228.341 Y91.847 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.967 Y91.988 E.01254
G2 X230.381 Y91.52 I2.227 J5.023 E1.00476
G2 X229.343 Y91.583 I-.065 J7.504 E.03263
G2 X228.504 Y91.783 I.85 J5.429 E.02707
G1 X228.397 Y91.825 E.00362
; WIPE_START
M204 S3000
G1 X227.967 Y91.988 E-.0874
G1 X227.455 Y92.252 E-.10934
M73 P73 R13
G1 X226.973 Y92.565 E-.1093
G1 X226.67 Y92.81 E-.07396
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.805 Y93.079 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672897
G1 F952.416
M204 S3000
G1 X228.706 Y93.111 E.00547
G2 X226.025 Y97.003 I1.497 J3.9 E.26314
G1 X226.048 Y97.449 E.02335
G1 X226.115 Y97.872 E.02247
G1 X226.227 Y98.295 E.02289
G1 X226.311 Y98.529 E.01304
G2 X229.114 Y92.978 I3.892 J-1.518 E1.00769
G1 X228.862 Y93.06 E.01385
; OBJECT_ID: 12
; WIPE_START
G1 X228.706 Y93.111 E-.03124
G1 X228.306 Y93.289 E-.08315
G1 X227.935 Y93.503 E-.08149
G1 X227.741 Y93.636 E-.04469
G1 X227.408 Y93.907 E-.08149
G1 X227.192 Y94.122 E-.05795
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.983 Y96.63 Z4.8 F36000
G1 X211.821 Y99.47 Z4.8
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.945 Y99.326 E.00642
G2 X209.186 Y93.137 I-3.159 J-2.301 E.27754
G2 X208.639 Y93.119 I-.41 J4.191 E.01856
G2 X211.687 Y99.644 I.147 J3.906 E.52128
G1 X211.785 Y99.517 E.00543
M204 S10000
G1 X211.505 Y99.214 F36000
G1 F1473.913
M204 S3000
G1 X211.615 Y99.086 E.0057
G2 X209.144 Y93.542 I-2.83 J-2.062 E.24864
M73 P73 R12
G2 X208.657 Y93.526 I-.367 J3.749 E.01649
G2 X211.384 Y99.371 I.128 J3.499 E.4671
G1 X211.469 Y99.261 E.0047
M204 S250
G1 X211.201 Y98.967 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.298 Y98.856 E.00463
G2 X209.103 Y93.932 I-2.513 J-1.831 E.20454
G2 X208.675 Y93.917 I-.326 J3.32 E.01343
G2 X211.092 Y99.109 I.11 J3.107 E.38434
G1 X211.164 Y99.015 E.00371
; WIPE_START
M204 S3000
G1 X211.298 Y98.856 E-.03945
G1 X211.471 Y98.58 E-.06191
G1 X211.619 Y98.29 E-.06185
G1 X211.715 Y98.042 E-.05043
G1 X211.82 Y97.671 E-.07325
G1 X211.883 Y97.187 E-.09273
G1 X211.883 Y97.185 E-.00037
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.633 Y99.253 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.829 Y99.589 E.01315
G2 X209.358 Y101.697 I3.949 J-2.564 E.17825
G2 X208.935 Y92.319 I-.586 J-4.672 E.47533
G2 X204.583 Y99.162 I-.157 J4.706 E.33078
G1 X204.604 Y99.201 E.00149
M204 S10000
G1 X204.281 Y99.457 F36000
G1 F1473.913
M204 S3000
G1 X204.481 Y99.815 E.01388
G2 X208.946 Y91.912 I4.288 J-2.79 E.71011
G2 X207.977 Y91.971 I-.064 J6.98 E.03288
G2 X204.213 Y99.351 I.792 J5.054 E.32682
G1 X204.249 Y99.406 E.00224
M204 S250
G1 X203.942 Y99.653 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.152 Y100.029 E.01351
G2 X208.956 Y91.52 I4.616 J-3.004 E.70827
G2 X207.916 Y91.583 I-.065 J7.523 E.0327
G2 X203.863 Y99.529 I.852 J5.441 E.32595
G1 X203.909 Y99.602 E.00271
; WIPE_START
M204 S3000
G1 X204.152 Y100.029 E-.09324
G1 X204.496 Y100.492 E-.10962
G1 X204.882 Y100.92 E-.10956
G1 X205.091 Y101.119 E-.05482
G1 X205.143 Y101.161 E-.01276
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.938 Y98.981 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436016
G1 F1526.347
M204 S3000
G1 X205.291 Y99.558 E.02209
G1 X205.73 Y100.072 E.02211
G1 X206.244 Y100.511 E.0221
G1 X206.821 Y100.865 E.02211
G1 X207.384 Y101.102 E.01997
G2 X204.468 Y97.019 I1.393 J-4.078 E.70997
G1 X204.474 Y97.255 E.00771
G1 X204.521 Y97.699 E.01458
G1 X204.679 Y98.356 E.0221
G1 X204.915 Y98.926 E.02015
; OBJECT_ID: 11
; WIPE_START
G1 X205.291 Y99.558 E-.13968
G1 X205.73 Y100.072 E-.12852
G1 X206.177 Y100.454 E-.1118
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.785 Y98.554 Z4.8 F36000
G1 X183.874 Y94.722 Z4.8
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.843 Y94.778 E.00218
G2 X187.759 Y92.902 I3.49 J2.261 E.72977
G2 X187.177 Y92.884 I-.436 J4.461 E.01972
G2 X184.098 Y94.427 I.156 J4.156 E.12021
G1 X183.91 Y94.674 E.01051
M204 S10000
G1 X184.203 Y94.961 F36000
G1 F1473.913
M204 S3000
G1 X184.184 Y95 E.00147
G2 X187.717 Y93.307 I3.149 J2.039 E.65833
G2 X187.196 Y93.29 I-.393 J4.015 E.01765
G2 X184.414 Y94.683 I.137 J3.749 E.10858
G1 X184.239 Y94.913 E.00979
M204 S250
G1 X184.52 Y95.191 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.513 Y95.213 E.00073
G2 X187.676 Y93.698 I2.82 J1.826 E.54608
G2 X187.214 Y93.682 I-.352 J3.59 E.0145
G2 X184.718 Y94.929 I.119 J3.357 E.09019
G1 X184.556 Y95.143 E.00843
; WIPE_START
M204 S3000
G1 X184.513 Y95.213 E-.01564
G1 X184.33 Y95.514 E-.06677
G1 X184.187 Y95.835 E-.06682
G1 X184.038 Y96.341 E-.10019
G1 X183.983 Y96.688 E-.06681
G1 X183.965 Y97.023 E-.06377
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.482 Y92.319 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.831 Y92.341 I-.157 J5.074 E.02209
G2 X187.542 Y92.321 I.483 J4.698 E.9804
M204 S10000
G1 X187.493 Y91.912 F36000
G1 F1473.913
M204 S3000
G2 X186.522 Y91.971 I-.064 J7.003 E.03296
G2 X187.553 Y91.914 I.794 J5.069 E1.05618
M204 S250
G1 X187.518 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.503 Y91.52 E.00045
G2 X186.46 Y91.583 I-.065 J7.545 E.03279
G2 X187.901 Y91.548 I.855 J5.456 E1.04269
G1 X187.577 Y91.525 E.01019
; WIPE_START
M204 S3000
G1 X187.503 Y91.52 E-.01415
G1 X187.035 Y91.523 E-.08887
G1 X186.46 Y91.583 E-.10989
G1 X186.176 Y91.636 E-.05495
G1 X185.617 Y91.786 E-.10982
G1 X185.606 Y91.79 E-.00231
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.549 Y92.603 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200628
G1 F3804.505
M204 S3000
G1 X187.322 Y92.597 E.00298
G2 X182.882 Y97.039 I.001 J4.441 E.09148
G1 X182.907 Y97.504 E.0061
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.0061
G1 X183.178 Y98.633 E.00311
G1 X183.366 Y99.056 E.00607
G1 X183.599 Y99.459 E.0061
G1 X183.872 Y99.835 E.0061
G1 X184.134 Y100.128 E.00516
G2 X187.609 Y92.606 I3.189 J-3.09 E.22586
; OBJECT_ID: 10
; WIPE_START
G1 X187.322 Y92.597 E-.0545
G1 X186.867 Y92.621 E-.08667
G1 X186.403 Y92.694 E-.08923
G1 X186.173 Y92.749 E-.04497
G1 X185.732 Y92.892 E-.08797
G1 X185.652 Y92.928 E-.01667
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.022 Y93.129 Z4.8 F36000
G1 X163.215 Y93.52 Z4.8
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.071 Y93.635 E.00623
G2 X166.301 Y92.67 I2.781 J3.421 E.82051
G2 X165.705 Y92.649 I-.461 J4.703 E.02023
G2 X163.443 Y93.363 I.147 J4.406 E.08129
G1 X163.264 Y93.486 E.00734
M204 S10000
G1 X163.454 Y93.849 F36000
G1 F1473.913
M204 S3000
G1 X163.326 Y93.95 E.00551
G2 X166.259 Y93.075 I2.524 J3.104 E.74462
G2 X165.715 Y93.056 I-.418 J4.265 E.01842
G2 X163.664 Y93.704 I.135 J3.999 E.07372
G1 X163.503 Y93.815 E.00662
M204 S250
G1 X163.684 Y94.166 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.573 Y94.255 E.00447
G2 X166.218 Y93.465 I2.276 J2.798 E.62181
G2 X165.726 Y93.448 I-.378 J3.852 E.01545
G2 X163.878 Y94.033 I.124 J3.605 E.06153
G1 X163.733 Y94.132 E.00549
; WIPE_START
M204 S3000
G1 X163.573 Y94.255 E-.03844
G1 X163.288 Y94.502 E-.07174
G1 X163.035 Y94.783 E-.0718
G1 X162.813 Y95.089 E-.07176
G1 X162.624 Y95.416 E-.07182
G1 X162.507 Y95.678 E-.05444
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.14 Y101.484 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X165.999 Y92.319 I1.689 J-4.428 E.55674
G2 X165.345 Y92.341 I-.157 J5.089 E.02217
G2 X164.085 Y101.462 I.485 J4.715 E.42707
M204 S10000
G1 X163.971 Y101.844 F36000
G1 F1473.913
M204 S3000
G1 X164.25 Y101.949 E.01013
G2 X166.01 Y91.912 I1.59 J-4.894 E.5962
G2 X160.978 Y98.74 I-.169 J5.143 E.33745
G2 X163.747 Y101.756 I4.862 J-1.685 E.14253
G1 X163.915 Y101.822 E.00608
M204 S250
G1 X163.83 Y102.209 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.128 Y102.326 E.01002
G2 X166.02 Y91.52 I1.703 J-5.27 E.59391
G2 X164.974 Y91.584 I-.065 J7.566 E.03288
G2 X163.586 Y102.118 I.857 J5.472 E.4461
G1 X163.774 Y102.188 E.00628
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.128 Y102.326 E-.07214
G1 X164.407 Y102.406 E-.05513
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.721 Y102.587 E-.03236
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.937 Y106.085 Z4.8 F36000
G1 X47.346 Y163.613 Z4.8
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.611 E.00133
G2 X47.715 Y163.582 I-.239 J-4.644 E.01122
G1 X47.869 Y163.562 E.00527
G2 X47.297 Y154.319 I-.734 J-4.594 E.46427
G2 X46.899 Y163.61 I-.151 J4.648 E.49124
G1 X47.286 Y163.612 E.0131
M204 S10000
G1 X47.346 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.017 E.00205
G2 X47.768 Y163.986 I-.26 J-5.051 E.0123
G1 X47.933 Y163.964 E.00563
G2 X47.308 Y153.912 I-.798 J-4.996 E.505
G2 X46.877 Y164.017 I-.161 J5.055 E.53413
G1 X47.286 Y164.019 E.01383
M204 S250
G1 X47.346 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00254
G2 X47.819 Y164.374 I-.28 J-5.442 E.01236
M73 P74 R12
G1 X47.994 Y164.351 E.00554
G2 X47.318 Y153.52 I-.86 J-5.383 E.50413
G2 X46.857 Y164.408 I-.171 J5.447 E.53304
G1 X47.286 Y164.411 E.01345
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.02679
G1 X47.819 Y164.374 E-.07491
G1 X47.994 Y164.351 E-.03355
G1 X48.275 Y164.299 E-.05423
G1 X48.826 Y164.152 E-.10839
G1 X49.23 Y163.997 E-.08214
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X44.904 Y162.638 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X44.316 Y162.209 I1.749 J-3.013 E.02469
G1 X46.315 Y154.749 E.26141
G2 X45.749 Y154.901 I.438 J2.769 E.01989
G1 X51.208 Y160.36 E.26132
G2 X51.359 Y159.793 I-2.616 J-1.005 E.01989
G1 X43.897 Y161.793 E.26149
G3 X43.47 Y161.203 I4.102 J-3.419 E.02466
; WIPE_START
G1 X43.897 Y161.793 E-.13834
G1 X45.126 Y161.464 E-.24166
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.053 Y157.643 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X42.897 Y158.268 I2.895 J1.057 E.02185
G1 X50.464 Y156.241 E.26517
G2 X49.868 Y155.645 I-3.335 J2.739 E.02856
G1 X47.84 Y163.212 E.26517
G2 X48.659 Y162.993 I-.633 J-4.001 E.02874
G1 X43.116 Y157.45 E.26534
G3 X43.384 Y156.873 I5.623 J2.265 E.02153
G1 X49.348 Y155.275 E.20898
G2 X48.779 Y154.992 I-2.644 J4.598 E.02153
G1 X46.572 Y163.228 E.28862
G2 X47.204 Y163.264 I.488 J-2.989 E.02147
G1 X42.844 Y158.905 E.20869
G2 X42.88 Y159.537 I3.025 J.144 E.02147
G1 X51.117 Y157.33 E.28863
G2 X50.832 Y156.764 I-2.832 J1.071 E.02147
G1 X49.237 Y162.72 E.20869
G2 X49.766 Y162.372 I-1.387 J-2.69 E.02147
G1 X43.737 Y156.343 E.28862
G3 X44.45 Y155.615 I3.555 J2.769 E.03458
; WIPE_START
G1 X43.737 Y156.343 E-.1937
G1 X44.43 Y157.036 E-.18631
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.515 Y154.712 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X47.242 Y154.667 I.586 J3.641 E.0247
G1 X51.439 Y158.864 E.20091
G2 X51.415 Y158.514 I-1.679 J-.061 E.0119
G1 X43.214 Y160.712 E.28738
G2 X43.369 Y161.027 I1.578 J-.577 E.0119
G1 X44.904 Y155.296 E.20081
G2 X44.611 Y155.49 I.898 J1.68 E.01192
G1 X50.62 Y161.5 E.28768
G2 X50.813 Y161.204 I-1.333 J-1.079 E.01196
G1 X45.08 Y162.74 E.2009
G2 X45.396 Y162.897 I1.27 J-2.165 E.01196
G1 X47.596 Y154.688 E.28768
G3 X48.589 Y154.919 I-.58 J4.736 E.03457
; OBJECT_ID: 14
; WIPE_START
G1 X47.596 Y154.688 E-.19368
G1 X47.342 Y155.635 E-.18632
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X39.71 Y155.657 Z4.8 F36000
G1 X26.616 Y155.696 Z4.8
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.319 Y155.631 E.0103
G2 X25.964 Y155.595 I-.522 J3.369 E.01207
G2 X25.662 Y155.594 I-.165 J2.858 E.01021
G2 X26.675 Y155.706 I.134 J3.406 E.69039
M204 S10000
G1 X26.531 Y156.093 F36000
G1 F1473.913
M204 S3000
G1 X26.255 Y156.034 E.00957
G2 X25.942 Y156.002 I-.459 J2.966 E.01064
G2 X25.681 Y156 I-.144 J2.483 E.00886
G2 X26.59 Y156.105 I.115 J3 E.60731
M204 S250
G1 X26.449 Y156.479 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.446 E.00394
G2 X25.922 Y156.393 I-.533 J2.553 E.01286
G2 X25.699 Y156.392 I-.124 J2.122 E.007
G2 X26.593 Y156.515 I.096 J2.606 E.48536
G1 X26.507 Y156.494 E.00275
; WIPE_START
M204 S3000
G1 X26.328 Y156.446 E-.03527
G1 X25.922 Y156.393 E-.07785
G1 X25.699 Y156.392 E-.04241
G1 X25.243 Y156.447 E-.08726
G1 X24.979 Y156.518 E-.05191
G1 X24.724 Y156.616 E-.05193
G1 X24.567 Y156.695 E-.03338
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.942 Y154.319 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.296 Y154.34 I-.156 J5.029 E.02191
G2 X26.002 Y154.321 I.479 J4.659 E.97225
M204 S10000
G1 X25.956 Y153.912 F36000
G1 F1473.913
M204 S3000
G1 X25.953 Y153.912 E.00012
G2 X24.989 Y153.97 I-.064 J6.944 E.03271
G2 X26.317 Y153.938 I.788 J5.03 E1.03775
G1 X26.016 Y153.916 E.01022
M204 S250
G1 X25.981 Y153.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.963 Y153.52 E.00058
G2 X30.942 Y157.138 I-.176 J5.477 E.87473
G2 X26.643 Y153.587 I-5.177 J1.89 E.18332
G1 X26.041 Y153.528 E.01895
; WIPE_START
M204 S3000
G1 X25.963 Y153.52 E-.01494
G1 X25.498 Y153.523 E-.08825
G1 X24.927 Y153.583 E-.10911
G1 X24.645 Y153.635 E-.05456
G1 X24.09 Y153.784 E-.10908
G1 X24.07 Y153.791 E-.00407
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.649 Y154.669 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X24.968 Y154.746 I.227 J5.029 E.02322
G1 X24.829 Y155.371 E.02166
G1 X24.366 Y154.908 E.02216
G2 X23.736 Y155.183 I1.626 J4.584 E.02328
M204 S10000
G1 X23.068 Y155.621 F36000
G1 F1473.913
M204 S3000
G2 X22.357 Y156.353 I4.788 J5.369 E.03456
G1 X22.767 Y156.763 E.01965
G1 X22.824 Y156.693 E.00306
G1 X21.984 Y156.918 E.02943
G2 X21.733 Y157.456 I6.063 J3.152 E.02012
G1 X22.191 Y157.914 E.0219
G1 X22.129 Y158.143 E.00804
G1 X21.504 Y158.311 E.0219
G2 X21.455 Y158.905 I6.852 J.873 E.02018
G1 X22.066 Y159.516 E.02925
G1 X22.056 Y159.427 E.00302
G1 X21.492 Y159.579 E.01979
G2 X21.743 Y160.567 I14.919 J-3.262 E.03454
M204 S10000
G1 X22.105 Y161.285 F36000
G1 F1473.913
M204 S3000
G2 X22.508 Y161.835 I2.819 J-1.643 E.02313
G1 X23.12 Y161.643 E.02171
G1 X22.951 Y162.277 E.02222
G2 X23.502 Y162.681 I2.198 J-2.423 E.02319
M204 S10000
G1 X24.218 Y163.043 F36000
G1 F1473.913
M204 S3000
G2 X25.207 Y163.294 I4.404 J-15.3 E.03453
G1 X25.357 Y162.732 E.01968
G1 X25.268 Y162.718 E.00307
G1 X25.88 Y163.331 E.02933
G2 X26.475 Y163.281 I-.279 J-6.901 E.02018
G1 X26.642 Y162.655 E.02194
G2 X26.871 Y162.594 I-.176 J-1.115 E.00802
G1 X27.329 Y163.052 E.02194
G2 X27.868 Y162.798 I-2.66 J-6.349 E.02018
G1 X28.092 Y161.961 E.02933
G1 X28.022 Y162.018 E.00307
G1 X28.433 Y162.429 E.01968
G2 X29.159 Y161.715 I-3.819 J-4.608 E.03453
M204 S10000
G1 X29.603 Y161.047 F36000
G1 F1473.913
M204 S3000
G2 X29.879 Y160.42 I-2.839 J-1.625 E.02321
G1 X29.415 Y159.956 E.02222
G1 X30.042 Y159.816 E.02176
G2 X30.116 Y159.134 I-4.741 J-.859 E.02324
M204 S10000
G1 X30.07 Y158.336 F36000
G1 F1473.913
M204 S3000
G2 X29.794 Y157.354 I-11.514 J2.705 E.03455
G1 X29.228 Y157.506 E.01983
G1 X29.264 Y157.587 E.00302
G1 X29.488 Y156.751 E.02929
G2 X29.142 Y156.264 I-2.49 J1.404 E.02026
G1 X28.515 Y156.432 E.02199
G1 X28.355 Y156.264 E.00787
G1 X28.521 Y155.643 E.02176
G2 X28.034 Y155.297 I-1.891 J2.144 E.02025
G1 X27.196 Y155.521 E.02936
G1 X27.279 Y155.561 E.00309
G1 X27.431 Y154.993 E.01989
G2 X26.449 Y154.721 I-1.662 J4.083 E.03456
M204 S10000
G1 X27.006 Y155.45 F36000
G1 F1473.913
M204 S3000
G2 X26.5 Y155.315 I-.896 J2.336 E.01775
G1 X25.853 Y154.668 E.03099
G3 X26.248 Y154.689 I-.147 J6.457 E.0134
G1 X26.095 Y155.259 E.01998
G2 X25.026 Y155.32 I-.256 J4.869 E.03633
M204 S10000
G1 X24.603 Y155.434 F36000
G1 F1473.913
M204 S3000
G2 X23.646 Y155.914 I1.325 J3.832 E.03637
G1 X23.233 Y155.502 E.01976
G3 X23.56 Y155.284 I1.198 J1.448 E.01332
G1 X23.324 Y156.164 E.03081
G2 X22.952 Y156.535 I3.327 J3.706 E.01779
; WIPE_START
G1 X23.324 Y156.164 E-.09983
G1 X23.56 Y155.284 E-.17295
G1 X23.233 Y155.502 E-.07462
G1 X23.354 Y155.623 E-.03261
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.101 Y159.716 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X22.237 Y160.223 I2.476 J-.392 E.0178
G1 X21.999 Y161.111 E.03113
G3 X21.826 Y160.753 I2.186 J-1.277 E.01347
G1 X22.39 Y160.602 E.01979
G2 X22.978 Y161.497 I4.284 J-2.172 E.03633
M204 S10000
G1 X23.288 Y161.807 F36000
G1 F1473.913
M204 S3000
G2 X24.183 Y162.396 I2.654 J-3.06 E.03637
G1 X24.031 Y162.963 E.01986
G3 X23.676 Y162.786 I1.071 J-2.601 E.01343
G1 X24.559 Y162.549 E.03095
G2 X25.067 Y162.686 I1.543 J-4.723 E.01779
; WIPE_START
G1 X24.559 Y162.549 E-.09983
G1 X23.676 Y162.786 E-.17373
G1 X24.031 Y162.963 E-.07532
G1 X24.074 Y162.804 E-.03112
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.251 Y161.833 Z4.8 F36000
G1 Z4.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X28.622 Y161.461 I-3.329 J-3.693 E.01779
G1 X29.504 Y161.225 E.03093
G3 X29.288 Y161.556 I-1.686 J-.864 E.01344
G1 X28.871 Y161.14 E.01995
G2 X29.352 Y160.182 I-3.351 J-2.282 E.03637
M204 S10000
G1 X29.465 Y159.759 F36000
G1 F1473.913
M204 S3000
G2 X29.526 Y158.69 I-4.734 J-.809 E.03633
G1 X30.091 Y158.539 E.01979
G3 X30.116 Y158.931 I-1.853 J.313 E.01332
G1 X29.47 Y158.285 E.03091
G2 X29.334 Y157.778 I-2.478 J.392 E.0178
; CHANGE_LAYER
; Z_HEIGHT: 4.6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X29.47 Y158.285 E-.09974
G1 X30.116 Y158.931 E-.17348
G1 X30.091 Y158.539 E-.07462
G1 X29.928 Y158.582 E-.03217
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L23
M991 S0 P22 ;notify layer change


M204 S10000
G17
G3 Z4.8 I1.217 J0 P1  F36000
; object ids of layer 23 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer23 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.122 Y93.518
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.073 Y93.534 E.00173
G2 X230.586 Y93.372 I1.137 J3.477 E.72624
G2 X230.068 Y93.356 I-.385 J3.935 E.01756
G2 X229.443 Y93.434 I.143 J3.656 E.02134
G1 X229.18 Y93.503 E.0092
M204 S10000
G1 X229.227 Y93.911 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.922 E.00102
G2 X230.373 Y93.764 I1.015 J3.089 E.65125
G2 X230.086 Y93.762 I-.157 J2.727 E.00972
G2 X229.528 Y93.833 I.128 J3.249 E.01909
G1 X229.285 Y93.896 E.00848
M204 S250
G1 X229.328 Y94.289 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.32 Y94.295 E.00031
G2 X230.353 Y94.155 I.893 J2.717 E.5305
G2 X230.104 Y94.154 I-.137 J2.365 E.00779
G2 X229.609 Y94.217 I.109 J2.857 E.01567
G1 X229.387 Y94.274 E.00721
; WIPE_START
M204 S3000
G1 X229.32 Y94.295 E-.01317
G1 X229.04 Y94.399 E-.05686
G1 X228.773 Y94.535 E-.05686
G1 X228.522 Y94.698 E-.05685
G1 X228.181 Y94.989 E-.08531
G1 X227.98 Y95.212 E-.05688
G1 X227.813 Y95.442 E-.05406
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.624 Y92.593 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.624 E.00371
G2 X230.369 Y92.319 I1.674 J4.387 E.93477
G2 X229.712 Y92.34 I-.164 J5.054 E.02225
G2 X228.987 Y92.473 I.481 J4.671 E.02497
G1 X228.681 Y92.574 E.01091
M204 S10000
G1 X228.498 Y92.206 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.245 E.00443
G2 X230.379 Y91.912 I1.822 J4.767 E1.01604
G2 X229.405 Y91.97 I-.075 J6.926 E.03308
G2 X228.882 Y92.081 I.79 J5.042 E.01809
G1 X228.555 Y92.188 E.01163
M204 S250
G1 X228.377 Y91.834 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.233 Y91.879 E.00475
G2 X230.39 Y91.52 I1.961 J5.133 E1.01358
G2 X229.343 Y91.583 I-.077 J7.472 E.03289
G2 X228.78 Y91.702 I.851 J5.429 E.01804
G1 X228.434 Y91.815 E.01142
; WIPE_START
M204 S3000
G1 X228.233 Y91.879 E-.04017
G1 X227.708 Y92.114 E-.10934
G1 X227.455 Y92.252 E-.05465
G1 X226.972 Y92.565 E-.10931
G1 X226.7 Y92.785 E-.06653
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.905 Y93.041 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672833
G1 F952.513
M204 S3000
G1 X228.505 Y93.196 E.02249
G2 X226.025 Y97.003 I1.7 J3.818 E.2516
G1 X226.075 Y97.657 E.03433
G1 X226.17 Y98.101 E.02379
G1 X226.386 Y98.711 E.03389
G1 X226.699 Y99.287 E.03435
G1 X227.098 Y99.807 E.03432
G1 X227.567 Y100.253 E.03393
G1 X227.935 Y100.52 E.02377
G1 X228.511 Y100.832 E.03432
G1 X229.122 Y101.047 E.03394
G1 X229.766 Y101.167 E.03431
G1 X230.421 Y101.184 E.03433
G1 X231.064 Y101.1 E.03392
G1 X231.693 Y100.915 E.03436
G1 X232.107 Y100.73 E.02375
G1 X232.659 Y100.392 E.03391
G1 X233.157 Y99.966 E.03434
G1 X233.583 Y99.467 E.03435
G1 X233.922 Y98.916 E.0339
G1 X234.174 Y98.31 E.03434
G1 X234.291 Y97.872 E.02377
G1 X234.375 Y97.23 E.03393
G1 X234.358 Y96.575 E.03433
G1 X234.239 Y95.93 E.03433
G1 X234.02 Y95.312 E.03433
G1 X233.711 Y94.743 E.03392
G1 X233.445 Y94.376 E.02377
G1 X232.999 Y93.907 E.03389
G1 X232.479 Y93.507 E.03436
G1 X231.902 Y93.195 E.03434
G1 X231.284 Y92.976 E.03435
G1 X230.64 Y92.856 E.03431
G1 X230.038 Y92.838 E.03155
G2 X228.962 Y93.023 I.167 J4.176 E.05734
; OBJECT_ID: 12
; WIPE_START
G1 X228.505 Y93.196 E-.09292
G1 X228.121 Y93.389 E-.0816
G1 X227.921 Y93.512 E-.04463
G1 X227.574 Y93.765 E-.0816
G1 X227.264 Y94.044 E-.07925
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.06 Y96.568 Z5 F36000
G1 X211.844 Y99.446 Z5
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X212.061 Y99.157 E.01224
G2 X209.186 Y93.137 I-3.275 J-2.133 E.27058
G2 X208.634 Y93.119 I-.411 J4.2 E.01873
G2 X211.812 Y99.497 I.152 J3.906 E.52768
M204 S10000
G1 X211.515 Y99.207 F36000
G1 F1473.913
M204 S3000
G1 X211.719 Y98.935 E.01152
G2 X209.144 Y93.542 I-2.934 J-1.911 E.24241
G2 X208.652 Y93.526 I-.367 J3.755 E.01665
G2 X211.482 Y99.257 I.133 J3.499 E.47207
M204 S250
G1 X211.198 Y98.977 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.393 Y98.723 E.01004
G2 X208.94 Y93.919 I-2.605 J-1.699 E.20474
G2 X208.67 Y93.917 I-.149 J2.567 E.00846
M73 P75 R12
G2 X211.169 Y99.025 I.118 J3.107 E.38759
; WIPE_START
M204 S3000
G1 X211.393 Y98.723 E-.07142
G1 X211.619 Y98.29 E-.09289
G1 X211.735 Y97.986 E-.06184
G1 X211.82 Y97.671 E-.06186
G1 X211.871 Y97.35 E-.06183
G1 X211.879 Y97.191 E-.03016
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.646 Y99.276 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.692 Y99.383 E.00395
G2 X208.943 Y92.319 I4.075 J-2.359 E.66149
G2 X208.285 Y92.341 I-.164 J5.068 E.02231
G2 X204.468 Y98.943 I.482 J4.684 E.30091
G1 X204.617 Y99.223 E.01074
M204 S10000
G1 X204.273 Y99.443 F36000
G1 F1473.913
M204 S3000
G1 X204.481 Y99.815 E.01443
G2 X208.954 Y91.912 I4.289 J-2.79 E.70995
G2 X207.977 Y91.971 I-.075 J6.949 E.03316
G2 X204.212 Y99.351 I.792 J5.054 E.32682
G1 X204.24 Y99.393 E.0017
M204 S250
G1 X203.934 Y99.639 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.151 Y100.029 E.01401
G2 X208.964 Y91.52 I4.617 J-3.004 E.70812
G2 X207.916 Y91.583 I-.077 J7.491 E.03297
G2 X203.862 Y99.529 I.853 J5.442 E.32595
G1 X203.901 Y99.588 E.00222
; WIPE_START
M204 S3000
G1 X204.151 Y100.029 E-.09625
G1 X204.32 Y100.263 E-.05487
G1 X204.683 Y100.711 E-.10959
G1 X205.091 Y101.119 E-.10952
G1 X205.131 Y101.151 E-.00976
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.941 Y98.988 Z5 F36000
M73 P75 R11
G1 Z4.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436012
G1 F1526.361
M204 S3000
G1 X205.163 Y99.372 E.0145
G2 X204.468 Y97.019 I3.613 J-2.347 E.80361
G1 X204.491 Y97.475 E.01492
G1 X204.561 Y97.916 E.01457
G1 X204.677 Y98.352 E.01474
G1 X204.76 Y98.584 E.00807
G2 X204.914 Y98.934 I4.017 J-1.56 E.01251
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.09568
G1 X205.428 Y99.737 E-.08569
G1 X205.726 Y100.068 E-.08469
G1 X205.898 Y100.231 E-.0449
G1 X206.181 Y100.459 E-.06905
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.788 Y98.559 Z5 F36000
G1 X183.871 Y94.725 Z5
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.843 Y94.778 E.00203
G2 X187.759 Y92.902 I3.49 J2.261 E.72977
G2 X187.172 Y92.884 I-.437 J4.47 E.0199
G2 X184.098 Y94.426 I.161 J4.155 E.12003
G1 X183.907 Y94.677 E.01067
M204 S10000
G1 X184.2 Y94.964 F36000
G1 F1473.913
M204 S3000
G1 X184.184 Y95 E.00132
G2 X187.717 Y93.307 I3.148 J2.04 E.65833
G2 X187.191 Y93.29 I-.394 J4.021 E.01782
G2 X184.414 Y94.682 I.142 J3.749 E.1084
G1 X184.236 Y94.916 E.00994
M204 S250
G1 X184.517 Y95.194 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.512 Y95.213 E.0006
G2 X187.676 Y93.698 I2.819 J1.826 E.54607
G2 X187.209 Y93.682 I-.352 J3.596 E.01465
G2 X184.718 Y94.929 I.123 J3.357 E.09004
G1 X184.553 Y95.147 E.00857
; WIPE_START
M204 S3000
G1 X184.512 Y95.213 E-.01482
G1 X184.255 Y95.673 E-.1001
G1 X184.129 Y96.001 E-.06683
G1 X184.037 Y96.342 E-.0671
G1 X183.983 Y96.688 E-.06653
G1 X183.965 Y97.028 E-.06462
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.491 Y92.319 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.83 Y92.341 I-.165 J5.086 E.02238
G2 X187.551 Y92.322 I.484 J4.699 E.9802
M204 S10000
G1 X187.501 Y91.912 F36000
G1 F1473.913
M204 S3000
G2 X186.521 Y91.971 I-.075 J6.968 E.03326
G2 X187.561 Y91.915 I.795 J5.069 E1.05582
M204 S250
G1 X187.523 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.512 Y91.52 E.00034
G2 X186.46 Y91.583 I-.077 J7.51 E.03306
G2 X187.901 Y91.548 I.855 J5.456 E1.04269
G1 X187.582 Y91.525 E.01003
; WIPE_START
M204 S3000
G1 X187.512 Y91.52 E-.01348
G1 X187.035 Y91.523 E-.0905
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10984
G1 X185.617 Y91.786 E-.05495
G1 X185.611 Y91.788 E-.00134
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.526 Y92.608 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.20065
G1 F3803.984
M204 S3000
G1 X187.324 Y92.598 E.00264
G2 X182.882 Y97.039 I-.001 J4.441 E.09151
G1 X182.889 Y97.274 E.00308
G1 X182.937 Y97.732 E.00604
G1 X183.037 Y98.2 E.00628
G2 X187.788 Y92.622 I4.287 J-1.161 E.25297
G1 X187.586 Y92.611 E.00267
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.598 E-.04971
G1 X186.871 Y92.62 E-.08614
G1 X186.628 Y92.652 E-.04669
G1 X186.173 Y92.749 E-.08842
G1 X185.732 Y92.892 E-.08798
G1 X185.631 Y92.937 E-.02106
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.001 Y93.137 Z5 F36000
G1 X163.21 Y93.523 Z5
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.07 Y93.634 E.00605
G2 X166.302 Y92.67 I2.78 J3.421 E.82044
G2 X165.68 Y92.65 I-.463 J4.738 E.02107
G2 X163.442 Y93.362 I.17 J4.405 E.08045
G1 X163.26 Y93.489 E.00753
M204 S10000
G1 X163.449 Y93.852 F36000
G1 F1473.913
M204 S3000
G1 X163.326 Y93.95 E.00533
G2 X166.259 Y93.075 I2.523 J3.105 E.74467
G2 X165.699 Y93.057 I-.42 J4.288 E.01899
G2 X163.664 Y93.703 I.151 J3.998 E.07315
G1 X163.499 Y93.818 E.0068
M204 S250
G1 X163.68 Y94.169 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.572 Y94.254 E.00429
G2 X166.218 Y93.465 I2.276 J2.801 E.62219
G2 X165.717 Y93.448 I-.378 J3.863 E.01574
G2 X163.877 Y94.032 I.132 J3.607 E.06125
G1 X163.729 Y94.135 E.00566
; WIPE_START
M204 S3000
G1 X163.572 Y94.254 E-.0374
G1 X163.288 Y94.502 E-.07175
G1 X162.92 Y94.933 E-.10764
G1 X162.714 Y95.25 E-.07179
G1 X162.543 Y95.587 E-.0718
G1 X162.506 Y95.683 E-.01962
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.484 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.008 Y92.319 I1.69 J-4.428 E.5565
G2 X165.345 Y92.341 I-.165 J5.103 E.02246
G2 X164.085 Y101.462 I.485 J4.715 E.42703
M204 S10000
G1 X163.991 Y101.859 F36000
G1 F1473.913
M204 S3000
G1 X163.995 Y101.863 E.0002
G2 X166.018 Y91.912 I1.837 J-4.807 E.60456
G2 X165.035 Y91.971 I-.076 J6.989 E.03336
G2 X163.502 Y101.644 I.797 J5.084 E.43833
G1 X163.936 Y101.834 E.01602
M204 S250
G1 X163.831 Y102.216 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.229 E.00082
G2 X166.028 Y91.52 I1.977 J-5.174 E.60277
G2 X164.974 Y91.584 I-.077 J7.534 E.03315
G2 X163.324 Y101.994 I.858 J5.472 E.43698
G1 X163.776 Y102.192 E.01549
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.229 E-.01636
G1 X164.407 Y102.406 E-.11022
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.725 Y102.587 E-.03305
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.941 Y106.085 Z5 F36000
G1 X47.352 Y163.613 Z5
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.611 E.00112
G2 X47.306 Y154.319 I-.253 J-4.644 E.48012
G2 X46.655 Y154.34 I-.162 J5.009 E.02204
G2 X46.898 Y163.612 I.476 J4.627 E.47053
G1 X47.292 Y163.613 E.01332
M204 S10000
G1 X47.352 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00184
G2 X47.316 Y153.912 I-.276 J-5.051 E.52229
G2 X46.613 Y153.935 I-.173 J5.439 E.02384
G2 X46.877 Y164.019 I.518 J5.032 E.51178
G1 X47.292 Y164.019 E.01404
M204 S250
G1 X47.352 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00235
G2 X47.327 Y153.52 I-.294 J-5.442 E.52154
G2 X46.289 Y153.582 I-.076 J7.413 E.03262
G2 X46.857 Y164.41 I.844 J5.384 E.50161
G1 X47.292 Y164.411 E.01365
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.02562
G1 X47.712 Y164.389 E-.05426
G1 X48.275 Y164.299 E-.10842
G1 X48.826 Y164.152 E-.10839
G1 X49.235 Y163.995 E-.08331
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.89 Y163.201 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X48.8 Y162.934 I-.643 J-3.865 E.03218
G1 X43.176 Y157.309 E.26924
G1 X43.294 Y157.044 E.00983
G1 X49.507 Y155.379 E.21774
G3 X49.748 Y155.547 I-.682 J1.229 E.00996
G1 X47.689 Y163.231 E.26924
G1 X47.4 Y163.261 E.00983
G1 X42.848 Y158.708 E.21793
G1 X42.878 Y158.42 E.00983
G1 X50.561 Y156.361 E.26924
G3 X50.731 Y156.594 I-1.401 J1.201 E.0098
G1 X49.066 Y162.809 E.21779
G2 X49.876 Y162.282 I-1.935 J-3.86 E.03277
G1 X43.826 Y156.233 E.28961
G3 X44.563 Y155.528 I4.278 J3.739 E.03455
M204 S10000
G1 X45.101 Y155.183 F36000
G1 F1473.913
M204 S3000
G2 X44.757 Y155.387 I.799 J1.734 E.01357
G1 X47.415 Y154.675 E.09314
M73 P76 R11
G2 X47.014 Y154.669 I-.246 J2.825 E.01358
M204 S10000
G1 X47.655 Y154.697 F36000
G1 F1473.913
M204 S3000
G3 X48.646 Y154.941 I-.574 J4.465 E.03462
G1 X46.43 Y163.209 E.28974
G3 X45.452 Y162.921 I.874 J-4.779 E.03459
M204 S10000
G1 X44.88 Y162.622 F36000
G1 F1473.913
M204 S3000
G2 X45.23 Y162.818 I1.151 J-1.652 E.01358
G1 X43.274 Y160.842 E.0941
G1 X51.43 Y158.655 E.28583
G1 X47.452 Y154.678 E.19041
G1 X45.266 Y162.836 E.2859
G1 X50.698 Y161.381 E.19034
G1 X44.729 Y155.408 E.28584
G1 X43.273 Y160.839 E.19033
G3 X42.899 Y159.678 I5.035 J-2.259 E.04137
G1 X51.171 Y157.462 E.28987
G3 X51.409 Y158.453 I-4.321 J1.56 E.03457
M204 S10000
G1 X51.439 Y159.092 F36000
G1 F1473.913
M204 S3000
G2 X51.434 Y158.692 I-1.904 J-.175 E.01357
G1 X50.724 Y161.341 E.09285
G2 X50.933 Y160.997 I-1.771 J-1.31 E.01364
; WIPE_START
G1 X50.724 Y161.341 E-.07648
G1 X51.137 Y159.798 E-.30352
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X44.199 Y162.101 Z5 F36000
G1 Z4.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X46.16 Y154.782 E.25649
M204 S10000
G1 X45.9 Y154.852 F36000
G1 F1473.913
M204 S3000
G1 X51.257 Y160.209 E.25644
M204 S10000
G1 X51.326 Y159.949 F36000
G1 F1473.913
M204 S3000
G1 X44.007 Y161.91 E.25649
; OBJECT_ID: 14
; WIPE_START
G1 X45.939 Y161.392 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X38.618 Y159.234 Z5 F36000
G1 X26.607 Y155.694 Z5
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.319 Y155.631 E.00998
G2 X25.964 Y155.595 I-.523 J3.369 E.01207
G2 X25.658 Y155.594 I-.166 J2.902 E.01035
G2 X26.669 Y155.705 I.138 J3.406 E.69048
G1 X26.666 Y155.704 E.0001
M204 S10000
G1 X26.522 Y156.091 F36000
G1 F1473.913
M204 S3000
G1 X26.255 Y156.034 E.00925
G2 X25.942 Y156.002 I-.46 J2.966 E.01064
G2 X25.677 Y156.001 I-.145 J2.522 E.00899
G2 X26.581 Y156.103 I.118 J2.999 E.6075
M204 S250
G1 X26.441 Y156.475 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.194 Y156.421 E.00792
G2 X25.922 Y156.393 I-.399 J2.577 E.00857
G2 X25.695 Y156.392 I-.125 J2.16 E.00712
G2 X26.499 Y156.487 I.1 J2.606 E.48831
; WIPE_START
M204 S3000
G1 X26.194 Y156.421 E-.05937
G1 X25.922 Y156.393 E-.05192
G1 X25.695 Y156.392 E-.0431
G1 X25.243 Y156.447 E-.08656
G1 X24.979 Y156.518 E-.05191
G1 X24.724 Y156.616 E-.05191
G1 X24.561 Y156.704 E-.03523
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.95 Y154.319 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.296 Y154.34 I-.163 J5.039 E.0222
G2 X26.01 Y154.322 I.48 J4.66 E.97205
M204 S10000
G1 X25.961 Y153.912 F36000
G1 F1473.913
M204 S3000
G2 X24.989 Y153.97 I-.075 J6.911 E.033
G2 X26.021 Y153.915 I.788 J5.03 E1.04775
M204 S250
G1 X25.986 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.971 Y153.52 E.00047
G2 X24.927 Y153.583 I-.076 J7.457 E.03282
G2 X26.358 Y153.548 I.849 J5.417 E1.03524
G1 X26.046 Y153.525 E.00981
; WIPE_START
M204 S3000
G1 X25.971 Y153.52 E-.01426
G1 X25.498 Y153.523 E-.08986
G1 X24.927 Y153.583 E-.10911
G1 X24.645 Y153.635 E-.05456
G1 X24.09 Y153.784 E-.10908
G1 X24.075 Y153.79 E-.00312
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.155 Y155.265 Z5 F36000
G1 Z4.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X26.754 Y155.369 I-.195 J2.905 E.02064
G1 X26.061 Y154.675 E.03321
G1 X26.105 Y154.678 E.00149
G1 X25.952 Y155.247 E.01993
G2 X25.187 Y155.295 I-.158 J3.593 E.02599
M204 S10000
G1 X24.987 Y155.329 F36000
G1 F1473.913
M204 S3000
G1 X24.517 Y154.859 E.02249
M204 S10000
G1 X24.813 Y154.779 F36000
G1 F1473.913
M204 S3000
G1 X24.641 Y155.421 E.02249
M204 S10000
G1 X24.451 Y155.492 F36000
G1 F1473.913
M204 S3000
G2 X23.767 Y155.836 I1.34 J3.52 E.02594
G1 X23.349 Y155.417 E.02002
G1 X23.385 Y155.391 E.00152
G1 X23.128 Y156.35 E.03359
G3 X23.596 Y155.947 I3.358 J3.427 E.02093
M204 S10000
G1 X23.147 Y155.564 F36000
G1 F1473.913
M204 S3000
G1 X23.312 Y155.444 E.00689
G1 X26.158 Y154.682 E.09974
G3 X27.298 Y154.942 I-1.382 J8.678 E.03962
G1 X27.149 Y155.499 E.01951
G1 X27.404 Y155.612 E.00944
G1 X28.194 Y155.401 E.02769
G3 X28.401 Y155.546 I-.586 J1.057 E.00857
G1 X28.237 Y156.156 E.0214
G3 X28.625 Y156.549 I-1.293 J1.666 E.01876
G1 X29.238 Y156.385 E.02147
G1 X29.386 Y156.588 E.00849
G1 X29.173 Y157.382 E.02782
G1 X29.286 Y157.636 E.00944
G1 X29.847 Y157.486 E.01964
G3 X30.101 Y158.636 I-4.321 J1.56 E.03996
G1 X29.34 Y161.478 E.0996
G3 X28.547 Y162.343 I-7.42 J-6.006 E.03974
G1 X28.136 Y161.931 E.01969
G1 X27.91 Y162.095 E.00944
G1 X27.697 Y162.889 E.02781
G1 X27.468 Y162.991 E.00849
G1 X27.022 Y162.545 E.02138
G3 X26.487 Y162.688 I-.948 J-2.468 E.01877
G1 X26.324 Y163.298 E.02138
G1 X26.074 Y163.324 E.00849
G1 X25.491 Y162.741 E.02792
G3 X25.217 Y162.71 I-.019 J-1.055 E.00936
G1 X25.065 Y163.276 E.01983
G3 X23.946 Y162.923 I2.296 J-9.239 E.03975
G1 X21.865 Y160.842 E.0996
G3 X21.511 Y159.72 I4.172 J-1.934 E.03995
G1 X22.071 Y159.57 E.01964
G1 X22.042 Y159.292 E.00944
G1 X21.461 Y158.711 E.02781
G1 X21.487 Y158.462 E.00849
G1 X22.097 Y158.299 E.02134
G3 X22.24 Y157.763 I4.461 J.908 E.01878
G1 X21.791 Y157.314 E.02149
G3 X21.9 Y157.087 I1.496 J.577 E.00853
G1 X22.69 Y156.875 E.0277
G3 X22.857 Y156.653 I1.143 J.682 E.00943
G1 X22.446 Y156.242 E.01966
G3 X23.147 Y155.564 I4.595 J4.048 E.03304
; WIPE_START
G1 X22.446 Y156.242 E-.18526
G1 X22.857 Y156.653 E-.11033
G1 X22.69 Y156.875 E-.05283
G1 X22.53 Y156.918 E-.03158
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.366 Y160.548 Z5 F36000
G1 Z4.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.156 Y159.976 I2.617 J-1.285 E.02064
G1 X21.902 Y160.925 E.03325
G1 X21.884 Y160.884 E.00152
G1 X22.452 Y160.732 E.0199
G2 X23.008 Y161.517 I3.19 J-1.671 E.03266
G1 X22.832 Y162.171 E.02294
M204 S10000
G1 X22.614 Y161.953 F36000
G1 F1473.913
M204 S3000
G1 X23.258 Y161.78 E.02257
M204 S10000
G1 X23.415 Y161.91 F36000
G1 F1473.913
M204 S3000
G2 X24.054 Y162.33 I2.377 J-2.918 E.02594
G1 X23.901 Y162.9 E.01998
G1 X23.865 Y162.882 E.00138
G1 X24.819 Y162.626 E.03341
G3 X24.236 Y162.423 I1.289 J-4.621 E.02092
; WIPE_START
G1 X24.819 Y162.626 E-.11737
G1 X23.865 Y162.882 E-.18755
G1 X23.901 Y162.9 E-.00772
G1 X23.993 Y162.558 E-.06736
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.839 Y161.189 Z5 F36000
G1 Z4.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X28.426 Y161.66 I-3.23 J-2.414 E.02121
G1 X29.389 Y161.402 E.03375
G1 X29.367 Y161.436 E.00138
G1 X28.95 Y161.018 E.01998
G2 X29.293 Y160.336 I-3.247 J-2.064 E.0259
M204 S10000
G1 X29.362 Y160.145 F36000
G1 F1473.913
M204 S3000
G1 X30.008 Y159.972 E.02264
M204 S10000
G1 X29.928 Y160.27 F36000
G1 F1473.913
M204 S3000
G1 X29.453 Y159.795 E.02275
G2 X29.538 Y158.833 I-3.861 J-.827 E.03276
G1 X30.106 Y158.681 E.0199
G1 X30.111 Y158.726 E.00151
G1 X29.416 Y158.031 E.03325
G3 X29.52 Y158.631 I-2.802 J.795 E.02064
; CHANGE_LAYER
; Z_HEIGHT: 4.8
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X29.416 Y158.031 E-.11563
G1 X30.111 Y158.726 E-.18664
G1 X30.106 Y158.681 E-.0085
G1 X29.754 Y158.775 E-.06923
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L24
M991 S0 P23 ;notify layer change


M204 S10000
G17
G3 Z5 I1.217 J0 P1  F36000
; object ids of layer 24 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer24 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.12 Y93.518
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.073 Y93.535 E.00167
G2 X230.395 Y93.357 I1.141 J3.476 E.73278
G2 X230.064 Y93.356 I-.178 J3.137 E.01122
G2 X229.443 Y93.435 I.151 J3.656 E.0212
G1 X229.178 Y93.503 E.00927
M204 S10000
G1 X229.225 Y93.911 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.922 E.00095
G2 X230.373 Y93.764 I1.014 J3.089 E.65125
G2 X230.082 Y93.762 I-.158 J2.76 E.00986
G2 X229.528 Y93.833 I.131 J3.249 E.01895
G1 X229.283 Y93.896 E.00855
M204 S250
G1 X229.326 Y94.29 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.32 Y94.295 E.00025
G2 X230.353 Y94.155 I.892 J2.717 E.53051
G2 X230.1 Y94.154 I-.138 J2.398 E.00792
G2 X229.609 Y94.216 I.112 J2.857 E.01555
G1 X229.384 Y94.275 E.00728
; WIPE_START
M204 S3000
G1 X229.32 Y94.295 E-.01276
G1 X229.04 Y94.399 E-.05683
G1 X228.645 Y94.613 E-.08528
G1 X228.403 Y94.789 E-.05692
G1 X228.181 Y94.989 E-.05685
G1 X227.98 Y95.212 E-.05688
G1 X227.812 Y95.444 E-.05448
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.659 Y92.581 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.625 E.00496
G2 X230.377 Y92.319 I1.675 J4.387 E.93449
G2 X229.712 Y92.34 I-.171 J5.07 E.02254
G2 X228.987 Y92.473 I.482 J4.671 E.02497
G1 X228.716 Y92.563 E.00966
M204 S10000
G1 X228.552 Y92.186 F36000
G1 F1473.913
M204 S3000
G1 X228.126 Y92.346 E.0154
G2 X230.388 Y91.912 I2.067 J4.665 E1.00661
G2 X229.67 Y91.936 I-.182 J5.497 E.02434
G2 X228.625 Y92.155 I.523 J5.076 E.0362
G1 X228.607 Y92.163 E.00066
M204 S250
G1 X228.413 Y91.822 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.233 Y91.879 E.00591
G2 X230.398 Y91.52 I1.962 J5.133 E1.01333
G2 X229.343 Y91.583 I-.088 J7.444 E.03316
G2 X228.78 Y91.702 I.851 J5.429 E.01804
G1 X228.47 Y91.804 E.01025
; WIPE_START
M204 S3000
G1 X228.233 Y91.879 E-.04722
G1 X227.708 Y92.115 E-.10936
G1 X227.21 Y92.402 E-.10927
G1 X226.744 Y92.74 E-.10931
G1 X226.725 Y92.757 E-.00484
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.908 Y93.04 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672861
G1 F952.472
M204 S3000
G1 X228.698 Y93.114 E.01162
G2 X226.025 Y97.003 I1.504 J3.897 E.26269
G1 X226.048 Y97.449 E.02335
G1 X226.115 Y97.872 E.02246
G1 X226.227 Y98.295 E.02292
G1 X226.31 Y98.527 E.01293
G2 X228.965 Y93.022 I3.893 J-1.516 E1.01566
; OBJECT_ID: 12
; WIPE_START
G1 X228.698 Y93.114 E-.05355
G1 X228.306 Y93.289 E-.08157
G1 X227.935 Y93.503 E-.0815
G1 X227.741 Y93.636 E-.04474
G1 X227.407 Y93.907 E-.08148
G1 X227.269 Y94.045 E-.03716
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.069 Y96.578 Z5.2 F36000
G1 X211.81 Y99.483 Z5.2
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.944 Y99.326 E.00699
G2 X209.186 Y93.137 I-3.159 J-2.301 E.27751
G2 X208.629 Y93.119 I-.411 J4.206 E.01888
G2 X211.686 Y99.644 I.156 J3.905 E.521
G1 X211.774 Y99.53 E.00485
M204 S10000
G1 X211.484 Y99.245 F36000
G1 F1473.913
M204 S3000
G1 X211.506 Y99.234 E.00082
G2 X208.961 Y93.527 I-2.717 J-2.209 E.26128
G2 X208.648 Y93.526 I-.17 J2.969 E.0106
G2 X211.259 Y99.506 I.141 J3.499 E.46042
G1 X211.445 Y99.291 E.00963
M204 S250
G1 X211.193 Y98.983 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.2 Y98.987 E.00025
G2 X208.94 Y93.919 I-2.412 J-1.962 E.21495
G2 X208.666 Y93.917 I-.15 J2.608 E.0086
G2 X210.982 Y99.229 I.122 J3.107 E.3788
G1 X211.154 Y99.029 E.00828
; WIPE_START
M204 S3000
G1 X211.2 Y98.987 E-.01189
G1 X211.386 Y98.719 E-.06194
G1 X211.619 Y98.29 E-.09274
G1 X211.735 Y97.986 E-.06185
G1 X211.82 Y97.671 E-.06186
G1 X211.871 Y97.35 E-.06183
G1 X211.878 Y97.203 E-.02789
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.639 Y99.262 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.693 Y99.383 E.0045
G2 X208.952 Y92.319 I4.075 J-2.359 E.66123
G2 X208.285 Y92.341 I-.172 J5.082 E.02261
G2 X204.468 Y98.943 I.483 J4.684 E.30088
G1 X204.61 Y99.209 E.0102
M204 S10000
G1 X204.276 Y99.447 F36000
G1 F1473.913
M204 S3000
G1 X204.339 Y99.587 E.00522
G2 X208.963 Y91.912 I4.428 J-2.563 E.71853
G2 X208.243 Y91.936 I-.183 J5.514 E.0244
G2 X204.095 Y99.109 I.524 J5.089 E.32692
G1 X204.248 Y99.394 E.01092
M204 S250
G1 X203.926 Y99.625 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.152 Y100.029 E.0145
G2 X208.973 Y91.52 I4.617 J-3.004 E.70788
M73 P77 R11
G2 X207.916 Y91.583 I-.088 J7.461 E.03324
G2 X203.862 Y99.529 I.853 J5.442 E.32592
G1 X203.893 Y99.575 E.00173
; WIPE_START
M204 S3000
G1 X204.152 Y100.029 E-.09926
G1 X204.32 Y100.263 E-.0548
G1 X204.683 Y100.711 E-.10963
G1 X205.091 Y101.119 E-.10955
G1 X205.119 Y101.141 E-.00676
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.937 Y98.981 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436011
G1 F1526.364
M204 S3000
G2 X204.468 Y97.025 I3.839 J-1.956 E.81856
G1 X204.491 Y97.475 E.01475
G1 X204.561 Y97.916 E.01458
G1 X204.677 Y98.352 E.01474
G1 X204.76 Y98.584 E.00805
G2 X204.911 Y98.927 I4.017 J-1.559 E.01226
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.09724
G1 X205.428 Y99.737 E-.08566
G1 X205.726 Y100.068 E-.08472
G1 X206.061 Y100.371 E-.08574
G1 X206.173 Y100.456 E-.02664
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.777 Y98.571 Z5.2 F36000
G1 X183.848 Y94.765 Z5.2
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.729 Y94.963 E.00782
G2 X187.759 Y92.902 I3.603 J2.076 E.72241
G2 X187.167 Y92.884 I-.437 J4.476 E.02006
G2 X183.965 Y94.599 I.165 J4.155 E.12724
G1 X183.883 Y94.716 E.00485
M204 S10000
G1 X184.189 Y94.987 F36000
G1 F1473.913
M204 S3000
G1 X184.081 Y95.167 E.0071
G2 X187.717 Y93.307 I3.251 J1.872 E.65169
G2 X187.186 Y93.291 I-.394 J4.029 E.01798
G2 X184.294 Y94.838 I.146 J3.748 E.11489
G1 X184.224 Y94.938 E.00414
M204 S250
G1 X184.514 Y95.198 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.512 Y95.213 E.00047
G2 X187.676 Y93.698 I2.819 J1.826 E.54607
G2 X187.204 Y93.682 I-.353 J3.603 E.0148
G2 X184.718 Y94.928 I.127 J3.357 E.08989
G1 X184.551 Y95.15 E.00871
; WIPE_START
M204 S3000
G1 X184.512 Y95.213 E-.01399
G1 X184.255 Y95.673 E-.10012
G1 X184.129 Y96.001 E-.06681
G1 X184.038 Y96.341 E-.06682
G1 X183.983 Y96.688 E-.06681
G1 X183.965 Y97.032 E-.06544
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.499 Y92.319 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.831 Y92.341 I-.172 J5.101 E.02267
G2 X187.559 Y92.322 I.484 J4.698 E.97983
M204 S10000
G1 X187.51 Y91.912 F36000
G1 F1473.913
M204 S3000
G2 X186.788 Y91.936 I-.183 J5.53 E.02447
G2 X187.57 Y91.915 I.526 J5.103 E1.06461
M204 S250
G1 X187.528 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.52 Y91.52 E.00023
G2 X186.46 Y91.583 I-.088 J7.483 E.03333
G2 X187.901 Y91.548 I.856 J5.456 E1.04271
M73 P77 R10
G1 X187.587 Y91.525 E.00987
; WIPE_START
M204 S3000
G1 X187.52 Y91.52 E-.01279
G1 X187.035 Y91.523 E-.09213
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10987
G1 X185.618 Y91.794 E-.05532
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.531 Y92.608 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200633
G1 F3804.393
M204 S3000
G1 X187.324 Y92.597 E.00271
G2 X182.882 Y97.039 I0 J4.442 E.0915
G1 X182.907 Y97.504 E.0061
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.0061
G1 X183.181 Y98.641 E.00321
G2 X187.787 Y92.621 I4.143 J-1.602 E.24693
G1 X187.591 Y92.611 E.00257
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.05073
G1 X186.866 Y92.621 E-.0872
G1 X186.627 Y92.652 E-.04566
G1 X186.173 Y92.749 E-.08837
G1 X185.732 Y92.892 E-.08794
G1 X185.636 Y92.935 E-.0201
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.006 Y93.136 Z5.2 F36000
G1 X163.207 Y93.525 Z5.2
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.07 Y93.633 E.00592
G2 X166.301 Y92.67 I2.78 J3.422 E.82043
G2 X165.675 Y92.65 I-.463 J4.744 E.02124
G2 X163.442 Y93.362 I.175 J4.405 E.08028
G1 X163.256 Y93.491 E.00766
M204 S10000
G1 X163.446 Y93.854 F36000
G1 F1473.913
M204 S3000
G1 X163.326 Y93.95 E.0052
G2 X166.259 Y93.075 I2.523 J3.105 E.74467
G2 X165.693 Y93.057 I-.42 J4.296 E.01917
G2 X163.664 Y93.703 I.155 J3.998 E.07298
G1 X163.495 Y93.82 E.00694
M204 S250
G1 X163.676 Y94.171 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.572 Y94.254 E.00417
G2 X166.218 Y93.465 I2.276 J2.801 E.62219
G2 X165.711 Y93.448 I-.379 J3.87 E.0159
G2 X163.877 Y94.032 I.137 J3.607 E.06109
G1 X163.726 Y94.137 E.00578
; WIPE_START
M204 S3000
G1 X163.572 Y94.254 E-.03668
G1 X163.288 Y94.502 E-.07175
G1 X163.035 Y94.783 E-.0718
G1 X162.813 Y95.089 E-.07178
G1 X162.624 Y95.416 E-.0718
G1 X162.504 Y95.686 E-.0562
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.483 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.016 Y92.319 I1.69 J-4.428 E.55621
G2 X165.345 Y92.341 I-.173 J5.117 E.02275
G2 X164.085 Y101.461 I.486 J4.714 E.42695
M204 S10000
G1 X163.995 Y101.863 F36000
G1 F1473.913
M204 S3000
G2 X166.027 Y91.912 I1.835 J-4.808 E.60411
G2 X165.302 Y91.936 I-.184 J5.545 E.02455
G2 X163.939 Y101.841 I.527 J5.119 E.46383
M204 S250
G1 X163.835 Y102.218 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.229 E.00068
G2 X166.037 Y91.52 I1.978 J-5.174 E.60258
G2 X164.974 Y91.584 I-.088 J7.504 E.03342
G2 X163.324 Y101.994 I.858 J5.472 E.43698
G1 X163.78 Y102.194 E.01563
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.229 E-.01552
G1 X164.129 Y102.324 E-.05513
G1 X164.407 Y102.406 E-.05512
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.729 Y102.587 E-.03385
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.945 Y106.085 Z5.2 F36000
G1 X47.358 Y163.613 Z5.2
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.611 E.00092
G2 X47.698 Y163.584 I-.238 J-4.644 E.01065
G2 X47.314 Y154.319 I-.557 J-4.617 E.46982
G2 X46.898 Y163.611 I-.168 J4.647 E.49181
G1 X47.298 Y163.612 E.01352
M204 S10000
G1 X47.358 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00164
G2 X47.325 Y153.912 I-.275 J-5.051 E.52205
G2 X46.613 Y153.935 I-.181 J5.45 E.02413
G2 X46.877 Y164.019 I.518 J5.032 E.51174
G1 X47.298 Y164.019 E.01424
M204 S250
G1 X47.358 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00216
G2 X47.335 Y153.52 I-.293 J-5.442 E.5213
G2 X46.289 Y153.582 I-.087 J7.381 E.03289
G2 X46.857 Y164.41 I.844 J5.384 E.50159
G1 X47.298 Y164.411 E.01383
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.02448
G1 X47.803 Y164.377 E-.07169
G1 X48.275 Y164.299 E-.09096
G1 X48.826 Y164.152 E-.10839
G1 X49.241 Y163.992 E-.08448
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.122 Y162.786 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X49.988 Y162.194 I-2.45 J-4.513 E.03554
G1 X43.918 Y156.125 E.29055
G2 X43.323 Y156.986 I3.442 J3.014 E.03553
; WIPE_START
G1 X43.918 Y156.125 E-.19899
G1 X44.592 Y156.798 E-.18102
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X42.844 Y158.773 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X42.929 Y159.817 I4.573 J.155 E.03553
G1 X51.218 Y157.595 E.29049
G2 X50.763 Y156.653 I-4.281 J1.487 E.03549
M204 S10000
G1 X50.498 Y156.283 F36000
G1 F1473.913
M204 S3000
G2 X49.667 Y155.483 I-7.315 J6.765 E.0391
G1 X43.22 Y157.21 E.22593
G1 X43.237 Y157.171 E.00146
G1 X48.938 Y162.871 E.27289
G1 X48.898 Y162.889 E.00146
G1 X50.626 Y156.442 E.22592
G1 X50.653 Y156.483 E.00165
G1 X42.862 Y158.57 E.273
G1 X42.867 Y158.527 E.00146
G1 X47.581 Y163.242 E.22568
G1 X47.538 Y163.246 E.00146
G1 X49.626 Y155.456 E.273
G2 X48.513 Y154.89 I-2.653 J3.841 E.04238
G1 X46.292 Y163.18 E.29049
G3 X45.595 Y162.982 I1.312 J-5.962 E.02455
G1 X43.134 Y160.522 E.11777
G1 X43.18 Y160.639 E.00425
G1 X44.546 Y155.539 E.17873
G1 X44.451 Y155.616 E.00415
G1 X47.796 Y154.719 E.11722
G1 X47.675 Y154.7 E.00415
G1 X51.407 Y158.432 E.17862
G1 X51.393 Y158.299 E.00452
G1 X50.493 Y161.657 E.11769
G1 X50.57 Y161.562 E.00415
G1 X45.473 Y162.928 E.17862
G1 X45.32 Y162.86 E.00565
M204 S10000
G1 X45.137 Y162.772 F36000
G1 F1473.913
M204 S3000
G1 X47.308 Y154.668 E.28398
; WIPE_START
G1 X46.791 Y156.6 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X44.851 Y155.33 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X50.78 Y161.26 E.28383
M204 S10000
G1 X51.105 Y160.631 F36000
G1 F1473.913
M204 S3000
G2 X51.291 Y160.105 I-2.412 J-1.147 E.01893
G1 X44.117 Y162.027 E.25137
G1 X44.081 Y161.992 E.00169
G1 X46.028 Y154.81 E.25187
G1 X51.304 Y160.056 E.25183
G2 X51.406 Y159.507 I-2.558 J-.761 E.01893
M204 S10000
G1 X51.439 Y158.801 F36000
G1 F1473.913
M204 S3000
G1 X43.34 Y160.971 E.28383
; OBJECT_ID: 14
; WIPE_START
G1 X45.271 Y160.453 E-.38
; WIPE_END
M73 P78 R10
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.876 Y158.567 Z5.2 F36000
G1 X26.6 Y155.692 Z5.2
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.319 Y155.631 E.00976
G2 X25.964 Y155.595 I-.523 J3.369 E.01207
G2 X25.655 Y155.594 I-.166 J2.928 E.01048
G2 X26.668 Y155.705 I.141 J3.406 E.69036
G1 X26.659 Y155.703 E.00031
M204 S10000
G1 X26.516 Y156.09 F36000
G1 F1473.913
M204 S3000
G1 X26.255 Y156.034 E.00903
G2 X25.942 Y156.002 I-.46 J2.966 E.01064
G2 X25.673 Y156.001 I-.146 J2.551 E.00912
G2 X26.575 Y156.101 I.122 J2.999 E.6076
M204 S250
G1 X26.434 Y156.473 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.194 Y156.421 E.00772
G2 X25.922 Y156.393 I-.4 J2.577 E.00857
G2 X25.691 Y156.392 I-.126 J2.189 E.00723
G2 X26.493 Y156.486 I.103 J2.606 E.4884
; WIPE_START
M204 S3000
G1 X26.194 Y156.421 E-.05815
G1 X25.922 Y156.393 E-.05192
G1 X25.691 Y156.392 E-.0438
G1 X25.243 Y156.447 E-.08588
G1 X24.979 Y156.518 E-.0519
G1 X24.724 Y156.616 E-.05191
G1 X24.553 Y156.703 E-.03644
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.959 Y154.319 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X26.346 Y163.65 I-.169 J4.68 E.52263
G2 X26.019 Y154.322 I-.561 J-4.65 E.47113
M204 S10000
G1 X25.97 Y153.912 F36000
G1 F1473.913
M204 S3000
G2 X26.399 Y164.054 I-.179 J5.087 E.56805
G1 X26.582 Y164.03 E.00625
G2 X26.03 Y153.915 I-.804 J-5.029 E.5057
M204 S250
G1 X25.991 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.98 Y153.52 E.00036
G2 X24.927 Y153.583 I-.087 J7.429 E.03309
G2 X26.358 Y153.548 I.849 J5.417 E1.03524
G1 X26.051 Y153.526 E.00966
; WIPE_START
M204 S3000
G1 X25.98 Y153.52 E-.01358
G1 X25.498 Y153.523 E-.09148
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10906
G1 X24.082 Y153.795 E-.05676
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.961 Y154.668 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.806 Y155.246 E.02025
M204 S10000
G1 X25.158 Y155.3 F36000
G1 F1473.913
M204 S3000
G1 X24.663 Y154.811 E.02353
G1 X24.479 Y155.482 E.02353
M204 S10000
G1 X23.888 Y155.757 F36000
G1 F1473.913
M204 S3000
G1 X23.471 Y155.34 E.01998
; WIPE_START
G1 X23.888 Y155.757 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.108 Y155.345 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X27.165 Y154.891 I-2.446 J3.876 E.03548
G1 X27.05 Y155.465 E.01981
G1 X26.279 Y154.694 E.03692
G1 X26.518 Y154.732 E.00821
G1 X23.016 Y155.67 E.12272
G1 X23.205 Y155.517 E.0082
G1 X22.922 Y156.572 E.03696
G1 X22.536 Y156.132 E.01983
G2 X21.944 Y156.995 I3.706 J3.177 E.0355
M204 S10000
G1 X22.373 Y157.43 F36000
G1 F1473.913
M204 S3000
G3 X22.575 Y157.052 I1.897 J.772 E.01454
G1 X21.821 Y157.255 E.02643
G1 X21.855 Y157.178 E.00284
G1 X22.296 Y157.619 E.0211
G2 X22.072 Y158.451 I3.521 J1.39 E.02925
G1 X21.472 Y158.612 E.02105
G1 X21.48 Y158.53 E.00279
G1 X22.035 Y159.085 E.02653
G1 X22.046 Y158.653 E.01462
M204 S10000
G1 X21.455 Y158.815 F36000
G1 F1473.913
M204 S3000
G2 X21.54 Y159.858 I4.585 J.148 E.03551
G1 X22.091 Y159.672 E.01968
G1 X21.811 Y160.72 E.03671
G3 X21.718 Y160.495 I1.023 J-.555 E.00826
G1 X24.291 Y163.068 E.12317
G3 X24.061 Y162.976 I.393 J-1.314 E.00838
G1 X25.114 Y162.694 E.03691
G1 X24.927 Y163.245 E.01971
G2 X25.97 Y163.331 I.895 J-4.5 E.03551
M204 S10000
G1 X26.131 Y162.737 F36000
G1 F1473.913
M204 S3000
G3 X25.696 Y162.746 I-.25 J-1.645 E.01475
G1 X26.255 Y163.305 E.02675
G1 X26.173 Y163.314 E.00279
G1 X26.333 Y162.716 E.02094
G2 X27.169 Y162.492 I-3.421 J-14.439 E.02931
G1 X27.608 Y162.931 E.02103
G1 X27.545 Y162.964 E.00242
G1 X27.733 Y162.209 E.02633
G3 X27.355 Y162.409 I-1.137 J-1.689 E.01451
M204 S10000
G1 X27.79 Y162.839 F36000
G1 F1473.913
M204 S3000
G2 X28.654 Y162.25 I-2.136 J-4.059 E.03548
G1 X28.214 Y161.863 E.01982
G1 X29.268 Y161.581 E.03693
G1 X29.115 Y161.769 E.0082
G1 X30.055 Y158.261 E.12295
G3 X30.087 Y158.502 I-1.132 J.272 E.00826
G1 X29.321 Y157.735 E.03671
G1 X29.891 Y157.621 E.01968
G2 X29.443 Y156.675 I-4.337 J1.472 E.03551
M204 S10000
G1 X28.85 Y156.83 F36000
G1 F1473.913
M204 S3000
G1 X29.076 Y157.198 E.01461
G1 X29.279 Y156.441 E.02653
G1 X29.327 Y156.508 E.00279
G1 X28.727 Y156.668 E.02105
G2 X28.115 Y156.065 I-2.674 J2.096 E.02917
G1 X28.278 Y155.455 E.02134
G3 X28.351 Y155.505 I-.2 J.369 E.00296
G1 X27.591 Y155.709 E.02663
G3 X27.954 Y155.941 I-.7 J1.496 E.01463
; WIPE_START
G1 X27.591 Y155.709 E-.0819
G1 X28.351 Y155.505 E-.1495
G1 X28.278 Y155.455 E-.01661
G1 X28.115 Y156.065 E-.11981
G1 X28.161 Y156.11 E-.01218
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X30.116 Y158.825 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X29.534 Y158.981 E.02038
M204 S10000
G1 X29.486 Y159.628 F36000
G1 F1473.913
M204 S3000
G1 X29.974 Y160.122 E.02353
G1 X29.304 Y160.307 E.02353
M204 S10000
G1 X29.028 Y160.897 F36000
G1 F1473.913
M204 S3000
G1 X29.446 Y161.315 E.01998
; WIPE_START
G1 X29.028 Y160.897 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.772 Y162.836 Z5.2 F36000
G1 Z4.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X23.925 Y162.264 E.02001
M204 S10000
G1 X23.392 Y161.891 F36000
G1 F1473.913
M204 S3000
G1 X22.729 Y162.068 E.02321
G1 X22.894 Y161.394 E.02349
M204 S10000
G1 X22.525 Y160.859 F36000
G1 F1473.913
M204 S3000
G1 X21.946 Y161.014 E.0203
; CHANGE_LAYER
; Z_HEIGHT: 5
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X22.525 Y160.859 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L25
M991 S0 P24 ;notify layer change


M204 S10000
G17
G3 Z5.2 I1.217 J0 P1  F36000
; object ids of layer 25 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer25 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.118 Y93.519
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.074 Y93.535 E.00159
G2 X230.395 Y93.357 I1.14 J3.477 E.7328
G2 X230.059 Y93.356 I-.18 J3.184 E.01137
G2 X229.443 Y93.435 I.154 J3.656 E.02105
G1 X229.176 Y93.504 E.00934
M204 S10000
G1 X229.223 Y93.912 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.922 E.00087
G2 X230.373 Y93.764 I1.014 J3.09 E.65126
G2 X230.078 Y93.763 I-.159 J2.802 E.01
G2 X229.528 Y93.833 I.135 J3.249 E.01881
G1 X229.281 Y93.897 E.00862
M204 S250
G1 X229.324 Y94.29 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.32 Y94.295 E.00019
G2 X230.353 Y94.155 I.892 J2.715 E.53018
G2 X230.096 Y94.154 I-.139 J2.439 E.00804
G2 X229.609 Y94.216 I.116 J2.856 E.01542
G1 X229.382 Y94.275 E.00734
; WIPE_START
M204 S3000
G1 X229.32 Y94.295 E-.01236
G1 X229.04 Y94.399 E-.05684
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05688
G1 X228.181 Y94.989 E-.08528
G1 X227.889 Y95.33 E-.08527
G1 X227.813 Y95.447 E-.02647
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.694 Y92.57 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.625 E.00619
G2 X230.386 Y92.32 I1.675 J4.387 E.93431
G2 X229.712 Y92.34 I-.179 J5.086 E.02283
G2 X228.987 Y92.473 I.482 J4.671 E.02497
G1 X228.751 Y92.551 E.00843
M204 S10000
G1 X228.568 Y92.183 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.244 E.00691
G2 X230.396 Y91.913 I1.82 J4.768 E1.01548
G2 X229.67 Y91.936 I-.19 J5.512 E.02463
G2 X228.882 Y92.08 I.524 J5.076 E.02714
G1 X228.625 Y92.165 E.00915
M204 S250
G1 X228.447 Y91.811 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.233 Y91.879 E.00705
G2 X230.407 Y91.521 I1.962 J5.133 E1.01299
G2 X229.343 Y91.583 I-.099 J7.418 E.03343
G2 X228.78 Y91.702 I.852 J5.429 E.01804
G1 X228.504 Y91.792 E.00911
; WIPE_START
M204 S3000
G1 X228.233 Y91.879 E-.05409
G1 X227.968 Y91.99 E-.05468
G1 X227.455 Y92.252 E-.10934
G1 X226.972 Y92.565 E-.10931
G1 X226.757 Y92.739 E-.05258
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.92 Y93.036 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672882
G1 F952.44
M204 S3000
G2 X226.025 Y97.003 I1.282 J3.975 E.275
G1 X226.048 Y97.449 E.02335
G1 X226.115 Y97.872 E.02246
G1 X226.227 Y98.295 E.02291
G1 X226.31 Y98.527 E.01292
G2 X228.977 Y93.018 I3.892 J-1.516 E1.01495
; OBJECT_ID: 12
; WIPE_START
G1 X228.698 Y93.114 E-.05608
G1 X228.306 Y93.289 E-.08152
G1 X227.927 Y93.508 E-.08315
G1 X227.58 Y93.76 E-.08157
G1 X227.402 Y93.912 E-.04457
G1 X227.278 Y94.035 E-.03312
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.084 Y96.583 Z5.4 F36000
G1 X211.781 Y99.523 Z5.4
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.822 Y99.49 E.00177
G2 X208.982 Y93.121 I-3.033 J-2.465 E.29158
G2 X208.624 Y93.119 I-.192 J3.396 E.01212
G2 X211.547 Y99.794 I.164 J3.905 E.51376
G1 X211.742 Y99.568 E.0101
M204 S10000
G1 X211.479 Y99.251 F36000
G1 F1473.913
M204 S3000
G1 X211.505 Y99.234 E.00105
G2 X208.961 Y93.527 I-2.717 J-2.209 E.26125
G2 X208.643 Y93.526 I-.171 J3.014 E.01075
G2 X211.259 Y99.506 I.145 J3.499 E.46031
G1 X211.44 Y99.296 E.00938
M204 S250
G1 X211.188 Y98.989 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.2 Y98.986 E.00038
G2 X208.94 Y93.919 I-2.413 J-1.962 E.21492
G2 X208.662 Y93.918 I-.151 J2.652 E.00874
G2 X210.981 Y99.228 I.126 J3.107 E.37871
G1 X211.149 Y99.034 E.00804
; WIPE_START
M204 S3000
G1 X211.2 Y98.986 E-.01331
G1 X211.386 Y98.719 E-.06193
G1 X211.549 Y98.437 E-.06186
G1 X211.681 Y98.139 E-.06186
G1 X211.82 Y97.671 E-.09274
G1 X211.871 Y97.35 E-.06183
G1 X211.878 Y97.211 E-.02648
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.632 Y99.248 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.693 Y99.383 E.00501
G2 X208.961 Y92.32 I4.076 J-2.358 E.66103
G2 X208.285 Y92.341 I-.179 J5.101 E.02289
G2 X204.468 Y98.943 I.484 J4.684 E.30084
G1 X204.603 Y99.195 E.00968
M204 S10000
G1 X204.269 Y99.433 F36000
G1 F1473.913
M204 S3000
G1 X204.34 Y99.587 E.00574
G2 X208.971 Y91.913 I4.428 J-2.562 E.71833
G2 X208.243 Y91.936 I-.19 J5.531 E.02469
G2 X204.096 Y99.109 I.525 J5.089 E.32688
G1 X204.241 Y99.38 E.0104
M204 S250
G1 X203.918 Y99.611 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.154 Y100.027 E.01499
G2 X208.982 Y91.521 I4.616 J-3.004 E.70741
G2 X207.916 Y91.583 I-.099 J7.437 E.03351
G2 X203.865 Y99.528 I.854 J5.44 E.32587
G1 X203.886 Y99.561 E.00122
; WIPE_START
M204 S3000
G1 X204.154 Y100.027 E-.10224
G1 X204.496 Y100.492 E-.1096
G1 X204.882 Y100.92 E-.10958
G1 X205.091 Y101.119 E-.05479
G1 X205.107 Y101.131 E-.00379
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.938 Y98.981 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.436005
G1 F1526.387
M204 S3000
G2 X204.468 Y97.019 I3.839 J-1.957 E.81835
G1 X204.474 Y97.255 E.00771
G1 X204.52 Y97.693 E.01439
G1 X204.619 Y98.155 E.01542
G2 X204.911 Y98.928 I4.158 J-1.13 E.02705
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.0971
G1 X205.425 Y99.733 E-.08476
G1 X205.727 Y100.068 E-.08567
G1 X205.898 Y100.231 E-.04482
G1 X206.175 Y100.455 E-.06766
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.773 Y98.59 Z5.4 F36000
G1 X183.81 Y94.821 Z5.4
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.532 Y95.35 E.02027
G2 X187.759 Y92.902 I3.8 J1.689 E.70769
G2 X187.162 Y92.884 I-.438 J4.49 E.02024
G2 X183.846 Y94.772 I.17 J4.155 E.13419
M204 S10000
G1 X184.195 Y94.971 F36000
G1 F1473.913
M204 S3000
G1 X184.183 Y94.999 E.00103
M73 P79 R10
G2 X187.717 Y93.307 I3.148 J2.04 E.65832
G2 X187.181 Y93.291 I-.395 J4.039 E.01815
G2 X184.413 Y94.682 I.151 J3.748 E.10808
G1 X184.231 Y94.923 E.01024
M204 S250
G1 X184.512 Y95.201 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.514 Y95.214 E.00041
G2 X187.5 Y93.684 I2.821 J1.825 E.55164
G2 X187.199 Y93.682 I-.163 J2.862 E.00944
G2 X184.72 Y94.93 I.136 J3.357 E.08971
G1 X184.548 Y95.154 E.00884
; WIPE_START
M204 S3000
G1 X184.514 Y95.214 E-.01319
G1 X184.255 Y95.673 E-.10007
G1 X184.129 Y96.001 E-.06683
G1 X184.037 Y96.342 E-.06707
G1 X183.983 Y96.688 E-.06656
G1 X183.964 Y97.036 E-.06627
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.508 Y92.32 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.83 Y92.341 I-.18 J5.118 E.02296
G2 X187.568 Y92.322 I.485 J4.699 E.97965
M204 S10000
G1 X187.519 Y91.913 F36000
G1 F1473.913
M204 S3000
G2 X186.788 Y91.936 I-.191 J5.546 E.02476
G2 X187.579 Y91.915 I.527 J5.103 E1.06437
M204 S250
G1 X187.533 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.529 Y91.521 E.00012
G2 X186.46 Y91.583 I-.099 J7.456 E.03359
G2 X187.901 Y91.548 I.856 J5.456 E1.04264
G1 X187.592 Y91.525 E.00972
; WIPE_START
M204 S3000
G1 X187.529 Y91.521 E-.0121
G1 X187.035 Y91.523 E-.09376
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10985
G1 X185.622 Y91.792 E-.0544
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.536 Y92.608 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.20065
G1 F3803.97
M204 S3000
G1 X187.324 Y92.598 E.00278
G2 X182.882 Y97.039 I-.001 J4.441 E.0915
G1 X182.907 Y97.504 E.0061
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.0061
G1 X183.181 Y98.641 E.00321
G2 X187.787 Y92.622 I4.142 J-1.601 E.24691
G1 X187.596 Y92.612 E.00251
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.598 E-.05162
G1 X186.86 Y92.622 E-.08832
G1 X186.403 Y92.694 E-.08797
G1 X186.173 Y92.749 E-.04497
G1 X185.732 Y92.892 E-.08797
G1 X185.64 Y92.933 E-.01915
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.01 Y93.138 Z5.4 F36000
G1 X163.186 Y93.536 Z5.4
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.07 Y93.633 E.00514
G2 X166.301 Y92.67 I2.779 J3.422 E.82044
G2 X165.669 Y92.65 I-.464 J4.758 E.02144
G2 X163.252 Y93.492 I.18 J4.405 E.0879
G1 X163.236 Y93.503 E.00064
M204 S10000
G1 X163.421 Y93.875 F36000
G1 F1473.913
M204 S3000
G1 X163.015 Y94.23 E.01824
G2 X166.259 Y93.075 I2.833 J2.825 E.7305
G2 X165.688 Y93.057 I-.421 J4.308 E.01935
G2 X163.491 Y93.822 I.16 J3.998 E.07989
G1 X163.468 Y93.839 E.00096
M204 S250
G1 X163.674 Y94.172 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.292 Y94.507 E.01593
G2 X166.218 Y93.465 I2.556 J2.548 E.61036
G2 X165.706 Y93.449 I-.379 J3.881 E.01606
G2 X163.723 Y94.137 I.142 J3.606 E.06678
; WIPE_START
M204 S3000
G1 X163.292 Y94.507 E-.10789
G1 X162.92 Y94.933 E-.10756
G1 X162.714 Y95.25 E-.0718
M73 P79 R9
G1 X162.543 Y95.587 E-.0718
G1 X162.503 Y95.69 E-.02096
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.483 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.025 Y92.32 I1.691 J-4.428 E.55604
G2 X165.345 Y92.341 I-.18 J5.137 E.02304
G2 X164.085 Y101.461 I.487 J4.715 E.42693
M204 S10000
G1 X163.995 Y101.864 F36000
G1 F1473.913
M204 S3000
G2 X166.035 Y91.913 I1.836 J-4.808 E.60394
G2 X165.302 Y91.936 I-.191 J5.562 E.02484
G2 X163.939 Y101.842 I.528 J5.12 E.46382
M204 S250
G1 X163.839 Y102.22 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.855 Y102.229 E.00054
G2 X166.046 Y91.521 I1.978 J-5.173 E.60229
G2 X164.974 Y91.584 I-.099 J7.48 E.03369
G2 X163.324 Y101.993 I.859 J5.472 E.43693
G1 X163.785 Y102.196 E.01576
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.855 Y102.229 E-.01467
G1 X164.407 Y102.406 E-.11022
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.734 Y102.587 E-.03474
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.95 Y106.085 Z5.4 F36000
G1 X47.364 Y163.613 Z5.4
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.611 E.00072
G2 X47.323 Y154.319 I-.252 J-4.644 E.47965
G2 X46.655 Y154.34 I-.177 J5.041 E.02262
G2 X46.898 Y163.612 I.478 J4.626 E.47043
G1 X47.304 Y163.613 E.01372
M204 S10000
G1 X47.364 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.017 E.00144
G2 X47.333 Y153.913 I-.274 J-5.051 E.52177
G2 X46.613 Y153.935 I-.188 J5.467 E.02442
G2 X46.877 Y164.018 I.519 J5.031 E.51164
G1 X47.304 Y164.019 E.01444
M204 S250
G1 X47.364 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00198
G2 X47.344 Y153.521 I-.296 J-5.443 E.52095
G2 X46.572 Y153.545 I-.199 J5.884 E.02423
G2 X46.857 Y164.411 I.559 J5.422 E.51075
G1 X47.304 Y164.411 E.01402
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.02338
G1 X47.994 Y164.351 E-.10845
G1 X48.553 Y164.233 E-.10842
G1 X48.826 Y164.152 E-.0542
G1 X49.246 Y163.99 E-.08555
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.184 Y163.264 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X46.153 Y163.15 I-.036 J-4.387 E.03519
G1 X48.378 Y154.849 E.2909
G3 X49.33 Y155.264 I-4.486 J11.596 E.03518
; WIPE_START
G1 X48.378 Y154.849 E-.19744
G1 X48.129 Y155.777 E-.18256
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.844 Y156.778 Z5.4 F36000
G1 Z5
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X51.262 Y157.73 I-12.95 J6.253 E.0352
G1 X42.958 Y159.955 E.291
G3 X42.844 Y158.924 I4.274 J-.995 E.03519
M204 S10000
G1 X42.923 Y158.146 F36000
G1 F1473.913
M204 S3000
G3 X43.146 Y157.376 I4.933 J1.012 E.02717
G1 X49.803 Y155.592 E.2333
G2 X49.501 Y155.375 I-1.185 J1.328 E.01262
G1 X47.388 Y163.262 E.27639
G1 X47.762 Y163.223 E.01274
G1 X42.886 Y158.346 E.23343
G1 X42.846 Y158.721 E.01274
G1 X50.734 Y156.607 E.27639
G2 X50.516 Y156.305 I-1.546 J.883 E.01262
G1 X48.732 Y162.965 E.23338
G2 X49.073 Y162.806 I-.84 J-2.248 E.01275
G1 X43.299 Y157.032 E.27639
G3 X43.877 Y156.17 I6.016 J3.407 E.03517
M204 S10000
G1 X44.571 Y155.523 F36000
G1 F1473.913
M204 S3000
G2 X44.361 Y155.684 I.919 J1.413 E.00895
G1 X43.093 Y160.416 E.16582
G3 X43.025 Y160.213 I1.381 J-.574 E.00724
G1 X45.892 Y163.079 E.13721
G1 X45.694 Y163.015 E.00704
G1 X50.418 Y161.749 E.16557
G3 X50.28 Y161.906 I-.818 J-.582 E.00712
G1 X51.328 Y157.993 E.13713
G1 X51.371 Y158.197 E.00704
G1 X47.913 Y154.738 E.16557
G3 X48.118 Y154.78 I-.095 J.999 E.00712
G1 X44.202 Y155.829 E.13724
G1 X44.012 Y156.019 E.00909
G1 X50.09 Y162.096 E.29093
G3 X49.254 Y162.714 I-7.787 J-9.666 E.03519
; WIPE_START
G1 X50.09 Y162.096 E-.19744
G1 X49.41 Y161.417 E-.18256
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.417 Y154.727 Z5.4 F36000
G1 Z5
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X47.162 Y154.668 I.78 J5.111 E.02533
G1 X45.009 Y162.703 E.28157
G3 X44.394 Y162.272 I2.933 J-4.829 E.02546
M204 S10000
G1 X43.837 Y161.715 F36000
G1 F1473.913
M204 S3000
G3 X43.405 Y161.1 I4.357 J-3.518 E.02545
G1 X51.439 Y158.947 E.28153
G3 X51.339 Y159.891 I-4.313 J.019 E.0322
G1 X46.217 Y154.77 E.24515
G2 X45.843 Y154.87 I.29 J1.829 E.01313
G1 X43.968 Y161.87 E.24532
G1 X44.238 Y162.141 E.01294
G1 X51.238 Y160.265 E.24532
G3 X50.857 Y161.136 I-6.818 J-2.466 E.03222
G1 X44.976 Y155.255 E.28153
G3 X45.65 Y154.933 I2.494 J4.354 E.02532
; OBJECT_ID: 14
; WIPE_START
G1 X44.976 Y155.255 E-.14197
G1 X45.862 Y156.141 E-.23803
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X38.231 Y155.963 Z5.4 F36000
G1 X26.596 Y155.692 Z5.4
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.319 Y155.631 E.00962
G2 X25.964 Y155.595 I-.524 J3.369 E.01207
G2 X25.65 Y155.594 I-.168 J2.971 E.01062
G2 X26.668 Y155.705 I.144 J3.406 E.69022
G1 X26.655 Y155.702 E.00045
M204 S10000
G1 X26.512 Y156.089 F36000
G1 F1473.913
M204 S3000
G1 X26.255 Y156.034 E.00889
G2 X25.942 Y156.002 I-.461 J2.964 E.01064
G2 X25.669 Y156.001 I-.147 J2.589 E.00925
G2 X26.571 Y156.1 I.125 J2.997 E.60722
M204 S250
G1 X26.43 Y156.474 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.446 E.00332
G2 X25.922 Y156.393 I-.535 J2.553 E.01286
G2 X25.688 Y156.392 I-.127 J2.226 E.00735
G2 X26.592 Y156.516 I.106 J2.606 E.48503
G1 X26.488 Y156.489 E.00337
; WIPE_START
M204 S3000
G1 X26.328 Y156.446 E-.03149
G1 X25.922 Y156.393 E-.07784
G1 X25.688 Y156.392 E-.04449
G1 X25.243 Y156.447 E-.08517
G1 X24.979 Y156.518 E-.05191
G1 X24.724 Y156.616 E-.05191
G1 X24.552 Y156.709 E-.03718
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.967 Y154.32 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X26.337 Y163.651 I-.177 J4.68 E.52263
G2 X26.027 Y154.322 I-.558 J-4.651 E.47083
M204 S10000
G1 X25.978 Y153.913 F36000
G1 F1473.913
M204 S3000
G2 X25.253 Y153.935 I-.189 J5.505 E.02457
G2 X26.038 Y153.915 I.523 J5.065 E1.05623
M204 S250
M73 P80 R9
G1 X25.996 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.988 Y153.521 E.00024
G2 X25.212 Y153.545 I-.2 J5.918 E.02438
G2 X26.358 Y153.548 I.562 J5.455 E1.04433
G1 X26.056 Y153.526 E.0095
; WIPE_START
M204 S3000
G1 X25.988 Y153.521 E-.01288
G1 X25.498 Y153.523 E-.0931
G1 X25.212 Y153.545 E-.0546
G1 X24.645 Y153.635 E-.10907
G1 X24.09 Y153.784 E-.10908
G1 X24.084 Y153.786 E-.00127
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.628 Y154.749 Z5.4 F36000
G1 Z5
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.517 Y154.731 E.00382
G1 X27.407 Y155.622 E.04264
G2 X26.88 Y155.409 I-1.071 J1.898 E.01929
G1 X27.03 Y154.85 E.0196
G1 X26.826 Y154.796 E.00715
G1 X22.782 Y155.879 E.14172
G1 X22.633 Y156.028 E.00714
G1 X23.041 Y156.437 E.01955
G2 X22.697 Y156.864 I3.438 J3.116 E.01857
G1 X23.018 Y155.669 E.04188
G1 X22.93 Y155.74 E.00382
M204 S10000
G1 X22.497 Y156.18 F36000
G1 F1473.913
M204 S3000
G2 X21.919 Y157.042 I3.664 J3.083 E.0352
G1 X22.351 Y157.474 E.0207
G1 X22.478 Y157.225 E.00945
G1 X21.748 Y157.42 E.02557
G2 X21.499 Y158.349 I26.184 J7.507 E.03255
G1 X22.04 Y158.89 E.02587
G3 X22.048 Y158.604 I1.078 J-.111 E.00969
G1 X21.456 Y158.763 E.02076
G2 X21.528 Y159.798 I14.127 J-.46 E.03511
M204 S10000
G1 X21.684 Y160.392 F36000
G1 F1473.913
M204 S3000
G1 X21.721 Y160.507 E.00407
G1 X22.044 Y159.304 E.04213
G2 X22.128 Y159.847 I2.626 J-.133 E.01863
G1 X21.57 Y159.997 E.01957
G2 X21.621 Y160.198 I.985 J-.144 E.00706
G1 X24.587 Y163.164 E.14196
G2 X24.788 Y163.215 I.345 J-.932 E.00706
G1 X24.938 Y162.658 E.01952
G2 X25.485 Y162.741 I.887 J-4.037 E.01875
G1 X24.279 Y163.064 E.04228
G1 X24.393 Y163.101 E.00407
M204 S10000
G1 X24.988 Y163.258 F36000
G1 F1473.913
M204 S3000
G2 X26.022 Y163.329 I1.495 J-14.05 E.03511
G1 X26.182 Y162.732 E.02094
G3 X25.901 Y162.752 I-.215 J-1.058 E.00956
G1 X26.436 Y163.286 E.02558
G2 X27.365 Y163.038 I-7.663 J-30.608 E.03253
G1 X27.56 Y162.308 E.02559
G3 X27.31 Y162.433 I-1.012 J-1.721 E.00948
G1 X27.741 Y162.864 E.02064
G2 X28.606 Y162.289 I-2.013 J-3.963 E.03524
M204 S10000
G1 X29.045 Y161.855 F36000
G1 F1473.913
M204 S3000
G1 X29.116 Y161.768 E.00382
G1 X27.921 Y162.088 E.04188
G2 X28.349 Y161.744 I-2.685 J-3.778 E.01857
G1 X28.757 Y162.153 E.01955
G1 X28.906 Y162.004 E.00715
G1 X29.991 Y157.956 E.14184
G2 X29.938 Y157.755 I-1.305 J.234 E.00705
G1 X29.376 Y157.905 E.0197
G2 X29.178 Y157.393 I-2.543 J.687 E.01864
G1 X30.058 Y158.273 E.04213
G1 X30.033 Y158.155 E.00407
M204 S10000
G1 X29.872 Y157.562 F36000
G1 F1473.913
M204 S3000
G2 X29.411 Y156.632 I-4.184 J1.494 E.03524
G1 X28.819 Y156.79 E.02074
G3 X28.977 Y157.022 I-1.023 J.868 E.0095
G1 X29.17 Y156.299 E.02532
G2 X28.486 Y155.615 I-3.397 J2.713 E.03281
G1 X27.762 Y155.809 E.02537
G1 X27.997 Y155.961 E.00945
G1 X28.154 Y155.374 E.02056
G2 X27.223 Y154.913 I-2.426 J3.725 E.03524
; WIPE_START
G1 X28.154 Y155.374 E-.19734
G1 X27.997 Y155.961 E-.11544
G1 X27.762 Y155.809 E-.05307
G1 X27.834 Y155.79 E-.01415
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.032 Y154.733 Z5.4 F36000
G1 Z5
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X25.814 Y154.668 I.795 J4.872 E.02659
G1 X25.66 Y155.246 E.02024
M204 S10000
G1 X25.331 Y155.272 F36000
G1 F1473.913
M204 S3000
G1 X24.833 Y154.775 E.0238
G2 X24.497 Y154.865 I.26 J1.644 E.01179
G1 X24.315 Y155.544 E.0238
M204 S10000
G1 X24.019 Y155.688 F36000
G1 F1473.913
M204 S3000
G1 X23.592 Y155.261 E.02044
G3 X24.304 Y154.928 I4.969 J9.7 E.0266
; WIPE_START
G1 X23.592 Y155.261 E-.21486
G1 X24.019 Y155.688 E-.16514
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.469 Y161.786 Z5.4 F36000
G1 Z5
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.016 Y161.142 I4.231 J-3.455 E.02669
G1 X22.6 Y160.985 E.02044
M204 S10000
G1 X22.784 Y161.258 F36000
G1 F1473.913
M204 S3000
G1 X22.601 Y161.941 E.02392
G1 X22.845 Y162.184 E.01165
G1 X23.527 Y162.001 E.02392
M204 S10000
G1 X23.8 Y162.186 F36000
G1 F1473.913
M204 S3000
G1 X23.644 Y162.769 E.02045
G3 X22.999 Y162.316 I2.843 J-4.729 E.02669
; WIPE_START
G1 X23.644 Y162.769 E-.21508
G1 X23.8 Y162.186 E-.16492
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.857 Y160.482 Z5.4 F36000
G1 Z5
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X29.525 Y161.193 I-10.147 J-4.31 E.0266
G1 X29.097 Y160.766 E.02044
M204 S10000
G1 X29.241 Y160.47 F36000
G1 F1473.913
M204 S3000
G1 X29.92 Y160.288 E.0238
G2 X30.01 Y159.952 I-1.552 J-.596 E.01179
G1 X29.513 Y159.455 E.0238
M204 S10000
G1 X29.53 Y159.128 F36000
G1 F1473.913
M204 S3000
G1 X30.116 Y158.971 E.02051
G3 X30.053 Y159.753 I-4.804 J.004 E.02657
; CHANGE_LAYER
; Z_HEIGHT: 5.2
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X30.116 Y158.971 E-.21435
G1 X29.53 Y159.128 E-.16565
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L26
M991 S0 P25 ;notify layer change


M204 S10000
G17
G3 Z5.4 I1.217 J0 P1  F36000
; object ids of layer 26 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer26 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.116 Y93.52
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.074 Y93.534 E.00152
G2 X230.395 Y93.357 I1.139 J3.477 E.73281
G2 X230.055 Y93.356 I-.181 J3.223 E.01152
G2 X229.443 Y93.434 I.158 J3.656 E.02089
G1 X229.174 Y93.504 E.00941
M204 S10000
G1 X229.221 Y93.912 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.922 E.0008
G2 X230.373 Y93.764 I1.013 J3.088 E.65084
G2 X230.074 Y93.763 I-.16 J2.84 E.01015
G2 X229.528 Y93.833 I.138 J3.247 E.01866
G1 X229.279 Y93.897 E.00869
M204 S250
G1 X229.322 Y94.291 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.32 Y94.294 E.00014
G2 X230.353 Y94.155 I.891 J2.715 E.53018
G2 X230.092 Y94.154 I-.14 J2.477 E.00817
G2 X229.609 Y94.216 I.119 J2.855 E.01529
G1 X229.38 Y94.276 E.0074
; WIPE_START
M204 S3000
G1 X229.32 Y94.294 E-.01198
G1 X229.04 Y94.399 E-.05687
G1 X228.773 Y94.535 E-.05686
G1 X228.522 Y94.698 E-.05691
G1 X228.181 Y94.989 E-.08525
G1 X227.98 Y95.212 E-.05688
G1 X227.809 Y95.447 E-.05526
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.729 Y92.559 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.625 E.00744
G2 X230.394 Y92.32 I1.676 J4.386 E.93392
G2 X229.712 Y92.34 I-.186 J5.107 E.02312
G2 X228.987 Y92.474 I.483 J4.671 E.02497
G1 X228.786 Y92.54 E.00719
M204 S10000
G1 X228.611 Y92.163 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.244 E.0085
G2 X230.405 Y91.913 I1.821 J4.767 E1.0152
G2 X229.67 Y91.936 I-.197 J5.532 E.02492
G2 X228.667 Y92.142 I.525 J5.076 E.03472
M204 S250
G1 X228.48 Y91.794 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X227.967 Y91.988 E.0172
G2 X230.415 Y91.521 I2.226 J5.024 E1.00378
G2 X229.629 Y91.545 I-.208 J5.947 E.02469
G2 X228.535 Y91.772 I.564 J5.466 E.03507
; WIPE_START
M204 S3000
G1 X227.967 Y91.988 E-.11557
G1 X227.708 Y92.114 E-.05476
G1 X227.21 Y92.402 E-.1093
G1 X226.782 Y92.713 E-.10037
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.945 Y93.033 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672807
G1 F952.552
M204 S3000
G1 X228.706 Y93.112 E.01317
G2 X226.025 Y97.012 I1.498 J3.902 E.26346
G1 X226.075 Y97.657 E.0339
G1 X226.17 Y98.101 E.02379
G1 X226.386 Y98.711 E.03389
G1 X226.699 Y99.287 E.03436
G1 X227.098 Y99.807 E.03432
G1 X227.568 Y100.253 E.03393
G1 X228.107 Y100.626 E.03433
G1 X228.511 Y100.832 E.02376
G1 X229.122 Y101.047 E.03392
G1 X229.766 Y101.167 E.03432
G1 X230.421 Y101.184 E.03433
G1 X231.064 Y101.1 E.03393
G1 X231.502 Y100.983 E.02376
G1 X232.107 Y100.73 E.03435
G1 X232.659 Y100.392 E.0339
G1 X233.151 Y99.972 E.03391
G1 X233.578 Y99.474 E.03435
G1 X233.825 Y99.093 E.02375
G1 X234.104 Y98.509 E.03389
G1 X234.29 Y97.881 E.03433
G1 X234.375 Y97.23 E.03438
G1 X234.359 Y96.583 E.03389
G1 X234.288 Y96.135 E.02377
G1 X234.104 Y95.514 E.0339
G1 X233.821 Y94.922 E.03434
G1 X233.455 Y94.389 E.03388
G1 X233.151 Y94.051 E.02379
G1 X232.659 Y93.631 E.03391
G1 X232.1 Y93.289 E.03432
G1 X231.502 Y93.041 E.03391
G1 X230.865 Y92.886 E.03436
G1 X230.414 Y92.84 E.02374
G2 X229.122 Y92.977 I-.209 J4.174 E.06829
G1 X229.002 Y93.015 E.0066
; OBJECT_ID: 12
; WIPE_START
G1 X228.706 Y93.112 E-.05919
G1 X228.306 Y93.289 E-.08313
G1 X227.928 Y93.507 E-.08302
G1 X227.574 Y93.765 E-.08312
G1 X227.294 Y94.016 E-.07153
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.102 Y96.571 Z5.6 F36000
G1 X211.776 Y99.529 Z5.6
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.822 Y99.49 E.00202
G2 X208.982 Y93.121 I-3.034 J-2.465 E.29153
G2 X208.619 Y93.119 I-.193 J3.439 E.01229
G2 X211.547 Y99.794 I.169 J3.905 E.51364
G1 X211.737 Y99.574 E.00985
M204 S10000
G1 X211.474 Y99.256 F36000
G1 F1473.913
M204 S3000
G1 X211.505 Y99.233 E.0013
G2 X208.961 Y93.527 I-2.718 J-2.208 E.2612
G2 X208.639 Y93.526 I-.172 J3.057 E.01091
G2 X211.258 Y99.506 I.149 J3.499 E.4602
G1 X211.435 Y99.302 E.00913
M204 S250
G1 X211.183 Y98.994 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.197 Y98.984 E.00055
G2 X208.94 Y93.919 I-2.411 J-1.961 E.2148
G2 X208.657 Y93.918 I-.152 J2.693 E.00888
G2 X210.979 Y99.226 I.13 J3.105 E.37834
G1 X211.143 Y99.039 E.0078
; WIPE_START
M204 S3000
G1 X211.197 Y98.984 E-.01465
G1 X211.386 Y98.719 E-.06188
G1 X211.619 Y98.29 E-.09274
G1 X211.721 Y98.026 E-.05379
G1 X211.82 Y97.671 E-.0699
G1 X211.871 Y97.35 E-.06184
G1 X211.877 Y97.217 E-.0252
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.611 Y99.218 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.694 Y99.382 E.00622
G2 X208.969 Y92.32 I4.076 J-2.358 E.66074
G2 X208.285 Y92.341 I-.187 J5.118 E.02319
G2 X204.576 Y99.166 I.485 J4.684 E.30917
G1 X204.578 Y99.168 E.00011
M204 S10000
G1 X204.263 Y99.419 F36000
G1 F1473.913
M204 S3000
G1 X204.34 Y99.586 E.00624
G2 X208.98 Y91.913 I4.428 J-2.562 E.71804
G2 X208.243 Y91.936 I-.198 J5.546 E.02498
G2 X204.096 Y99.109 I.526 J5.089 E.32684
G1 X204.234 Y99.367 E.0099
M204 S250
G1 X203.914 Y99.597 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204 Y99.783 E.00642
G2 X208.99 Y91.521 I4.767 J-2.759 E.71624
G2 X208.202 Y91.546 I-.209 J5.959 E.02475
G2 X203.737 Y99.268 I.566 J5.479 E.32598
G1 X203.885 Y99.544 E.00982
; WIPE_START
M204 S3000
G1 X204 Y99.783 E-.05029
G1 X204.32 Y100.263 E-.10963
G1 X204.683 Y100.711 E-.10963
G1 X205.091 Y101.119 E-.10952
G1 X205.095 Y101.122 E-.00093
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.945 Y98.97 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435972
G1 F1526.518
M204 S3000
G1 X205.16 Y99.367 E.01479
G1 X205.432 Y99.741 E.01508
G1 X205.894 Y100.227 E.02193
G1 X206.426 Y100.636 E.02193
G1 X206.825 Y100.867 E.01507
G2 X204.468 Y97.025 I1.951 J-3.842 E.72981
G1 X204.52 Y97.694 E.02193
G1 X204.616 Y98.145 E.01509
G1 X204.84 Y98.777 E.02193
G1 X204.916 Y98.917 E.00519
; OBJECT_ID: 11
; WIPE_START
G1 X205.16 Y99.367 E-.09736
G1 X205.432 Y99.741 E-.08767
G1 X205.894 Y100.227 E-.1275
G1 X206.175 Y100.444 E-.06747
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.781 Y98.552 Z5.6 F36000
G1 X183.864 Y94.736 Z5.6
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.844 Y94.779 E.00162
G2 X187.542 Y92.885 I3.491 J2.26 E.73726
G2 X187.157 Y92.884 I-.205 J3.653 E.01306
G2 X184.099 Y94.427 I.179 J4.155 E.11948
G1 X183.9 Y94.688 E.0111
M204 S10000
G1 X184.193 Y94.975 F36000
G1 F1473.913
M204 S3000
G1 X184.185 Y95.001 E.00092
G2 X187.521 Y93.292 I3.15 J2.039 E.66509
G2 X187.176 Y93.291 I-.184 J3.27 E.01168
G2 X184.415 Y94.683 I.159 J3.748 E.10787
G1 X184.229 Y94.927 E.01038
M204 S250
G1 X184.509 Y95.205 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.514 Y95.214 E.00031
G2 X187.5 Y93.684 I2.82 J1.825 E.55169
G2 X187.194 Y93.683 I-.164 J2.907 E.00959
G2 X184.719 Y94.93 I.14 J3.357 E.08957
G1 X184.546 Y95.157 E.00897
; WIPE_START
M204 S3000
G1 X184.514 Y95.214 E-.01239
G1 X184.311 Y95.555 E-.07546
G1 X184.187 Y95.835 E-.0581
G1 X184.038 Y96.341 E-.10019
G1 X183.983 Y96.688 E-.0668
G1 X183.964 Y97.039 E-.06683
G1 X183.964 Y97.04 E-.00022
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.516 Y92.32 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.83 Y92.341 I-.187 J5.139 E.02325
G2 X187.576 Y92.323 I.486 J4.698 E.97926
M204 S10000
G1 X187.527 Y91.913 F36000
G1 F1473.913
M204 S3000
G2 X186.788 Y91.936 I-.198 J5.565 E.02505
G2 X187.587 Y91.916 I.527 J5.104 E1.06415
M204 S250
G1 X187.537 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
M73 P81 R9
G1 F1500
M204 S1000
G2 X186.747 Y91.546 I-.209 J5.98 E.02482
G2 X187.597 Y91.524 I.567 J5.494 E1.06136
; WIPE_START
M204 S3000
G1 X187.035 Y91.523 E-.10678
G1 X186.747 Y91.546 E-.05499
G1 X186.176 Y91.636 E-.10985
G1 X185.625 Y91.784 E-.10838
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.541 Y92.609 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200617
G1 F3804.767
M204 S3000
G1 X187.324 Y92.598 E.00284
G2 X182.882 Y97.039 I-.001 J4.441 E.09148
G1 X182.907 Y97.504 E.0061
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.0061
G1 X183.181 Y98.64 E.0032
G2 X187.787 Y92.622 I4.143 J-1.601 E.24687
G1 X187.6 Y92.612 E.00244
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.598 E-.05258
G1 X186.86 Y92.622 E-.08832
G1 X186.401 Y92.694 E-.08834
G1 X185.953 Y92.814 E-.08796
G1 X185.731 Y92.893 E-.04488
G1 X185.645 Y92.931 E-.01791
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.015 Y93.138 Z5.6 F36000
G1 X163.183 Y93.539 Z5.6
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.069 Y93.633 E.00499
G2 X166.301 Y92.67 I2.779 J3.422 E.82044
G2 X165.663 Y92.65 I-.465 J4.773 E.02163
G2 X163.252 Y93.492 I.185 J4.405 E.08772
G1 X163.232 Y93.505 E.00079
M204 S10000
G1 X163.417 Y93.878 F36000
G1 F1473.913
M204 S3000
G1 X163.015 Y94.229 E.01809
G2 X166.259 Y93.075 I2.833 J2.826 E.7305
G2 X165.683 Y93.057 I-.422 J4.322 E.01953
G2 X163.491 Y93.821 I.165 J3.998 E.07971
G1 X163.465 Y93.841 E.00112
M204 S250
G1 X163.671 Y94.175 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.294 Y94.508 E.01578
G2 X166.029 Y93.45 I2.558 J2.547 E.61633
G2 X165.701 Y93.449 I-.176 J3.127 E.0103
G2 X163.722 Y94.14 I.15 J3.606 E.06668
G1 X163.721 Y94.141 E.00007
; WIPE_START
M204 S3000
G1 X163.294 Y94.508 E-.10697
G1 X162.92 Y94.933 E-.10753
G1 X162.714 Y95.25 E-.0718
G1 X162.543 Y95.587 E-.0718
G1 X162.501 Y95.694 E-.02191
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.482 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.033 Y92.32 I1.692 J-4.427 E.55574
G2 X165.345 Y92.341 I-.188 J5.155 E.02333
G2 X164.085 Y101.46 I.488 J4.714 E.42685
M204 S10000
G1 X163.995 Y101.862 F36000
G1 F1473.913
M204 S3000
G2 X166.044 Y91.913 I1.836 J-4.808 E.60363
G2 X165.302 Y91.936 I-.199 J5.581 E.02513
G2 X163.939 Y101.841 I.529 J5.119 E.46373
M204 S250
G1 X163.843 Y102.222 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.854 Y102.229 E.00041
G2 X166.054 Y91.521 I1.976 J-5.174 E.60188
G2 X165.261 Y91.546 I-.21 J5.996 E.02489
G2 X163.324 Y101.994 I.569 J5.509 E.44614
G1 X163.789 Y102.198 E.0159
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.854 Y102.229 E-.01385
G1 X164.407 Y102.406 E-.11022
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
M73 P81 R8
G1 X165.738 Y102.587 E-.03556
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.954 Y106.085 Z5.6 F36000
G1 X47.369 Y163.613 Z5.6
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.385 Y163.606 E.00056
G2 X47.331 Y154.32 I-.25 J-4.642 E.47917
G2 X46.655 Y154.34 I-.184 J5.061 E.0229
G2 X46.899 Y163.607 I.479 J4.624 E.47012
G1 X47.309 Y163.612 E.0139
M204 S10000
G1 X47.369 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00124
G2 X47.342 Y153.913 I-.273 J-5.051 E.5216
G2 X46.613 Y153.935 I-.196 J5.487 E.0247
G2 X46.877 Y164.019 I.52 J5.032 E.51164
G1 X47.309 Y164.019 E.01464
M204 S250
G1 X47.369 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.0018
G2 X47.352 Y153.521 I-.295 J-5.443 E.52074
G2 X46.572 Y153.545 I-.206 J5.902 E.02449
G2 X46.857 Y164.411 I.56 J5.422 E.5107
G1 X47.309 Y164.411 E.0142
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.02228
G1 X47.994 Y164.351 E-.10844
G1 X48.553 Y164.233 E-.10842
G1 X48.826 Y164.152 E-.05422
G1 X49.252 Y163.988 E-.08663
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.491 Y163.22 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X46.165 Y163.153 I.154 J-1.578 E.01128
G1 X42.956 Y159.943 E.15363
G2 X42.989 Y160.093 I.863 J-.11 E.0052
G1 X51.301 Y157.866 E.2913
G1 X51.317 Y157.943 E.00265
G1 X48.167 Y154.793 E.15079
G1 X48.241 Y154.812 E.00258
G1 X46.015 Y163.12 E.29111
G1 X45.941 Y163.095 E.00265
G1 X50.244 Y161.942 E.15079
G1 X50.19 Y161.996 E.00258
G1 X44.112 Y155.919 E.29093
G1 X44.166 Y155.865 E.00258
G1 X43.012 Y160.171 E.1509
G2 X43.127 Y160.502 I2.34 J-.624 E.01187
; WIPE_START
G1 X43.012 Y160.171 E-.06655
G1 X43.439 Y158.578 E-.31345
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.99 Y161.893 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X44.365 Y162.253 I2.481 J-2.205 E.01764
G1 X51.186 Y160.425 E.23904
G3 X50.927 Y161.006 I-4.859 J-1.825 E.02154
G1 X45.101 Y155.18 E.27887
G3 X45.683 Y154.922 I2.617 J5.112 E.02156
G1 X43.857 Y161.739 E.23888
G3 X43.484 Y161.225 I2.26 J-2.031 E.02153
G1 X51.439 Y159.093 E.27877
G3 X51.374 Y159.726 I-5.195 J-.217 E.02154
G1 X46.382 Y154.735 E.23893
G3 X47.015 Y154.669 I.863 J5.233 E.02155
G1 X44.883 Y162.625 E.27881
G2 X45.516 Y162.947 I1.849 J-2.851 E.02408
; WIPE_START
G1 X44.883 Y162.625 E-.13492
G1 X45.217 Y161.379 E-.24508
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.839 Y162.312 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X50.08 Y162.107 I-.859 J-1.247 E.01073
G1 X51.255 Y157.72 E.15373
G2 X51.15 Y157.404 I-1.551 J.341 E.01128
; WIPE_START
G1 X51.255 Y157.72 E-.06321
G1 X50.823 Y159.33 E-.31679
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.69 Y154.958 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X48.392 Y154.853 I-.65 J1.367 E.01073
G1 X44.002 Y156.029 E.15382
G2 X43.796 Y156.269 I1.04 J1.099 E.01073
; WIPE_START
G1 X44.002 Y156.029 E-.06014
G1 X45.628 Y155.593 E-.31986
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.156 Y157.347 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X43.37 Y156.903 I2.919 J1.135 E.01669
G1 X49.207 Y162.741 E.27943
G3 X48.57 Y163.021 I-2.523 J-4.867 E.02358
G1 X50.406 Y156.169 E.24011
G2 X49.939 Y155.702 I-3.724 J3.257 E.02237
G1 X43.087 Y157.538 E.24011
G2 X42.916 Y158.177 I2.951 J1.133 E.02241
G1 X47.932 Y163.192 E.2401
G3 X47.241 Y163.264 I-.832 J-4.636 E.02354
G1 X49.376 Y155.294 E.27931
G3 X49.781 Y155.574 I-1.132 J2.065 E.01669
; WIPE_START
G1 X49.376 Y155.294 E-.09352
G1 X48.986 Y156.75 E-.28648
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.534 Y156.328 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X50.814 Y156.732 I-2.153 J1.786 E.01667
G1 X42.844 Y158.868 E.27928
G3 X42.882 Y158.377 I2.353 J-.063 E.01669
; OBJECT_ID: 14
; WIPE_START
G1 X42.844 Y158.868 E-.0935
G1 X44.301 Y158.478 E-.2865
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X36.761 Y157.291 Z5.6 F36000
G1 X26.588 Y155.69 Z5.6
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.319 Y155.632 E.00933
G2 X25.964 Y155.595 I-.524 J3.366 E.01207
G2 X25.646 Y155.594 I-.169 J3.008 E.01076
G2 X26.668 Y155.705 I.148 J3.404 E.68964
G1 X26.647 Y155.701 E.00074
M204 S10000
G1 X26.503 Y156.088 F36000
G1 F1473.913
M204 S3000
G1 X26.255 Y156.034 E.00861
G2 X25.942 Y156.002 I-.461 J2.964 E.01064
G2 X25.665 Y156.001 I-.148 J2.625 E.00938
G2 X26.563 Y156.098 I.128 J2.997 E.60736
G1 X26.562 Y156.098 E.00002
M204 S250
G1 X26.422 Y156.471 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.194 Y156.421 E.00733
G2 X25.922 Y156.393 I-.401 J2.577 E.00857
G2 X25.684 Y156.393 I-.128 J2.261 E.00746
G2 X26.481 Y156.483 I.109 J2.606 E.48857
; WIPE_START
M204 S3000
G1 X26.194 Y156.421 E-.05576
G1 X25.922 Y156.393 E-.05192
G1 X25.684 Y156.393 E-.0452
G1 X25.243 Y156.447 E-.08447
G1 X24.979 Y156.518 E-.05191
G1 X24.724 Y156.616 E-.05191
G1 X24.544 Y156.713 E-.03882
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.976 Y154.32 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.296 Y154.34 I-.186 J5.092 E.02306
G2 X26.036 Y154.323 I.482 J4.659 E.97112
M204 S10000
G1 X25.987 Y153.913 F36000
G1 F1473.913
M204 S3000
G2 X25.253 Y153.935 I-.197 J5.522 E.02486
G2 X26.047 Y153.916 I.523 J5.064 E1.0559
M204 S250
G1 X26.001 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.997 Y153.521 E.00013
G2 X25.212 Y153.545 I-.208 J5.933 E.02464
G2 X26.358 Y153.548 I.563 J5.454 E1.04423
G1 X26.061 Y153.526 E.00936
; WIPE_START
M204 S3000
G1 X25.997 Y153.521 E-.01216
G1 X25.498 Y153.523 E-.09472
G1 X25.212 Y153.545 E-.0546
M73 P82 R8
G1 X24.645 Y153.635 E-.10906
G1 X24.09 Y153.784 E-.10909
G1 X24.089 Y153.784 E-.00037
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.565 Y154.739 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.668 Y154.669 I-.759 J3.95 E.03053
G1 X25.509 Y155.26 E.02072
G1 X24.998 Y154.74 E.02469
G2 X24.337 Y154.917 I.511 J3.23 E.02322
G1 X24.148 Y155.622 E.0247
G1 X23.722 Y155.191 E.02051
G2 X22.98 Y155.7 I2.221 J4.038 E.03051
M204 S10000
G1 X23.649 Y155.913 F36000
G1 F1473.913
M204 S3000
G3 X23.993 Y155.701 I1.179 J1.534 E.01371
G1 X22.582 Y156.079 E.04946
G2 X22.435 Y156.256 I.768 J.787 E.0078
M204 S10000
G1 X22.973 Y156.509 F36000
G1 F1473.913
M204 S3000
G3 X23.141 Y156.337 I.9 J.709 E.00814
G1 X22.733 Y155.928 E.01955
G1 X22.827 Y155.834 E.00452
G1 X22.418 Y157.341 E.05286
G1 X21.988 Y156.911 E.02062
G2 X21.761 Y157.39 I3.198 J1.802 E.01797
M204 S10000
G1 X22.31 Y157.581 F36000
G1 F1473.913
M204 S3000
G3 X22.391 Y157.395 I.928 J.293 E.00689
G1 X21.693 Y157.582 E.02447
G2 X21.532 Y158.182 I2.775 J1.065 E.02107
G1 X22.045 Y158.695 E.02455
G3 X22.31 Y157.581 I5.887 J.813 E.03882
; WIPE_START
G1 X22.109 Y158.219 E-.12704
G1 X22.045 Y158.695 E-.09129
G1 X21.532 Y158.182 E-.13782
G1 X21.564 Y158.061 E-.02384
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.496 Y158.382 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X21.455 Y158.91 I2.491 J.459 E.01795
G1 X22.043 Y158.752 E.02062
G1 X21.639 Y160.267 E.05308
G1 X21.6 Y160.135 E.00466
G1 X22.159 Y159.985 E.0196
G3 X22.107 Y159.748 I1.094 J-.363 E.00822
M204 S10000
G1 X21.502 Y159.677 F36000
G1 F1473.913
M204 S3000
G1 X21.556 Y159.934 E.00889
G1 X22.605 Y160.982 E.05021
G3 X22.407 Y160.639 I1.215 J-.932 E.01345
M204 S10000
G1 X21.707 Y160.459 F36000
G1 F1473.913
M204 S3000
G2 X22.094 Y161.267 I4.319 J-1.573 E.03038
G1 X22.679 Y161.103 E.02057
G1 X22.49 Y161.811 E.02482
G2 X22.974 Y162.296 I3.65 J-3.166 E.0232
G1 X23.679 Y162.107 E.0247
G1 X23.518 Y162.691 E.02051
G2 X24.332 Y163.081 I3.367 J-5.985 E.03057
M204 S10000
G1 X24.18 Y162.394 F36000
G1 F1473.913
M204 S3000
G3 X23.824 Y162.202 I.738 J-1.787 E.01371
G1 X24.852 Y163.229 E.04918
G2 X25.148 Y163.287 I.426 J-1.379 E.01024
M204 S10000
G1 X25.035 Y162.681 F36000
G1 F1473.913
M204 S3000
G3 X24.801 Y162.622 I.165 J-1.141 E.00818
G1 X24.65 Y163.185 E.01973
G1 X24.526 Y163.144 E.00443
G1 X26.032 Y162.748 E.05271
G1 X25.876 Y163.331 E.02042
G2 X26.403 Y163.289 I.068 J-2.532 E.01795
; WIPE_START
G1 X25.876 Y163.331 E-.10057
G1 X26.032 Y162.748 E-.11462
G1 X25.193 Y162.969 E-.16481
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.204 Y162.473 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X27.391 Y162.394 I-.206 J-.75 E.00689
G1 X27.204 Y163.093 E.02448
G3 X26.603 Y163.253 I-1.065 J-2.773 E.02107
G1 X26.091 Y162.742 E.0245
G2 X27.204 Y162.473 I-.313 J-3.732 E.03888
M204 S10000
G1 X27.395 Y163.024 F36000
G1 F1473.913
M204 S3000
G2 X27.872 Y162.795 I-.848 J-2.389 E.01795
G1 X27.444 Y162.367 E.02051
G1 X28.951 Y161.958 E.05286
G1 X28.857 Y162.053 E.00452
G1 X28.449 Y161.644 E.01955
G3 X28.277 Y161.812 I-.882 J-.734 E.00813
M204 S10000
G1 X28.529 Y162.35 F36000
G1 F1473.913
M204 S3000
G2 X28.706 Y162.204 I-.61 J-.915 E.00779
G1 X29.084 Y160.792 E.04945
G3 X28.873 Y161.137 I-1.742 J-.833 E.01371
M204 S10000
G1 X29.086 Y161.806 F36000
G1 F1473.913
M204 S3000
G2 X29.596 Y161.065 I-3.795 J-3.16 E.03049
G1 X29.163 Y160.637 E.02059
G1 X29.868 Y160.448 E.0247
G2 X30.045 Y159.787 I-3.057 J-1.174 E.02321
G1 X29.527 Y159.269 E.02482
G1 X30.116 Y159.118 E.02058
G2 X30.046 Y158.218 I-4.686 J-.091 E.0306
M204 S10000
G1 X29.531 Y158.731 F36000
G1 F1473.913
M204 S3000
G3 X29.531 Y159.127 I-1.504 J.197 E.01345
G1 X29.914 Y157.694 E.05021
G2 X29.817 Y157.407 I-1.411 J.321 E.01028
M204 S10000
G1 X29.344 Y157.807 F36000
G1 F1473.913
M204 S3000
G3 X29.418 Y158.04 I-1.076 J.472 E.00832
G1 X29.977 Y157.891 E.01957
G1 X30.004 Y158.019 E.00443
G1 X28.902 Y156.914 E.05281
G1 X29.492 Y156.756 E.02067
G2 X29.188 Y156.321 I-2.222 J1.226 E.01798
; WIPE_START
G1 X29.492 Y156.756 E-.10077
G1 X28.902 Y156.914 E-.11601
G1 X29.509 Y157.522 E-.16322
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.08 Y156.037 Z5.6 F36000
G1 Z5.2
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X28.872 Y156.866 I-3.481 J4.123 E.03886
G1 X29.06 Y156.163 E.02462
G2 X28.622 Y155.725 I-4.107 J3.669 E.02098
G1 X27.918 Y155.914 E.02466
G1 X28.08 Y156.037 E.00689
M204 S10000
G1 X28.464 Y155.597 F36000
G1 F1473.913
M204 S3000
G2 X28.029 Y155.293 I-1.661 J1.919 E.01799
G1 X27.872 Y155.878 E.02049
G1 X26.764 Y154.779 E.05283
G1 X26.893 Y154.814 E.00452
G1 X26.745 Y155.367 E.0194
G3 X26.978 Y155.441 I-.236 J1.14 E.00828
M204 S10000
G1 X27.315 Y154.948 F36000
G1 F1473.913
M204 S3000
G2 X27.099 Y154.869 I-.485 J.981 E.00779
G1 X25.691 Y155.246 E.04935
G3 X26.096 Y155.259 I.14 J1.994 E.01375
; CHANGE_LAYER
; Z_HEIGHT: 5.4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X25.691 Y155.246 E-.07707
G1 X27.099 Y154.869 E-.277
G1 X27.227 Y154.916 E-.02594
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L27
M991 S0 P26 ;notify layer change


M204 S10000
G17
G3 Z5.6 I1.217 J0 P1  F36000
; object ids of layer 27 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer27 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.114 Y93.52
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X229.073 Y93.534 E.00145
G2 X230.395 Y93.357 I1.139 J3.475 E.73233
G2 X230.051 Y93.356 I-.182 J3.268 E.01166
G2 X229.443 Y93.434 I.161 J3.653 E.02077
G1 X229.172 Y93.505 E.00947
M204 S10000
G1 X229.219 Y93.913 F36000
G1 F1473.913
M204 S3000
G1 X229.199 Y93.921 E.00073
G2 X230.373 Y93.764 I1.012 J3.088 E.65084
G2 X230.07 Y93.763 I-.161 J2.886 E.01028
G2 X229.527 Y93.832 I.142 J3.247 E.01853
G1 X229.277 Y93.898 E.00875
M204 S250
G1 X229.32 Y94.291 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.32 Y94.294 E.00009
G2 X230.353 Y94.155 I.89 J2.716 E.53018
G2 X230.088 Y94.155 I-.141 J2.518 E.0083
G2 X229.609 Y94.216 I.123 J2.855 E.01517
G1 X229.378 Y94.276 E.00747
; WIPE_START
M204 S3000
G1 X229.32 Y94.294 E-.01159
G1 X229.04 Y94.399 E-.05686
G1 X228.773 Y94.535 E-.0569
G1 X228.522 Y94.698 E-.05687
G1 X228.181 Y94.989 E-.08527
G1 X227.98 Y95.212 E-.05688
G1 X227.808 Y95.449 E-.05563
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.762 Y92.548 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.624 E.00862
G2 X230.403 Y92.32 I1.674 J4.388 E.9337
G2 X229.958 Y92.321 I-.211 J4.239 E.01508
G2 X228.987 Y92.473 I.235 J4.69 E.03331
G1 X228.819 Y92.529 E.00599
M204 S10000
G1 X228.637 Y92.161 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.245 E.00935
G2 X230.414 Y91.913 I1.822 J4.767 E1.01489
G2 X229.67 Y91.936 I-.205 J5.554 E.02521
G2 X228.882 Y92.08 I.526 J5.076 E.02714
G1 X228.694 Y92.142 E.00671
M204 S250
G1 X228.514 Y91.782 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.504 Y91.783 E.00031
G2 X230.424 Y91.521 I1.69 J5.229 E1.02146
G2 X229.629 Y91.545 I-.215 J5.968 E.02496
G2 X229.06 Y91.635 I.565 J5.466 E.01805
G1 X228.572 Y91.766 E.01586
; WIPE_START
M204 S3000
G1 X228.504 Y91.783 E-.01323
G1 X228.233 Y91.88 E-.05469
G1 X227.708 Y92.114 E-.10933
G1 X227.21 Y92.402 E-.10927
G1 X226.812 Y92.691 E-.09348
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.946 Y93.028 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672805
G1 F952.555
M204 S3000
G1 X228.904 Y93.041 E.00227
G2 X226.025 Y97.003 I1.299 J3.971 E.27411
G1 X226.048 Y97.449 E.02335
G1 X226.116 Y97.881 E.02291
G1 X226.23 Y98.303 E.0229
G1 X226.386 Y98.711 E.02288
G1 X226.585 Y99.101 E.02293
G1 X226.823 Y99.467 E.02288
G1 X227.098 Y99.807 E.02293
G1 X227.414 Y100.122 E.02333
G1 X227.747 Y100.392 E.02248
G1 X228.121 Y100.634 E.02334
G1 X228.512 Y100.832 E.02291
G1 X229.114 Y101.045 E.03346
G1 X229.55 Y101.138 E.02335
G1 X229.985 Y101.184 E.02292
G1 X230.421 Y101.184 E.02286
G1 X230.857 Y101.138 E.02292
G1 X231.284 Y101.047 E.0229
G1 X231.701 Y100.912 E.02293
G1 X232.1 Y100.734 E.0229
G1 X232.486 Y100.511 E.02334
G1 X232.839 Y100.253 E.02291
G1 X233.302 Y99.813 E.03345
G1 X233.583 Y99.467 E.02335
G1 X233.817 Y99.108 E.02248
G1 X234.02 Y98.711 E.02334
G1 X234.177 Y98.303 E.0229
G1 X234.29 Y97.881 E.02288
G1 X234.358 Y97.449 E.02291
G1 X234.381 Y97.012 E.02292
G1 X234.358 Y96.575 E.02292
G1 X234.29 Y96.143 E.02291
G1 X234.174 Y95.713 E.02331
G2 X229.13 Y92.974 I-3.971 J1.299 E.33141
G1 X229.003 Y93.011 E.00691
; OBJECT_ID: 12
; WIPE_START
G1 X228.904 Y93.041 E-.01963
G1 X228.496 Y93.199 E-.08309
G1 X228.121 Y93.389 E-.07993
G1 X227.921 Y93.512 E-.04468
G1 X227.574 Y93.765 E-.08157
G1 X227.295 Y94.015 E-.07111
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.101 Y96.564 Z5.8 F36000
G1 X211.778 Y99.512 Z5.8
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.946 Y99.327 E.00845
G2 X208.982 Y93.121 I-3.159 J-2.302 E.28455
G2 X208.615 Y93.119 I-.194 J3.487 E.01244
G2 X211.546 Y99.793 I.172 J3.905 E.51352
G1 X211.74 Y99.558 E.01031
M204 S10000
G1 X211.469 Y99.262 F36000
G1 F1473.913
M204 S3000
G1 X211.502 Y99.23 E.00153
G2 X208.961 Y93.527 I-2.715 J-2.208 E.26104
G2 X208.634 Y93.526 I-.173 J3.105 E.01106
G2 X211.255 Y99.503 I.152 J3.496 E.45977
G1 X211.43 Y99.307 E.00887
M204 S250
G1 X211.178 Y99 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.197 Y98.984 E.00077
G2 X208.94 Y93.919 I-2.411 J-1.961 E.21475
G2 X208.653 Y93.918 I-.153 J2.738 E.00902
G2 X210.978 Y99.225 I.133 J3.105 E.37825
G1 X211.138 Y99.045 E.00757
; WIPE_START
M204 S3000
G1 X211.197 Y98.984 E-.01605
G1 X211.386 Y98.718 E-.06186
G1 X211.619 Y98.29 E-.09274
G1 X211.723 Y98.021 E-.05462
G1 X211.82 Y97.671 E-.06906
G1 X211.871 Y97.35 E-.06183
G1 X211.877 Y97.224 E-.02384
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.618 Y99.221 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.692 Y99.384 E.00602
G2 X208.978 Y92.32 I4.075 J-2.359 E.66037
G2 X208.531 Y92.321 I-.212 J4.255 E.01512
G2 X204.467 Y98.944 I.236 J4.703 E.3093
G1 X204.589 Y99.169 E.00868
M204 S10000
G1 X204.256 Y99.406 F36000
G1 F1473.913
M204 S3000
G1 X204.341 Y99.586 E.00674
G2 X208.988 Y91.913 I4.428 J-2.562 E.7178
G2 X208.243 Y91.936 I-.205 J5.57 E.02527
G2 X204.097 Y99.108 I.527 J5.089 E.3268
G1 X204.228 Y99.353 E.00939
M204 S250
G1 X203.907 Y99.584 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.001 Y99.783 E.00689
G2 X208.999 Y91.521 I4.768 J-2.758 E.71602
G2 X208.202 Y91.546 I-.216 J5.98 E.02502
G2 X203.738 Y99.268 I.567 J5.479 E.32594
G1 X203.878 Y99.531 E.00934
; WIPE_START
M204 S3000
G1 X204.001 Y99.783 E-.05313
G1 X204.32 Y100.263 E-.10962
G1 X204.683 Y100.711 E-.10957
G1 X205.084 Y101.112 E-.10767
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.938 Y98.981 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435981
G1 F1526.483
M204 S3000
G2 X204.468 Y97.019 I3.839 J-1.957 E.8183
G1 X204.491 Y97.475 E.01492
G1 X204.561 Y97.916 E.01457
G1 X204.677 Y98.352 E.01474
G1 X204.759 Y98.581 E.00797
G2 X204.911 Y98.928 I4.018 J-1.557 E.01236
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.0971
G1 X205.428 Y99.737 E-.08573
G1 X205.727 Y100.068 E-.08471
G1 X205.898 Y100.231 E-.04476
G1 X206.175 Y100.455 E-.06769
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.781 Y98.561 Z5.8 F36000
G1 X183.861 Y94.739 Z5.8
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.844 Y94.779 E.00147
G2 X187.542 Y92.885 I3.491 J2.26 E.7372
G2 X187.152 Y92.884 I-.206 J3.704 E.01322
G2 X184.098 Y94.427 I.182 J4.155 E.11934
G1 X183.897 Y94.691 E.01123
M204 S10000
G1 X184.19 Y94.978 F36000
G1 F1473.913
M204 S3000
G1 X184.185 Y95 E.00077
G2 X187.521 Y93.292 I3.149 J2.039 E.66504
G2 X187.171 Y93.291 I-.186 J3.323 E.01184
G2 X184.414 Y94.683 I.163 J3.748 E.10773
G1 X184.226 Y94.93 E.01051
M204 S250
G1 X184.507 Y95.208 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.514 Y95.214 E.00028
G2 X187.5 Y93.684 I2.819 J1.823 E.55129
G2 X187.19 Y93.683 I-.165 J2.955 E.00974
G2 X184.719 Y94.93 I.144 J3.354 E.08943
G1 X184.543 Y95.16 E.0091
; WIPE_START
M204 S3000
G1 X184.514 Y95.214 E-.01162
G1 X184.33 Y95.514 E-.06675
G1 X184.187 Y95.835 E-.06685
G1 X184.038 Y96.341 E-.10018
G1 X183.983 Y96.688 E-.06681
G1 X183.964 Y97.039 E-.06683
G1 X183.964 Y97.044 E-.00096
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.525 Y92.32 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X187.077 Y92.321 I-.212 J4.263 E.01517
G2 X187.585 Y92.323 I.237 J4.718 E.98741
M204 S10000
G1 X187.536 Y91.913 F36000
G1 F1473.913
M204 S3000
G2 X186.788 Y91.936 I-.206 J5.585 E.02534
G2 X187.596 Y91.916 I.528 J5.103 E1.06375
M204 S250
G1 X187.542 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.524 E.01589
G2 X186.747 Y91.546 I.294 J5.995 E.00907
G2 X187.602 Y91.524 I.568 J5.494 E1.06117
; WIPE_START
M204 S3000
G1 X187.035 Y91.524 E-.10767
G1 X186.747 Y91.546 E-.05498
G1 X186.176 Y91.636 E-.10985
G1 X185.629 Y91.782 E-.10749
; WIPE_END
G1 E-.02 F1800
M204 S10000
M73 P83 R8
G1 X187.545 Y92.609 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200585
G1 F3805.552
M204 S3000
G1 X187.324 Y92.598 E.0029
G2 X182.882 Y97.037 I-.001 J4.441 E.09144
G1 X182.907 Y97.504 E.00613
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.00609
G1 X183.181 Y98.64 E.0032
G2 X187.786 Y92.623 I4.143 J-1.6 E.24681
G1 X187.605 Y92.612 E.00238
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.598 E-.05346
G1 X186.86 Y92.622 E-.08837
G1 X186.4 Y92.694 E-.08836
G1 X185.954 Y92.814 E-.08788
G1 X185.73 Y92.893 E-.04502
G1 X185.649 Y92.929 E-.01692
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.019 Y93.143 Z5.8 F36000
G1 X163.162 Y93.558 Z5.8
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.895 Y93.784 E.01186
G2 X166.071 Y92.652 I2.956 J3.271 E.82049
G2 X165.658 Y92.65 I-.219 J3.924 E.01399
G2 X163.253 Y93.494 I.193 J4.404 E.08753
G1 X163.211 Y93.523 E.00172
M204 S10000
G1 X163.435 Y93.862 F36000
G1 F1473.913
M204 S3000
G1 X163.326 Y93.95 E.00474
G2 X166.05 Y93.058 I2.524 J3.105 E.75188
G2 X165.677 Y93.057 I-.198 J3.542 E.01262
G2 X163.664 Y93.704 I.173 J3.998 E.07243
G1 X163.485 Y93.828 E.00739
M204 S250
G1 X163.666 Y94.179 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.573 Y94.255 E.00375
G2 X166.029 Y93.45 I2.277 J2.801 E.62822
G2 X165.696 Y93.449 I-.178 J3.175 E.01046
G2 X163.878 Y94.032 I.154 J3.606 E.0606
G1 X163.715 Y94.145 E.0062
; WIPE_START
M204 S3000
G1 X163.573 Y94.255 E-.03409
G1 X163.288 Y94.502 E-.07175
G1 X163.035 Y94.783 E-.07182
G1 X162.813 Y95.089 E-.07179
G1 X162.624 Y95.416 E-.0718
G1 X162.498 Y95.699 E-.05876
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.483 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.042 Y92.32 I1.69 J-4.428 E.55531
G2 X165.593 Y92.321 I-.213 J4.279 E.01522
G2 X164.085 Y101.461 I.238 J4.734 E.43546
M204 S10000
G1 X163.995 Y101.862 F36000
G1 F1473.913
M204 S3000
G2 X166.053 Y91.913 I1.837 J-4.807 E.60341
G2 X165.302 Y91.936 I-.206 J5.603 E.02542
G2 X163.939 Y101.84 I.53 J5.119 E.46367
M204 S250
G1 X163.847 Y102.224 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.855 Y102.229 E.00027
G2 X166.063 Y91.521 I1.977 J-5.174 E.60167
G2 X165.261 Y91.546 I-.217 J6.017 E.02516
G2 X163.525 Y102.09 I.57 J5.509 E.45307
G1 X163.792 Y102.201 E.00906
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.855 Y102.229 E-.01303
G1 X164.407 Y102.406 E-.11021
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.742 Y102.587 E-.03638
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.958 Y106.084 Z5.8 F36000
G1 X47.333 Y163.609 Z5.8
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.591 E.01
G2 X47.34 Y154.32 I-.496 J-4.624 E.47071
G2 X46.898 Y154.321 I-.209 J4.201 E.01494
G2 X47.142 Y163.617 I.233 J4.645 E.48702
G1 X47.273 Y163.612 E.00445
M204 S10000
G1 X47.375 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.00105
G2 X47.35 Y153.913 I-.272 J-5.051 E.52137
G2 X46.613 Y153.935 I-.203 J5.507 E.02499
G2 X46.877 Y164.019 I.521 J5.032 E.51156
G1 X47.315 Y164.019 E.01483
M204 S250
G1 X47.375 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.41 E.00162
G2 X47.36 Y153.521 I-.294 J-5.443 E.52051
G2 X46.572 Y153.545 I-.213 J5.922 E.02476
G2 X46.857 Y164.41 I.561 J5.422 E.51063
G1 X47.315 Y164.411 E.01438
; WIPE_START
M204 S3000
G1 X47.427 Y164.41 E-.02119
G1 X47.994 Y164.351 E-.10844
G1 X48.553 Y164.233 E-.10842
G1 X48.826 Y164.152 E-.0542
M73 P83 R7
G1 X49.257 Y163.986 E-.08775
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.298 Y163.264 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X48.097 Y163.157 I-.242 J-4.842 E.02731
G1 X42.951 Y158.012 E.24632
G3 X43.035 Y157.699 I1.53 J.242 E.01099
G1 X50.067 Y155.815 E.24642
G1 X50.294 Y156.042 E.01087
G1 X48.41 Y163.073 E.24642
G2 X49.155 Y162.767 I-1.464 J-4.615 E.02731
M204 S10000
G1 X49.331 Y162.665 F36000
G1 F1473.913
M204 S3000
G1 X43.441 Y156.775 E.28196
; WIPE_START
G1 X44.855 Y158.189 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X42.844 Y159.014 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X50.892 Y156.858 E.28202
; WIPE_START
G1 X48.96 Y157.375 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.25 Y155.218 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X47.094 Y163.264 E.28196
; WIPE_START
G1 X47.612 Y161.333 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.677 Y162.443 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X49.889 Y162.272 E.00921
G1 X51.175 Y157.473 E.16819
G1 X51.236 Y157.661 E.00671
G1 X48.441 Y154.866 E.13382
G3 X48.63 Y154.935 I-.235 J.937 E.00685
G1 X43.836 Y156.22 E.168
G3 X43.966 Y156.065 I.802 J.54 E.00685
G1 X42.943 Y159.883 E.13382
G1 X42.902 Y159.689 E.00671
G1 X46.419 Y163.207 E.16837
G1 X46.225 Y163.166 E.00672
G1 X50.044 Y162.142 E.13382
G1 X50.29 Y161.896 E.01178
G1 X44.212 Y155.819 E.29093
G3 X45.052 Y155.206 I8.489 J10.753 E.03521
; WIPE_START
G1 X44.212 Y155.819 E-.19758
G1 X44.891 Y156.498 E-.18242
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.071 Y154.669 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X48.104 Y154.776 I-.184 J6.831 E.03522
G1 X45.881 Y163.076 E.29085
G3 X44.93 Y162.654 I1.996 J-5.791 E.03525
; WIPE_START
G1 X45.881 Y163.076 E-.19763
G1 X46.129 Y162.149 E-.18237
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.455 Y161.177 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X43.033 Y160.228 I3.762 J-2.243 E.03523
G1 X51.331 Y158.005 E.29078
G3 X51.434 Y159.241 I-7.88 J1.281 E.04205
G1 X43.56 Y161.351 E.27593
G2 X43.747 Y161.603 I1.695 J-1.061 E.01063
G1 X45.52 Y154.985 E.23192
G1 X45.233 Y155.112 E.01063
G1 X50.996 Y160.875 E.27587
G1 X51.124 Y160.589 E.01063
G1 X44.505 Y162.362 E.23192
G2 X44.759 Y162.544 I.991 J-1.115 E.01057
G1 X46.867 Y154.675 E.27575
G1 X46.555 Y154.707 E.01063
G1 X51.401 Y159.553 E.23198
G3 X51.195 Y160.398 I-4.69 J-.696 E.02948
; OBJECT_ID: 14
; WIPE_START
G1 X51.401 Y159.553 E-.16522
G1 X50.602 Y158.754 E-.21478
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X43.031 Y157.788 Z5.8 F36000
G1 X26.582 Y155.688 Z5.8
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.318 Y155.632 E.00912
G2 X25.964 Y155.595 I-.525 J3.366 E.01207
G2 X25.643 Y155.594 I-.17 J3.048 E.01088
G2 X26.668 Y155.705 I.151 J3.404 E.68953
G1 X26.641 Y155.7 E.00094
M204 S10000
G1 X26.497 Y156.086 F36000
G1 F1473.913
M204 S3000
G1 X26.255 Y156.034 E.0084
G2 X25.942 Y156.002 I-.462 J2.964 E.01064
G2 X25.662 Y156.001 I-.149 J2.666 E.0095
G2 X26.563 Y156.099 I.131 J2.997 E.60725
G1 X26.556 Y156.097 E.00022
M204 S250
G1 X26.416 Y156.469 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.194 Y156.421 E.00713
G2 X25.922 Y156.393 I-.401 J2.577 E.00857
G2 X25.68 Y156.393 I-.129 J2.299 E.00758
G2 X26.475 Y156.481 I.112 J2.606 E.48865
; WIPE_START
M204 S3000
G1 X26.194 Y156.421 E-.05459
G1 X25.922 Y156.393 E-.05192
G1 X25.68 Y156.393 E-.0459
G1 X25.243 Y156.447 E-.08378
G1 X24.979 Y156.518 E-.05191
G1 X24.724 Y156.616 E-.05191
G1 X24.539 Y156.716 E-.03999
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.985 Y154.32 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X30.175 Y157.364 I-.199 J4.68 E.81042
G2 X26.044 Y154.323 I-4.409 J1.662 E.18359
M204 S10000
G1 X25.995 Y153.913 F36000
G1 F1473.913
M204 S3000
G2 X25.253 Y153.935 I-.204 J5.543 E.02515
G2 X26.055 Y153.916 I.524 J5.065 E1.05574
M204 S250
G1 X26.006 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.005 Y153.521 E.00001
G2 X25.212 Y153.545 I-.215 J5.953 E.02491
G2 X26.358 Y153.547 I.564 J5.455 E1.04435
G1 X26.065 Y153.526 E.00921
; WIPE_START
M204 S3000
G1 X26.005 Y153.521 E-.01143
G1 X25.498 Y153.523 E-.09634
G1 X25.212 Y153.545 E-.0546
G1 X24.645 Y153.635 E-.10907
G1 X24.093 Y153.783 E-.10857
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.557 Y154.738 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.52 Y154.673 I-.93 J6.608 E.03521
G1 X25.358 Y155.279 E.02121
G3 X25.704 Y155.246 I.301 J1.336 E.01181
G1 X25.169 Y154.71 E.02565
G2 X24.175 Y154.977 I3.032 J13.304 E.03484
G1 X23.979 Y155.708 E.02564
G3 X24.286 Y155.555 I.884 J1.39 E.01166
G1 X23.852 Y155.121 E.02081
G2 X22.985 Y155.694 I3.689 J6.509 E.0352
M204 S10000
G1 X22.492 Y156.186 F36000
G1 F1473.913
M204 S3000
G1 X22.426 Y156.267 E.00355
G1 X23.576 Y155.96 E.04032
G2 X23.241 Y156.237 I1.152 J1.736 E.01476
G1 X22.833 Y155.828 E.01955
G1 X22.627 Y156.034 E.00984
G1 X21.568 Y159.987 E.13852
G2 X21.644 Y160.27 I1.383 J-.223 E.00993
G1 X22.206 Y160.119 E.01969
G2 X22.353 Y160.53 I1.624 J-.347 E.0148
G1 X21.502 Y159.68 E.04069
G1 X21.525 Y159.788 E.00375
M204 S10000
G1 X21.707 Y160.463 F36000
G1 F1473.913
M204 S3000
G2 X22.175 Y161.392 I5.541 J-2.208 E.03524
G1 X22.765 Y161.234 E.02067
G3 X22.575 Y160.947 I1.266 J-1.046 E.01166
G1 X22.38 Y161.676 E.02553
G2 X23.106 Y162.407 I4.819 J-4.066 E.03493
G1 X23.838 Y162.21 E.02564
G3 X23.552 Y162.02 I.763 J-1.461 E.01166
G1 X23.392 Y162.614 E.02081
M73 P84 R7
G2 X24.322 Y163.078 I6.314 J-11.496 E.03517
M204 S10000
G1 X24.997 Y163.26 F36000
G1 F1473.913
M204 S3000
G1 X25.106 Y163.283 E.00375
G1 X24.257 Y162.433 E.04065
G2 X24.665 Y162.585 I.926 J-1.862 E.01476
G1 X24.516 Y163.141 E.01947
G2 X24.798 Y163.218 I.506 J-1.305 E.00993
G1 X28.751 Y162.158 E.13853
G1 X28.957 Y161.953 E.00984
G1 X28.549 Y161.544 E.01955
G2 X28.827 Y161.208 I-8.697 J-7.466 E.01478
G1 X28.515 Y162.369 E.0407
G1 X28.602 Y162.296 E.00384
M204 S10000
G1 X29.091 Y161.8 F36000
G1 F1473.913
M204 S3000
G2 X29.666 Y160.934 I-3.711 J-3.09 E.03523
G1 X29.23 Y160.499 E.02085
G3 X29.077 Y160.807 I-1.543 J-.575 E.01166
G1 X29.809 Y160.611 E.02565
G2 X30.075 Y159.617 I-13.222 J-4.072 E.03484
G1 X29.532 Y159.074 E.02599
G3 X29.518 Y159.424 I-1.338 J.122 E.01191
G1 X30.112 Y159.265 E.02081
G2 X30.049 Y158.228 I-13.132 J.281 E.03517
M204 S10000
G1 X29.871 Y157.56 F36000
G1 F1473.913
M204 S3000
G1 X29.832 Y157.457 E.00372
G1 X29.519 Y158.622 E.04084
G2 X29.448 Y158.179 I-2.146 J.119 E.01523
G1 X30.006 Y158.029 E.01957
G2 X29.937 Y157.752 I-1.797 J.3 E.00968
G1 X27.038 Y154.852 E.13881
G1 X26.757 Y154.777 E.00984
G1 X26.607 Y155.338 E.01965
G2 X26.163 Y155.266 I-.563 J2.075 E.01523
G1 X27.328 Y154.954 E.04084
G1 X27.23 Y154.916 E.00355
; WIPE_START
G1 X27.328 Y154.954 E-.01995
G1 X26.163 Y155.266 E-.22922
G1 X26.607 Y155.338 E-.08533
G1 X26.668 Y155.106 E-.04551
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.595 Y155.703 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X27.903 Y155.219 I-3.239 J3.893 E.02864
G1 X27.747 Y155.799 E.02034
M204 S10000
G1 X28.069 Y156.02 F36000
G1 F1473.913
M204 S3000
G1 X28.747 Y155.838 E.02379
G1 X28.948 Y156.038 E.00958
G1 X28.766 Y156.717 E.02379
M204 S10000
G1 X28.986 Y157.038 F36000
G1 F1473.913
M204 S3000
G1 X29.567 Y156.883 E.02034
G2 X29.082 Y156.19 I-4.381 J2.549 E.02864
; WIPE_START
G1 X29.567 Y156.883 E-.2221
G1 X28.986 Y157.038 E-.1579
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.237 Y163.082 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X27.999 Y162.722 I-1.57 J-4.317 E.02857
G1 X27.576 Y162.299 E.02024
M204 S10000
G1 X27.225 Y162.465 F36000
G1 F1473.913
M204 S3000
G1 X27.043 Y163.145 E.02381
G3 X26.768 Y163.218 I-.488 J-1.271 E.00965
G1 X26.272 Y162.723 E.02374
M204 S10000
G1 X25.884 Y162.751 F36000
G1 F1473.913
M204 S3000
G1 X25.729 Y163.331 E.02031
G2 X26.569 Y163.261 I.04 J-4.6 E.02857
; WIPE_START
G1 X25.729 Y163.331 E-.22201
G1 X25.884 Y162.751 E-.15799
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.525 Y158.216 Z5.8 F36000
G1 Z5.4
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X21.455 Y159.056 I4.53 J.8 E.02857
G1 X22.039 Y158.9 E.02049
M204 S10000
G1 X22.063 Y158.513 F36000
G1 F1473.913
M204 S3000
G1 X21.567 Y158.017 E.02373
G3 X21.641 Y157.742 I1.345 J.213 E.00965
G1 X22.318 Y157.561 E.02373
M204 S10000
G1 X22.486 Y157.209 F36000
G1 F1473.913
M204 S3000
G1 X22.061 Y156.784 E.02034
G2 X21.704 Y157.549 I7.249 J3.853 E.02858
; CHANGE_LAYER
; Z_HEIGHT: 5.6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X22.061 Y156.784 E-.22196
G1 X22.486 Y157.209 E-.15804
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L28
M991 S0 P27 ;notify layer change


M204 S10000
G17
G3 Z5.8 I1.217 J0 P1  F36000
; object ids of layer 28 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer28 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.032 Y93.547
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X228.716 Y93.672 E.01151
G2 X230.395 Y93.357 I1.495 J3.337 E.71936
G2 X230.046 Y93.356 I-.183 J3.311 E.01181
G2 X229.089 Y93.529 I.165 J3.653 E.033
M204 S10000
G1 X229.178 Y93.926 F36000
G1 F1473.913
M204 S3000
G1 X228.882 Y94.044 E.01079
G2 X230.373 Y93.764 I1.329 J2.966 E.63932
G2 X230.065 Y93.763 I-.162 J2.924 E.01043
G2 X229.235 Y93.909 I.145 J3.247 E.02861
M204 S250
G1 X229.318 Y94.292 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.041 Y94.402 E.00934
G2 X230.353 Y94.155 I1.169 J2.608 E.5208
G2 X230.084 Y94.155 I-.142 J2.556 E.00843
G2 X229.375 Y94.277 I.126 J2.855 E.02263
; WIPE_START
M204 S3000
G1 X229.041 Y94.402 E-.06766
G1 X228.773 Y94.535 E-.05689
G1 X228.522 Y94.698 E-.05687
G1 X228.181 Y94.989 E-.08527
G1 X227.98 Y95.212 E-.05688
G1 X227.806 Y95.452 E-.05643
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.795 Y92.537 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.624 E.0098
G2 X230.412 Y92.32 I1.676 J4.387 E.93343
G2 X229.958 Y92.321 I-.218 J4.317 E.01537
G2 X228.987 Y92.473 I.237 J4.69 E.03331
G1 X228.852 Y92.518 E.00482
M204 S10000
G1 X228.669 Y92.151 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.243 E.01052
G2 X230.422 Y91.913 I1.819 J4.768 E1.01458
G2 X229.936 Y91.915 I-.231 J4.622 E.01645
G2 X228.882 Y92.079 I.256 J5.097 E.0362
G1 X228.726 Y92.131 E.00554
M204 S250
G1 X228.547 Y91.773 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.504 Y91.783 E.00138
G2 X230.432 Y91.521 I1.691 J5.229 E1.02128
G2 X229.629 Y91.545 I-.223 J5.987 E.02523
G2 X229.06 Y91.635 I.566 J5.466 E.01805
G1 X228.605 Y91.757 E.01478
; WIPE_START
M204 S3000
G1 X228.504 Y91.783 E-.01975
G1 X227.968 Y91.99 E-.10928
G1 X227.708 Y92.114 E-.05474
G1 X227.405 Y92.282 E-.06575
G1 X226.972 Y92.565 E-.0982
G1 X226.84 Y92.672 E-.03228
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.945 Y93.029 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672825
G1 F952.525
M204 S3000
G1 X228.92 Y93.035 E.00135
G2 X226.025 Y97.012 I1.282 J3.976 E.27543
G1 X226.048 Y97.449 E.02292
G1 X226.115 Y97.872 E.02246
G1 X226.227 Y98.295 E.02291
G1 X226.309 Y98.524 E.01276
G2 X229.334 Y92.925 I3.894 J-1.513 E.99576
G1 X229.003 Y93.013 E.01796
; OBJECT_ID: 12
; WIPE_START
G1 X228.92 Y93.035 E-.01631
G1 X228.698 Y93.114 E-.04466
G1 X228.306 Y93.289 E-.08161
G1 X227.927 Y93.508 E-.08307
G1 X227.58 Y93.76 E-.08156
G1 X227.402 Y93.912 E-.04458
G1 X227.297 Y94.017 E-.02821
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.105 Y96.574 Z6 F36000
G1 X211.767 Y99.539 Z6
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.817 Y99.486 E.00248
G2 X208.982 Y93.121 I-3.031 J-2.464 E.29132
G2 X208.61 Y93.12 I-.195 J3.534 E.0126
G2 X211.543 Y99.79 I.176 J3.903 E.51307
G1 X211.727 Y99.584 E.00935
M204 S10000
G1 X211.465 Y99.267 F36000
G1 F1473.913
M204 S3000
G1 X211.501 Y99.23 E.00176
G2 X208.961 Y93.527 I-2.716 J-2.208 E.261
G2 X208.63 Y93.526 I-.174 J3.147 E.01122
G2 X211.255 Y99.502 I.156 J3.496 E.45966
G1 X211.425 Y99.312 E.00863
M204 S250
G1 X211.174 Y99.005 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.196 Y98.983 E.00099
G2 X208.94 Y93.919 I-2.411 J-1.961 E.21472
G2 X208.648 Y93.918 I-.154 J2.779 E.00916
G2 X210.978 Y99.225 I.137 J3.105 E.37815
G1 X211.134 Y99.05 E.00735
; WIPE_START
M204 S3000
G1 X211.196 Y98.983 E-.01737
G1 X211.386 Y98.719 E-.06185
G1 X211.619 Y98.29 E-.09274
G1 X211.735 Y97.986 E-.06187
G1 X211.82 Y97.671 E-.06186
G1 X211.871 Y97.35 E-.06183
G1 X211.877 Y97.232 E-.02249
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.587 Y99.174 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.822 Y99.593 E.01628
G2 X208.986 Y92.32 I3.947 J-2.569 E.65183
G2 X208.531 Y92.321 I-.218 J4.337 E.01541
G2 X204.554 Y99.125 I.238 J4.703 E.31605
M204 S10000
G1 X204.235 Y99.377 F36000
G1 F1473.913
M204 S3000
G1 X204.479 Y99.816 E.01701
G2 X208.997 Y91.913 I4.287 J-2.792 E.70833
G2 X208.51 Y91.915 I-.232 J4.646 E.0165
G2 X204.199 Y99.33 I.257 J5.11 E.34428
M204 S250
G1 X203.9 Y99.571 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.001 Y99.782 E.00735
G2 X209.007 Y91.521 I4.768 J-2.758 E.7158
G2 X208.202 Y91.546 I-.223 J6.002 E.02529
G2 X203.739 Y99.268 I.568 J5.479 E.3259
G1 X203.872 Y99.518 E.00888
; WIPE_START
M204 S3000
G1 X204.001 Y99.782 E-.05593
G1 X204.32 Y100.263 E-.10958
G1 X204.683 Y100.711 E-.10957
G1 X205.074 Y101.101 E-.10491
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.938 Y98.981 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435972
G1 F1526.517
M204 S3000
G2 X204.468 Y97.019 I3.839 J-1.957 E.81828
G1 X204.491 Y97.475 E.01492
G1 X204.561 Y97.916 E.01457
G1 X204.677 Y98.352 E.01475
G1 X204.759 Y98.581 E.00795
G2 X204.911 Y98.928 I4.018 J-1.556 E.01238
; OBJECT_ID: 11
; WIPE_START
G1 X205.161 Y99.368 E-.09614
G1 X205.425 Y99.733 E-.08562
G1 X205.578 Y99.912 E-.04489
G1 X205.894 Y100.227 E-.08472
G1 X206.175 Y100.455 E-.06864
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.772 Y98.594 Z6 F36000
G1 X183.804 Y94.832 Z6
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.532 Y95.351 E.01986
G2 X187.542 Y92.885 I3.801 J1.688 E.71511
G2 X187.147 Y92.884 I-.208 J3.754 E.0134
G2 X183.843 Y94.778 I.187 J4.155 E.13389
G1 X183.839 Y94.783 E.0002
M204 S10000
G1 X184.161 Y95.025 F36000
G1 F1473.913
M204 S3000
G1 X183.905 Y95.517 E.01877
G2 X187.521 Y93.292 I3.428 J1.52 E.64468
G2 X187.166 Y93.291 I-.187 J3.368 E.01201
G2 X184.199 Y94.979 I.167 J3.746 E.11997
M204 S250
G1 X184.505 Y95.212 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.263 Y95.676 E.01642
G2 X187.5 Y93.684 I3.069 J1.361 E.53476
G2 X187.185 Y93.683 I-.167 J2.999 E.00989
G2 X184.541 Y95.171 I.148 J3.354 E.09868
; WIPE_START
M204 S3000
G1 X184.263 Y95.676 E-.1097
G1 X184.129 Y96.001 E-.06676
G1 X184.038 Y96.341 E-.06681
G1 X183.983 Y96.688 E-.06681
G1 X183.964 Y97.039 E-.06684
G1 X183.965 Y97.055 E-.00309
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.534 Y92.32 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X187.077 Y92.321 I-.219 J4.345 E.01546
G2 X187.593 Y92.323 I.239 J4.718 E.98715
M204 S10000
G1 X187.544 Y91.913 F36000
G1 F1473.913
M204 S3000
G2 X187.909 Y102.136 I-.219 J5.126 E.57281
G2 X187.604 Y91.916 I-.585 J-5.097 E.51623
M204 S250
G1 X187.547 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.524 E.01604
G2 X186.747 Y91.546 I.296 J6.018 E.00907
G2 X187.607 Y91.524 I.569 J5.493 E1.06097
; WIPE_START
M204 S3000
G1 X187.035 Y91.524 E-.10856
G1 X186.747 Y91.546 E-.05498
G1 X186.176 Y91.636 E-.10985
G1 X185.634 Y91.781 E-.1066
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.55 Y92.609 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200579
G1 F3805.691
M204 S3000
G1 X187.326 Y92.597 E.00293
G2 X182.882 Y97.037 I-.002 J4.442 E.09147
G1 X182.907 Y97.504 E.00613
G1 X182.98 Y97.965 E.00612
G1 X183.034 Y98.191 E.00305
G1 X183.177 Y98.629 E.00604
G1 X183.367 Y99.056 E.00613
G1 X183.6 Y99.46 E.00612
G1 X183.871 Y99.833 E.00603
G1 X184.022 Y100.01 E.00305
G1 X184.352 Y100.34 E.00612
G1 X184.72 Y100.638 E.00621
G2 X187.789 Y92.622 I2.604 J-3.598 E.21331
G1 X187.61 Y92.612 E.00236
; OBJECT_ID: 10
; WIPE_START
G1 X187.326 Y92.597 E-.0539
G1 X187.092 Y92.604 E-.0445
G1 X186.86 Y92.622 E-.04425
G1 X186.399 Y92.695 E-.08876
G1 X185.952 Y92.815 E-.08789
G1 X185.653 Y92.929 E-.06071
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.024 Y93.143 Z6 F36000
G1 X163.161 Y93.559 Z6
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.895 Y93.784 E.01178
G2 X166.071 Y92.652 I2.955 J3.271 E.82051
G2 X165.652 Y92.651 I-.22 J3.978 E.01419
G2 X163.252 Y93.493 I.198 J4.404 E.08735
G1 X163.209 Y93.524 E.00179
M204 S10000
G1 X163.41 Y93.884 F36000
G1 F1473.913
M204 S3000
M73 P85 R7
G1 X163.016 Y94.23 E.01778
G2 X166.05 Y93.058 I2.834 J2.825 E.73766
G2 X165.672 Y93.057 I-.199 J3.591 E.0128
G2 X163.491 Y93.822 I.178 J3.998 E.07935
G1 X163.458 Y93.847 E.00141
M204 S250
G1 X163.664 Y94.181 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.293 Y94.508 E.01551
G2 X166.029 Y93.45 I2.556 J2.545 E.61595
G2 X165.691 Y93.449 I-.179 J3.223 E.01062
G2 X163.722 Y94.14 I.159 J3.604 E.06636
G1 X163.713 Y94.146 E.00034
; WIPE_START
M204 S3000
G1 X163.293 Y94.508 E-.10531
G1 X162.92 Y94.933 E-.10756
G1 X162.714 Y95.25 E-.0718
G1 X162.543 Y95.587 E-.07179
G1 X162.498 Y95.702 E-.02353
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.14 Y101.473 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X164.375 Y101.565 E.00856
G2 X166.05 Y92.32 I1.457 J-4.51 E.54673
G2 X165.593 Y92.321 I-.219 J4.359 E.01551
G2 X163.911 Y101.388 I.239 J4.734 E.42898
G1 X164.084 Y101.452 E.00622
M204 S10000
G1 X163.995 Y101.863 F36000
G1 F1473.913
M204 S3000
G2 X166.061 Y91.913 I1.835 J-4.809 E.60297
G2 X165.571 Y91.915 I-.233 J4.668 E.01659
G2 X163.939 Y101.842 I.258 J5.14 E.47302
M204 S250
G1 X163.851 Y102.225 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.855 Y102.228 E.00015
G2 X166.071 Y91.521 I1.977 J-5.174 E.60146
G2 X165.261 Y91.546 I-.224 J6.037 E.02543
G2 X163.533 Y102.093 I.571 J5.509 E.45329
G1 X163.796 Y102.202 E.00892
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.855 Y102.228 E-.01224
G1 X164.407 Y102.406 E-.11021
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.746 Y102.587 E-.03718
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.962 Y106.084 Z6 F36000
G1 X47.338 Y163.609 Z6
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.592 E.00981
G2 X47.348 Y154.32 I-.494 J-4.625 E.47059
G2 X46.898 Y154.321 I-.216 J4.282 E.01523
G2 X47.142 Y163.618 I.235 J4.646 E.48696
G1 X47.278 Y163.612 E.00464
M204 S10000
G1 X47.36 Y164.015 F36000
G1 F1473.913
M204 S3000
G1 X47.67 Y163.996 E.01053
G2 X47.359 Y153.913 I-.539 J-5.03 E.51192
G2 X46.877 Y153.914 I-.229 J4.591 E.01631
G2 X47.142 Y164.025 I.254 J5.052 E.52968
G1 X47.3 Y164.018 E.00536
M204 S250
G1 X47.381 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.408 E.00144
G2 X47.369 Y153.521 I-.293 J-5.442 E.52026
G2 X46.572 Y153.545 I-.221 J5.943 E.02502
G2 X46.857 Y164.409 I.562 J5.421 E.51052
G1 X47.321 Y164.411 E.01455
; WIPE_START
M204 S3000
G1 X47.427 Y164.408 E-.02013
G1 X47.994 Y164.351 E-.10843
G1 X48.553 Y164.233 E-.10842
G1 X48.826 Y164.152 E-.05422
G1 X49.263 Y163.984 E-.0888
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.851 Y163.257 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X46.948 Y163.264 I.081 J-.458 E.0033
G1 X49.121 Y155.152 E.28426
G1 X49.038 Y155.11 E.00317
; WIPE_START
G1 X49.121 Y155.152 E-.01778
G1 X48.628 Y156.994 E-.36222
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.571 Y156.575 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X43.52 Y156.653 E.00317
G1 X49.458 Y162.592 E.28426
G2 X49.702 Y162.424 I-1.853 J-2.945 E.01002
G1 X51.086 Y157.259 E.18097
G1 X51.127 Y157.352 E.00344
G1 X48.759 Y154.985 E.11333
G1 X48.855 Y155.021 E.00347
G1 X43.685 Y156.407 E.18117
G1 X43.75 Y156.327 E.00347
G1 X42.883 Y159.561 E.11333
G1 X42.872 Y159.46 E.00344
G1 X46.648 Y163.236 E.18076
G1 X46.547 Y163.226 E.00344
G1 X49.781 Y162.359 E.11333
G2 X50.385 Y161.791 I-3.008 J-3.797 E.02807
G1 X44.317 Y155.724 E.29043
G3 X45.169 Y155.144 I2.828 J3.234 E.03496
M204 S10000
G1 X45.557 Y154.968 F36000
G1 F1473.913
M204 S3000
G3 X46.717 Y154.69 I2.545 J8.067 E.04038
G1 X44.646 Y162.471 E.27252
G1 X51.061 Y160.741 E.22489
G1 X45.371 Y155.051 E.27236
G1 X43.639 Y161.457 E.22464
G1 X51.418 Y159.392 E.27243
G1 X46.736 Y154.688 E.22464
G3 X47.966 Y154.746 I.366 J5.316 E.04177
G1 X45.746 Y163.032 E.29035
G3 X44.817 Y162.581 I1.991 J-5.287 E.03499
; WIPE_START
G1 X45.746 Y163.032 E-.19612
G1 X45.996 Y162.097 E-.18388
; WIPE_END
M73 P85 R6
G1 E-.02 F1800
M204 S10000
G1 X43.521 Y161.292 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X43.077 Y160.363 I3.939 J-2.458 E.03493
G1 X51.36 Y158.143 E.29028
G3 X51.439 Y159.17 I-4.563 J.868 E.03493
; WIPE_START
G1 X51.36 Y158.143 E-.19568
G1 X50.423 Y158.394 E-.18432
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X51.003 Y157.073 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X50.96 Y156.986 I-.438 J.159 E.0033
G1 X42.844 Y159.161 E.28441
G2 X42.851 Y159.258 I.465 J.016 E.0033
; WIPE_START
G1 X42.844 Y159.161 E-.01848
G1 X44.682 Y158.668 E-.36152
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X47.92 Y163.195 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X48.25 Y163.125 E.01139
G1 X50.182 Y155.93 E.25217
G1 X42.987 Y157.847 E.25206
G1 X48.261 Y163.122 E.25248
G1 X48.582 Y163.018 E.0114
; OBJECT_ID: 14
; WIPE_START
G1 X48.261 Y163.122 E-.06402
G1 X47.085 Y161.946 E-.31598
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X39.785 Y159.718 Z6 F36000
G1 X26.616 Y155.698 Z6
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.494 Y155.664 E.00427
G2 X25.964 Y155.595 I-.702 J3.334 E.01812
G2 X25.638 Y155.594 I-.171 J3.088 E.01102
G2 X26.84 Y155.756 I.154 J3.403 E.68334
G1 X26.674 Y155.713 E.0058
M204 S10000
G1 X26.511 Y156.09 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.062 E.00355
G2 X25.942 Y156.002 I-.618 J2.936 E.01596
G2 X25.658 Y156.001 I-.15 J2.701 E.00964
G2 X26.714 Y156.143 I.134 J2.997 E.60179
G1 X26.569 Y156.105 E.00507
M204 S250
G1 X26.409 Y156.469 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.446 E.00264
G2 X25.922 Y156.393 I-.537 J2.552 E.01286
G2 X25.677 Y156.393 I-.129 J2.333 E.00769
G2 X26.592 Y156.516 I.115 J2.606 E.48469
G1 X26.467 Y156.484 E.00405
; WIPE_START
M204 S3000
G1 X26.328 Y156.446 E-.0274
G1 X25.922 Y156.393 E-.07783
G1 X25.677 Y156.393 E-.0466
G1 X25.243 Y156.447 E-.08309
G1 X24.979 Y156.518 E-.05189
G1 X24.724 Y156.616 E-.05192
G1 X24.533 Y156.719 E-.04127
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.993 Y154.32 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.54 Y154.321 I-.217 J4.308 E.01533
G2 X26.053 Y154.323 I.237 J4.678 E.97889
M204 S10000
G1 X26.004 Y153.913 F36000
G1 F1473.913
M204 S3000
G2 X25.519 Y153.915 I-.23 J4.616 E.01642
G2 X26.064 Y153.916 I.256 J5.085 E1.06443
M204 S250
G1 X26.01 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.499 Y153.524 E.01605
G2 X25.212 Y153.545 I.293 J5.973 E.00901
G2 X26.07 Y153.524 I.565 J5.454 E1.05331
; WIPE_START
M204 S3000
G1 X25.499 Y153.524 E-.10864
G1 X25.212 Y153.545 E-.05459
G1 X24.645 Y153.635 E-.10907
G1 X24.097 Y153.782 E-.1077
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.572 Y154.669 Z6 F36000
G1 Z5.6
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X26.618 Y154.747 I.201 J4.357 E.0356
G1 X26.468 Y155.308 E.01965
G1 X27.552 Y155.04 E.03781
G1 X27.346 Y154.96 E.0075
G1 X29.835 Y157.45 E.11917
G1 X29.743 Y157.242 E.0077
G1 X29.477 Y158.317 E.03751
G1 X30.036 Y158.168 E.01957
G3 X30.116 Y159.213 I-4.614 J.88 E.03557
M204 S10000
G1 X29.524 Y159.376 F36000
G1 F1473.913
M204 S3000
G1 X29.537 Y158.879 E.01684
G1 X30.096 Y159.416 E.02624
G1 X29.494 Y159.577 E.0211
G3 X29.286 Y160.354 I-3.712 J-.578 E.02729
G1 X29.726 Y160.795 E.02111
G1 X28.974 Y160.981 E.02623
G2 X29.211 Y160.544 I-1.96 J-1.345 E.01686
M204 S10000
G1 X29.642 Y160.981 F36000
G1 F1473.913
M204 S3000
G3 X29.053 Y161.849 I-4.612 J-2.493 E.03559
G1 X28.641 Y161.437 E.01973
G1 X28.331 Y162.51 E.03781
G1 X28.504 Y162.371 E.0075
G1 X25.103 Y163.282 E.11917
G1 X25.329 Y163.306 E.0077
G1 X24.531 Y162.538 E.0375
G1 X24.381 Y163.097 E.01958
G3 X23.439 Y162.64 I1.986 J-5.29 E.03547
M204 S10000
G1 X23.59 Y162.05 F36000
G1 F1473.913
M204 S3000
G2 X24.014 Y162.31 I1.449 J-1.885 E.01686
G1 X23.247 Y162.515 E.02688
G1 X23.431 Y161.923 E.02099
G3 X22.858 Y161.355 I4.261 J-4.88 E.02734
G1 X22.27 Y161.538 E.02083
G1 X22.475 Y160.773 E.02682
G2 X22.738 Y161.191 I2.107 J-1.032 E.01674
M204 S10000
G1 X22.145 Y161.346 F36000
G1 F1473.913
M204 S3000
G3 X21.688 Y160.404 I4.827 J-2.924 E.03547
G1 X22.247 Y160.255 E.01957
G1 X21.479 Y159.456 E.0375
G1 X21.503 Y159.682 E.0077
G1 X22.414 Y156.282 E.11917
G1 X22.275 Y156.454 E.00751
G1 X23.348 Y156.144 E.03781
G1 X22.938 Y155.734 E.01965
G3 X23.806 Y155.148 I2.937 J3.42 E.03552
M204 S10000
G1 X24.242 Y155.574 F36000
G1 F1473.913
M204 S3000
G2 X23.805 Y155.811 I.907 J2.195 E.01686
G1 X24.01 Y155.044 E.02688
G1 X24.431 Y155.5 E.02099
G3 X25.206 Y155.298 I1.215 J3.075 E.02719
G1 X25.37 Y154.689 E.02132
G1 X25.905 Y155.247 E.02617
G2 X25.408 Y155.272 I-.149 J1.947 E.01688
; WIPE_START
G1 X25.905 Y155.247 E-.09447
G1 X25.37 Y154.689 E-.14687
G1 X25.206 Y155.298 E-.11967
G1 X25.11 Y155.323 E-.01898
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.714 Y155.36 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X27.62 Y155.726 I-2.621 J7.811 E.0331
G1 X27.774 Y155.153 E.02008
; WIPE_START
G1 X27.62 Y155.726 E-.14351
G1 X26.714 Y155.36 E-.23649
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.201 Y156.131 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X28.863 Y155.953 E.02318
G1 X28.832 Y155.922 E.00148
G1 X28.656 Y156.581 E.02307
; WIPE_START
G1 X28.832 Y155.922 E-.18368
G1 X28.863 Y155.953 E-.01178
G1 X28.201 Y156.131 E-.18454
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.637 Y157.01 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X29.054 Y157.166 E.02044
G3 X29.425 Y158.071 I-5.896 J2.946 E.03314
; WIPE_START
G1 X29.054 Y157.166 E-.23496
G1 X29.637 Y157.01 E-.14504
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.467 Y161.626 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X27.699 Y162.222 I-2.504 J-2.433 E.03303
G1 X28.123 Y162.646 E.02028
; WIPE_START
G1 X27.699 Y162.222 E-.14484
G1 X28.467 Y161.626 E-.23516
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.061 Y162.532 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X26.908 Y163.189 E.02284
G1 X26.446 Y162.696 E.02284
; WIPE_START
G1 X26.908 Y163.189 E-.19002
G1 X27.061 Y162.532 E-.18998
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.583 Y163.331 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X25.739 Y162.747 E.02044
G3 X24.776 Y162.615 I-.011 J-3.493 E.03303
; WIPE_START
G1 X25.739 Y162.747 E-.23444
G1 X25.583 Y163.331 E-.14556
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.169 Y160.016 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G3 X22.036 Y159.047 I7.36 J-1.508 E.03312
G1 X21.455 Y159.203 E.02035
; WIPE_START
G1 X22.036 Y159.047 E-.14471
M73 P86 R6
G1 X22.169 Y160.016 E-.23529
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.09 Y158.34 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X21.597 Y157.878 E.02288
G1 X22.255 Y157.724 E.02289
; WIPE_START
G1 X21.597 Y157.878 E-.19006
G1 X22.09 Y158.34 E-.18994
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.14 Y156.663 Z6 F36000
G1 Z5.6
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.557 Y157.08 E.01998
G3 X23.16 Y156.318 I3.363 J2.04 E.03297
; CHANGE_LAYER
; Z_HEIGHT: 5.8
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X22.557 Y157.08 E-.23637
G1 X22.14 Y156.663 E-.14363
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L29
M991 S0 P28 ;notify layer change


M204 S10000
G17
G3 Z6 I1.217 J0 P1  F36000
; object ids of layer 29 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer29 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.03 Y93.547
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X228.716 Y93.672 E.01144
G2 X230.395 Y93.357 I1.494 J3.338 E.71936
G2 X230.041 Y93.356 I-.184 J3.351 E.01197
G2 X229.087 Y93.529 I.169 J3.653 E.03291
M204 S10000
G1 X229.176 Y93.927 F36000
G1 F1473.913
M204 S3000
G1 X228.882 Y94.043 E.01072
G2 X230.373 Y93.764 I1.328 J2.966 E.63932
G2 X230.061 Y93.763 I-.163 J2.963 E.01058
G2 X229.234 Y93.91 I.149 J3.246 E.02853
M204 S250
G1 X229.316 Y94.293 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.041 Y94.402 E.00929
G2 X230.353 Y94.155 I1.168 J2.608 E.5208
G2 X230.08 Y94.155 I-.143 J2.594 E.00855
G2 X229.374 Y94.277 I.129 J2.855 E.02253
; WIPE_START
M204 S3000
G1 X229.041 Y94.402 E-.06751
G1 X228.645 Y94.613 E-.08523
G1 X228.403 Y94.789 E-.05689
G1 X228.181 Y94.989 E-.05686
G1 X227.98 Y95.212 E-.05688
G1 X227.805 Y95.453 E-.05663
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.827 Y92.527 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.625 E.01093
G2 X230.397 Y92.32 I1.677 J4.386 E.93382
G2 X229.712 Y92.34 I-.189 J5.116 E.02322
G2 X228.987 Y92.474 I.484 J4.671 E.02497
G1 X228.884 Y92.508 E.00369
M204 S10000
G1 X228.701 Y92.14 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.245 E.01166
G2 X230.417 Y91.913 I1.822 J4.766 E1.0147
G2 X229.67 Y91.936 I-.207 J5.563 E.02533
G2 X228.882 Y92.08 I.526 J5.076 E.02714
G1 X228.758 Y92.121 E.00441
M204 S250
G1 X228.579 Y91.764 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.504 Y91.783 E.00242
G2 X230.436 Y91.521 I1.691 J5.228 E1.02109
G2 X229.629 Y91.545 I-.226 J5.999 E.02535
G2 X229.06 Y91.635 I.567 J5.466 E.01805
G1 X228.637 Y91.749 E.01374
; WIPE_START
M204 S3000
G1 X228.504 Y91.783 E-.02609
G1 X227.968 Y91.99 E-.10929
G1 X227.708 Y92.114 E-.05474
G1 X227.21 Y92.402 E-.1093
G1 X226.866 Y92.651 E-.08057
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X229.078 Y92.991 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.67279
G1 F952.578
M204 S3000
G1 X228.504 Y93.195 E.0319
G2 X226.025 Y97.012 I1.698 J3.817 E.25206
G1 X226.075 Y97.657 E.0339
G1 X226.17 Y98.101 E.02377
G1 X226.386 Y98.711 E.0339
G1 X226.695 Y99.28 E.03392
G1 X226.962 Y99.647 E.02378
G1 X227.408 Y100.117 E.03391
G1 X227.921 Y100.511 E.0339
G1 X228.314 Y100.738 E.02374
G2 X229.135 Y92.973 I1.889 J-3.726 E.84651
; OBJECT_ID: 12
; WIPE_START
G1 X228.504 Y93.195 E-.12712
G1 X228.121 Y93.389 E-.08156
G1 X227.92 Y93.512 E-.04476
G1 X227.574 Y93.765 E-.08149
G1 X227.397 Y93.923 E-.04506
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.215 Y96.505 Z6.2 F36000
G1 X211.762 Y99.544 Z6.2
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.817 Y99.486 E.00271
G2 X208.982 Y93.121 I-3.032 J-2.464 E.29127
G2 X208.605 Y93.12 I-.196 J3.577 E.01277
G2 X211.542 Y99.79 I.18 J3.902 E.51294
G1 X211.722 Y99.589 E.00911
M204 S10000
G1 X211.46 Y99.272 F36000
G1 F1473.913
M204 S3000
G1 X211.5 Y99.23 E.00199
G2 X208.961 Y93.527 I-2.716 J-2.207 E.26096
G2 X208.625 Y93.526 I-.175 J3.189 E.01138
G2 X211.255 Y99.502 I.16 J3.496 E.45955
G1 X211.42 Y99.317 E.00839
M204 S250
G1 X211.169 Y99.01 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.196 Y98.983 E.0012
G2 X208.94 Y93.919 I-2.412 J-1.96 E.21468
G2 X208.644 Y93.918 I-.155 J2.82 E.0093
G2 X210.977 Y99.225 I.14 J3.105 E.37806
G1 X211.129 Y99.055 E.00713
; WIPE_START
M204 S3000
G1 X211.196 Y98.983 E-.01868
G1 X211.386 Y98.719 E-.06186
G1 X211.549 Y98.437 E-.06187
G1 X211.681 Y98.139 E-.06185
G1 X211.82 Y97.671 E-.09274
G1 X211.87 Y97.35 E-.06182
G1 X211.876 Y97.238 E-.02119
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.605 Y99.196 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X204.694 Y99.382 E.00699
G2 X208.972 Y92.32 I4.076 J-2.358 E.66067
G2 X208.285 Y92.341 I-.189 J5.127 E.02329
G2 X204.47 Y98.943 I.485 J4.684 E.30079
G1 X204.577 Y99.143 E.00768
M204 S10000
G1 X204.243 Y99.38 F36000
G1 F1473.913
M204 S3000
G1 X204.341 Y99.586 E.00772
G2 X208.992 Y91.913 I4.428 J-2.561 E.71771
G2 X208.243 Y91.936 I-.208 J5.579 E.02539
G2 X204.098 Y99.108 I.527 J5.089 E.32678
G1 X204.214 Y99.327 E.00841
M204 S250
G1 X203.894 Y99.558 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.002 Y99.782 E.00779
G2 X209.011 Y91.521 I4.768 J-2.758 E.7157
G2 X208.202 Y91.546 I-.226 J6.011 E.02541
G2 X203.739 Y99.268 I.568 J5.479 E.32588
G1 X203.865 Y99.505 E.00843
; WIPE_START
M204 S3000
G1 X204.002 Y99.782 E-.05863
G1 X204.32 Y100.263 E-.1096
G1 X204.683 Y100.711 E-.10957
G1 X205.064 Y101.091 E-.10221
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.934 Y98.961 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435906
G1 F1526.771
M204 S3000
G1 X205.043 Y99.175 E.00784
G2 X204.468 Y97.019 I3.735 J-2.15 E.81108
G1 X204.492 Y97.48 E.01508
G2 X204.841 Y98.777 I4.285 J-.456 E.04407
G1 X204.907 Y98.908 E.00477
; OBJECT_ID: 11
; WIPE_START
G1 X205.043 Y99.175 E-.05696
G1 X205.288 Y99.554 E-.08571
G1 X205.432 Y99.741 E-.04485
G1 X205.73 Y100.072 E-.08472
G1 X206.061 Y100.371 E-.08474
G1 X206.159 Y100.442 E-.02302
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.758 Y98.579 Z6.2 F36000
G1 X183.811 Y94.816 Z6.2
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.626 Y95.155 E.01307
G2 X187.542 Y92.885 I3.706 J1.882 E.72198
G2 X187.141 Y92.884 I-.209 J3.802 E.01358
G2 X183.849 Y94.769 I.191 J4.152 E.13335
M204 S10000
G1 X184.164 Y95.019 F36000
G1 F1473.913
M204 S3000
G1 X183.989 Y95.34 E.01235
G2 X187.521 Y93.292 I3.343 J1.697 E.6513
G2 X187.161 Y93.291 I-.188 J3.414 E.01218
G2 X184.201 Y94.973 I.171 J3.746 E.1196
M204 S250
G1 X184.503 Y95.215 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.337 Y95.517 E.0108
G2 X187.5 Y93.684 I2.994 J1.52 E.54026
G2 X187.18 Y93.683 I-.168 J3.044 E.01004
G2 X184.54 Y95.171 I.152 J3.354 E.09858
; WIPE_START
M204 S3000
G1 X184.337 Y95.517 E-.07619
G1 X184.187 Y95.835 E-.06676
G1 X184.079 Y96.169 E-.0668
G1 X184.006 Y96.514 E-.06685
G1 X183.964 Y97.039 E-.10017
G1 X183.965 Y97.056 E-.00323
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.52 Y92.32 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X186.83 Y92.341 I-.19 J5.146 E.02336
G2 X187.58 Y92.323 I.487 J4.698 E.97915
M204 S10000
G1 X187.539 Y91.913 F36000
G1 F1473.913
M204 S3000
G2 X186.788 Y91.936 I-.209 J5.594 E.02546
G2 X187.599 Y91.916 I.529 J5.103 E1.06364
M204 S250
G1 X187.551 Y91.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.524 E.01618
G2 X186.747 Y91.546 I.296 J6.028 E.00907
G2 X187.611 Y91.524 I.57 J5.493 E1.06083
; WIPE_START
M204 S3000
G1 X187.035 Y91.524 E-.10943
G1 X186.747 Y91.546 E-.05498
G1 X186.176 Y91.636 E-.10985
G1 X185.638 Y91.78 E-.10574
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.555 Y92.609 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200506
G1 F3807.457
M204 S3000
G1 X187.322 Y92.597 E.00305
G2 X182.882 Y97.039 I.002 J4.442 E.09141
G1 X182.907 Y97.506 E.00612
G2 X187.787 Y92.621 I4.417 J-.467 E.26208
G1 X187.614 Y92.612 E.00226
; OBJECT_ID: 10
; WIPE_START
G1 X187.322 Y92.597 E-.05562
G1 X186.863 Y92.621 E-.08737
G1 X186.401 Y92.694 E-.08894
G1 X185.952 Y92.815 E-.08831
G1 X185.658 Y92.927 E-.05976
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.028 Y93.138 Z6.2 F36000
G1 X163.17 Y93.548 Z6.2
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.069 Y93.633 E.00449
G2 X166.071 Y92.652 I2.78 J3.422 E.82831
G2 X165.647 Y92.651 I-.222 J4.034 E.01438
G2 X163.252 Y93.492 I.202 J4.404 E.08715
G1 X163.22 Y93.514 E.00132
M204 S10000
G1 X163.429 Y93.867 F36000
G1 F1473.913
M204 S3000
G1 X163.325 Y93.95 E.00447
G2 X166.05 Y93.058 I2.523 J3.103 E.75133
G2 X165.667 Y93.057 I-.201 J3.647 E.01299
G2 X163.663 Y93.703 I.182 J3.995 E.07208
G1 X163.478 Y93.833 E.00767
M204 S250
G1 X163.659 Y94.184 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.572 Y94.254 E.00349
G2 X166.029 Y93.45 I2.276 J2.799 E.62777
G2 X165.685 Y93.449 I-.18 J3.275 E.01079
G2 X163.877 Y94.032 I.163 J3.604 E.06028
G1 X163.708 Y94.15 E.00646
; WIPE_START
M204 S3000
G1 X163.572 Y94.254 E-.03255
G1 X163.288 Y94.502 E-.07172
M73 P87 R6
G1 X163.035 Y94.783 E-.0718
G1 X162.813 Y95.089 E-.07178
G1 X162.542 Y95.587 E-.10767
G1 X162.496 Y95.707 E-.02448
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.145 Y101.483 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.037 Y92.32 I1.688 J-4.428 E.55553
G2 X165.345 Y92.341 I-.19 J5.167 E.02344
G2 X164.089 Y101.462 I.488 J4.714 E.42695
M204 S10000
G1 X163.998 Y101.863 F36000
G1 F1473.913
M204 S3000
G2 X166.056 Y91.913 I1.835 J-4.808 E.60324
G2 X165.302 Y91.936 I-.209 J5.612 E.02554
G2 X163.942 Y101.841 I.53 J5.119 E.46373
M204 S250
G1 X163.855 Y102.227 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.855 Y102.228 E.00005
G2 X166.075 Y91.521 I1.977 J-5.174 E.60134
G2 X165.261 Y91.546 I-.227 J6.049 E.02555
G2 X163.537 Y102.095 I.571 J5.509 E.45339
G1 X163.799 Y102.204 E.00892
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X163.855 Y102.228 E-.01163
G1 X164.407 Y102.406 E-.11006
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.75 Y102.587 E-.03794
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.966 Y106.085 Z6.2 F36000
G1 X47.385 Y163.611 Z6.2
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X47.334 Y154.32 I-.25 J-4.644 E.47936
G2 X46.655 Y154.34 I-.187 J5.074 E.02299
G2 X47.325 Y163.614 I.479 J4.626 E.48479
M204 S10000
G1 X47.386 Y164.019 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.017 E.00068
G2 X47.354 Y153.913 I-.272 J-5.051 E.52124
G2 X46.613 Y153.935 I-.205 J5.519 E.0251
G2 X46.877 Y164.018 I.521 J5.031 E.5115
G1 X47.326 Y164.019 E.0152
M204 S250
G1 X47.386 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00127
G2 X47.373 Y153.521 I-.293 J-5.442 E.5202
G2 X46.572 Y153.545 I-.224 J5.954 E.02514
G2 X46.857 Y164.41 I.562 J5.421 E.51052
G1 X47.326 Y164.411 E.01472
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.0191
G1 X47.994 Y164.351 E-.10844
G1 X48.553 Y164.233 E-.10842
G1 X49.095 Y164.056 E-.10845
G1 X49.267 Y163.98 E-.0356
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.602 Y163.231 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G3 X45.611 Y162.988 I.623 J-4.684 E.03461
G1 X47.826 Y154.724 E.2896
G3 X48.807 Y155.003 I-.715 J4.383 E.03463
M204 S10000
G1 X49.231 Y155.208 F36000
G1 F1473.913
M204 S3000
G3 X50.063 Y155.811 I-7.216 J10.844 E.03479
G1 X48.094 Y163.158 E.25747
G2 X48.412 Y163.073 I-.245 J-1.552 E.01116
G1 X43.036 Y157.696 E.25736
G2 X42.951 Y158.014 I1.469 J.564 E.01116
G1 X50.298 Y156.046 E.25747
G3 X50.897 Y156.876 I-4.791 J4.087 E.03468
M204 S10000
G1 X51.104 Y157.302 F36000
G1 F1473.913
M204 S3000
G3 X51.389 Y158.282 I-4.363 J1.8 E.03461
G1 X43.125 Y160.496 E.28962
G2 X43.534 Y161.303 I4.084 J-1.568 E.03067
G1 X45.187 Y155.133 E.2162
G1 X45.51 Y154.989 E.01195
G1 X51.12 Y160.599 E.26854
G3 X50.973 Y160.922 I-2.265 J-.832 E.01201
G1 X44.798 Y162.576 E.21639
G1 X44.513 Y162.369 E.01195
G1 X46.566 Y154.706 E.26852
G1 X46.917 Y154.669 E.01195
G1 X51.439 Y159.191 E.21647
G1 X51.402 Y159.543 E.01195
G1 X43.74 Y161.596 E.26849
G2 X44.355 Y162.241 I3.006 J-2.248 E.03023
; WIPE_START
G1 X43.74 Y161.596 E-.16931
G1 X44.812 Y161.308 E-.21069
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.606 Y163.01 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G2 X49.522 Y162.55 I-5.522 J-12.134 E.0347
G1 X50.994 Y157.054 E.19259
G1 X51.022 Y157.116 E.00229
G1 X42.856 Y159.304 E.28615
G1 X42.849 Y159.237 E.00229
G1 X46.872 Y163.26 E.19258
G1 X46.805 Y163.253 E.00229
G1 X48.993 Y155.087 E.28615
G1 X49.049 Y155.116 E.00215
G1 X43.564 Y156.586 E.19223
G1 X43.599 Y156.532 E.00216
G1 X49.576 Y162.51 E.28615
G2 X50.474 Y161.681 I-3.075 J-4.229 E.04146
G1 X44.428 Y155.635 E.28942
G2 X43.717 Y156.367 I2.804 J3.432 E.03463
; OBJECT_ID: 14
; WIPE_START
G1 X44.428 Y155.635 E-.19395
G1 X45.12 Y156.327 E-.18605
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X37.493 Y156.063 Z6.2 F36000
G1 X26.567 Y155.685 Z6.2
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X26.319 Y155.632 E.0086
G2 X25.964 Y155.595 I-.527 J3.366 E.01208
G2 X25.634 Y155.594 I-.172 J3.124 E.01116
G2 X26.668 Y155.706 I.158 J3.403 E.68925
G1 X26.626 Y155.697 E.00146
M204 S10000
G1 X26.483 Y156.083 F36000
G1 F1473.913
M204 S3000
G1 X26.255 Y156.034 E.00787
G2 X25.942 Y156.002 I-.464 J2.964 E.01064
G2 X25.654 Y156.001 I-.151 J2.736 E.00977
G2 X26.563 Y156.099 I.137 J2.997 E.60699
G1 X26.541 Y156.095 E.00074
M204 S250
G1 X26.401 Y156.466 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.194 Y156.422 E.00665
G2 X25.922 Y156.393 I-.403 J2.577 E.00857
G2 X25.673 Y156.393 I-.13 J2.367 E.00781
G2 X26.461 Y156.478 I.118 J2.605 E.48886
M73 P87 R5
G1 X26.46 Y156.478 E.00004
; WIPE_START
M204 S3000
G1 X26.194 Y156.422 E-.0517
G1 X25.922 Y156.393 E-.05193
G1 X25.673 Y156.393 E-.0473
G1 X25.243 Y156.447 E-.0824
G1 X24.979 Y156.518 E-.05188
G1 X24.724 Y156.616 E-.05194
G1 X24.523 Y156.718 E-.04285
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.979 Y154.32 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.295 Y154.34 I-.188 J5.101 E.02317
G2 X26.039 Y154.323 I.483 J4.659 E.97102
M204 S10000
G1 X25.999 Y153.913 F36000
G1 F1473.913
M204 S3000
G2 X25.253 Y153.935 I-.207 J5.553 E.02527
G2 X26.059 Y153.916 I.525 J5.064 E1.0555
M204 S250
G1 X26.015 Y153.521 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.499 Y153.524 E.01619
G2 X25.212 Y153.545 I.294 J5.982 E.00901
G2 X26.075 Y153.524 I.565 J5.454 E1.05317
; WIPE_START
M204 S3000
G1 X25.499 Y153.524 E-.10949
G1 X25.212 Y153.545 E-.05459
G1 X24.645 Y153.635 E-.10907
G1 X24.102 Y153.781 E-.10685
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.717 Y155.807 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
; FEATURE: Sparse infill
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X28.541 Y156.462 E.02297
G1 X28.333 Y156.242 E.01026
G1 X28.978 Y156.069 E.0226
; WIPE_START
G1 X28.333 Y156.242 E-.15383
G1 X28.541 Y156.462 E-.06982
G1 X28.717 Y155.807 E-.15635
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X27.082 Y163.132 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X26.611 Y162.661 E.02253
G2 X26.901 Y162.584 I-.224 J-1.415 E.01016
G1 X26.728 Y163.227 E.02253
M204 S10000
G1 X25.896 Y163.331 F36000
G1 F1473.913
M204 S3000
G3 X25.553 Y163.33 I-.168 J-1.638 E.01162
G1 X24.86 Y162.638 E.03314
G2 X25.594 Y162.743 I.846 J-3.27 E.02512
G1 X25.44 Y163.318 E.02013
G1 X28.244 Y162.567 E.09826
G1 X27.83 Y162.153 E.0198
G2 X28.408 Y161.677 I-2.447 J-3.561 E.02537
G1 X28.152 Y162.634 E.03352
G3 X27.855 Y162.805 I-.972 J-1.335 E.01162
M204 S10000
G1 X28.408 Y162.447 F36000
G1 F1473.913
M204 S3000
G2 X29.141 Y161.737 I-3.666 J-4.517 E.03458
G1 X28.731 Y161.327 E.01965
G2 X28.859 Y161.158 I-.738 J-.695 E.00718
G1 X29.661 Y160.943 E.0281
G2 X29.788 Y160.657 I-1.883 J-1.012 E.01061
G1 X29.342 Y160.21 E.02139
G2 X29.463 Y159.732 I-1.8 J-.71 E.01675
G1 X30.08 Y159.566 E.02164
G1 X30.113 Y159.255 E.01061
G1 X29.524 Y158.666 E.0282
G1 X29.502 Y158.457 E.0071
G1 X30.065 Y158.306 E.01973
G2 X29.698 Y157.14 I-5.715 J1.158 E.04145
G1 X29.133 Y157.292 E.01981
G3 X29.399 Y157.977 I-4.924 J2.309 E.02492
G1 X29.649 Y157.044 E.0327
G1 X29.67 Y157.084 E.00151
G1 X27.701 Y155.116 E.09422
G1 X27.741 Y155.136 E.0015
G1 X26.808 Y155.386 E.03269
G3 X27.492 Y155.651 I-.923 J3.391 E.02487
G1 X27.645 Y155.087 E.01979
G2 X26.478 Y154.725 I-2.842 J7.096 E.04141
G1 X26.328 Y155.283 E.01956
G1 X26.12 Y155.261 E.0071
G1 X25.531 Y154.672 E.0282
G1 X25.219 Y154.705 E.01061
G1 X25.055 Y155.317 E.02143
G2 X24.575 Y155.444 I1.116 J5.159 E.0168
G1 X24.128 Y154.997 E.0214
G1 X23.842 Y155.125 E.01061
G1 X23.627 Y155.926 E.02809
G2 X23.459 Y156.055 I.526 J.865 E.00718
G1 X23.048 Y155.644 E.01965
G2 X22.218 Y156.541 I5.181 J5.624 E.04141
G1 X22.636 Y156.959 E.01998
G3 X23.097 Y156.38 I3.179 J2.062 E.02509
G1 X22.16 Y156.631 E.03286
G1 X22.184 Y156.594 E.00151
G1 X21.467 Y159.346 E.09625
G1 X22.032 Y159.194 E.01981
G2 X22.144 Y159.921 I5.411 J-.461 E.02492
G1 X21.455 Y159.232 E.03298
G3 X21.455 Y158.891 I1.676 J-.173 E.01159
M204 S10000
G1 X21.487 Y159.548 F36000
G1 F1473.913
M204 S3000
G2 X21.732 Y160.539 I5.284 J-.778 E.0346
G1 X22.295 Y160.388 E.01973
G1 X22.38 Y160.58 E.0071
G1 X22.165 Y161.384 E.0282
G1 X22.349 Y161.638 E.01061
G1 X22.96 Y161.474 E.0214
G2 X23.311 Y161.826 I4.226 J-3.876 E.01682
G1 X23.147 Y162.436 E.0214
G2 X23.407 Y162.619 I.999 J-1.142 E.01076
G1 X24.203 Y162.406 E.02789
G2 X24.398 Y162.487 I.488 J-.891 E.00718
G1 X24.246 Y163.053 E.01983
G2 X25.237 Y163.297 I1.625 J-4.48 E.03461
; WIPE_START
G1 X24.246 Y163.053 E-.19388
G1 X24.398 Y162.487 E-.11132
G1 X24.203 Y162.406 E-.04025
G1 X24.027 Y162.453 E-.03455
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.558 Y158.057 Z6.2 F36000
G1 Z5.8
G1 E.4 F1800
G1 F1473.913
M204 S3000
G1 X22.202 Y157.884 E.02256
G1 X22.13 Y158.18 E.01029
G1 X21.653 Y157.703 E.02281
; CHANGE_LAYER
; Z_HEIGHT: 6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1473.913
G1 X22.13 Y158.18 E-.15571
G1 X22.202 Y157.884 E-.07027
G1 X21.558 Y158.057 E-.15401
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L30
M991 S0 P29 ;notify layer change


M204 S10000
G17
G3 Z6.2 I1.217 J0 P1  F36000
; object ids of layer 30 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer30 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.029 Y93.548
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
G1 F1473.913
M204 S3000
G1 X228.716 Y93.671 E.01138
G2 X230.395 Y93.357 I1.493 J3.338 E.71937
G2 X230.037 Y93.356 I-.185 J3.396 E.01212
G2 X229.086 Y93.529 I.172 J3.653 E.03282
M204 S10000
G1 X229.174 Y93.928 F36000
G1 F1473.913
M204 S3000
G1 X228.882 Y94.043 E.01065
G2 X230.373 Y93.764 I1.327 J2.967 E.63933
G2 X230.057 Y93.763 I-.164 J3.008 E.01072
G2 X229.232 Y93.91 I.152 J3.246 E.02845
M204 S250
G1 X229.315 Y94.293 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.041 Y94.401 E.00922
G2 X230.353 Y94.155 I1.167 J2.609 E.5208
G2 X230.076 Y94.155 I-.144 J2.635 E.00868
G2 X229.372 Y94.277 I.132 J2.855 E.02246
; WIPE_START
M204 S3000
G1 X229.041 Y94.401 E-.06719
G1 X228.773 Y94.535 E-.05687
G1 X228.522 Y94.698 E-.05687
G1 X228.181 Y94.989 E-.08527
G1 X227.98 Y95.212 E-.0569
G1 X227.804 Y95.454 E-.05689
G1 X227.804 Y95.454 E-.00001
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.857 Y92.517 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.522 Y92.623 E.01189
G2 X230.405 Y92.32 I1.671 J4.389 E.93373
G2 X229.958 Y92.321 I-.213 J4.266 E.01517
G2 X228.987 Y92.473 I.236 J4.69 E.03331
G1 X228.914 Y92.498 E.00261
M204 S10000
G1 X228.732 Y92.13 F36000
G1 F1473.913
M204 S3000
M73 P88 R5
G1 X228.375 Y92.243 E.01266
G2 X230.425 Y91.913 I1.818 J4.768 E1.01456
G2 X229.936 Y91.915 I-.233 J4.662 E.01656
G2 X228.882 Y92.079 I.257 J5.097 E.0362
G1 X228.788 Y92.111 E.00333
M204 S250
G1 X228.611 Y91.758 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.233 Y91.877 E.01242
G2 X230.444 Y91.522 I1.96 J5.134 E1.01189
G2 X229.916 Y91.523 I-.253 J5.042 E.01659
G2 X228.78 Y91.701 I.277 J5.488 E.0361
G1 X228.667 Y91.739 E.00373
; WIPE_START
M204 S3000
G1 X228.233 Y91.877 E-.08665
G1 X227.926 Y92.01 E-.06356
G1 X227.455 Y92.252 E-.10053
G1 X226.972 Y92.565 E-.10934
G1 X226.891 Y92.631 E-.01992
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X229.075 Y92.991 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672783
G1 F952.588
M204 S3000
G1 X228.711 Y93.11 E.02003
G2 X226.025 Y97.012 I1.491 J3.902 E.26378
G1 X226.075 Y97.657 E.03389
G1 X226.17 Y98.101 E.02378
G1 X226.386 Y98.711 E.0339
G1 X226.695 Y99.28 E.0339
G1 X226.962 Y99.647 E.02378
G1 X227.407 Y100.116 E.03389
G1 X227.921 Y100.511 E.03391
G1 X228.314 Y100.738 E.02378
G2 X229.132 Y92.974 I1.889 J-3.726 E.84666
; OBJECT_ID: 12
; WIPE_START
G1 X228.711 Y93.11 E-.08407
G1 X228.466 Y93.212 E-.05043
G1 X228.114 Y93.393 E-.07521
G1 X227.754 Y93.627 E-.08147
G1 X227.567 Y93.77 E-.04478
G1 X227.395 Y93.925 E-.04404
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.213 Y96.508 Z6.4 F36000
G1 X211.758 Y99.55 Z6.4
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.816 Y99.485 E.00294
G2 X208.982 Y93.121 I-3.032 J-2.463 E.29122
G2 X208.6 Y93.12 I-.198 J3.627 E.01294
G2 X211.542 Y99.789 I.184 J3.902 E.51285
G1 X211.717 Y99.594 E.00888
M204 S10000
G1 X211.455 Y99.277 F36000
G1 F1473.913
M204 S3000
G1 X211.5 Y99.229 E.00222
G2 X208.961 Y93.527 I-2.716 J-2.207 E.26091
G2 X208.62 Y93.526 I-.177 J3.239 E.01154
G2 X211.254 Y99.501 I.163 J3.496 E.45946
G1 X211.415 Y99.322 E.00816
M204 S250
G1 X211.164 Y99.015 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.195 Y98.982 E.00142
G2 X208.94 Y93.919 I-2.412 J-1.96 E.21463
G2 X208.639 Y93.918 I-.156 J2.865 E.00944
G2 X210.977 Y99.224 I.144 J3.104 E.37797
G1 X211.124 Y99.06 E.00691
; WIPE_START
M204 S3000
G1 X211.195 Y98.982 E-.01998
G1 X211.386 Y98.719 E-.06185
G1 X211.549 Y98.437 E-.06187
G1 X211.681 Y98.139 E-.06185
G1 X211.82 Y97.671 E-.09274
G1 X211.871 Y97.35 E-.06182
G1 X211.876 Y97.245 E-.01989
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.574 Y99.167 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X208.98 Y92.32 I4.194 J-2.142 E.66867
G2 X208.531 Y92.321 I-.214 J4.282 E.01521
G2 X204.547 Y99.113 I.237 J4.703 E.31562
M204 S10000
G1 X204.236 Y99.368 F36000
G1 F1473.913
M204 S3000
G1 X204.339 Y99.587 E.00819
G2 X209 Y91.913 I4.428 J-2.563 E.71735
G2 X208.51 Y91.915 I-.234 J4.678 E.0166
G2 X204.095 Y99.109 I.257 J5.11 E.336
G1 X204.208 Y99.315 E.00795
M204 S250
G1 X203.887 Y99.546 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X203.999 Y99.783 E.00823
G2 X209.019 Y91.522 I4.768 J-2.759 E.71537
G2 X208.489 Y91.523 I-.254 J5.058 E.01663
G2 X203.736 Y99.269 I.278 J5.501 E.33508
G1 X203.859 Y99.493 E.00801
; WIPE_START
M204 S3000
G1 X203.999 Y99.783 E-.06128
G1 X204.32 Y100.263 E-.10964
G1 X204.683 Y100.711 E-.10963
G1 X205.054 Y101.081 E-.09945
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.917 Y98.919 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435911
G1 F1526.752
M204 S3000
G1 X205.16 Y99.367 E.01667
G1 X205.432 Y99.741 E.01508
G1 X205.894 Y100.227 E.02193
G1 X206.426 Y100.636 E.02193
G1 X206.825 Y100.867 E.01506
G2 X204.468 Y97.025 I1.951 J-3.842 E.7297
G1 X204.52 Y97.693 E.02192
G1 X204.616 Y98.145 E.01509
G1 X204.84 Y98.777 E.02192
G1 X204.889 Y98.866 E.0033
; OBJECT_ID: 11
; WIPE_START
G1 X205.16 Y99.367 E-.10836
G1 X205.432 Y99.741 E-.08767
G1 X205.894 Y100.227 E-.1275
G1 X206.13 Y100.408 E-.05648
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.726 Y98.554 Z6.4 F36000
G1 X183.81 Y94.819 Z6.4
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.625 Y95.154 E.01294
G2 X187.542 Y92.885 I3.706 J1.882 E.72195
G2 X187.136 Y92.885 I-.21 J3.854 E.01375
G2 X183.846 Y94.772 I.195 J4.152 E.13331
M204 S10000
G1 X184.157 Y95.032 F36000
G1 F1473.913
M204 S3000
G1 X183.904 Y95.516 E.0185
G2 X187.521 Y93.292 I3.427 J1.521 E.64466
G2 X187.156 Y93.291 I-.189 J3.466 E.01235
G2 X184.193 Y94.984 I.175 J3.745 E.11991
M204 S250
G1 X184.501 Y95.219 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.337 Y95.517 E.01068
G2 X187.5 Y93.684 I2.994 J1.52 E.54024
G2 X187.175 Y93.683 I-.169 J3.093 E.01019
G2 X184.538 Y95.173 I.155 J3.354 E.09853
; WIPE_START
M204 S3000
G1 X184.337 Y95.517 E-.07573
G1 X184.187 Y95.835 E-.06678
G1 X184.079 Y96.169 E-.0668
G1 X184.006 Y96.514 E-.06685
G1 X183.964 Y97.039 E-.10017
G1 X183.965 Y97.058 E-.00367
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.528 Y92.32 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X187.077 Y92.321 I-.214 J4.293 E.01526
G2 X187.588 Y92.323 I.237 J4.718 E.98733
M204 S10000
G1 X187.548 Y91.913 F36000
G1 F1473.913
M204 S3000
G2 X187.056 Y91.915 I-.235 J4.688 E.01665
G2 X187.608 Y91.916 I.258 J5.124 E1.07248
M204 S250
G1 X187.556 Y91.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.525 E.01632
G2 X186.747 Y91.546 I.298 J6.052 E.00907
G2 X187.616 Y91.524 I.571 J5.493 E1.0607
; WIPE_START
M204 S3000
G1 X187.035 Y91.525 E-.11027
G1 X186.747 Y91.546 E-.05498
G1 X186.176 Y91.636 E-.10985
G1 X185.642 Y91.779 E-.1049
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.559 Y92.61 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200539
G1 F3806.659
M204 S3000
G1 X187.322 Y92.597 E.00311
G2 X182.882 Y97.039 I.002 J4.442 E.09143
G1 X182.907 Y97.506 E.00612
G2 X187.787 Y92.621 I4.417 J-.467 E.26213
G1 X187.619 Y92.613 E.0022
; OBJECT_ID: 10
; WIPE_START
G1 X187.322 Y92.597 E-.05647
G1 X186.86 Y92.622 E-.08794
G1 X186.401 Y92.694 E-.08837
G1 X185.952 Y92.815 E-.08832
G1 X185.662 Y92.926 E-.05891
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.033 Y93.135 Z6.4 F36000
G1 X163.186 Y93.541 Z6.4
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.069 Y93.633 E.00503
G2 X166.071 Y92.652 I2.779 J3.419 E.82777
G2 X165.641 Y92.651 I-.223 J4.085 E.01457
G2 X163.441 Y93.361 I.207 J4.401 E.07917
G1 X163.235 Y93.507 E.00855
M204 S10000
G1 X163.425 Y93.87 F36000
G1 F1473.913
M204 S3000
G1 X163.325 Y93.949 E.0043
G2 X166.05 Y93.058 I2.522 J3.104 E.75133
G2 X165.661 Y93.058 I-.202 J3.697 E.01317
G2 X163.663 Y93.703 I.186 J3.995 E.07191
G1 X163.474 Y93.836 E.00783
M204 S250
G1 X163.655 Y94.187 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.572 Y94.254 E.00334
G2 X166.029 Y93.45 I2.275 J2.799 E.62777
G2 X165.68 Y93.449 I-.182 J3.323 E.01095
G2 X163.877 Y94.031 I.167 J3.604 E.06013
G1 X163.704 Y94.152 E.00661
; WIPE_START
M204 S3000
G1 X163.572 Y94.254 E-.03164
G1 X163.288 Y94.502 E-.07176
G1 X162.92 Y94.933 E-.10764
G1 X162.714 Y95.25 E-.07179
G1 X162.543 Y95.587 E-.07178
G1 X162.494 Y95.711 E-.02539
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.144 Y101.484 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.045 Y92.32 I1.687 J-4.429 E.55514
G2 X165.593 Y92.321 I-.215 J4.307 E.01531
G2 X164.088 Y101.463 I.238 J4.734 E.43555
M204 S10000
G1 X163.997 Y101.864 F36000
G1 F1473.913
M204 S3000
G2 X166.065 Y91.913 I1.834 J-4.809 E.60284
G2 X165.571 Y91.915 I-.235 J4.702 E.0167
G2 X163.941 Y101.842 I.259 J5.14 E.47305
M204 S250
G1 X163.858 Y102.228 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.406 Y102.408 E.01808
G2 X166.084 Y91.522 I1.423 J-5.353 E.58278
G2 X165.551 Y91.523 I-.255 J5.082 E.01672
G2 X163.803 Y102.21 I.279 J5.532 E.47178
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.406 Y102.408 E-.12074
G1 X164.974 Y102.527 E-.11016
G1 X165.551 Y102.587 E-.11021
G1 X165.755 Y102.593 E-.03889
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
M73 P89 R5
G1 X158.971 Y106.089 Z6.4 F36000
G1 X47.348 Y163.608 Z6.4
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.592 E.00949
G2 X47.342 Y154.32 I-.496 J-4.625 E.47071
G2 X46.898 Y154.321 I-.211 J4.226 E.01502
G2 X47.142 Y163.618 I.234 J4.645 E.48703
G1 X47.288 Y163.611 E.00496
M204 S10000
G1 X47.369 Y164.014 F36000
G1 F1473.913
M204 S3000
G1 X47.67 Y163.996 E.01021
G2 X47.362 Y153.913 I-.539 J-5.03 E.51186
G2 X46.877 Y153.914 I-.231 J4.621 E.01642
G2 X47.142 Y164.025 I.255 J5.052 E.52964
G1 X47.309 Y164.017 E.00568
M204 S250
G1 X47.39 Y164.412 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00115
G2 X47.381 Y153.522 I-.296 J-5.442 E.51977
G2 X46.856 Y153.523 I-.251 J5 E.01646
G2 X47.142 Y164.417 I.275 J5.444 E.5286
G1 X47.33 Y164.413 E.00591
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.01835
G1 X47.994 Y164.351 E-.10843
G1 X48.553 Y164.233 E-.10842
G1 X49.095 Y164.056 E-.10841
G1 X49.27 Y163.978 E-.03639
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.292 Y162.905 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X50.394 Y161.803 E.05072
G2 X51.194 Y160.449 I-3.215 J-2.814 E.05147
G1 X48.624 Y163.02 E.11831
G3 X47.869 Y163.221 I-1.336 J-3.492 E.02548
G1 X51.396 Y159.694 E.16232
G2 X51.454 Y159.082 I-5.608 J-.843 E.02001
G1 X47.257 Y163.279 E.19316
G3 X46.724 Y163.259 I-.171 J-2.55 E.0174
G1 X51.434 Y158.549 E.21678
G2 X51.36 Y158.07 I-2.315 J.113 E.01581
G1 X46.245 Y163.185 E.23543
G3 X45.808 Y163.068 I.339 J-2.137 E.01473
G1 X51.247 Y157.629 E.25034
G1 X51.094 Y157.229 E.01394
G1 X45.404 Y162.918 E.26185
G3 X45.035 Y162.734 I1.062 J-2.586 E.01344
G1 X50.908 Y156.861 E.27031
G2 X50.695 Y156.521 I-1.728 J.847 E.01309
G1 X44.695 Y162.52 E.27613
G3 X44.381 Y162.281 I.982 J-1.613 E.01288
G1 X50.455 Y156.207 E.27956
G2 X50.191 Y155.918 I-1.506 J1.113 E.01277
G1 X44.092 Y162.016 E.28069
G3 X43.828 Y161.727 I1.243 J-1.403 E.01277
G1 X49.902 Y155.653 E.27956
G2 X49.588 Y155.414 I-1.296 J1.373 E.01288
G1 X43.588 Y161.413 E.27613
G3 X43.373 Y161.075 I2.034 J-1.528 E.01307
G1 X49.248 Y155.2 E.27037
G2 X48.88 Y155.015 I-1.067 J1.661 E.01344
G1 X43.193 Y160.701 E.26172
G3 X43.041 Y160.3 I1.824 J-.924 E.01399
G1 X48.48 Y154.861 E.25033
G2 X48.044 Y154.744 I-.768 J1.985 E.01473
G1 X42.923 Y159.864 E.23565
G3 X42.849 Y159.385 I2.248 J-.593 E.01581
G1 X47.564 Y154.67 E.21699
G2 X47.026 Y154.654 I-.376 J3.614 E.01752
G1 X42.829 Y158.851 E.19318
G3 X42.887 Y158.24 I5.661 J.231 E.02001
G1 X46.414 Y154.713 E.16232
G2 X45.659 Y154.914 I.58 J3.69 E.02548
G1 X43.089 Y157.485 E.11831
G3 X43.889 Y156.131 I4.015 J1.46 E.05147
G1 X44.991 Y155.029 E.05072
; OBJECT_ID: 14
; WIPE_START
G1 X43.889 Y156.131 E-.2961
G1 X43.648 Y156.429 E-.07283
G1 X43.616 Y156.478 E-.01107
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X35.992 Y156.123 Z6.4 F36000
G1 X26.564 Y155.685 Z6.4
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.319 Y155.632 E.0085
G2 X25.964 Y155.595 I-.528 J3.366 E.01207
G2 X25.63 Y155.595 I-.173 J3.166 E.0113
G2 X26.668 Y155.706 I.161 J3.403 E.68912
G1 X26.623 Y155.697 E.00157
M204 S10000
G1 X26.509 Y156.093 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.061 E.00351
G2 X25.785 Y155.998 I-.613 J2.938 E.02129
G1 X25.65 Y156.001 E.00458
G2 X26.863 Y156.193 I.147 J2.998 E.59653
G1 X26.566 Y156.109 E.01043
M204 S250
G1 X26.398 Y156.468 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.445 E.00229
G2 X25.785 Y156.39 I-.533 J2.555 E.01714
G1 X25.669 Y156.393 E.00364
G2 X26.722 Y156.56 I.127 J2.606 E.48043
G1 X26.455 Y156.484 E.00869
; WIPE_START
M204 S3000
G1 X26.328 Y156.445 E-.02526
G1 X26.058 Y156.404 E-.0519
G1 X25.785 Y156.39 E-.05192
G1 X25.669 Y156.393 E-.02207
G1 X25.243 Y156.447 E-.08168
G1 X24.979 Y156.518 E-.05191
G1 X24.724 Y156.616 E-.05191
G1 X24.52 Y156.719 E-.04334
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.987 Y154.32 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.54 Y154.321 I-.212 J4.253 E.01513
G2 X26.047 Y154.323 I.235 J4.679 E.97913
M204 S10000
G1 X26.007 Y153.913 F36000
G1 F1473.913
M204 S3000
G2 X25.519 Y153.915 I-.233 J4.649 E.01653
G2 X26.067 Y153.916 I.256 J5.085 E1.06433
M204 S250
G1 X26.019 Y153.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.498 Y153.523 E.01633
G2 X26.079 Y153.524 I.276 J5.477 E1.06213
; WIPE_START
M204 S3000
G1 X25.498 Y153.523 E-.11033
G1 X24.927 Y153.583 E-.10912
G1 X24.366 Y153.702 E-.10906
G1 X24.106 Y153.779 E-.05149
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.532 Y161.248 Z6.4 F36000
G1 X22.451 Y161.632 Z6.4
G1 Z6
G1 E.4 F1800
; Slow Down Start
; FEATURE: Floating vertical shell
; LINE_WIDTH: 0.478766
G1 F1376.635;_EXTRUDE_SET_SPEED
M204 S3000
G1 X22.086 Y161.11 E.02311
G1 X21.82 Y160.55 E.02245
G3 X21.578 Y159.643 I7.276 J-2.429 E.03404
G1 X21.533 Y158.8 E.03057
G3 X21.68 Y157.876 I7.354 J.695 E.03395
G1 X21.985 Y157.081 E.03085
G1 X22.35 Y156.481 E.02545
G1 X22.92 Y155.852 E.03075
G3 X23.679 Y155.3 I4.852 J5.868 E.03403
G1 X24.275 Y155.018 E.02391
G1 X25.142 Y154.79 E.03248
G1 X25.992 Y154.748 E.03086
G1 X26.689 Y154.839 E.02546
G1 X27.538 Y155.12 E.03241
G1 X28.307 Y155.568 E.03226
G1 X28.933 Y156.135 E.03059
G3 X29.486 Y156.89 I-6.256 J5.157 E.03395
G1 X29.765 Y157.489 E.02396
G3 X29.993 Y158.356 I-6.993 J2.299 E.03251
G1 X30.04 Y159.2 E.03062
G3 X29.893 Y160.124 I-8.352 J-.85 E.03395
G1 X29.685 Y160.708 E.02244
G3 X29.215 Y161.521 I-6.875 J-3.434 E.03406
G1 X28.652 Y162.15 E.03058
G3 X27.895 Y162.7 I-5.298 J-6.498 E.03394
G1 X27.335 Y162.965 E.02245
G3 X26.428 Y163.208 I-2.429 J-7.278 E.03405
G1 X25.585 Y163.254 E.03059
G3 X24.661 Y163.108 I.844 J-8.296 E.03395
G1 X24.039 Y162.882 E.02396
G3 X23.265 Y162.43 I3.29 J-6.524 E.0325
G1 X22.636 Y161.867 E.03062
G1 X22.488 Y161.679 E.00865
; Slow Down End
; WIPE_START
G1 X22.636 Y161.867 E-.04535
G1 X23.265 Y162.43 E-.16054
G1 X23.7 Y162.7 E-.09713
M73 P89 R4
G1 X24.039 Y162.882 E-.07324
G1 X24.058 Y162.889 E-.00374
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.942 Y156.443 Z6.4 F36000
G1 Z6
G1 E.4 F1800
; Slow Down Start
; LINE_WIDTH: 0.470071
G1 F1404.657;_EXTRUDE_SET_SPEED
M204 S3000
G1 X23.52 Y155.92 E.02771
G1 X24.208 Y155.514 E.02839
G1 X24.972 Y155.263 E.02853
G1 X25.591 Y155.181 E.02218
G1 X26.362 Y155.218 E.02743
G1 X27.135 Y155.422 E.02841
G1 X27.831 Y155.769 E.02762
G1 X28.329 Y156.144 E.02215
G1 X28.868 Y156.737 E.02845
G1 X29.197 Y157.268 E.02219
G1 X29.473 Y157.989 E.02743
G1 X29.603 Y158.78 E.02847
G1 X29.592 Y159.381 E.02133
G1 X29.47 Y160.005 E.02261
G3 X29.086 Y160.931 I-4.648 J-1.39 E.03566
G1 X28.642 Y161.541 E.02679
G1 X28.208 Y161.961 E.02144
G1 X27.68 Y162.317 E.02261
G3 X26.754 Y162.699 I-2.305 J-4.27 E.03566
G1 X26.005 Y162.817 E.02693
G1 X25.405 Y162.807 E.02133
G1 X24.781 Y162.685 E.02256
G3 X23.854 Y162.301 I1.439 J-4.777 E.0357
G1 X23.241 Y161.854 E.02694
G1 X22.824 Y161.423 E.02132
G1 X22.469 Y160.895 E.02261
G3 X22.086 Y159.968 I4.271 J-2.305 E.03566
G1 X21.968 Y159.222 E.02682
G1 X22.002 Y158.448 E.02752
G1 X22.207 Y157.651 E.02925
G1 X22.566 Y156.933 E.0285
G1 X22.904 Y156.49 E.0198
; Slow Down End
; CHANGE_LAYER
; Z_HEIGHT: 6.2
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1404.657
G1 X22.566 Y156.933 E-.10591
G1 X22.207 Y157.651 E-.15247
G1 X22.048 Y158.271 E-.12161
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L31
M991 S0 P30 ;notify layer change


M204 S10000
G17
G3 Z6.4 I1.217 J0 P1  F36000
; object ids of layer 31 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer31 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.027 Y93.549
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.717 Y93.672 E.0113
G2 X230.203 Y93.352 I1.497 J3.338 E.72629
G1 X230.032 Y93.357 E.00578
G2 X229.084 Y93.531 I.182 J3.654 E.03273
M204 S10000
G1 X229.173 Y93.928 F36000
G1 F1473.913
M204 S3000
G1 X228.882 Y94.044 E.01059
G2 X230.203 Y93.759 I1.331 J2.967 E.64547
G1 X230.053 Y93.763 E.0051
G2 X229.23 Y93.911 I.161 J3.248 E.02836
M204 S250
G1 X229.313 Y94.294 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.041 Y94.402 E.00916
G2 X230.203 Y94.151 I1.171 J2.609 E.5258
G1 X230.072 Y94.155 E.00412
G2 X229.37 Y94.278 I.141 J2.856 E.02239
; WIPE_START
M204 S3000
G1 X229.041 Y94.402 E-.06679
G1 X228.645 Y94.613 E-.08522
G1 X228.403 Y94.789 E-.0569
G1 X228.181 Y94.989 E-.05688
G1 X227.969 Y95.226 E-.06038
G1 X227.804 Y95.454 E-.05336
G1 X227.803 Y95.456 E-.00047
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.848 Y92.519 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.751 Y92.543 E.00336
G2 X230.413 Y92.32 I1.444 J4.469 E.9417
G2 X229.958 Y92.321 I-.219 J4.334 E.01544
G2 X229.226 Y92.416 I.237 J4.69 E.02498
G1 X228.906 Y92.503 E.01125
M204 S10000
G1 X228.742 Y92.126 F36000
G1 F1473.913
M204 S3000
G1 X228.625 Y92.155 E.00409
G2 X230.433 Y91.914 I1.569 J4.856 E1.02329
G2 X229.936 Y91.915 I-.24 J4.735 E.01684
G2 X229.142 Y92.018 I.258 J5.097 E.02715
G1 X228.8 Y92.11 E.01197
M204 S250
G1 X228.641 Y91.748 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.504 Y91.782 E.00443
G2 X230.453 Y91.522 I1.69 J5.229 E1.02066
G2 X229.916 Y91.523 I-.259 J5.12 E.01686
G2 X229.06 Y91.634 I.279 J5.488 E.02708
G1 X228.699 Y91.732 E.01173
; WIPE_START
M204 S3000
G1 X228.504 Y91.782 E-.03823
G1 X227.968 Y91.99 E-.10932
G1 X227.455 Y92.252 E-.10935
G1 X226.973 Y92.565 E-.10929
G1 X226.916 Y92.611 E-.01381
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X229.114 Y92.979 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672829
G1 F952.519
M204 S3000
G2 X226.025 Y97.012 I1.088 J4.033 E.28601
G1 X226.075 Y97.657 E.0339
G1 X226.17 Y98.101 E.02377
G1 X226.387 Y98.71 E.03389
G1 X226.695 Y99.28 E.03393
G1 X226.961 Y99.647 E.02375
G1 X227.408 Y100.117 E.03393
G1 X227.921 Y100.511 E.0339
G1 X228.314 Y100.738 E.02377
G2 X229.172 Y92.963 I1.889 J-3.726 E.84455
; OBJECT_ID: 12
; WIPE_START
G1 X228.504 Y93.195 E-.13435
G1 X228.121 Y93.389 E-.08159
G1 X227.921 Y93.512 E-.04462
G1 X227.423 Y93.896 E-.11944
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
M73 P90 R4
G1 X220.244 Y96.488 Z6.6 F36000
G1 X211.753 Y99.554 Z6.6
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.816 Y99.485 E.00316
G2 X208.982 Y93.121 I-3.033 J-2.463 E.29116
G2 X208.595 Y93.12 I-.199 J3.67 E.0131
G2 X211.541 Y99.789 I.188 J3.902 E.51274
G1 X211.713 Y99.599 E.00866
M204 S10000
G1 X211.452 Y99.269 F36000
G1 F1473.913
M204 S3000
G1 X211.617 Y99.088 E.00831
G2 X208.777 Y93.522 I-2.829 J-2.064 E.26127
G1 X208.615 Y93.527 E.00549
G2 X211.259 Y99.506 I.173 J3.497 E.45929
G1 X211.414 Y99.316 E.00831
M204 S250
G1 X211.16 Y99.02 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.2 Y98.986 E.00164
G2 X208.777 Y93.915 I-2.412 J-1.962 E.22005
G1 X208.635 Y93.918 E.00447
G2 X210.981 Y99.228 I.153 J3.106 E.37781
G1 X211.121 Y99.066 E.00673
; WIPE_START
M204 S3000
G1 X211.2 Y98.986 E-.02129
G1 X211.386 Y98.719 E-.06189
G1 X211.619 Y98.29 E-.09275
G1 X211.735 Y97.986 E-.06182
G1 X211.82 Y97.671 E-.06189
G1 X211.871 Y97.35 E-.06183
G1 X211.876 Y97.252 E-.01853
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.575 Y99.166 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X208.988 Y92.32 I4.194 J-2.141 E.6685
G2 X208.531 Y92.321 I-.22 J4.349 E.01548
G2 X204.548 Y99.112 I.238 J4.703 E.31555
M204 S10000
G1 X204.212 Y99.351 F36000
G1 F1473.913
M204 S3000
G2 X209.008 Y91.914 I4.557 J-2.326 E.72625
G2 X208.51 Y91.915 I-.24 J4.751 E.01688
G2 X204.185 Y99.297 I.259 J5.11 E.34299
M204 S250
G1 X203.875 Y99.536 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.152 Y100.028 E.01771
G2 X209.028 Y91.522 I4.617 J-3.004 E.70611
G2 X208.489 Y91.523 I-.26 J5.136 E.01689
G2 X203.842 Y99.488 I.279 J5.501 E.34263
; WIPE_START
M204 S3000
G1 X204.152 Y100.028 E-.11836
G1 X204.496 Y100.492 E-.10965
G1 X204.882 Y100.92 E-.10956
G1 X205.048 Y101.07 E-.04243
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.938 Y98.981 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435922
G1 F1526.71
M204 S3000
G2 X204.468 Y97.025 I3.839 J-1.957 E.81835
G1 X204.491 Y97.475 E.01475
G1 X204.561 Y97.916 E.01456
G1 X204.677 Y98.352 E.01476
G1 X204.758 Y98.578 E.00785
G2 X204.911 Y98.927 I4.019 J-1.554 E.01247
; OBJECT_ID: 11
; WIPE_START
G1 X205.16 Y99.367 E-.09612
G1 X205.294 Y99.562 E-.04482
G1 X205.578 Y99.912 E-.08572
G1 X205.894 Y100.227 E-.08472
G1 X206.174 Y100.455 E-.06862
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.771 Y98.598 Z6.6 F36000
G1 X183.799 Y94.842 Z6.6
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.531 Y95.35 E.01946
G2 X187.542 Y92.885 I3.799 J1.686 E.71458
G2 X187.131 Y92.885 I-.212 J3.901 E.01393
G2 X183.841 Y94.777 I.199 J4.152 E.13339
G1 X183.832 Y94.792 E.00058
M204 S10000
G1 X184.156 Y95.035 F36000
G1 F1473.913
M204 S3000
G1 X183.903 Y95.516 E.01838
G2 X187.521 Y93.292 I3.427 J1.521 E.64463
G2 X187.151 Y93.291 I-.191 J3.512 E.01252
G2 X184.19 Y94.987 I.179 J3.745 E.11988
M204 S250
G1 X184.499 Y95.222 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.336 Y95.516 E.01056
G2 X187.5 Y93.684 I2.994 J1.521 E.54023
G2 X187.17 Y93.683 I-.17 J3.138 E.01035
G2 X184.536 Y95.175 I.159 J3.354 E.09848
; WIPE_START
M204 S3000
G1 X184.336 Y95.516 E-.07515
G1 X184.187 Y95.835 E-.06679
G1 X184.037 Y96.341 E-.10031
G1 X183.983 Y96.688 E-.06668
G1 X183.964 Y97.039 E-.06684
G1 X183.965 Y97.061 E-.00422
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.536 Y92.32 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X187.077 Y92.321 I-.22 J4.363 E.01553
G2 X187.596 Y92.323 I.239 J4.718 E.98708
M204 S10000
G1 X187.556 Y91.914 F36000
G1 F1473.913
M204 S3000
G2 X187.056 Y91.915 I-.241 J4.765 E.01693
G2 X187.616 Y91.917 I.26 J5.124 E1.07228
M204 S250
G1 X187.56 Y91.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.523 E.01646
G2 X187.62 Y91.524 I.28 J5.516 E1.0697
; WIPE_START
M204 S3000
G1 X187.035 Y91.523 E-.1111
G1 X186.46 Y91.583 E-.10988
G1 X185.895 Y91.704 E-.10988
G1 X185.647 Y91.777 E-.04914
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.563 Y92.61 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200577
G1 F3805.735
M204 S3000
G1 X187.324 Y92.598 E.00313
G2 X182.882 Y97.037 I-.001 J4.441 E.09143
G1 X182.907 Y97.503 E.00612
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.00609
G1 X183.18 Y98.637 E.00316
G2 X187.787 Y92.622 I4.144 J-1.598 E.24685
G1 X187.623 Y92.613 E.00215
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.598 E-.05681
G1 X186.861 Y92.621 E-.0881
G1 X186.403 Y92.694 E-.08821
G1 X186.172 Y92.749 E-.04497
G1 X185.732 Y92.892 E-.08795
G1 X185.665 Y92.922 E-.01396
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.036 Y93.141 Z6.6 F36000
G1 X163.151 Y93.567 Z6.6
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.894 Y93.782 E.01136
G2 X166.071 Y92.652 I2.953 J3.27 E.81997
G2 X165.635 Y92.651 I-.224 J4.135 E.01476
G2 X163.251 Y93.492 I.211 J4.401 E.08679
G1 X163.199 Y93.531 E.0022
M204 S10000
G1 X163.401 Y93.892 F36000
G1 F1473.913
M204 S3000
G1 X163.014 Y94.229 E.01737
G2 X166.05 Y93.058 I2.832 J2.824 E.73717
G2 X165.656 Y93.058 I-.203 J3.746 E.01336
G2 X163.49 Y93.821 I.191 J3.995 E.07881
G1 X163.448 Y93.854 E.00183
M204 S250
G1 X163.655 Y94.189 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.291 Y94.506 E.01512
G2 X166.029 Y93.45 I2.555 J2.547 E.61593
G2 X165.675 Y93.449 I-.183 J3.372 E.01111
G2 X163.721 Y94.138 I.171 J3.603 E.06589
G1 X163.702 Y94.152 E.00074
; WIPE_START
M204 S3000
G1 X163.291 Y94.506 E-.10302
G1 X162.92 Y94.933 E-.10759
G1 X162.714 Y95.25 E-.0718
G1 X162.543 Y95.587 E-.0718
G1 X162.494 Y95.714 E-.02579
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.144 Y101.484 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.053 Y92.32 I1.689 J-4.429 E.555
G2 X165.593 Y92.321 I-.221 J4.378 E.01558
G2 X164.088 Y101.462 I.24 J4.734 E.43544
M204 S10000
G1 X163.997 Y101.864 F36000
G1 F1473.913
M204 S3000
G2 X166.073 Y91.914 I1.835 J-4.809 E.60269
G2 X165.571 Y91.915 I-.242 J4.78 E.01698
G2 X163.941 Y101.842 I.261 J5.14 E.47294
M204 S250
G1 X163.862 Y102.229 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.407 Y102.407 E.01796
G2 X166.092 Y91.522 I1.425 J-5.352 E.58261
G2 X165.551 Y91.523 I-.261 J5.165 E.01699
G2 X163.806 Y102.21 I.281 J5.532 E.47175
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.407 Y102.407 E-.12018
G1 X164.974 Y102.527 E-.11017
G1 X165.261 Y102.565 E-.0551
G1 X165.758 Y102.591 E-.09455
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.974 Y106.087 Z6.6 F36000
G1 X47.353 Y163.608 Z6.6
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.592 E.0093
G2 X47.35 Y154.32 I-.494 J-4.625 E.47055
G2 X46.898 Y154.321 I-.217 J4.295 E.01529
G2 X47.142 Y163.618 I.235 J4.646 E.48694
G1 X47.293 Y163.611 E.00514
M204 S10000
G1 X47.385 Y164.02 F36000
G1 F1473.913
M204 S3000
G1 X47.406 Y164.018 E.0007
G2 X47.37 Y153.914 I-.273 J-5.051 E.52068
G2 X46.877 Y153.914 I-.237 J4.696 E.01669
G2 X47.142 Y164.025 I.256 J5.052 E.52954
G1 X47.325 Y164.021 E.00622
M204 S250
G1 X47.395 Y164.405 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.711 Y164.387 E.00993
G2 X47.389 Y153.522 I-.578 J-5.42 E.51071
G2 X46.856 Y153.523 I-.257 J5.08 E.01672
G2 X47.142 Y164.418 I.276 J5.444 E.52853
G1 X47.335 Y164.408 E.00608
; WIPE_START
M204 S3000
G1 X47.711 Y164.387 E-.07156
G1 X48.275 Y164.299 E-.1084
G1 X48.826 Y164.152 E-.10841
G1 X49.095 Y164.056 E-.05423
M73 P91 R4
G1 X49.275 Y163.976 E-.03739
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.213 Y161.127 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X44.306 Y162.219 E.05027
G2 X45.659 Y163.02 I2.928 J-3.409 E.05145
G1 X43.089 Y160.449 E.11831
G3 X42.887 Y159.694 I3.488 J-1.335 E.02548
G1 X46.414 Y163.221 E.16232
G2 X47.026 Y163.279 I.843 J-5.607 E.02001
G1 X42.829 Y159.082 E.19316
G3 X42.849 Y158.549 I2.546 J-.171 E.0174
G1 X47.559 Y163.259 E.21678
G2 X48.039 Y163.185 I-.113 J-2.316 E.01581
G1 X42.923 Y158.07 E.23543
G3 X43.041 Y157.633 I2.135 J.338 E.01473
G1 X48.475 Y163.068 E.25013
G2 X48.876 Y162.915 I-.526 J-1.984 E.01398
G1 X43.193 Y157.233 E.26155
G3 X43.377 Y156.863 I1.851 J.689 E.01346
G1 X49.246 Y162.732 E.27012
G2 X49.59 Y162.523 I-1.156 J-2.292 E.01313
G1 X43.588 Y156.521 E.27624
G3 X43.824 Y156.203 I2.138 J1.343 E.01289
G1 X49.902 Y162.281 E.27971
G2 X50.191 Y162.016 I-1.113 J-1.507 E.01277
G1 X44.092 Y155.918 E.28069
G3 X44.381 Y155.653 I1.403 J1.243 E.01277
G1 X50.455 Y161.727 E.27956
G2 X50.695 Y161.413 I-1.376 J-1.298 E.01288
G1 X44.693 Y155.411 E.27624
G3 X45.037 Y155.202 I1.501 J2.084 E.01313
G1 X50.909 Y161.074 E.27026
G2 X51.09 Y160.702 I-2.402 J-1.397 E.01349
G1 X45.407 Y155.018 E.26156
G3 X45.808 Y154.866 I.927 J1.831 E.01398
G1 X51.243 Y160.3 E.25013
G2 X51.36 Y159.864 I-2.017 J-.775 E.01473
G1 X46.245 Y154.749 E.23543
G3 X46.724 Y154.675 I.592 J2.242 E.01581
G1 X51.434 Y159.385 E.21678
G2 X51.454 Y158.851 I-2.528 J-.363 E.0174
G1 X47.256 Y154.654 E.1932
G3 X47.873 Y154.716 I-.05 J3.545 E.02019
G1 X51.396 Y158.24 E.16215
G2 X51.194 Y157.485 I-3.691 J.58 E.02547
G1 X48.628 Y154.918 E.11812
G3 X49.978 Y155.714 I-1.338 J3.811 E.05132
G1 X51.073 Y156.809 E.05041
; OBJECT_ID: 14
; WIPE_START
G1 X49.978 Y155.714 E-.29429
G1 X49.68 Y155.473 E-.07274
G1 X49.623 Y155.436 E-.01297
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X41.991 Y155.524 Z6.6 F36000
G1 X26.619 Y155.702 Z6.6
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.495 Y155.663 E.00441
G2 X25.785 Y155.59 I-.699 J3.336 E.02418
G1 X25.626 Y155.595 E.0054
G2 X27.009 Y155.814 I.17 J3.405 E.67725
G1 X26.676 Y155.718 E.0117
M204 S10000
G1 X26.504 Y156.091 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.061 E.00332
G2 X25.785 Y155.998 I-.615 J2.938 E.02129
G1 X25.646 Y156.001 E.00471
G2 X26.863 Y156.194 I.149 J2.998 E.5964
G1 X26.561 Y156.108 E.01061
M204 S250
G1 X26.392 Y156.466 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.445 E.00212
G2 X25.785 Y156.39 I-.534 J2.554 E.01714
G1 X25.665 Y156.393 E.00376
G2 X26.722 Y156.56 I.129 J2.606 E.48031
G1 X26.45 Y156.483 E.00886
; WIPE_START
M204 S3000
G1 X26.328 Y156.445 E-.02421
G1 X26.058 Y156.404 E-.05191
G1 X25.785 Y156.39 E-.05192
G1 X25.665 Y156.393 E-.02278
G1 X25.243 Y156.447 E-.08098
G1 X24.979 Y156.518 E-.05192
G1 X24.724 Y156.616 E-.0519
G1 X24.518 Y156.727 E-.04438
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X25.995 Y154.32 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.54 Y154.321 I-.218 J4.32 E.01539
G2 X26.055 Y154.323 I.237 J4.679 E.97889
M204 S10000
G1 X26.015 Y153.914 F36000
G1 F1473.913
M204 S3000
G2 X25.519 Y153.915 I-.239 J4.722 E.0168
G2 X26.075 Y153.917 I.258 J5.085 E1.06409
M204 S250
G1 X26.023 Y153.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.498 Y153.523 E.01646
G2 X26.083 Y153.524 I.278 J5.477 E1.06202
; WIPE_START
M204 S3000
G1 X25.498 Y153.523 E-.11114
G1 X25.212 Y153.545 E-.05459
G1 X24.645 Y153.635 E-.10907
G1 X24.11 Y153.779 E-.10521
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X23.76 Y161.403 Z6.6 F36000
G1 X23.701 Y162.699 Z6.6
G1 Z6.2
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.479877
G1 F1373.134
M204 S3000
G1 X24.077 Y162.9 E.0155
G1 X24.661 Y163.108 E.0225
G2 X25.585 Y163.254 I1.775 J-8.206 E.03404
G1 X26.429 Y163.21 E.03069
G1 X27.29 Y162.983 E.03234
G1 X28.092 Y162.579 E.03265
G1 X28.617 Y162.179 E.02397
G2 X29.243 Y161.483 I-5.335 J-5.422 E.03403
G1 X29.668 Y160.745 E.03096
G1 X29.893 Y160.125 E.02397
G2 X30.04 Y159.2 I-8.209 J-1.776 E.03404
G1 X29.993 Y158.357 E.03067
G2 X29.751 Y157.453 I-7.226 J1.451 E.03403
G1 X29.365 Y156.696 E.03087
G1 X28.966 Y156.166 E.02411
G2 X27.538 Y155.12 I-3.73 J3.593 E.06461
G1 X26.689 Y154.839 E.03252
G1 X26 Y154.748 E.02524
G1 X25.142 Y154.79 E.03121
G1 X24.273 Y155.019 E.03265
G1 X23.677 Y155.301 E.02397
G2 X22.491 Y156.3 I2.662 J4.363 E.05652
G2 X21.981 Y157.087 I6.341 J4.668 E.03411
G2 X21.531 Y158.8 I4.397 J2.072 E.0647
G1 X21.575 Y159.644 E.03069
G1 X21.804 Y160.512 E.03265
G1 X22.087 Y161.109 E.02398
G2 X22.638 Y161.865 I6.413 J-4.091 E.03403
G1 X23.265 Y162.43 E.03065
G1 X23.65 Y162.667 E.01644
; WIPE_START
G1 X23.265 Y162.43 E-.086
G1 X22.638 Y161.865 E-.16026
G1 X22.377 Y161.531 E-.08058
G1 X22.218 Y161.301 E-.05316
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.274 Y160.544 Z6.6 F36000
G1 Z6.2
G1 E.4 F1800
; LINE_WIDTH: 0.470448
G1 F1403.419
M204 S3000
G1 X29.086 Y160.931 E.0153
G1 X28.641 Y161.542 E.02686
G1 X28.053 Y162.082 E.02841
G1 X27.361 Y162.485 E.02844
G1 X26.6 Y162.737 E.02851
G3 X25.405 Y162.807 I-.824 J-3.826 E.04272
G1 X24.78 Y162.685 E.02263
G3 X23.854 Y162.3 I1.389 J-4.647 E.03569
G1 X23.243 Y161.856 E.02686
G1 X22.705 Y161.265 E.02841
G1 X22.299 Y160.577 E.02842
G1 X22.048 Y159.814 E.02853
G3 X21.978 Y158.619 I3.825 J-.824 E.04272
G1 X22.099 Y158 E.02243
G1 X22.388 Y157.256 E.02839
G1 X22.829 Y156.581 E.02867
G1 X22.945 Y156.435 E.00663
G1 X23.52 Y155.92 E.02744
G1 X24.209 Y155.513 E.02842
G1 X24.972 Y155.263 E.02855
G1 X25.586 Y155.181 E.02204
G1 X26.362 Y155.218 E.02761
G1 X27.135 Y155.422 E.02844
G1 X27.835 Y155.772 E.02781
G1 X28.331 Y156.146 E.02209
G1 X28.747 Y156.576 E.02129
G1 X29.182 Y157.244 E.02834
G1 X29.473 Y157.989 E.02841
G1 X29.603 Y158.78 E.02851
G1 X29.592 Y159.381 E.02134
G1 X29.47 Y160.006 E.02264
G1 X29.295 Y160.488 E.01824
; CHANGE_LAYER
; Z_HEIGHT: 6.4
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1403.419
G1 X29.47 Y160.006 E-.09748
G1 X29.592 Y159.381 E-.121
G1 X29.603 Y158.78 E-.11406
G1 X29.562 Y158.534 E-.04746
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L32
M991 S0 P31 ;notify layer change


M204 S10000
G17
G3 Z6.6 I1.217 J0 P1  F36000
; object ids of layer 32 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer32 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.025 Y93.549
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.716 Y93.672 E.01125
G2 X230.203 Y93.352 I1.495 J3.339 E.72628
G1 X230.028 Y93.357 E.00593
G2 X229.082 Y93.531 I.184 J3.654 E.03264
M204 S10000
G1 X229.171 Y93.929 F36000
G1 F1473.913
M204 S3000
G1 X228.882 Y94.043 E.01053
G2 X230.203 Y93.759 I1.329 J2.967 E.64547
G1 X230.048 Y93.763 E.00525
G2 X229.228 Y93.911 I.163 J3.248 E.02828
M204 S250
G1 X229.311 Y94.295 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.041 Y94.402 E.00911
G2 X230.203 Y94.151 I1.169 J2.609 E.5258
G1 X230.068 Y94.155 E.00424
G2 X229.369 Y94.278 I.143 J2.856 E.02231
; WIPE_START
M204 S3000
G1 X229.041 Y94.402 E-.0665
G1 X228.773 Y94.535 E-.05687
G1 X228.522 Y94.698 E-.05689
G1 X228.181 Y94.989 E-.08526
G1 X227.889 Y95.33 E-.08527
G1 X227.806 Y95.459 E-.02921
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.917 Y92.498 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.625 E.01415
G2 X230.422 Y92.32 I1.677 J4.383 E.93251
G2 X229.958 Y92.321 I-.225 J4.413 E.01571
G2 X228.987 Y92.474 I.239 J4.687 E.0333
G1 X228.974 Y92.478 E.00047
M204 S10000
G1 X228.792 Y92.111 F36000
G1 F1473.913
M204 S3000
G1 X228.373 Y92.245 E.01487
G2 X230.442 Y91.914 I1.823 J4.763 E1.01332
G2 X229.936 Y91.915 I-.246 J4.813 E.01712
G2 X228.882 Y92.08 I.26 J5.094 E.03619
G1 X228.848 Y92.092 E.00119
M204 S250
G1 X228.671 Y91.738 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
M73 P91 R3
G1 X228.233 Y91.879 E.01442
G2 X230.461 Y91.522 I1.963 J5.129 E1.01073
G2 X229.916 Y91.523 I-.266 J5.2 E.01712
G2 X228.78 Y91.701 I.28 J5.485 E.0361
G1 X228.727 Y91.719 E.00175
; WIPE_START
M204 S3000
G1 X228.233 Y91.879 E-.09877
G1 X227.708 Y92.114 E-.10933
G1 X227.21 Y92.402 E-.10929
G1 X226.943 Y92.596 E-.06261
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X229.067 Y92.996 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672813
G1 F952.543
M204 S3000
G1 X228.92 Y93.036 E.00798
G1 X228.698 Y93.114 E.01232
G1 X228.306 Y93.289 E.02249
G1 X227.927 Y93.508 E.02291
G1 X227.574 Y93.765 E.0229
G1 X227.249 Y94.057 E.0229
G1 X226.956 Y94.382 E.0229
G1 X226.704 Y94.729 E.02248
G1 X226.581 Y94.93 E.01232
G1 X226.383 Y95.32 E.0229
G1 X226.229 Y95.721 E.02248
G1 X226.116 Y96.143 E.02289
G1 X226.048 Y96.575 E.02291
G1 X226.025 Y97.012 E.02291
G1 X226.047 Y97.44 E.02249
G1 X226.079 Y97.678 E.01254
G1 X226.167 Y98.093 E.02223
G1 X226.306 Y98.517 E.02336
G1 X226.48 Y98.908 E.02247
G1 X226.699 Y99.287 E.0229
G1 X226.956 Y99.641 E.02293
G1 X227.249 Y99.966 E.02289
G1 X227.574 Y100.258 E.02289
G1 X227.927 Y100.515 E.0229
G1 X228.306 Y100.734 E.02293
G1 X228.698 Y100.909 E.02246
G1 X228.92 Y100.988 E.01234
G1 X229.342 Y101.1 E.02289
G1 X229.766 Y101.167 E.02247
G1 X230.203 Y101.19 E.02292
G1 X230.64 Y101.167 E.02292
G1 X231.064 Y101.1 E.02247
G1 X231.486 Y100.988 E.0229
G1 X231.708 Y100.909 E.01232
G1 X232.1 Y100.734 E.02248
G1 X232.479 Y100.516 E.0229
G1 X232.833 Y100.259 E.02291
G1 X233.157 Y99.966 E.0229
G1 X233.45 Y99.641 E.02289
G1 X233.702 Y99.294 E.02248
G1 X233.825 Y99.093 E.01234
G1 X234.023 Y98.703 E.0229
G1 X234.177 Y98.303 E.02248
G1 X234.29 Y97.88 E.02289
G1 X234.358 Y97.448 E.02291
G1 X234.381 Y97.012 E.02291
G1 X234.358 Y96.575 E.02292
G1 X234.29 Y96.143 E.0229
G1 X234.177 Y95.72 E.0229
G1 X234.023 Y95.32 E.02247
G1 X233.922 Y95.107 E.01233
G1 X233.703 Y94.729 E.02289
G1 X233.45 Y94.382 E.02249
G1 X233.157 Y94.058 E.02288
G1 X232.832 Y93.765 E.02292
G1 X232.486 Y93.512 E.02247
G1 X232.107 Y93.293 E.0229
G1 X231.895 Y93.191 E.01234
G1 X231.494 Y93.038 E.02247
G1 X231.072 Y92.925 E.02289
G1 X230.643 Y92.857 E.02273
G1 X230.203 Y92.833 E.02309
G1 X229.766 Y92.856 E.02291
G1 X229.342 Y92.923 E.02248
G1 X229.125 Y92.981 E.01177
; OBJECT_ID: 12
; WIPE_START
G1 X228.92 Y93.036 E-.04034
G1 X228.698 Y93.114 E-.04468
G1 X228.306 Y93.289 E-.08158
G1 X227.927 Y93.508 E-.0831
G1 X227.574 Y93.765 E-.08306
G1 X227.389 Y93.931 E-.04725
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.207 Y96.515 Z6.8 F36000
G1 X211.749 Y99.559 Z6.8
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.82 Y99.488 E.0034
G2 X208.777 Y93.115 I-3.034 J-2.465 E.2984
G1 X208.59 Y93.12 E.00633
G2 X211.546 Y99.793 I.196 J3.904 E.51268
G1 X211.71 Y99.604 E.00845
M204 S10000
G1 X211.447 Y99.287 F36000
G1 F1473.913
M204 S3000
G1 X211.504 Y99.232 E.00268
G2 X208.777 Y93.522 I-2.717 J-2.208 E.26736
G1 X208.611 Y93.527 E.00564
G2 X211.257 Y99.505 I.176 J3.497 E.45927
G1 X211.407 Y99.332 E.00773
M204 S250
G1 X211.156 Y99.025 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.199 Y98.985 E.00183
G2 X208.777 Y93.915 I-2.413 J-1.961 E.21994
G1 X208.63 Y93.918 E.00461
G2 X210.98 Y99.227 I.155 J3.106 E.37779
G1 X211.116 Y99.07 E.00652
; WIPE_START
M204 S3000
G1 X211.199 Y98.985 E-.02248
G1 X211.386 Y98.719 E-.06191
G1 X211.549 Y98.437 E-.06185
G1 X211.681 Y98.139 E-.06187
G1 X211.82 Y97.671 E-.09275
G1 X211.871 Y97.35 E-.06181
G1 X211.875 Y97.259 E-.01733
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.58 Y99.163 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X208.996 Y92.32 I4.191 J-2.142 E.66782
G2 X208.531 Y92.321 I-.226 J4.429 E.01576
G2 X204.553 Y99.11 I.24 J4.7 E.31536
M204 S10000
G1 X204.217 Y99.348 F36000
G1 F1473.913
M204 S3000
G2 X209.017 Y91.914 I4.553 J-2.327 E.72553
M73 P92 R3
G2 X208.51 Y91.915 I-.246 J4.83 E.01716
G2 X204.19 Y99.295 I.261 J5.107 E.34279
M204 S250
G1 X203.868 Y99.526 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G2 X209.036 Y91.522 I4.902 J-2.505 E.72354
G2 X208.489 Y91.523 I-.266 J5.217 E.01716
G2 X203.841 Y99.473 I.281 J5.498 E.342
; WIPE_START
M204 S3000
G1 X204.157 Y100.025 E-.12095
G1 X204.496 Y100.492 E-.10955
G1 X204.882 Y100.92 E-.10959
G1 X205.038 Y101.061 E-.03991
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.938 Y98.981 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.435957
G1 F1526.576
M204 S3000
G1 X205.163 Y99.372 E.01476
G1 X205.428 Y99.737 E.01473
G1 X205.73 Y100.072 E.01474
G1 X206.065 Y100.374 E.01475
G1 X206.43 Y100.639 E.01474
G1 X206.821 Y100.865 E.01475
G1 X207.228 Y101.046 E.01457
G1 X207.451 Y101.125 E.00771
G1 X207.887 Y101.241 E.01474
G1 X208.327 Y101.311 E.01456
G1 X208.777 Y101.334 E.01475
G1 X209.228 Y101.311 E.01475
G1 X209.668 Y101.241 E.01456
G1 X210.104 Y101.125 E.01475
G1 X210.33 Y101.045 E.00782
G1 X210.734 Y100.865 E.01446
G1 X211.125 Y100.639 E.01475
G1 X211.49 Y100.374 E.01474
G1 X211.825 Y100.072 E.01474
G1 X212.127 Y99.737 E.01475
G1 X212.389 Y99.376 E.01457
G1 X212.615 Y98.986 E.01474
G1 X212.717 Y98.773 E.00771
G1 X212.876 Y98.356 E.01457
G1 X212.993 Y97.921 E.01474
G1 X213.063 Y97.475 E.01474
G1 X213.087 Y97.025 E.01475
G1 X213.063 Y96.574 E.01475
G1 X212.994 Y96.134 E.01457
G1 X212.939 Y95.904 E.00771
G1 X212.799 Y95.475 E.01475
G1 X212.617 Y95.068 E.01457
G1 X212.392 Y94.677 E.01474
G1 X212.127 Y94.312 E.01475
G1 X211.825 Y93.977 E.01475
G1 X211.49 Y93.676 E.01473
G1 X211.124 Y93.41 E.01476
G1 X210.734 Y93.185 E.01474
G1 X210.327 Y93.003 E.01456
G1 X209.898 Y92.863 E.01475
G1 X209.668 Y92.808 E.00771
G1 X209.231 Y92.739 E.01447
G1 X208.777 Y92.715 E.01485
G1 X208.327 Y92.739 E.01475
G1 X207.886 Y92.808 E.01458
G1 X207.451 Y92.924 E.01472
G1 X207.228 Y93.003 E.00773
G1 X206.821 Y93.185 E.01456
G1 X206.43 Y93.41 E.01475
G1 X206.065 Y93.675 E.01473
G1 X205.73 Y93.977 E.01474
G1 X205.428 Y94.312 E.01474
G1 X205.166 Y94.673 E.01457
G1 X205.043 Y94.874 E.00771
G1 X204.838 Y95.276 E.01474
G1 X204.679 Y95.693 E.01458
G1 X204.562 Y96.128 E.01474
G1 X204.491 Y96.574 E.01474
G1 X204.468 Y97.019 E.01458
G1 X204.491 Y97.475 E.01492
G1 X204.561 Y97.916 E.01458
G1 X204.677 Y98.351 E.01473
G1 X204.757 Y98.577 E.00783
G1 X204.913 Y98.926 E.0125
; OBJECT_ID: 11
; WIPE_START
G1 X205.163 Y99.372 E-.09713
G1 X205.428 Y99.737 E-.08566
G1 X205.73 Y100.072 E-.08569
G1 X206.065 Y100.374 E-.08573
G1 X206.175 Y100.454 E-.02579
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.773 Y98.591 Z6.8 F36000
G1 X183.806 Y94.826 Z6.8
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.626 Y95.155 E.0127
G2 X187.324 Y92.88 I3.708 J1.883 E.72983
G1 X187.125 Y92.885 E.00673
G2 X183.843 Y94.778 I.209 J4.153 E.13318
G1 X183.843 Y94.779 E.00001
M204 S10000
G1 X184.158 Y95.029 F36000
G1 F1473.913
M204 S3000
G1 X183.989 Y95.34 E.01198
G2 X187.324 Y93.287 I3.345 J1.699 E.65839
G1 X187.146 Y93.292 E.00604
G2 X184.196 Y94.983 I.188 J3.747 E.11945
M204 S250
G1 X184.497 Y95.225 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.338 Y95.517 E.01045
G2 X187.324 Y93.679 I2.995 J1.521 E.54613
G1 X187.165 Y93.683 E.00498
G2 X184.535 Y95.179 I.168 J3.355 E.09842
; WIPE_START
M204 S3000
G1 X184.338 Y95.517 E-.07436
G1 X184.187 Y95.835 E-.06676
G1 X184.079 Y96.169 E-.06682
G1 X184.006 Y96.514 E-.06684
G1 X183.964 Y97.039 E-.10017
G1 X183.966 Y97.066 E-.00504
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.544 Y92.321 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X187.077 Y92.321 I-.227 J4.44 E.01581
G2 X187.604 Y92.324 I.241 J4.715 E.98622
M204 S10000
G1 X187.564 Y91.914 F36000
G1 F1473.913
M204 S3000
G2 X187.056 Y91.915 I-.247 J4.84 E.01722
G2 X187.624 Y91.917 I.262 J5.121 E1.07135
M204 S250
G1 X187.564 Y91.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.035 Y91.523 E.01658
G2 X187.624 Y91.524 I.282 J5.513 E1.06897
; WIPE_START
M204 S3000
G1 X187.035 Y91.523 E-.11188
G1 X186.46 Y91.583 E-.10989
G1 X185.895 Y91.704 E-.10984
G1 X185.652 Y91.782 E-.04839
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.568 Y92.61 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200572
G1 F3805.862
M204 S3000
G1 X187.322 Y92.597 E.00322
G2 X182.882 Y97.039 I.002 J4.442 E.09144
G1 X182.907 Y97.506 E.00612
G2 X187.787 Y92.621 I4.417 J-.467 E.26219
G1 X187.627 Y92.613 E.00209
; OBJECT_ID: 10
; WIPE_START
G1 X187.322 Y92.597 E-.05808
G1 X186.86 Y92.622 E-.08794
G1 X186.401 Y92.694 E-.08837
G1 X185.952 Y92.815 E-.08827
G1 X185.67 Y92.923 E-.05734
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.041 Y93.133 Z6.8 F36000
G1 X163.182 Y93.544 Z6.8
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X163.069 Y93.634 E.00487
G2 X165.84 Y92.646 I2.781 J3.42 E.83609
G1 X165.63 Y92.651 E.00713
G2 X163.442 Y93.362 I.221 J4.403 E.07877
G1 X163.231 Y93.51 E.00873
M204 S10000
G1 X163.398 Y93.894 F36000
G1 F1473.913
M204 S3000
G1 X163.016 Y94.23 E.01724
G2 X165.84 Y93.053 I2.835 J2.824 E.74473
G1 X165.65 Y93.058 E.00644
G2 X163.492 Y93.822 I.2 J3.996 E.07861
G1 X163.446 Y93.857 E.00196
M204 S250
G1 X163.652 Y94.191 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.293 Y94.507 E.015
G2 X165.84 Y93.445 I2.557 J2.547 E.62225
G1 X165.67 Y93.45 E.00535
G2 X163.722 Y94.139 I.18 J3.605 E.06571
G1 X163.7 Y94.155 E.00085
; WIPE_START
M204 S3000
G1 X163.293 Y94.507 E-.10228
G1 X162.92 Y94.933 E-.10755
G1 X162.714 Y95.251 E-.07189
G1 X162.543 Y95.587 E-.0717
G1 X162.492 Y95.717 E-.02659
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.146 Y101.478 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.061 Y92.321 I1.689 J-4.426 E.55449
G2 X165.593 Y92.321 I-.227 J4.455 E.01586
G2 X164.09 Y101.456 I.241 J4.731 E.43508
M204 S10000
G1 X163.999 Y101.857 F36000
G1 F1473.913
M204 S3000
G2 X166.081 Y91.914 I1.835 J-4.805 E.60213
G2 X165.571 Y91.915 I-.248 J4.856 E.01727
G2 X163.943 Y101.836 I.262 J5.137 E.47257
M204 S250
G1 X163.865 Y102.23 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.408 Y102.401 E.01784
G2 X166.101 Y91.522 I1.425 J-5.349 E.5821
G2 X165.551 Y91.523 I-.268 J5.243 E.01726
G2 X163.812 Y102.205 I.283 J5.529 E.47154
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.408 Y102.401 E-.11928
G1 X164.974 Y102.527 E-.1101
G1 X165.551 Y102.587 E-.11021
G1 X165.763 Y102.593 E-.04041
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.979 Y106.089 Z6.8 F36000
G1 X47.358 Y163.608 Z6.8
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.627 Y163.587 E.00913
G2 X47.358 Y154.32 I-.492 J-4.623 E.47013
G2 X46.898 Y154.321 I-.223 J4.373 E.01556
G2 X47.142 Y163.613 I.237 J4.643 E.48654
G1 X47.298 Y163.609 E.0053
M204 S10000
G1 X47.38 Y164.014 F36000
G1 F1473.913
M204 S3000
G1 X47.67 Y163.991 E.00985
G2 X47.378 Y153.914 I-.535 J-5.027 E.51125
G2 X46.877 Y153.914 I-.244 J4.773 E.01697
G2 X47.142 Y164.019 I.258 J5.049 E.52911
G1 X47.32 Y164.015 E.00602
M204 S250
G1 X47.4 Y164.405 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.711 Y164.38 E.00977
G2 X47.398 Y153.522 I-.576 J-5.417 E.51026
G2 X46.856 Y153.523 I-.264 J5.16 E.01698
G2 X47.142 Y164.411 I.278 J5.441 E.5281
G1 X47.34 Y164.406 E.00622
; WIPE_START
M204 S3000
G1 X47.711 Y164.38 E-.07058
G1 X48.275 Y164.299 E-.10835
G1 X48.826 Y164.152 E-.1084
G1 X49.282 Y163.977 E-.09267
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.292 Y162.905 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X50.394 Y161.803 E.05073
G2 X51.194 Y160.449 I-3.193 J-2.8 E.05147
G1 X48.624 Y163.02 E.11831
G3 X47.869 Y163.221 I-1.336 J-3.492 E.02547
G1 X51.396 Y159.694 E.16232
G2 X51.454 Y159.082 I-5.602 J-.843 E.02001
G1 X47.257 Y163.279 E.19316
G3 X46.724 Y163.259 I-.171 J-2.547 E.0174
G1 X51.434 Y158.549 E.21678
G2 X51.36 Y158.07 I-2.317 J.113 E.01581
G1 X46.245 Y163.185 E.23543
G3 X45.808 Y163.068 I.338 J-2.134 E.01473
G1 X51.243 Y157.633 E.25014
G2 X51.094 Y157.228 I-2.748 J.781 E.01404
G1 X45.407 Y162.915 E.26174
G3 X45.034 Y162.735 I.958 J-2.462 E.0135
G1 X50.908 Y156.861 E.27037
G2 X50.695 Y156.521 I-1.725 J.846 E.01309
G1 X44.695 Y162.52 E.27613
G3 X44.381 Y162.281 I.983 J-1.614 E.01288
G1 X50.455 Y156.207 E.27956
G2 X50.191 Y155.917 I-1.507 J1.113 E.01277
G1 X44.092 Y162.016 E.28069
G3 X43.828 Y161.727 I1.243 J-1.402 E.01277
G1 X49.902 Y155.653 E.27956
G2 X49.588 Y155.414 I-1.298 J1.376 E.01288
G1 X43.588 Y161.413 E.27613
G3 X43.373 Y161.075 I2.044 J-1.534 E.01307
G1 X49.248 Y155.2 E.27037
G2 X48.88 Y155.015 I-1.066 J1.66 E.01344
G1 X43.193 Y160.701 E.26172
G3 X43.041 Y160.3 I1.824 J-.924 E.01399
M73 P93 R3
G1 X48.48 Y154.861 E.25033
G2 X48.044 Y154.744 I-.763 J1.967 E.01473
G1 X42.923 Y159.864 E.23565
G3 X42.849 Y159.385 I2.245 J-.593 E.01581
G1 X47.564 Y154.67 E.217
G2 X47.026 Y154.654 I-.373 J3.562 E.01753
G1 X42.829 Y158.851 E.19317
G3 X42.887 Y158.239 I5.662 J.231 E.02001
G1 X46.414 Y154.713 E.16232
G2 X45.659 Y154.914 I.58 J3.687 E.02548
G1 X43.089 Y157.485 E.1183
G3 X43.87 Y156.15 I4.271 J1.604 E.05056
G1 X44.981 Y155.039 E.05116
; OBJECT_ID: 14
; WIPE_START
G1 X43.87 Y156.15 E-.2987
G1 X43.612 Y156.492 E-.0813
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X35.988 Y156.134 Z6.8 F36000
G1 X26.594 Y155.692 Z6.8
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.494 Y155.663 E.00351
G2 X25.785 Y155.59 I-.701 J3.336 E.02417
G1 X25.622 Y155.595 E.00554
G2 X26.84 Y155.755 I.171 J3.405 E.68317
G1 X26.652 Y155.707 E.00655
M204 S10000
G1 X26.489 Y156.085 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.062 E.00279
G2 X25.785 Y155.998 I-.617 J2.938 E.02129
G1 X25.642 Y156.001 E.00485
G2 X26.714 Y156.143 I.151 J2.998 E.6016
G1 X26.547 Y156.1 E.00583
M204 S250
G1 X26.388 Y156.463 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.446 E.00194
G2 X25.785 Y156.39 I-.536 J2.554 E.01714
G1 X25.662 Y156.393 E.00388
G2 X26.593 Y156.516 I.13 J2.606 E.4845
G1 X26.446 Y156.478 E.00476
; WIPE_START
M204 S3000
G1 X26.328 Y156.446 E-.02315
G1 X26.058 Y156.404 E-.0519
G1 X25.785 Y156.39 E-.05192
G1 X25.662 Y156.393 E-.02348
G1 X25.243 Y156.447 E-.08029
G1 X24.979 Y156.518 E-.05189
G1 X24.724 Y156.616 E-.05191
G1 X24.513 Y156.73 E-.04546
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.003 Y154.32 Z6.8 F36000
G1 Z6.4
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X25.54 Y154.321 I-.225 J4.402 E.01567
G2 X26.063 Y154.324 I.239 J4.676 E.97803
M204 S10000
G1 X26.023 Y153.914 F36000
G1 F1473.913
M204 S3000
G2 X25.519 Y153.915 I-.245 J4.802 E.01708
G2 X26.083 Y153.917 I.26 J5.082 E1.06316
M204 S250
G1 X26.027 Y153.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.498 Y153.523 E.01659
G2 X26.087 Y153.524 I.28 J5.474 E1.06126
; WIPE_START
M204 S3000
G1 X25.498 Y153.523 E-.1119
G1 X24.927 Y153.583 E-.10911
G1 X24.366 Y153.702 E-.10906
G1 X24.114 Y153.777 E-.04992
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.634 Y159.927 Z6.8 F36000
G1 X29.484 Y161.084 Z6.8
G1 Z6.4
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.479928
G1 F1372.975
M204 S3000
G1 X29.685 Y160.708 E.01551
G1 X29.893 Y160.125 E.0225
G2 X30.04 Y159.2 I-8.208 J-1.775 E.03404
G1 X29.993 Y158.357 E.03069
G2 X29.486 Y156.89 I-4.94 J.887 E.05663
G2 X28.933 Y156.135 I-6.858 J4.44 E.03402
G1 X28.307 Y155.568 E.03069
G1 X27.538 Y155.12 E.03233
G1 X26.688 Y154.839 E.03253
G1 X26.008 Y154.749 E.02496
G1 X25.142 Y154.79 E.0315
G1 X24.275 Y155.018 E.03257
G1 X23.679 Y155.3 E.02397
G2 X22.92 Y155.853 I4.096 J6.424 E.03413
G1 X22.352 Y156.484 E.03085
G1 X22.081 Y156.907 E.01828
G1 X21.762 Y157.635 E.02886
G1 X21.667 Y157.919 E.0109
G2 X21.531 Y158.8 I8.582 J1.775 E.03239
G1 X21.578 Y159.643 E.03067
G2 X22.083 Y161.108 I5.029 J-.915 E.05655
G2 X22.638 Y161.866 I6.97 J-4.523 E.03413
G1 X23.265 Y162.43 E.03065
G2 X24.075 Y162.898 I4.083 J-6.137 E.03403
G1 X24.883 Y163.16 E.03087
G1 X25.537 Y163.253 E.02399
G2 X26.474 Y163.2 I.011 J-8.218 E.03412
G1 X27.298 Y162.982 E.03099
G1 X27.894 Y162.699 E.02398
G2 X28.651 Y162.148 I-4.114 J-6.441 E.03402
G1 X29.215 Y161.52 E.03066
G1 X29.452 Y161.136 E.01643
; WIPE_START
G1 X29.215 Y161.52 E-.08592
G1 X28.651 Y162.148 E-.16033
G1 X28.316 Y162.409 E-.08058
G1 X28.086 Y162.567 E-.05317
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X22.892 Y156.974 Z6.8 F36000
G1 X22.696 Y156.762 Z6.8
G1 Z6.4
G1 E.4 F1800
; LINE_WIDTH: 0.469387
G1 F1406.911
M204 S3000
G1 X22.943 Y156.441 E.01438
G1 X23.52 Y155.92 E.02756
G1 X24.209 Y155.513 E.02835
G1 X24.971 Y155.263 E.02846
G1 X25.582 Y155.181 E.02185
G1 X26.362 Y155.217 E.02769
G1 X27.135 Y155.422 E.02836
G1 X27.854 Y155.783 E.02853
G1 X28.33 Y156.145 E.02121
G1 X28.867 Y156.737 E.02835
G1 X29.193 Y157.26 E.02185
G1 X29.473 Y157.989 E.02771
G1 X29.603 Y158.78 E.02842
G1 X29.592 Y159.381 E.0213
G1 X29.47 Y160.006 E.02258
G3 X29.086 Y160.931 I-4.649 J-1.39 E.0356
G1 X28.642 Y161.542 E.02678
G1 X28.051 Y162.08 E.02836
G1 X27.374 Y162.481 E.02788
G1 X26.794 Y162.688 E.02183
G1 X26.005 Y162.817 E.02837
G1 X25.388 Y162.806 E.02186
G1 X24.624 Y162.643 E.0277
G1 X23.893 Y162.322 E.02833
G1 X23.243 Y161.856 E.02835
G1 X22.703 Y161.263 E.02844
G1 X22.384 Y160.755 E.02128
G1 X22.098 Y160.011 E.02828
G1 X21.968 Y159.22 E.02843
G1 X21.978 Y158.619 E.0213
G1 X22.099 Y158 E.02239
G1 X22.38 Y157.271 E.02768
G1 X22.664 Y156.813 E.01911
; CHANGE_LAYER
; Z_HEIGHT: 6.6
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1406.911
G1 X22.38 Y157.271 E-.10241
G1 X22.099 Y158 E-.14833
G1 X21.978 Y158.619 E-.11998
G1 X21.978 Y158.668 E-.00929
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L33
M991 S0 P32 ;notify layer change


M204 S10000
G17
G3 Z6.8 I1.217 J0 P1  F36000
; object ids of layer 33 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer33 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.024 Y93.55
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.716 Y93.671 E.01119
G2 X230.203 Y93.352 I1.494 J3.34 E.72628
G1 X230.023 Y93.357 E.00609
G2 X229.08 Y93.531 I.186 J3.654 E.03255
M204 S10000
G1 X229.169 Y93.93 F36000
G1 F1473.913
M204 S3000
G1 X228.881 Y94.043 E.01047
G2 X230.203 Y93.759 I1.328 J2.968 E.64546
G1 X230.044 Y93.763 E.00539
G2 X229.226 Y93.911 I.165 J3.247 E.0282
M204 S250
G1 X229.31 Y94.295 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.041 Y94.401 E.00905
G2 X230.203 Y94.151 I1.168 J2.61 E.5258
G1 X230.064 Y94.155 E.00437
G2 X229.367 Y94.278 I.145 J2.856 E.02224
; WIPE_START
M204 S3000
G1 X229.041 Y94.401 E-.06623
G1 X228.645 Y94.613 E-.08528
G1 X228.403 Y94.789 E-.05689
G1 X228.181 Y94.989 E-.05685
G1 X227.98 Y95.212 E-.05689
G1 X227.805 Y95.454 E-.05686
G1 X227.802 Y95.458 E-.00101
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.905 Y92.503 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.751 Y92.542 E.00539
G2 X230.429 Y92.321 I1.442 J4.469 E.94108
G1 X230.203 Y92.315 E.00767
G2 X229.226 Y92.415 I-.01 J4.696 E.0333
G1 X228.963 Y92.488 E.00923
M204 S10000
G1 X228.8 Y92.111 F36000
G1 F1473.913
M204 S3000
G1 X228.625 Y92.154 E.00611
G2 X230.45 Y91.914 I1.568 J4.856 E1.02265
G1 X230.203 Y91.908 E.00836
G2 X229.141 Y92.017 I-.011 J5.103 E.03619
G1 X228.858 Y92.095 E.00995
M204 S250
G1 X228.698 Y91.727 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.504 Y91.783 E.00631
G2 X230.47 Y91.522 I1.694 J5.225 E1.01951
G2 X229.916 Y91.523 I-.272 J5.277 E.01738
G2 X228.78 Y91.702 I.282 J5.485 E.0361
G1 X228.755 Y91.71 E.00084
; WIPE_START
M204 S3000
G1 X228.504 Y91.783 E-.04962
G1 X227.968 Y91.991 E-.10934
G1 X227.437 Y92.263 E-.11328
G1 X226.972 Y92.565 E-.10532
G1 X226.963 Y92.573 E-.00244
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X229.098 Y92.988 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672817
G1 F952.537
M204 S3000
G1 X228.912 Y93.038 E.01007
G1 X228.511 Y93.191 E.02246
G1 X228.107 Y93.398 E.02378
G1 X227.754 Y93.627 E.02204
G1 X227.414 Y93.901 E.02289
G1 X227.243 Y94.063 E.01233
G1 X226.956 Y94.382 E.02246
G1 X226.704 Y94.729 E.02247
G1 X226.581 Y94.93 E.01233
G1 X226.383 Y95.32 E.02292
G1 X226.23 Y95.72 E.02245
G1 X226.116 Y96.143 E.0229
G1 X226.048 Y96.575 E.02291
G1 X226.025 Y97.003 E.02248
G1 X226.048 Y97.449 E.02335
G1 X226.115 Y97.873 E.02248
G1 X226.227 Y98.295 E.02288
G1 X226.307 Y98.52 E.0125
G1 X226.48 Y98.908 E.0223
G1 X226.699 Y99.287 E.02292
G1 X226.956 Y99.641 E.02289
G1 X227.249 Y99.966 E.02291
G1 X227.574 Y100.258 E.02288
G1 X227.921 Y100.511 E.02248
G1 X228.122 Y100.634 E.01235
G1 X228.511 Y100.832 E.02289
G1 X228.912 Y100.985 E.02247
G1 X229.334 Y101.098 E.02289
G1 X229.766 Y101.167 E.02291
G1 X230.203 Y101.19 E.02292
G1 X230.64 Y101.167 E.02291
G1 X231.064 Y101.1 E.02246
G1 X231.486 Y100.988 E.0229
G1 X231.711 Y100.908 E.01249
G1 X232.1 Y100.734 E.02231
G1 X232.479 Y100.515 E.02292
G1 X232.832 Y100.259 E.02288
G1 X233.163 Y99.96 E.02334
G1 X233.45 Y99.641 E.02247
G1 X233.707 Y99.287 E.02292
G1 X233.926 Y98.908 E.02291
G1 X234.101 Y98.517 E.02245
G1 X234.179 Y98.295 E.01234
G1 X234.291 Y97.872 E.02289
G1 X234.358 Y97.449 E.02247
G1 X234.381 Y97.012 E.02292
G1 X234.358 Y96.575 E.02292
G1 X234.29 Y96.143 E.02291
G1 X234.177 Y95.72 E.02289
G1 X234.023 Y95.32 E.02246
G1 X233.826 Y94.93 E.0229
G1 X233.702 Y94.729 E.01235
G1 X233.462 Y94.397 E.02148
G1 X233.157 Y94.057 E.02388
G1 X232.833 Y93.765 E.0229
G1 X232.478 Y93.508 E.02291
G1 X232.1 Y93.289 E.0229
G1 X231.708 Y93.114 E.02246
G1 X231.486 Y93.036 E.01233
G1 X231.064 Y92.923 E.02289
G1 X230.642 Y92.857 E.02236
G1 X230.203 Y92.833 E.02304
G1 X229.766 Y92.856 E.02291
G1 X229.334 Y92.925 E.0229
G1 X229.156 Y92.973 E.00969
; OBJECT_ID: 12
; WIPE_START
G1 X228.912 Y93.038 E-.04794
G1 X228.511 Y93.191 E-.08146
G1 X228.107 Y93.398 E-.08625
G1 X227.754 Y93.627 E-.07995
G1 X227.414 Y93.901 E-.08305
G1 X227.409 Y93.906 E-.00135
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.227 Y96.49 Z7 F36000
G1 X211.77 Y99.532 Z7
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.944 Y99.325 E.00916
G2 X208.777 Y93.115 I-3.16 J-2.301 E.29133
G1 X208.585 Y93.12 E.0065
G2 X211.686 Y99.643 I.199 J3.904 E.51959
G1 X211.734 Y99.58 E.00269
M204 S10000
G1 X211.454 Y99.276 F36000
G1 F1473.913
M204 S3000
G1 X211.614 Y99.085 E.00843
G2 X208.777 Y93.522 I-2.83 J-2.062 E.26101
G1 X208.606 Y93.527 E.0058
G2 X211.383 Y99.37 I.178 J3.497 E.46547
G1 X211.418 Y99.324 E.00196
M204 S250
G1 X211.15 Y99.03 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.297 Y98.855 E.00717
G2 X208.777 Y93.915 I-2.513 J-1.831 E.2147
G1 X208.626 Y93.919 E.00475
G2 X211.091 Y99.108 I.157 J3.105 E.3829
G1 X211.114 Y99.078 E.00118
; WIPE_START
M204 S3000
G1 X211.297 Y98.855 E-.05481
G1 X211.471 Y98.58 E-.06187
M73 P93 R2
G1 X211.619 Y98.29 E-.06186
G1 X211.735 Y97.986 E-.06186
G1 X211.849 Y97.511 E-.09273
G1 X211.875 Y97.266 E-.04687
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.574 Y99.166 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X209.004 Y92.321 I4.193 J-2.142 E.66781
G1 X208.777 Y92.315 E.00768
G2 X204.547 Y99.113 I-.01 J4.709 E.32397
M204 S10000
G1 X204.211 Y99.351 F36000
G1 F1473.913
M204 S3000
G2 X209.025 Y91.914 I4.556 J-2.328 E.72554
G1 X208.777 Y91.908 E.00838
G2 X204.184 Y99.298 I-.01 J5.116 E.35214
M204 S250
G1 X203.864 Y99.515 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X203.862 Y99.529 E.00047
G2 X209.045 Y91.522 I4.905 J-2.506 E.72357
G1 X208.777 Y91.515 E.00839
G2 X203.626 Y99.002 I-.011 J5.508 E.33507
G1 X203.838 Y99.46 E.01583
; WIPE_START
M204 S3000
G1 X203.862 Y99.529 E-.01387
G1 X204.157 Y100.025 E-.10964
G1 X204.496 Y100.492 E-.10956
G1 X204.882 Y100.92 E-.10959
G1 X205.028 Y101.052 E-.03734
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.934 Y98.972 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.43596
G1 F1526.562
M204 S3000
G1 X204.937 Y98.981 E.00032
G1 X205.163 Y99.372 E.01475
G1 X205.428 Y99.737 E.01475
G1 X205.73 Y100.072 E.01475
G1 X206.065 Y100.373 E.01473
G1 X206.43 Y100.639 E.01476
G1 X206.821 Y100.865 E.01474
G1 X207.228 Y101.046 E.01457
G1 X207.451 Y101.125 E.00771
G1 X207.887 Y101.241 E.01475
G1 X208.327 Y101.311 E.01456
G1 X208.777 Y101.334 E.01475
G1 X209.228 Y101.31 E.01475
G1 X209.668 Y101.241 E.01456
G1 X210.104 Y101.125 E.01475
G1 X210.327 Y101.046 E.00771
G1 X210.734 Y100.865 E.01456
G1 X211.125 Y100.639 E.01475
G1 X211.49 Y100.374 E.01475
G1 X211.825 Y100.072 E.01474
G1 X212.127 Y99.737 E.01474
G1 X212.392 Y99.372 E.01474
G1 X212.619 Y98.977 E.0149
G1 X212.799 Y98.574 E.01441
G1 X212.878 Y98.351 E.00772
G1 X212.994 Y97.916 E.01473
G1 X213.063 Y97.475 E.01457
G1 X213.087 Y97.025 E.01475
G1 X213.063 Y96.574 E.01475
G1 X212.993 Y96.128 E.01474
G1 X212.876 Y95.693 E.01473
G1 X212.717 Y95.277 E.01457
G1 X212.615 Y95.063 E.00773
G1 X212.389 Y94.673 E.01473
G1 X212.127 Y94.312 E.01458
G1 X211.825 Y93.977 E.01474
G1 X211.49 Y93.675 E.01474
G1 X211.125 Y93.411 E.01473
G1 X210.734 Y93.185 E.01474
G1 X210.327 Y93.003 E.01458
G1 X210.104 Y92.924 E.00771
G1 X209.668 Y92.808 E.01475
G1 X209.23 Y92.739 E.01449
M73 P94 R2
G1 X208.777 Y92.715 E.01482
G1 X208.327 Y92.739 E.01475
G1 X207.882 Y92.809 E.01473
G1 X207.446 Y92.926 E.01475
G1 X207.03 Y93.085 E.01456
G1 X206.816 Y93.187 E.00771
G1 X206.426 Y93.413 E.01475
G1 X206.065 Y93.676 E.01457
G1 X205.73 Y93.977 E.01474
G1 X205.432 Y94.308 E.01455
G1 X205.286 Y94.498 E.00781
G1 X205.045 Y94.869 E.01447
G1 X204.838 Y95.277 E.01493
G1 X204.679 Y95.693 E.01457
G1 X204.562 Y96.129 E.01474
G1 X204.491 Y96.574 E.01474
G1 X204.468 Y97.025 E.01475
G1 X204.491 Y97.47 E.01457
G1 X204.522 Y97.707 E.0078
G1 X204.615 Y98.14 E.01448
G1 X204.756 Y98.574 E.01493
G1 X204.909 Y98.917 E.01228
; OBJECT_ID: 11
; WIPE_START
G1 X204.937 Y98.981 E-.01323
G1 X205.163 Y99.372 E-.08573
G1 X205.428 Y99.737 E-.08573
G1 X205.73 Y100.072 E-.08573
G1 X206.065 Y100.373 E-.08561
G1 X206.167 Y100.448 E-.02397
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.765 Y98.588 Z7 F36000
G1 X183.804 Y94.829 Z7
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.624 Y95.154 E.01258
G2 X187.324 Y92.88 I3.707 J1.884 E.72979
G1 X187.12 Y92.885 E.00691
G2 X183.841 Y94.777 I.211 J4.153 E.13303
G1 X183.839 Y94.78 E.00012
M204 S10000
G1 X184.17 Y95.016 F36000
G1 F1473.913
M204 S3000
G1 X184.08 Y95.166 E.00591
G2 X187.324 Y93.287 I3.251 J1.872 E.66499
G1 X187.141 Y93.292 E.00622
G2 X184.293 Y94.837 I.19 J3.747 E.11339
G1 X184.204 Y94.967 E.00534
M204 S250
G1 X184.496 Y95.228 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.336 Y95.516 E.01034
G2 X187.324 Y93.679 I2.995 J1.522 E.5461
G1 X187.161 Y93.683 E.00514
G2 X184.532 Y95.18 I.17 J3.355 E.09839
; WIPE_START
M204 S3000
G1 X184.336 Y95.516 E-.07389
G1 X184.187 Y95.835 E-.06679
G1 X184.038 Y96.341 E-.1002
G1 X183.983 Y96.688 E-.0668
G1 X183.964 Y97.039 E-.06684
G1 X183.966 Y97.068 E-.00548
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.547 Y92.321 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.324 Y92.315 E.00755
G2 X187.607 Y92.324 I-.01 J4.723 E.995
M204 S10000
G1 X187.558 Y91.914 F36000
G1 F1473.913
M204 S3000
G1 X187.324 Y91.908 E.00791
G2 X187.618 Y91.917 I-.01 J5.131 E1.08123
M204 S250
G1 X187.568 Y91.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X187.324 Y91.515 E.00765
G2 X187.628 Y91.524 I-.011 J5.523 E1.07848
; WIPE_START
M204 S3000
G1 X187.324 Y91.515 E-.05773
G1 X186.747 Y91.546 E-.10986
G1 X186.176 Y91.636 E-.10985
G1 X185.654 Y91.776 E-.10255
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.571 Y92.61 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200558
G1 F3806.204
M204 S3000
G1 X187.324 Y92.597 E.00324
G1 X186.86 Y92.622 E.00609
G1 X186.403 Y92.694 E.00607
G1 X185.954 Y92.814 E.00609
G1 X185.73 Y92.893 E.00311
G1 X185.31 Y93.08 E.00604
G1 X184.905 Y93.314 E.00612
G1 X184.529 Y93.587 E.0061
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.0061
G1 X183.6 Y94.618 E.00607
G1 X183.477 Y94.82 E.0031
G1 X183.265 Y95.235 E.0061
G1 X183.1 Y95.667 E.00606
G1 X182.979 Y96.116 E.00609
G1 X182.907 Y96.575 E.00609
G1 X182.882 Y97.037 E.00607
G1 X182.907 Y97.503 E.00612
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.00609
G1 X183.179 Y98.635 E.00314
G1 X183.366 Y99.056 E.00603
G1 X183.599 Y99.458 E.00609
G1 X183.872 Y99.835 E.0061
G1 X184.183 Y100.18 E.00609
G1 X184.529 Y100.491 E.00609
G1 X184.905 Y100.764 E.0061
G1 X185.308 Y100.997 E.00609
G1 X185.728 Y101.184 E.00604
G1 X185.954 Y101.264 E.00314
G1 X186.403 Y101.384 E.00609
G1 X186.86 Y101.457 E.00607
G1 X187.324 Y101.481 E.00609
G1 X187.789 Y101.456 E.00609
G1 X188.246 Y101.384 E.00607
G1 X188.695 Y101.264 E.00609
G1 X188.918 Y101.185 E.00311
G1 X189.341 Y100.997 E.00607
G1 X189.744 Y100.764 E.00609
G1 X190.12 Y100.491 E.00609
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.00609
G1 X191.049 Y99.459 E.00609
G1 X191.283 Y99.054 E.00613
G1 X191.47 Y98.633 E.00604
G1 X191.614 Y98.191 E.00609
G1 X191.669 Y97.961 E.0031
G1 X191.742 Y97.504 E.00607
G1 X191.766 Y97.039 E.0061
G1 X191.742 Y96.575 E.0061
G1 X191.669 Y96.116 E.00609
G1 X191.549 Y95.666 E.0061
G1 X191.383 Y95.235 E.00606
G1 X191.281 Y95.02 E.00311
G1 X191.048 Y94.618 E.00609
G1 X190.776 Y94.244 E.00607
G1 X190.465 Y93.898 E.00609
G1 X190.12 Y93.587 E.00609
G1 X189.744 Y93.314 E.00609
G1 X189.341 Y93.081 E.0061
G1 X188.92 Y92.894 E.00603
G1 X188.695 Y92.814 E.00313
G1 X188.246 Y92.694 E.0061
G1 X187.791 Y92.622 E.00604
G1 X187.631 Y92.613 E.0021
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.05833
G1 X186.86 Y92.622 E-.0883
G1 X186.403 Y92.694 E-.08795
G1 X185.954 Y92.814 E-.08829
G1 X185.73 Y92.893 E-.04508
G1 X185.672 Y92.919 E-.01205
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.043 Y93.14 Z7 F36000
G1 X163.144 Y93.573 Z7
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.894 Y93.782 E.01104
G2 X165.84 Y92.646 I2.955 J3.272 E.82828
G1 X165.624 Y92.651 E.00732
G2 X163.251 Y93.492 I.224 J4.403 E.08641
G1 X163.192 Y93.537 E.00253
M204 S10000
G1 X163.394 Y93.898 F36000
G1 F1473.913
M204 S3000
G1 X163.014 Y94.229 E.01705
G2 X165.84 Y93.053 I2.834 J2.825 E.74471
G1 X165.645 Y93.058 E.00663
G2 X163.491 Y93.821 I.203 J3.996 E.07845
G1 X163.441 Y93.861 E.00216
M204 S250
G1 X163.646 Y94.193 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.571 Y94.253 E.00301
G2 X165.84 Y93.445 I2.276 J2.801 E.63407
G1 X165.665 Y93.45 E.00552
G2 X163.876 Y94.031 I.183 J3.605 E.05964
G1 X163.695 Y94.159 E.00695
; WIPE_START
M204 S3000
G1 X163.571 Y94.253 E-.0296
G1 X163.288 Y94.502 E-.07176
G1 X163.035 Y94.783 E-.07179
G1 X162.813 Y95.089 E-.0718
G1 X162.624 Y95.416 E-.07178
G1 X162.488 Y95.72 E-.06326
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.482 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.069 Y92.321 I1.689 J-4.428 E.55438
G1 X165.84 Y92.315 E.00774
G2 X164.085 Y101.461 I-.01 J4.739 E.44384
M204 S10000
G1 X163.995 Y101.863 F36000
G1 F1473.913
M204 S3000
G2 X166.089 Y91.914 I1.835 J-4.808 E.602
G1 X165.84 Y91.908 E.00843
G2 X163.939 Y101.841 I-.011 J5.147 E.48211
M204 S250
G1 X163.869 Y102.232 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.13 Y102.318 E.00865
G2 X166.109 Y91.522 I1.705 J-5.267 E.59104
G2 X165.551 Y91.523 I-.274 J5.321 E.01752
G2 X163.815 Y102.206 I.285 J5.529 E.47154
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.13 Y102.318 E-.06358
G1 X164.689 Y102.474 E-.11012
G1 X165.24 Y102.562 E-.10617
G1 X165.767 Y102.591 E-.10014
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.982 Y106.088 Z7 F36000
G1 X47.383 Y163.61 Z7
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X47.366 Y154.321 I-.251 J-4.644 E.47818
G1 X47.142 Y154.315 E.00759
G2 X47.323 Y163.613 I-.01 J4.651 E.50142
M204 S10000
G1 X47.383 Y164.013 F36000
G1 F1473.913
M204 S3000
G1 X47.69 Y163.993 E.01041
G2 X47.386 Y153.914 I-.559 J-5.027 E.51031
G1 X47.142 Y153.908 E.00829
G2 X47.142 Y164.024 I-.01 J5.058 E.5386
G1 X47.323 Y164.016 E.00616
M204 S250
G1 X47.405 Y164.404 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.732 Y164.383 E.01027
G2 X47.406 Y153.522 I-.601 J-5.417 E.50938
G1 X47.142 Y153.515 E.0083
G2 X47.142 Y164.416 I-.011 J5.45 E.53755
G1 X47.345 Y164.407 E.00638
; WIPE_START
M204 S3000
G1 X47.732 Y164.383 E-.07363
G1 X48.275 Y164.299 E-.10446
G1 X48.826 Y164.152 E-.10838
G1 X49.286 Y163.975 E-.09353
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X43.21 Y161.124 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X44.305 Y162.219 E.05039
G2 X45.659 Y163.02 I2.929 J-3.409 E.05145
G1 X43.092 Y160.453 E.11815
G3 X42.887 Y159.694 I3.481 J-1.347 E.02561
G1 X46.414 Y163.221 E.16232
G2 X47.026 Y163.279 I.844 J-5.622 E.02001
G1 X42.829 Y159.082 E.19316
G3 X42.849 Y158.549 I2.548 J-.171 E.0174
G1 X47.559 Y163.259 E.21678
G2 X48.039 Y163.185 I-.112 J-2.313 E.01582
G1 X42.923 Y158.07 E.23543
G3 X43.041 Y157.633 I2.132 J.338 E.01473
G1 X48.475 Y163.068 E.25013
G2 X48.876 Y162.915 I-.526 J-1.984 E.01398
G1 X43.193 Y157.233 E.26155
G3 X43.377 Y156.863 I1.85 J.688 E.01346
G1 X49.246 Y162.732 E.27012
G2 X49.588 Y162.52 I-.835 J-1.732 E.01311
G1 X43.586 Y156.518 E.27623
G3 X43.828 Y156.207 I2.102 J1.382 E.01285
G1 X49.905 Y162.284 E.27971
G2 X50.191 Y162.016 I-1.555 J-1.945 E.01276
G1 X44.092 Y155.918 E.28069
G3 X44.381 Y155.653 I1.403 J1.243 E.01277
G1 X50.455 Y161.727 E.27956
G2 X50.695 Y161.413 I-1.376 J-1.298 E.01288
G1 X44.695 Y155.414 E.27614
G3 X45.034 Y155.199 I1.533 J2.042 E.01307
G1 X50.91 Y161.074 E.27043
G2 X51.09 Y160.701 I-2.355 J-1.371 E.0135
G1 X45.407 Y155.018 E.26156
G3 X45.808 Y154.866 I.927 J1.831 E.01398
G1 X51.243 Y160.3 E.25013
G2 X51.36 Y159.864 I-2.02 J-.775 E.01473
G1 X46.245 Y154.749 E.23543
G3 X46.724 Y154.675 I.592 J2.242 E.01581
G1 X51.434 Y159.385 E.21678
G2 X51.454 Y158.851 I-2.528 J-.363 E.0174
G1 X47.257 Y154.654 E.19318
G3 X47.873 Y154.716 I-.03 J3.368 E.02018
G1 X51.396 Y158.24 E.16215
G2 X51.19 Y157.481 I-3.557 J.556 E.02564
G1 X48.628 Y154.918 E.11793
G3 X49.978 Y155.714 I-1.339 J3.813 E.05132
G1 X51.073 Y156.81 E.05041
; OBJECT_ID: 14
; WIPE_START
G1 X49.978 Y155.714 E-.29429
G1 X49.68 Y155.473 E-.0728
G1 X49.623 Y155.436 E-.01291
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X41.991 Y155.52 Z7 F36000
G1 X26.589 Y155.691 Z7
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.494 Y155.664 E.00334
G2 X25.785 Y155.59 I-.703 J3.336 E.02417
G1 X25.618 Y155.595 E.00568
G2 X26.839 Y155.756 I.173 J3.404 E.68305
G1 X26.647 Y155.706 E.00671
M204 S10000
G1 X26.484 Y156.083 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.062 E.00261
G2 X25.785 Y155.998 I-.619 J2.937 E.02129
G1 X25.638 Y156.002 E.00498
G2 X26.713 Y156.143 I.152 J2.998 E.60149
G1 X26.542 Y156.098 E.00599
M204 S250
G1 X26.383 Y156.462 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.446 E.00178
G2 X25.785 Y156.39 I-.538 J2.553 E.01714
G1 X25.658 Y156.393 E.00399
G2 X26.592 Y156.516 I.132 J2.606 E.48439
M73 P95 R2
G1 X26.441 Y156.477 E.00491
; WIPE_START
M204 S3000
G1 X26.328 Y156.446 E-.02217
G1 X26.058 Y156.404 E-.05191
G1 X25.785 Y156.39 E-.05191
G1 X25.658 Y156.393 E-.02419
G1 X25.243 Y156.447 E-.07961
G1 X24.979 Y156.518 E-.05187
G1 X24.724 Y156.616 E-.05193
G1 X24.506 Y156.726 E-.0464
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.011 Y154.321 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.785 Y154.315 E.00765
G2 X26.071 Y154.324 I-.01 J4.684 E.98658
M204 S10000
G1 X26.021 Y153.914 F36000
G1 F1473.913
M204 S3000
G1 X25.785 Y153.908 E.00798
G2 X26.081 Y153.917 I-.01 J5.091 E1.07283
M204 S250
G1 X26.031 Y153.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.785 Y153.515 E.00771
G2 X26.091 Y153.524 I-.011 J5.484 E1.0707
; WIPE_START
M204 S3000
G1 X25.785 Y153.515 E-.05814
G1 X25.212 Y153.545 E-.10908
G1 X24.645 Y153.635 E-.10908
G1 X24.118 Y153.776 E-.10371
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.064 Y160.309 Z7 F36000
G1 X28.97 Y161.808 Z7
G1 Z6.6
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.478184
G1 F1378.474
M204 S3000
G1 X29.243 Y161.484 E.01536
G1 X29.576 Y160.939 E.02309
G2 X30.04 Y159.2 I-4.355 J-2.091 E.06554
G1 X29.993 Y158.357 E.03057
G2 X29.485 Y156.891 I-4.932 J.887 E.05638
G2 X28.935 Y156.133 I-7.058 J4.549 E.03388
G1 X28.307 Y155.568 E.03059
G1 X27.538 Y155.12 E.03222
G1 X26.688 Y154.839 E.03239
G1 X26.004 Y154.748 E.02499
G2 X24.949 Y154.835 I-.233 J3.609 E.03843
G1 X24.661 Y154.893 E.01065
G2 X23.332 Y155.518 I1.389 J4.685 E.05335
G1 X22.667 Y156.101 E.03202
G1 X22.132 Y156.813 E.03222
G1 X21.818 Y157.452 E.02578
G1 X21.584 Y158.311 E.03223
G1 X21.53 Y159.164 E.03093
G1 X21.656 Y160.039 E.03199
G1 X21.806 Y160.525 E.01839
G1 X22.085 Y161.106 E.02336
G2 X23.085 Y162.294 I4.365 J-2.66 E.0564
G2 X23.873 Y162.804 I4.667 J-6.339 E.034
G2 X25.585 Y163.254 I2.071 J-4.397 E.06444
G1 X26.428 Y163.208 E.03055
G2 X28.09 Y162.581 I-.897 J-4.895 E.06464
G1 X28.615 Y162.181 E.02387
G1 X28.928 Y161.851 E.01646
; WIPE_START
G1 X28.615 Y162.181 E-.08643
G1 X28.09 Y162.581 E-.12529
G1 X27.492 Y162.894 E-.12835
G1 X27.293 Y162.962 E-.03994
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.35 Y157.642 Z7 F36000
G1 Z6.6
G1 E.4 F1800
; LINE_WIDTH: 0.474132
G1 F1391.427
M204 S3000
G1 X29.485 Y158.032 E.01478
G1 X29.603 Y158.78 E.02717
G1 X29.592 Y159.38 E.02152
G1 X29.471 Y160 E.02263
G1 X29.187 Y160.735 E.02827
G3 X28.612 Y161.575 I-4.21 J-2.268 E.03657
G1 X28.053 Y162.082 E.02707
G1 X27.359 Y162.486 E.02878
G1 X26.793 Y162.689 E.02154
G1 X26.005 Y162.817 E.02864
G1 X25.405 Y162.807 E.02153
G1 X24.786 Y162.686 E.02262
G1 X24.041 Y162.398 E.02862
G1 X23.366 Y161.956 E.02893
G3 X22.679 Y161.23 I3.184 J-3.699 E.03592
G1 X22.298 Y160.574 E.02718
G1 X22.091 Y160.01 E.02154
G1 X21.963 Y159.22 E.02868
G1 X21.979 Y158.62 E.02155
G1 X22.141 Y157.839 E.02857
G3 X22.458 Y157.105 I5.831 J2.084 E.02869
G1 X22.926 Y156.455 E.02871
G1 X23.517 Y155.916 E.02869
G1 X24.054 Y155.596 E.02244
G1 X24.808 Y155.308 E.02892
G1 X25.577 Y155.177 E.02797
G1 X26.362 Y155.217 E.0282
G1 X27.135 Y155.422 E.02867
G1 X27.852 Y155.782 E.02875
G3 X28.753 Y156.586 I-2.113 J3.274 E.04351
G1 X29.102 Y157.104 E.02238
G1 X29.325 Y157.587 E.01908
; CHANGE_LAYER
; Z_HEIGHT: 6.8
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1391.427
G1 X29.102 Y157.104 E-.10113
G1 X28.753 Y156.586 E-.11859
G1 X28.332 Y156.147 E-.11565
G1 X28.145 Y156.005 E-.04463
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L34
M991 S0 P33 ;notify layer change


M204 S10000
G17
G3 Z7 I1.217 J0 P1  F36000
; object ids of layer 34 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer34 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.022 Y93.551
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.715 Y93.67 E.01114
G2 X230.203 Y93.352 I1.492 J3.341 E.72628
G1 X230.018 Y93.357 E.00625
G2 X229.079 Y93.53 I.189 J3.654 E.03244
M204 S10000
G1 X229.168 Y93.93 F36000
G1 F1473.913
M204 S3000
G1 X228.881 Y94.042 E.01042
G2 X230.203 Y93.759 I1.326 J2.969 E.64546
G1 X230.039 Y93.764 E.00554
G2 X229.225 Y93.911 I.168 J3.247 E.02811
M204 S250
G1 X229.308 Y94.296 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.04 Y94.4 E.00901
G2 X230.203 Y94.151 I1.166 J2.611 E.52579
G1 X230.06 Y94.155 E.0045
G2 X229.365 Y94.278 I.147 J2.856 E.02216
; WIPE_START
M204 S3000
G1 X229.04 Y94.4 E-.06595
G1 X228.773 Y94.535 E-.05688
G1 X228.522 Y94.698 E-.05686
G1 X228.289 Y94.886 E-.05691
G1 X228.078 Y95.098 E-.05684
G1 X227.804 Y95.454 E-.08528
G1 X227.801 Y95.46 E-.00128
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.972 Y92.48 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X228.519 Y92.625 E.01609
G2 X230.437 Y92.321 I1.678 J4.386 E.93251
G1 X230.203 Y92.315 E.00793
G2 X229.029 Y92.462 I-.006 J4.696 E.04016
M204 S10000
G1 X228.827 Y92.103 F36000
G1 F1473.913
M204 S3000
G1 X228.625 Y92.156 E.00706
G2 X230.458 Y91.914 I1.572 J4.855 E1.02239
G1 X230.203 Y91.908 E.00863
G2 X229.142 Y92.018 I-.006 J5.103 E.03619
G1 X228.885 Y92.088 E.009
M204 S250
G1 X228.726 Y91.725 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X228.504 Y91.782 E.00718
G2 X230.478 Y91.523 I1.692 J5.228 E1.01981
G1 X230.203 Y91.515 E.00863
G2 X229.06 Y91.634 I-.007 J5.495 E.03609
G1 X228.784 Y91.709 E.00899
; WIPE_START
M204 S3000
G1 X228.504 Y91.782 E-.0549
G1 X228.233 Y91.88 E-.0547
G1 X227.708 Y92.114 E-.10931
G1 X227.21 Y92.402 E-.10926
G1 X226.989 Y92.562 E-.05183
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X229.124 Y92.981 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.672818
G1 F952.535
M204 S3000
G1 X228.92 Y93.035 E.01103
G2 X226.025 Y97.012 I1.283 J3.976 E.27545
G1 X226.048 Y97.449 E.02292
G1 X226.115 Y97.872 E.02248
G1 X226.227 Y98.294 E.02287
G1 X226.306 Y98.519 E.01246
G2 X229.334 Y92.924 I3.897 J-1.508 E.99625
G1 X229.182 Y92.966 E.00828
; OBJECT_ID: 12
; WIPE_START
G1 X228.92 Y93.035 E-.05142
G1 X228.698 Y93.114 E-.04482
G1 X228.306 Y93.289 E-.08143
G1 X227.928 Y93.507 E-.08309
G1 X227.58 Y93.759 E-.08152
G1 X227.429 Y93.888 E-.03771
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X220.25 Y96.478 Z7.2 F36000
G1 X211.766 Y99.538 Z7.2
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X211.942 Y99.324 E.00936
G2 X208.777 Y93.115 I-3.16 J-2.3 E.2912
G1 X208.58 Y93.12 E.00668
G2 X211.684 Y99.642 I.201 J3.904 E.51957
G1 X211.729 Y99.585 E.00246
M204 S10000
G1 X211.437 Y99.298 F36000
G1 F1473.913
M204 S3000
G1 X211.501 Y99.23 E.00315
G2 X208.777 Y93.522 I-2.719 J-2.206 E.26709
G1 X208.601 Y93.527 E.00597
G2 X211.255 Y99.502 I.18 J3.497 E.45924
G1 X211.397 Y99.342 E.00724
M204 S250
G1 X211.146 Y99.036 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.196 Y98.983 E.00227
G2 X208.777 Y93.915 I-2.415 J-1.959 E.21971
G1 X208.621 Y93.919 E.00489
G2 X210.978 Y99.225 I.16 J3.105 E.37776
G1 X211.106 Y99.08 E.00606
; WIPE_START
M204 S3000
G1 X211.196 Y98.983 E-.02518
G1 X211.386 Y98.719 E-.06182
G1 X211.619 Y98.29 E-.09277
G1 X211.733 Y97.992 E-.06057
G1 X211.82 Y97.671 E-.06312
G1 X211.871 Y97.35 E-.06185
G1 X211.875 Y97.272 E-.0147
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.577 Y99.165 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X209.012 Y92.321 I4.194 J-2.141 E.66773
G1 X208.777 Y92.315 E.00795
G2 X204.551 Y99.111 I-.006 J4.709 E.32379
M204 S10000
G1 X204.217 Y99.345 F36000
G1 F1473.913
M204 S3000
G1 X204.214 Y99.35 E.00019
G2 X209.033 Y91.914 I4.557 J-2.326 E.72546
G1 X208.777 Y91.908 E.00865
G2 X203.996 Y98.86 I-.006 J5.116 E.33581
G1 X204.192 Y99.29 E.016
M204 S250
G1 X203.864 Y99.501 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X204.003 Y99.781 E.00981
G2 X209.053 Y91.523 I4.768 J-2.758 E.71446
G1 X208.777 Y91.515 E.00865
G2 X203.74 Y99.267 I-.006 J5.508 E.34394
G1 X203.836 Y99.448 E.00641
; WIPE_START
M204 S3000
G1 X204.003 Y99.781 E-.07084
G1 X204.32 Y100.263 E-.10961
G1 X204.496 Y100.492 E-.05481
G1 X204.882 Y100.92 E-.10957
G1 X205.019 Y101.044 E-.03518
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.929 Y98.961 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.43596
G1 F1526.565
M204 S3000
G1 X204.938 Y98.981 E.00074
G1 X205.163 Y99.372 E.01473
G1 X205.428 Y99.737 E.01474
G1 X205.73 Y100.072 E.01473
G1 X206.065 Y100.374 E.01475
G1 X206.431 Y100.639 E.01475
G1 X206.821 Y100.864 E.01473
G1 X207.228 Y101.046 E.01458
G1 X207.451 Y101.125 E.00771
G1 X207.887 Y101.241 E.01475
G1 X208.327 Y101.311 E.01456
G1 X208.777 Y101.334 E.01475
G1 X209.228 Y101.311 E.01476
G1 X209.668 Y101.241 E.01456
G1 X210.104 Y101.125 E.01475
G1 X210.328 Y101.045 E.00777
G1 X210.734 Y100.864 E.01452
G1 X211.125 Y100.639 E.01475
G1 X211.49 Y100.374 E.01474
G1 X211.825 Y100.072 E.01473
G1 X212.127 Y99.737 E.01474
G1 X212.392 Y99.372 E.01474
G1 X212.62 Y98.976 E.01492
G1 X212.799 Y98.574 E.0144
G1 X212.938 Y98.147 E.01468
G1 X212.994 Y97.916 E.00776
G1 X213.063 Y97.475 E.01457
G1 X213.087 Y97.025 E.01475
G1 X213.063 Y96.574 E.01475
G1 X212.994 Y96.135 E.01451
G1 X212.939 Y95.904 E.00777
G1 X212.799 Y95.475 E.01475
G1 X212.617 Y95.068 E.01457
G1 X212.392 Y94.677 E.01473
G1 X212.127 Y94.312 E.01475
G1 X211.825 Y93.977 E.01474
G1 X211.49 Y93.675 E.01474
G1 X211.125 Y93.41 E.01475
G1 X210.734 Y93.185 E.01474
G1 X210.327 Y93.003 E.01458
G1 X209.898 Y92.863 E.01473
G1 X209.668 Y92.808 E.00772
G1 X209.23 Y92.739 E.01452
G1 X208.777 Y92.715 E.0148
G1 X208.327 Y92.739 E.01474
G1 X207.881 Y92.809 E.01475
G1 X207.445 Y92.926 E.01474
G1 X207.029 Y93.086 E.01456
G1 X206.816 Y93.187 E.00771
G1 X206.426 Y93.413 E.01475
G1 X206.065 Y93.675 E.01457
G1 X205.73 Y93.977 E.01474
G1 X205.428 Y94.312 E.01474
G1 X205.166 Y94.673 E.01458
G1 X204.94 Y95.063 E.01473
G1 X204.838 Y95.277 E.00773
G1 X204.679 Y95.693 E.01456
G1 X204.562 Y96.129 E.01474
G1 X204.491 Y96.574 E.01473
G1 X204.468 Y97.019 E.01458
G1 X204.491 Y97.47 E.01474
G1 X204.522 Y97.704 E.00772
G1 X204.615 Y98.14 E.01456
G1 X204.756 Y98.574 E.01492
G1 X204.904 Y98.906 E.01188
; OBJECT_ID: 11
; WIPE_START
G1 X204.938 Y98.981 E-.01569
G1 X205.163 Y99.372 E-.08565
G1 X205.428 Y99.737 E-.08571
G1 X205.73 Y100.072 E-.08566
G1 X206.065 Y100.374 E-.08578
G1 X206.157 Y100.44 E-.02151
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X198.752 Y98.589 Z7.2 F36000
G1 X183.795 Y94.849 Z7.2
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X183.528 Y95.349 E.01918
G2 X187.324 Y92.88 I3.8 J1.689 E.72238
G1 X187.114 Y92.885 E.00711
G2 X183.839 Y94.776 I.214 J4.153 E.13288
G1 X183.826 Y94.798 E.00088
M204 S10000
G1 X184.169 Y95.017 F36000
G1 F1473.913
M204 S3000
M73 P95 R1
G1 X184.078 Y95.165 E.00586
G2 X187.324 Y93.287 I3.25 J1.874 E.66496
G1 X187.135 Y93.292 E.00639
G2 X184.292 Y94.836 I.193 J3.747 E.11324
G1 X184.203 Y94.968 E.00539
M204 S250
G1 X184.498 Y95.231 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.418 Y95.361 E.00479
G2 X187.324 Y93.679 I2.911 J1.678 E.55157
G1 X187.156 Y93.684 E.00529
G2 X184.609 Y95.066 I.173 J3.355 E.09395
G1 X184.531 Y95.181 E.00435
; WIPE_START
M204 S3000
G1 X184.418 Y95.361 E-.04043
G1 X184.255 Y95.673 E-.06683
G1 X184.129 Y96.001 E-.06682
G1 X184.006 Y96.514 E-.10017
G1 X183.969 Y96.863 E-.06682
G1 X183.969 Y97.068 E-.03893
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.551 Y92.321 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X187.324 Y92.315 E.00768
G2 X187.611 Y92.324 I-.006 J4.724 E.99488
M204 S10000
G1 X187.562 Y91.914 F36000
G1 F1473.913
M204 S3000
G1 X187.324 Y91.908 E.00804
G2 X187.622 Y91.917 I-.006 J5.131 E1.08111
M204 S250
G1 X187.572 Y91.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
M73 P96 R1
G1 F1500
M204 S1000
G1 X187.324 Y91.515 E.00777
G2 X187.632 Y91.524 I-.007 J5.523 E1.07837
; WIPE_START
M204 S3000
G1 X187.324 Y91.515 E-.05847
G1 X186.747 Y91.546 E-.10986
G1 X186.176 Y91.636 E-.10988
G1 X185.658 Y91.775 E-.10179
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.575 Y92.61 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.200581
G1 F3805.654
M204 S3000
G1 X187.324 Y92.597 E.00329
G1 X186.86 Y92.622 E.0061
G1 X186.403 Y92.694 E.00606
G1 X185.953 Y92.814 E.0061
G1 X185.729 Y92.894 E.00312
G1 X185.307 Y93.082 E.00605
G1 X184.905 Y93.314 E.00609
G1 X184.529 Y93.587 E.0061
G1 X184.183 Y93.898 E.00609
G1 X183.872 Y94.244 E.00609
G1 X183.6 Y94.618 E.00607
G1 X183.477 Y94.82 E.00311
G1 X183.265 Y95.235 E.0061
G1 X183.1 Y95.667 E.00607
G1 X182.979 Y96.116 E.0061
G1 X182.907 Y96.575 E.00609
G1 X182.882 Y97.039 E.00609
G1 X182.907 Y97.504 E.0061
G1 X182.979 Y97.961 E.00607
G1 X183.099 Y98.41 E.00609
G1 X183.179 Y98.634 E.00312
G1 X183.366 Y99.056 E.00605
G1 X183.599 Y99.459 E.0061
G1 X183.872 Y99.835 E.0061
G1 X184.183 Y100.18 E.00609
G1 X184.529 Y100.491 E.00609
G1 X184.905 Y100.764 E.0061
G1 X185.307 Y100.997 E.00609
G1 X185.729 Y101.185 E.00605
G1 X186.175 Y101.33 E.00614
G1 X186.627 Y101.426 E.00607
G1 X186.862 Y101.457 E.0031
G1 X187.324 Y101.481 E.00607
G1 X187.789 Y101.457 E.00609
G1 X188.246 Y101.384 E.00607
G1 X188.695 Y101.264 E.0061
G1 X188.92 Y101.185 E.00312
G1 X189.341 Y100.997 E.00605
G1 X189.744 Y100.764 E.0061
G1 X190.12 Y100.491 E.0061
G1 X190.465 Y100.18 E.00609
G1 X190.776 Y99.835 E.00609
G1 X191.049 Y99.459 E.00609
G1 X191.283 Y99.054 E.00612
G1 X191.47 Y98.633 E.00604
G1 X191.55 Y98.409 E.00312
G1 X191.67 Y97.961 E.00608
G1 X191.742 Y97.503 E.00607
G1 X191.766 Y97.039 E.0061
G1 X191.742 Y96.574 E.0061
G1 X191.67 Y96.118 E.00606
G1 X191.55 Y95.67 E.00607
G1 X191.47 Y95.445 E.00313
G1 X191.282 Y95.023 E.00606
G1 X191.05 Y94.62 E.00609
G1 X190.776 Y94.243 E.0061
G1 X190.465 Y93.899 E.00608
G1 X190.12 Y93.587 E.0061
G1 X189.743 Y93.314 E.0061
G1 X189.341 Y93.081 E.0061
G1 X188.918 Y92.893 E.00606
G1 X188.476 Y92.749 E.00609
G1 X188.246 Y92.694 E.00311
G1 X187.79 Y92.622 E.00605
G1 X187.635 Y92.614 E.00204
; OBJECT_ID: 10
; WIPE_START
G1 X187.324 Y92.597 E-.05906
G1 X186.86 Y92.622 E-.0884
G1 X186.403 Y92.694 E-.0879
G1 X185.953 Y92.814 E-.08834
G1 X185.729 Y92.894 E-.04522
G1 X185.676 Y92.917 E-.01109
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.047 Y93.14 Z7.2 F36000
G1 X163.143 Y93.574 Z7.2
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X162.892 Y93.781 E.01101
G2 X165.84 Y92.646 I2.953 J3.274 E.82826
G1 X165.617 Y92.652 E.00756
G2 X163.25 Y93.49 I.228 J4.403 E.08619
G1 X163.19 Y93.537 E.00257
M204 S10000
G1 X163.399 Y93.89 F36000
G1 F1473.913
M204 S3000
G1 X163.164 Y94.083 E.01029
G2 X165.84 Y93.053 I2.68 J2.971 E.75177
G1 X165.639 Y93.058 E.00684
G2 X163.49 Y93.819 I.206 J3.996 E.07825
G1 X163.446 Y93.853 E.00185
M204 S250
G1 X163.645 Y94.194 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.427 Y94.375 E.00889
G2 X165.84 Y93.445 I2.418 J2.68 E.62813
G1 X165.659 Y93.45 E.00569
G2 X163.72 Y94.137 I.185 J3.605 E.06541
G1 X163.693 Y94.157 E.00107
; WIPE_START
M204 S3000
G1 X163.427 Y94.375 E-.06525
G1 X163.158 Y94.64 E-.07174
G1 X162.92 Y94.933 E-.0718
G1 X162.714 Y95.25 E-.07179
G1 X162.543 Y95.587 E-.07182
G1 X162.49 Y95.722 E-.02759
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.141 Y101.481 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G2 X166.077 Y92.321 I1.693 J-4.427 E.5544
G1 X165.841 Y92.315 E.008
G2 X164.086 Y101.459 I-.006 J4.74 E.44357
M204 S10000
G1 X163.995 Y101.861 F36000
G1 F1473.913
M204 S3000
G2 X166.098 Y91.914 I1.839 J-4.807 E.60202
G1 X165.84 Y91.908 E.0087
G2 X163.94 Y101.839 I-.006 J5.147 E.48184
M204 S250
G1 X163.874 Y102.226 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X164.129 Y102.324 E.00855
G2 X166.118 Y91.523 I1.705 J-5.27 E.59104
G1 X165.84 Y91.515 E.0087
G2 X163.587 Y102.117 I-.007 J5.539 E.47324
G1 X163.818 Y102.205 E.00775
; OBJECT_ID: 15
; WIPE_START
M204 S3000
G1 X164.129 Y102.324 E-.06322
G1 X164.689 Y102.474 E-.11018
G1 X165.261 Y102.565 E-.11014
G1 X165.551 Y102.587 E-.05515
G1 X165.768 Y102.587 E-.04131
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X158.984 Y106.084 Z7.2 F36000
G1 X47.368 Y163.607 Z7.2
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X47.628 Y163.591 E.0088
G2 X47.373 Y154.321 I-.492 J-4.625 E.46988
G1 X47.142 Y154.315 E.00784
G2 X47.142 Y163.617 I-.006 J4.651 E.49501
G1 X47.308 Y163.61 E.00564
M204 S10000
G1 X47.389 Y164.013 F36000
G1 F1473.913
M204 S3000
G1 X47.67 Y163.996 E.00952
G2 X47.394 Y153.914 I-.535 J-5.03 E.51101
G1 X47.142 Y153.908 E.00855
G2 X47.142 Y164.024 I-.006 J5.058 E.53832
G1 X47.329 Y164.016 E.00636
M204 S250
G1 X47.411 Y164.411 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00051
G2 X47.414 Y153.522 I-.291 J-5.443 E.519
G1 X47.142 Y153.515 E.00856
G2 X46.857 Y164.409 I-.006 J5.451 E.52835
G1 X47.351 Y164.411 E.01549
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.01445
G1 X47.995 Y164.351 E-.10846
G1 X48.552 Y164.233 E-.10837
G1 X49.095 Y164.056 E-.10843
G1 X49.289 Y163.97 E-.04029
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X49.302 Y162.895 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.43431
G1 F1532.998
M204 S3000
G1 X50.394 Y161.803 E.05027
G2 X51.194 Y160.449 I-3.397 J-2.921 E.05144
G1 X48.624 Y163.02 E.1183
G3 X47.869 Y163.221 I-1.335 J-3.489 E.02548
G1 X51.396 Y159.694 E.16232
G2 X51.454 Y159.082 I-5.607 J-.843 E.02001
G1 X47.257 Y163.279 E.19316
G3 X46.724 Y163.259 I-.171 J-2.55 E.0174
G1 X51.434 Y158.549 E.21678
G2 X51.36 Y158.07 I-2.317 J.113 E.01581
G1 X46.245 Y163.185 E.23543
G3 X45.808 Y163.068 I.338 J-2.135 E.01473
G1 X51.243 Y157.633 E.25013
G2 X51.09 Y157.233 I-1.983 J.526 E.01398
G1 X45.407 Y162.915 E.26155
G3 X45.037 Y162.732 I.687 J-1.849 E.01346
G1 X50.906 Y156.863 E.27012
G2 X50.695 Y156.521 I-1.731 J.834 E.01311
G1 X44.695 Y162.52 E.27612
G3 X44.378 Y162.284 I1.342 J-2.136 E.01289
G1 X50.459 Y156.203 E.27987
G2 X50.191 Y155.918 I-1.949 J1.559 E.01276
G1 X44.092 Y162.016 E.28069
G3 X43.828 Y161.727 I1.242 J-1.402 E.01277
G1 X49.902 Y155.653 E.27956
G2 X49.588 Y155.414 I-1.299 J1.377 E.01288
G1 X43.586 Y161.416 E.27624
G3 X43.377 Y161.071 I2.08 J-1.498 E.01313
G1 X49.248 Y155.2 E.27021
G2 X48.88 Y155.015 I-1.065 J1.658 E.01344
G1 X43.193 Y160.701 E.26172
G3 X43.041 Y160.3 I1.828 J-.926 E.01398
G1 X48.48 Y154.861 E.25034
G2 X48.044 Y154.744 I-.778 J2.025 E.01473
G1 X42.923 Y159.864 E.23565
G3 X42.849 Y159.385 I2.244 J-.593 E.01581
G1 X47.564 Y154.67 E.217
G2 X47.026 Y154.654 I-.369 J3.479 E.01754
G1 X42.829 Y158.851 E.19317
G3 X42.887 Y158.24 I5.668 J.231 E.02001
G1 X46.414 Y154.713 E.16232
G2 X45.659 Y154.914 I.58 J3.69 E.02548
G1 X43.089 Y157.485 E.11831
G3 X43.889 Y156.131 I3.969 J1.433 E.05148
G1 X44.981 Y155.039 E.05027
; OBJECT_ID: 14
; WIPE_START
G1 X43.889 Y156.131 E-.29348
G1 X43.648 Y156.429 E-.07282
G1 X43.609 Y156.489 E-.0137
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X35.985 Y156.131 Z7.2 F36000
G1 X26.585 Y155.689 Z7.2
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X26.494 Y155.664 E.00318
G2 X25.785 Y155.59 I-.705 J3.335 E.02417
G1 X25.613 Y155.595 E.00583
G2 X26.839 Y155.756 I.176 J3.404 E.68289
G1 X26.643 Y155.705 E.00689
M204 S10000
G1 X26.479 Y156.082 F36000
G1 F1473.913
M204 S3000
G1 X26.41 Y156.063 E.00245
G2 X25.785 Y155.998 I-.621 J2.937 E.02129
G1 X25.634 Y156.002 E.00512
G2 X26.713 Y156.144 I.155 J2.998 E.60135
G1 X26.537 Y156.097 E.00616
M204 S250
G1 X26.378 Y156.46 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.446 E.00163
G2 X25.785 Y156.39 I-.54 J2.553 E.01714
G1 X25.654 Y156.393 E.00411
G2 X26.592 Y156.517 I.134 J2.606 E.48428
G1 X26.436 Y156.476 E.00506
; WIPE_START
M204 S3000
G1 X26.328 Y156.446 E-.02126
G1 X26.058 Y156.404 E-.05191
G1 X25.785 Y156.39 E-.05191
G1 X25.654 Y156.393 E-.0249
G1 X25.377 Y156.422 E-.053
G1 X25.11 Y156.479 E-.05188
G1 X24.719 Y156.618 E-.07886
G1 X24.502 Y156.729 E-.04627
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.014 Y154.321 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Inner wall
; LINE_WIDTH: 0.45
G1 F1473.913
M204 S3000
G1 X25.785 Y154.315 E.00775
G2 X26.074 Y154.324 I-.006 J4.684 E.98649
M204 S10000
G1 X26.025 Y153.914 F36000
G1 F1473.913
M204 S3000
G1 X25.785 Y153.908 E.00811
G2 X26.085 Y153.917 I-.006 J5.092 E1.07272
M204 S250
G1 X26.035 Y153.522 F36000
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X25.785 Y153.515 E.00783
G2 X26.095 Y153.524 I-.007 J5.484 E1.07059
; WIPE_START
M204 S3000
G1 X25.785 Y153.515 E-.05885
G1 X25.212 Y153.545 E-.10909
G1 X24.645 Y153.635 E-.10906
G1 X24.121 Y153.775 E-.103
; WIPE_END
G1 E-.02 F1800
M204 S10000
M73 P97 R1
G1 X29.12 Y156.368 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; FEATURE: Internal solid infill
; LINE_WIDTH: 0.478221
G1 F1378.359
M204 S3000
G1 X28.935 Y156.133 E.01081
G1 X28.307 Y155.568 E.03058
G1 X27.538 Y155.12 E.03221
G1 X26.688 Y154.838 E.03241
G1 X26.011 Y154.748 E.02472
G1 X25.502 Y154.751 E.01845
G1 X24.746 Y154.871 E.02769
G2 X23.829 Y155.217 I2.182 J7.167 E.03551
G1 X23.332 Y155.518 E.02103
G1 X22.667 Y156.101 E.03201
G1 X22.226 Y156.661 E.0258
G1 X21.831 Y157.419 E.03092
G1 X21.591 Y158.268 E.03193
G1 X21.53 Y159.156 E.03222
G1 X21.656 Y160.037 E.03221
G1 X21.884 Y160.709 E.0257
G1 X22.327 Y161.484 E.03231
G1 X22.892 Y162.125 E.03092
G1 X23.598 Y162.653 E.03191
G1 X24.236 Y162.967 E.02576
G1 X25.097 Y163.202 E.03227
G1 X25.949 Y163.256 E.03093
G1 X26.822 Y163.13 E.0319
G1 X27.496 Y162.9 E.02578
G1 X28.269 Y162.458 E.03223
G1 X28.91 Y161.893 E.03093
G1 X29.438 Y161.187 E.03191
G1 X29.753 Y160.548 E.02581
G1 X29.982 Y159.725 E.03089
G2 X30.042 Y158.8 I-17.217 J-1.588 E.03357
G1 X29.915 Y157.963 E.03062
G1 X29.763 Y157.476 E.01848
G1 X29.486 Y156.892 E.02338
G1 X29.154 Y156.417 E.02099
; WIPE_START
G1 X29.486 Y156.892 E-.11019
G1 X29.763 Y157.476 E-.12272
G1 X29.915 Y157.963 E-.097
G1 X29.955 Y158.224 E-.05009
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X29.349 Y157.638 Z7.2 F36000
G1 Z6.8
G1 E.4 F1800
; LINE_WIDTH: 0.47255
G1 F1396.551
M204 S3000
G1 X29.489 Y158.031 E.0149
G1 X29.607 Y158.777 E.02698
G1 X29.569 Y159.579 E.0287
G1 X29.427 Y160.17 E.02172
G1 X29.112 Y160.895 E.02822
G1 X28.643 Y161.547 E.02869
G1 X28.208 Y161.96 E.02146
G1 X27.542 Y162.397 E.02845
G1 X26.798 Y162.692 E.02858
G1 X26.006 Y162.822 E.02869
G1 X25.405 Y162.806 E.02148
G1 X24.625 Y162.644 E.02844
G1 X23.89 Y162.327 E.02858
G1 X23.238 Y161.858 E.02869
G1 X22.825 Y161.422 E.02147
G1 X22.388 Y160.756 E.02845
G1 X22.093 Y160.013 E.02857
G1 X21.964 Y159.223 E.02859
G1 X22.001 Y158.424 E.02858
G1 X22.204 Y157.647 E.0287
G1 X22.463 Y157.104 E.02147
G1 X22.925 Y156.455 E.02846
G1 X23.517 Y155.916 E.02859
G3 X24.775 Y155.307 I2.494 J3.546 E.05015
G1 X25.569 Y155.178 E.02874
G1 X26.361 Y155.217 E.02835
G1 X27.135 Y155.422 E.02858
G1 X27.852 Y155.782 E.02865
G3 X28.746 Y156.577 I-2.123 J3.288 E.04294
G1 X29.103 Y157.107 E.02281
G1 X29.324 Y157.584 E.01877
; CHANGE_LAYER
; Z_HEIGHT: 7
; LAYER_HEIGHT: 0.2
; WIPE_START
G1 F1396.551
G1 X29.103 Y157.107 E-.09981
G1 X28.746 Y156.577 E-.12132
G1 X28.332 Y156.147 E-.11352
G1 X28.142 Y156.002 E-.04535
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 14
M625
;======== P2S layer_change gcode ==========
;===== 2026/05/15 ====





; update layer progress
M73 L35
M991 S0 P34 ;notify layer change


M204 S10000
G17
G3 Z7.2 I1.217 J0 P1  F36000
; object ids of layer 35 start: 10,11,12,13,14,15
M624 +AEAAAAAAAA=
;======== P2S timelapes gcode ==========
;===== 2025/06/16 ====
; SKIPPABLE_START
; SKIPTYPE: timelapse
M622.1 S1 ; for prev firware, default turned on

M1002 judge_flag timelapse_record_flag
M622 J1
 ; timelapse without wipe tower
  M971 S11 C10 O0
  M1004 S5 P1  ; external shutter

M623
; SKIPPABLE_END

; object ids of this layer35 end: 10,11,12,13,14,15
M625
; OBJECT_ID: 13
; start printing object, unique label id: 13
M624 QAAAAAAAAAA=
G1 X229.307 Y94.296
G1 Z7
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X229.04 Y94.399 E.00896
G2 X230.203 Y94.151 I1.164 J2.612 E.52579
G1 X230.055 Y94.155 E.00464
G2 X229.364 Y94.278 I.149 J2.856 E.02208
; WIPE_START
M204 S3000
G1 X229.04 Y94.399 E-.06569
G1 X228.645 Y94.613 E-.08524
G1 X228.403 Y94.789 E-.0569
G1 X228.181 Y94.989 E-.05685
G1 X227.889 Y95.331 E-.08533
G1 X227.803 Y95.463 E-.02999
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.751 Y91.712 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X228.233 Y91.88 E.01707
G2 X230.487 Y91.523 I1.967 J5.131 E1.01054
G1 X230.203 Y91.515 E.00889
G2 X228.809 Y91.695 I-.002 J5.495 E.0442
; WIPE_START
M204 S3000
G1 X228.233 Y91.88 E-.11485
G1 X227.708 Y92.115 E-.10938
G1 X227.21 Y92.402 E-.10927
G1 X227.012 Y92.546 E-.04651
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X232.796 Y92.405 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X234.798 Y94.407 E.08877
G1 X234.931 Y94.541
G1 X235.354 Y95.497
G1 X235.221 Y95.364
G1 X231.84 Y91.983 E.1499
G1 X231.706 Y91.849
G1 X231.003 Y91.679
G1 X231.136 Y91.812
G1 X235.405 Y96.081 E.18927
G1 X235.538 Y96.214
G1 X235.613 Y96.823
G1 X235.48 Y96.689
G1 X230.524 Y91.734 E.21972
G1 X230.391 Y91.6
G1 X229.854 Y91.597
G1 X229.988 Y91.73
G1 X235.484 Y97.227 E.24374
G1 X235.618 Y97.361
G1 X235.573 Y97.849
G1 X235.44 Y97.715
G1 X229.499 Y91.775 E.2634
G1 X229.366 Y91.641
G1 X228.915 Y91.724
G1 X229.049 Y91.858
G1 X231.371 Y94.18 E.10296
G1 X231.504 Y94.313
G1 X230.768 Y94.11
G1 X230.634 Y93.976
G1 X228.628 Y91.97 E.08896
G1 X228.494 Y91.837
G1 X228.097 Y91.972
G1 X228.231 Y92.106
G1 X230.072 Y93.948 E.08167
G1 X230.206 Y94.082
G1 X229.731 Y94.14
G1 X229.597 Y94.006
G1 X227.866 Y92.275 E.07677
G1 X227.732 Y92.141
G1 X227.383 Y92.325
G1 X227.517 Y92.459
G1 X229.181 Y94.123 E.07377
G1 X229.314 Y94.256
G1 X228.942 Y94.418
G1 X228.809 Y94.284
G1 X227.193 Y92.669 E.07161
G1 X227.06 Y92.535
G1 X226.756 Y92.765
G1 X226.89 Y92.899
G1 X228.473 Y94.482 E.07021
G1 X228.607 Y94.616
G1 X228.306 Y94.848
G1 X228.172 Y94.714
G1 X226.602 Y93.144 E.06963
G1 X226.468 Y93.01
G1 X226.202 Y93.277
G1 X226.335 Y93.41
G1 X227.906 Y94.981 E.06963
G1 X228.039 Y95.114
G1 X227.807 Y95.416
G1 X227.674 Y95.282
G1 X226.09 Y93.699 E.07021
G1 X225.957 Y93.565
G1 X225.724 Y93.866
G1 X225.858 Y94
G1 X227.475 Y95.617 E.07172
G1 X227.609 Y95.751
G1 X227.448 Y96.123
G1 X227.314 Y95.989
G1 X225.654 Y94.329 E.07362
G1 X225.52 Y94.195
G1 X225.33 Y94.538
G1 X225.464 Y94.672
G1 X227.202 Y96.41 E.07708
G1 X227.336 Y96.544
G1 X227.273 Y97.015
G1 X227.14 Y96.881
G1 X225.299 Y95.041 E.0816
G1 X225.166 Y94.907
G1 X225.028 Y95.303
G1 X225.162 Y95.436
G1 X227.176 Y97.451 E.08931
G1 X227.31 Y97.584
G1 X227.503 Y98.311
G1 X227.369 Y98.177
G1 X225.049 Y95.857 E.10286
; WIPE_START
M204 S3000
G1 X226.463 Y97.271 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X233.038 Y95.847 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X235.357 Y98.166 E.10282
G1 X235.491 Y98.3
G1 X235.378 Y98.72
G1 X235.244 Y98.587
G1 X233.238 Y96.581 E.08896
G1 X233.105 Y96.447
G1 X233.133 Y97.009
G1 X233.267 Y97.142
G1 X235.107 Y98.982 E.0816
G1 X235.24 Y99.116
G1 X235.076 Y99.485
G1 X234.943 Y99.351
G1 X233.207 Y97.616 E.07697
G1 X233.073 Y97.482
G1 X232.958 Y97.901
G1 X233.092 Y98.034
G1 X234.756 Y99.698 E.07377
G1 X234.889 Y99.832
G1 X234.679 Y100.155
G1 X234.546 Y100.021
G1 X232.928 Y98.403 E.07174
G1 X232.794 Y98.27
G1 X232.599 Y98.608
G1 X232.733 Y98.741
G1 X234.316 Y100.325 E.07021
G1 X234.45 Y100.458
G1 X234.204 Y100.746
G1 X234.071 Y100.613
G1 X232.501 Y99.042 E.06963
G1 X232.367 Y98.909
G1 X232.1 Y99.175
G1 X232.234 Y99.309
G1 X233.804 Y100.879 E.06963
G1 X233.938 Y101.013
G1 X233.65 Y101.258
G1 X233.516 Y101.125
G1 X231.933 Y99.541 E.07021
G1 X231.799 Y99.408
G1 X231.464 Y99.606
G1 X231.598 Y99.739
G1 X233.213 Y101.354 E.07161
G1 X233.346 Y101.488
G1 X233.023 Y101.698
G1 X232.889 Y101.564
G1 X231.221 Y99.896 E.07398
G1 X231.087 Y99.762
G1 X230.673 Y99.882
G1 X230.807 Y100.015
G1 X232.54 Y101.748 E.07685
G1 X232.674 Y101.882
G1 X232.309 Y102.051
G1 X232.176 Y101.917
G1 X230.334 Y100.075 E.08168
G1 X230.2 Y99.941
G1 X229.638 Y99.913
G1 X229.772 Y100.047
G1 X231.778 Y102.053 E.08895
G1 X231.912 Y102.186
G1 X231.491 Y102.299
G1 X231.358 Y102.166
G1 X229.038 Y99.846 E.10286
; WIPE_START
M204 S3000
G1 X230.452 Y101.26 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X230.907 Y102.248 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X224.967 Y96.308 E.26339
G1 X224.833 Y96.174
G1 X224.788 Y96.663
G1 X224.922 Y96.796
G1 X230.418 Y102.293 E.24373
G1 X230.552 Y102.427
G1 X230.014 Y102.422
G1 X229.88 Y102.288
G1 X224.927 Y97.334 E.21965
G1 X224.793 Y97.201
G1 X224.865 Y97.806
G1 X224.998 Y97.939
G1 X229.276 Y102.217 E.18967
G1 X229.409 Y102.35
G1 X228.7 Y102.174
G1 X228.566 Y102.04
G1 X225.174 Y98.649 E.15038
G1 X225.041 Y98.515
G1 X225.463 Y99.471
G1 X225.597 Y99.604
G1 X227.61 Y101.618 E.08928
; WIPE_START
M204 S3000
G1 X226.196 Y100.204 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X231.122 Y94.374 Z7.4 F36000
G1 X232.734 Y92.467 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.198098
G1 F3866.548
M204 S3000
G1 X232.606 Y92.374 E.00204
; LINE_WIDTH: 0.157925
G1 F5217.184
G1 X232.479 Y92.281 E.00151
; LINE_WIDTH: 0.112203
G1 F8660.206
G2 X232.313 Y92.163 I-1.202 J1.52 E.00117
; WIPE_START
G1 X232.479 Y92.281 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X231.865 Y94.436 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.102465
G1 F10076.477
M204 S3000
G1 X231.748 Y94.341 E.00075
G1 X231.698 Y94.355 E.00025
; WIPE_START
G1 X231.748 Y94.341 E-.09618
G1 X231.865 Y94.436 E-.28382
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X233.1 Y95.785 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.1883
G1 F4127.13
M204 S3000
G1 X232.975 Y95.603 E.00267
; LINE_WIDTH: 0.162723
G1 F5008.225
G1 X232.971 Y95.598 E.00006
; LINE_WIDTH: 0.143352
G1 F5974.208
G1 X232.878 Y95.477 E.00127
; LINE_WIDTH: 0.106567
G1 F9426.977
G1 X232.786 Y95.356 E.00081
; WIPE_START
G1 X232.878 Y95.477 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X228.3 Y101.584 Z7.4 F36000
G1 X228.093 Y101.86 Z7.4
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.0928696
G1 F12012.187
M204 S3000
G1 X228.055 Y101.835 E.00019
; LINE_WIDTH: 0.117663
G1 F8027.599
G1 X227.928 Y101.742 E.00098
; LINE_WIDTH: 0.15787
G1 F5219.674
G1 X227.8 Y101.649 E.00151
; LINE_WIDTH: 0.198078
G1 F3867.044
G1 X227.672 Y101.556 E.00204
; WIPE_START
G1 X227.8 Y101.649 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X229.049 Y99.835 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.176153
G1 F4503.407
M204 S3000
G1 X228.905 Y99.861 E.00162
; LINE_WIDTH: 0.186559
G1 F4177.162
G1 X228.783 Y99.773 E.00179
; LINE_WIDTH: 0.139063
G1 F6240.726
G1 X228.659 Y99.682 E.00123
; LINE_WIDTH: 0.101696
G1 F10208.245
G1 X228.541 Y99.587 E.00074
; WIPE_START
G1 X228.659 Y99.682 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X227.628 Y98.674 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.105037
G1 F9659.231
M204 S3000
G1 X227.531 Y98.554 E.0008
G1 X227.545 Y98.504 E.00027
; OBJECT_ID: 12
; WIPE_START
G1 X227.531 Y98.554 E-.09635
G1 X227.628 Y98.674 E-.28365
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 13
M625
; start printing object, unique label id: 12
M624 IAAAAAAAAAA=
M204 S10000
G1 X219.998 Y98.843 Z7.4 F36000
G1 X211.143 Y99.039 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X211.294 Y98.853 E.00751
G2 X208.777 Y93.915 I-2.515 J-1.829 E.2145
G1 X208.617 Y93.919 E.00503
G2 X211.089 Y99.106 I.162 J3.105 E.38285
G1 X211.105 Y99.085 E.00082
; WIPE_START
M204 S3000
G1 X211.294 Y98.853 E-.05691
G1 X211.471 Y98.58 E-.06184
G1 X211.619 Y98.29 E-.06187
G1 X211.735 Y97.988 E-.06146
G1 X211.849 Y97.511 E-.09309
G1 X211.874 Y97.277 E-.04483
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X204.517 Y99.31 Z7.4 F36000
G1 X203.854 Y99.494 Z7.4
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X203.868 Y99.526 E.00111
G2 X209.062 Y91.523 I4.907 J-2.503 E.72344
G1 X208.777 Y91.515 E.00891
G2 X203.633 Y98.999 I-.002 J5.508 E.33472
G1 X203.83 Y99.439 E.0151
; WIPE_START
M204 S3000
G1 X203.868 Y99.526 E-.01812
G1 X204.157 Y100.025 E-.10957
G1 X204.496 Y100.492 E-.10951
G1 X204.882 Y100.92 E-.10959
G1 X205.009 Y101.041 E-.03321
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X211.019 Y96.336 Z7.4 F36000
G1 X213.414 Y94.462 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X211.34 Y92.388 E.09195
G1 X211.206 Y92.255
G1 X210.262 Y91.843
G1 X210.396 Y91.977
G1 X213.816 Y95.397 E.15164
G1 X213.949 Y95.531
G1 X214.129 Y96.244
G1 X213.996 Y96.111
G1 X209.695 Y91.81 E.19071
G1 X209.561 Y91.676
G1 X208.951 Y91.599
G1 X209.085 Y91.733
G1 X214.069 Y96.717 E.221
G1 X214.202 Y96.85
G1 X214.205 Y97.387
G1 X214.072 Y97.253
G1 X208.549 Y91.73 E.24489
G1 X208.415 Y91.597
G1 X207.928 Y91.643
G1 X208.062 Y91.776
G1 X210.438 Y94.152 E.10536
G1 X210.572 Y94.286
G1 X209.689 Y93.936
G1 X209.555 Y93.803
G1 X207.612 Y91.86 E.08615
G1 X207.478 Y91.726
G1 X207.058 Y91.839
G1 X207.192 Y91.973
G1 X208.93 Y93.711 E.07709
G1 X209.064 Y93.845
G1 X208.555 Y93.869
G1 X208.421 Y93.735
G1 X206.797 Y92.111 E.07202
G1 X206.663 Y91.977
G1 X206.294 Y92.142
G1 X206.428 Y92.275
G1 X207.965 Y93.812 E.06815
G1 X208.098 Y93.946
G1 X207.695 Y94.076
G1 X207.562 Y93.943
G1 X206.085 Y92.466 E.06548
G1 X205.951 Y92.332
G1 X205.622 Y92.536
G1 X205.756 Y92.67
G1 X207.197 Y94.111 E.0639
G1 X207.331 Y94.245
G1 X207.001 Y94.448
G1 X206.867 Y94.315
G1 X205.455 Y92.902 E.06262
G1 X205.321 Y92.769
G1 X205.033 Y93.014
G1 X205.167 Y93.148
G1 X206.569 Y94.55 E.06217
G1 X206.703 Y94.683
G1 X206.436 Y94.95
G1 X206.302 Y94.816
G1 X204.9 Y93.414 E.06217
G1 X204.767 Y93.281
G1 X204.522 Y93.569
G1 X204.655 Y93.702
G1 X206.067 Y95.114 E.06262
G1 X206.201 Y95.248
G1 X205.999 Y95.58
G1 X205.866 Y95.446
G1 X204.425 Y94.006 E.06387
G1 X204.292 Y93.872
G1 X204.082 Y94.195
G1 X204.215 Y94.329
G1 X205.693 Y95.807 E.06554
G1 X205.827 Y95.941
G1 X205.697 Y96.344
G1 X205.563 Y96.21
G1 X204.031 Y94.678 E.06794
G1 X203.898 Y94.544
G1 X203.732 Y94.912
G1 X203.866 Y95.046
G1 X205.484 Y96.664 E.07174
G1 X205.618 Y96.798
G1 X205.598 Y97.311
G1 X205.464 Y97.178
G1 X203.722 Y95.436 E.07725
G1 X203.589 Y95.302
G1 X203.476 Y95.722
G1 X203.609 Y95.856
G1 X205.556 Y97.802 E.08629
G1 X205.689 Y97.936
G1 X206.039 Y98.819
G1 X205.905 Y98.685
G1 X203.529 Y96.309 E.10537
; WIPE_START
M204 S3000
G1 X204.943 Y97.723 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X211.638 Y95.352 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X214.026 Y97.74 E.10589
G1 X214.159 Y97.874
G1 X214.076 Y98.324
G1 X213.942 Y98.19
G1 X211.999 Y96.247 E.08615
G1 X211.866 Y96.114
G1 X211.957 Y96.738
G1 X212.091 Y96.872
G1 X213.829 Y98.61 E.07709
G1 X213.963 Y98.744
G1 X213.825 Y99.139
G1 X213.691 Y99.005
G1 X212.071 Y97.385 E.07183
G1 X211.937 Y97.252
G1 X211.852 Y97.699
G1 X211.985 Y97.833
G1 X213.527 Y99.374 E.06835
G1 X213.66 Y99.508
G1 X213.47 Y99.851
G1 X213.336 Y99.717
G1 X211.86 Y98.24 E.06548
G1 X211.726 Y98.107
G1 X211.557 Y98.471
G1 X211.691 Y98.605
G1 X213.129 Y100.043 E.06376
G1 X213.262 Y100.176
G1 X213.038 Y100.485
G1 X212.904 Y100.352
G1 X211.488 Y98.935 E.06283
G1 X211.354 Y98.801
G1 X211.119 Y99.099
G1 X211.252 Y99.233
G1 X212.653 Y100.633 E.06208
G1 X212.786 Y100.767
G1 X212.523 Y101.037
G1 X212.39 Y100.903
G1 X210.986 Y99.5 E.06225
G1 X210.852 Y99.366
G1 X210.553 Y99.6
G1 X210.687 Y99.734
G1 X212.1 Y101.147 E.06265
G1 X212.233 Y101.28
G1 X211.93 Y101.51
G1 X211.796 Y101.377
G1 X210.356 Y99.937 E.06386
G1 X210.223 Y99.803
G1 X209.862 Y99.975
G1 X209.995 Y100.109
G1 X211.473 Y101.587 E.06552
G1 X211.607 Y101.72
G1 X211.258 Y101.905
G1 X211.124 Y101.771
G1 X209.592 Y100.239 E.06794
G1 X209.458 Y100.105
G1 X209.004 Y100.185
G1 X209.138 Y100.318
G1 X210.76 Y101.94 E.07192
G1 X210.894 Y102.074
G1 X210.497 Y102.21
G1 X210.363 Y102.076
G1 X208.624 Y100.338 E.07709
G1 X208.491 Y100.204
G1 X207.866 Y100.113
G1 X208 Y100.247
G1 X209.943 Y102.19 E.08616
G1 X210.077 Y102.323
G1 X209.627 Y102.407
G1 X209.493 Y102.273
G1 X207.105 Y99.885 E.1059
; WIPE_START
M204 S3000
G1 X208.519 Y101.299 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X209.006 Y102.319 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X203.483 Y96.796 E.24489
G1 X203.349 Y96.663
G1 X203.353 Y97.199
G1 X203.486 Y97.333
G1 X208.469 Y102.316 E.22095
G1 X208.603 Y102.449
G1 X207.997 Y102.377
G1 X207.863 Y102.243
G1 X203.556 Y97.936 E.19097
G1 X203.423 Y97.802
G1 X203.597 Y98.51
G1 X203.73 Y98.643
G1 X207.15 Y102.062 E.15161
G1 X207.283 Y102.196
G1 X206.348 Y101.794
G1 X206.215 Y101.661
G1 X204.141 Y99.588 E.09193
M204 S10000
G1 X204.203 Y99.526 F36000
; FEATURE: Gap infill
; LINE_WIDTH: 0.200184
G1 F3815.239
M204 S3000
G1 X204.103 Y99.389 E.00222
; LINE_WIDTH: 0.164167
G1 F4948.607
G1 X204.003 Y99.251 E.00171
; LINE_WIDTH: 0.128149
G1 F7039.902
G1 X203.903 Y99.114 E.0012
; WIPE_START
G1 X204.003 Y99.251 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X207.044 Y99.946 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.217187
G1 F3443.001
M204 S3000
G1 X206.928 Y99.856 E.00212
; LINE_WIDTH: 0.192958
G1 F3999.002
G1 X206.735 Y99.687 E.00321
; LINE_WIDTH: 0.151601
G1 F5520.773
G1 X206.291 Y99.267 E.00552
G1 X206.071 Y99.024 E.00296
; WIPE_START
G1 X206.291 Y99.267 E-.13271
G1 X206.735 Y99.687 E-.24729
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X211.699 Y95.291 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.217607
G1 F3434.729
M204 S3000
G1 X211.612 Y95.179 E.00206
; LINE_WIDTH: 0.19706
G1 F3892.578
G1 X211.499 Y95.047 E.00222
; LINE_WIDTH: 0.154514
G1 F5376.669
G1 X211.387 Y94.915 E.00161
G2 X210.776 Y94.318 I-8.339 J7.925 E.00793
; WIPE_START
G1 X211.023 Y94.541 E-.12278
G1 X211.387 Y94.915 E-.19311
G1 X211.499 Y95.047 E-.06411
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X213.654 Y94.939 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.127454
G1 F7097.733
M204 S3000
G1 X213.553 Y94.8 E.0012
; LINE_WIDTH: 0.163752
G1 F4965.584
G1 X213.453 Y94.662 E.00172
; LINE_WIDTH: 0.20005
G1 F3818.509
G1 X213.352 Y94.523 E.00224
; OBJECT_ID: 11
; WIPE_START
G1 X213.453 Y94.662 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 12
M625
; start printing object, unique label id: 11
M624 EAAAAAAAAAA=
M204 S10000
G1 X205.822 Y94.813 Z7.4 F36000
G1 X184.493 Y95.234 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X184.256 Y95.673 E.01565
G2 X187.324 Y93.679 I3.07 J1.365 E.5405
G1 X187.151 Y93.684 E.00544
G2 X184.525 Y95.183 I.175 J3.355 E.09834
; WIPE_START
M204 S3000
G1 X184.256 Y95.673 E-.10622
G1 X184.129 Y96.001 E-.06674
G1 X184.038 Y96.341 E-.06686
M73 P97 R0
G1 X183.983 Y96.688 E-.06678
G1 X183.964 Y97.039 E-.06686
G1 X183.966 Y97.074 E-.00654
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.575 Y91.522 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X187.324 Y91.515 E.00788
G2 X187.635 Y91.524 I-.002 J5.523 E1.07827
; WIPE_START
M204 S3000
G1 X187.324 Y91.515 E-.05913
G1 X186.747 Y91.546 E-.10986
G1 X186.46 Y91.583 E-.05494
G1 X185.895 Y91.704 E-.10985
G1 X185.663 Y91.779 E-.04622
; WIPE_END
M73 P98 R0
G1 E-.02 F1800
M204 S10000
G1 X191.994 Y94.51 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X189.854 Y92.37 E.09493
G1 X189.72 Y92.236
G1 X188.786 Y91.835
G1 X188.92 Y91.969
G1 X192.385 Y95.434 E.15365
G1 X192.518 Y95.568
G1 X192.695 Y96.277
G1 X192.561 Y96.144
G1 X188.219 Y91.802 E.19251
G1 X188.086 Y91.668
G1 X187.483 Y91.598
G1 X187.616 Y91.732
G1 X192.632 Y96.747 E.22239
G1 X192.765 Y96.881
G1 X192.767 Y97.416
G1 X192.633 Y97.282
G1 X187.081 Y91.73 E.24618
G1 X186.948 Y91.597
G1 X186.462 Y91.644
G1 X186.595 Y91.778
G1 X188.489 Y93.671 E.08397
G1 X188.623 Y93.805
G1 X187.924 Y93.639
G1 X187.79 Y93.506
G1 X186.146 Y91.862 E.07288
G1 X186.013 Y91.728
G1 X185.594 Y91.842
G1 X185.727 Y91.976
G1 X187.227 Y93.476 E.06652
G1 X187.361 Y93.61
G1 X186.879 Y93.661
G1 X186.746 Y93.528
G1 X185.333 Y92.115 E.06265
G1 X185.199 Y91.981
G1 X184.83 Y92.145
G1 X184.964 Y92.279
G1 X186.308 Y93.623 E.0596
G1 X186.441 Y93.757
G1 X186.049 Y93.897
G1 X185.915 Y93.764
G1 X184.621 Y92.47 E.05738
G1 X184.487 Y92.336
G1 X184.162 Y92.544
G1 X184.296 Y92.677
G1 X185.558 Y93.94 E.05599
G1 X185.692 Y94.074
G1 X185.367 Y94.282
G1 X185.234 Y94.149
G1 X183.987 Y92.902 E.05529
G1 X183.853 Y92.768
G1 X183.57 Y93.018
G1 X183.704 Y93.152
G1 X184.938 Y94.387 E.05475
G1 X185.072 Y94.52
G1 X184.805 Y94.787
G1 X184.672 Y94.653
G1 X183.437 Y93.419 E.05475
G1 X183.303 Y93.285
G1 X183.058 Y93.573
G1 X183.192 Y93.707
G1 X184.434 Y94.949 E.05507
G1 X184.567 Y95.082
G1 X184.359 Y95.407
G1 X184.225 Y95.274
G1 X182.962 Y94.01 E.05604
G1 X182.828 Y93.876
G1 X182.618 Y94.199
G1 X182.752 Y94.333
G1 X184.053 Y95.635 E.05772
G1 X184.187 Y95.768
G1 X184.042 Y96.157
G1 X183.908 Y96.023
G1 X182.567 Y94.682 E.05947
G1 X182.434 Y94.548
G1 X182.268 Y94.916
G1 X182.402 Y95.049
G1 X183.806 Y96.454 E.06229
G1 X183.94 Y96.588
G1 X183.895 Y97.076
G1 X183.761 Y96.943
G1 X182.256 Y95.437 E.06675
G1 X182.122 Y95.304
G1 X182.013 Y95.728
G1 X182.147 Y95.862
G1 X183.799 Y97.513 E.07324
G1 X183.933 Y97.647
G1 X184.088 Y98.336
G1 X183.954 Y98.202
G1 X182.063 Y96.31 E.08387
; WIPE_START
M204 S3000
G1 X183.477 Y97.725 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X190.692 Y95.874 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X192.586 Y97.768 E.08397
G1 X192.719 Y97.902
G1 X192.635 Y98.351
G1 X192.501 Y98.217
G1 X190.858 Y96.573 E.07288
G1 X190.724 Y96.44
G1 X190.753 Y97.002
G1 X190.887 Y97.136
G1 X192.387 Y98.636 E.06653
G1 X192.521 Y98.77
G1 X192.382 Y99.164
G1 X192.249 Y99.031
G1 X190.842 Y97.624 E.06237
G1 X190.709 Y97.491
G1 X190.607 Y97.922
G1 X190.74 Y98.056
G1 X192.085 Y99.4 E.05961
G1 X192.218 Y99.533
G1 X192.027 Y99.876
G1 X191.894 Y99.742
G1 X190.595 Y98.444 E.05758
G1 X190.462 Y98.31
G1 X190.289 Y98.671
G1 X190.423 Y98.805
G1 X191.689 Y100.071 E.05614
G1 X191.823 Y100.205
G1 X191.59 Y100.505
G1 X191.457 Y100.372
G1 X190.215 Y99.13 E.05507
G1 X190.081 Y98.996
G1 X189.843 Y99.291
G1 X189.977 Y99.425
G1 X191.211 Y100.66 E.05475
G1 X191.345 Y100.793
G1 X191.079 Y101.06
G1 X190.945 Y100.926
G1 X189.71 Y99.692 E.05475
G1 X189.576 Y99.558
G1 X189.281 Y99.796
G1 X189.415 Y99.93
G1 X190.657 Y101.172 E.05507
G1 X190.79 Y101.305
G1 X190.487 Y101.536
G1 X190.354 Y101.402
G1 X189.09 Y100.138 E.05604
G1 X188.956 Y100.004
G1 X188.599 Y100.18
G1 X188.733 Y100.314
G1 X190.03 Y101.612 E.05755
G1 X190.164 Y101.745
G1 X189.815 Y101.93
G1 X189.682 Y101.796
G1 X188.339 Y100.453 E.05955
G1 X188.205 Y100.32
G1 X187.776 Y100.424
G1 X187.909 Y100.557
G1 X189.314 Y101.962 E.06229
G1 X189.448 Y102.096
G1 X189.06 Y102.241
G1 X188.926 Y102.107
G1 X187.419 Y100.6 E.06684
G1 X187.285 Y100.466
G1 X186.725 Y100.439
G1 X186.858 Y100.573
G1 X188.502 Y102.216 E.07288
G1 X188.636 Y102.35
G1 X188.187 Y102.434
G1 X188.053 Y102.301
G1 X186.161 Y100.409 E.08387
; WIPE_START
M204 S3000
G1 X187.576 Y101.823 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X187.567 Y102.348 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X182.014 Y96.795 E.24622
G1 X181.881 Y96.662
G1 X181.89 Y97.204
G1 X182.024 Y97.338
G1 X187.032 Y102.347 E.22209
G1 X187.166 Y102.48
G1 X186.563 Y102.41
G1 X186.429 Y102.276
G1 X182.092 Y97.939 E.19231
G1 X181.958 Y97.806
G1 X182.123 Y98.503
G1 X182.256 Y98.637
G1 X185.719 Y102.1 E.15354
G1 X185.853 Y102.233
G1 X184.928 Y101.842
G1 X184.795 Y101.709
G1 X182.655 Y99.569 E.09488
; WIPE_START
M204 S3000
G1 X184.069 Y100.983 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X190.114 Y96.323 Z7.4 F36000
G1 X190.678 Y95.888 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.201073
G1 F3793.802
M204 S3000
G1 X190.709 Y95.735 E.00205
; LINE_WIDTH: 0.180977
G1 F4346.052
G1 X190.647 Y95.645 E.00126
; LINE_WIDTH: 0.143851
G1 F5944.679
G1 X190.585 Y95.555 E.00092
; LINE_WIDTH: 0.106725
G1 F9403.671
G1 X190.523 Y95.465 E.00058
; WIPE_START
G1 X190.585 Y95.555 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X192.215 Y94.972 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.109983
G1 F8946.843
M204 S3000
G1 X192.143 Y94.867 E.00071
; LINE_WIDTH: 0.153626
G1 F5419.771
G1 X192.071 Y94.762 E.00117
; LINE_WIDTH: 0.208295
G1 F3628.119
G2 X191.933 Y94.571 I-1.877 J1.213 E.00323
; WIPE_START
G1 X192.071 Y94.762 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X191.318 Y93.536 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.0913036
G1 F12400.998
M204 S3000
G2 X190.837 Y93.056 I-15.006 J14.538 E.00274
; WIPE_START
G1 X191.318 Y93.536 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X185.048 Y97.889 Z7.4 F36000
G1 X182.716 Y99.507 Z7.4
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.194677
G1 F3953.709
M204 S3000
G1 X182.57 Y99.306 E.00315
; LINE_WIDTH: 0.147634
G1 F5729.888
G1 X182.423 Y99.104 E.00217
; WIPE_START
G1 X182.57 Y99.306 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X183.811 Y101.022 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.0912506
G1 F12414.591
M204 S3000
G3 X183.341 Y100.552 I13.4 J-13.87 E.00267
; WIPE_START
G1 X183.811 Y101.022 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X186.094 Y100.477 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.119615
G1 F7823.196
M204 S3000
G3 X185.748 Y100.235 I4.488 J-6.775 E.00269
; OBJECT_ID: 10
; WIPE_START
G1 X186.094 Y100.477 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 11
M625
; start printing object, unique label id: 10
M624 CAAAAAAAAAA=
M204 S10000
G1 X178.743 Y98.421 Z7.4 F36000
G1 X163.643 Y94.196 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X163.426 Y94.373 E.00878
G2 X165.84 Y93.445 I2.416 J2.681 E.62812
G1 X165.654 Y93.45 E.00584
G2 X163.719 Y94.135 I.188 J3.605 E.06527
G1 X163.69 Y94.159 E.00118
; WIPE_START
M204 S3000
G1 X163.426 Y94.373 E-.0646
G1 X163.158 Y94.64 E-.07183
G1 X162.813 Y95.089 E-.10761
G1 X162.624 Y95.416 E-.07182
G1 X162.487 Y95.725 E-.06414
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X163.875 Y102.233 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X164.407 Y102.405 E.01753
G2 X166.126 Y91.523 I1.431 J-5.351 E.58194
G1 X165.84 Y91.515 E.00896
G2 X163.819 Y102.212 I-.002 J5.539 E.48086
; WIPE_START
M204 S3000
G1 X164.407 Y102.405 E-.11762
G1 X164.974 Y102.527 E-.11019
G1 X165.551 Y102.587 E-.1102
G1 X165.772 Y102.587 E-.042
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X169.687 Y96.036 Z7.4 F36000
G1 X170.56 Y94.575 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X168.333 Y92.349 E.09872
G1 X168.2 Y92.216
G1 X167.282 Y91.831
G1 X167.415 Y91.965
G1 X170.926 Y95.475 E.15566
G1 X171.06 Y95.609
G1 X171.232 Y96.314
G1 X171.098 Y96.181
G1 X166.721 Y91.803 E.1941
G1 X166.588 Y91.67
G1 X165.981 Y91.597
G1 X166.115 Y91.73
G1 X171.165 Y96.781 E.22396
; WIPE_START
M204 S3000
G1 X169.751 Y95.367 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X169.297 Y95.446 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X171.165 Y97.314 E.08283
G1 X171.299 Y97.448
G1 X171.25 Y97.932
G1 X171.117 Y97.799
G1 X169.567 Y96.249 E.06872
G1 X169.433 Y96.115
G1 X169.519 Y96.735
G1 X169.653 Y96.868
G1 X171.031 Y98.246 E.06111
G1 X171.165 Y98.38
G1 X171.05 Y98.798
G1 X170.916 Y98.665
G1 X169.639 Y97.388 E.05663
G1 X169.505 Y97.254
G1 X169.431 Y97.713
G1 X169.565 Y97.847
G1 X170.777 Y99.059 E.05376
G1 X170.911 Y99.193
G1 X170.746 Y99.562
G1 X170.613 Y99.428
G1 X169.457 Y98.272 E.05125
G1 X169.323 Y98.139
G1 X169.171 Y98.52
G1 X169.305 Y98.653
G1 X170.425 Y99.773 E.04965
G1 X170.558 Y99.907
G1 X170.348 Y100.23
G1 X170.215 Y100.096
G1 X169.121 Y99.003 E.04848
G1 X168.988 Y98.869
G1 X168.775 Y99.19
G1 X168.909 Y99.324
G1 X169.984 Y100.399 E.04768
G1 X170.118 Y100.533
G1 X169.873 Y100.821
G1 X169.739 Y100.687
G1 X168.67 Y99.618 E.04742
G1 X168.536 Y99.484
G1 X168.269 Y99.751
G1 X168.403 Y99.884
G1 X169.472 Y100.954 E.04742
G1 X169.606 Y101.087
G1 X169.323 Y101.338
G1 X169.189 Y101.204
G1 X168.109 Y100.124 E.0479
G1 X167.976 Y99.99
G1 X167.655 Y100.203
G1 X167.788 Y100.336
G1 X168.88 Y101.428 E.04843
G1 X169.014 Y101.562
G1 X168.689 Y101.77
G1 X168.555 Y101.636
G1 X167.439 Y100.52 E.04951
G1 X167.305 Y100.386
G1 X166.917 Y100.531
G1 X167.05 Y100.665
G1 X168.213 Y101.828 E.05157
G1 X168.347 Y101.961
G1 X167.978 Y102.125
G1 X167.844 Y101.992
G1 X166.636 Y100.784 E.05357
G1 X166.502 Y100.65
G1 X166.039 Y100.72
G1 X166.173 Y100.854
G1 X167.45 Y102.131 E.05664
G1 X167.584 Y102.265
G1 X167.165 Y102.379
G1 X167.032 Y102.246
G1 X165.654 Y100.868 E.06111
G1 X165.52 Y100.734
G1 X164.893 Y100.641
G1 X165.027 Y100.774
G1 X166.584 Y102.331 E.06904
G1 X166.717 Y102.465
G1 X166.233 Y102.514
G1 X166.099 Y102.38
G1 X164.236 Y100.516 E.08264
; WIPE_START
M204 S3000
G1 X165.65 Y101.931 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X167.275 Y94.473 Z7.4 F36000
G1 X167.463 Y93.612 Z7.4
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X165.582 Y91.73 E.08344
G1 X165.448 Y91.597
G1 X164.963 Y91.645
G1 X165.097 Y91.779
G1 X166.647 Y93.329 E.06872
G1 X166.78 Y93.463
G1 X166.161 Y93.376
G1 X166.027 Y93.243
G1 X164.649 Y91.865 E.06111
G1 X164.516 Y91.731
G1 X164.097 Y91.846
G1 X164.231 Y91.979
G1 X165.511 Y93.26 E.05677
G1 X165.645 Y93.393
G1 X165.174 Y93.456
G1 X165.041 Y93.322
G1 X163.837 Y92.119 E.05339
G1 X163.703 Y91.985
G1 X163.334 Y92.149
G1 X163.468 Y92.283
G1 X164.624 Y93.439 E.05125
G1 X164.757 Y93.572
G1 X164.376 Y93.724
G1 X164.242 Y93.591
G1 X163.126 Y92.474 E.04951
G1 X162.992 Y92.34
G1 X162.663 Y92.545
G1 X162.797 Y92.679
G1 X163.893 Y93.774 E.04858
G1 X164.026 Y93.908
G1 X163.705 Y94.12
G1 X163.572 Y93.987
G1 X162.496 Y92.911 E.04768
G1 X162.363 Y92.778
G1 X162.075 Y93.023
G1 X162.209 Y93.157
G1 X163.278 Y94.226 E.04742
G1 X163.412 Y94.36
G1 X163.145 Y94.626
G1 X163.011 Y94.493
G1 X161.942 Y93.423 E.04742
G1 X161.808 Y93.29
G1 X161.563 Y93.578
G1 X161.697 Y93.711
G1 X162.778 Y94.793 E.04797
G1 X162.912 Y94.927
G1 X162.695 Y95.243
G1 X162.562 Y95.109
G1 X161.466 Y94.014 E.04857
G1 X161.333 Y93.88
G1 X161.123 Y94.204
G1 X161.256 Y94.337
G1 X162.378 Y95.459 E.04973
G1 X162.511 Y95.593
G1 X162.36 Y95.974
G1 X162.226 Y95.841
G1 X161.068 Y94.682 E.05136
G1 X160.934 Y94.549
G1 X160.77 Y94.918
G1 X160.904 Y95.051
G1 X162.112 Y96.26 E.05357
G1 X162.246 Y96.393
G1 X162.176 Y96.856
G1 X162.042 Y96.723
G1 X160.765 Y95.446 E.05664
G1 X160.631 Y95.312
G1 X160.516 Y95.73
G1 X160.65 Y95.864
G1 X162.028 Y97.242 E.06111
G1 X162.162 Y97.376
G1 X162.248 Y97.995
G1 X162.114 Y97.862
G1 X160.564 Y96.312 E.06872
G1 X160.431 Y96.178
G1 X160.382 Y96.663
G1 X160.516 Y96.796
G1 X162.379 Y98.66 E.08263
; WIPE_START
M204 S3000
G1 X160.965 Y97.246 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X160.516 Y97.33 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X165.566 Y102.38 E.22395
G1 X165.7 Y102.514
G1 X165.1 Y102.447
G1 X164.966 Y102.313
G1 X160.583 Y97.93 E.19436
G1 X160.449 Y97.796
G1 X160.621 Y98.502
G1 X160.755 Y98.636
G1 X164.26 Y102.141 E.15542
G1 X164.394 Y102.274
G1 X163.489 Y101.903
G1 X163.355 Y101.769
G1 X161.127 Y99.541 E.09881
; WIPE_START
M204 S3000
G1 X162.541 Y100.955 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X162.481 Y101.192 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.102772
G1 F10024.824
M204 S3000
G3 X161.703 Y100.415 I9.73 J-10.508 E.00547
; WIPE_START
G1 X162.481 Y101.192 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X164.174 Y100.578 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.20031
G1 F3812.207
M204 S3000
G1 X164.046 Y100.484 E.00208
; LINE_WIDTH: 0.163921
G1 F4958.656
G1 X163.913 Y100.388 E.00165
; LINE_WIDTH: 0.130977
G1 F6813.787
G1 X163.798 Y100.295 E.00108
; LINE_WIDTH: 0.10244
G1 F10080.631
G1 X163.683 Y100.202 E.00073
; WIPE_START
G1 X163.798 Y100.295 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X162.694 Y99.212 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.102428
G1 F10082.817
M204 S3000
G1 X162.601 Y99.097 E.00073
; LINE_WIDTH: 0.13149
G1 F6774.335
G1 X162.504 Y98.978 E.00113
; LINE_WIDTH: 0.161001
G1 F5081.292
G1 X162.45 Y98.904 E.0009
; LINE_WIDTH: 0.202416
G1 F3761.87
G1 X162.318 Y98.721 E.00299
; WIPE_START
G1 X162.45 Y98.904 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X161.186 Y99.481 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.197771
G1 F3874.697
M204 S3000
G1 X161.097 Y99.351 E.00203
; LINE_WIDTH: 0.153927
G1 F5405.064
G1 X161.007 Y99.221 E.00146
; LINE_WIDTH: 0.110084
G1 F8933.466
G1 X160.918 Y99.091 E.00088
; WIPE_START
G1 X161.007 Y99.221 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X167.084 Y94.603 Z7.4 F36000
G1 X167.997 Y93.908 Z7.4
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.102549
G1 F10062.239
M204 S3000
G1 X167.882 Y93.815 E.00074
; LINE_WIDTH: 0.131975
G1 F6737.47
G1 X167.76 Y93.717 E.00115
; LINE_WIDTH: 0.164548
G1 F4933.095
G1 X167.643 Y93.634 E.00146
; LINE_WIDTH: 0.198542
G1 F3855.502
G1 X167.525 Y93.55 E.00187
; WIPE_START
G1 X167.643 Y93.634 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X169.932 Y93.651 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.103435
G1 F9914.973
M204 S3000
G2 X169.245 Y92.963 I-8.008 J7.321 E.00489
; WIPE_START
G1 X169.932 Y93.651 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X170.763 Y95.019 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.109688
G1 F8986.333
M204 S3000
G1 X170.675 Y94.891 E.00086
; LINE_WIDTH: 0.152742
G1 F5463.404
G1 X170.587 Y94.763 E.00142
; LINE_WIDTH: 0.195796
G1 F3924.77
G1 X170.499 Y94.636 E.00197
; WIPE_START
G1 X170.587 Y94.763 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X169.359 Y95.384 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.208449
G1 F3624.741
M204 S3000
G1 X169.292 Y95.287 E.00163
; LINE_WIDTH: 0.182895
G1 F4286.499
G1 X169.188 Y95.154 E.00196
; LINE_WIDTH: 0.145001
G1 F5877.681
G1 X169.083 Y95.022 E.00143
; LINE_WIDTH: 0.107108
G1 F9347.571
G1 X168.979 Y94.889 E.0009
; OBJECT_ID: 15
; WIPE_START
G1 X169.083 Y95.022 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 10
M625
; start printing object, unique label id: 15
M624 AAEAAAAAAAA=
M204 S10000
G1 X162.453 Y98.803 Z7.4 F36000
G1 X47.415 Y164.411 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X47.427 Y164.409 E.00037
G2 X47.423 Y153.523 I-.287 J-5.443 E.519
G1 X47.142 Y153.515 E.00882
G2 X46.857 Y164.409 I-.002 J5.451 E.5281
G1 X47.355 Y164.411 E.01562
; WIPE_START
M204 S3000
G1 X47.427 Y164.409 E-.01364
G1 X47.994 Y164.351 E-.10844
G1 X48.553 Y164.233 E-.10841
G1 X48.826 Y164.152 E-.05422
G1 X49.294 Y163.972 E-.09528
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X48.961 Y156.347 Z7.4 F36000
G1 X48.859 Y154.019 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X52.09 Y157.249 E.14325
G1 X52.224 Y157.383
G1 X52.419 Y158.112
G1 X52.285 Y157.978
G1 X48.131 Y153.823 E.18422
G1 X47.997 Y153.69
G1 X47.381 Y153.607
G1 X47.515 Y153.741
G1 X52.368 Y158.594 E.2152
G1 X52.502 Y158.728
G1 X52.512 Y159.271
G1 X52.378 Y159.138
G1 X46.971 Y153.73 E.23978
G1 X46.837 Y153.597
G1 X46.345 Y153.637
G1 X46.478 Y153.771
G1 X52.337 Y159.63 E.2598
G1 X52.471 Y159.764
G1 X52.392 Y160.217
G1 X52.258 Y160.084
G1 X46.025 Y153.851 E.27639
G1 X45.891 Y153.717
G1 X45.468 Y153.827
G1 X45.602 Y153.961
G1 X52.148 Y160.507 E.29024
G1 X52.281 Y160.64
G1 X52.145 Y161.038
G1 X52.011 Y160.904
G1 X45.205 Y154.097 E.30183
G1 X45.071 Y153.963
G1 X44.702 Y154.128
G1 X44.836 Y154.261
G1 X51.847 Y161.273 E.3109
G1 X51.981 Y161.407
G1 X51.792 Y161.751
G1 X51.658 Y161.617
G1 X44.491 Y154.45 E.31779
G1 X44.358 Y154.317
G1 X44.028 Y154.52
G1 X44.162 Y154.654
G1 X51.452 Y161.944 E.32325
G1 X51.585 Y162.078
G1 X51.361 Y162.386
G1 X51.227 Y162.253
G1 X43.86 Y154.886 E.32667
G1 X43.727 Y154.752
G1 X43.438 Y154.997
G1 X43.572 Y155.131
G1 X50.978 Y162.537 E.32839
G1 X51.111 Y162.67
G1 X50.845 Y162.937
G1 X50.711 Y162.803
G1 X43.305 Y155.397 E.32839
G1 X43.172 Y155.264
G1 X42.922 Y155.547
G1 X43.056 Y155.681
G1 X50.423 Y163.048 E.32667
G1 X50.557 Y163.182
G1 X50.253 Y163.411
G1 X50.119 Y163.277
G1 X42.832 Y155.99 E.32314
G1 X42.698 Y155.856
G1 X42.491 Y156.183
G1 X42.625 Y156.317
G1 X49.796 Y163.487 E.31796
G1 X49.929 Y163.621
M73 P99 R0
G1 X49.579 Y163.804
G1 X49.445 Y163.67
G1 X42.436 Y156.661 E.31081
G1 X42.302 Y156.527
G1 X42.138 Y156.896
G1 X42.272 Y157.03
G1 X49.076 Y163.834 E.30169
G1 X49.209 Y163.967
G1 X48.819 Y164.111
G1 X48.686 Y163.977
G1 X42.136 Y157.427 E.29043
G1 X42.002 Y157.294
G1 X41.892 Y157.716
G1 X42.025 Y157.85
G1 X48.258 Y164.083 E.27639
G1 X48.392 Y164.217
G1 X47.938 Y164.296
G1 X47.805 Y164.163
G1 X41.946 Y158.304 E.25979
G1 X41.812 Y158.17
G1 X41.771 Y158.663
G1 X41.905 Y158.796
G1 X47.312 Y164.204 E.23977
G1 X47.446 Y164.337
G1 X46.902 Y164.327
G1 X46.769 Y164.193
G1 X41.915 Y159.34 E.21521
G1 X41.782 Y159.206
G1 X41.865 Y159.823
G1 X41.998 Y159.956
G1 X46.153 Y164.11 E.1842
G1 X46.286 Y164.244
G1 X45.558 Y164.049
G1 X45.424 Y163.915
G1 X42.194 Y160.685 E.14324
; WIPE_START
M204 S3000
G1 X43.608 Y162.099 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X50.022 Y157.962 Z7.4 F36000
G1 X51.89 Y156.757 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.103577
G1 F9891.704
M204 S3000
G1 X51.836 Y156.678 E.00048
; LINE_WIDTH: 0.134382
G1 F6560.161
G1 X51.782 Y156.599 E.00073
; LINE_WIDTH: 0.169229
G1 F4750.253
G1 X51.7 Y156.49 E.00143
; LINE_WIDTH: 0.208133
G1 F3631.682
G1 X51.619 Y156.381 E.00187
; LINE_WIDTH: 0.246413
G1 F2948.505
G1 X51.506 Y156.241 E.00305
; LINE_WIDTH: 0.284067
G1 F2488.114
G1 X51.392 Y156.101 E.00361
; LINE_WIDTH: 0.32172
G1 F2152.08
G1 X51.279 Y155.961 E.00418
; LINE_WIDTH: 0.354529
G1 F1925.494
G1 X51.1 Y155.762 E.00693
; LINE_WIDTH: 0.391813
G1 F1719.728
G2 X50.545 Y155.187 I-5.762 J5.008 E.0232
; LINE_WIDTH: 0.38249
G1 F1766.941
G1 X50.346 Y155.009 E.00755
; LINE_WIDTH: 0.354511
G1 F1925.601
G1 X50.147 Y154.83 E.00692
; LINE_WIDTH: 0.321677
G1 F2152.415
G1 X50.007 Y154.716 E.00418
; LINE_WIDTH: 0.283968
G1 F2489.134
G1 X49.867 Y154.603 E.00361
; LINE_WIDTH: 0.246259
G1 F2950.739
G1 X49.727 Y154.489 E.00305
; LINE_WIDTH: 0.204199
G1 F3720.259
G1 X49.601 Y154.398 E.00209
; LINE_WIDTH: 0.157786
G1 F5223.509
G1 X49.475 Y154.306 E.00149
; LINE_WIDTH: 0.111372
G1 F8765.325
G1 X49.348 Y154.214 E.00089
; WIPE_START
G1 X49.475 Y154.306 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X46.159 Y161.181 Z7.4 F36000
G1 X44.935 Y163.719 Z7.4
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.111364
G1 F8766.352
M204 S3000
G1 X44.809 Y163.628 E.00089
; LINE_WIDTH: 0.157758
G1 F5224.79
G1 X44.682 Y163.536 E.00149
; LINE_WIDTH: 0.204151
G1 F3721.374
G1 X44.556 Y163.445 E.00209
; LINE_WIDTH: 0.246184
G1 F2951.828
G1 X44.416 Y163.331 E.00305
; LINE_WIDTH: 0.283888
G1 F2489.965
G1 X44.276 Y163.218 E.00361
; LINE_WIDTH: 0.321591
G1 F2153.08
G1 X44.136 Y163.104 E.00418
; LINE_WIDTH: 0.354427
G1 F1926.126
G1 X43.937 Y162.925 E.00693
; LINE_WIDTH: 0.391724
G1 F1720.166
G3 X43.362 Y162.37 I5.009 J-5.763 E.02319
; LINE_WIDTH: 0.382293
G1 F1767.966
G1 X43.182 Y162.17 E.00761
; LINE_WIDTH: 0.354072
G1 F1928.318
G1 X43.001 Y161.969 E.00697
; LINE_WIDTH: 0.316078
G1 F2196.535
G1 X42.835 Y161.769 E.00593
; LINE_WIDTH: 0.268258
G1 F2662.674
G1 X42.723 Y161.623 E.00344
; LINE_WIDTH: 0.220385
G1 F3380.952
G1 X42.611 Y161.478 E.00271
; LINE_WIDTH: 0.172513
G1 F4629.908
G1 X42.5 Y161.332 E.00198
; LINE_WIDTH: 0.133476
G1 F6625.773
G1 X42.446 Y161.255 E.00071
; LINE_WIDTH: 0.103266
G1 F9942.727
G1 X42.393 Y161.177 E.00047
; OBJECT_ID: 14
; WIPE_START
G1 X42.446 Y161.255 E-.38
; WIPE_END
G1 E-.02 F1800
; stop printing object, unique label id: 15
M625
; start printing object, unique label id: 14
M624 gAAAAAAAAAA=
M204 S10000
G1 X35.132 Y159.072 Z7.4 F36000
G1 X26.374 Y156.459 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Outer wall
; LINE_WIDTH: 0.42
G1 F1500
M204 S1000
G1 X26.328 Y156.447 E.00149
G2 X25.785 Y156.39 I-.542 J2.553 E.01713
G1 X25.65 Y156.393 E.00423
G2 X26.592 Y156.517 I.136 J2.606 E.48416
G1 X26.432 Y156.475 E.0052
; WIPE_START
M204 S3000
G1 X26.328 Y156.447 E-.02044
G1 X26.058 Y156.404 E-.05184
G1 X25.785 Y156.39 E-.05192
G1 X25.65 Y156.393 E-.02566
G1 X25.241 Y156.447 E-.07843
G1 X24.979 Y156.518 E-.05155
G1 X24.722 Y156.616 E-.05232
G1 X24.498 Y156.731 E-.04785
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.038 Y153.522 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S1000
G1 X25.785 Y153.515 E.00794
G2 X26.098 Y153.524 I-.002 J5.484 E1.07049
; WIPE_START
M204 S3000
G1 X25.785 Y153.515 E-.0595
G1 X25.498 Y153.523 E-.05453
G1 X24.927 Y153.583 E-.10911
G1 X24.366 Y153.702 E-.10908
G1 X24.127 Y153.78 E-.04779
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X30.365 Y156.381 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; FEATURE: Top surface
G1 F1500
M204 S2000
G1 X28.404 Y154.42 E.08695
G1 X28.271 Y154.286
G1 X27.309 Y153.858
G1 X27.442 Y153.991
G1 X30.794 Y157.343 E.14861
G1 X30.928 Y157.477
G1 X31.105 Y158.188
G1 X30.972 Y158.054
G1 X26.731 Y153.814 E.18803
G1 X26.598 Y153.68
G1 X25.988 Y153.603
G1 X26.121 Y153.737
G1 X31.049 Y158.664 E.2185
G1 X31.182 Y158.798
G1 X31.189 Y159.338
G1 X31.055 Y159.204
G1 X25.581 Y153.73 E.24271
G1 X25.448 Y153.597
G1 X24.958 Y153.64
G1 X25.092 Y153.774
G1 X31.011 Y159.693 E.26247
G1 X31.145 Y159.827
G1 X31.067 Y160.282
G1 X30.933 Y160.149
G1 X24.641 Y153.856 E.27903
G1 X24.507 Y153.722
G1 X24.086 Y153.834
G1 X24.219 Y153.968
G1 X26.537 Y156.286 E.10277
G1 X26.671 Y156.419
G1 X26.038 Y156.32
G1 X25.904 Y156.186
G1 X23.823 Y154.105 E.09228
G1 X23.69 Y153.971
G1 X23.321 Y154.136
G1 X23.454 Y154.269
G1 X25.402 Y156.217 E.08636
G1 X25.536 Y156.351
G1 X25.093 Y156.442
G1 X24.96 Y156.308
G1 X23.111 Y154.459 E.08198
G1 X22.977 Y154.325
G1 X22.651 Y154.533
G1 X22.785 Y154.666
G1 X24.576 Y156.458 E.07944
G1 X24.71 Y156.592
G1 X24.37 Y156.785
G1 X24.236 Y156.651
G1 X22.476 Y154.891 E.07805
G1 X22.342 Y154.757
G1 X22.059 Y155.007
G1 X22.192 Y155.14
G1 X23.932 Y156.88 E.07714
G1 X24.066 Y157.014
G1 X23.799 Y157.28
G1 X23.665 Y157.147
G1 X21.926 Y155.407 E.07714
G1 X21.792 Y155.273
G1 X21.547 Y155.562
G1 X21.681 Y155.695
G1 X23.436 Y157.451 E.07785
G1 X23.57 Y157.584
G1 X23.377 Y157.925
G1 X23.243 Y157.791
G1 X21.448 Y155.996 E.07958
G1 X21.315 Y155.863
G1 X21.111 Y156.192
G1 X21.244 Y156.326
G1 X23.094 Y158.175 E.08203
G1 X23.228 Y158.309
G1 X23.13 Y158.745
G1 X22.997 Y158.611
G1 X21.055 Y156.669 E.08612
G1 X20.921 Y156.535
G1 X20.757 Y156.904
G1 X20.89 Y157.038
G1 X22.971 Y159.119 E.09228
G1 X23.105 Y159.253
G1 X23.205 Y159.886
G1 X23.071 Y159.752
G1 X20.753 Y157.434 E.10279
; WIPE_START
M204 S3000
G1 X22.167 Y158.848 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.5 Y158.248 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X30.821 Y160.569 E.10291
G1 X30.954 Y160.703
G1 X30.811 Y161.093
G1 X30.678 Y160.96
G1 X28.599 Y158.881 E.09217
G1 X28.466 Y158.747
G1 X28.44 Y159.255
G1 X28.574 Y159.389
G1 X30.513 Y161.328 E.086
G1 X30.647 Y161.462
G1 X30.463 Y161.812
G1 X30.33 Y161.678
G1 X28.476 Y159.825 E.08218
G1 X28.343 Y159.691
G1 X28.194 Y160.075
G1 X28.327 Y160.209
G1 X30.12 Y162.001 E.07947
G1 X30.253 Y162.135
G1 X30.024 Y162.438
G1 X29.89 Y162.305
G1 X28.134 Y160.549 E.07785
G1 X28.001 Y160.416
G1 X27.772 Y160.72
G1 X27.905 Y160.853
G1 X29.645 Y162.593 E.07714
G1 X29.779 Y162.727
G1 X29.512 Y162.993
G1 X29.378 Y162.86
G1 X27.639 Y161.12 E.07714
G1 X27.505 Y160.986
G1 X27.201 Y161.215
G1 X27.334 Y161.349
G1 X29.09 Y163.105 E.07785
G1 X29.224 Y163.238
G1 X28.92 Y163.468
G1 X28.787 Y163.334
G1 X26.994 Y161.542 E.07947
G1 X26.861 Y161.408
G1 X26.474 Y161.555
G1 X26.608 Y161.689
G1 X28.463 Y163.544 E.08227
G1 X28.597 Y163.678
G1 X28.247 Y163.862
G1 X28.114 Y163.728
G1 X26.174 Y161.789 E.086
G1 X26.04 Y161.655
G1 X25.533 Y161.68
G1 X25.666 Y161.814
G1 X27.749 Y163.897 E.09235
G1 X27.883 Y164.03
G1 X27.485 Y164.166
G1 X27.351 Y164.032
G1 X25.026 Y161.707 E.10311
; WIPE_START
M204 S3000
G1 X26.44 Y163.121 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X26.93 Y164.144 Z7.4 F36000
G1 Z7
G1 E.4 F1800
G1 F1500
M204 S2000
G1 X20.641 Y157.855 E.27886
G1 X20.507 Y157.722
G1 X20.426 Y158.173
G1 X20.559 Y158.307
G1 X26.478 Y164.226 E.26246
G1 X26.612 Y164.36
G1 X26.123 Y164.403
G1 X25.989 Y164.27
G1 X20.516 Y158.796 E.24271
G1 X20.382 Y158.663
G1 X20.388 Y159.202
G1 X20.522 Y159.336
G1 X25.45 Y164.263 E.2185
G1 X25.583 Y164.397
G1 X24.973 Y164.32
G1 X24.839 Y164.186
G1 X20.599 Y159.946 E.18802
G1 X20.465 Y159.812
G1 X20.643 Y160.523
G1 X20.777 Y160.657
G1 X24.119 Y164 E.14821
G1 X24.253 Y164.133
G1 X23.3 Y163.713
G1 X23.166 Y163.58
G1 X21.205 Y161.619 E.08694
; WIPE_START
M204 S3000
G1 X22.62 Y163.033 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.664 Y158.372 Z7.4 F36000
G1 X30.613 Y156.869 Z7.4
G1 Z7
G1 E.4 F1800
; FEATURE: Gap infill
; LINE_WIDTH: 0.107474
G1 F9294.547
M204 S3000
G1 X30.537 Y156.763 E.0007
; LINE_WIDTH: 0.1461
G1 F5815.109
G1 X30.46 Y156.657 E.00112
; LINE_WIDTH: 0.184725
G1 F4231.162
G1 X30.383 Y156.551 E.00154
; LINE_WIDTH: 0.211117
G1 F3567.244
G1 X30.304 Y156.442 E.00187
; WIPE_START
G1 X30.383 Y156.551 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X28.568 Y158.181 Z7.4 F36000
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.121679
G1 F7618.178
M204 S3000
G2 X28.362 Y157.87 I-6.011 J3.76 E.00244
; WIPE_START
G1 X28.568 Y158.181 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G1 X21.64 Y161.385 Z7.4 F36000
G1 X21.267 Y161.558 Z7.4
G1 Z7
G1 E.4 F1800
; LINE_WIDTH: 0.196512
G1 F3906.469
M204 S3000
G1 X21.164 Y161.416 E.00224
; LINE_WIDTH: 0.153172
G1 F5442.111
G1 X21.06 Y161.274 E.00161
; LINE_WIDTH: 0.109832
G1 F8967.102
G1 X20.957 Y161.131 E.00098
; close powerlost recovery
M1003 S0
; WIPE_START
G1 F8967.102
G1 X21.06 Y161.274 E-.38
; WIPE_END
G1 E-.02 F1800
M204 S10000
G17
G3 Z7.4 I1.217 J0 P1  F36000
; stop printing object, unique label id: 14
M625
M106 S0
M106 P2 S0
M981 S0 P20000 ; close spaghetti detector
; FEATURE: Custom
; MACHINE_END_GCODE_START
; filament end gcode 

;======== P2S end gcode ==========
;===== 2026/05/18 =====
M400 ; wait for buffer to clear
G92 E0 ; zero the extruder
M211 Z1

G90
G1 Z7.4 F900 ; lower z a little
M1002 judge_flag timelapse_record_flag
M622 J1
    G150.3
    M400 ; wait all motion done
    M991 S0 P-1 ;end smooth timelapse at safe pos
    M400 S5 ;wait for last picture to be taken
M623  ;end of "timelapse_record_flag

G90
G1 Z17 F900 ; lower z a little

M140 S0 ; turn off bed
M106 S0 ; turn off fan
M106 P2 S0 ; turn off remote part cooling fan
M106 P3 S0 ; turn off chamber cooling fan
M106 P10 S0 ; turn off left aux fan

; pull back filament to AMS
M620 S65535
T65535
G150.1 F8000
M621 S65535

G150.3
M104 S0 ; turn off hotend
M400 ; wait all motion done
M17 S
M17 Z0.4 ; lower z motor current to reduce impact if there is something in the bottom

    
        G1 Z83.5 F600
        G1 Z81.5
    

M400 P100
M17 R ; restore z current


M220 S100  ; Reset feedrate magnitude
M201.2 K1.0 ; Reset acc magnitude
M73.2 R1.0 ;Reset left time magnitude
M1002 set_gcode_claim_speed_level : 0

M1015.3 S0 ;disable clog detect
M1015.4 S0 K0 ;disable air printing detect

;=====printer finish air purification=========
M622.1 S0
M1002 judge_flag print_finish_air_filt_flag

M622 J1
M1002 gcode_claim_action : 66
M145 P1
M106 P2 S255
M400 S180
M106 P2 S0
M623

M622 J2
M1002 gcode_claim_action : 66
M145 P0
M106 P3 S255
M400 S180
M106 P3 S0
M623
;=====printer finish air purification=========

;=====printer finish  sound=========
M17
M400 S1
M1006 S1
M1006 A53 B10 L50 C53 D10 M50 E53 F10 N50 
M1006 A57 B10 L50 C57 D10 M50 E57 F10 N50 
M1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 
M1006 A53 B10 L50 C53 D10 M50 E53 F10 N50 
M1006 A57 B10 L50 C57 D10 M50 E57 F10 N50 
M1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 
M1006 A48 B10 L50 C48 D10 M50 E48 F10 N50 
M1006 A0 B15 L0 C0 D15 M0 E0 F15 N0 
M1006 A60 B10 L50 C60 D10 M50 E60 F10 N50 
M1006 W
;=====printer finish  sound=========
M400
M18
M73 P100 R0
; EXECUTABLE_BLOCK_END

