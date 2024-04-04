    figure(1)
    plot(autoxresults.L_track/3.6,autoxresults.V_track)
    hold on
    plot(actual.L/3.6,actual.V/3.6)
    grid on
    title('Velocity Trace')
    ylabel('Velocity [m/s]')
    xlabel('Distance [m]')
    legend('Simulated V','Actual V','location','best')
    ylim([0,20])
    xlim([0,100])

    figure(2)
    plot(autoxresults.L_track/3.6,autoxresults.AY_track)
    hold on
    plot(actual.L/3.6,9.81*abs(smoothdata(actual.ay,'sgolay',40)))
    grid on
    title('Lateral Accel Trace Comparison')
    ylabel('Lateral Acceleration [m/s/s]')
    xlabel('Distance [m]')
    legend('Simulated Ay','Actual Ay','location','best')
    xlim([0,100])
    
    figure(3)
    plot(autoxresults.L_track/3.6,autoxresults.AX_track)
    hold on
    plot(actual.L/3.6,9.81*smoothdata(actual.ax,'sgolay',40))
    grid on
    title('Longit Accel Trace')
    ylabel('Longitudinal Acceleration [m/s/s]')
    xlabel('Distance [m]')
    legend('Simulated Ax','Actual Ax','location','best')
    xlim([0,100])
    
    %% Sensitivity?
    
    load('Power Setting Sweep Lap Averages.mat')
    
        errors = experimental.Laptime_Var(1:3) + experimental.Laptime_Var(3);
        errors(3) = 0;
        
    figure(4)
    plot(settinglist, (T_laps-T_laps(2)) / 7)
    hold on
    errorbar(experimental.ADC_Set(1:3),(experimental.Laptime(1:3)-experimental.Laptime(3)),errors,'o')
    yline(0)
    grid on
    title('Egg - Laptime Delta vs Power Setting')
    ylabel('Laptime Delta [s]')
    xlabel('Current Setting [DC Amps]')
    ylim([-1.5,0.5])
    xlim([30,120])
    legend('Simulated Laptime Delta','Actual Laptime Deltas (7 lap average)','location','best')
    
%     figure(5)
%     plot(settinglist, (T_laps) / 7)
%     hold on
%     errorbar(experimental.ADC_Set(1:3),experimental.Laptime(1:3),experimental.Laptime_Var(1:3),'o')
%     grid on
%     title('Egg - Laptime vs Power Setting')
%     ylabel('Laptime [s]')
%     xlabel('Current Setting [DC Amps]')
%     xlim([30,120])
%     legend('Simulated Laptime Delta','Actual Laptime Deltas (7 lap average)','location','best')
