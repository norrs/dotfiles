{-# LANGUAGE PackageImports #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where
import System.Taffybar
import System.Taffybar.Hooks
import System.Taffybar.Information.CPU
import System.Taffybar.SimpleConfig
import System.Taffybar.Widget
import System.Taffybar.Widget.Generic.Graph
import System.Taffybar.Widget.Generic.PollingGraph
import System.Taffybar.Information.EWMHDesktopInfo
import System.Taffybar.Information.X11DesktopInfo

--import           Data.List
--import           Data.List.Split
--import qualified Data.Map as M
--import           Data.Maybe
--
--import           System.IO
--import qualified Data.ByteString.Char8 as BS
--import           System.FilePath.Posix
--import           System.Directory
--import           Text.Printf
--import           Text.Read hiding (lift)
-- test
-- import System.Taffybar.DBus
--
cpuCallback = do
  (_, systemLoad, totalLoad) <- cpuLoad
  return [ totalLoad, systemLoad ]

main = do
--  homeDirectory <- getHomeDirectory
--  let resourcesDirectory = homeDirectory </> ".lib" </> "resources"
--      inResourcesDirectory file = resourcesDirectory </> file
--      highContrastDirectory =
--        "/" </> "usr" </> "share" </> "icons" </> "HighContrast" </> "256x256"
--      inHighContrastDirectory file = highContrastDirectory </> file
--      getIconFileName w@WindowData {windowTitle = title, windowClass = klass}
--        -- | "URxvt" `isInfixOf` klass = Just "urxvt.png"
--        -- | "Termite" `isInfixOf` klass = Just "urxvt.png"
--        -- | "Kodi" `isInfixOf` klass = Just "kodi.png"
--        | "@gmail.com" `isInfixOf` title &&
--            "chrome" `isInfixOf` klass && "Gmail" `isInfixOf` title =
--          Just "gmail.png"
--        | otherwise = Nothing
--      myIcons = scaledWindowIconPixbufGetter $
--                unscaledDefaultGetWindowIconPixbuf <|||>
--                (\size _ -> lift $ loadPixbufByName size "application-default-icon")
 
  let myWorkspacesConfig = defaultWorkspacesConfig { minIcons = 1
                                                   , widgetGap = 0
                                                   , showWorkspaceFn = hideEmpty
                                                   --, getWindowIconPixbuf = myIcons
                                                   }
      battery = textBatteryNew "$percentage$ - $time$"                                             
      clock = textClockNew Nothing "<span fgcolor='orange'>%a %b %_d %H:%M</span>" 1
      workspaces = workspacesNew myWorkspacesConfig
      windows = windowsNew defaultWindowsConfig
      layout = layoutNew defaultLayoutConfig
      tray = sniTrayNew
      --- tray = sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt
      simpleConfig = defaultSimpleTaffyConfig
              { monitorsAction = usePrimaryMonitor
                       , startWidgets =  workspaces : map (>>= buildContentsBox) [ layout, windows ]
                       , endWidgets = [ tray, clock, battery ]
                       }
--  dyreTaffybar $ withLogServer $ toTaffyConfig simpleConfig
  startTaffybar $ withLogServer $ toTaffyConfig simpleConfig
