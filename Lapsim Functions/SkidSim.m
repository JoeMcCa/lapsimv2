function time = SkidSim(vehicle,latG,VelocityRange)

%% Velocity Fit
if nargin ~= 3
    [GGV latG VelocityRange PosGGV NegGGV] = GGVGenerator(vehicle, simsetup);
end
vel = linspace(1,min(vehicle.Vmaxvoltage,VelocityRange(end)),50);
rad = [];
for v = vel
    
    r = (v.^2)./latG(v);
    rad = [rad r];
end
rad2vel = fit(transpose(rad),transpose(vel),'smoothingspline');

%% Skidpad Time
ri = 15.25/2; %Radius of inner cone circle (m)
tw = vehicle.t/1000;
r = ri+(tw/2)+0.012; %Radius of circle driven - CL of car (m)
v = rad2vel(r);
omega = v/r;
time = 2*pi/omega;




% %% 
% 
% m = vehicle.m;
% mu = 1.5;
% ClA = vehicle.ClA;
% tw = vehicle.t/1000;
% %Sim Variables - variables taken from car info, constants given below
% g = 9.81; %Gravity (m/s^2)
% rho = 1.1644; %Air density - sea level, 30degC (kg/m^3)
% ri = 7.625; %Radius of inner cone circle (m)
% r = ri+(tw/2)+0.012; %Radius of circle driven - CL of car (m)
% laps = 1; %Total circles driven for event (unitless)
% theta = laps*2*pi; %Angle covered in event (rad)
% 
% %Balance centrifugal force and max tire grip to calc max velocity
% v = sqrt((m*g*mu)/((m/r)-(ClA*rho*mu/2))) %Max velocity due to tire grip (m/s)
% v_new = rad2vel(r)
% omega = v/r; %Max angular velocity (rad/s)
% 
% %Calc time taken from max angular velocity
% time = theta/omega; %Time taken for event (s)