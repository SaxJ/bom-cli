{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Run (run) where

import Import
import System.IO (putStrLn)

run :: Options -> RIO App ()
run options = do
  xml <- liftIO $ getForecastXML $ optionsState options
  liftIO $ displayXML xml $ optionsCity options

getForecastXML :: String -> IO String
getForecastXML state = do
    connection <- easyConnectFTP "ftp.bom.gov.au"
    _ <- loginAnon connection
    (xml,_) <- getbinary connection $ mapState state
    --putStrLn $ show $ extract $ parseTags xml
    return xml

mapState :: String -> String
mapState s =
    let
        pth = "/anon/gen/fwo/"
        mp "wa" = "IDW12400.xml"
        mp "vic" = "IDV10751.xml"
        mp "tas" = "IDT13630.xml"
        mp "sa" = "IDS10037.xml"
        mp "qld" = "IDQ10605.xml"
        mp "nt" = "IDD10198.xml"
        mp "nsw" = "IDN11050.xml"
        mp "act" = mp "nsw"
        mp _ = mp "wa" -- default to WA, because we can
    in
        pth ++ (mp s)

displayXML :: String -> String -> IO ()
displayXML xml city = mapM_ displaySection $ sections (~== ("<area>" :: String)) tags
    where
        tags = parseTags xml
        displayPeriods ls = mapM_ putStrLn
            $ filter (\t -> length t /= 0) $ map (unpack . strip . pack . fromTagText) $ filter isTagText ls
        displaySection tgs = do
            (prettyPrint "header") $ fromAttrib "description" $ head tgs
            displayPeriods tgs

prettyPrint :: String -> String -> IO ()
prettyPrint "header" s = do
    setSGR [SetColor Foreground Vivid Green]
    putStrLn s
    setSGR [Reset]  -- Reset to default colour scheme
prettyPrint _ s = prettyPrint "header" s
