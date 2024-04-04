function [Results] = ptcalc(Results)
%% Autocross
TmaxAx = 1.45 * min([Results.Autox; Results.our_Autox]);
autoxlogical = Results.Autox < TmaxAx;
Results.points_Autox = 118.5 * autoxlogical .* (((TmaxAx ./ Results.Autox) - 1) / 0.45) + 6.5;
    
autoxlogical_our = Results.our_Autox < TmaxAx;
Results.our_points_Autox = 118.5 * ((TmaxAx / Results.our_Autox - 1) / 0.45) + 6.5;
%% Enduro
TmaxEn = 1.45 * min([Results.Enduro; Results.our_Enduro]);
endurological = Results.Enduro < TmaxEn;
Results.points_Enduro = 250 * endurological .* (((TmaxEn ./ Results.Enduro) - 1) / 0.45) + 25;

endurological_our = Results.our_Enduro < TmaxEn;
Results.our_points_Enduro = 250 * endurological_our .* (((TmaxEn ./ Results.our_Enduro) - 1) / 0.45) + 25;
%% Skidpan
TmaxSk = 1.25 * min([Results.skid; Results.our_skid]);
skidlogical = Results.skid < TmaxSk;
Results.points_skid = 71.5 * skidlogical .* (((TmaxSk ./ Results.skid) .^ 2 - 1) / 0.5625) + 3.5;

skidlogical_our = Results.our_skid < TmaxSk;
Results.our_points_skid = 71.5 * skidlogical_our .* (((TmaxSk ./ Results.our_skid) .^ 2 - 1) / 0.5625) + 3.5;
%% Acceleration
TmaxAc = 1.5 * min([Results.accel; Results.our_accel]);
accellogical = Results.accel < TmaxAc;
Results.points_accel = 95.5 * accellogical .* (((TmaxAc ./ Results.accel) - 1) / 0.5) + 4.5;

accellogical_our = Results.our_accel < TmaxAc;
Results.our_points_accel = 95.5 * ((TmaxAc / Results.our_accel - 1) / 0.5) + 4.5;
%% Efficiency
TminEn = min([Results.Enduro; Results.our_Enduro]);
CO2min = 0.65 * min([Results.Eff; Results.our_Eff]);

EF = ((TminEn)./(Results.Enduro)) .* ((CO2min)./(0.65*Results.Eff));
EF_our = ((TminEn)./(Results.our_Enduro)) .* ((CO2min)./(0.65*Results.our_Eff));
EFmin = (1/1.45) * ((CO2min)/(60.06*0.22));
EFmax = max(((TminEn)./([Results.Enduro;Results.our_Enduro])) .* ((CO2min)./(0.65*[Results.Eff;Results.our_Eff])));

Results.points_Eff = 100 * ((EFmin./EF) - 1) ./ ((EFmin./EFmax) - 1);

Results.our_points_Eff = 100 * ((EFmin./EF_our) - 1) ./ ((EFmin./EFmax) - 1);
%% Scores
% Results.our_points_total = Results.our_points_Autox + Results.our_points_Enduro + Results.our_points_skid + Results.our_points_Eff + Results.our_points_accel
% Results.points_total = Results.points_Autox + Results.points_Enduro + Results.points_skid + Results.points_Eff + Results.points_accel
% score = [Results.points_total; Results.our_points_total];
% scoreboard = sort(score, 'descend');
% position = find(scoreboard==Results.our_points_total);
% 
% score_Autox = [Results.points_Autox; Results.our_points_Autox];
% scoreboard_Autox = sort(score_Autox, 'descend');
% position_Autox = find(scoreboard_Autox==Results.our_points_Autox);
% 
% score_Enduro = [Results.points_Enduro; Results.our_points_Enduro];
% scoreboard_Enduro = sort(score_Enduro, 'descend');
% position_Enduro = find(scoreboard_Enduro==Results.our_points_Enduro);
% 
% score_skid = [Results.points_skid; Results.our_points_skid];
% scoreboard_skid = sort(score_skid, 'descend');
% position_skid = find(scoreboard_skid==Results.our_points_skid);
% 
% score_Eff = [Results.points_Eff; Results.our_points_Eff];
% scoreboard_Eff = sort(score_Eff, 'descend');
% position_Eff = find(scoreboard_Eff==Results.our_points_Eff);
% 
% score_accel = [Results.points_accel; Results.our_points_accel];
% scoreboard_accel = sort(score_accel, 'descend');
% position_accel = find(scoreboard_accel==Results.our_points_accel);
% 
% position_all = [position_Autox, position_Enduro, position_skid, position_Eff, position_accel, position, position];
% scoreboard_nohead = [score_Autox, score_Enduro, score_skid, score_Eff, score_accel, score, scoreboard];
% teams = ["Teams"; "Team1"; "Team2"; "Team3"; "Team4"; "Team5"; "Team6"; "Team7"; "Team8"; "Team9"; "Team10"; "Our Team"; "Our Position"] 
% headers_scoreboard = ["Autocross", "Endurance", "Skidpan", "Efficiency", "Acceleration", "Total", "Total Ordered"];
% scoreboard_final = [headers_scoreboard; scoreboard_nohead; position_all]
% Results.scoreboard_present = [teams, scoreboard_final]
end

