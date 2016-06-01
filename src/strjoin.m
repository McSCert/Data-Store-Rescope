function output = strjoin(input, separator)

% http://www.mathworks.com/matlabcentral/fileexchange/31862-strjoin
%
% Copyright (c) 2011, Kota Yamaguchi
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

  if nargin < 2, separator = ','; end
  assert(ischar(separator), 'Invalid separator input: %s', class(separator));
  separator = strrep(separator, '%', '%%');

  output = '';
  if ~isempty(input)
    if ischar(input)
      input = cellstr(input);
    end
    if isnumeric(input) || islogical(input)
      output = [repmat(sprintf(['%.15g', separator], input(1:end-1)), ...
                       1, ~isscalar(input)), ...
                sprintf('%.15g', input(end))];
    elseif iscellstr(input)
      output = [repmat(sprintf(['%s', separator], input{1:end-1}), ...
                       1, ~isscalar(input)), ...
                sprintf('%s', input{end})];
    elseif iscell(input)
      output = strjoin(cellfun(@(x)strjoin(x, separator), input, ...
                               'UniformOutput', false), ...
                       separator);
    else
      error('strjoin:invalidInput', 'Unsupported input: %s', class(input));
    end
  end
end