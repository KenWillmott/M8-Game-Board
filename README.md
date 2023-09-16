# M8-Game-Board

The M8 Game Board is so named because it combines a video display processor, a sound synthesizer, and dual joystick inputs. These are the main components of a video game. Keyboard input is also possible with the serial chip that is also on board. It also follows the M8 philosophy of using the most advanced ICs that were available at the time, without regard to brand.

The TMS9918A VDP (Video Display Processor) was certainly the IC that brought game features like hardware sprites (up to 32) and using cheap (at the time) dynamic memory. Steve Ciarcia's article about it inspired an Apple II compatible video expansion card that I happened to get a hold of. It's an amazing chip, and also extremely simple to interface to an 8 bit processor.

The synth was a tough choice because it factors in my judgement of the current availability, combined with interface ease issues. But I played with a prototype and it can make game quality music and effects. The PHilips SAA1099.

The joystick inputs are just a pair of 4 filtered digital inputs to a latch, with resistor pull ups to the power supply. So they can also be any general purpose switches.

The serial interface is an MC6850 or equivalent part. It's a UART but Motorola called it an "ACIA". There are now small USB Host to Serial cards available, it would allow the input from a keyboard and maybe mouse.

One board has been built and tested. Evaluation is on going.
