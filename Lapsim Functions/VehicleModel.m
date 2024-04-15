function [AX,AY,V] = VehicleModel(V,Ax,mode,vehicle)
%Vehicle Model - Lapsim
%Used to create the GGV diagram for the Lapsim
%Mode 1 = Tractive
%Mode 2 = Braking
%Mode 3 = Lateral Solving for given Long

%% Initialisation Settings
ittol = 0.01;

Fl = 0.5*1.225*vehicle.ClA*V^2;
Fd = 0.5*1.225*vehicle.CdA*V^2;

%% Pure Longit
if mode == 1 || mode == 2
    %Guess AXold:
    
    AXnew = 16;
    
    IterError = 100;
    while IterError > ittol
        AXold = AXnew;
        %Calculate Moments and Forces on the vehicle
        AXMoment = -AXold*vehicle.CGH*vehicle.m;
        DragMoment = -Fd * vehicle.DragCentreHeight;
        GravityMoment = 9.81*vehicle.m*vehicle.rw*vehicle.l;
        LiftMoment = Fl * vehicle.AeroBias * vehicle.l;%Lift Centre from Rear Axle
        
        %Calculate Longitudinal Axle Loads
        LT = AXMoment/vehicle.l; %Lateral load transfer
        
        FZF = min(vehicle.m*9.81*(1-vehicle.rw)+0.5*LT , vehicle.m*9.81) + Fl*(1-vehicle.AeroBias);
        FZR = min(vehicle.m*9.81*vehicle.rw-0.5*LT , vehicle.m*9.81) + Fl*vehicle.AeroBias;
                
        if mode == 1 %brum brum
            %~~~~~~~ [ED]
            muF = vehicle.muXfitgg(0.5*FZF)*0.5*vehicle.MuXsens;
            FXF = FZF*muF*vehicle.awd;
            
            muR = vehicle.muXfitgg(0.5*FZR)*0.5*vehicle.MuXsens;
            FXR = FZR*muR;
            
            FX = FXF+FXR;
            
        elseif mode == 2 %braking
            muF = vehicle.muXfitgg(0.5*FZF)*0.5*vehicle.MuXsens;
            FXF = -FZF*muF;
            
            muR = vehicle.muXfitgg(0.5*FZR)*0.5*vehicle.MuXsens;
            FXR = -FZR*muR;
            
            FX = FXF+FXR;
        end
        AXnew = (FX - Fd)/vehicle.m;
        
        IterError = abs(AXnew-AXold)/AXold;
        
    end
    
    AX = AXnew;
    AY = 0;
    
