{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE TypeFamilies              #-}
import Data.Colour
import System.Random
import Data.List
import Diagrams.Prelude
import Diagrams.Backend.SVG.CmdLine

point :: Double -> Double -> Diagram B
point x y = circle 1 # translateX x # translateY y # fc black

diagram4 :: Diagram B
diagram4 =  point 0 0 

main = mainWith diagram4
