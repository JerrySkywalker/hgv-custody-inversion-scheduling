function design_scene = mb_vgeom_apply_scene_to_design(cfg, design_row, scene_row)
%MB_VGEOM_APPLY_SCENE_TO_DESIGN Build a Walker instance with scene offsets applied.

row = local_table_row_to_struct(design_row);
scene = local_table_row_to_struct(scene_row);

cfg_eval = cfg;
cfg_eval.stage03.h_km = row.h_km;
cfg_eval.stage03.i_deg = row.i_deg;
cfg_eval.stage03.P = row.P;
cfg_eval.stage03.T = row.T;
cfg_eval.stage03.F = row.F;

walker = build_single_layer_walker_stage03(cfg_eval);
phase_offset_deg = mod(double(scene.phase_offset_norm) * 360, 360);
raan_offset_deg = mod(double(scene.raan_offset_deg), 360);
for idx = 1:numel(walker.sat)
    walker.sat(idx).raan_deg = mod(walker.sat(idx).raan_deg + raan_offset_deg, 360);
    walker.sat(idx).M0_deg = mod(walker.sat(idx).M0_deg + phase_offset_deg, 360);
end

design_scene = struct();
design_scene.design_row = row;
design_scene.scene = scene;
design_scene.walker = walker;
design_scene.design_id = local_design_id(row);
design_scene.phase_offset_deg = phase_offset_deg;
end

function row = local_table_row_to_struct(value)
if istable(value)
    if height(value) ~= 1
        error('table input must contain exactly one row.');
    end
    row = table2struct(value);
else
    row = value;
end
end

function design_id = local_design_id(row)
design_id = sprintf('h%g_i%g_P%d_T%d_F%d', row.h_km, row.i_deg, row.P, row.T, row.F);
design_id = string(design_id);
end
