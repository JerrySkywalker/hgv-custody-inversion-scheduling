function out = run_ch5r_phase4c_batch_pipeline(opts)
%RUN_CH5R_PHASE4C_BATCH_PIPELINE
% Phase 4C unified batch entry:
%   case-set resolution -> multicase suite -> phase4A summary -> phase4B plots
%
% Typical use:
%   out = run_ch5r_phase4c_batch_pipeline(struct('case_set','paper'));
%   out = run_ch5r_phase4c_batch_pipeline(struct('case_set','full','max_cases',20));
%
% Important options:
%   case_set           : 'paper' | 'full' | 'smoke'
%   family             : '', 'nominal', 'heading', 'critical'
%   case_ids           : explicit case ids; if nonempty, intersects with case_set/family
%   methods            : default {'R4','R5','R9','R10'}
%   max_cases          : optional positive integer for truncation
%   lock_name          : default 'ch5_constellation_lock'
%   suite_save_case_mat: default false
%   suite_fail_fast    : default true
%   visible_mode       : default 'off'
%   reuse_suite_source : [] or prior suite output struct or csv path
%
% Outputs:
%   out.case_ids
%   out.suite
%   out.phase4ab
%   out.paths.*

if nargin < 1 || isempty(opts)
    opts = struct();
end

opts = local_apply_defaults(opts);

startup('force', true);

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));
addpath(fullfile(pwd, 'ch5_rebuild', 'analysis'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));
addpath(fullfile(pwd, 'ch5_rebuild', 'runners'));

resolved = resolve_ch5r_case_list(struct( ...
    'case_set', opts.case_set, ...
    'family', opts.family, ...
    'case_ids', opts.case_ids));

case_ids = resolved.case_ids;

if ~isempty(opts.max_cases)
    assert(isnumeric(opts.max_cases) && isscalar(opts.max_cases) && opts.max_cases >= 1, ...
        'max_cases must be a positive scalar.');
    if numel(case_ids) > opts.max_cases
        case_ids = case_ids(1:opts.max_cases);
    end
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
method_tag = regexprep(strjoin(opts.methods, '-'), '[^A-Za-z0-9_\-]+', '-');
pipe_tag = ['caseSet-' lower(char(string(opts.case_set))) ...
            '_family-' regexprep(lower(char(string(opts.family))), '[^A-Za-z0-9_\-]+', '-') ...
            '_methods-' method_tag '_' stamp];

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phase4c_pipeline', ['phase4c_' pipe_tag]);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

% Manifest of actually scheduled cases
manifest = table( ...
    string(case_ids(:)), ...
    repmat(string(opts.case_set), numel(case_ids), 1), ...
    repmat(string(opts.family), numel(case_ids), 1), ...
    'VariableNames', {'case_id','case_set','family_filter'});

manifest_csv = fullfile(out_dir, ['phase4c_manifest_' pipe_tag '.csv']);
writetable(manifest, manifest_csv);

disp(' ')
disp('=== [ch5r:phase4C] batch pipeline start ===')
disp(['case_set         : ' char(string(opts.case_set))])
disp(['family           : ' char(string(opts.family))])
disp(['methods          : ' strjoin(opts.methods, ', ')])
disp(['n_cases          : ' num2str(numel(case_ids))])
disp(['lock_name        : ' opts.lock_name])
disp(['reuse_suite      : ' num2str(~isempty(opts.reuse_suite_source))])
disp(['manifest csv     : ' manifest_csv])

% --------------------------------
% Step 1: suite
% --------------------------------
if isempty(opts.reuse_suite_source)
    suite_out = run_ch5r_multicase_suite(struct( ...
        'case_set', opts.case_set, ...
        'family', opts.family, ...
        'case_ids', {case_ids}, ...
        'methods', {opts.methods}, ...
        'lock_name', opts.lock_name, ...
        'save_case_mat', opts.suite_save_case_mat, ...
        'fail_fast', opts.suite_fail_fast));
else
    suite_out = opts.reuse_suite_source;
end

% --------------------------------
% Step 2: phase4A + phase4B
% --------------------------------
phase4ab = run_ch5r_phase4ab_suite_summary_and_plots(struct( ...
    'suite_source', suite_out, ...
    'visible_mode', opts.visible_mode));

