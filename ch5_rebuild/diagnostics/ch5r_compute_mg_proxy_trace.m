function mg = ch5r_compute_mg_proxy_trace(ch5case, selection_trace)
%CH5R_COMPUTE_MG_PROXY_TRACE
% Current-shell MG proxy:
% rolling min-eigenvalue of windowed position Fisher information.
%
% This is shell-aligned, not a literal copy of cpt2 compute_MG.m.
% It preserves the Chapter 2 semantics:
%   MG = directional observability lower-bound over a window.

Nt = numel(ch5case.t_s);
left_steps  = ch5case.window.left_steps;
right_steps = ch5case.window.right_steps;

Jcum = zeros(3,3,Nt+1);
for k = 1:Nt
    Jk = zeros(3,3);
    if k <= numel(selection_trace) && isstruct(selection_trace{k}) ...
            && isfield(selection_trace{k}, 'J_pair') && ~isempty(selection_trace{k}.J_pair)
        Jk = selection_trace{k}.J_pair;
    end
    Jcum(:,:,k+1) = Jcum(:,:,k) + Jk;
end

mg.valid = false(Nt,1);
mg.value = nan(Nt,1);
mg.left_steps = left_steps;
mg.right_steps = right_steps;

for k = 1:Nt
    s0 = k - left_steps;
    s1 = k + right_steps;
    if s0 < 1 || s1 > Nt
        continue;
    end

    Yw = Jcum(:,:,s1+1) - Jcum(:,:,s0);
    Yw = 0.5 * (Yw + Yw');
    mg.value(k) = min(real(eig(Yw)));
    mg.valid(k) = true;
end
end
