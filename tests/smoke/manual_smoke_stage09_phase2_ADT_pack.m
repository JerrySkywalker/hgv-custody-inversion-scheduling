function out = manual_smoke_stage09_phase2_ADT_pack(base)
%MANUAL_SMOKE_STAGE09_PHASE2_ADT_PACK
% Plot-only smoke: draw DA and DT Stage05-style packs from a precomputed base.

    clear functions;
    rehash;

    if nargin < 1 || isempty(base)
        error('manual_smoke_stage09_phase2_ADT_pack:MissingBase', ...
            ['A precomputed base struct is required.' newline ...
             'Run: base = manual_smoke_stage09_phase1_metric_views();']);
    end

    out = struct();

    fprintf('\n');
    fprintf('================ Phase2-B ADT Pack Smoke ================\n');
    fprintf('Using precomputed base only. No search will be rerun.\n');
    fprintf('Step 1: draw DA Stage05-pack\n');
    fprintf('Step 2: draw DT Stage05-pack\n');
    fprintf('=========================================================\n\n');

    packDA = plot_stage09_DA_stage05_pack(base, 'phase2_DA');
    packDT = plot_stage09_DT_stage05_pack(base, 'phase2_DT');

    out.base = base;
    out.packDA = packDA;
    out.packDT = packDT;

    fprintf('\n');
    fprintf('================ Phase2-B ADT Pack Summary ================\n');
    fprintf('DA figure index : %s\n', packDA.files.figure_index_csv);
    fprintf('DT figure index : %s\n', packDT.files.figure_index_csv);
    fprintf('===========================================================\n\n');
end
