function result = processChannelName(inputString)
    % Remove all spaces at the rear of the string
    trimmedString = regexprep(inputString, '\s+$', '');
    
    % Replace remaining spaces with underscores
    inputStr = strrep(trimmedString, ' ', '_');

    % Remove "(" and ")"
    inputStr = strrep(inputStr, '(', '');
    result = strrep(inputStr, ')', '');
end