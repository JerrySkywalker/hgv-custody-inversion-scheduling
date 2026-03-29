function pkg = stage14_formal_package_joint_phase_orientation(grid_out, post_out, cfg, opts)
%STAGE14_FORMAL_PACKAGE_JOINT_PHASE_ORIENTATION
% Official formal export layer for Stage14.4 joint phase-orientation analysis.

    if nargin < 1 || isempty(grid_out)
        error('grid_out is required.');
    end
    if nargin < 2 || isempty(post_out)
        error('post_out is required.');
    end
    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 4 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.scope_name = "A1";
    local.output_dir = fullfile(cfg.paths.outputs, 'stage', 'stage14');
    local.timestamp = string(datestr(now, 'yyyymmdd_HHMMSS'));
    local.save_table = true;
    local.save_markdown = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    if ~exist(local.output_dir, 'dir')
        mkdir(local.output_dir);
    end

    scope = char(local.scope_name);
    tag = char(local.timestamp);

    bestF_csv = fullfile(local.output_dir, sprintf('stage14_%s_bestF_table_%s.csv', scope, tag));
    robust_stats_csv = fullfile(local.output_dir, sprintf('stage14_%s_robust_stats_%s.csv', scope, tag));
    dgmin_switch_csv = fullfile(local.output_dir, sprintf('stage14_%s_bestF_DGmin_counts_%s.csv', scope, tag));
    key_summary_csv = fullfile(local.output_dir, sprintf('stage14_%s_key_summary_%s.csv', scope, tag));
    formal_md = fullfile(local.output_dir, sprintf('stage14_%s_formal_summary_%s.md', scope, tag));

    if local.save_table
        writetable(post_out.bestF_table, bestF_csv);
        writetable(post_out.robust_stats_table, robust_stats_csv);
        writetable(post_out.dgmin_switch_table, dgmin_switch_csv);
        writetable(post_out.key_summary, key_summary_csv);
    end

    if local.save_markdown
        fid = fopen(formal_md, 'w');
        assert(fid > 0, 'Failed to open markdown output file.');
        cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
        fprintf(fid, '%s\n', post_out.formal_summary_md);
    end

    pkg = struct();
    pkg.scope_name = local.scope_name;
    pkg.out_dir = local.output_dir;
    pkg.bestF_csv = bestF_csv;
    pkg.robust_stats_csv = robust_stats_csv;
    pkg.dgmin_switch_csv = dgmin_switch_csv;
    pkg.key_summary_csv = key_summary_csv;
    pkg.formal_md = formal_md;
    pkg.key_summary = post_out.key_summary;

    if isstruct(grid_out) && isfield(grid_out, 'files')
        pkg.raw_grid_files = grid_out.files;
    end

    if ~local.quiet
        fprintf('\n=== Stage14.4 Formal Package (%s) ===\n', scope);
        fprintf('output dir         : %s\n', pkg.out_dir);
        fprintf('bestF csv          : %s\n', pkg.bestF_csv);
        fprintf('robust stats csv   : %s\n', pkg.robust_stats_csv);
        fprintf('DGmin switch csv   : %s\n', pkg.dgmin_switch_csv);
        fprintf('key summary csv    : %s\n', pkg.key_summary_csv);
        fprintf('formal markdown    : %s\n\n', pkg.formal_md);

        fprintf('--- key_summary ---\n');
        disp(pkg.key_summary)

        fprintf('--- dgmin_switch_table ---\n');
        disp(post_out.dgmin_switch_table)

        fprintf('--- markdown preview ---\n');
        disp(post_out.formal_summary_md)
    end
end
