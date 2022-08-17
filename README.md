# ay16f57
This software can play music in AY-3-8910 using PIC16F57/59.<br>

## Feature
1. **Plays RSF file from I2C EEPROM**<br>
   Plays RSF file and press button to skip the song.<br>
   EEPROM data structure is:<br>
   01-07: Address High, Low of song 1 to 4<br>
   data is headderless RSF (starts with 3F FF) and append EOF(FD)
   at the end of the each song.<br>
   See "16krom".
   
2. **Tests PSG IC while startup**<br>
   If LED light up while startup sound playing, it is AY-3-8910 or clone.<br>
   If it turns off, it is YM2149.<br>
   Also, If IOA3 is high while start up, IOB is '10101010'
   or else, '01010101'.<br>
   
3. **Tests and disables PIC**<br>
   If button was pressed while startup, LED will blink about 5 seconds
   and turns off. After that, all PIC pins interfacing to AY will
   be Hi-Z state. It enables use AY-3-8910 with Arduino.<br>
   
## Wiring

Note: SDA and SCL needs 10k pullup!

| PIC | AY-3-8910 | Others |
| ------------- | ------------- | ------------- |
| RC0 | DA0 |  |
| RC1 | DA1 |  |
| RC2 | DA2 |  |
| RC3 | DA3 |  |
| RC4 | DA4 |  |
| RC5 | DA5 |  |
| RC6 | DA6 |  |
| RC7 | DA7 |  |
| RA0 |  | LED |
| RA1 | BC1 |  |
| RA2 | (BC2) |  |
| RA3 | BDIR |  |
| RB0 |  | 24FC512 SDA |
| RB1 |  | 24FC512 SCL |
| RB3 | RESET_ |  |
| RB3 |  | tact switch |
| MCLR |  | Vdd |
| CLKIN |  | 74HCU04 clock out |
| Vdd | Vcc | +5V |

Clock circuit:

| 74HCU04 | 74HC74 | Others |
| ------------- | ------------- | ------------- |
| 1A |  | Crystal 3.58MHz 3 |
| GND |  | Crystal 3.58MHz 2 |
| 1Y-2A |  | Crystal 3.58MHz 1 |
| 2Y | 1CK | PIC CLKIN |
|  | 1D-1Q_ |  |
|  | 1Q | AY-3-8910 CLOCK |
|  | 1CLR_-1PR_ | Vcc |

[AY-3-8910 Audio Output](https://www.avray.ru/new_rc_filter/):

| AY-3-8910 | Filter | 3.5mm Jack |
| ------------- | ------------- | ------------- |
| Channel A | 10k~20kohm | Left |
| Channel C | 10k~20kohm | Left |
| Channel C | 10k~20kohm | Right |
| Channel B | 10k~20kohm | Right |
| GND | 820pf~1000pf | Left |
| GND | 820pf~1000pf | Right |

## Note

RSF file can generate from [AVR-AY Player](https://www.avray.ru/avr-ay-player/)

If you want to build from source, you need to use MPASM(not a XC8 ASM).

If you don't have EEPROM writer, [use Raspberry Pi and EEProg](https://www.richud.com/wiki/Rasberry_Pi_I2C_EEPROM_Program)

When flashing 16F57/59 with PICSTART Plus, you need to float CLKOUT pin. Or you can use [pickle](https://wiki.kewl.org/dokuwiki/projects:pickle)(but require 13V).

Example PCB design and BOM list, CPL file is available.

## Thanks & License

sample ROM file contains "Touhou Zero Track 1" by Gogin.<br>

[EEPROM routine by nagoyacoder](http://nagoyacoder.web.fc2.com/pic/pic_i2c.html)<br>
[YMZ294 routine by hijiri~](http://hijiri3.s65.xrea.com/sorekore/develop/pic/PIC04_YMZ.htm)

I can't find a license of these routines, but they takes for "sample source".<br>
So I will take this software for "sample source" ...
