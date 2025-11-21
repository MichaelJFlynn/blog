Introduction
------------

Data science is a big word these days. It wows crowds, it stirs the
imagination! Dropping this phrase can be used to instantly placate
investors:

"We've got several projects coming down the pipeline: data science, deep
learning, and *cloud computing*."

"Wow, that's like AI. I like AI. AI is good. You're good. Have some
money."

You might be suprised to learn that there is actually useful tools in
the field outside of just marketing. Principle component analysis is an
incredibly useful tool for finding the <em>things</em> in your data. Why
might you do this? Well..

This tutorial is based on a [tutorial by Jonathan
Shlens](https://arxiv.org/pdf/1404.1100v1.pdf), expanded to be
"interactive" using R-markdown.

What is principle component analysis? In concrete terms, principle
component analysis is way to rotate your data's coordinate system into
the *most important* directions.

Obfuscation
-----------

A key example of PCA (lifted from the parent article) is a ball on a
string who's position is recorded by several different cameras. The
balls motion might be described as
*x*(*t*)=*x*<sub>0</sub>*c**o**s*(*ω**t*)
 around the equilibrium point, *x*<sub>0</sub> being the initial
stretched length and *ω* being the frequency. For a standard spring, *ω*
is related to the ratio of the spring constant to the mass of the ball
($\\omega = \\sqrt{\\frac{k}{m}}$), but to make things easy, I'm going
to plot *t* in units of 1/*ω* and *x* in units of *x*<sub>0</sub>. That
way, the equation of motion just becomes
*x*(*t*)=*c**o**s*(*t*).
 I can model this in R.

    library(ggplot2)
    library(tidyr)
    library(dplyr) 
    theme_set(theme_bw()) # set default theme to black-white
    t <- seq(0, 6*pi, by = .1)
    x <- cos(t)
    qplot(x = t, y = x) 

![](pca_files/figure-markdown_strict/unnamed-chunk-1-1.png)

So this is how the position *x* varies in time, between 1 and -1 of
*x*<sub>0</sub>, with a period of 2*π**ω*. However, we are in the real
world, and the real world has 3 spatial dimentions. Therefore I am going
to add a *y* and *z* to these points. Not only that, but the real world
has **noise** as well. I'm going to mix in a little bit of noise, in
every direction, with standard deviation about 1/10th the amplitude of
the wave.

    positions <- data.frame(t = seq(0, 6*pi, by = .1),
                            x = x + rnorm(length(x), sd = .1),
                            y = rnorm(length(x), sd = .1),
                            z = rnorm(length(x), sd = .1))

    ggplot(data = gather(positions, variable, value, x:z), aes(x = t, y = value)) +
        geom_point() +
        facet_wrap(~ variable, nrow = 1) 

![](pca_files/figure-markdown_strict/unnamed-chunk-2-1.png)

Above we can see 3 relationships, one of (mostly) signal, 2 with just
noise. We've expanded our coordinates to 4 variables, but really only 2
of them are important, *x* and *t*.

Now let's say *foolish scientists* have set up 3 cameras to observe this
process, trying to discover the relationship between the variables. They
do not have priviledged access to the coordinate system that we know of,
where the *x* direction contains the entire relationship. Rather, for
each camera they get two coordinates: the *x* and *y* of the ball's
location in the camera's image plane. What does this experiment look
like to these scientists?

The first thing to do is express the data in terms of each cameras *x*
and *y*. Well, let's assume the cameras are all directly pointed at the
origin (of our coordinate system) to capture all the action. I am going
to assert (and you can prove to yourself) that a camera's image plane
coordinates can be expressed by picking two directions out of a rotated
and scaled version of the original, experiment coordinate system. So to
get the coordinates for each camera, I'm going to pick a random rotation
and scaling (foreshadowing...), and pick the first two directions that
result.

How do I describe this process mathematically? Our current coordinate
system has 3 basis vectors:

$$ \\mathbf{ \\hat x} = \\begin{bmatrix} 1 \\\\ 0 \\\\ 0 \\end{bmatrix},
\\ \\mathbf{\\hat y} = \\begin{bmatrix} 0 \\\\ 1 \\\\ 0 \\end{bmatrix}, 
\\mbox{ and } \\mathbf{ \\hat z} = \\begin{bmatrix} 0 \\\\ 0 \\\\ 1 \\end{bmatrix}$$

Our new coordinate system is going to have 3 new basis vectors
$\\mathbf {\\hat e\_1}$, $\\mathbf{\\hat e\_2}$, and
$\\mathbf {\\hat e\_3}$. Each of these can be represented as a linear
combination of the experiment basis vectors
$$\\mathbf {\\hat e\_i} = t\_{ix} \\mathbf {\\hat
x} + t\_{iy} \\mathbf {\\hat y} + t\_{iz} \\mathbf {\\hat z}.$$
 A coordinate in this new basis can therefore be represented as a matrix
transformation on the original coordinates:

$$\\begin{aligned}
\\mathbf{\\vec r} &= \\begin{bmatrix} e\_1 \\\\ e\_2 \\\\ e\_3 \\end{bmatrix}\_{\\mathbf e}\\\\ 
&= e\_1 \\mathbf {\\hat e\_1} + e\_2 \\mathbf {\\hat e\_2} + e\_3 \\mathbf {\\hat e\_3} \\\\
&= e\_1 (t\_{1x} \\mathbf {\\hat x} + t\_{1y} \\mathbf {\\hat y} + t\_{1z}\\mathbf {\\hat z}) + e\_2 (t\_{2x} \\mathbf {\\hat x} + t\_{2y} \\mathbf {\\hat y} + t\_{2z}\\mathbf {\\hat z})  + e\_3 (t\_{3x}\\mathbf {\\hat x} + t\_{3y}\\mathbf {\\hat y} + t\_{3z}\\mathbf {\\hat z}) \\end{aligned}$$

$$ \\mathbf B = \\begin{bmatrix} \\hat x \\\\ \\hat y \\\\ \\hat z \\end{bmatrix} = 
\\begin{bmatrix} 1 & 0 & 0 \\\\ 0 & 1 & 0 \\\\ 0 & 0 & 1 \\end{bmatrix} = \\mathbf I.
$$

One side note: In the process of writing this post, I discovered that
generating a random 3D-rotation is actually super annoying. I spent a
little bit of time trying to tie the concept down and this is what I've
come up with: a rotation can be uniquely specified by an axis and an
angle to rotate around that axis. You can read about all that
[here](http://math.stackexchange.com/questions/442418/random-generation-of-rotation-matrices)
and
[here](https://en.wikipedia.org/wiki/Rotation_matrix#Conversion_from_and_to_axis-angle),
or you can just steal my code.

    ## random 3d rotation matrix
    random.rotation.matrix <- function(seed) { 
     set.seed(seed)
     
     ## angle around vector to rotate
     psi <- runif(1, max = 2*pi)

     ## select a random point on S^2
     phi <- runif(1, max = 2*pi)
     theta <- acos(2 * runif(1) - 1)

     ## construct axis from random S^2 point
     axis <- c(cos(theta)*cos(phi),
              cos(theta)*sin(phi),
              sin(theta))

     ## cross product matrix for formula
     axis.cp <- matrix(c(0, -axis[3], axis[2],
                         axis[3], 0, -axis[1],
                         -axis[2], axis[1], 0), nrow = 3, byrow = TRUE)

     ## create rotation matrix using wikipedia formula
     R <- cos(psi) * diag(c(1,1,1)) +
          sin(psi) * axis.cp +
          (1-cos(psi)) * outer(axis, axis) 

     R
    } 

I've tested the above function and it does seem to create random
rotations. So let's go ahead an find the new coordinates!

    new.camera.data <- function(positions, seed ) { 
     set.seed(seed)
     ## original data
     original.coordinates <- t(as.matrix(select(positions, x,y,z)))

     ## get scale
     scale <- 1/rexp(1, 1/3)
     
     ## get rotation
     rotation <- random.rotation.matrix(seed)
     
     ## new points
     new.points <- t(scale * rotation %*% original.coordinates)
     
     ## project
     image.plane.projection <- new.points[,1:2]

     list(scale = scale, rotation = rotation, data = image.plane.projection)
    }

    camera.1 <- new.camera.data(positions, 1)
    camera.2 <- new.camera.data(positions, 2)
    camera.3 <- new.camera.data(positions, 3)

    camera.data = data.frame(t = seq(0, 6*pi, by = .1),
                             x1 = camera.1$data[,1],
                             y1 = camera.1$data[,2],
                             x2 = camera.2$data[,1],
                             y2 = camera.2$data[,2],
                             x3 = camera.3$data[,1],
                             y3 = camera.3$data[,2])

Fun exercise: see if you can reconstruct the camera's position and
orientation from the rotation matrix and scale. Now what does the data
look like:

    ggplot(data = gather(camera.data, variable, value, x1:y3), aes(x = t, y = value)) +
        geom_point() +
        facet_wrap(~ variable, nrow = 2) 

![](pca_files/figure-markdown_strict/unnamed-chunk-5-1.png)

What? It looks like there are several signals here. How do the
scientists tell what is what? That's where principal component analysis
comes in. PCA is going to isolate the true signal from all of these
redundant copies. We shall soon see.

Isolation of the signal
-----------------------

So how does PCA actually work? Let's first consider the problem we are
trying to solve.

    1+1

    ## [1] 2
