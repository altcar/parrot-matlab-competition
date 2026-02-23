function [p_ref, o_ref] = myLogic2(x,y,z,yaw,p,r)
    global globalR globalG globalB
    persistent device initPhaseStartTime integralError lastError csvFile prevCentroidRow
    
    if isempty(initPhaseStartTime)
        initPhaseStartTime = now;
    end
    if isempty(integralError)
        integralError = 0;
    end
    if isempty(lastError)
        lastError = 0;
    end
    if isempty(prevCentroidRow)
        prevCentroidRow = 60;
    end
    
    if isempty(device) || ~isvalid(device)
        device = serialport("COM10", 115200); 
    end
    
    if isempty(globalR)
        o_ref = single([0, 0, 0]);
        p_ref = single([0.1, 0, -1.1]);
        return;
    end

    R_d = double(globalR); G_d = double(globalG); B_d = double(globalB);
    redDominance = R_d - (B_d/2) - (G_d/2); 
    binaryMask = redDominance > 30;

    columnSums = sum(binaryMask, 1);
    totalWeight = sum(columnSums);
    rowSums = sum(binaryMask, 2);
    totalRowWeight = sum(rowSums);
    
    elapsedTime = (now - initPhaseStartTime) * 86400;
    
    if totalWeight == 0
        p_ref = single([x, y, z]);
        o_ref = single([0, 0, 0]);
        
        if isempty(csvFile)
            csvFile = fopen('_log1.csv', 'w');
            fprintf(csvFile, 'time,x,y,z,yaw,totalWeight,centroidCol,centroidRow,yawAngle\n');
        end
        t_now = now;
        fprintf(csvFile, '%.10f,%.4f,%.4f,%.4f,%.4f,%d,%.1f,%.1f,%.4f\n', t_now, x, y, z, yaw, totalWeight, 80, 60, 0);
        return;
    end
    
    gapIndices = find(columnSums > 0);
    if length(gapIndices) > 1
        gaps = diff(gapIndices);
        if any(gaps > 3)
            p_ref = single([x, y, z]);
            o_ref = single([0, 0, 0]);
            
            if isempty(csvFile)
                csvFile = fopen('_log1.csv', 'w');
                fprintf(csvFile, 'time,x,y,z,yaw,totalWeight,centroidCol,centroidRow,yawAngle\n');
            end
            t_now = now;
            centroidCol = sum((1:size(binaryMask, 2)) .* columnSums) / totalWeight;
            centroidRow = sum((1:size(binaryMask, 1))' .* rowSums) / totalRowWeight;
            fprintf(csvFile, '%.10f,%.4f,%.4f,%.4f,%.4f,%d,%.1f,%.1f,%.4f\n', t_now, x, y, z, yaw, totalWeight, centroidCol, centroidRow, 0);
            return;
        end
    end
    
    centroidCol = sum((1:size(binaryMask, 2)) .* columnSums) / totalWeight;
    centroidRow = sum((1:size(binaryMask, 1))' .* rowSums) / totalRowWeight;

    flatMask = uint8(binaryMask'); 
    fullPacket = [uint8(flatMask(:))', single(centroidCol)]; 
    write(device, fullPacket, "uint8"); 

    middleCol = 80;
    middleRow = 60;
    stepSize = 0.3;
    
    rowChange = centroidRow - prevCentroidRow;
    prevCentroidRow = centroidRow;
    
    if elapsedTime < 5
        yawAngle = 0;
        integralError = 0;
        lastError = 0;
    else
        colError = double(centroidCol) - middleCol;
        
        Kp = 0.02;
        Ki = 0.005;
        Kd = 0.005;
        
        proportional = Kp * colError;
        integralError = integralError + colError;
        integral = Ki * integralError;
        derivative = Kd * (colError - lastError);
        yawAngle = proportional + integral + derivative;
        lastError = colError;
        
        if rowChange > 5
            yawAngle = 0.6;
        elseif rowChange < -5
            yawAngle = -0.6;
        elseif abs(centroidRow - 40) > 15
            yawAngle = yawAngle * 2.0;
        end
    end
    
    yawAngle = max(min(yawAngle, 1.2), -1.2);
    o_ref = single([0, 0, yawAngle]);
    
    newX = x + stepSize;
    p_ref = single([newX, y, z]);
    
    if isempty(csvFile)
        csvFile = fopen('_log1.csv', 'w');
        fprintf(csvFile, 'time,x,y,z,yaw,totalWeight,centroidCol,centroidRow,yawAngle\n');
    end
    t_now = now;
    fprintf(csvFile, '%.10f,%.4f,%.4f,%.4f,%.4f,%d,%.1f,%.1f,%.4f\n', t_now, x, y, z, yaw, totalWeight, centroidCol, centroidRow, yawAngle);
end
