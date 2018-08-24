{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Run (run) where

import Import
import System.IO (putStrLn)

run :: Options -> RIO App ()
run options = do
  logInfo "We're inside the application!"
  xml <- liftIO $ getForecastXML $ optionsCity options
  liftIO $ displayXML xml
  --liftIO $ putStrLn xml

getForecastXML :: String -> IO String
getForecastXML state = do
    connection <- easyConnectFTP "ftp.bom.gov.au"
    _ <- loginAnon connection
    (xml,_) <- getbinary connection $ mapCity state
    --putStrLn $ show $ extract $ parseTags xml
    return xml

mapCity :: String -> String
mapCity s =
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

displayXML :: String -> IO ()
displayXML xml = mapM_ displaySection $ sections (~== ("<area>" :: String)) tags
    where
        tags = parseTags xml
        displayPeriods ls = mapM_ (prettyPrint "header")
            $ filter (\t -> length t /= 0) $ map (unpack . strip . pack . fromTagText) $ filter isTagText ls
        displaySection tgs = do
            putStrLn $ fromAttrib "description" $ head tgs
            displayPeriods tgs

prettyPrint :: String -> String -> IO ()
prettyPrint "header" s = do
    setSGR [SetColor Foreground Vivid Red]
    setSGR [SetColor Background Vivid Blue]
    putStrLn s
    setSGR [Reset]  -- Reset to default colour scheme
prettyPrint _ s = prettyPrint "header" s
