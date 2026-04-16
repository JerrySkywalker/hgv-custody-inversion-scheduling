function out = run_ch5r_multicase_suite(opts)
%RUN_CH5R_MULTICASE_SUITE
% Multi-case suite with explicit case_ids priority and tagged outputs.

if nargin < 1 || builtin('isempty', opts)
    opts = struct();
end

if ~isfield(opts, 'case_set') || builtin('isempty', opts.case_set)
    case_set_name = 'smoke';
else
    case_set_name = lower(char(string(opts.case_set)));
end

if ~isfield(opts, 'family') || builtin('isempty', opts.family)
    family_name = '';
else
    family_name = lower(char(string(opts.family)));
end

if ~isfield(opts, 'lock_name') || builtin('isempty', opts.lock_name)
    lock_name = 'ch5_constellation_lock';
else
    lock_name = char(string(opts.lock_name));
end

if ~isfield(opts, 'save_case_mat') || builtin('isempty', opts.save_case_mat)
    save_case_mat = true;
else
    save_case_mat = logical(opts.save_case_mat);
end

if ~isfield(opts, 'fail_fast') || builtin('isempty', opts.fail_fast)
    fail_fast = true;
else
    fail_fast = logical(opts.fail_fast);
end

if ~isfield(opts, 'methods') || builtin('isempty', opts.methods)
    methods = {'R4'};
else
    tmp = opts.methods;
    if iscell(tmp) && numel(tmp) == 1 && iscell(tmp{1})
        tmp = tmp{1};
    end
    if isstring(tmp)
        methods = cellstr(tmp(:)).';
    elseif ischar(tmp)
        methods = {tmp};
    elseif iscell(tmp)
        methods = cell(size(tmp));
        for i = 1:numel(tmp)
            methods{i} = char(string(tmp{i}));
        end
    else
        error('run_ch5r_multicase_suite:UnsupportedMethods', ...
            'Unsupported methods type: %s', class(tmp));
    end
end

explicit_case_ids = {};
if isfield(opts, 'case_ids') && ~(builtin('isempty', opts.case_ids))
    tmp = opts.case_ids;
    if iscell(tmp) && numel(tmp) == 1 && iscell(tmp{1})
        tmp = tmp{1};
    end
    if isstring(tmp)
        explicit_case_ids = cellstr(tmp(:)).';
    elseif ischar(tmp)
        explicit_case_ids = {tmp};
    elseif iscell(tmp)
        explicit_case_ids = cell(size(tmp));
        for i = 1:numel(tmp)
            explicit_case_ids{i} = char(string(tmp{i}));
        end
    else
        error('run_ch5r_multicase_suite:UnsupportedCaseIds', ...
            'Unsupported case_ids type: %s', class(tmp));
    end
    keep = true(size(explicit_case_ids));
    for i = 1:numel(explicit_case_ids)
        keep(i) = ~(builtin('isempty', explicit_case_ids{i}));
    end
    explicit_case_ids = explicit_case_ids(keep);
end

startup('force', true);

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));
addpath(fullfile(pwd, 'ch5_rebuild', 'bootstrap'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));

registry_all = build_ch5r_case_registry();

if ~(builtin('isempty', explicit_case_ids))
    [tf, loc] = ismember(explicit_case_ids, registry_all.case_id);
    if ~all(tf)
        missing = explicit_case_ids(~tf);
        error('run_ch5r_multicase_suite:UnknownCaseId', ...
            'Unknown case_ids: %s', strjoin(missing, ', '));
    end

    reg = registry_all(loc, :);

    switch case_set_name
        case 'smoke'
            keep = reg.include_in_smoke;
        case 'paper'
            keep = reg.include_in_paper;
        case 'full'
            keep = true(height(reg),1);
        otherwise
            error('run_ch5r_multicase_suite:UnsupportedCaseSet', ...
                'Unsupported case_set: %s', case_set_name);
    end

    if ~(builtin('isempty', family_name))
        keep = keep & strcmpi(reg.family, family_name);
    end

    reg = reg(keep, :);
    case_ids = reshape(reg.case_id, 1, []);

    disp(' ')
    disp('=== [ch5r:multicase-suite] explicit case list accepted ===')
    disp(['requested explicit case_ids : ', strjoin(explicit_case_ids, ', ')])
    disp(['resolved case_ids           : ', strjoin(case_ids, ', ')])
else
    cases_out = resolve_ch5r_case_list(struct( ...
        'case_set', case_set_name, ...
        'family', family_name, ...
        'case_ids', {}));
    case_ids = cases_out.case_ids;
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
method_tag = regexprep(strjoin(methods, '-'), '[^A-Za-z0-9_\-]+', '-');
suite_tag = ['caseSet-' case_set_name '_family-' family_name '_methods-' method_tag '_' stamp];
suite_tag = regexprep(suite_tag, '[^A-Za-z0-9_\-]+', '-');

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite', ['suite_' suite_tag]);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

