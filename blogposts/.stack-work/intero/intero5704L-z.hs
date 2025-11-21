{-# LANGUAGE GADTs #-}
import Data.Array
data Structure = Paired Int (Structure, Structure) | Slip Structure | Empty

testStrand :: String
testStrand = "GAAACCCCUUUUGGGG"

baseEnergy :: String -> Int -> Int -> Double
baseEnergy string i j = case (string !! i, string !! j) of
  ('A', 'U') -> -1
  ('G', 'C') -> -1
  ('U', 'A') -> -1 
  ('C', 'G') -> -1 
  otherwise -> 0

energyModel :: String -> Structure -> Double
energyModel [] s = 0
energyModel strand (Paired i (s1,s2)) =
  (baseEnergy strand 0 i) + -- energy of pair
  (energyModel sub1 s1) + -- energy of substructure under pair
  (energyModel sub2 s2) -- energy of substructure after pair
  where
    sub1 = take i strand
    sub2 = drop i strand    
energyModel strand (Slip s) = energyModel (tail strand) s
energyModel strand Empty = 0 

type PFunArray = Array (Int, Int) Double

partitionFunction :: String -> PFunArray
partitionFunction strand = arr                           
  where
    len = length strand
    arr = array ((0,0), (len - 1, len - 1))
--          [((i,j), (pfCell i j strand arr)) | i <- [0..len-1], j <- [i..len-1]]
          [((i,j), 1) | i <- [0..len-1], j <- [i..len-1]]  

pfCell :: Int -> Int -> String -> PFunArray -> Double
pfCell i j strand arr = if (i==j) then 1 else (sum pairTerms) +  slipTerm
  where
    pairTerm i k = boltz (baseEnergy strand i k) *
                   (if k-i > 2 then arr ! (i+1, k-1) else 1) *
                   (if j-k > 2 then arr ! (k+1, j-1) else 1)
    pairTerms = [pairTerm i k | k <- [(i+1)..j]]
    slipTerm  = if i == j then 1 else arr ! (i+1, j)
    boltz x = exp (-x)

sampleStructure :: Int -> Int -> PFunArray -> StdGen -> Structure
sampleStructure i j arr gen = if (i == j) then Empty else struct
  where
    -- (cumulative probability, structure) pairs
    slipCase = (arr ! (i + 1, j), Slip  (sampleStructure (i+1) j arr))    
    pairTerm i k = boltz (baseEnergy strand i k) *
                   (if k-i > 2 then arr ! (i+1, k-1) else 1) *
                   (if j-k > 2 then arr ! (k+1, j-1) else 1)
    pairTerms = [pairTerm i k | k <- [(i+1)..j]]
    pairCases = unfold 
