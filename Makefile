PRJNAME := sandbox
OUTPUT := binaries/
TILES := data/chapter_completed_tiles.inc data/end_of_demo_tiles.inc
TILEMAPS := data/chapter_completed_tilemap.inc data/end_of_demo_tilemap.inc
# missing the .asm files in root directory *.asm

all: $(OUTPUT)$(PRJNAME).sms $(TILES) $(TILEMAPS)

$(OUTPUT)$(PRJNAME).sms: $(PRJNAME).asm
	@C:\Users\ANSJ\Documents\wla_dx_9.12\wla-z80.exe -o $(PRJNAME).o $(PRJNAME).asm
	@echo [objects] > linkfile
	@echo $(PRJNAME).o >> linkfile
	@C:\Users\ANSJ\Documents\wla_dx_9.12\wlalink.exe -d -v -S linkfile $(OUTPUT)$(PRJNAME).sms
	@rm *.o linkfile

# FIXME: Include all files below in the all-variables!!
data/sprite_tiles.inc: data/img/sprites.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/sprites.png -noremovedupes -8x8 -palsms -fullpalette -savetiles data/sprite_tiles.inc -exit

data/village_tiles.inc: data/img/village.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/village.png -noremovedupes -8x8 -palsms -fullpalette -savetiles data/village_tiles.inc -exit

data/village_tilemap.bin: data/map/village.tmx
	node tools/convert_map.js data/map/village.tmx data/village_tilemap.bin

data/boss_sprite_tiles.inc: data/img/boss_sprites.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/boss_sprites.png -noremovedupes -8x8 -palsms -fullpalette -savetiles data/boss_sprite_tiles.inc -exit

data/boss_tiles.inc: data/img/boss.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/boss.png -noremovedupes -8x8 -palsms -fullpalette -savetiles data/boss_tiles.inc -exit

data/boss_tilemap.bin: data/map/boss.tmx
	node tools/convert_map.js data/map/boss.tmx data/boss_tilemap.bin

data/chapter_completed_tiles.inc: data/img/chapter_completed.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/chapter_completed.png -8x8 -palsms -fullpalette -savetiles data/chapter_completed_tiles.inc -exit

data/chapter_completed_tilemap.inc: data/img/chapter_completed.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/chapter_completed.png -8x8 -palsms -fullpalette -savetilemap data/chapter_completed_tilemap.inc -exit

data/end_of_demo_tiles.inc: data/img/end_of_demo.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/end_of_demo.png -8x8 -palsms -fullpalette -savetiles data/end_of_demo_tiles.inc -exit

data/end_of_demo_tilemap.inc: data/img/end_of_demo.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/end_of_demo.png -8x8 -palsms -fullpalette -savetilemap data/end_of_demo_tilemap.inc -exit

data/%.psg: data/psg/%.psg
	@C:\Users\ANSJ\Documents\PSGlib-nov15\tools\vgm2psg.exe $< $@

