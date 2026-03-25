function casebank = build_casebank_nominal(engine_cfg)
%BUILD_CASEBANK_NOMINAL Build the nominal target casebank subset.
% Input:
%   engine_cfg : engine configuration tree; defaults to default_params()
%
% Output:
%   casebank   : struct with .meta and .nominal fields

if nargin < 1 || isempty(engine_cfg)
    engine_cfg = default_params();
end

legacy_casebank = build_casebank(engine_cfg);

casebank = struct();
casebank.meta = legacy_casebank.meta;
casebank.nominal = legacy_casebank.nominal;
casebank.source = 'engine_stage01';
end
