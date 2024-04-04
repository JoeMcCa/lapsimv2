clear all
close all
clc

%% Convert GPS Data to xy position values
%load('wintonmap.mat')
load('EGG LAYOUT DATA.mat')
Ground_Speed_Right.Value = Vehicle_Chassis_Wheel_Speed_FR.Value;
Ground_Speed_Left.Value = Vehicle_Chassis_Wheel_Speed_FL.Value;
G_Force_Lat.Value = Vehicle_Chassis_SBG_Accel_Y.Value;

GPS = [transpose(GPS_Latitude.Value),transpose(GPS_Longitude.Value)]; % Store GPS data in array
GPS = [GPS, zeros(size(GPS,1),1)]; %add Altitude zeroes column

POS = lla2flat(GPS, GPS(1,1:2), 0, 0); %Convert to Position using LL2flat
POS(:,3) = []; %clear altitude column
%POS = POS(1:10:end,:); %select every 10th GPS coord - the rest are interpolated :(

plot (POS(:,1),POS(:,2),'.-') %plot track map from raw data

%% Create continuous spline of length coordinates
L = [];
L = [L;0];

for i = 5:size(POS,1)-5

    Li = ((POS((i),1)-POS((i-1),1))^2+(POS((i),2)-POS((i-1),2))^2)^0.5;
    
    Lii = L(end)+Li;
    
    L = [L;Lii];
    
end

PosLength = transpose(1:size(POS,1));
    
%% Evaluate Derivatives of X,Y Coords
    %% X First Derivatives
    XPos = POS(:,1);
    XPosd = [];
    for i = 3:(size(XPos)-2);
        XPosdi = (XPos(i+2)-XPos(i-2))/4;
        XPosd = [XPosd,XPosdi];
    end
    
    XPosds = smooth(XPosd,0.02,'loess'); %Smooth derivative output using loess - to remove noise.
    
    %Plot comparison of smoothed derivatives vs direct.
%         plot(XPosd)
%         hold on
%         plot(XPosds)
        
        %% X Second Derivatives
            XPosdsd = [];
            for i = 3:(size(XPosds)-2);
                XPosdsdi = (XPosds(i+2)-XPosds(i-2))/4;
                XPosdsd = [XPosdsd,XPosdsdi];
            end
    
            XPosdsds = smooth(XPosdsd,0.02,'loess'); %Smooth derivative output using loess - to remove noise.
    %% Y First Derivatives
    YPos = POS(:,2);
    YPosd = [];
    for i = 3:(size(YPos)-2);
        YPosdi = (YPos(i+2)-YPos(i-2))/4;
        YPosd = [YPosd,YPosdi];
    end
    
    YPosds = smooth(YPosd,0.02,'loess'); %Smooth derivative output using loess - to remove noise.
    
    %Plot comparison of smoothed derivatives vs direct.
%         plot(YPosd)
%         hold on
%         plot(YPosdersmooth)
        %% Y Second Derivatives
            YPosdsd = [];
            for i = 3:(size(YPosds)-2)
                YPosdsdi = (YPosds(i+2)-YPosds(i-2))/4;
                YPosdsd = [YPosdsd,YPosdsdi];
            end
    
            YPosdsds = smooth(YPosdsd,0.02,'loess'); %Smooth derivative output using loess - to remove noise.
            
            %plot comparison of smoothed double deriv vs direct.
%             plot (YPosdsd)
%             hold on
%             plot (YPosdsds)

%% Resize Derivative arrays by chopping off start and end of arrays

YPosds(1:2,:) = [];
YPosds(size(YPosds)-1:size(YPosds),:) = [];

XPosds(1:2,:) = [];
XPosds(size(XPosds)-1:size(XPosds),:) = [];
            
%% Form Curvature Array

    K = abs(XPosds.*YPosdsds - YPosds.*XPosdsds)./(((XPosds).^2+(YPosds).^2).^1.5);
    
    Ks = smooth(K,0.01,'loess');
    
    figure(2)
    plot (L,K)
    hold on
    plot (L,Ks)
    title('comparison of smoothed vs non-smoothed curvature vector')
    legend('Non Smoothed','Smoothed')
    ylabel 'Curvature 1/m'
    xlabel 'Distance Along Track'
    
    
    R = K.^-1;
    Rs = Ks.^-1;
    
    R(R>1000) = 1000;
    
    Rmin = islocalmin(R);
    
%% Plot max velocity along track & Compare to actual speed to get initial idea of how accurate the processed curvature is

    latgmax = 1.5;
    latamax = latgmax*9.81;
    
    vmax = sqrt(latamax.*R);
    
    vmax = vmax*3.6;
    
    vactual = (Ground_Speed_Right.Value' + Ground_Speed_Left.Value') / 2;
    
    %vactual = vactual(1:10:end,:);
    vactual(1:8,:) = [];
    xactual = cumtrapz((vactual/3.6) * 0.1);
    
    figure(3)
    plot (L,vmax)
    hold on
    plot (L,vactual)
    title('Plot Max speed vs Distance along track')
    ylabel 'Velocity kmh'
    xlabel 'Distance Along Track'
    
    
    % This is actually pretty decent. certianly very encouraging
    
    
    %% calculate track radius from latg and velocity
%     % Now i want to calculate track radius from acceleration and velocity 
%     %then compare the two and potentially remove  any wierd data.
%     
%     alatactual = abs(G_Force_Lat.Value)';
%     %alatactual = alatactual(1:10:end,:);
%     alatactual(end-5:end,:) = [];
%     alatactual(1:2,:) = [];
%     
%     r_derived = ((vactual./3.6).^2)./(alatactual*9.81);
%     r_derived(r_derived>1000) = 1000;
%     
%     figure(4)
%     plot (L,r_derived,L,R)
%     hold on
%     title('comparison of acceleration & velocity derived radius with GPS')
%     legend('a=v^2/r method', 'GPS Method')
%     ylabel 'Radius m'
%     xlabel 'Distance Along Track'
%     
%     %Thats a lot better than i expected. The magnitude of nearly all
%     %troughs are pretty much on point. Most peaks seeto line up, but the
%     %ones that dont i think is because of the resolution in the x data.
%     
%     k_derived = (alatactual*9.81)./((vactual./3.6).^2);
%     
%     figure(5)
%     plot (L,k_derived,L,K)
%     hold on
%     title('comparison of acceleration & velocity derived curvature with GPS')
%     legend('a=v^2/r method', 'GPS Method')
%     ylabel 'Curvature 1/m'
%     xlabel 'Distance Along Track'
%     
%     %same deal - good stuff    

%% PROCESS CURVATURE PLOT FOR USE    
% Ok Track map is ok

% now need to do some processing to get it useful for next scripts.

% I have decided its best to use curvature here. Its a lot simpler in terms
% of variance and div0 bullshit. - Less variance = easier i reckon

%% Create vector defining high curvature.

[K_peaks, K_peakslocs] = findpeaks(K);

% figure(6)
% findpeaks(K)
% title('findpeaks Results on Curvature Array')
% ylabel 'Curvature 1/m'
% xlabel 'Count'
% grid on



%% Split curvature & Distance data based off peaks, Start and finish

Size = size(K_peaks)

for i = 1:size(K_peaks)+1
    
    if i <= 1
        K_section{i} = K(1:K_peakslocs(i));
        L_section{i} = L(1:K_peakslocs(i));
    elseif i > (Size)
        K_section{i} = K(K_peakslocs(i-1):end);
        L_section{i} = L(K_peakslocs(i-1):end);
    else
        K_section{i} = K(K_peakslocs(i-1):K_peakslocs(i)); 
        L_section{i} = L(K_peakslocs(i-1):K_peakslocs(i));
    end
end

%% Vector of sizes of K_section/L_section
S=[];
for i = 1:size(K_section,2)
    s = size(K_section{i},1);
    S = [S s];
end

actual.ax = Vehicle_Chassis_SBG_Accel_X.Value(1:end-1);
actual.ay = Vehicle_Chassis_SBG_Accel_Y.Value(1:end-1);
actual.V = (Vehicle_Chassis_Wheel_Speed_FL.Value(1:end-1) + Vehicle_Chassis_Wheel_Speed_FR.Value(1:end-1)) / 2;
actual.X = xactual';

save('EGGlakeside_processed', 'K_section','L_section','actual','POS')
