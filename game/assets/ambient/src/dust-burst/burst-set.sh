#!/bin/sh
# Dust burst when an enemy falls: a wide puff kicked up at the enemy's feet (cell point
# 192,180), Dust Yellow going to grey-brown, spreading sideways, slowing; the packer fades the last 4 frames.
# One shot, 14 frames at 12 fps from 0.083 s; the emitter fires in the first 3 frames only.
S() { effectcraft-cli set burst cloud "$@" --project burst.ecproj --save >/dev/null || echo "FAIL $1"; }
S effects/#1/producer/position '[192,180]'; S effects/#1/producer/radiusX 40; S effects/#1/producer/radiusY 8
S effects/#1/birthRate 14 --time 0; S effects/#1/birthRate 14 --time 0.17; S effects/#1/birthRate 0 --time 0.25
S effects/#1/longevity 1.0
S effects/#1/physics/animation 0;   S effects/#1/physics/velocity 3.6; S effects/#1/physics/resistance 2.5
S effects/#1/physics/gravity -0.15; S effects/#1/physics/extra 0.6
S effects/#1/particle/particleType 2; S effects/#1/particle/birthSize 3; S effects/#1/particle/deathSize 7
S effects/#1/particle/sizeVariation 40; S effects/#1/particle/maxOpacity 75; S effects/#1/particle/transferMode 0
S effects/#1/particle/birthColor '[0.92,0.80,0.45,1]'; S effects/#1/particle/deathColor '[0.52,0.46,0.40,1]'
S effects/#1/randomSeed 11
