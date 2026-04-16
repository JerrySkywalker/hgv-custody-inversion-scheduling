function out = run_ch5r_phase4g_select_reduce(opts)
%RUN_CH5R_PHASE4G_SELECT_REDUCE
% Full-run selector/reducer interface.
%
% Workflow:
%   1) load full suite raw table
%   2) attach registry metadata
%   3) filter rows by selector
%   4) export filtered csv/mat
%   5) rerun summary + wins on filtered csv
%   6) optionally replot without rerunning simulation
%
% Robustness:
%   - accepts scalar struct as intended
%   - also auto-normalizes accidental struct arrays produced by
%     MATLAB struct(..., {'a','b','c'}, ...) constructor usage

if nargin < 1 || isempty(opts)
    opts = struct();
end

% normalize accidental struct arrays into one scalar struct
opts = local_scalarize_opts(opts);

if ~isfield(opts, 'project_root') || isempty(opts.project_root)
    opts.project_root = pwd;
end
if ~isfield(opts, 'visible_mode') || isempty(opts.visible_mode)
    opts.visible_mode = 'off';
end
if ~isfield(opts, 'do_plots') || isempty(opts.do_plots)
    opts.do_plots = true;
end

suite_source = local_resolve_suite_source(opts);

[T, meta] = ch5r_load_suite_table(suite_source);
[Tsel, sel_info] = select_ch5r_suite_rows(T, opts);

assert(height(Tsel) > 0, 'Selector produced empty result set.');

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = local_build_tag(opts, stamp);

out_dir = fullfile(opts.project_root, 'outputs', 'ch5_rebuild', 'phase4g_select_reduce', tag);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

filtered_csv = fullfile(out_dir, ['selected_suite_rows_' tag '.csv']);
filtered_mat = fullfile(out_dir, ['selected_suite_rows_' tag '.mat']);
md_file = fullfile(out_dir, ['selected_suite_rows_' tag '.md']);

writetable(Tsel, filtered_csv);
save(filtered_mat, 'Tsel', 'sel_info', 'meta', 'opts');

outA = run_ch5r_phase4a_suite_summary(struct('suite_source', filtered_csv));
outE = run_ch5r_phase4e_case_wins(struct('suite_source', filtered_csv));

outF = [];
if opts.do_plots
    outF = run_ch5r_phase4f_suite_plots(struct( ...
        'suite_source', filtered_csv, ...
        'summary_source', outA, ...
        'case_wins_source', outE, ...
        'visible_mode', opts.visible_mode, ...
        'outdir_override', fullfile(out_dir, 'plots')));
end

local_write_md(md_file, suite_source, filtered_csv, sel_info, outA, outE, outF);

disp(' ')
disp('=== [ch5r:phase4G] selector/reducer done ===')
disp(['source suite : ' char(string(suite_source))])
disp(['filtered csv : ' filtered_csv])
disp(sel_info)

out = struct();
out.ok = true;
out.source_suite = suite_source;
out.output_dir = out_dir;
out.filtered_csv = filtered_csv;
out.filtered_mat = filtered_mat;
out.md_file = md_file;
out.selected_table = Tsel;
out.selector_info = sel_info;
out.summary = outA;
out.wins = outE;
out.plots = outF;
end

function opts = local_scalarize_opts(opts)
% Convert accidental struct array into one scalar struct.
% Example problematic input:
%   struct('methods', {'R4','R9','R10'}, ...)
%
% Strategy:
%   - if already scalar -> keep as is
%   - if struct array:
%       * repeated identical values -> keep single value
%       * varying char/string scalars -> pack into cellstr
%       * varying numeric/logical scalars -> pack into row vector
%       * otherwise -> pack into cell array

assert(isstruct(opts), 'opts must be a struct.');

if isscalar(opts)
    return;
end

fns = fieldnames(opts);
S = struct();

for i = 1:numel(fns)
    fn = fns{i};
    vals = {opts.(fn)};  % 1 x N cell

    if local_all_same(vals)
        S.(fn) = vals{1};
        continue;
    end

    if all(cellfun(@(x) ischar(x) || (isstring(x) && isscalar(x)), vals))
        S.(fn) = cellstr(string([vals{:}]));
        continue;
    end

    if all(cellfun(@(x) isnumeric(x) && isscalar(x), vals))
        S.(fn) = cell2mat(vals);
        continue;
    end

    if all(cellfun(@(x) islogical(x) && isscalar(x), vals))
        S.(fn) = cell2mat(vals);
        continue;
    end

    % fallback: preserve as cell array
    S.(fn) = vals;
end

opts = S;
end

function tf = local_all_same(vals)
n = numel(vals);
if n <= 1
    tf = true;
    return;
end

a = vals{1};
tf = true;
for k = 2:n
    b = vals{k};
    if ischar(a) || isstring(a)
        if ~strcmp(char(string(a)), char(string(b)))
            tf = false;
            return;
        end
    elseif isnumeric(a) || islogical(a)
        if ~isequal(a, b)
            tf = false;
            return;
        end
    else
        if ~isequal(a, b)
            tf = false;
            return;
        end
    end
