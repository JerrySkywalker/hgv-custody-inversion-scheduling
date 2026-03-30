function out = manual_smoke_stage09_phase2_ADT_pack()
%MANUAL_SMOKE_STAGE09_PHASE2_ADT_PACK
% Run Phase1-B metric-view smoke once, then draw DA and DT Stage05-style packs.

    clear functions;
    rehash;

    out = struct();

    fprintf('\n');
    fprintf('================ Phase2-B ADT Pack Smoke ================\n');
    fprintf('Step 1: build/rebuild metric views and frontiers\n');
    fprintf('Step 2: draw DA Stage05-pack\n');
    fprintf('Step 3: draw DT Stage05-pack\n');
    fprintf('=========================================================\n\n');

    base = manual_smoke_stage09_phase1_metric_views();

    packDA = plot_stage09_DA_stage05_pack(base, 'phase2_DA');
    packDT = plot_stage09_DT_stage05_pack(base, 'phase2_DT');

    out.base = base;
    out.packDA = packDA;
    out.packDT = packDT;
    out.cfg = base.cfg;

    fprintf('\n');
    fprintf('================ Phase2-B ADT Pack Summary ================\n');
    fprintf('DA figure index : %s\n', packDA.files.figure_index_csv);
    fprintf('DT figure index : %s\n', packDT.files.figure_index_csv);
    fprintf('===========================================================\n\n');
end