rows = {};
row_id = 0;

disp(' ')
disp('=== [ch5r:multicase-suite] start ===')
disp(['case_set  : ' case_set_name])
disp(['family    : ' family_name])
disp(['methods   : ' strjoin(methods, ', ')])
disp(['n_cases   : ' num2str(numel(case_ids))])
disp(['lock_name : ' lock_name])

for iCase = 1:numel(case_ids)
    case_id = case_ids{iCase};

    disp(' ')
    disp(['[suite] case ', num2str(iCase), '/', num2str(numel(case_ids)), ' : ', case_id])

    activate_ch5r_runtime_override(case_id, struct( ...
        'use_constellation_lock', true, ...
        'lock_name', lock_name));

    try
        for iMethod = 1:numel(methods)
            method_tag_i = methods{iMethod};

            disp(['[suite] run method : ' method_tag_i])

            switch upper(method_tag_i)
                case 'R4'
                    outx = run_ch5r_phase4_tracking_baseline();
                case 'R5'
                    outx = run_ch5r_phase5_bubble_predictive();
                case 'R9'
                    outx = run_ch5r_phase9_r9_closedloop();
                case 'R10'
                    outx = run_ch5r_phase10_li_backend_closedloop(struct( ...
                        'save_outputs', false, ...
                        'log_enable', true));
                otherwise
                    error('run_ch5r_multicase_suite:UnsupportedMethod', ...
                        'Unsupported method: %s', method_tag_i);
            end

            row = extract_ch5r_suite_row(method_tag_i, case_id, outx);

            row_id = row_id + 1;
            rows(row_id,:) = { ...
                row.method, ...
                row.requested_case_id, ...
                row.actual_case_id, ...
                row.family, ...
                row.window_mode, ...
                row.window_length_s, ...
                row.valid_steps, ...
                row.valid_time_s, ...
                row.bubble_steps, ...
                row.bubble_time_s, ...
                row.bubble_fraction, ...
                row.longest_bubble_time_s, ...
                row.max_bubble_depth, ...
                row.mean_bubble_depth, ...
                row.switch_count, ...
                row.resource_score, ...
                row.SC_steps, ...
                row.DC_steps, ...
                row.LoC_steps, ...
                row.SC_ratio, ...
                row.DC_ratio, ...
                row.LoC_ratio, ...
                row.mean_rmse_pos_km, ...
                row.final_rmse_pos_km, ...
                row.ok, ...
                row.mat_file, ...
                row.artifact_tag}; %#ok<AGROW>

            if save_case_mat
                case_dir = fullfile(out_dir, char(string(case_id)));
                if ~exist(case_dir, 'dir')
                    mkdir(case_dir);
                end

                case_file_tag = char(row.artifact_tag);
                if builtin('isempty', case_file_tag)
                    case_file_tag = ['case-' char(string(case_id)) '_method-' upper(method_tag_i) '_' stamp];
                end

                save(fullfile(case_dir, ['suite_' upper(method_tag_i) '_' case_file_tag '.mat']), 'outx');
            end
        end

    catch ME
        clear_ch5r_runtime_override();
        if fail_fast
            rethrow(ME);
        else
            warning('[suite] case=%s failed: %s', case_id, ME.message);
        end
    end

    clear_ch5r_runtime_override();
end

if builtin('isempty', rows)
    error('[suite] No rows collected.');
end

T = cell2table(rows, 'VariableNames', { ...
    'method', 'requested_case_id', 'actual_case_id', 'family', 'window_mode', 'window_length_s', ...
    'valid_steps', 'valid_time_s', 'bubble_steps', 'bubble_time_s', 'bubble_fraction', ...
    'longest_bubble_time_s', 'max_bubble_depth', 'mean_bubble_depth', ...
    'switch_count', 'resource_score', ...
    'SC_steps', 'DC_steps', 'LoC_steps', 'SC_ratio', 'DC_ratio', 'LoC_ratio', ...
    'mean_rmse_pos_km', 'final_rmse_pos_km', ...
    'ok', 'mat_file', 'artifact_tag'});

csv_file = fullfile(out_dir, ['multicase_results_' suite_tag '.csv']);
writetable(T, csv_file);

disp(' ')
disp('=== [ch5r:multicase-suite] done ===')
disp(['csv file : ' csv_file])
disp(T)

out = struct();
out.ok = true;
out.case_ids = case_ids;
out.methods = methods;
out.table = T;
out.paths = struct('csv_file', csv_file, 'output_dir', out_dir, 'suite_tag', suite_tag);
end
