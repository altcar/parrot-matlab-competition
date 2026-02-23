# 1. Connect to the MATLAB COM server
$matlab = New-Object -ComObject Matlab.Application
$matlab.Visible = 1 # Ensures you can see the Simulink window pop up

# 2. Open the MATLAB Project
$projectPath = "L:\save\devdrive\0_parrotMinidroneCompetition\MinidroneCompetition.prj"
$matlab.Execute("openProject('$projectPath')")

# 3. Wait a few seconds for the Project startup scripts to open the Simulink window
Start-Sleep -Seconds 15

# 4. Trigger the 'Play' button
$matlab.Execute("set_param(bdroot, 'SimulationCommand', 'start')")
Write-Host "Project loaded and Simulation started."