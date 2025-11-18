%% Gear Calculations
% The calculations are based around the sun gear having the given factor of
% safety, done by calculating the required gear module to achive it. 
%
% It doesn't gurantee that the other gears will have a factor of safety 
% above what is given. It will instead set the gears_pass flag to false if
% any are below the factor of safety.

function [gear_table, extra_data_table, T_s, efficiency_actual, ...
    gears_pass, overall_diameter] = calculate_gears(z_s, z_p1, z_r, ...
    z_p2, T_c, N_s, num_planets, yield_stress, safety_factor, ...
    mesh_efficiency, min_gear_module, face_width_sun, face_width_ring, ...
    round_ring_module)

    % Hardcoded pressure angle is 20 degrees, to change this requires
    % changing things that depend on it, like the lewis form factor
    % function.
    pressure_angle = 20; % degrees

    gear_ratio = 1 + (z_p1 * z_r) / (z_p2 * z_s);
    N_c = N_s / gear_ratio; % rpm of the carrier
    % Initial guess at the efficiency.
    efficiency_guess = efficiency_0(mesh_efficiency, z_s, z_r);
    % Torque at the sun gear.
    T_s = (T_c * N_c) / (efficiency_guess * (N_s - N_c) + N_c);
    % Efficiency based on input and output power.
    efficiency_actual = (T_c * N_c) / (T_s * N_s);
    
    % Lewis form factors
    Y_s = lewis_form_factor_interpolation(z_s);
    Y_p1 = lewis_form_factor_interpolation(z_p1);
    Y_r = lewis_form_factor_interpolation(z_r);
    Y_p2 = lewis_form_factor_interpolation(z_p2);
    
    % Calculate gear modules
    % By taking the equations for the tangential force, Lewis bending
    % stress, speed at the carrier and rearranging, the minimum sun gear
    % modulus can be found.
    numerator = 2 * T_c;
    denominator = (yield_stress / safety_factor) * num_planets * z_s * ...
         face_width_sun * Y_s * (efficiency_guess * (gear_ratio - 1)  + 1);
    module_sun = sqrt(numerator / denominator); % m
    
    % Ensure the module => minimum module
    if module_sun < min_gear_module
        module_sun = min_gear_module; % m
    end
    
    % Satisfy condition of coaxiality. The radius of the sun gear plus the
    % radius of its planet gear must equal the radius of the ring gear
    % minus its planet gear. This ensures the centre of the two planet
    % gears are coaxial. r_s + r_p1 = r_r - r_p2
    module_ring = module_sun / (z_r - z_p2) * (z_s + z_p1); % m

    % Scale both modules up to make the ring gear module equal the minimum.
    if module_ring < min_gear_module
        module_sun = module_sun * (min_gear_module / module_ring);
        module_ring = module_ring * (min_gear_module / module_ring);
    end

    % Round the ring gear module up to the nearest 0.25 mm.
    if round_ring_module
        rounding = 0.25e-3; % m
        new_module_ring = ceil(module_ring / rounding) * rounding;
        module_ratio = new_module_ring / module_ring;
        module_sun = module_sun * module_ratio;
        module_ring = module_ring * module_ratio;
    end
    
    % Diamter and radius
    d_s = module_sun * z_s; % m
    d_p1 = module_sun * z_p1; % m
    d_r = module_ring * z_r; % m
    d_p2 = module_ring * z_p2; % m
    
    r_s = d_s / 2; % m
    r_p1 = d_p1 / 2; % m
    r_r = d_r / 2; % m
    r_p2 = d_p2 / 2; % m
    r_c = r_s + r_p1; % m
    
    % Tangential force on gear teeth
    F_s = T_s / (num_planets * (r_s)); % N
    F_c = T_c / (num_planets * (r_c)); % N
    F_p2 = F_c / (1 + r_p2/r_p1); % N
    F_p1 = F_p2 * r_p2 / r_p1; % N
    F_r = F_p2 * efficiency_actual;
    
    % Calculate max bending stress in the gear tooth.
    stress_sun = bending_stress_lewis_eq( ...
        F_s, module_sun, face_width_sun, Y_s); % MPa
    
    stress_p1 = bending_stress_lewis_eq( ...
        F_p1, module_sun, face_width_sun, Y_p1); % MPa
    
    stress_ring = bending_stress_lewis_eq( ...
        F_r, module_ring, face_width_ring, Y_r); % MPa
    
    stress_p2 = bending_stress_lewis_eq( ...
        F_p2, module_ring, face_width_ring, Y_p2); % MPa
    
    % Create table to neatly display the results.
    names = {'Sun', 'Planet 1', 'Ring', 'Planet 2', 'Carrier'};

    num_teeth = [z_s, z_p1, z_r, z_p2, NaN];

    diameters = [d_s, d_p1, d_r, d_p2, r_c*2] * 1000; % mm

    modules = [module_sun, module_sun, ...
        module_ring, module_ring, NaN] * 1000; % mm

    stress_values = [stress_sun/1e6, ...
                     stress_p1/1e6, ...
                     stress_ring/1e6, ...
                     stress_p2/1e6, NaN]; % MPa

    factor_of_safety = [yield_stress/stress_sun, ...
                        yield_stress/stress_p1, ...
                        yield_stress/stress_ring, ...
                        yield_stress/stress_p2, NaN];

    % Revolutions Per Minute
    % Calculate the planet gear RPM with the two equations so that if they
    % don't equal then theres an issue
    RPM_planet_1 = (N_c * 2*r_c - N_s * d_s) / d_p1;
    RPM_planet_2 = -N_c * 2*r_c / d_p2;
    rotations = [N_s, RPM_planet_1, 0, RPM_planet_2, N_c]; % RPM

    % Pitch Line Velocity in m/s
    pitch_line_velocities = [
                    RPM_to_Pitchline_Velocity(rotations(1), d_s), ...
                    RPM_to_Pitchline_Velocity(rotations(2), d_p1), ...
                    RPM_to_Pitchline_Velocity(rotations(3), d_r), ...
                    RPM_to_Pitchline_Velocity(rotations(4), d_p2), ...
                    RPM_to_Pitchline_Velocity(rotations(5), r_c*2)];

    % Lewis Form Factors
    lewis_form_factors = [Y_s, Y_p1, Y_r, Y_p2, NaN];

    % Tangential Forces in gears and carrier
    tangential_forces = [F_s, F_p1, F_r, F_p2, F_c]; % N

    radial_forces = [F_s * tand(pressure_angle), ...
                     F_p1 * tand(pressure_angle), ...
                     F_r * tand(pressure_angle), ...
                     F_p2 * tand(pressure_angle), ...
                     NaN];

    torques = [T_s, F_p1 * r_p1, F_r * r_r * num_planets, ...
        F_p2 * r_p2, T_c]; % Torque at each gear and the carrier

    power = [power_from_RPM(rotations(1), torques(1)), ...
             power_from_RPM(rotations(2), torques(2)), ...
             power_from_RPM(rotations(3), torques(3)), ...
             power_from_RPM(rotations(4), torques(4)), ...
             power_from_RPM(rotations(5), torques(5))];

    face_widths = [face_width_sun * 1000, face_width_sun * 1000, ...
        face_width_ring * 1000, face_width_ring * 1000, NaN]; % mm
    
    gear_table = table(names', num_teeth', modules', diameters', ...
        face_widths', lewis_form_factors', stress_values', ...
        factor_of_safety', tangential_forces', radial_forces', ...
        torques', rotations', power', pitch_line_velocities', ...
        'VariableNames', {'Gear', 'Teeth', 'Module_mm', 'Diameter_mm', ...
        'Face_Width_mm', 'Lewis_Form_Factor', 'Stress_MPa', ...
        'Factor_Safety', 'Tan._Force_N', 'Rad._Force_N', 'Torque_Nm', ...
        'RPM', 'Power_W', 'V_rel_m_s'});
    %disp(gear_table);
    
    % Table to show additional data.
    % The difference in the radius of the ring gear and the radius of the
    % sun + diameter of planet_1.
    diameter_sun_p1 = (d_s + 2 * d_p1) * 1000; % mm
    overall_diameter = max(diameter_sun_p1, d_r); % mm

    extra_data_table = table(gear_ratio, diameter_sun_p1, ...
        overall_diameter, mesh_efficiency, efficiency_actual, ...
        num_planets, safety_factor, yield_stress/1e6, ...
        pressure_angle, ...
        'VariableNames', {'Gear_Ratio', 'Planet_Diamater_mm', ...
        'Overall_Diameter_mm', 'Eff._Mesh', 'Eff._Ack', 'Num_Planets', ...
        'Safety_Factor', 'S_y_MPa', 'Pressure_Angle_deg'});
    %disp(extra_data_table);

    % Check that the factors of safety for the 4 gears are greater 
    % than the specified factor of safety.
    if all(factor_of_safety(1:4) > safety_factor)
        gears_pass = true;
    else
        gears_pass = false;
    end
