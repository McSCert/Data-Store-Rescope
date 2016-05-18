function system = gts
%GTS Gets top level system of the current open system.

    address = gcs;
    numChars = strfind(address, '/');
    if ~isempty(numChars)
        system = address(1:numChars(1)-1);
    else
        system = address;
    end

end

