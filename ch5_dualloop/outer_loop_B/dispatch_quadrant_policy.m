function mode = dispatch_quadrant_policy(risk_state_now)
%DISPATCH_QUADRANT_POLICY  Map outerA risk_state to CK mode.
%
% mode:
%   'safe'
%   'warn'
%   'trigger'

if risk_state_now <= 0
    mode = 'safe';
elseif risk_state_now == 1
    mode = 'warn';
else
    mode = 'trigger';
end
end