% --------------------------------
% Step 3: save bundle + markdown
% --------------------------------
mat_file = fullfile(out_dir, ['phase4c_pipeline_' pipe_tag '.mat']);
save(mat_file, 'opts', 'resolved', 'case_ids', 'suite_out', 'phase4ab');

md_file = fullfile(out_dir, ['phase4c_pipeline_' pipe_tag '.md']);
local_write_md(md_file, opts, case_ids, suite_out, phase4ab, manifest_csv, mat_file);

disp(' ')
disp('=== [ch5r:phase4C] batch pipeline done ===')
disp(['pipeline dir     : ' out_dir])
disp(['pipeline mat     : ' mat_file])
disp(['pipeline md      : ' md_file])

out = struct();
out.ok = true;
out.opts = opts;
out.case_ids = case_ids;
out.resolved = resolved;
out.manifest = manifest;
out.suite = suite_out;
out.phase4ab = phase4ab;
out.paths = struct( ...
    'output_dir', out_dir, ...
    'manifest_csv', manifest_csv, ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'tag', pipe_tag);
end

function opts = local_apply_defaults(opts)
if ~isfield(opts, 'case_set') || isempty(opts.case_set)
    opts.case_set = 'paper';
end
if ~isfield(opts, 'family') || isempty(opts.family)
    opts.family = '';
end
if ~isfield(opts, 'case_ids') || isempty(opts.case_ids)
    opts.case_ids = {};
end
if ~isfield(opts, 'methods') || isempty(opts.methods)
    opts.methods = {'R4','R5','R9','R10'};
end
if ~isfield(opts, 'max_cases') || isempty(opts.max_cases)
    opts.max_cases = [];
end
if ~isfield(opts, 'lock_name') || isempty(opts.lock_name)
    opts.lock_name = 'ch5_constellation_lock';
end
if ~isfield(opts, 'suite_save_case_mat') || isempty(opts.suite_save_case_mat)
    opts.suite_save_case_mat = false;
end
if ~isfield(opts, 'suite_fail_fast') || isempty(opts.suite_fail_fast)
    opts.suite_fail_fast = true;
end
if ~isfield(opts, 'visible_mode') || isempty(opts.visible_mode)
    opts.visible_mode = 'off';
end
if ~isfield(opts, 'reuse_suite_source')
    opts.reuse_suite_source = [];
end
end

function local_write_md(md_file, opts, case_ids, suite_out, phase4ab, manifest_csv, mat_file)
lines = {};
lines{end+1} = '# Phase 4C Batch Pipeline';
lines{end+1} = '';
lines{end+1} = ['- Case set: `', char(string(opts.case_set)), '`'];
lines{end+1} = ['- Family filter: `', char(string(opts.family)), '`'];
lines{end+1} = ['- Methods: `', strjoin(opts.methods, ', '), '`'];
lines{end+1} = ['- Number of cases: `', num2str(numel(case_ids)), '`'];
lines{end+1} = ['- Lock name: `', opts.lock_name, '`'];
lines{end+1} = ['- Manifest CSV: `', manifest_csv, '`'];
lines{end+1} = ['- Pipeline MAT: `', mat_file, '`'];

if isstruct(suite_out) && isfield(suite_out, 'paths') && isfield(suite_out.paths, 'csv_file')
    lines{end+1} = ['- Suite CSV: `', suite_out.paths.csv_file, '`'];
end
if isstruct(phase4ab) && isfield(phase4ab, 'phase4a') && isfield(phase4ab.phase4a, 'paths')
    lines{end+1} = ['- Phase4A overall CSV: `', phase4ab.phase4a.paths.overall_csv, '`'];
    lines{end+1} = ['- Phase4A family CSV: `', phase4ab.phase4a.paths.family_csv, '`'];
end
if isstruct(phase4ab) && isfield(phase4ab, 'phase4b') && isfield(phase4ab.phase4b, 'paths')
    lines{end+1} = ['- Phase4B plot dir: `', phase4ab.phase4b.paths.output_dir, '`'];
end

txt = strjoin(lines, newline);
fid = fopen(md_file, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', txt);
end
