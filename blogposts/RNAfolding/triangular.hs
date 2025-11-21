import Data.Ix (Ix, range, index, inRange)

data UpperTriagIndex = Int :. Int deriving (Show, Ord, Eq)

instance Ix UpperTriagIndex where
  range (a :. b, c :. d) = concatMap (\i -> (i :.) <$> [max i b..d]) [a..c]
  inRange (a :. b, c :. d) (i :. j) = a <= i && i <= c && b <= j && j <= d

  index pr@(a :. b, c :. d) ix@(i :.j)
    | inRange pr ix = f a - f i + j - i
    | otherwise = error "out of range!"
    where
      f x = let s = d + 1 - max x b in s * (s+1) `div` 2
                                            
