{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}
module Main (main) where

import Import
import Run
import RIO.Process
import Options.Applicative.Simple
import qualified Paths_bom_cli

main :: IO ()
main = do
  (options, ()) <- simpleOptions
    $(simpleVersion Paths_bom_cli.version)
    "BOM CLI options"
    "Customise weather display"
    (Options
       <$> switch (long "verbose" <> short 'v' <> help "Verbose output?")
       <*> strOption (long "city" <> short 'c' <> help "Australian city to get weather for.")
    )
    empty
  lo <- logOptionsHandle stderr (optionsVerbose options)
  pc <- mkDefaultProcessContext
  withLogFunc lo $ \lf ->
    let app = App
          { appLogFunc = lf
          , appProcessContext = pc
          , appOptions = options
          }
     in runRIO app (run options)
