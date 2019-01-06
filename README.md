# reshade-xhair
ReShade Crosshair Shader Overlay

![xhair-gui](./img/xhair-gui.png)

![xhair1](./img/xhair1.png)
![xhair2](./img/xhair2.png)
![xhair4](./img/xhair3.png)
![xhair5](./img/xhair4.png)
![xhair6](./img/xhair5.png)

## How to Install (for Killing Floor 2)

1. Navigate to your KF2 game folder located under `steamapps/common/killingfloor2/Binaries/Win64`.
2. Copy the "shaders" folder to your game folder.
3. Install ReShade 3.x (3.4.1 is recommended) from [`reshade-install/ReShade_Setup_3.4.1.exe`](./reshade-install/ReShade_Setup_3.4.1.exe).

    ![reshade-installer](./img/reshade-installer.png)
    1. Click "Select game" and select your game executable (`KFGame.exe`) located under `steamapps/common/killingfloor2/Binaries/Win64`.
    2. Check the "Direct3D 10+" option.
    3. Click "No" when prompted with a "Yes/No" dialog about downloading standard shaders.
    4. Click "Edit ReShade settings".
        1. Change the "Effects Path" to the `shaders` folder created in Step 2.
        2. (optional) Check "Skip Tutorial" if you're familiar enough with ReShade.
        3. Click "OK".
    5. Exit the ReShade installer.

4. Launch your game and open the ReShade overlay (shift-F2 by default).
