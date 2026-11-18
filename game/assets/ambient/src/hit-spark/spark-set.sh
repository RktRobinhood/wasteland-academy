#!/bin/sh
# Hit spark for a correct answer: a burst of Dust Yellow streaks cooling to Rust Orange, over a
# short white-yellow flash. One shot, 10 frames at 12 fps; the emitters fire only in the
# first 2 frames; render from 0.083 s, as frame 0 is still empty (birthRate keyed at 0 s and 0.17 s).
S() { L=$1; shift; effectcraft-cli set spark $L "$@" --project spark.ecproj --save >/dev/null || echo "FAIL $L $1"; }
for L in streaks flash; do
  S $L effects/#1/producer/position '[128,128]'
  S $L effects/#1/physics/animation 0;  S $L effects/#1/physics/gravity 0
  S $L effects/#1/particle/transferMode 0; S $L effects/#1/randomSeed 3
done
S streaks effects/#1/birthRate 30 --time 0;  S streaks effects/#1/birthRate 30 --time 0.09; S streaks effects/#1/birthRate 0 --time 0.17
S streaks effects/#1/longevity 0.45;  S streaks effects/#1/physics/velocity 8; S streaks effects/#1/physics/resistance 2
S streaks effects/#1/particle/particleType 0; S streaks effects/#1/particle/birthSize 3; S streaks effects/#1/particle/deathSize 1
S streaks effects/#1/particle/maxOpacity 100
S streaks effects/#1/particle/birthColor '[1.0,0.97,0.80,1]'; S streaks effects/#1/particle/deathColor '[0.98,0.64,0.38,1]'
S flash effects/#1/birthRate 6 --time 0;  S flash effects/#1/birthRate 0 --time 0.09
S flash effects/#1/longevity 0.25; S flash effects/#1/physics/velocity 0.3
S flash effects/#1/particle/particleType 2; S flash effects/#1/particle/birthSize 5; S flash effects/#1/particle/deathSize 9
S flash effects/#1/particle/maxOpacity 50
S flash effects/#1/particle/birthColor '[1.0,0.98,0.88,1]'; S flash effects/#1/particle/deathColor '[0.92,0.80,0.45,1]'
