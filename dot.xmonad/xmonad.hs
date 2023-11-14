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
import XMonad.Util.NamedScratchpad
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
import PagerHints
------------------------------------------------------------------------
promptConfig :: XPConfig
promptConfig =
  def {font = "xft:Source Code Pro:pixelsize=20"
                  ,borderColor = "#1e2320"
                  ,height = 40
                  ,position = Top}
------------------------------------------------------------------------
myWorkspaces :: [WorkspaceId]
myWorkspaces = ["1:main", "2:www", "3", "4:IDE", "5:www-stack", "6:music","7", "8", "9", "0", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10","F11", "F12:chat"]


-- mod-[1..9] %! Switch to workspace N
-- mod-shift-[1..9] %! Move client to workspace N
myKeys conf = M.fromList
       [((m .|. modMask conf, k), windows $ f i)
        | (i, k) <- zip myWorkspaces ([xK_1 .. xK_9] ++ [xK_0] ++ [xK_F1 .. xK_F12])
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]


------------------------------------------------------------------------
-- add mouse buttons
-- button8 = 8 :: Button
-- button9 = 9 :: Button
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
-- myBorders = lessBorders (Combine Union Screen OnlyFloat)
myBorders = lessBorders (Combine Union Screen OnlyScreenFloat)

myLayout =
  avoidStruts $
  myBorders $
  layoutHintsToCenter  $
  onWorkspace "1:main"
              ( tab ||| full ||| tiled ||| mtiled) $
  onWorkspaces ["2:www","F12:chat"]
              tab $
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
          (fullscreenFloat) Full
          --(fullscreenFull) Full -- not working!
          -- fullscreenFull Full -- not working!
          --(fullscreenFloat . fullscreenFull) not working!
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
  [title =? r --> doIgnore | r <- myIgnoresTitles] ++
  [className =? c --> doCenterFloat | c <- myFloats] ++
  [appName =? r --> doShift wsp | (r,wsp) <- myWorkspaceMove]
  -- fulscreen windows to fullfloating
  ++
  [isFullscreen --> doFullFloat] ++
  -- unmanage docks such as gnome-panel and dzen
  [fullscreenManageHook
  , namedScratchpadManageHook scratchpads
  ]
  where
        -- windows to operate
        myIgnoresTitles =
          [" "] -- Webex makes a black window due to transparency effects.. and no good prop identity.
        myIgnores =
          ["desktop","kdesktop","desktop_window"]
        myFloats =
          ["Steam","steam","vlc","Vlc","mpv", "gcr-prompter", "Gcr-prompter", "Webex"]
        myWorkspaceMove =
          [("google-chrome","2:www")
          --,("urxvt","1:main")
          ,("weechat","3:chat")]


scratchpads = [
  NS "scratch" "urxvt -name scratch"
    (appName =? "scratch")
    (customFloating $ W.RationalRect  (2/4) (1/4) (2/4) (2/4))
  , NS "cal" "google-chrome --app='https://calendar.google.com/b/0/r'"
    (className =? "Google-chrome" <&&> appName =? "calendar.google.com__b_0_r")
    (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3))
  , NS "pavucontrol" "pavucontrol"
    (className =? "Pavucontrol")
    (customFloating $ W.RationalRect (1/4) (1/4) (2/4) (2/4))
    ]


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
     setWMName "LG3D"
     spawn "systemctl --user start wm.target"
     spawnOnce "xrdb -merge ~/.Xdefaults"
     spawnOnce "xsetroot -solid black"
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
  docks $
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
  ,((mod4Mask,xK_Print),spawn "flameshot gui") -- screenshot
  ,((controlMask, xK_Print),spawn "sleep 0.2 && scrot '%F-%H-%M-%S-window-select.png' --select -e 'mv $f ~/Shot/'") -- screenshot, select area with mouse
  ,((mod1Mask, xK_Print),spawn "scrot '%F-%H-%M-%S-window-focus.png' --focused -e 'mv $f ~/Shot/'") -- screenshot focused window
  ,((mod4Mask,xK_s)
   , submap. M.fromList $ -- add submap to Super+S
     [((0, xK_s), namedScratchpadAction scratchpads "scratch"), -- Super+S and s
      ((0, xK_c), namedScratchpadAction scratchpads "cal"), -- Super+S and c
      ((0, xK_p), namedScratchpadAction scratchpads "pavucontrol")
    ])
  ,((mod4Mask .|. controlMask,xK_p)
   ,submap . M.fromList $ -- add submap Ctrl+Win+P,key
    [((0,xK_q),spawn "urxvt")
    ,((0,xK_w),spawn "google-chrome")
    ,((0,xK_s),sshPrompt promptConfig)])
  -- , ((mod4Mask,xK_p),shellPrompt promptConfig) -- Built in xmonad prompt , disabled when using rofi
  ,((mod1Mask .|. controlMask, xK_k)
   ,submap . M.fromList $ -- add submap Ctrl+Alt+K,key  , kubernetes shortcuts
    [((0,xK_k),spawn "KUBECTX_IGNORE_FZF=1 kubectx | rofi -dmenu -i | KUBECTX_IGNORE_FZF=1 xargs kubectx"),
     ((0,xK_i), spawn "change-keyboard"),
     ((0,xK_c), spawn "change-gcloud")
    ])
  ,((mod1Mask .|. controlMask, xK_g)
   ,submap . M.fromList $ -- add submap Ctrl+Alt+K,key  , chrome shortcuts
    [((0,xK_y),spawn "split_current_chrome_tab"),
     ((0,xK_h), spawn "split_current_chrome_tab_norangshol")
    ])
  ,((mod1Mask .|. shiftMask, xK_r), spawn "rofi-systemd")
  , ((mod4Mask, xK_p), spawn "rofi -show run")
  , ((mod4Mask .|. shiftMask, xK_p), spawn "rofi -show drun -show-icons")
  --        , ((mod4Mask  .|. shiftMask     , xK_p          ), passPrompt promptConfig  )
  ,((mod4Mask .|. shiftMask,xK_z),spawn "i3lock -c 101010")
  ,((0,xF86XK_AudioMute),spawn "pulseaudio-ctl mute")
  ,((0,xF86XK_AudioRaiseVolume),spawn "pulseaudio-ctl up")
  ,((0,xF86XK_AudioLowerVolume),spawn "pulseaudio-ctl down")
  ,((0,xF86XK_MonBrightnessUp),spawn "light -A 5")
  ,((0,xF86XK_MonBrightnessDown),spawn "light -U 5")
  ,((mod4Mask,xK_b),sendMessage ToggleStruts)] 

-- `additionalMouseBindings`
  -- [((0,button8),const prevWS) -- cycle Workspace up
  -- ,((0,button9),const nextWS) -- cycle Workspace down
  -- ]
