try {
    # Initialize MATLAB COM interface
    $matlab = New-Object -ComObject matlab.application

    # Run the simulation command in MATLAB
    $matlab.Execute("set_param(bdroot, 'SimulationCommand', 'start')")

    # Check if CSV logging exists and read the state_estimator_log.csv
    $logPath = "L:\save\devdrive\0_parrotMinidroneCompetition\state_estimator_log.csv"
    if (Test-Path $logPath) {
        $csvContent = Get-Content -Path $logPath
        Write-Output "Simulation log contents:" 
        Write-Output $csvContent
    } else {
        Write-Output "Error: state_estimator_log.csv file not found."
    }
} catch {
    # Catch any MATLAB simulation execution errors
    Write-Error "Error during MATLAB simulation: $_"
}