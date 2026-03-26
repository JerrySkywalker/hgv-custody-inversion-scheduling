function out = manual_smoke_stage05_legacy_passratio_family_validation()
startup;

artifact_root = fullfile('outputs','experiments','chapter4','stage05_passratio_family_validation','smoke');
out = run_stage05_legacy_passratio_family_validation('artifact_root', artifact_root);

disp('[manual] Stage05 legacy passratio family validation completed.');
disp(out.summary_table);
disp(out.compare_csv);
disp(out.summary_csv);
disp(out.figure_legacy);
disp(out.figure_engine);
disp(out.figure_overlay);
disp(out.manifest_txt);
end
