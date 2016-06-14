function s = removeNewline(string)
% REMOVENEWLINE Replaces newlines with spaces
% M. Bialy
    if ischar(string)
        s = string;
        s(s == char(10)) = ' ';
    end
end