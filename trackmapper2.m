%% Track Mapper V2
clc
clear all

addpath 'Track Map Data'\
addpath 'Lapsim Functions'\

load('EGG LAYOUT DATA 70Adc 100Hz.mat')

%Velocity = GPS_Speed.Value/3.6;
Velocity = (Vehicle_Chassis_Wheel_Speed_FL.Value' + Vehicle_Chassis_Wheel_Speed_FR.Value') / (2*3.6);
V_dt = Vehicle_Chassis_Wheel_Speed_FL.Time(2)-Vehicle_Chassis_Wheel_Speed_FL.Time(1);
L = cumtrapz((Velocity) * V_dt);
L(end) = [];

Yaw_Rate = deg2rad(Vehicle_Chassis_SBG_Gyro_Z.Value');

K = abs(Yaw_Rate ./ Velocity);

K_smooth = smooth(K,0.02,'loess');

% figure
% plot(K,'.')
% hold on
% plot(K_smooth)

%% Create vector defining high curvature.

[K_peaks, K_peakslocs] = findpeaks(K_smooth);

% figure(6)
% findpeaks(K_smooth)
% title('findpeaks Results on Curvature Array')
% ylabel 'Curvature 1/m'
% xlabel 'Count'
% grid on

%% Split curvature & Distance data based off peaks, Start and finish

Size = size(K_peaks);

for i = 1:size(K_peaks)+1
    if i <= 1
        K_section{i} = K_smooth(1:K_peakslocs(i));
        L_section{i} = L(1:K_peakslocs(i));
    elseif i > (Size)
        K_section{i} = K_smooth(K_peakslocs(i-1):end);
        L_section{i} = L(K_peakslocs(i-1):end);
    else
        K_section{i} = K_smooth(K_peakslocs(i-1):K_peakslocs(i)); 
        L_section{i} = L(K_peakslocs(i-1):K_peakslocs(i));
    end
end

%% Save

actual.ax = lowpass(Vehicle_Chassis_SBG_Accel_X.Value(1:end-1),10,100);
actual.ay = lowpass(Vehicle_Chassis_SBG_Accel_Y.Value(1:end-1),10,100);
actual.V = (Vehicle_Chassis_Wheel_Speed_FL.Value(1:end-1) + Vehicle_Chassis_Wheel_Speed_FR.Value(1:end-1)) / 2;
actual.L = L-L_section{1}(end);

save('EGGlakeside_processed', 'K_section','L_section','actual')