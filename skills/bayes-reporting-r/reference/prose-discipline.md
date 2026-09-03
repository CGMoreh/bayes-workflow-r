# Prose discipline for the write-up

The rules here govern how the methods, results and appendix text produced with this skill is
written. They are not a house style in the sense of a journal's typographic preferences; they
are the habits that separate prose a reader trusts from prose a reader discounts on sight, and
most of them exist because language models have a documented tendency to the opposite. The
companion file `results-register.md` describes how the authors of the workflow book turn
diagnostics and results into sentences. This file describes what to avoid while doing so, and
why.

## The reader assumed

A methods reviewer in a sociology, political science or demography journal. They know what a
posterior is, what partial pooling does, and what a marginal effect means; they do not need
those defined. They do not necessarily know what `elpd` is, what a Pareto k diagnoses, or what
power-scaling measures, and each of those gets a plain definition at first use and then its
name. The test for whether a term needs defining is whether it would appear undefined in
*Sociological Methods and Research* or the *European Sociological Review*. If it would, use it;
if it would not, define it once and then use it.

## Hedging runs in one direction

Reported facts, data descriptions, model specifications and computed numbers are stated flat:
the sample has 262 apartments; the model is a negative binomial; the difference in expected log
predictive density is 8.4 with a standard error of 4.7. The author's own interpretive claims
carry the hedges: the concentration of that difference in a few cases *suggests* the models
differ chiefly in how they handle unusual apartments; the interaction *appears* to weaken as
baseline infestation rises. Language models tend to invert this, asserting interpretations and
hedging facts, and the inversion reads as a machine to anyone who has seen enough of it.

A strong claim travels with the sentence that says what would overturn it. "The treatment
reduces the expected count to about 40% of its untreated level" is followed, in the same
paragraph, by what the analysis could not check: the absence of a building identifier, the
unstated assignment mechanism, the four models that cross-validation cannot separate. The
limitation belongs beside the claim, not in a separate section where it can be skipped.

## Salience is marked in a clause, never in a fronted adverb

"Notably," "Crucially," "Importantly," and "Interestingly," at the head of a sentence tell the
reader that something matters without saying why. The alternative is a full clause carrying the
reason: "It matters that the two estimands coincide only under a constant effect, because the
question of which one to report never arises until the effect is allowed to vary." If the
reason cannot be stated, the salience was not real.

The same applies to superlatives applied to one's own findings. "The clearest result", "the
most striking pattern" and "the sharpest lesson" rank findings by a criterion the reader cannot
inspect. A superlative is fine as a fact about the data with its comparison set named – "the
largest pointwise difference, 2.1 elpd, belongs to apartment 41" – and nowhere else.

## No verdict sentences, no kickers

A short declarative sentence that delivers a judgement after the evidence – "The Poisson is
simply wrong." "That is the whole story." "The data have spoken." – performs a conclusion
rather than earning one. The preceding sentences almost always did the work; delete the
verdict, or fold its content into a sentence that states the finding with its evidence attached
and its limits in view. The characteristic shape of a defensible conclusion in this register is
a sentence of ordinary length whose final noun phrase carries the claim and whose next sentence
says what the claim does not cover.

## The structural marks of machine prose

Each of these is a documented marker of language-model output, identified in the detection
literature by shape rather than by vocabulary. One instance is fine; the tell is the shape
recurring until the reader hears the machine. The budget is roughly one marked structure per
page, spent where the contrast or the triad is the actual argument.

- **Negative parallelism.** "It is not X, it is Y." "Not just X but Y." State the positive claim.
- **Aphoristic closers.** A short dramatic sentence after the point has been made. Delete it.
- **Forced-drama framing.** "Here is the thing:", "The result?", "But notice what this means."
  Use "But" and "So" and let the material carry its own weight.
- **Rule-of-three padding.** A third list item added to complete a rhythm. Vary list lengths.
- **Uniform rhythm.** The same setup–dash–twist sentence, or three mid-length sentences per
  paragraph, repeated. Some sentences long and unbalanced, some paragraphs two sentences.
