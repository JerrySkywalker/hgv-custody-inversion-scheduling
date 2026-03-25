function walker = build_single_layer_walker(design_row, engine_cfg)
%BUILD_SINGLE_LAYER_WALKER Build a single-layer Walker constellation design.
% Inputs:
%   design_row : struct or table row with h_km, i_deg, P, T, F
%   engine_cfg : engine configuration tree; defaults to default_params()
%
% Output:
%   walker     : Walker constellation struct

if nargin < 2 || isempty(engine_cfg)
    engine_cfg = default_params();
end

row = local_normalize_design_row(design_row);
cfg_eval = engine_cfg;

if ~isfield(cfg_eval, 'stage03') || isempty(cfg_eval.stage03)
    cfg_eval.stage03 = struct();
end

cfg_eval.stage03.h_km = row.h_km;
cfg_eval.stage03.i_deg = row.i_deg;
cfg_eval.stage03.P = row.P;
cfg_eval.stage03.T = row.T;
cfg_eval.stage03.F = row.F;

walker = legacy_build_single_layer_walker_stage03_impl(cfg_eval);
end

function row = local_normalize_design_row(design_row)
if istable(design_row)
    assert(height(design_row) == 1, ...
        'build_single_layer_walker expects a single design-row table input.');
    row = table2struct(design_row);
else
    row = design_row;
end

required = {'h_km', 'i_deg', 'P', 'T', 'F'};
for k = 1:numel(required)
    name = required{k};
    if ~isfield(row, name)
        error('build_single_layer_walker:MissingField', ...
            'design_row is missing required field "%s".', name);
    end
end
end
