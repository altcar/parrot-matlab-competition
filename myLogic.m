function myLogic(R, G, B)
    % Expose raw data to the global workspace for Path Planning to use
    global globalR globalG globalB
    globalR = R;
    globalG = G;
    globalB = B;
end