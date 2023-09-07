% show result for PaiRS
% 20230601 Woii junwei.chen@uc3m.es UC3M EAP NextFlow
% v9

% settings
global folder table current_frame Scaler2Show X Y ColorMap CAxis
global OpenColorBar OpenQuiver XArrowDist YArrowDist Scale v_lock
global FrameJump FrameRate CAxis0 Scale0 flag_hist HistBins
Template = 'testIV_10_out_PaIRS_save2/PIV_*'; % 'folder/string_*'
Scaler2Show = 'U'; % U, V, CC, Info, SN
StartFrame = 1; % First Frame to show
OpenColorBar = 1; % 0: off
ColorMap = 'jet'; % the map of colour bar
CAxis = [0.06 0.24]; % the range of colour bar
OpenQuiver = 1; % 0: off
XArrowDist = 8; % distance of arrows
YArrowDist = 4;
Scale = 1; % amplification of arrows
FrameJump = 10; % frame jump when pressing PgUp/PgDn
FrameRate = 15; % FrameRate in video display
Position = [10 10 720 720]; % [left bottom width height] of the figure
HistBins = 128; % number of bins in histogram

% keyboard control:
% works on Englisch (US) keyboard
% ←/→: decrease/increase the range of colour bar
% ↑/↓: move the colour bar range up/downwards
% /: restore the range of colour bar
% 9: change the range of colour bar to 3-sigma
% 0: make the colour bar symmetric to 0
% [/]: decrease/increase the amplification rate of arrows
% \: restore the amplification rate of arrows
% z(Home)/m(End): go to first/last frame
% x(-)/n(=): go to previous/next frame
% PgUp/PgDn: go to previous/next frame by FrameJump
% c/b: play backward/forward
% v: pause

% h: switch to histogram of current scaler
% [/]: decrease/increase the scope of histogram
% ←/→: move the scope of histogram
% ↑/↓: increase/decrease the level of histogram
% 0: make the histogram symmetric to 0
% z(Home)/m(End): go to first/last frame
% x(-)/n(=): go to previous/next frame
% PgUp/PgDn: go to previous/next frame by FrameJump

% changing to other scalers
% u: U
% v: V
% p: correlation value (CC)
% i: vector choice (Info): peak 1, mean replacement 0, second peak 0.25
% s: signal-to-noise ratio (SN)
% a: magnitude
% d: divergence
% e: vorticity in z
% r: strength of rotation (TBC)
% q: q-criterion (TBC)

% start
table = dir(Template);
current_frame = StartFrame;
current_frame = max(current_frame, 1);
current_frame = min(current_frame, length(table));
folder = table(1).folder;
if numel(CAxis) == 1, CAxis = [-abs(CAxis) abs(CAxis)]; end
CAxis0 = CAxis;
Scale0 = Scale;
flag_hist = 0;
v_lock = 0;

% load average field
Mean = load([Template(1:end-2), '.mat']);
X = Mean.X;                    Y = Mean.Y;

% load and display start frame
figure;
if length(Position) == 4, set(gcf, 'position', Position); end
showFrame();

% waiting for event of pressing down buttens
set(gcf, 'WindowKeyPressFcn', @keyPressCallback);

function readFrame(current_frame)
% read the scaler field in the current frame
global folder table Scaler2Show scaler_field
if sum(matches(["U", "V", "CC", "Info", "SN"], Scaler2Show))
    current = load([folder, '/', table(current_frame).name], Scaler2Show);
    tmp = fieldnames(current);
    scaler_field = current.(tmp{1});
else
end
end

