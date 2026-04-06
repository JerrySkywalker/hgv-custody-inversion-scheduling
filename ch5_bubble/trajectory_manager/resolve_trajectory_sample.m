function traj_sample = resolve_trajectory_sample(registry, sample_id, cfg)
%RESOLVE_TRAJECTORY_SAMPLE Resolve one trajectory sample for ch5_bubble.
%
% Preferred path:
%   manual recipe -> synthetic case -> Stage02 propagation kernel
%
% B1.1 fix:
%   Apply recipe-level overrides directly to the fundamental propagation
%   state fields used by the kernel: v0 / theta0 / h0 / sigma0.

if nargin < 3 || isempty(cfg)
    cfg = default_ch5b_params();
end

requiredFns = { ...
    'build_hgv_cfg_from_case_stage02', ...
    'propagate_hgv_case_stage02'};

for i = 1:numel(requiredFns)
    assert(exist(requiredFns{i}, 'file') == 2, ...
        'resolve_trajectory_sample:MissingDependency', ...
        'Required function not found on path: %s', requiredFns{i});
end

idx = find(strcmp(registry.sample_ids, sample_id), 1, 'first');
if isempty(idx)
    error('resolve_trajectory_sample:SampleNotFound', ...
        'Sample id "%s" not found in registry.', sample_id);
end

meta = registry.samples(idx);

recipe = [];
switch lower(meta.source_tag)
    case 'manual_recipe'
        recipes = default_ch5b_trajectory_recipes(cfg);
        recipe = local_find_recipe(recipes, sample_id);
        case_i = build_manual_case_from_recipe_ch5b(recipe, cfg);

    case 'stage01_casebank'
        [casebank, ~] = load_stage01_casebank_ch5b(cfg);
        case_i = local_find_case_by_id(casebank, sample_id);

    otherwise
        error('resolve_trajectory_sample:UnsupportedSourceTag', ...
            'Unsupported source_tag: %s', meta.source_tag);
end

hgv_cfg = build_hgv_cfg_from_case_stage02(case_i, cfg);

if ~isempty(recipe)
    hgv_cfg = local_apply_recipe_overrides(hgv_cfg, recipe);
end

traj = propagate_hgv_case_stage02(case_i, cfg, hgv_cfg);

traj_sample = struct();
traj_sample.sample_id = meta.sample_id;
traj_sample.family_id = meta.family_id;
traj_sample.case_label = meta.case_label;
traj_sample.source_tag = meta.source_tag;
traj_sample.description = sprintf('Real propagated trajectory for %s', meta.sample_id);

traj_sample.case = case_i;
traj_sample.traj = traj;
traj_sample.hgv_cfg = hgv_cfg;

traj_sample.time = traj.t_s(:);
traj_sample.truth = traj.X;
traj_sample.dt = local_get_dt(traj.t_s(:));
traj_sample.n_steps = numel(traj.t_s);
traj_sample.t_start = traj.t_s(1);
traj_sample.t_end = traj.t_s(end);
traj_sample.state_dim = size(traj.X, 2);
traj_sample.first_state = traj.X(1,:);
traj_sample.last_state = traj.X(end,:);
traj_sample.terminal_reason = local_infer_terminal_reason(traj, cfg);

traj_sample.metadata = struct();
traj_sample.metadata.framework = 'ch5_bubble';
traj_sample.metadata.phase = 'B1_manual_recipe';
traj_sample.metadata.entry_theta_deg = local_get_field(case_i, 'entry_theta_deg', NaN);
traj_sample.metadata.heading_deg = local_get_field(case_i, 'heading_deg', NaN);
traj_sample.metadata.heading_offset_deg = local_get_field(case_i, 'heading_offset_deg', NaN);
traj_sample.metadata.subfamily = local_get_field(case_i, 'subfamily', '');
traj_sample.metadata.recipe_used = ~isempty(recipe);

end

function recipe = local_find_recipe(recipes, sample_id)
for k = 1:numel(recipes)
    if strcmp(recipes(k).case_id, sample_id)
        recipe = recipes(k);
        return;
    end
end
error('resolve_trajectory_sample:RecipeNotFound', ...
    'Manual recipe not found for sample id "%s".', sample_id);
end

function hgv_cfg = local_apply_recipe_overrides(hgv_cfg, recipe)

% -------------------------------------------------------------------------
% Fundamental propagation state fields actually used by the kernel
% -------------------------------------------------------------------------
if isfield(recipe, 'h0_m')
    hgv_cfg.h0 = recipe.h0_m;
    hgv_cfg.h0_m = recipe.h0_m;
end

if isfield(recipe, 'v0_mps')
    hgv_cfg.v0 = recipe.v0_mps;
    hgv_cfg.v0_mps = recipe.v0_mps;
