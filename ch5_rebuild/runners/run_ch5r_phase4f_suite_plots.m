function out = run_ch5r_phase4f_suite_plots(opts)
%RUN_CH5R_PHASE4F_SUITE_PLOTS
% Plot-only layer for multicase suite.
% No suite recomputation is performed.

if nargin < 1 || isempty(opts)
    opts = struct();
end

assert(isfield(opts, 'suite_source') && ~isempty(opts.suite_source), 'suite_source is required');
assert(isfield(opts, 'summary_source') && ~isempty(opts.summary_source), 'summary_source is required');
assert(isfield(opts, 'case_wins_source') && ~isempty(opts.case_wins_source), 'case_wins_source is required');

if ~isfield(opts, 'visible_mode') || isempty(opts.visible_mode)
    opts.visible_mode = 'off';
end

if isfield(opts, 'outdir_override') && ~isempty(opts.outdir_override)
    outdir = opts.outdir_override;
else
    stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    outdir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite', 'figs', ['phase4f_suite_plots_' stamp]);
end
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

[T, meta] = ch5r_load_suite_table(opts.suite_source);
stats = local_load_stats(opts.summary_source);
wins  = local_load_wins(opts.case_wins_source);

box_metrics = {'LoC_ratio','bubble_time_s','max_bubble_depth','switch_count'};
out_box = plot_ch5r_suite_boxplots(T, box_metrics, outdir, opts.visible_mode);
out_occ = plot_ch5r_suite_family_state_bars(stats.summary_by_family, outdir, opts.visible_mode);
out_win = plot_ch5r_suite_case_wins(wins.overall, wins.by_family, outdir, opts.visible_mode);
out_uq  = plot_ch5r_suite_upper_quartile_bars(stats.summary_all, 'LoC_ratio', outdir, opts.visible_mode);

md_file = fullfile(outdir, 'phase4f_suite_plots_manifest.md');
local_write_md(md_file, outdir, meta, out_box, out_occ, out_win, out_uq);

disp(' ')
disp('=== [ch5r:phase4F] suite plots done ===')
disp(outdir)

out = struct();
out.ok = true;
out.output_dir = outdir;
out.md_file = md_file;
out.meta = meta;
out.boxplots = out_box;
out.family_state = out_occ;
out.case_wins = out_win;
out.upper_quartile = out_uq;
end

function stats = local_load_stats(src)
if isstruct(src) && isfield(src, 'stats')
    stats = src.stats;
    return;
end
if ischar(src) || isstring(src)
    S = load(char(string(src)));
    if isfield(S, 'stats')
        stats = S.stats;
        return;
    end
end
error('Cannot load summary stats from summary_source.');
end

function wins = local_load_wins(src)
if isstruct(src) && isfield(src, 'wins')
    wins = src.wins;
    return;
end
if ischar(src) || isstring(src)
    S = load(char(string(src)));
    if isfield(S, 'wins')
        wins = S.wins;
        return;
    end
end
error('Cannot load wins from case_wins_source.');
end

function local_write_md(md_file, outdir, meta, out_box, out_occ, out_win, out_uq)
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Cannot open markdown manifest for writing.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Phase 4F plot manifest\n\n');
fprintf(fid, '- output dir: `%s`\n', outdir);
fprintf(fid, '- source type: `%s`\n', local_to_char(meta.source_type));
fprintf(fid, '- source csv: `%s`\n\n', local_to_char(local_default(meta.csv_file, '')));

fprintf(fid, '## Boxplots\n\n');
fns = fieldnames(out_box.files);
for i = 1:numel(fns)
    fprintf(fid, '- `%s`: `%s`\n', fns{i}, out_box.files.(fns{i}).png);
end

fprintf(fid, '\n## Family state occupancy\n\n');
fprintf(fid, '- `%s`\n', out_occ.png_file);

fprintf(fid, '\n## Case wins\n\n');
fprintf(fid, '- `%s`\n', out_win.png_file);

fprintf(fid, '\n## Upper quartile bar\n\n');
fprintf(fid, '- `%s`\n', out_uq.png_file);
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
