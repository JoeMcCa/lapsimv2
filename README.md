# lapsimv2
 Steady state laptime and competition simulator code for fsae in matlab

 Core functions for the lapsim are saved in /lapsim functions/ folder. Example wrappers are in the form of runner_xxxx.m files.

 ## Quick Start Tips

Change the loaded track file as required.
Modify parameters below to change vehicle settings.


to do sweeps of data:
1. Use "var" & "var2" as indexes of the changing vehicle settings
2. replace the definition of the vehicle parameters with "setting" and "setting2" respectively
3. the results structure will be filled with vectors of length=length(var)*length(var2)
4. settinglist and settinglist2 store the swept values
5. In a seperate post processing function convert these results to format required.

To do a sensitivity study:
1. change sensitivity_study definition to 1
2. ensure vehicle parameters are correct baseline configuration.

Remember that sensitivities will change considerably from one baseline config to another.
