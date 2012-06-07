function retval = GetChennu(dontwait)

if nargin == 0
    dontwait = false;
end

if ~dontwait
    while(KbCheck(-1))
    end
end

retval = 0;

while true

    if ~dontwait
        FlushEvents('keyDown');
        KbWait(-1);
    end
    [ keyIsDown, seconds, keyCode ] = KbCheck(-1);

    if keyIsDown
        keysPressed = (keyCode ~= 0);

        if sum(keysPressed) == 1

            keyPressed = KbName(find(keysPressed));
            if ischar(keyPressed)
                switch keyPressed
                    case {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'}
                        retval = str2double(sprintf('%d', keyPressed));
                    case {'0)','1!','2@','3#','4$','5%','6^','7&','8*','9(','.>'}
                        retval = str2double(sprintf('%d', keyPressed(1)));
                    otherwise
                        retval = keyPressed;
                end
                %keyPressed
                FlushEvents('keyDown');
                return;
            end
        end
    end
    if dontwait
        return;
    end
end
end