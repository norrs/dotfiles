import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ICCCMFocus
import XMonad.Layout.Fullscreen
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Util.EZConfig(additionalKeysP)
import System.IO
import System.Exit

myManageHook = ( composeAll . concat $
    [ [ className =? "Gimp"      --> doFloat]
    , [ className =? "Vncviewer" --> doFloat]
    , [ className =? "Chromium"  --> doShift "2:www"]
    ])

myWorkspaces = ["1:main", "2:www", "3:chat", "4:IDE", "5:www-stack", "6:music", "7", "8", "9"]

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
        } `additionalKeys`
        [ ((mod4Mask .|. shiftMask, xK_z), spawn "gnome-screensaver-command -l")
        , ((controlMask, xK_Print), spawn "sleep 0.2; scrot -u")
        , ((0, xK_Print), spawn "scrot")
	] `additionalKeysP`
	[ ("M-S-q", spawn "gnome-session-quit")
	, ("M-S-<Backspace>", io (exitWith ExitSuccess))
        ]
