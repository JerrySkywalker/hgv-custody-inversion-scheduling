function satbank = propagate_constellation_stage03(walker, t_s)
    %PROPAGATE_CONSTELLATION_STAGE03 Propagate a simple circular Walker constellation.
    %
    % Output:
    %   satbank.r_eci_km : Nt x 3 x Ns
    
        mu_km3_s2 = 398600.4418;
        Re_km = 6378.137;
    
        Nt = numel(t_s);
        Ns = walker.Ns;
    
        r_eci_km = zeros(Nt, 3, Ns);
    
        a_km = Re_km + walker.h_km;
        n_rad_s = sqrt(mu_km3_s2 / a_km^3);
    
        for s = 1:Ns
            sat = walker.sat(s);
    
            i = deg2rad(sat.i_deg);
            Omega = deg2rad(sat.raan_deg);
            M0 = deg2rad(sat.M0_deg);
    
            for k = 1:Nt
                M = M0 + n_rad_s * t_s(k);   % circular orbit => true anomaly ~ mean anomaly
                u = M;
    
                r_pf = [a_km*cos(u); a_km*sin(u); 0];
    
                R3_Omega = [ cos(Omega), -sin(Omega), 0;
                             sin(Omega),  cos(Omega), 0;
                             0,           0,          1 ];
                R1_i = [1, 0, 0;
                        0, cos(i), -sin(i);
                        0, sin(i),  cos(i)];
    
                r_eci = R3_Omega * R1_i * r_pf;
                r_eci_km(k,:,s) = r_eci(:).';
            end
        end
    
        satbank = struct();
        satbank.t_s = t_s(:);
        satbank.r_eci_km = r_eci_km;
        satbank.Ns = Ns;
        satbank.walker = walker;
    end