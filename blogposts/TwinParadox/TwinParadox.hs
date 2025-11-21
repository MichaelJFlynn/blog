{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE TypeFamilies              #-}
import Data.Colour
import System.Random
import Data.List
import Diagrams.Prelude
import Diagrams.Backend.SVG.CmdLine

ray :: Double -> Double -> Diagram B
ray len angle = hrule len # translateX (len / 2) # rotate (angle @@ deg)

point :: Double -> Double -> Diagram B
point x y = circle 1 # translateX x # translateY y # fc black

myGray = sRGB24read "#C5C8C9"
myBlue = sRGB24read "#00FFFF"

axes :: Diagram B
axes = axis <> timelabel <> xlabel 
  where
    timelabel = text "Time" # scale 4 # translateY 93 # translateX 8 # fc myGray
    xlabel = text "x" # scale 4 # translateY 5 # translateX 93 # fc myGray
    axis = (arrowBetween' options down up <> arrowBetween' options left right) # lc myGray
    options = with & arrowHead .~ spike & arrowTail .~ spike'
    down = p2 (0, -100)
    up = p2 (0, 100)
    left = p2 (-100, 0)
    right = p2 (100, 0)
    

-- bob is going 4/5 light speed
lightCone :: Diagram B
lightCone = (labeledaxis <> vrule 282) # lc (myGray) # rotate (45 @@ deg) # dashingG [1,1] 0
  where
    labeledaxis = hrule 282 <> text "Light Cone"
      # fc myGray
      # scale 4
      # translateY 2
      # translateX 125
      
clockLine :: Diagram B
clockLine =  arrowBetween (p2 (0,-90)) (p2 (0, 90)) # lc black # dashingG [1,1] 0 <> clocklabel
  where
    clocklabel = text "Clock" # scale 4 # translateY 85 # translateX 8 # fc black

thePresent :: Diagram B
thePresent = hrule 195 # lc black # dashingG [1,1] 0 <>
  text "The Present t=1" # scale 4 # translateY 2 # translateX 50

diagram1 :: Diagram B
diagram1 =  point 0 0 <>
  point 0 30 <> 
  point 30 30 <>
  text "Clock t=1" # lc black # scale 4 # translateX 40 # translateY 25 <>
  text "Us" # scale 4 # translateY 85 # translateX 8 # fc black <>
  point 0 60 <>
  arrowBetween (p2 (0,-90)) (p2 (0, 90)) # lc black # dashingG [1,1] 0  <>
  text "Us t=2" # lc black # scale 4 # translateY 58 # translateX (-10) <>
  text "Us t=1" # lc black # scale 4 # translateY 32 # translateX (-10) <>
  text "Us t=0" # lc black # scale 4 # translateY 2 # translateX (-10) <>
  thePresent # translateY 30 <>
  axes <>
  clockLine # translateX 30 <>
  lightPath 
  where
    lightTrail = fromVertices $ map p2 $ zip [0, 30, 0] [0, 30, 60]
    lightPath = lightTrail # lc red # dashingG [1,1] 0

bobsTrajectory :: Diagram B
bobsTrajectory = arrowBetween (p2 (-80,-100)) (p2 (80, 100)) # lc black # dashingG [1,1] 0 

thePresent2 :: Diagram B
thePresent2 = hrule 195 # lc black # dashingG [1,1] 0 <>
  text "The Present" # scale 4 # translateY 2 # translateX 50


diagram2 :: Diagram B
diagram2 =  point 0 0 <>
  point 0 30 <>
  point 24 30 <>
  point 0 6 <>
  point 0 54 <>
  text "Us" # scale 4 # translateY 85 # translateX 8 # fc black <>
  arrowBetween (p2 (0,-90)) (p2 (0, 90)) # lc black # dashingG [1,1] 0  <>
  -- point 8 10 <>
  -- point 0 18 <>
  -- point 72 90 <>
  -- point 40 50 <>
  bobsTrajectory <>
  text "Bob" # lc black # scale 4 # rotate (51.34 @@ deg) # translateY 90 # translateX 70 <>
  thePresent2 # translateY 30 <>
  axes <>  
  lightPath <>
  -- lightPath2 <>
  lightCone 
  where
    lightTrail = fromVertices $ map p2 $ zip [0, 24, 0] [6, 30, 54]
    lightPath = lightTrail # lc red # dashingG [1,1] 0
    lightTrail2 = fromVertices $ map p2 $ zip [8, 0, 72] [10, 18, 90]
    lightPath2 = lightTrail2 # lc myBlue # dashingG [1,1] 0

bobsTrajectory2 :: Diagram B
bobsTrajectory2 = arrowBetween (p2 (-60,-100)) (p2 (60, 100)) # lc black # dashingG [1,1] 0 

diagram3 :: Diagram B
diagram3 =  point 0 0 <>
  point 0 30 <>
  point 18 30 <>
  point 0 12 <>
  point 0 48 <>
  -- point 8 10 <>
  -- point 0 18 <>
  -- point 72 90 <>
  -- point 40 50 <>
  text "Us" # scale 4 # translateY 85 # translateX 8 # fc black <>
  text "The station" # scale 4 # translateY 32 # translateX (-10) # fc black <>
  arrowBetween (p2 (0,-90)) (p2 (0, 90)) # lc black # dashingG [1,1] 0  <>
  bobsTrajectory2 <>
  text "Bob" # lc black # scale 4 # rotate (59.04 @@ deg) # translateY 90 # translateX 50 <>
  thePresent2 # translateY 30 <>
  axes <>  
  lightPath 
  -- lightPath2 <>
  -- lightCone 
  where
    lightTrail = fromVertices $ map p2 $ zip [0, 18, 0] [12, 30, 48]
    lightPath = lightTrail # lc red # dashingG [1,1] 0
    lightTrail2 = fromVertices $ map p2 $ zip [8, 0, 72] [10, 18, 90]
    lightPath2 = lightTrail2 # lc myBlue # dashingG [1,1] 0

thePresent3 :: Diagram B
thePresent3 = hrule 195 # lc black # dashingG [1,1] 0 <>
  text "Our Present" # scale 4 # translateY 2 # translateX 50

bobsPresent :: Diagram B
bobsPresent = fromVertices (map p2 [(-100, -36), (100, 84)]) # lc black # dashingG [1,1] 0

diagram4 :: Diagram B
diagram4 =  point 0 0 <>
  point 0 30  <>
  point 18 30 <>
  point 0 12 <>
  point 0 48 <>
  point 9 15 <>
  point 0 24  <>
  point 36 60  <>
  point 22.5 37.5 <>
  text "Us" # scale 4 # translateY 85 # translateX 8 # fc black <>
  text "The station" # scale 4 # translateY 32 # translateX (-10) # fc black <>
  arrowBetween (p2 (0,-90)) (p2 (0, 90)) # lc black # dashingG [1,1] 0  <>
  bobsTrajectory2 <>
  text "Bob" # lc black # scale 4 # rotate (59.04 @@ deg) # translateY 90 # translateX 50 <>
  text "Bob's Present" # lc black # scale 4 # rotate (30.96 @@ deg) # translateX 60 # translateY 62 <> 
  thePresent3 # translateY 30 <>
  bobsPresent <>
  axes <>  
  lightPath <>
  lightPath2 
  where
    lightTrail = fromVertices $ map p2 $ zip [0, 18, 0] [12, 30, 48]
    lightPath = lightTrail # lc red # dashingG [1,1] 0
    lightTrail2 = fromVertices $ map p2 $ zip [9, 0, 36] [15, 24, 60]
    lightPath2 = lightTrail2 # lc myBlue # dashingG [1,1] 0



main = mainWith diagram4
