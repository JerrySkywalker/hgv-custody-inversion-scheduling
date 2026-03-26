function out = manual_smoke_stage05_passratio_profile_plot()
startup;

products = run_stage05_scan_products( ...
    'preset', 'legacy_stage05_strict', ...
    'artifact_root', fullfile('outputs','experiments','chapter4','stage05_passratio_profile_plot','products'), ...
    'show_progress', false);

fig = plot_stage05_passratio_profile(products.scan.passratio_profile, ...
    'visible', 'off', ...
    'title', 'Stage05 pass-ratio profile versus Ns');

fig_dir = fullfile('outputs','experiments','chapter4','stage05_passratio_profile_plot','figures');
if exist(fig_dir, 'dir') ~= 7
    mkdir(fig_dir);
end

png_path = save_figure_artifact(fig, struct( ...
    'output_dir', fig_dir, ...
    'file_name', 'stage05_passratio_profile_strict.png'));

out = struct();
out.products = products;
out.png_path = string(png_path);

disp('[manual] Stage05 passratio profile strict plot completed.');
disp(out.products.meta.profile_name);
disp(out.png_path);
end
