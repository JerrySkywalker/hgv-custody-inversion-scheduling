function family_out = legacy_build_heading_family_stage06_impl(trajs_nominal, heading_offsets_deg, varargin)
%LEGACY_BUILD_HEADING_FAMILY_STAGE06_IMPL Copied Stage06 heading-family builder.

arguments
    trajs_nominal struct
    heading_offsets_deg double
end

arguments (Repeating)
    varargin
end

heading_offsets_deg = heading_offsets_deg(:).';

p = inputParser;
addParameter(p, 'HeadingMode', 'small');
addParameter(p, 'FamilyType', 'heading_extended');
addParameter(p, 'Cfg', []);
parse(p, varargin{:});

heading_mode = string(p.Results.HeadingMode);
family_type = string(p.Results.FamilyType);
cfg = p.Results.Cfg;

if isempty(cfg)
    cfg = default_params();
end

n_nominal = numel(trajs_nominal);
n_heading = numel(heading_offsets_deg);
n_total = n_nominal * n_heading;

if n_nominal == 0
    family_out = struct('case', {}, 'traj', {}, 'validation', {}, 'summary', {});
    return;
end

family_out = repmat(local_empty_item(), n_total, 1);

idx = 0;
for iCase = 1:n_nominal
    base_item = trajs_nominal(iCase);

    for j = 1:n_heading
        idx = idx + 1;
        offset_deg = heading_offsets_deg(j);

        new_item = local_apply_heading_offset_and_repropagate( ...
            base_item, iCase, offset_deg, heading_mode, family_type, cfg);

        family_out(idx) = new_item;
    end
end
end

function out_item = local_apply_heading_offset_and_repropagate(base_item, entry_id, offset_deg, heading_mode, family_type, cfg)
assert(isfield(base_item, 'case') && ~isempty(base_item.case), ...
    'Stage06.2b requires base_item.case from Stage02 nominal trajbank.');

base_case = base_item.case;

if isfield(base_case, 'case_id')
    source_case_id = string(base_case.case_id);
else
    source_case_id = "unknown_case";
end

if isfield(base_case, 'heading_deg') && isfinite(base_case.heading_deg)
    nominal_heading_deg = base_case.heading_deg;
elseif isfield(base_item, 'traj') && isfield(base_item.traj, 'meta') && ...
       isfield(base_item.traj.meta, 'heading_deg')
    nominal_heading_deg = base_item.traj.meta.heading_deg;
else
    error('Cannot infer nominal heading_deg for case %s.', char(source_case_id));
end

perturbed_heading_deg = wrapTo180(nominal_heading_deg + offset_deg);
heading_label = local_heading_label(offset_deg);
new_case_id = sprintf('E%02d_%s', entry_id, char(heading_label));

new_case = base_case;

new_case.case_id = new_case_id;
new_case.family = char(family_type);
new_case.subfamily = sprintf('stage06_%s', char(heading_mode));

new_case.entry_id = entry_id;
new_case.entry_point_id = entry_id;
new_case.source_case_id = char(source_case_id);
new_case.family_origin = 'stage02_nominal';
new_case.heading_mode = char(heading_mode);
new_case.heading_label = char(heading_label);

new_case.nominal_heading_deg = nominal_heading_deg;
new_case.heading_offset_deg = offset_deg;
new_case.heading_deg = perturbed_heading_deg;

new_case.is_heading_extended_copy = false;
new_case.is_heading_extended_physical = true;

if ~isfield(new_case, 'notes') || isempty(new_case.notes)
    new_case.notes = '';
end
new_case.notes = sprintf([ ...
    'Stage06 physical heading-extended case. ', ...
    'Repropagated from nominal case %s with heading offset %+g deg.'], ...
    char(source_case_id), offset_deg);

new_traj = legacy_propagate_target_case_stage02_impl(new_case, cfg);
new_val = validate_hgv_trajectory_stage02(new_traj, cfg);
new_sum = summarize_hgv_case_stage02(new_case, new_traj, new_val);

if ~isfield(new_traj, 'meta') || isempty(new_traj.meta)
    new_traj.meta = struct();
end

new_traj.case_id = new_case_id;
new_traj.family = char(family_type);
new_traj.subfamily = sprintf('stage06_%s', char(heading_mode));

new_traj.meta.entry_id = entry_id;
new_traj.meta.entry_point_id = entry_id;
new_traj.meta.source_case_id = char(source_case_id);
new_traj.meta.family_origin = 'stage02_nominal';
new_traj.meta.heading_mode = char(heading_mode);
new_traj.meta.heading_label = char(heading_label);
new_traj.meta.nominal_heading_deg = nominal_heading_deg;
new_traj.meta.heading_offset_deg = offset_deg;
new_traj.meta.heading_deg = perturbed_heading_deg;
new_traj.meta.is_heading_extended_copy = false;
new_traj.meta.is_heading_extended_physical = true;

if isfield(base_item, 'traj') && isfield(base_item.traj, 'meta') && ...
        isfield(base_item.traj.meta, 'sigma0_deg')
    new_traj.meta.nominal_sigma0_deg = base_item.traj.meta.sigma0_deg;
end
if isfield(new_traj.meta, 'sigma0_deg')
    new_traj.meta.perturbed_sigma0_deg = new_traj.meta.sigma0_deg;
end

if ~isstruct(new_sum) || isempty(new_sum)
    new_sum = struct();
end

new_sum.case_id = new_case_id;
new_sum.family = char(family_type);
new_sum.subfamily = sprintf('stage06_%s', char(heading_mode));
new_sum.entry_id = entry_id;
new_sum.heading_offset_deg = offset_deg;
new_sum.heading_label = char(heading_label);
new_sum.source_case_id = char(source_case_id);
new_sum.nominal_heading_deg = nominal_heading_deg;
new_sum.heading_deg = perturbed_heading_deg;

out_item = struct();
out_item.case = new_case;
out_item.traj = new_traj;
out_item.validation = new_val;
out_item.summary = new_sum;
end

function label = local_heading_label(offset_deg)
if abs(offset_deg) < 1e-12
    label = "h0";
elseif offset_deg > 0
    label = sprintf('hp%02d', round(abs(offset_deg)));
else
    label = sprintf('hm%02d', round(abs(offset_deg)));
end
end

function s = local_empty_item()
s = struct( ...
    'case', [], ...
    'traj', [], ...
    'validation', [], ...
    'summary', []);
end
