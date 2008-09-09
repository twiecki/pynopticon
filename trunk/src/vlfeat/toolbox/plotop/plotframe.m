function h=plotframe(frames,varargin)
% PLOTFRAME  Plot feature frame
%  PLOTFRAME(FRAME) plots the frames FRAME.  Frames are attributed
%  image regions (as, for example, extracted by a feature detector). A
%  frame is a vector of D=2,3,..,6 real numbers, depending on its
%  class. PLOTFRAME() supports the following classes:
%
%   * POINTS
%     + FRAME(1:2)   coordinates
%
%   * CIRCLES
%     + FRAME(1:2)   center
%     + FRAME(3)     radius
%
%   * ORIENTED CIRCLES
%     + FRAME(1:2)   center
%     + FRAME(3)     radius
%     + FRAME(4)     orientation
%
%   * ELLIPSES
%     + FRAME(1:2)   center
%     + FRAME(3:5)   S11, S12, S22 of x' inv(S) x = 1.
%
%   * ORIENTED ELLIPSES
%     + FRAME(1:2)   center
%     + FRAME(3:6)   A(:) of ELLIPSE = A UNIT_CIRCLE
%
%  H=PLOTFRAME(...) returns the handle of the graphical object
%  representing the frames.
%
%  PLOTFRAME(FRAMES) where FRAMES is a matrix whose column are FRAME
%  vectors plots all frames simultaneously. Using this call is much
%  faster than calling PLOTFRAME() for each frame.
%
%  PLOTFRAME(FRAMES,...) passes any extra argument to the underlying
%  plot function. The first optional argument can be a line
%  specification string such as the one used by PLOT().

% AUTORIGHTS
% Copyright 2007 (c) Andrea Vedaldi and Brian Fulkerson
% 
% This file is part of VLFeat, available in the terms of the GNU
% General Public License version 2.

% number of vertices drawn for each frame
np        = 40 ;

lineprop = {} ;
if length(varargin) > 0 
  lineprop = linespec2prop(varargin{1}) ;
  lineprop = {lineprop{:}, varargin{2:end}} ;
end

% --------------------------------------------------------------------
%                                         Handle various frame classes
% --------------------------------------------------------------------

% if just a vector, make sure it is column
if(min(size(frames))==1)
  frames = frames(:) ;
end
  
[D,K] = size(frames) ;
zero_dimensional = D==2 ;

% just points?
if zero_dimensional
  h = plot(frames(1,:),frames(2,:),'g.',lineprop{:}) ;
  return ;
end

% reduce all other cases to ellipses/oriented ellipses 
frames    = frame2oell(frames) ;
do_arrows = (D==4 || D==6) ;

% --------------------------------------------------------------------
%                                                                 Draw
% --------------------------------------------------------------------

K   = size(frames,2) ;
thr = linspace(0,2*pi,np) ;

% allx and ally are nan separated lists of the vertices describing the
% boundary of the frames
allx = nan*ones(1, np*K+(K-1)) ;
ally = nan*ones(1, np*K+(K-1)) ;

if do_arrows
  % allxf and allyf are nan separated lists of the vertices of the
  allxf = nan*ones(1, 3*K) ;
  allyf = nan*ones(1, 3*K) ;
end

% vertices around a unit circle
Xp = [cos(thr) ; sin(thr) ;] ;

for k=1:K
  
  % frame center
	xc = frames(1,k) ;
	yc = frames(2,k) ;
  
  % frame matrix
  A = reshape(frames(3:6,k),2,2) ;

  % vertices along the boundary
  X = A * Xp ;
  X(1,:) = X(1,:) + xc ;
  X(2,:) = X(2,:) + yc ;
  		
  % store 
	allx((k-1)*(np+1) + (1:np)) = X(1,:) ;
	ally((k-1)*(np+1) + (1:np)) = X(2,:) ;

  if do_arrows
    allxf((k-1)*3 + (1:2)) = xc + [0 A(1,1)] ;
    allyf((k-1)*3 + (1:2)) = yc + [0 A(2,1)] ;
  end

end

if do_arrows
  h = line([allx nan allxf], ...
           [ally nan allyf], ...
           'Color','g','LineWidth',3, ...
           lineprop{:}) ;
else
  h = line(allx, ally, ...
           'Color','g','LineWidth',3, ...
           lineprop{:}) ;
end


% --------------------------------------------------------------------
function eframes = frame2oell(frames)
% FRAMES2OELL  Convert generic frame to oriented ellipse
%   EFRAMES = FRAME2OELL(FRAMES) converts the frames FRAMES to
%   oriented ellipses EFRAMES. This is useful because many tasks are
%   almost equivalent for all kind of regions and are immediately
%   reduced to the most general case.

%
% Determine the kind of frames
%
[D,K] = size(frames) ;

switch D
  case 2
    kind = 'point' ;
       
  case 3
    kind = 'disk' ;
    
  case 4 
    kind = 'odisk' ;
    
  case 5
    kind = 'ellipse' ;
    
  case 6
    kind = 'oellipse' ;
    
  otherwise 
    error(['FRAMES format is unknown']) ;
end

eframes = zeros(6,K) ;

%
% Do converison
%
switch kind
  case 'point'
    eframes(1:2,:) = frames(1:2,:) ;

  case 'disk'
    eframes(1:2,:) = frames(1:2,:) ;
    eframes(3,:)   = frames(3,:) ;
    eframes(6,:)   = frames(3,:) ;
    
  case 'odisk' 
    r = frames(3,:) ;
    c = r.*cos(frames(4,:)) ;
    s = r.*sin(frames(4,:)) ;

    eframes(1:2,:) = frames(1:2,:) ;
    eframes(3:6,:) = [c ; s ; -s ; c] ;

  case 'ellipse'
%    sz = find(1e6 * abs(eframes(3,:)) < abs(eframes(4,:)+eframes(5,:))
    
    eframes(1:2,:) = frames(1:2,:) ;
    
    eframes(3,:) = sqrt(frames(3,:)) ;
    eframes(4,:) = frames(4,:) ./ (eframes(3,:)+eps) ;
    eframes(5,:) = zeros(1,K) ;
    eframes(6,:) = sqrt(frames(5,:) - ...
                        frames(4,:).*frames(4,:)./(frames(3,:)+eps)) ;
  case 'oellipse' 
    eframes = frames ;
end    
