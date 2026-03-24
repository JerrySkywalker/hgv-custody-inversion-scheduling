function outs = run_all_milestones(cfg_override)
%RUN_ALL_MILESTONES Run dissertation milestone workflow MA -> ME.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
    addpath(fullfile(proj_root, 'run_milestones'));
end
startup();

cfg = milestone_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

fprintf('[run_milestones] ===== Running MA -> ME =====\n');

outs = struct();
outs.MA = milestone_A_truth_baseline(cfg);
outs.MB = milestone_B_inverse_slices(cfg);
outs.MC = milestone_C_window_scale(cfg);
outs.MD = milestone_D_fft_support(cfg);
outs.ME = milestone_E_worst_window_diagnosis(cfg);

summary_file = fullfile(cfg.paths.milestones, 'milestone_summary_report.md');
fid = fopen(summary_file, 'w');
if fid < 0
    error('Failed to write milestone summary report: %s', summary_file);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Milestone Summary Report\n\n');
fprintf(fid, 'Generated at `%s`.\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '## Completed milestones\n\n');
fprintf(fid, '- MA\n- MB\n- MC\n- MD\n- ME\n\n');
fprintf(fid, '## Milestone conclusions\n\n');
local_write_summary_block(fid, outs.MA);
local_write_summary_block(fid, outs.MB);
local_write_summary_block(fid, outs.MC);
local_write_summary_block(fid, outs.MD);
local_write_summary_block(fid, outs.ME);

outs.summary_report = string(summary_file);
fprintf('[run_milestones] Summary report: %s\n', summary_file);
fprintf('[run_milestones] ===== All milestones complete =====\n');
end

function local_write_summary_block(fid, out)
fprintf(fid, '### %s `%s`\n\n', out.milestone_id, out.title);
fprintf(fid, '%s\n\n', local_pick_conclusion(out));
fprintf(fid, '- report: `%s`\n', local_pick_path(out.artifacts, 'summary_report'));
fprintf(fid, '- tables: `%s`\n', strjoin(local_struct_paths(out.tables), '`, `'));
fprintf(fid, '- figures: `%s`\n\n', strjoin(local_struct_paths(out.figures), '`, `'));
end

function txt = local_pick_conclusion(out)
txt = 'No milestone conclusion available.';
if isfield(out, 'summary') && isfield(out.summary, 'main_conclusion')
    txt = char(string(out.summary.main_conclusion));
end
end

function txt = local_pick_path(S, field_name)
txt = '';
if isstruct(S) && isfield(S, field_name)
    txt = char(string(S.(field_name)));
end
end

function paths = local_struct_paths(S)
names = fieldnames(S);
if isempty(names)
    paths = {''};
    return;
end
paths = cell(1, numel(names));
for k = 1:numel(names)
    paths{k} = char(string(S.(names{k})));
end
end