function showFrame()
% display the scaler field and arrow map
global folder table Scaler2Show X Y ColorMap CAxis scaler_field
global OpenColorBar OpenQuiver XArrowDist YArrowDist Scale current_frame
readFrame(current_frame);
pcolor(X, Y, scaler_field); shading flat; colormap(ColorMap);
axis equal;
xlim([min(X, [], 'all'), max(X, [], 'all')]);
ylim([min(Y, [], 'all'), max(Y, [], 'all')]);
title([Scaler2Show, ',   Frame: ', num2str(current_frame)]);
if length(CAxis) == 2, caxis(CAxis); end
if OpenColorBar, colorbar; end
if OpenQuiver
    hold on;
    load([folder, '/', table(current_frame).name], 'U', 'V');
    x_q = X(1, 1:XArrowDist:end);
    y_q = Y(1:YArrowDist:end, 1);
    u_q = U(1:YArrowDist:end, 1:XArrowDist:end);
    v_q = V(1:YArrowDist:end, 1:XArrowDist:end);
    quiver(x_q, y_q, u_q, v_q, Scale, 'k', 'LineWidth', 1);
    hold off;
end
set(gca, 'FontSize', 12);
end

function showHist()
% display the histogram of the scalar in current frame
global scaler_field Scaler2Show current_frame HistBins
if HistBins > 0, histogram(scaler_field, HistBins);
else, histogram(scaler_field); end
title([Scaler2Show, ',   Frame: ', num2str(current_frame)]);
set(gca, 'FontSize', 12);
end

function moveFrame(n)
% move frame by n and show
global current_frame table
current_frame = current_frame + n;
current_frame = max(current_frame, 1);
current_frame = min(current_frame, length(table));
end

function playFrame(n)
% play video
global FrameRate current_frame table v_lock
flag_state = '';
v_lock = 1;
while 1
    current_frame = current_frame + n;
    current_frame = max(current_frame, 1);
    current_frame = min(current_frame, length(table));
    showFrame();
    if current_frame == 1 | current_frame == length(table)
        break;
    end
    pause(1/FrameRate);
    key = get(gcf, 'CurrentKey');
    if strcmp(key,'z') & ~strcmp(flag_state,'z')
        current_frame = 1; flag_state = 'z';
        showFrame(); pause(1/FrameRate);
    end
    if strcmp(key,'c'), n =-1; end
    if strcmp(key,'v'),  break; end
    if strcmp(key,'b'), n = 1; end
    if strcmp(key,'m') & ~strcmp(flag_state,'m')
        current_frame = length(table); flag_state = 'm';
        showFrame(); pause(1/FrameRate);
    end
end
v_lock = 0;
end

function refreshFrame()
global flag_hist
if flag_hist == 0
    showFrame();
else
    readFrame(current_frame); showHist();
end
end

function keyPressCallback(~, event)
global current_frame FrameJump table CAxis CAxis0 Scale Scale0 flag_hist
global scaler_field Scaler2Show v_lock
if flag_hist == 0
    if     strcmp(event.Key, 'leftarrow')
        CAxis = (CAxis - mean(CAxis))/sqrt(2) + mean(CAxis);
        showFrame();
    elseif strcmp(event.Key, 'rightarrow')
        CAxis = (CAxis - mean(CAxis))*sqrt(2) + mean(CAxis);
        showFrame();
    elseif strcmp(event.Key, 'uparrow')
        CAxis = CAxis + 0.1*(CAxis(2)-CAxis(1)); showFrame();
    elseif strcmp(event.Key, 'downarrow')
        CAxis = CAxis - 0.1*(CAxis(2)-CAxis(1)); showFrame();
    elseif strcmp(event.Key, '9')
        s_mean = mean(scaler_field, 'all');
        s_std = std(scaler_field, 0, 'all');
        CAxis = s_mean + [-3*s_std 3*s_std]; showFrame();
    elseif strcmp(event.Key, '0')
        CAxis = CAxis - mean(CAxis); showFrame();
    elseif strcmp(event.Key, 'slash')
        CAxis = CAxis0; showFrame();
    elseif strcmp(event.Key, 'leftbracket')
        Scale = Scale/2^0.25; showFrame();
    elseif strcmp(event.Key, 'rightbracket')
        Scale = Scale*2^0.25; showFrame();
    elseif strcmp(event.Key, 'backslash')
        Scale = Scale0; showFrame();
    end
    if     strcmp(event.Key, 'home') | strcmp(event.Key, 'z')
        current_frame = 1; showFrame()
    elseif strcmp(event.Key, 'x')    | strcmp(event.Key, 'hyphen')
        moveFrame(-1); showFrame();
    elseif strcmp(event.Key, 'c'), playFrame(-1);
    elseif strcmp(event.Key, 'b'), playFrame(1);
    elseif strcmp(event.Key, 'n')    | strcmp(event.Key, 'equal')
        moveFrame(1);  showFrame();
    elseif strcmp(event.Key, 'end')  | strcmp(event.Key, 'm')
        current_frame = length(table); showFrame()
    elseif strcmp(event.Key, 'pageup')
        moveFrame(-FrameJump); showFrame();
    elseif strcmp(event.Key, 'pagedown')
        moveFrame(FrameJump);  showFrame();
    end
    if strcmp(event.Key, 'h'), showHist(); flag_hist = 1; end
