function out = run_ch5r_phase4a_suite_summary(opts)
%RUN_CH5R_PHASE4A_SUITE_SUMMARY
% Phase 4A/4D: compute full summary tables from multicase suite output.

if nargin < 1 || isempty(opts)
    opts = struct();
end

if ~isfield(opts, 'suite_source') || isempty(opts.suite_source)
    error('run_ch5r_phase4a_suite_summary:MissingSource', 'opts.suite_source is required.');
end

if ~isfield(opts, 'metrics') || isempty(opts.metrics)
    opts.metrics = { ...
        'LoC_ratio', ...
        'DC_ratio', ...
        'SC_ratio', ...
        'bubble_steps', ...
        'bubble_time_s', ...
        'bubble_fraction', ...
        'longest_bubble_time_s', ...
        'max_bubble_depth', ...
        'switch_count', ...
        'mean_rmse_pos_km', ...
        'final_rmse_pos_km'};
end

[T, meta] = ch5r_load_suite_table(opts.suite_source);
stats = aggregate_ch5r_suite_stats(T, opts.metrics);

% aliases for current Phase4B compatibility
stats.overall = stats.summary_all;
stats.by_family = stats.summary_by_family;

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = ['phase4a_suite_summary_' stamp];

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phase4_suite_summary', tag);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

results_csv = fullfile(out_dir, ['multicase_results_' tag '.csv']);
summary_csv = fullfile(out_dir, ['multicase_summary_stats_' tag '.csv']);
family_csv  = fullfile(out_dir, ['multicase_summary_by_family_' tag '.csv']);
md_file     = fullfile(out_dir, ['multicase_summary_' tag '.md']);
mat_file    = fullfile(out_dir, ['suite_summary_' tag '.mat']);

writetable(T, results_csv);
writetable(stats.summary_all, summary_csv);
writetable(stats.summary_by_family, family_csv);

local_write_md(md_file, meta, T, stats, opts, results_csv, summary_csv, family_csv);

save(mat_file, 'T', 'stats', 'meta', 'opts');

disp(' ')
disp('=== [ch5r:phase4A] suite summary done ===')
disp(['results csv : ' results_csv])
disp(['summary csv : ' summary_csv])
disp(['family csv  : ' family_csv])
disp(stats.summary_all)
disp(stats.summary_by_family)

out = struct();
out.ok = true;
out.source_table = T;
out.meta = meta;
out.stats = stats;
out.paths = struct( ...
    'output_dir', out_dir, ...
    'results_csv', results_csv, ...
    'summary_csv', summary_csv, ...
    'family_csv', family_csv, ...
    'md_file', md_file, ...
    'mat_file', mat_file, ...
    'tag', tag);
end

function local_write_md(md_file, meta, T, stats, opts, results_csv, summary_csv, family_csv)
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Cannot open markdown file for writing.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Chapter 5 multicase summary\n\n');
fprintf(fid, '- source type: `%s`\n', local_to_char(meta.source_type));
fprintf(fid, '- source csv: `%s`\n', local_to_char(local_default(meta.csv_file, '')));
fprintf(fid, '- n rows: `%d`\n', height(T));
fprintf(fid, '- methods: `%s`\n', strjoin(cellstr(string(stats.methods)), ', '));
fprintf(fid, '- families: `%s`\n', strjoin(cellstr(string(stats.families)), ', '));
fprintf(fid, '- metrics: `%s`\n\n', strjoin(cellstr(string(opts.metrics)), ', '));

fprintf(fid, '## Output files\n\n');
fprintf(fid, '- results csv: `%s`\n', results_csv);
fprintf(fid, '- summary csv: `%s`\n', summary_csv);
fprintf(fid, '- family csv: `%s`\n\n', family_csv);

fprintf(fid, '## Overall summary\n\n');
fprintf(fid, '%s\n\n', local_table_to_md(stats.summary_all));

fprintf(fid, '## By-family summary\n\n');
fprintf(fid, '%s\n', local_table_to_md(stats.summary_by_family));
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
        v = T{i,j};
        vals{j} = local_scalar_to_char(v);
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

function x = local_default(x, y)
if isempty(x)
    x = y;
end
end

function c = local_to_char(x)
if ischar(x)
    c = x;
elseif isstring(x)
    if isempty(x)
        c = '';
    else
        c = char(x(1));
    end
else
    c = char(string(x));
end
end
