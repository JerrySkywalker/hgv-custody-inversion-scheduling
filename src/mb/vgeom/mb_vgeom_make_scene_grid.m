function scene_table = mb_vgeom_make_scene_grid(design_row, cfg_vgeom, use_fine_bins)
%MB_VGEOM_MAKE_SCENE_GRID Build the normalized scene grid for one design.

if nargin < 2 || isempty(cfg_vgeom)
    cfg_vgeom = struct();
end
if nargin < 3
    use_fine_bins = false;
end

row = local_table_row_to_struct(design_row);
P = double(row.P);
if ~isfinite(P) || P <= 0
    error('mb_vgeom_make_scene_grid requires design_row.P > 0.');
end

raan_bins = round(local_getfield_or(cfg_vgeom, 'raan_bins', 6));
phase_bins = round(local_getfield_or(cfg_vgeom, 'phase_bins', 6));
if use_fine_bins && logical(local_getfield_or(cfg_vgeom, 'enable_fine_pass', false))
    raan_bins = round(local_getfield_or(cfg_vgeom, 'raan_bins_fine', raan_bins));
    phase_bins = round(local_getfield_or(cfg_vgeom, 'phase_bins_fine', phase_bins));
end
raan_bins = max(1, raan_bins);
phase_bins = max(1, phase_bins);

use_fundamental_domain = logical(local_getfield_or(cfg_vgeom, 'use_fundamental_domain', true));
if use_fundamental_domain
    raan_fundamental_deg = 360 / P;
else
    raan_fundamental_deg = 360;
end

raan_norm = (0:raan_bins-1) ./ raan_bins;
phase_norm = (0:phase_bins-1) ./ phase_bins;
[R, Phi] = ndgrid(raan_norm, phase_norm);
[Ridx, Pidx] = ndgrid(1:raan_bins, 1:phase_bins);
n = numel(R);

scene_id = strings(n, 1);
for idx = 1:n
    scene_id(idx) = sprintf('r%02d_p%02d', Ridx(idx), Pidx(idx));
end

scene_table = table();
scene_table.scene_id = scene_id;
scene_table.raan_bin_idx = Ridx(:);
scene_table.phase_bin_idx = Pidx(:);
scene_table.raan_offset_norm = R(:);
scene_table.phase_offset_norm = Phi(:);
scene_table.raan_offset_deg = R(:) * raan_fundamental_deg;
scene_table.num_planes = repmat(P, n, 1);
scene_table.raan_fundamental_deg = repmat(raan_fundamental_deg, n, 1);
scene_table.use_fundamental_domain = repmat(use_fundamental_domain, n, 1);
scene_table.raan_bins = repmat(raan_bins, n, 1);
scene_table.phase_bins = repmat(phase_bins, n, 1);
end

function row = local_table_row_to_struct(design_row)
if istable(design_row)
    if height(design_row) ~= 1
        error('design_row table input must contain exactly one row.');
    end
    row = table2struct(design_row);
else
    row = design_row;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
