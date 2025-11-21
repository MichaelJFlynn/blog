{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE TypeFamilies              #-}
import Data.Array
import Data.Time.Clock.POSIX 
import Data.Colour
import System.Random
import Data.List
import Diagrams.Prelude
import Diagrams.Backend.PGF.CmdLine

fourierWire :: Double -> Int -> Diagram B
fourierWire level n = (hrule 1 <> text ("$f(" ++ (show n) ++ ")$") # fontSize (local 0.5) # translateX (-1.25)) #  translateY level

leftArms ::  Diagram B
leftArms  =  
  fourierWire 0.5 4 <>
  fourierWire 1.5 3 <>
  fourierWire 2.5 2 <>
  fourierWire 3.5 1 <>
  fourierWire (-0.5) 5 <>
  fourierWire (-1.5) 6 <>
  fourierWire (-2.5) 7 <>
  fourierWire (-3.5) 8


ftBox :: Diagram B
ftBox = square 9 <> text "Discrete Fourier Transform" # fontSize (local 0.5)

diagram1 :: Diagram B
diagram1 = leftArms <> (ftBox # translateX 5) 

main = defaultMain diagram1
