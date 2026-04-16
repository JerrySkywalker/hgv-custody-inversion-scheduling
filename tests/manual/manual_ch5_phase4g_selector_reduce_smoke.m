clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));

out = run_ch5r_phase4g_select_reduce(struct( ...
    'families', {'heading'}, ...
    'case_ids', {'H04_+30'}, ...
    'methods', {'R4','R9','R10'}, ...
    'do_plots', true, ...
    'visible_mode', 'off'));

assert(out.ok);
assert(height(out.selected_table) == 3);

assert(all(ismember(string(out.selected_table.method), ["R4","R9","R10"])));
if ismember('actual_case_id', out.selected_table.Properties.VariableNames)
    assert(all(string(out.selected_table.actual_case_id) == "H04_+30"));
end

disp('=== manual_ch5_phase4g_selector_reduce_smoke passed ===')
disp(out.output_dir)
disp(out.selector_info)
