<map version="0.9.0">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node text="RNAfolding.org" background_color="#00bfff">
<richcontent TYPE="NOTE"><html><head></head><body><p>--org-mode: WHOLE FILE</p></body></html></richcontent>
<node text="How RNA folding is predicted" position="left">
<node style="bubble" background_color="#eeee00">
<richcontent TYPE="NODE"><html>
<head>
<style type="text/css">
<!--
p { margin-top: 3px; margin-bottom: 3px; }-->
</style>
</head>
<body>
<p><br />Many people might hear of fields such as RNA and protein folding and<br />wonder how that stuff must work. RNA is a physical system, therefore<br />it must obey the laws of physics. The most commonly used physical law<br />in the field of RNA prediction is the partition function law [TODO:<br />better name]. If RNA is modeled as a system in thermal equilibium then<br />the probability of any state $s$ with energy $E(s)$ is equal to <br />#<br />$$P(s)= \frac{e^{-E(s)/kT}}{\sum_{s'} e^{-E(s')/kT}} $$<br />#<br />Therefore to predict the folding of RNA we need 3 things:<br />- a specification of a state of RNA $s$,<br />- an energy function, which takes a state and outputs a physical<br />&#160;&#160;energy,<br />- the partition function, the sum of the Boltmann factors over every<br />&#160;&#160;possible state $Z = \sum_{s'} e^{-E(s)/kT}$.<br /></p></body>
</html>
</richcontent>
</node>
</node>
<node text="States of RNA" position="left">
<node style="bubble" background_color="#eeee00">
<richcontent TYPE="NODE"><html>
<head>
<style type="text/css">
<!--
p { margin-top: 3px; margin-bottom: 3px; }-->
</style>
</head>
<body>
<p><br />RNA is polymer of 4 nucleic acids, adenine, guanine, cytosine, and<br />uracil. This &quot;primary structure&quot; of RNA can be specified with a simple<br />string of 4 letters, for example &quot;GAAACCCCUUUUGGGG&quot;. For the secondary<br />structure of RNA, we are interested in which of these bases are going<br />to pair with each other. Any state of RNA can therefore be represented<br />as a list of base pairs $(i,j)$. For <b>tractability</b> reasons, in<br />practice the secondary structure of RNA is assumed to be composed of<br />several recursive types. </p><p>#+BEGIN_SRC haskell<br />data Structure = (Paired 1 Int, Structure ) | Structure <br />me :: Structure<br />me = Me<br />#+END_SRC</p><p>This is actually a key assumption, because the computability of this<br />problem hinges on it. There is the question of whether it is a<br />physically valid assumption. The answer is unquivically NO. There are<br />many RNAs found in nature that have &quot;crossing&quot; pairs, which break the<br />recursive definition here, such as Group I and Group II introns [TODO:<br />cite someone]. However, without the recursive definition, computing<br />the partition function is intractable, so most RNA folding software<br />packages make this assumption.<br /></p></body>
</html>
</richcontent>
</node>
</node>
<node text="Energy Model" position="left">
<node style="bubble" background_color="#eeee00">
<richcontent TYPE="NODE"><html>
<head>
<style type="text/css">
<!--
p { margin-top: 3px; margin-bottom: 3px; }-->
</style>
</head>
<body>
<p>For RNA, the most relevant energy to consider is electric<br />potential. Nucleic acids are covered in exposed ions, and each free<br />charge interacts with every other charge. The total energy can be<br />therefore expressed as a function of the charges and the distances<br />between them $U = f(\frac{q_iq_j}{r_{ij}}). </p><p>This is far too complicated. For $n$ charges there would be $n^2$<br />charges to consider. As we shall soon see, we want to be sure that the<br />energy model runs in constant time. How can we do this?</p><p>Doing a full physical energy model of RNA would be very difficult to<br />compute. In practice, there are several levels of complexity that are<br />implemented. A very simple energy model is one where each hydrogen<br />bond contributes exactly -1 unit of energy to the total. </p><p>Reducing the complexity of the energy model to this allows us to<br />compute the energy recursively.</p><p>#+BEGIN_SRC haskell<br />typedef Joul = Real</p><p>energy :: Structure -&gt; Joule<br />data Structure = (Paired 1 Int, Structure ) | Structure <br />me :: Structure<br />me = Me<br />#+END_SRC</p><p></p></body>
</html>
</richcontent>
</node>
</node>
<node text="Partition Function">
<node style="bubble" background_color="#eeee00">
<richcontent TYPE="NODE"><html>
<head>
<style type="text/css">
<!--
p { margin-top: 3px; margin-bottom: 3px; }-->
</style>
</head>
<body>
<p>The sum $Z = \sum_{s'} e^{-E(s)/kT}$ initially seems daunting. There<br />are $O(1.8^n)$ structures possible for an RNA strand of length<br />$n$. However, from the recursive definition of our energy model, we<br />can easily see that the partition function can be defined recursively<br />as well:</p><p>[TODO: partition function definition]</p><p>This becomes a standard dynamic programming homework problem! We can<br />turn Z into a table of values where Z[i,j] is the partition function<br />from base $i$ to base $n$. Since each row of the table only depends on<br />the entries below and to the left, we can compute the full partition<br />function by starting from the bottom left and working out to the top<br />right. This is even parallelizable along the diagonals, as shown in<br />the diagram: </p><p>[TODO: make elm diagram.]</p><p>Now that we have the partition function, we know the probability of<br />any structure from the Boltzmann distribution. <br /></p></body>
</html>
</richcontent>
</node>
</node>
<node text="Sampling RNA Structures">
<node style="bubble" background_color="#eeee00">
<richcontent TYPE="NODE"><html>
<head>
<style type="text/css">
<!--
p { margin-top: 3px; margin-bottom: 3px; }-->
</style>
</head>
<body>
<p><br />To actually predict the structure of RNA molecules in nature, we can<br />work backwards through the partition function table to sample<br />structures from the Boltzmann distribution with probability equal to<br />their probability to be found in nature. </p><p>[Todo: Haskell code]</p><p>Let's try it out:</p><p>[Todo: try example]</p><p>Cool!<br /></p></body>
</html>
</richcontent>
</node>
</node>
<node text="Macrostates">
<node style="bubble" background_color="#eeee00">
<richcontent TYPE="NODE"><html>
<head>
<style type="text/css">
<!--
p { margin-top: 3px; margin-bottom: 3px; }-->
</style>
</head>
<body>
<p><br />One last thing to do is cluster these structures into<br />Macrostates. Given two structures of the same strand, a distance<br />measure can be computed between them and with this distance metric, we<br />can classify and compare macrostates. Let's sample a bunch of structures<br /></p></body>
</html>
</richcontent>
</node>
</node>
<node text="Applications">
<node style="bubble" background_color="#eeee00">
<richcontent TYPE="NODE"><html>
<head>
<style type="text/css">
<!--
p { margin-top: 3px; margin-bottom: 3px; }-->
</style>
</head>
<body>
<p><br />Many genetic diseases are caused by mutations causing RNA to fold<br />incorrectly. The treatment is then to find some way to get it to fold<br />correctly again. One way to do this is to insert some binding agent to<br />block binding to a particular base or set of bases for that strand,<br />which disrupts the partition function, energy landscape, and causes<br />the strand to fold correctly. For example let's assume that the<br />healthy strand is [TODO: insert] but a pointwise mutation has caused<br />this to mutate to [TODO: insert]. We can compute a statistical<br />distance to the healthy boltzmann distribution and then pick a base to<br />block that gets us as close to the healthy distribution as possible. </p><p>[TODO: do example]</p><p>Cool right?</p></body>
</html>
</richcontent>
</node>
</node>
</node>
</map>
