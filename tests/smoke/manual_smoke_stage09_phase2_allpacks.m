function out = manual_smoke_stage09_phase2_allpacks(base)
%MANUAL_SMOKE_STAGE09_PHASE2_ALLPACKS
% Plot-only smoke: generate DG / DA / DT / joint Stage05-style packs from a precomputed base.

    clear functions;
    rehash;

    if nargin < 1 || isempty(base)
        error('manual_smoke_stage09_phase2_allpacks:MissingBase', ...
            ['A precomputed base struct is required.' newline ...
             'Run: base = manual_smoke_stage09_phase1_metric_views();']);
    end

    out = struct();

    fprintf('\n');
    fprintf('================ Phase2-C All-Packs Smoke ================\n');
    fprintf('Using precomputed base only. No search will be rerun.\n');
    fprintf('Export DG / DA / DT / joint packs.\n');
    fprintf('==========================================================\n\n');

    packDG = plot_stage09_DG_stage05_pack(base, 'phase2_DG');
    packDA = plot_stage09_DA_stage05_pack(base, 'phase2_DA');
    packDT = plot_stage09_DT_stage05_pack(base, 'phase2_DT');
    packJ  = plot_stage09_joint_stage05_pack(base, 'phase2_joint');

    out.base = base;
    out.packDG = packDG;
    out.packDA = packDA;
    out.packDT = packDT;
    out.packJoint = packJ;

    fprintf('\n');
    fprintf('================ Phase2-C All-Packs Summary ================\n');
    fprintf('DG    index : %s\n', packDG.files.figure_index_csv);
    fprintf('DA    index : %s\n', packDA.files.figure_index_csv);
    fprintf('DT    index : %s\n', packDT.files.figure_index_csv);
    fprintf('Joint index : %s\n', packJ.files.figure_index_csv);
    fprintf('============================================================\n\n');
end