end

function efficiency = efficiency_0(mesh_efficiency, z_sun, z_ring)
    % Calculates the initial efficiency guess for the planet gear stage.
    % mesh_efficiency: The assumed mesh efficiency between two spur gears.
    % Z_sun: Number of teeth on the sun gear.
    % Z_ring: Number of teeth on the ring gear.
    R = z_ring / z_sun;
    L_p_r = (R-1)/(R+1) * (1 - mesh_efficiency);
    L_s_p = 1 - mesh_efficiency;
    efficiency = (1 - L_s_p) * (1 - L_p_r);
end

function lewis_factor = lewis_form_factor_interpolation(gear_teeth)
    % Interpolates the Lewis form factor for a 20-degress gear tooth based
    % on a table found at, 
    % https://www.engineersedge.com/gears/lewis-factor.htm,
    % The value for 'RACK' is included as 1000) for interpolation.
    teeth_values = [10; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20; 22; ...
                    24; 26; 28; 30; 32; 34; 36; 38; 40; 45; 50; 55; ...
                    60; 65; 70; 75; 80; 90; 100; 150; 200; 300; 1000]; 
    lewis_factor_values = ...
        [0.201; 0.226; 0.245; 0.264; 0.276; 0.289; 0.295; 0.302; 0.308; ...
         0.314; 0.320; 0.330; 0.337; 0.344; 0.352; 0.358; 0.364; 0.370; ...
         0.377; 0.383; 0.389; 0.399; 0.408; 0.415; 0.421; 0.425; 0.429; ...
         0.433; 0.436; 0.442; 0.446; 0.458; 0.463; 0.471; 0.484];
    lewis_factor = interp1(teeth_values, lewis_factor_values, ...
                           gear_teeth, 'linear');
    % Check if the interpolated value is within the range of the table
    if isnan(lewis_factor)
        fprintf('%i teeth entered is outside the range\n', gear_teeth);
    end
end

function stress = bending_stress_lewis_eq( ...
    force_tangential, ...
    gear_module, ...
    facewidth, ...
    lewis_form_factor)
    % Calculate the maximum bending stress in the gear tooth using the
    % Lewis equation.
    stress = force_tangential / ...
    (gear_module * facewidth * lewis_form_factor);
end

function velocity = RPM_to_Pitchline_Velocity(RPM, diameter)
    % Calculates the pitch line velocity from the gears RPM and diameter
    velocity = abs(pi * diameter * RPM / 60);
end

function power = power_from_RPM(RPM, torque)
    % Calculates power from the RPM and torque of a gear
    power = abs(RPM / 60 * 2 * pi * torque);
end