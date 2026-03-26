function res = run_stage05_closedd_manual_raan_experiment(varargin)
%RUN_STAGE05_CLOSEDD_MANUAL_RAAN_EXPERIMENT Run Stage05/ClosedD manual-RAAN experiment.

spec = make_stage05_closedd_manual_raan_spec(varargin{:});
res = run_search_experiment(spec);
end
