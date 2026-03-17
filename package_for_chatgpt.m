function zipFilePath = package_for_chatgpt(include_milestone_outputs)
%PACKAGE_FOR_CHATGPT Backward-compatible wrapper for pack_snapshot_all.

if nargin < 1
    include_milestone_outputs = [];
end

zipFilePath = pack_snapshot_all(include_milestone_outputs);
end
