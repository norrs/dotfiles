{-# LANGUAGE OverloadedStrings #-}
import System.Directory
import System.Taffybar
import System.Taffybar.Hooks
import System.Taffybar.Information.CPU
import System.Taffybar.SimpleConfig
import System.Taffybar.Widget
import System.Taffybar.Widget.Generic.Graph
import System.Taffybar.Widget.Generic.PollingGraph
import System.Taffybar.Widget.Generic.PollingLabel
import System.Taffybar.Information.EWMHDesktopInfo
import Graphics.UI.Gtk
import System.IO
import System.Process.Typed
--import qualified "gtk" Graphics.UI.Gtk as Gtk
--import qualified System.IO as IO

-- test
-- import System.Taffybar.DBus
--
cpuCallback = do
  (_, systemLoad, totalLoad) <- cpuLoad
  return [ totalLoad, systemLoad ]

homeDirectory :: String

main :: IO()
main = do
  homeDirectory <- getHomeDirectory
  let myWorkspacesConfig = defaultWorkspacesConfig { minIcons = 1
                                                   , widgetGap = 0
                                                   , showWorkspaceFn = hideEmpty
                                                   }
      kubectx = customW 1 kubectxString
      battery = textBatteryNew "$percentage$ - $time$"                                             
      clock = textClockNew Nothing "<span fgcolor='orange'>%a %b %_d %H:%M</span>" 1
      workspaces = workspacesNew myWorkspacesConfig
      windows = windowsNew defaultWindowsConfig
      layout = System.Taffybar.Widget.layoutNew defaultLayoutConfig
      tray = sniTrayNew
      --- tray = sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt
      simpleConfig = defaultSimpleTaffyConfig
              { monitorsAction = usePrimaryMonitor
                       , startWidgets =  workspaces : map (>>= buildContentsBox) [ layout, windows ]
                       , endWidgets = [ tray, clock, battery, kubectx ]
                       }
  dyreTaffybar $ withLogServer $ toTaffyConfig simpleConfig

-- Read the active kubectl context
kubectxString :: IO String
kubectxString = do
  return readProcess "cat" [homeDirectory </> ".kube" </> "kubectx"]

-- | A simple textual battery widget that auto-updates once every
-- polling period (specified in seconds).
customW :: Double -- ^ Poll period in seconds
        -> IO String
        -> IO Graphics.UI.Gtk.Widget
customW interval f = do
    l <- pollingLabelNew "" interval f
    Graphics.UI.Gtk.widgetShowAll l
    return l
