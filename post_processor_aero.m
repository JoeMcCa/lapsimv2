clc
clear all

load('DF_Mass_Sweep10x10.mat')

Results.ClA_list = linspace(0,4,10);
Results.m_list = 176+linspace(0,30,10);

[Results.ClA, Results.m] = meshgrid(Results.ClA_list,Results.m_list);

Results.points_total_mesh = reshape(Results.points_total,10,10);

%~~~~~~~

[dpoints_dcolumn,dpoints_drow] = gradient(Results.points_total_mesh);

[dCla_dcolumn,~] = gradient(Results.ClA);

[~,dm_drow] = gradient(Results.m);

%~~~~~~~

dpoints_dCla = dpoints_dcolumn ./ dCla_dcolumn;

dpoints_dm = dpoints_drow ./ dm_drow;

dm_dClA = -dpoints_dCla ./ dpoints_dm;

%%

figure(1)
surf(Results.ClA,Results.m,dm_dClA)
ylabel('Vehicle Mass [kg]')
xlabel('ClA [m^2]')
zlabel('breakeven mass:ClA [kg/ClA]')

figure(2)
contourf(Results.ClA,Results.m,dm_dClA,'showtext','on')
ylabel('Vehicle Mass [kg]')
xlabel('ClA [m^2]')
title('breakeven kg/ClA Ratio')

figure(3)
contourf(Results.ClA,Results.m-176,Results.points_total_mesh - Results.points_total_mesh(1,1),'showtext','on')
ylabel('Aero Mass [kg]')
xlabel('ClA [m^2]')
title('Points Delta From No Aero')