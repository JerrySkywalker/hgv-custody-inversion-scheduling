function is_better = compare_bubble_correction_candidates(candA, candB)
%COMPARE_BUBBLE_CORRECTION_CANDIDATES Lexicographic comparison for bubble correction.
%
% Priority:
%   1) maximize Xi_B
%   2) maximize tau_B_time_s (inf is best)
%   3) minimize A_B
%   4) minimize switch_cost
%   5) minimize resource_cost

assert(isstruct(candA) && isstruct(candB), 'Inputs must be structs.');

if candA.Xi_B > candB.Xi_B
    is_better = true;
    return;
elseif candA.Xi_B < candB.Xi_B
    is_better = false;
    return;
end

tauA = candA.tau_B_time_s;
tauB = candB.tau_B_time_s;

if tauA > tauB
    is_better = true;
    return;
elseif tauA < tauB
    is_better = false;
    return;
end

if candA.A_B < candB.A_B
    is_better = true;
    return;
elseif candA.A_B > candB.A_B
    is_better = false;
    return;
end

if candA.switch_cost < candB.switch_cost
    is_better = true;
    return;
elseif candA.switch_cost > candB.switch_cost
    is_better = false;
    return;
end

if candA.resource_cost < candB.resource_cost
    is_better = true;
    return;
elseif candA.resource_cost > candB.resource_cost
    is_better = false;
    return;
end

is_better = false;
end
