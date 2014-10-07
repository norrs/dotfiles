import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Fullscreen
import XMonad.Util.Run(spawnPipe)
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig(additionalKeys, additionalKeysP)
import System.IO
import System.Exit
import qualified Data.Map as M

myManageHook = composeAll . concat $
    [ [ className =? "Gimp"      --> doFloat]
    , [ className =? "Vncviewer" --> doFloat]
    , [ className =? "Chromium"  --> doShift "2:www"]
    ]

myWorkspaces = ["1:main", "2:www", "3:chat", "4:IDE", "5:www-stack", "6:music","7", "8", "9", "0", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10","F11", "F12"]


-- mod-[1..9] %! Switch to workspace N
-- mod-shift-[1..9] %! Move client to workspace N
myKeys conf = M.fromList
       [((m .|. modMask conf, k), windows $ f i)
        | (i, k) <- zip myWorkspaces ([xK_1 .. xK_9] ++ [xK_0] ++ [xK_F1 .. xK_F12])
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]


main = do
    xmproc <- spawnPipe "xmobar"
    xmonad $ defaultConfig
        { terminal = "urxvt"
        , manageHook = manageDocks <+> myManageHook <+> manageHook defaultConfig
        , handleEventHook = fullscreenEventHook <+> handleEventHook defaultConfig
        , startupHook = startupHook defaultConfig
        , workspaces = myWorkspaces <+> workspaces defaultConfig
        , layoutHook = avoidStruts  $  layoutHook defaultConfig
        , logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppTitle = xmobarColor "green" "" . shorten 50
                        }
        , modMask = mod4Mask     -- Rebind Mod to the Windows key
        , keys = keys defaultConfig <+> myKeys
        } `additionalKeys`
        [ ((mod4Mask .|. shiftMask, xK_z), spawn "gnome-screensaver-command -l")
        , ((controlMask, xK_Print), spawn "sleep 0.2; scrot -u")
        , ((0, xK_Print), spawn "scrot")
        ] `additionalKeysP`
        [ ("M-S-q", spawn "gnome-session-quit")
        , ("M-S-<Backspace>", io (exitSuccess))
        ]