else
    if strcmp(event.Key, 'h')
        showFrame(); flag_hist = 0; end
    if strcmp(event.Key, 'leftarrow')
        x_lim = xlim; xlim(x_lim - 0.1*(x_lim(2)-x_lim(1)));
    elseif strcmp(event.Key, 'rightarrow')
        x_lim = xlim; xlim(x_lim + 0.1*(x_lim(2)-x_lim(1)));
    elseif strcmp(event.Key, 'leftbracket')
        xlim((xlim - mean(xlim))/2^0.25 + mean(xlim));
    elseif strcmp(event.Key, 'rightbracket')
        xlim((xlim - mean(xlim))*2^0.25 + mean(xlim));
    elseif strcmp(event.Key, '0')
        xlim(xlim - mean(xlim));
    elseif strcmp(event.Key, 'uparrow')
        ylim(ylim*2^0.25);
    elseif strcmp(event.Key, 'downarrow')
        ylim(ylim/2^0.25);
    end
    if     strcmp(event.Key, 'home') | strcmp(event.Key, 'z')
        current_frame = 1;             readFrame(current_frame);
        x_lim = xlim; y_lim = ylim; showHist(); xlim(x_lim); ylim(y_lim);
    elseif strcmp(event.Key, 'x')    | strcmp(event.Key, 'hyphen')
        moveFrame(-1);                 readFrame(current_frame);
        x_lim = xlim; y_lim = ylim; showHist(); xlim(x_lim); ylim(y_lim);
    elseif strcmp(event.Key, 'n')    | strcmp(event.Key, 'equal')
        moveFrame(1);                  readFrame(current_frame);
        x_lim = xlim; y_lim = ylim; showHist(); xlim(x_lim); ylim(y_lim);
    elseif strcmp(event.Key, 'end')  | strcmp(event.Key, 'm')
        current_frame = length(table); readFrame(current_frame);
        x_lim = xlim; y_lim = ylim; showHist(); xlim(x_lim); ylim(y_lim);
    elseif strcmp(event.Key, 'pageup')
        moveFrame(-FrameJump);         readFrame(current_frame);
        x_lim = xlim; y_lim = ylim; showHist(); xlim(x_lim); ylim(y_lim);
    elseif strcmp(event.Key, 'pagedown')
        moveFrame(FrameJump);          readFrame(current_frame);
        x_lim = xlim; y_lim = ylim; showHist(); xlim(x_lim); ylim(y_lim);
    end
end
if     strcmp(event.Key, 'u')
    Scaler2Show = 'U'; refreshFrame();
elseif strcmp(event.Key, 'v')
    if v_lock == 0, Scaler2Show = 'V'; refreshFrame(); end
elseif strcmp(event.Key, 'p')
    Scaler2Show = 'CC'; refreshFrame();
elseif strcmp(event.Key, 'i')
    Scaler2Show = 'Info'; CAxis = [0 1]; refreshFrame();
elseif strcmp(event.Key, 's')
    Scaler2Show = 'SN'; refreshFrame();
end
% disp(event);
end