function trajs_in = build_heading_family(nominal_case, nominal_traj, heading_offsets_deg, engine_cfg)
%BUILD_HEADING_FAMILY Build a heading-perturbed target family from nominal inputs.
% Inputs:
%   nominal_case         : one case struct or struct array
%   nominal_traj         : one trajectory struct or struct array
%   heading_offsets_deg  : vector of heading offsets in degrees
%   engine_cfg           : engine configuration tree; defaults to default_params()
%
% Output:
%   trajs_in             : struct array with fields .case and .traj

if nargin < 4 || isempty(engine_cfg)
    engine_cfg = default_params();
end

trajs_nominal = local_pack_nominal_bank(nominal_case, nominal_traj);

heading_mode = 'engine';
if isfield(engine_cfg, 'stage06') && isfield(engine_cfg.stage06, 'active_heading_set_name')
    heading_mode = char(string(engine_cfg.stage06.active_heading_set_name));
end

family_out = legacy_build_heading_family_stage06_impl( ...
    trajs_nominal, ...
    heading_offsets_deg, ...
    'HeadingMode', heading_mode, ...
    'FamilyType', 'heading_extended', ...
    'Cfg', engine_cfg);

trajs_in = repmat(struct('case', [], 'traj', []), numel(family_out), 1);
for k = 1:numel(family_out)
    trajs_in(k).case = family_out(k).case;
    trajs_in(k).traj = family_out(k).traj;
end
end

function trajs_nominal = local_pack_nominal_bank(nominal_case, nominal_traj)
assert(isstruct(nominal_case) && isstruct(nominal_traj), ...
    'build_heading_family expects struct inputs for nominal_case and nominal_traj.');
assert(numel(nominal_case) == numel(nominal_traj), ...
    'build_heading_family requires nominal_case and nominal_traj to have the same length.');

trajs_nominal = repmat(struct('case', [], 'traj', [], 'validation', [], 'summary', []), ...
    numel(nominal_case), 1);

for k = 1:numel(nominal_case)
    trajs_nominal(k).case = nominal_case(k);
    trajs_nominal(k).traj = nominal_traj(k);
    trajs_nominal(k).validation = [];
    trajs_nominal(k).summary = [];
end
end
