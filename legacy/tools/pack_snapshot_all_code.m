function zipFilePath = pack_snapshot_all_code()
%PACK_SNAPSHOT_ALL_CODE  Create a working-tree code-only snapshot zip.
%
% Packages the current working directory without including any outputs/
% paper assets or reports.
%
% Filename:
%   yyyymmdd_HHMMSS_<branch>_working_code.zip
%
% Usage (from MATLAB):
%   zipPath = pack_snapshot_all_code();

    zipFilePath = pack_snapshot_all(false, false, 'working_code');
end
