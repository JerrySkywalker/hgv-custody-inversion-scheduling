function mgr = create_static_evaluation_manager(profile)
% Minimal bootstrap implementation for static evaluation framework.

if nargin < 1
    profile = struct();
end

mgr = struct();
mgr.profile = profile;

mgr.run = @() local_run(profile);
end

function result = local_run(profile)
cfg = config_service(profile);
design_pool = design_pool_service(cfg);
task_family = task_family_service(cfg);
truth_result = truth_evaluation_service(cfg, design_pool, task_family);
minimum_solution_result = minimum_solution_service(truth_result);

result = struct();
result.profile = profile;
result.cfg = cfg;
result.design_pool = design_pool;
result.task_family = task_family;
result.truth_result = truth_result;
result.minimum_solution_result = minimum_solution_result;

fprintf('[static] Run completed.\n');
fprintf('[static] Profile: %s\n', get_profile_name(profile));
fprintf('[static] Design count: %d\n', design_pool.design_count);
fprintf('[static] Task family: %s\n', task_family.name);
fprintf('[static] Case count: %d\n', task_family.case_count);
fprintf('[static] Truth rows: %d\n', truth_result.row_count);

tbl = truth_result.table;
if ~isempty(tbl)
    feasible_count = sum(tbl.is_feasible);
    min_Ns = min(tbl.Ns);
    max_joint_margin = max(tbl.joint_margin);

    fprintf('[static] Feasible rows: %d\n', feasible_count);
    fprintf('[static] Minimum Ns: %d\n', min_Ns);
    fprintf('[static] Maximum joint margin: %.6g\n', max_joint_margin);
end

ms = minimum_solution_result;
if isfield(ms, 'solution_count')
    fprintf('[static] Minimum-solution count: %d\n', ms.solution_count);
    if ~isnan(ms.min_Ns)
        fprintf('[static] Minimum-solution Ns: %d\n', ms.min_Ns);
    end
    if isfield(ms, 'near_optimal_count')
        fprintf('[static] Near-optimal count: %d\n', ms.near_optimal_count);
    end
end
end

function name = get_profile_name(profile)
name = 'unnamed';
if isstruct(profile) && isfield(profile, 'name') && ~isempty(profile.name)
    name = profile.name;
end
end
