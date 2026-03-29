function out = manual_smoke_stage14_4_step1(cfg, overrides)
%MANUAL_SMOKE_STAGE14_4_STEP1
% First formal smoke entry for Stage14.4:
%   1) B1 joint phase-orientation raw grid
%   2) B2 / B2-dual postprocess
%   3) formal package export

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    raw = stage14_joint_phase_orientation(cfg, overrides);
    post = stage14_joint_phase_orientation_postprocess(raw, cfg);
    pkg = stage14_joint_phase_orientation_formal_package(raw, post, cfg);

    out = struct();
    out.raw = raw;
    out.post = post;
    out.pkg = pkg;

    fprintf('\n=== Stage14.4 step1 smoke summary ===\n');
    if isfield(post, 'bestF_table')
        fprintf('bestF rows       : %d\n', height(post.bestF_table));
    end
    if isfield(post, 'robust_stats_table')
        fprintf('robust stats rows: %d\n', height(post.robust_stats_table));
    end
    if isfield(pkg, 'files')
        disp(pkg.files)
    end
end
