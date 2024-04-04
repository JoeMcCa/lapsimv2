clc
clear all

load('DF_Drag_Sweep10x10.mat')

Results.ClA_list = linspace(0,4,10);
Results.CdA_list = linspace(1,3,10);

[Results.ClA, Results.CdA] = meshgrid(Results.ClA_list,Results.CdA_list);

Results.points_total_mesh = reshape(Results.points_total,10,10);

%~~~~~~~

[dpoints_dcolumn,dpoints_drow] = gradient(Results.points_total_mesh);

[dCla_dcolumn,~] = gradient(Results.ClA);

[~,dCdA_drow] = gradient(Results.CdA);

%~~~~~~~

dpoints_dClA = dpoints_dcolumn ./ dCla_dcolumn;

dpoints_dCdA = dpoints_drow ./ dCdA_drow;

dCdA_dClA = -dpoints_dCdA ./ dpoints_dClA; %%-dpoints_dClA ./ dpoints_dCdA;

%%

% figure(1)
% surf(Results.ClA,Results.CdA,dCdA_dClA)
% ylabel('CdA [m^2]')
% xlabel('ClA [m^2]')
% zlabel('breakeven Aerodynamic Efficiency [ClA/CdA]')

figure(2)
contourf(Results.ClA,Results.CdA,dCdA_dClA,'showtext','on')
ylabel('CdA [m^2]')
xlabel('ClA [m^2]')
title('breakeven Aerodynamic Efficiency [deltaClA/deltaCdA]')

figure(3)
contourf(Results.ClA,Results.CdA,Results.points_total_mesh - Results.points_total_mesh(1,1),'showtext','on')
ylabel('CdA [m^2]')
xlabel('ClA [m^2]')
title('Points Delta From No Aero')

