function out = evaluate_dense_design_grid_with_stage09(cfg, design_table, options)
%EVALUATE_DENSE_DESIGN_GRID_WITH_STAGE09 Evaluate a local dense design table with the Stage09 truth kernel.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || ~istable(design_table)
    error('evaluate_dense_design_grid_with_stage09 requires cfg and design_table.');
end
if nargin < 3 || isempty(options)
    options = struct();
end

family_names = ["joint", "nominal", "heading"];
if isfield(options, 'family_names') && ~isempty(options.family_names)
    family_names = string(options.family_names);
end

overrides = struct();
overrides.use_parallel = true;
overrides.save_case_window_bank = false;
overrides.enable_checkpoint = false;
overrides.resume_from_checkpoint = false;
if isfield(options, 'use_parallel') && ~isempty(options.use_parallel)
    overrides.use_parallel = logical(options.use_parallel);
end
if isfield(options, 'heading_subset_max') && ~isempty(options.heading_subset_max)
    overrides.heading_subset_max = options.heading_subset_max;
elseif isfield(cfg.milestones.MB.slice_settings, 'heading_subset_max')
    overrides.heading_subset_max = cfg.milestones.MB.slice_settings.heading_subset_max;
end
if isfield(options, 'fast_mode') && ~isempty(options.fast_mode)
    overrides.fast_mode = logical(options.fast_mode);
end

design_table = unique_design_rows(design_table);
t_joint = tic;
joint_eval = evaluate_design_pool_with_stage09(cfg, design_table, 'joint', overrides);
t_joint_s = toc(t_joint);

out = struct();
out.design_pool_table = design_table;
out.joint = joint_eval;
out.summary = struct();
out.summary.num_designs = height(design_table);
out.summary.joint_eval_s = t_joint_s;
out.summary.family_names = family_names;

if any(strcmpi(family_names, "nominal"))
    out.nominal = derive_family_eval_from_joint(joint_eval, 'nominal', joint_eval.cfg);
end
if any(strcmpi(family_names, "heading"))
    out.heading = derive_family_eval_from_joint(joint_eval, 'heading', joint_eval.cfg);
end
if any(strcmpi(family_names, "critical"))
    out.critical = derive_family_eval_from_joint(joint_eval, 'critical', joint_eval.cfg);
end
end
