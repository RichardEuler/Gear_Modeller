function r_f0 = toolRootRounding(m_n)
    % toolRootRounding — Return the hob tool root rounding radius per CSN 01 4608.
    %
    %   r_f0 = toolRootRounding(m_n)
    %
    % This function is shared by all generator classes to avoid code
    % duplication of the rounding-radius look-up table.

    if m_n < 1
        r_f0 = 0.1;
    elseif m_n < 2
        r_f0 = 0.2;
    elseif m_n < 4.5
        r_f0 = 0.5;
    elseif m_n < 7
        r_f0 = 1;
    elseif m_n < 10
        r_f0 = 1.5;
    elseif m_n < 18
        r_f0 = 2;
    else
        r_f0 = 2.5;
    end
end
