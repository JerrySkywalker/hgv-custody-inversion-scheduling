function ok = smoke_clean_outputs()
%SMOKE_CLEAN_OUTPUTS Minimal smoke test for clean_outputs.

    ok = false;
    root_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    tmp_base = fullfile(root_dir, 'outputs', 'stage', 'smoke_clean_outputs_tmp');
    tmp_file = fullfile(tmp_base, 'dummy.txt');

    if isfolder(tmp_base)
        rmdir(tmp_base, 's');
    end
    mkdir(tmp_base);

    fid = fopen(tmp_file, 'w');
    assert(fid > 0, 'Failed to create dummy file.');
    fprintf(fid, 'smoke');
    fclose(fid);

    fprintf('[smoke_clean_outputs] created: %s\n', tmp_file);

    % dry-run: should not delete
    clean_outputs('execute', false, 'targets', {'stage'});
    assert(isfile(tmp_file), 'Dry-run should not delete files.');

    % execute: should delete the temporary subtree
    clean_outputs('execute', true, 'targets', {'stage'});
    assert(~isfolder(tmp_base), 'Execute mode should delete temporary directory.');

    fprintf('[smoke_clean_outputs] PASS\n');
    ok = true;
end
