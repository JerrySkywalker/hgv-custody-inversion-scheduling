function casebank = legacy_build_casebank_stage01_impl(cfg, opts)
%LEGACY_BUILD_CASEBANK_STAGE01_IMPL Thin wrapper over frozen legacy Stage01.

if nargin < 2
    opts = struct();
end

casebank = build_casebank_stage01(cfg, opts);
end