elseif mode == 3 % Combined/lateral
    
    AYnew = 0;
    IterError = 100;
    
    while IterError > ittol
        AYold = AYnew;
        AXMoment = -Ax * vehicle.CGH * vehicle.m;
        AYMoment = AYold * vehicle.CGH * vehicle.m;
        DragMoment = -Fd * vehicle.DragCentreHeight;
        GravityXMoment = 9.81 * vehicle.m * vehicle.rw * vehicle.l;
        LiftMoment = Fl * vehicle.AeroBias * vehicle.l;%Lift Centre from Rear Axle
        
        %Calculate Longitudinal Axle Loads
        LT = AXMoment/vehicle.l; %Longit load transfer
        
        FZFk = min(vehicle.m*9.81*(1-vehicle.rw) + 0.5*LT,vehicle.m*9.81);
        FZFa = Fl*(1-vehicle.AeroBias);
        FZF = FZFk+FZFa;
        
        
        FZRk = min(vehicle.m * 9.81 * vehicle.rw - 0.5*LT , vehicle.m*9.81);
        FZRa = Fl * vehicle.AeroBias;
        FZR = FZRk+FZRa;
        
        %Lateral Load transfer
        LLT = min(AYMoment/vehicle.t , vehicle.m*9.81); %Lateral load transfer
        
        FLLT = LLT*FZFk/(9.81*vehicle.m); % LateralLT per axle is proportional to load on the axle
        RLLT = LLT*FZRk/(9.81*vehicle.m);
        
        %Corners
        FZFI = FZFk/2 - FLLT/2 + FZFa/2;
        FZFO = FZFk/2 + FLLT/2 + FZFa/2;
        
        FZRI = FZRk/2 - RLLT/2 + FZRa/2;
        FZRO = FZRk/2 + RLLT/2 + FZRa/2;
        
        %Coefficient of frictions:
        
        muFI = [vehicle.muXfitgg(FZFI)*vehicle.MuXsens,vehicle.muYfitgg(FZFI)*vehicle.MuYsens]*0.5;
        muFO = [vehicle.muXfitgg(FZFO)*vehicle.MuXsens,vehicle.muYfitgg(FZFO)*vehicle.MuYsens]*0.5;
        
        muRI = [vehicle.muXfitgg(FZRI)*vehicle.MuXsens,vehicle.muYfitgg(FZRI)*vehicle.MuYsens]*0.5;
        muRO = [vehicle.muXfitgg(FZRO)*vehicle.MuXsens,vehicle.muYfitgg(FZRO)*vehicle.MuYsens]*0.5;
        
        % Solve resultant possible lateral acceleration from input
        % longitudinal
        
        if Ax*vehicle.m + Fd < 0 %braking
            FX = Ax*vehicle.m + Fd;
            
            muXtotal = (muFI(1)*FZFI+muFO(1)*FZFO+muRI(1)*FZRI+muRO(1)*FZRO);
            
            FXFI = FX*muFI(1)*FZFI/muXtotal;
            FXFO = FX*muFO(1)*FZFO/muXtotal;
            
            FXRI = FX*muRI(1)*FZRI/muXtotal;
            FXRO = FX*muRO(1)*FZRO/muXtotal;
            
        elseif Ax*vehicle.m + Fd > 0 %brum brum
            
            FX = Ax*vehicle.m + Fd;
            %Calculate proportion of longit force for each tyre based on
            %proportion of total grip that tyre provides. I.e. with a
            %square tyre setup, and equal load on each tyre the proportion 
            %of total Fx is 1/4
            muXtotal = (vehicle.awd*(muFI(1)*FZFI+muFO(1)*FZFO)+muRI(1)*FZRI+muRO(1)*FZRO);
            
            FXFI = vehicle.awd*FX*muFI(1)*FZFI/muXtotal;
            FXFO = vehicle.awd*FX*muFO(1)*FZFO/muXtotal;
            
            FXRI = FX*muRI(1)*FZRI/muXtotal;
            FXRO = FX*muRO(1)*FZRO/muXtotal;
        else Ax*vehicle.m + Fd == 0
            
            FXFI = 0;
            FXFO = 0;
            
            FXRI = 0;
            FXRO = 0;
        end
        
        % Take Longitudinal forces on each tire, and use the ellipse
        % approximation of a friction circle to solve the available lateral
        % on each tire.
        FYFI = (sqrt((muFI(2)*FZFI)^2*(1-FXFI^2/(muFI(1)*FZFI)^2)));
        FYFO = (sqrt((muFO(2)*FZFO)^2*(1-FXFO^2/(muFO(1)*FZFO)^2)));
        
        FYRI = (sqrt((muRI(2)*FZRI)^2*(1-FXRI^2/(muRI(1)*FZRI)^2)));
        FYRO = (sqrt((muRO(2)*FZRO)^2*(1-FXRO^2/(muRO(1)*FZRO)^2)));
        
        % Determine the yaw moment-balance condition limited lateral force
        
        Npotential = (FYFI+FYFO)*(vehicle.l-vehicle.rw*vehicle.l) - (FYRI+FYRO)*(vehicle.rw*vehicle.l);
        
        FYF = min( (FYFI+FYFO) , ((FYRI+FYRO) * (1-vehicle.rw)*vehicle.l/(vehicle.rw*vehicle.l)) );
        FYR = min( (FYRI+FYRO) , ((FYFI+FYFO) * (vehicle.rw*vehicle.l)/((1-vehicle.rw)*vehicle.l)) );
        
        %FYF = FYFI+FYFO;
        %FYR = FYRI+FYRO;
        
        FY = FYF+FYR;
        
        AY = FY/vehicle.m;
        
        
        AX = Ax;
        AYnew = AY;

        if isnan(AY) || AY < 0.0 || imag(AY) ~= 0
            AY = 0;
        end
        
        IterError = abs(AYold-AYnew)/AYold;
        
    end
    
end

%% Outputs:

end