- **Empty openers and closers.** "In conclusion", "Ultimately", "The bottom line". Start with the
  subject; stop where the argument stops.
- **Significance inflation.** Everything crucial, striking, powerful. Say what follows from the
  finding and let the reader judge its size.
- **Performing headings.** A heading describes what the section contains or claims. It may take
  a stance – "The effect depends on how infested the apartment was" is a claim – but it does not
  stage a paradox, pose a teaser or reach for a metaphor.
- **Forced metaphor.** Journeys, landscapes, tapestries, spines and hinges applied to an analysis.
  Say it literally. A term of art keeps its name: "garden of forking paths" is Gelman and Loken's
  own coinage and is used with attribution, as is any borrowed figure.
- **Announcement openers.** A paragraph that begins by declaring its own content instructive,
  telling or revealing – "The zero-inflated model is instructive here." – instead of beginning.
  Open with the subject itself and carry the contrast in a mid-clause connective: "The
  zero-inflated model, by contrast, puts the untreated arm at 41.7."
- **Revision residue.** Sentences that answer a previous draft rather than the reader:
  comparative scoring left from a superseded structure, transitions responding to a deleted
  paragraph, corrections phrased as corrections. Every draft argues afresh to a reader who has
  seen no other draft. On any revision, reread each paragraph as that reader.

## Vocabulary that reads as machine text

Corpus studies of the years since language models became common measure a sharp surge in a
specific set of words, in specific decorative senses, and readers now pattern-match on them.
In their ornamental uses avoid: delve, foster, crucial, critical (in the non-technical sense),
leverage as a verb, intricate, underscore, noteworthy, meticulous, seamless, pivotal, realm,
testament, tapestry, elevate, resonate, harness, empower, showcase, unpack, journey, landscape
and navigate as metaphors, vital, and comprehensive, dynamic, rich and robust as generic
praise. Technical senses always survive: *statistically significant*, *critical value*,
*robustness check* as the named exercise, *dynamic model*. The ban is on "a crucial insight",
"delve into the posterior", "a rich set of findings". Replace each with the specific word the
sentence means.

## Punctuation

Use en-dashes (–, U+2013), spaced, for a parenthetical break, and never the longer em-dash
(U+2014): em-dash-driven
drama is one of the better-attested markers of machine text. Use double quotes for someone's
actual words and single quotes for terms of art and scare quotes. Keep the rate of
parenthetical dashes, semicolons and colons down – roughly one of each per paragraph – because
each of them does a specific job that it stops doing when it appears in every sentence.

## Explain, do not compress

A term of art or a compressed phrase is spelled out the first time it appears, with what it means
and why it bears on the point, in the same sentence or the next. "The comparison rests on a
leave-one-out estimate that importance sampling could not compute reliably for 205 of the 262
observations" is what "high Pareto k" means to a reader who has not met it. Descriptive is not
verbose: the target is that the reader never has to look something up, and anything that adds
no understanding is cut.

Write relative clauses out in full where the embedded clause has its own noun-phrase subject
– "the codes that are defined by the classification as covering the whole region", not "codes
the classification defines as covering" – and expand a possessive that exists only to shorten
the sentence: "the sample used by the survey", not "the survey's sample". The reader follows
the sentence more easily when the head noun is the subject of its own clause.

## State what a thing is, never the edit that produced it

Prose and code comments describe the current state of the analysis, not its history. Not
"we now also fit a hurdle model" or "the earlier specification was replaced": the reader of a
paper sees one draft. The exceptions are files whose purpose is to record change – the workflow
log, a response to reviewers, a changelog – where the history is the content.

## How these rules are checked

`scripts/br_check_numbers.R` traces every number in a draft to the output behind it and lists
the sentences that quantify without a number. For the prose rules above, sweep by shape rather
than by string: read each page asking whether the same rhetorical move recurs. A string search
catches only the easy cases – "not just", "here's the", "in conclusion", the vocabulary list –
and a draft that passes the grep can still be built entirely from the structures listed here.
