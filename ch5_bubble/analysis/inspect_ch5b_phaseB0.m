function inspect_ch5b_phaseB0()
%INSPECT_CH5B_PHASEB0 Simple inspection entry for Phase B0.

cfg = default_ch5b_params();

disp('=== inspect_ch5b_phaseB0 ===');
disp(cfg.framework);
disp(cfg.path);
disp(cfg.output);
disp(cfg.trajectory);
disp(cfg.policy);
disp(cfg.metrics);

end
