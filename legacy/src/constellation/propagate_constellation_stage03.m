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

            u = M0 + n_rad_s * t_s(:);
            cu = cos(u);
            su = sin(u);

            cos_Omega = cos(Omega);
            sin_Omega = sin(Omega);
            cos_i = cos(i);
            sin_i = sin(i);

            x = a_km * (cos_Omega * cu - sin_Omega * cos_i .* su);
            y = a_km * (sin_Omega * cu + cos_Omega * cos_i .* su);
            z = a_km * (sin_i .* su);

            r_eci_km(:,:,s) = [x, y, z];
        end
    
        satbank = struct();
        satbank.t_s = t_s(:);
        satbank.r_eci_km = r_eci_km;
        satbank.Ns = Ns;
        satbank.walker = walker;
    end
