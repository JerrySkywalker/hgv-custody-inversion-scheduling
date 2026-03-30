function out = manual_smoke_stage09_phase3_joint_closure_pack(base)
%MANUAL_SMOKE_STAGE09_PHASE3_JOINT_CLOSURE_PACK
% Plot-only smoke for Phase3-A joint closure pack.
%
% Usage:
%   base = manual_smoke_stage09_phase1_metric_views();
%   out  = manual_smoke_stage09_phase3_joint_closure_pack(base);

    clear functions;
    rehash;

    if nargin < 1 || isempty(base)
        error('manual_smoke_stage09_phase3_joint_closure_pack:MissingBase', ...
            ['A precomputed base struct is required.' newline ...
             'Run: base = manual_smoke_stage09_phase1_metric_views();']);
    end

    fprintf('\n');
    fprintf('================ Phase3-A Joint Closure Smoke ================\n');
    fprintf('Using precomputed base only. No search will be rerun.\n');
    fprintf('Export joint closure formal pack.\n');
    fprintf('==============================================================\n\n');

    out = struct();
    out.base = base;
    out.packJointClosure = plot_stage09_joint_closure_pack(base, 'phase3_joint');

    fprintf('\n');
    fprintf('================ Phase3-A Joint Closure Summary ================\n');
    fprintf('Joint closure index : %s\n', out.packJointClosure.files.figure_index_csv);
    fprintf('===============================================================\n\n');
end
