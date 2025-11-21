title: Alice, The Alien, and the Illusion of the Twin Paradox
date: 2017-01-17 16:16
author: mflynn
tags: Philosophy, Physics, Relativity
slug: alice-the-alien-and-the-illusion-of-the-twin-paradox

**Note: imported from an earlier version of this blog. Sorry if anything is broken.**

<link rel="stylesheet"
      href="https://cdn.jsdelivr.net/npm/katex/dist/katex.min.css"
      crossorigin="anonymous">


Alice is traveling through deep space with her alien navigator. They are
delivering a shipment of water to Proxima Centauri at a solid fraction
of light speed. They had been traveling in deep space at constant speed
for so long that it was as if they were standing still. Suddenly, and
with a flash of light, they pass another interstellar traveler, one
Robert, heading back to Earth. Sensor readings on Alice’s ship have him
traveling at 3/5 light speed relative to them.

“Bob’s foot is made of solid lead,” the Alien commented.

“It better be when he has to slow down.” Alice took a moment to consider
the significance of this event. “Reality is so strange. Bob is speeding
past us right now. According to special relativity, time should be
passing slower for him. However, special relativity also says that he
has every right to say that he is stationary and we are moving, and
therefore time is passing slower for us. Who is right?”

“Both.” The Alien blinked.

Alice continued. “One of us could start accelerating towards the other
to meet up and find out which one was aging faster, but whoever does the
acceleration will find that *they* had aged as if they were the ones
moving the whole time! It’s almost like acceleration breaks the
symmetry.”

The Alien squinted his big black eyes. “Well, I guess.”

“Don’t you think that’s weird? That’s how the *real world* works!”

The Alien shrugged, looking back at his console. “Not really.”

Alice sighed. She wasn’t particularly surprised that the Alien wasn’t
playing along. He had a habit of shooting down her conversation topics.

She went on. “I guess the core of the paradox is that we both have an
equal right to say that we are the more aged person while we are both
moving at constant speed. Special relativity says that we are both
right, but how could that be possible?”

The Alien turned. “What do you mean *when* we arrive at the station?”

“I mean the moment in time when our ship’s coordinates become coincident
with the station’s coordinates.” said Alice, frustrated.

“What do you mean *moment in time*?” asked the Alien, with a grin. “I’m
going to go re-hydrate some noodles.” He clapped his hands excitedly and
went to go pull out some noodles from the freezer.

Now the Alien was just being obtuse. Alice was determined to get through
his philosophical meanderings.

“*I mean* the slice of all points in space-time where every synced clock
traveling parallel to us at the same speed would read the same number as
our clock.”

“But-“, the Alien began but Alice interrupted him, anticipating his
question and being a gifted experimentalist. “You could easily sync
clocks using a laser. All you need to do is fire a pulse at the clock.
When the reflection comes back, you know that the clock is exactly half
of the elapsed lightseconds away and it has advanced by exactly half the
number of seconds the total journey took. Add that number to the
reflected value on the clock and then you are synced.”

Alice drew a diagram.


![Twin Paradox diagram 1]({static}diagram1.svg)

“Here’s a chart with time on the y-axis and distance in line with the
direction to the clock on the x-axis. I’ve scaled the axes so that light
moves at 45 degree angles. Here you can see how the mechanism works. The
red line is the laser pulse. All the spacetime points on the horizontal
dotted line make up the moment in time, the *present*, when we hit the
station, because any laser pulse reflected off a clock at any of those
points makes a 45-45-90 triangle, who’s altitude from the 90 bisects the
base. Do you get it?”

The Alien nodded.

Alice continued. “In fact, we don’t even need a clock. We know that
when we receive the reflection of the laser, whatever it bounced off
of must have been simultaneous with whatever was happening on our ship
exactly halfway through the round trip. We could even do this with
Bob. I know his speed relative to me is 3/5 light speed. In 30 months,
when we arrive at the station, he will be 18 light months away. I can
send out a laser pulse in 12 months that will hit him exactly at (30
months, 18 lightmonths), which is when I arrive at the station. It
will return to me. What will the reflection read out? Well, I remember
a special trick for measuring straight-line clock-time from special
relativity class: $\Delta u = \sqrt{\Delta t^2 - \Delta x^2}$, where
$\Delta x$ is in light-units. So his clock reads $\sqrt{30^2 - 18^2}=24$ months greater than the time when we crossed paths, confirming
that he has aged less than the 30 months we will have aged!”

![Twin Paradox diagram 2]({static}diagram2.svg)

“But how does that make any sense?” asked Alice, still stumped. “Perhaps
Bob’s reference frame is in a different universe. Maybe we are now split
into *multiverses*.”

“Hold on a second,” pleaded the Alien. “Bob can do the same to us. He
can wait 12 months, which due to time dilation is 15 months for us, and
send a laser pulse towards us. When he receives the reflection, he knows
he can go back half the round-trip time to the exact moment on his
timeline where the laser hit us. And it seems the laser hits us at… 24
weeks, which is perfectly symmetrical, but…” He edited the diagram.

![Twin Paradox diagram 3]({static}diagram3.svg)

“Bob knows that the laser pulse hit you when your clock had elapsed 24
months, and that *must* be at the same time as when his clock read 30
months. However, these two events do not happen at the same time in our
reference frame. There is no paradox, but Bob’s present is *tilted*
relative to ours. That’s what causes the illusion of contradiction. At
the event at which you have accused Bob of being younger than us, to him
you are not even close to reaching the station.” The Alien said,
translating Bob’s present line down.

The Alien plopped a bowl of noodles in front of Alice. She was shocked.
“So we are both right, in our own reference frames, and there isn’t any
contradiction because the present is relative?” she asked. She paused
for a moment, tired of thinking. “Thanks for the soup.”

“You’re welcome.” said the Alien. They sipped in silence.

All diagrams made using the
[diagrams](http://projects.haskell.org/diagrams/)
library by Brent Yorgey.

*Note: This post closely follows the approach of [Tim
Maudlin](http://www.3ammagazine.com/3am/philosophy-of-physics/)
in his book: <a
href="https://www.amazon.com/gp/product/0691165718">Philosophy of Physics: Space and Time (Princeton
Foundations of Contemporary Philosophy)</a>. It is an excellent book. Maudlin is concrete
where many philosophers are abstract and fluffy. He also understands
physics better than many physicists. The great Richard Feynman gave an
incorrect, acceleration symmetry-breaking explanation to this
phenomenon.*

