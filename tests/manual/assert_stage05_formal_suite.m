function assert_stage05_formal_suite()
startup;

out = manual_smoke_stage05_formal_suite();

assert(isequal(size(out.legacy_reproduction.grid_table), [6 26]), ...
    'Unexpected legacy reproduction grid size in formal suite smoke.');

assert(isequal(size(out.opend_manual_raan.grid_table), [18 32]), ...
    'Unexpected OpenD manual-RAAN grid size in formal suite smoke.');

assert(isequal(size(out.closedd_manual_raan.grid_table), [18 35]), ...
    'Unexpected ClosedD manual-RAAN grid size in formal suite smoke.');

assert(isfile(char(out.manifest.manifest_mat)), ...
    'Formal suite manifest MAT file was not created.');

assert(isfile(char(out.manifest.manifest_txt)), ...
    'Formal suite manifest TXT file was not created.');

disp('assert_stage05_formal_suite passed.');
end
