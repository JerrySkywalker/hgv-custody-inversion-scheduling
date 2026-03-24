function zipFilePath = pack_snapshot_head_code()
%PACK_SNAPSHOT_HEAD_CODE  Create a HEAD code-only snapshot zip.
%
% Packages the latest committed version without including deliverables/ or
% tracked outputs/ paper assets.
%
% Filename:
%   yyyymmdd_HHMMSS_<branch>_head_code.zip
%
% Usage (from MATLAB):
%   zipPath = pack_snapshot_head_code();

    zipFilePath = pack_snapshot_head(false, false, 'head_code');
end
