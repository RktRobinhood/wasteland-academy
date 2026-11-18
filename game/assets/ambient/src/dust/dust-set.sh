#!/bin/sh
# Dust wisps drifting right across the Dry Flats. Comp = board rect (0,820)-(420,1020).
S() { effectcraft-cli set dust emitter "$1" "$2" --project dust.ecproj --save >/dev/null || echo "FAIL $1"; }
S effects/#1/birthRate 0.25;                S effects/#1/longevity 4
S effects/#1/producer/position '[60,110]'; S effects/#1/producer/radiusX 40; S effects/#1/producer/radiusY 70
S effects/#1/physics/animation 1;          S effects/#1/physics/direction 95
S effects/#1/physics/velocity 2.4;         S effects/#1/physics/gravity 0; S effects/#1/physics/extra 0.3
S effects/#1/particle/particleType 2;      S effects/#1/particle/birthSize 6; S effects/#1/particle/deathSize 10
S effects/#1/particle/sizeVariation 40;    S effects/#1/particle/maxOpacity 40; S effects/#1/particle/transferMode 0
S effects/#1/particle/birthColor '[0.72,0.52,0.34,1]'; S effects/#1/particle/deathColor '[0.86,0.70,0.50,1]'
S effects/#1/randomSeed 7
