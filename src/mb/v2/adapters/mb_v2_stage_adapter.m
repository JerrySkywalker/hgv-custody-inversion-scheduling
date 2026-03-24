function request = mb_v2_stage_adapter(stage_name, options)
%MB_V2_STAGE_ADAPTER Define the MB_v2 adapter contract for trusted Stage kernels.
% Inputs:
%   stage_name - string or char naming the trusted Stage capability to wrap.
%   options    - struct carrying read-only adapter options and requested outputs.
% Output:
%   request    - struct describing the adapter contract for a future wrapper call.
% TODO:
%   Implement read-only wrappers that call Stage05/06 without modifying Stage files.

if nargin < 1 || strlength(string(stage_name)) == 0
    stage_name = "unassigned";
end
if nargin < 2 || isempty(options)
    options = struct();
end

request = struct();
request.stage_name = string(stage_name);
request.status = "not_implemented";
request.options = options;
request.allowed_behavior = "wrapper_only";
request.note = "MB_v2 may reuse trusted Stage kernels only through adapters.";
end
