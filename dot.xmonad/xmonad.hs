{-# LANGUAGE FlexibleContexts #-}
-- Ondřej Súkup xmonad config ...
-- main import
import XMonad
-- xmonad hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
--xmonad actions
import XMonad.Actions.CycleWS
import XMonad.Actions.GridSelect
import XMonad.Actions.Submap
--xmonad utils
import XMonad.Util.Cursor
import XMonad.Util.EZConfig
import XMonad.Util.NamedWindows
import XMonad.Util.Scratchpad
import XMonad.Util.SpawnOnce (spawnOnce)
import XMonad.Util.Themes
--xmonad layouts
import XMonad.Layout.Fullscreen hiding (fullscreenEventHook)
import XMonad.Layout.LayoutHints
import XMonad.Layout.LayoutModifier
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Tabbed
-- import xmonad promt
import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.Ssh
-- qualified imports of Data and Stack
import qualified XMonad.StackSet as W
import qualified Data.Map as M
-- general import
import Control.Applicative
import Graphics.X11.ExtraTypes.XF86
-- taffybar
import System.Taffybar.Support.PagerHints (pagerHints)

------------------------------------------------------------------------
promptConfig :: XPConfig
promptConfig =
  def {font = "xft:Source Code Pro:pixelsize=14"
                  ,borderColor = "#1e2320"
                  ,height = 18
                  ,position = Top}
------------------------------------------------------------------------
myWorkspaces :: [WorkspaceId]
myWorkspaces = ["1:main", "2:www", "3:chat", "4:IDE", "5:www-stack", "6:music","7", "8", "9", "0", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10","F11", "F12"]


-- mod-[1..9] %! Switch to workspace N
-- mod-shift-[1..9] %! Move client to workspace N
myKeys conf = M.fromList
       [((m .|. modMask conf, k), windows $ f i)
        | (i, k) <- zip myWorkspaces ([xK_1 .. xK_9] ++ [xK_0] ++ [xK_F1 .. xK_F12])
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]


------------------------------------------------------------------------
-- add mouse buttons
button8 = 8 :: Button
button9 = 9 :: Button
------------------------------------------------------------------------
-- Layouts:
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--
myBorders = lessBorders (Combine Union Screen OnlyFloat)

myLayout =
  avoidStruts $
  myBorders $
  layoutHintsToCenter  $
  onWorkspace "1:main"
              ( tab ||| full ||| tiled ||| mtiled) $
  onWorkspaces ["2:www","3:chat"]
              full $
    full ||| tiled ||| mtiled
  where
        -- default tiling algorithm partitions the screen into two panes
        tiled = Tall nmaster delta ratio
        -- The default number of windows in the master pane
        nmaster = 1
        -- Default proportion of screen occupied by master pane
        ratio =
          toRational (2 / (1 + sqrt 5 :: Double))
        -- Percent of screen to increment by when resizing panes
        delta = 5 / 100
        -- tab is tabbed
        tab =
          tabbed shrinkText (theme smallClean)
        -- full is Full
        full =
          (fullscreenFloat . fullscreenFull) Full
        -- mtiled is mirrortiled
        mtiled = Mirror tiled
------------------------------------------------------------------------
-- Window rules:
-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook :: ManageHook
myManageHook =
  composeAll $
  [isDialog --> doFloat] ++
  [appName =? r --> doIgnore | r <- myIgnores] ++
  [className =? c --> doCenterFloat | c <- myFloats] ++
  [appName =? r --> doShift wsp | (r,wsp) <- myWorkspaceMove]
  -- fulscreen windows to fullfloating
  ++
  [isFullscreen --> doFullFloat] ++
  -- unmanage docks such as gnome-panel and dzen
  [fullscreenManageHook
  ,scratchpadManageHookDefault
  ,manageDocks]
  where
        -- windows to operate
        myIgnores =
          ["desktop","kdesktop","desktop_window"]
        myFloats =
          ["Steam","steam","vlc","Vlc","mpv"]
        myWorkspaceMove =
          [("google-chrome","2:www")
          ,("urxvt","1:main")
          ,("weechat","3:chat")]

------------------------------------------------------------------------
-- Event handling
--
-- * EwmhDesktops users should change this to ewmhDesktopsEventHook
--
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
myEventHook = fullscreenEventHook <+> hintsEventHook <+> docksEventHook
------------------------------------------------------------------------
-- myStartupHook
myStartupHook :: X ()
myStartupHook =
  do setDefaultCursor xC_left_ptr
     -- setWMName "LG3D"
     spawnOnce "xrdb -merge ~/.Xdefaults"
     spawnOnce "xsetroot -solid black"
     spawnOnce "status-notifier-watcher"
     spawnOnce "taffybar"
     -- spawnOnce "compton -fb"
     --     spawnOnce "urxvtd-256color -f -q -o"
     -- spawnOnce "/home/mimi/.fehbg"
------------------------------------------------------------------------
-- Urgency Hook:
--
-- Use libnotify notifications when the X11 urgent hint is set
data LibNotifyUrgencyHook =
  LibNotifyUrgencyHook
  deriving (Read,Show)
instance UrgencyHook LibNotifyUrgencyHook where
  urgencyHook LibNotifyUrgencyHook w =
    do name <- getName w
       wins <- gets windowset
       whenJust (W.findTag w wins)
                (flash name)
    where flash name index = spawn $
                             "notify-send " ++
                             "'Workspace " ++
                             index ++
                             "' " ++ "'Activity in: " ++ show name ++ "' "
------------------------------------------------------------------------
--
-- |
-- Helper function which provides ToggleStruts keybinding
--
-- toggleStrutsKey :: XConfig t -> (KeyMask,KeySym)
-- toggleStrutsKey XConfig{modMask = modm} =
--  (modm,xK_b)
------------------------------------------------------------------------
-- xmobar from XMonad.Hooks.DynamicLog with scratchpad filter
--
-- myXmobar
--   :: LayoutClass l Window
--   => XConfig l -> IO (XConfig (ModifiedLayout AvoidStruts l))
-- myXmobar =
--   statusBar "xmobar"
--             xmobarPP {ppSort = (. scratchpadFilterOutWorkspace) Control.Applicative.<$>
--                                ppSort def}
--             toggleStrutsKey
-------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.
main :: IO ()
-- main = xmonad =<< myXmobar defaults
main = xmonad defaults
------------------------------------------------------------------------
myUrgencyHook =
  withUrgencyHook LibNotifyUrgencyHook

defaults =
  myUrgencyHook $
  ewmh $
  pagerHints $
  def {terminal = "urxvt"
                ,borderWidth = 2
                ,modMask = mod4Mask
                ,workspaces = myWorkspaces
                ,layoutHook = myLayout
                ,manageHook = myManageHook
                ,handleEventHook = myEventHook
                ,startupHook = myStartupHook
                ,keys = keys defaultConfig <+> myKeys } `additionalKeys`
  [((mod4Mask,xK_g),goToSelected def) -- Gridselect
  ,((mod4Mask,xK_Print),spawn "scrot '%F-%H-%M-%S.png' -e 'mv $f ~/Shot/'") -- screenshot
  ,((mod4Mask,xK_s),scratchpadSpawnActionTerminal "urxvt") -- scratchpad
  ,((mod4Mask .|. controlMask,xK_p)
   ,submap . M.fromList $ -- add submap Ctrl+Win+P,key
    [((0,xK_q),spawn "urxvt")
    ,((0,xK_w),spawn "google-chrome")
    ,((0,xK_s),sshPrompt promptConfig)])
  ,((mod4Mask,xK_p),shellPrompt promptConfig)
  ,
   --        , ((mod4Mask  .|. shiftMask     , xK_p          ), passPrompt promptConfig  )
   ((mod4Mask .|. shiftMask,xK_z),spawn "i3lock -c 101010")
  ,((0,xF86XK_AudioMute),spawn "pulseaudio-ctl mute")
  ,((0,xF86XK_AudioRaiseVolume),spawn "pulseaudio-ctl up")
  ,((0,xF86XK_AudioLowerVolume),spawn "pulseaudio-ctl down")
  ,((0,xF86XK_MonBrightnessUp),spawn "xbacklight +5")
  ,((0,xF86XK_MonBrightnessDown),spawn "xbacklight -5")
  ,((mod4Mask,xK_b),sendMessage ToggleStruts)] `additionalMouseBindings`
  [((0,button8),const prevWS) -- cycle Workspace up
  ,((0,button9),const nextWS) -- cycle Workspace down
   ]
