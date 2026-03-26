function out = manual_smoke_stage05_formal_suite_assets()
startup;

out = manual_smoke_stage05_formal_suite();

disp('[manual] Stage05 formal suite assets summary');
disp(out.manifest.manifest_mat);
disp(out.manifest.manifest_txt);
disp(out.summary_exports.summary_csv);
disp(out.summary_exports.summary_mat);
disp(out.figure_exports.manifest_txt);
disp(out.figure_exports.files);
end
