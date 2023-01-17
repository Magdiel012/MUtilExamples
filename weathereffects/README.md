# Weather effects

This example, lifted from an upcoming project I've been assisting with,
consists of a highly-optimized weather system that makes use of the sector 
triangulation utilities in MUtil to spawn weather particles randomly in
sectors with the designated tags. Tag 3570 will cause rain to spawn within the
tagged sector, whereas tag 3571 will cause snow to spawn. MAP01 demonstrates
the included weather effects in a smaller environment. MAP02, on the other hand,
serves as a stress test.

## Performance

As mentioned prior, the system has undergone a number of optimizations to
maximize performance. It would be impractical to attempt to provide metrics
encompassing the breadth of computer hardware that may play mods utilizing this
system, but to at least mention an anecdotal remark, the machine used to develop
this system sports an RTX 3050 GPU, a Ryzen 7 5800X processor at 3.8 Ghz, and is
connected to a 1440p display. As currently configured, in MAP02, performance
averaged around 240 FPS at Ultra settings.

## Use case considerations

Care should be taken when repurposing this system for other projects. Currently,
configuration is rather inflexible: spawning behavior cannot be customized per
sector. Weather types and all of their associated configuration are hard-coded,
using tags to differentiate between them. The current configuration has been
fine-tuned to perform reasonably well in the provided test maps. Equivalent
performance in other contexts out of the box is not guaranteed. Additional
weather types may be created by adding more tag constants and modifying the
weather handler's CreateWeatherSpawners() method to iterate over sectors with
the new tag and create additional spawners with the desired configuration.

Should more flexibility be required, it is theoretically possible to modify the
system to read UDMF properties from the tagged sectors and provide granular
configuration this way, but this is beyond the scope of the usage example.

## Multiplayer

While the system is technically compatible with multiplayer, this has not been
thoroughly tested and will likely result in issues, particularly with regards to
saved games.

## Acknowledgements

This example uses certain sprites from boondorl's Universal Rain and Snow mod.