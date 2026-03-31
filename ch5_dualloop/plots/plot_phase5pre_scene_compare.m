function fig = plot_phase5pre_scene_compare(sceneSummary, out_png)
%PLOT_PHASE5PRE_SCENE_COMPARE  Compare stress96 vs ref128 scene summaries.

scene_names = string({sceneSummary.scene});
cand_mean = [sceneSummary.cand_mean];
T_rmse = [sceneSummary.T_mean_rmse];
S_rmse = [sceneSummary.S_mean_rmse];
C_rmse = [sceneSummary.C_mean_rmse];

fig = figure('Visible', 'off');

subplot(2,1,1)
bar(categorical(scene_names), cand_mean);
ylabel('Mean Candidate Count')
title('Chapter 5 Phase 5-pre Scene Reference Layer')
grid on

subplot(2,1,2)
vals = [T_rmse(:), S_rmse(:), C_rmse(:)];
bar(categorical(scene_names), vals);
ylabel('Mean RMSE')
legend({'T','S','C'}, 'Location', 'best')
grid on

if nargin >= 2 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
