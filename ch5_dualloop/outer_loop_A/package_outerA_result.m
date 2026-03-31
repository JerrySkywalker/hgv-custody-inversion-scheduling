function outerA = package_outerA_result(time, mr_hat, mr_tilde, omega_max_series, risk_state, risk_quadrant, lead_time_steps)
%PACKAGE_OUTERA_RESULT  Standard package for standalone outerA outputs.

outerA = struct();
outerA.time = time(:);
outerA.mr_hat = mr_hat(:);
outerA.mr_tilde = mr_tilde(:);
outerA.omega_max = omega_max_series(:);
outerA.risk_state = risk_state(:);
outerA.risk_quadrant = risk_quadrant(:);
outerA.lead_time_steps = lead_time_steps(:);
end
