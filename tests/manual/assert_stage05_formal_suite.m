function assert_stage05_formal_suite()
startup;

out = manual_smoke_stage05_formal_suite();

assert(height(out.legacy_reproduction.grid_table) == 6, ...
    'Unexpected legacy reproduction row count in formal suite smoke.');

assert(height(out.opend_manual_raan.grid_table) == 18, ...
    'Unexpected OpenD manual-RAAN row count in formal suite smoke.');

assert(height(out.closedd_manual_raan.grid_table) == 18, ...
    'Unexpected ClosedD manual-RAAN row count in formal suite smoke.');

assert(all(ismember({'design_id','P','T','Ns'}, out.legacy_reproduction.grid_table.Properties.VariableNames)), ...
    'Legacy reproduction grid_table is missing required columns.');

assert(all(ismember({'design_id','P','T','Ns'}, out.opend_manual_raan.grid_table.Properties.VariableNames)), ...
    'OpenD manual-RAAN grid_table is missing required columns.');

assert(all(ismember({'design_id','P','T','Ns'}, out.closedd_manual_raan.grid_table.Properties.VariableNames)), ...
    'ClosedD manual-RAAN grid_table is missing required columns.');

assert(isfile(char(out.manifest.manifest_mat)), ...
    'Formal suite manifest MAT file was not created.');

assert(isfile(char(out.manifest.manifest_txt)), ...
    'Formal suite manifest TXT file was not created.');

disp('assert_stage05_formal_suite passed.');
end