end

if isfield(recipe, 'theta0_deg')
    hgv_cfg.theta0 = deg2rad(recipe.theta0_deg);
    hgv_cfg.theta0_deg = recipe.theta0_deg;
    hgv_cfg.gamma0_deg = recipe.theta0_deg;
    hgv_cfg.entry_theta_deg = recipe.theta0_deg;
end

if isfield(recipe, 'sigma0_deg')
    hgv_cfg.sigma0 = deg2rad(recipe.sigma0_deg);
    hgv_cfg.sigma0_deg = recipe.sigma0_deg;
end

% -------------------------------------------------------------------------
% Additional aliases / control-profile related fields
% -------------------------------------------------------------------------
hgv_cfg = local_set_if_present(hgv_cfg, 'bank_cmd_deg', recipe, 'bank_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'bank_nominal_deg', recipe, 'bank_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'bank_heading_deg', recipe, 'bank_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'bank_c1_deg', recipe, 'bank_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'bank_c2_deg', recipe, 'bank_cmd_deg');

hgv_cfg = local_set_if_present(hgv_cfg, 'alpha_cmd_deg', recipe, 'alpha_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'alpha_nominal_deg', recipe, 'alpha_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'alpha_heading_deg', recipe, 'alpha_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'alpha_c1_deg', recipe, 'alpha_cmd_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'alpha_c2_deg', recipe, 'alpha_cmd_deg');

hgv_cfg = local_set_if_present(hgv_cfg, 'heading_deg', recipe, 'heading_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'psi0_deg', recipe, 'heading_deg');
hgv_cfg = local_set_if_present(hgv_cfg, 'heading_offset_deg', recipe, 'heading_offset_deg');

% -------------------------------------------------------------------------
% Try to patch ctrl_profile as well, if present
% -------------------------------------------------------------------------
if isfield(hgv_cfg, 'ctrl_profile') && isstruct(hgv_cfg.ctrl_profile)
    cp = hgv_cfg.ctrl_profile;

    if isfield(recipe, 'alpha_cmd_deg')
        cp = local_set_struct_field(cp, 'alpha_cmd_deg', recipe.alpha_cmd_deg);
        cp = local_set_struct_field(cp, 'alpha_deg', recipe.alpha_cmd_deg);
    end

    if isfield(recipe, 'bank_cmd_deg')
        cp = local_set_struct_field(cp, 'bank_cmd_deg', recipe.bank_cmd_deg);
        cp = local_set_struct_field(cp, 'bank_deg', recipe.bank_cmd_deg);
        cp = local_set_struct_field(cp, 'sigma_deg', recipe.bank_cmd_deg);
    end

    hgv_cfg.ctrl_profile = cp;
end

end

function s = local_set_if_present(s, dst_field, src_struct, src_field)
if isfield(src_struct, src_field)
    s.(dst_field) = src_struct.(src_field);
end
end

function s = local_set_struct_field(s, field_name, value)
s.(field_name) = value;
end

function case_i = local_find_case_by_id(casebank, sample_id)
families = {'nominal', 'heading', 'critical'};
for i = 1:numel(families)
    fam = families{i};
    if ~isfield(casebank, fam)
        continue;
    end
    arr = casebank.(fam);
    for k = 1:numel(arr)
        if isfield(arr(k), 'case_id') && strcmp(arr(k).case_id, sample_id)
            case_i = arr(k);
            return;
        end
    end
end
error('resolve_trajectory_sample:CaseNotFoundInStage01', ...
    'Case id "%s" not found in loaded Stage01 casebank.', sample_id);
end

function dt = local_get_dt(t)
if numel(t) < 2
    dt = NaN;
else
    dt = mean(diff(t));
end
end

function reason = local_infer_terminal_reason(traj, cfg)
tol = 1e-9;
if traj.t_s(end) >= cfg.stage02.Tmax_s - tol
    reason = 'tmax_reached';
    return;
end

if isfield(traj, 'h_m')
    h_end = traj.h_m(end);
    if h_end <= cfg.stage02.h_min_m + 1.0
        reason = 'event_h_min';
        return;
    end
    if h_end >= cfg.stage02.h_max_m - 1.0
        reason = 'event_h_max';
        return;
    end
end

if isfield(traj, 'v_mps')
    v_end = traj.v_mps(end);
    if v_end <= cfg.stage02.v_min_mps + 1.0
        reason = 'event_v_min';
        return;
    end
    if v_end >= cfg.stage02.v_max_mps - 1.0
        reason = 'event_v_max';
        return;
    end
end

reason = 'event_or_ode_stop';
end

function v = local_get_field(s, name, defaultv)
if isfield(s, name)
    v = s.(name);
else
    v = defaultv;
end
end
