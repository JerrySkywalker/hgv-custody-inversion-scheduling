clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));

suite_source = local_resolve_suite_source_for_smoke(pwd);
[T0, ~] = ch5r_load_suite_table(suite_source);
T0 = ch5r_attach_case_metadata(T0);

family_col = local_pick_column(T0, {'reg_family','family'});
case_col   = local_pick_column(T0, {'actual_case_id','requested_case_id','reg_case_id'});

assert(~isempty(family_col), 'Smoke setup failed: no family column found.');
assert(~isempty(case_col), 'Smoke setup failed: no case id column found.');

families_all = string(T0.(family_col));
case_values_all = string(T0.(case_col));

if any(families_all == "heading")
    target_family = "heading";
else
    uf = unique(families_all, 'stable');
    assert(~isempty(uf), 'Smoke setup failed: no family values found.');
    target_family = uf(1);
end

idx_family = (families_all == target_family);
candidate_cases = unique(case_values_all(idx_family), 'stable');
assert(~isempty(candidate_cases), 'Smoke setup failed: no candidate cases in target family.');

target_case = candidate_cases(1);

idx_case = idx_family & (case_values_all == target_case);
target_methods = cellstr(unique(string(T0.method(idx_case)), 'stable'));
assert(~isempty(target_methods), 'Smoke setup failed: no methods found for selected case.');

disp('=== [selector-reducer smoke] auto-selected target ===')
disp(struct( ...
    'suite_source', suite_source, ...
    'target_family', char(target_family), ...
    'target_case', char(target_case), ...
    'target_methods', {target_methods}))

out = run_ch5r_phase4g_select_reduce(struct( ...
    'suite_source', suite_source, ...
    'families', {{char(target_family)}}, ...
    'case_ids', {{char(target_case)}}, ...
    'methods', {target_methods}, ...
    'do_plots', true, ...
    'visible_mode', 'off'));

assert(out.ok);
assert(height(out.selected_table) == numel(target_methods));

assert(all(ismember(string(out.selected_table.method), string(target_methods))));

matched_case = false(height(out.selected_table), 1);

if ismember('actual_case_id', out.selected_table.Properties.VariableNames)
    matched_case = matched_case | (string(out.selected_table.actual_case_id) == string(target_case));
end
if ismember('requested_case_id', out.selected_table.Properties.VariableNames)
    matched_case = matched_case | (string(out.selected_table.requested_case_id) == string(target_case));
end
if ismember('reg_case_id', out.selected_table.Properties.VariableNames)
    matched_case = matched_case | (string(out.selected_table.reg_case_id) == string(target_case));
end

assert(all(matched_case), 'Selected table contains unexpected case ids.');

disp('=== manual_ch5_phase4g_selector_reduce_smoke passed ===')
disp(out.output_dir)
disp(out.selector_info)

function suite_source = local_resolve_suite_source_for_smoke(project_root)
summary_root = fullfile(project_root, 'outputs', 'ch5_rebuild', 'phase4_suite_summary');
suite_source = local_latest_file(summary_root, 'multicase_results_*.csv');
if ~isempty(suite_source) && isfile(suite_source)
    return;
end

suite_root = fullfile(project_root, 'outputs', 'ch5_rebuild', 'multicase_suite');
suite_source = local_latest_file(suite_root, 'multicase_suite_results*.csv');
assert(~isempty(suite_source) && isfile(suite_source), ...
    'Cannot resolve suite_source for smoke.');
end

function f = local_latest_file(root_dir, pattern)
f = '';
if ~exist(root_dir, 'dir')
    return;
end
D = dir(fullfile(root_dir, '**', pattern));
D = D(~[D.isdir]);
if isempty(D)
    return;
end
[~, idx] = max([D.datenum]);
f = fullfile(D(idx).folder, D(idx).name);
end

function col = local_pick_column(T, cands)
col = '';
for i = 1:numel(cands)
    if ismember(cands{i}, T.Properties.VariableNames)
        col = cands{i};
        return;
    end
end
end
