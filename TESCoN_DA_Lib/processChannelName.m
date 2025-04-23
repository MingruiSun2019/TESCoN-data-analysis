function validFieldName = processChannelName(inputString)
    % Remove all spaces at the rear of the string
    trimmedString = regexprep(inputString, '\s+$', '');
    
    % Replace remaining spaces with underscores
    inputStr = strrep(trimmedString, ' ', '_');

    % Remove "(" and ")"
    inputStr = strrep(inputStr, '(', '');
    result = strrep(inputStr, ')', '');

    idx = regexp(result, '[a-zA-Z]'); % Find the index of the first English character
    if isempty(idx)
        validFieldName = ''; % Return empty if no English character is found
    else
        validFieldName = extractAfter(result, idx(1) - 1); % Extract from the first English character
    end
end