function zipFilePath = package_for_chatgpt_baseline(includeDeliverables, include_milestone_outputs)
%PACKAGE_FOR_CHATGPT_BASELINE Backward-compatible wrapper for pack_snapshot_head.

if nargin < 1
    includeDeliverables = [];
end
if nargin < 2
    include_milestone_outputs = [];
end

zipFilePath = pack_snapshot_head(includeDeliverables, include_milestone_outputs);
end
