%% EGB210 Planet Gear Force Plots
close all; clear; clc;

% -- How To Use --
% You need to do the calculations by hand to get the shear and moment at
% the planet gears and bearing.
% 1. V_1 is the shear between planet gears.
% 2. V_2 is the shear between planet gear 2 and the bearing.
% 3. M_1 is the moment at the second planet gear.
% 4. M_2 is the moment at the bearing.
% 5. T is the torque between the planet gears.

% To change the appearance of the plot look through the function, there are
% parameters to change things like the size and style of font, and the size
% of the plots.

% -- Plots in xy-plane
% Goes from left to right in the positive x-direction, so planet 2 is point
% 1, planet gear 1 is the second point.
V_1_xy = -8.74; V_2_xy = -4.47;
M_1_xy = -0.118; M_2_xy = -0.203;
T_1_xy = -0.294;

% This is setup to get the vertical lines since the shear and torsion have
% step changes.
x_xy = [0, 2.999, 3, 14.999, 15, 33.999, 34, 38];
V_xy = [0, 0, V_1_xy, V_1_xy,  V_2_xy,  V_2_xy, 0, 0];
M_xy = [0, 0, 0, M_1_xy, M_1_xy, M_2_xy, 0, 0];
T_xy = [0, 0, T_1_xy, T_1_xy, 0, 0, 0, 0];

title_xy = 'SFD, BMD, TD of Planet Gears 2 Shaft in x-y Plane';
filename_xy = 'SFD_BMD_TD_Planet_Gears_xy_stage1.tif';
plot_SFD_BMD_TD(x_xy, V_xy, M_xy, T_xy, title_xy, filename_xy)

% -- Plots in xz-plane
% Goes from left to right in the positive x-direction, so planet 2 is point
% 1, planet gear 1 is the second point.
V_1_xz = 24.0; V_2_xz = 35.75;
M_1_xz = -0.324; M_2_xz = -1.00;
T_1_xz = -0.294;

% This is setup to get the vertical lines since the shear and torsion have
% step changes.
x_xz = [0, 2.999, 3, 14.999, 15, 33.999, 34, 38];
V_xz = [0, 0, V_1_xz, V_1_xz,  V_2_xz,  V_2_xz, 0, 0];
M_xz = [0, 0, 0, M_1_xz, M_1_xz, M_2_xz, 0, 0];
T_xz = [0, 0, T_1_xz, T_1_xz, 0, 0, 0, 0];

title_xz = 'SFD, BMD, TD of Planet Gears 2 Shaft in x-z Plane';
filename_xz = 'SFD_BMD_TD_Planet_Gears_xz_stage1.tif';
plot_SFD_BMD_TD(x_xz, V_xz, M_xz, T_xz, title_xz, filename_xz)

function plot_SFD_BMD_TD(x, V, M, T, title, filename)
    % -- Figure setup --
    figure;
    titleFontSize = 20; % Variable for title font size
    labelFontSize = 24; % Variable for label font size
    tickLabelFontSize = 14; % Variable for axis tick label font size
    lineThicknessData = 1.5; % Thickness for the actual data line
    lineThicknessZero = 1; % Thickness for the y=0 line
    
    tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    sgtitle(title, 'FontName', 'Times New Roman', 'FontSize', titleFontSize);
    
    % -- Shear Force Diagram --
    nexttile; % Activate the first tile
    plot(x, V, 'k-', 'LineWidth', lineThicknessData);
    ylabel('V [N]', 'Rotation', 0, 'HorizontalAlignment', 'right', 'FontSize', labelFontSize, 'FontName', 'Times New Roman'); % Set horizontal y-axis label
    xlim([min(x) max(x)]);
    y_limit_V = max(abs(min(V)), abs(max(V))) * 1.1;
    ylim([-y_limit_V y_limit_V]);
    grid on;
    yline(0, 'k--', 'LineWidth', lineThicknessZero); % Add a horizontal line at y=0
    % Remove the box and x-axis ticks/labels
    set(gca, 'TickDir', 'out', 'Box', 'off', 'XColor', 'none', 'FontName', 'Times New Roman', 'FontSize', tickLabelFontSize); % Set font to Times New Roman
    
    % -- Bending Moment Diagram --
    nexttile; % Activate the second tile
    plot(x, M, 'k-', 'LineWidth', lineThicknessData);
    ylabel('M [N\cdotm]', 'Rotation', 0, 'HorizontalAlignment', 'right', 'FontSize', labelFontSize, 'FontName', 'Times New Roman'); % Set horizontal y-axis label
    xlim([min(x) max(x)]);
    y_limit_M = max(abs(min(M)), abs(max(M))) * 1.1;
    ylim([-y_limit_M y_limit_M]);
    grid on;
    yline(0, 'k--', 'LineWidth', lineThicknessZero); % Add a horizontal line at y=0
    % Remove the box and x-axis ticks/labels
    set(gca, 'TickDir', 'out', 'Box', 'off', 'XColor', 'none', 'FontName', 'Times New Roman', 'FontSize', tickLabelFontSize); % Set font to Times New Roman
    
    % -- Torsion Diagram --
    nexttile; % Activate the third tile
    plot(x, T, 'k-', 'LineWidth', lineThicknessData);
    xlabel('$x$ [mm]', 'FontSize', labelFontSize, 'Interpreter', 'latex'); % Renders x in LaTeX style
    ylabel('T [N\cdotm]', 'Rotation', 0, 'HorizontalAlignment', 'right', 'FontSize', labelFontSize, 'FontName', 'Times New Roman'); % Set horizontal y-axis label
    xlim([min(x) max(x)]);
    y_limit_T = max(abs(min(T)), abs(max(T))) * 1.1;
    ylim([-y_limit_T y_limit_T]);
    grid on;
    yline(0, 'k--', 'LineWidth', lineThicknessZero); % Add a horizontal line at y=0
    % Remove the box around the plot
    set(gca, 'TickDir', 'out', 'Box', 'off', 'FontName', 'Times New Roman', 'FontSize', tickLabelFontSize); % Set font to Times New Roman
    
    % -- Set size and export --
    % Set the size of the figure in inches
    figureWidth = 8; % Width in inches
    figureHeight = 10; % Height in inches
    set(gcf, 'Units', 'Inches', 'Position', [1, 1, figureWidth, figureHeight]);
    
    % Export the figure
    exportgraphics(gcf, filename, 'Resolution', 300);
end
