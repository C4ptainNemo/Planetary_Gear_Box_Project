%% Individual Calculation
% Takes the give gear teeth numbers and runs the calculations. Good for
% playing around with a solution that is close but needs some minor tweaks.

clear; close all; clc;

% Parameters, change these as you please.
N_input = 1500; % RPM, rpm's of the input shaft
T_output = 20; % N*m, the torque output from the second stage
reduction_total = 65; % Total reduction ratio

num_planets = 3; % Number of planet gears
min_gear_module = 1.5e-3; % m, minimum allowable gear modulus

mesh_efficiency = 0.75; % 0<=x<=1, efficiency of meshing spur gears.
yield_stress = 60e6; % Pa, Set the gear material yield stress.
safety_factor = 3; % Safety factor applied to the yield stress.

face_width_sun_stage_1  = 6e-3; % m, Set the face width.
face_width_ring_stage_1 = 6e-3; % m, Set the face width.
face_width_sun_stage_2  = 9e-3; % m, Set the face width.
face_width_ring_stage_2 = 9e-3; % m, Set the face width.

round_ring_module = true;

gear_ratio_stage_2 = 7.125;

% Stage 1
z_s_1 = 15;
z_p1_1 = 30;
z_p2_1 = 14;   
% Stage 2
z_s_2 = 12;
z_p1_2 = 21;
z_p2_2 = 12;

% Calculate the value for the ring gear teeth based of the given
% ratios
z_r_2 = round((gear_ratio_stage_2 - 1) * (z_p2_2 * z_s_2) / z_p1_2, 0);
gear_ratio_2 = 1 + (z_p1_2 * z_r_2) / (z_p2_2 * z_s_2);

gear_ratio_1_ideal = reduction_total / gear_ratio_2;
z_r_1 = round((gear_ratio_1_ideal - 1) * (z_p2_1 * z_s_1) / z_p1_1, 0);
gear_ratio_1 = 1 + (z_p1_1 * z_r_1) / (z_p2_1 * z_s_1);

% Check the assembly conditions given the current gear teeth.
% z_r has been made negative to account for the sign rule for internal 
% gear teeth.
% Gears and Gear Drives - Damir Jelaska - 2012; p. 343, eq. 6.20
k_1 = ((z_s_1 * z_p2_1) - (z_p1_1 * (-1 * z_r_1))) ...
    / (gcd(z_p1_1, z_p2_1) * num_planets);
if mod(k_1, 1) ~= 0 % If k is not an integer then end iteration.
    error('Stage 1 failed assembly condition')
end

k_2 = ((z_s_2 * z_p2_2) - (z_p1_2 * (-1 * z_r_2))) ...
    / (gcd(z_p1_2, z_p2_2) * num_planets);
if mod(k_2, 1) ~= 0 % If k is not an integer then end iteration.
    error("Stage 2 failed assembly condition")
end

% Calculate the input rpm for stage 2.
N_s_2 = N_input / gear_ratio_1;

% Run gear calculation functions
[gear_table_2, extra_data_table_2, T_s_2, efficiency_actual_2, ...
    gears_pass_2, diameter_2] = calculate_gears(...
    z_s_2, z_p1_2, z_r_2, z_p2_2, T_output, N_s_2, ... 
    num_planets, yield_stress, safety_factor, mesh_efficiency, ...
    min_gear_module, face_width_sun_stage_2, face_width_ring_stage_2, ...
    round_ring_module);

[gear_table_1, extra_data_table_1, T_s_1, efficiency_actual_1, ...
    gears_pass_1, diameter_1] = calculate_gears(...
    z_s_1, z_p1_1, z_r_1, z_p2_1, T_s_2, N_input, ...
    num_planets, yield_stress, safety_factor, mesh_efficiency, ...
    min_gear_module, face_width_sun_stage_1, face_width_ring_stage_1, ...
    round_ring_module);

% Output results of stage 1 then stage 2.
gear_ratio_total = gear_ratio_1 * gear_ratio_2;
efficiency__total = efficiency_actual_1 * efficiency_actual_2;
overall_table = table(gear_ratio_total, efficiency__total, ...
                'VariableNames', {'Gear_ratio_total', 'Eff._total'});

fprintf('Overall Details\n')
disp(overall_table)
fprintf('\n')

fprintf('Stage 1\n')
disp(gear_table_1)
disp(extra_data_table_1)
fprintf('\n')

fprintf('Stage 2\n')
disp(gear_table_2)
disp(extra_data_table_2)