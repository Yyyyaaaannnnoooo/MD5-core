# Ciao MD5

> Pico Live Coding environment using the MD5 hashing algorithm to build musical compositions.

This is a Pico Live Coding environment based on the MD5 hashing algorithm. It takes a text of any length and turns it into a 128-bit hash, which is then transformed into a musical score. This work explores the cryptographic retirement of MD5. Designed by Ronald Rivest in 1992, MD5 was a widely adopted cryptographic hash function. However it was formally deprecated by the National Institute of Standards and Technology in 2010. And thus turning it into a dead algorithm.

> [Initially Developed for the Hack the Promise Festival](https://hackthepromise.org/festival-2025/programm/)

## Current status

the project is in development, focusing on two things: 
- buidling a better melody generator
- make it run on a raspberry pi

The client input interface is currenttly broken, to favor terminal based interface. The terminal does not take text inputs at the moment.

### The Story of MD5

MD5 (Message-Digest Algorithm 5) was designed by Ronald Rivest in 1992 as a cryptographic hash function that produces a 128-bit hash value. For over a decade, it was widely used for various security applications and data integrity verification.


Despite its initial widespread adoption, MD5 has been considered cryptographically broken and unsuitable for further use since approximately 2005 ~ 2008. The National Institute of Standards and Technology formally deprecated MD5 for most uses in 2010
By transforming text into musical requiems, this work composes poetic farewells to say goodbye to the MD5 algorithm.


> [Short Video Explanation](https://youtu.be/TZOxIBP_L-o)




### How it works



### new built in strings

> check line 427 and after to choose between sending midi or using internal synth


### Technical Architecture

MD5 Core consists of three main components:

1. Web Interface: where users can input text

2. MD5 Hashing: The input text is processed through the MD5 algorithm to generate a 128-bit hash

3. MIDI Composition: The hash is sent via OSC protocol to SuperCollider, which generates a musical composition based on requiem chords. The resulting composition is served over MIDI

Each hash produces a unique musical piece that reflects the solemn nature of a funeral mass.


## Requiem Chords:

### Kyrie:

1. Cm - Fm - Cm - G


- C, Eb, G 
- F, Ab, C 
- C, Eb, G 
- G, B, D

2. Cm - Fm - Ab - G


- C, Eb, G 
- F, Ab, C 
- Ab, C, Eb 
- G, B, D



### Dies Irae:

1. Dm - A - Gm - A - Dm

- D, F, A 
- A, C#, E 
- G, Bb, D 
- A, C#, E 
- D, F, A

2. Dm - C#°7 - A

- D, F, A 
- C#, F, G#, C 
- A, C#, E



### Sanctus

1. Eb - Bb - Cm - Ab

- Eb, G, Bb 
- Bb, D, F 
- C, Eb, G 
- Ab, C, Eb

2. Eb - Bb - Cm - Gm - Ab - Eb - Ab - Bb

- Eb, G, Bb 
- Bb, D, F 
- C, Eb, G 
- G, Bd, D 
- Ab, C, Eb 
- Eb, G, Bb 
- Ab, C, Eb 
- Bb, D, F


### Lux Aeterna

1. Am - C - F - G

- A, C, E 
- C, E, G 
- F, A, C 
- G, B, D


## Current upgrade to work scsynth instead of external synthesizer

### TO DO
1. check line 333
2. remove 'dura' from make_scores
3. add drum composer to md5-drums-midi.scd line 872
