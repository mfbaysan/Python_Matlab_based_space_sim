function [pass] = mtlb_test_func(object,b_box)
    
    pathname = 'C:\Users\fatih\PycharmProjects\correlation_IDP\rcs_files' ;
    cd(pathname)
    rcs = load(object);
    
    signal = randi(10,20,1);
    pass = struct('BB',b_box,'Sinyal',signal)

    %location = "C:\Users\fatih\PycharmProjects\correlation_IDP";
    %filePattern = fullfile(location, "*.csv")
    %files = dir(filePattern)
    
    % note to myself: If you dont regard the passing datatype it doesnt work. 
    % pass a dictionary instead of tuple (to be more organized) /pass
    % struct it returns as dict