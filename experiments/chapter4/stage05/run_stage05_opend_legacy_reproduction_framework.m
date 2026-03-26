function res = run_stage05_opend_legacy_reproduction_framework(varargin)
%RUN_STAGE05_OPEND_LEGACY_REPRODUCTION_FRAMEWORK Run framework reproduction of legacy Stage05 OpenD products.

spec = make_stage05_opend_legacy_reproduction_spec(varargin{:});
res = run_search_experiment(spec);
end
