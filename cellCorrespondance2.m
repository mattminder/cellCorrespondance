function [newCurr, lostOnes] = cellCorrespondance2(prev, curr)
% Ensures that number between current and previous frame correspond
% Prev and curr are both masks obtained with cellWatershed
%
% For every cell in the current frame, looks at to which cells its pixels
% belonged in the previous frame. Then it takes the cell id with the
% largest amount of pixels in common to be the cell number.
%
% Exception to this:
% If a cell is determined to be background, it is considered
% as a new cell and given a new id. 

% Notes for improvement: By far the most time is spent on getting the
% counts. Could be made faster by subsampling the map.

prevToCurr = getMap(curr, prev);
currToPrev = getMap(prev, curr);
reassignMap = containers.Map(0,0);

% Find all previous that were lost, and all the current that worked
lostOnes = [];
goodOnes = [];
for from=prevToCurr.keys
    from = from{1};
    to = prevToCurr(from);
    backToFrom = currToPrev(to);
    if from~=backToFrom
        lostOnes = [lostOnes, from];
    else
        goodOnes = [goodOnes, to];
        reassignMap(to) = from;
    end
end

% Find all current that map to zero (and thus are new)
newOnes = [];
counter = double(max(prev(:))+1);
for from=currToPrev.keys
    from = from{1};
    to = currToPrev(from);
    if to==0 && from~=0
        newOnes = [newOnes, from];
        reassignMap(from) = counter;
        counter = counter+1;
    end
end
        
% Find all current that have a problem, match them to cell number >9000
currProb = setdiff(setdiff(unique(curr), goodOnes), newOnes);
probCounter=9001;
if ~isempty(currProb)
    for x=currProb'
        display(x)
        reassignMap(x) = probCounter;
        probCounter = probCounter+1;
    end
end

% Create new mask
newCurr = curr;
for x=reassignMap.keys
    x = x{1};
    newCurr(curr==x) = reassignMap(x);
end
    
end


function out = inner(c, v)
% Takes counts and values, returns value with highest count
[~, maxix] = max(c);
out = v(maxix);
end


function map = getMap(im1, im2)
map = [im1(:), im2(:)];
[unique_rows,~,ix] = unique(map, 'rows');
counts = histcounts(categorical(ix), categorical(1:max(ix)));

% Group by current cell, find cell from previous with the largest overlap
[g, oldval] = findgroups(unique_rows(:,2));
newval = splitapply(@inner, counts', unique_rows(:,1), g);
map = containers.Map(oldval, newval);
end