end
end

function suite_source = local_resolve_suite_source(opts)
if isfield(opts, 'suite_source') && ~isempty(opts.suite_source)
    suite_source = opts.suite_source;
    return;
end

suite_root = fullfile(opts.project_root, 'outputs', 'ch5_rebuild', 'multicase_suite');
suite_source = local_latest_file(suite_root, 'multicase_suite_results*.csv');
assert(~isempty(suite_source) && isfile(suite_source), ...
    'Cannot resolve suite_source automatically. Please pass opts.suite_source.');
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

function tag = local_build_tag(opts, stamp)
parts = {};
if isfield(opts, 'families') && ~isempty(opts.families)
    parts{end+1} = ['fam-' strjoin(cellstr(string(opts.families)), '-')]; %#ok<AGROW>
end
if isfield(opts, 'methods') && ~isempty(opts.methods)
    parts{end+1} = ['meth-' strjoin(cellstr(string(opts.methods)), '-')]; %#ok<AGROW>
end
if isfield(opts, 'case_ids') && ~isempty(opts.case_ids)
    parts{end+1} = ['cases-' num2str(numel(opts.case_ids))]; %#ok<AGROW>
end
if isfield(opts, 'base_nominal_cases') && ~isempty(opts.base_nominal_cases)
    parts{end+1} = ['base-' strjoin(cellstr(string(opts.base_nominal_cases)), '-')]; %#ok<AGROW>
end
if isfield(opts, 'include_in_paper') && ~isempty(opts.include_in_paper) && logical(opts.include_in_paper)
    parts{end+1} = 'paperOnly'; %#ok<AGROW>
end
if isfield(opts, 'include_in_smoke') && ~isempty(opts.include_in_smoke) && logical(opts.include_in_smoke)
    parts{end+1} = 'smokeOnly'; %#ok<AGROW>
end

if isempty(parts)
    base = 'fullSelection';
else
    base = strjoin(parts, '_');
end

tag = [base '_' stamp];
tag = regexprep(tag, '[^A-Za-z0-9_\-]+', '_');
end

function local_write_md(md_file, suite_source, filtered_csv, sel_info, outA, outE, outF)
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Cannot open markdown file for writing.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Phase 4G selector/reducer result\n\n');
fprintf(fid, '- source suite: `%s`\n', char(string(suite_source)));
fprintf(fid, '- filtered csv: `%s`\n', filtered_csv);
fprintf(fid, '- input rows: `%d`\n', sel_info.n_input_rows);
fprintf(fid, '- output rows: `%d`\n', sel_info.n_output_rows);
fprintf(fid, '- removed rows: `%d`\n\n', sel_info.n_removed_rows);

fprintf(fid, '## Selected families\n\n');
fprintf(fid, '%s\n\n', strjoin(sel_info.families, ', '));

fprintf(fid, '## Selected methods\n\n');
fprintf(fid, '%s\n\n', strjoin(sel_info.methods, ', '));

fprintf(fid, '## Selected case ids\n\n');
fprintf(fid, '%s\n\n', strjoin(sel_info.case_ids, ', '));

if isstruct(outA) && isfield(outA, 'stats')
    fprintf(fid, '## Summary (overall)\n\n');
    fprintf(fid, '%s\n\n', local_table_to_md(outA.stats.summary_all));
end

if isstruct(outE) && isfield(outE, 'wins')
    fprintf(fid, '## Winner counts (overall)\n\n');
    fprintf(fid, '%s\n\n', local_table_to_md(outE.wins.overall));
end

if ~isempty(outF)
    fprintf(fid, '## Plot output dir\n\n');
    fprintf(fid, '- `%s`\n\n', outF.output_dir);
end
end

function s = local_table_to_md(T)
if isempty(T)
    s = '_empty_';
    return;
end

vars = T.Properties.VariableNames;
header = ['| ' strjoin(vars, ' | ') ' |'];
sep = ['| ' strjoin(repmat({'---'}, 1, numel(vars)), ' | ') ' |'];

rows = cell(height(T),1);
for i = 1:height(T)
    vals = cell(1, numel(vars));
    for j = 1:numel(vars)
        vals{j} = local_scalar_to_char(T{i,j});
    end
    rows{i} = ['| ' strjoin(vals, ' | ') ' |'];
end

parts = [{header}; {sep}; rows];
s = strjoin(parts, newline);
end

function c = local_scalar_to_char(v)
if iscell(v)
    if isempty(v)
        c = '';
    else
        c = local_scalar_to_char(v{1});
    end
elseif isstring(v)
    if isempty(v)
        c = '';
    else
        c = char(v(1));
    end
elseif ischar(v)
    c = v;
elseif iscategorical(v)
    c = char(string(v));
elseif isnumeric(v) || islogical(v)
    if isscalar(v)
        c = num2str(v);
    else
        c = '[array]';
    end
else
    c = char(string(v));
end
end
