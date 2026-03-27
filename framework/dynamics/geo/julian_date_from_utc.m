function jd = julian_date_from_utc(utc_input)
    %JULIAN_DATE_FROM_UTC Convert UTC datetime/string to Julian Date.
    %
    % Input can be:
    %   - datetime
    %   - char / string in a datetime-readable format
    
        if ischar(utc_input) || isstring(utc_input)
            dt = datetime(utc_input, 'TimeZone', 'UTC');
        elseif isa(utc_input, 'datetime')
            dt = utc_input;
            if isempty(dt.TimeZone)
                dt.TimeZone = 'UTC';
            end
        else
            error('Unsupported utc_input type.');
        end
    
        y = year(dt);
        m = month(dt);
        d = day(dt);
        hr = hour(dt);
        mi = minute(dt);
        se = second(dt);
    
        frac_day = (hr + mi/60 + se/3600) / 24;
    
        idx = m <= 2;
        y(idx) = y(idx) - 1;
        m(idx) = m(idx) + 12;
    
        A = floor(y/100);
        B = 2 - A + floor(A/4);
    
        jd = floor(365.25*(y + 4716)) + floor(30.6001*(m + 1)) + d + B - 1524.5 + frac_day;
    end
