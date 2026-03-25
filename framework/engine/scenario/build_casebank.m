function casebank = build_casebank(engine_cfg, options)
%BUILD_CASEBANK Build the generic scenario casebank.
% Inputs:
%   engine_cfg : engine configuration tree; defaults to default_params()
%   options    : optional Stage01 build options
%
% Output:
%   casebank   : struct with .meta, .nominal, .heading, .critical

if nargin < 1 || isempty(engine_cfg)
    engine_cfg = default_params();
end
if nargin < 2
    options = struct();
end

casebank = legacy_build_casebank_stage01_impl(engine_cfg, options);
casebank.source = 'engine_scenario';
end
