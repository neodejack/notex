The chord_step func takes a single chordtemplate as arg

User use it like 
append_step( chordtemp, & add_interval(&1, :five))

IMPORTANT: add_interval is not a step function.
It's just a helper for user to construct their step function.
In the above example, the step function is & add_interval(&1, :five)

---

We need to abstract out ChordTemplate out of Chord.

Chordtemplate: voicings, steps, current_steps.

Chord: base_note, chordtemplate

Then we provide built-in chord template as functions like maj()

User can built their own chordtemplate by adding steps the existing chord templates
For example

maj_sus4 =
maj(:closed)
|> append_step( & add_interval(&1, :four))
|> append_step( & add_voicing(&1, :four , [0,1])
|> append_step( &omit_interval(&1, :three)

---
Maybe we don't even need the Chord data structure.

Since base_note is only needed when we run the notes function (to get a list of notes)

User can simply provide the base_note and chordtemplate as args to the notes() function

For example
notes(~n/C4/, maj(:closed))
notes(~n/C4/, majsus4)


---
Actually, it doesn't have to be that complicated. We don't need to let users define an anonymous function that uses our helpers as a step function. We can just expose functions like addNote or addVoicing or omitvoicing or omitNote. The user can put in their whatever arguments, but the function itself doesn't actually change the underlying data structure. It just adds another step function to the current steps and steps. And then yeah, just like that.

So that's another abstraction 
def add_interval(chordtemplate, :five) do
chordtemplate
|> append_step( & add_interval(&1, :five))
end

User just need to do this:
maj(:closed)
|> add_interval(:five)

And this create a new chordtemplate 
