%% EGB210 Gear Calculation and Optimisation
% Currently calculates the minimum gear modulus for the sun gear so that
% the stress in its teeth is equal to the yield stress of the material
% divided by a safety factor.
%
% Gear ratio is based on a 2AI configuration with the sun as the input
% member and carrier as the output member. The ring gear teeth are
% considered as positive, as their negative sign for being an internal gear
% has been accounted for in the equations.
%
% Calculates stage 2 first so that the output torque of stage 1 is know.
%
% Can use other script for individual calculations that allows setting the
% gear teeth numbers, its a good way to fiddle with the output result from
% this script if it's not quite right but close.

% METHOD
%
% The way this search works is that it picks a gear ratios (it's 2 stage so
% pick a ratio for stage 2 and stage 1 is known), loops through different 
% gear combos until the total diameter starts getting larger (which is 
% probably the point at which the stage is smallest. Store the smallest
% diameter gear numbers and end break from the loop.
% 
% Then iterate the ratio and go again.
%
% Once the max ratio end the loops and find the stored result with the
% smallest diameter (which is based off the largest diameter of either
% stage for the single result).
%
% Rerun the calculations with the numbers from the chosen result, and
% display the gear table.

% Retrospect and Improvements
%
% After some thought, this search could be improved by setting more
% criterion for the stages, and doing a more comprehensive search of gear
% combinations. A brute force check of all gear combinations would probaby
% be fine since this is a fairly small search space.

% Units are shown next to the variable.
%
% Variables
%   z: Number of gear teeth
%   T: Torque
%   F: Tangential Force
%   N: RPM of an element
%   Y: Lewis form factor
%   d: diameter
%   r: radius
% Subscripts
%   s: Sun gear
%   r: Ring gear
%   p1: Planet gear that meshes with sun gear
%   p2: Planet gear that meshes with ring gear
%   c: carrier

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

min_gear_teeth = 12; % Set the minimum allowable number of gear teeth.
max_gear_teeth = 100;
face_width_sun_stage_1 = 6e-3; % m, Set the face width.
face_width_ring_stage_1 = 6e-3; % m, Set the face width.
face_width_sun_stage_2 = 9e-3; % m, Set the face width.
face_width_ring_stage_2 = 9e-3; % m, Set the face width.

min_stage_2_gear_ratio = 7; % Set the minimum gear ratio of stage 2.
max_stage_2_gear_ratio = 16; % Set the maximum gear ratio of stage 2.
ratio_increment = 0.1; % Set the increment of the ratio per iteration.
round_ring_module = true;

% Run the numbers HAL.
gear_ratio_2_ideal = min_stage_2_gear_ratio; 
results = []; % Stores the results of each iteration.
while gear_ratio_2_ideal < max_stage_2_gear_ratio
    
    % Stage 1
    z_p1_1 = min_gear_teeth;
    z_s_1 = min_gear_teeth;
    z_p2_1 = min_gear_teeth;  
    face_width_sun_1 = face_width_sun_stage_1; % m, face width
    face_width_ring_1 = face_width_ring_stage_1; % m, face width
    % Stage 2
    z_p1_2 = min_gear_teeth;
    z_s_2 = min_gear_teeth;
    z_p2_2 = min_gear_teeth;  
    face_width_sun_2 = face_width_sun_stage_2; % m, face width
    face_width_ring_2 = face_width_ring_stage_2; % m, face width
    
    diameter_1_prev = NaN;
    while 1
        if z_p1_1 > max_gear_teeth || z_p1_2 > max_gear_teeth
            disp('Test')
            break
        end
        % Calculate the value for the ring gear teeth based of the given
        % ratios
        z_r_2 = round((gear_ratio_2_ideal - 1) * ...
                                            (z_p2_2 * z_s_2) / z_p1_2, 0);
        
        gear_ratio_2 = 1 + (z_p1_2 * z_r_2) / (z_p2_2 * z_s_2);
    
        gear_ratio_1_ideal = reduction_total / gear_ratio_2;
        z_r_1 = round((gear_ratio_1_ideal - 1) * ...
                                            (z_p2_1 * z_s_1) / z_p1_1, 0);
        
        gear_ratio_1 = 1 + (z_p1_1 * z_r_1) / (z_p2_1 * z_s_1);

        % Check the assembly conditions given the current gear teeth.
        % Gears and Gear Drives - Damir Jelaska - 2012; p. 343, eq. 6.20
        % z_r has been made negative to account for the sign rule for
        % internal gear teeth.
        k_1 = ((z_s_1 * z_p2_1) - (z_p1_1 * (-1 * z_r_1))) ...
            / (gcd(z_p1_1, z_p2_1) * num_planets);
        if mod(k_1, 1) ~= 0 % If k is not an integer then end iteration.
            z_p1_1 = z_p1_1 + 1;
            continue
        end

        k_2 = ((z_s_2 * z_p2_2) - (z_p1_2 * (-1 * z_r_2))) ...
            / (gcd(z_p1_2, z_p2_2) * num_planets);
        if mod(k_2, 1) ~= 0 % If k is not an integer then end iteration.
            z_p1_2 = z_p1_2 + 1;
            continue
        end
        
        % Calculate the input rpm for stage 2.
        N_s_2 = N_input / gear_ratio_1;
        
        % Run gear calculation functions
        [gear_table_2, extra_data_table_2, T_s_2, efficiency_actual_2, ...
            gears_pass_2, diameter_2] = calculate_gears(...
            z_s_2, z_p1_2, z_r_2, z_p2_2, T_output, N_s_2, ... 
            num_planets, yield_stress, safety_factor, mesh_efficiency, ...
            min_gear_module, face_width_sun_2, face_width_ring_2, ...
            round_ring_module);
    
        % Check if the gears all have a factor of safety over the input
        % factor. If not then iterate z_p1_2 go to next iteration.
        if ~gears_pass_2
            z_p1_2 = z_p1_2 + 1;
            continue
        end
        
        [gear_table_1, extra_data_table_1, T_s_1, efficiency_actual_1, ...
            gears_pass_1, diameter_1] = calculate_gears(...
            z_s_1, z_p1_1, z_r_1, z_p2_1, T_s_2, N_input, ...
            num_planets, yield_stress, safety_factor, mesh_efficiency, ...
            min_gear_module, face_width_sun_1, face_width_ring_1, ...
            round_ring_module);

        % Having these two checks produces a better results than if they're
        % deleted. This is a product of the overall code being poorly
        % written, but in engineering "close enough is good enough", and I
        % don't have the desire nor time to rewrite all of this when it
        % gets a 95% solution and I can fiddle with it to get one I want.

        % Check gear table 1 to make sure the planet gear 2 is larger than
        % 25 mm in diameter
        if gear_table_1.Module_mm(4) * gear_table_1.Teeth(4) < 25
            z_p1_1 = z_p1_1 + 1;
            continue
        end

        % Check gear table 1 to make sure the sun gear 1 is larger than
        % 25 mm in diameter
        if gear_table_1.Module_mm(1) * gear_table_1.Teeth(1) < 18
            z_p1_1 = z_p1_1 + 1;
            continue
        end
    
        % Check the diameter of the current iteration is lower than the.
        % previous. If so store that value and increment z_p1, then check 
        % the diameter again. If it is larger then the smallest diameter 
        % was the previous iteration. Decrement z_p1 to get the previous 
        % value.
        if isnan(diameter_1_prev)
            diameter_1_prev = diameter_1;
        elseif diameter_1 <= diameter_1_prev
            diameter_1_prev = diameter_1;
            z_p1_1 = z_p1_1 + 1;
            continue
        elseif diameter_1 > diameter_1_prev
            z_p1_1 = z_p1_1 - 1;
        end
    
        % Last check to make sure both sets of gears all pass the 
        % factor of safety check.
        if gears_pass_1 && gears_pass_2
            diameter = max(diameter_1_prev, diameter_2);
            
            % Store results to be used for finding the smallest diameter.
            results = [results; struct('diameter', diameter, ...
                                       'diameter_1', diameter_1_prev, ...
                                       'diameter_2', diameter_2, ...
                                       'gear_ratio_1', gear_ratio_1, ...
                                       'gear_ratio_2', gear_ratio_2, ...
                                       'z_s_1', z_s_1, ...
                                       'z_p1_1', z_p1_1, ...
                                       'z_r_1', z_r_1, ...
                                       'z_p2_1', z_p2_1, ...
                                       'z_s_2', z_s_2, ...
                                       'z_p1_2', z_p1_2, ...
                                       'z_r_2', z_r_2, ...
                                       'z_p2_2', z_p2_2, ...
                                       'T_in', T_s_1, ...
                                       'T_out', T_output)];
            break
        end
    end
    gear_ratio_2_ideal = gear_ratio_2_ideal + ratio_increment;
end


% Get the minimum diameter and the index of its row.
[min_diameter, row_index] = min([results.diameter]);
% Display results
%fprintf('Results\n');
%disp(results(row_index, :))

% Use results from the row corresponding to the minimum diameter to run 
% the calculations for both stages and then display them.

% Assign gear tooth numbers for stage 2
z_s_2 = results(row_index).z_s_2;
z_p1_2 = results(row_index).z_p1_2;
z_r_2 = results(row_index).z_r_2;
z_p2_2 = results(row_index).z_p2_2;
N_s_2 = N_input / results(row_index).gear_ratio_1;

% Stage 2 calculations
[gear_table_2, extra_data_table_2, T_s_2, efficiency_actual_2, ...
 gears_pass_2, diameter_2] = calculate_gears(z_s_2, z_p1_2, z_r_2, ...
 z_p2_2, T_output, N_s_2, num_planets, yield_stress, safety_factor, ...
 mesh_efficiency, min_gear_module, face_width_sun_2, face_width_ring_2, ...
 round_ring_module);

% Assign gear tooth numbers for stage 1
z_s_1 = results(row_index).z_s_1;
z_p1_1 = results(row_index).z_p1_1;
z_r_1 = results(row_index).z_r_1;
z_p2_1 = results(row_index).z_p2_1;
T_output = results(row_index).T_out;
N_s_1 = N_input;

% Stage 1 calculations
[gear_table_1, extra_data_table_1, T_s_1, efficiency_actual_1, ...
 gears_pass_1, diameter_1] = calculate_gears(z_s_1, z_p1_1, z_r_1, ...
 z_p2_1, T_s_2, N_s_1, num_planets, yield_stress, safety_factor, ...
 mesh_efficiency, min_gear_module, face_width_sun_1, face_width_ring_1, ...
 round_ring_module);

% Check the assembly conditions given the current gear teeth.
% This is a final check to make sure whats about to be displayed is valid.
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