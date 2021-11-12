PRJNAME := sandbox
OUTPUT := binaries/

$(OUTPUT)$(PRJNAME).sms: $(PRJNAME).asm libraries/* data/* 
	@C:\Users\ANSJ\Documents\wla_dx_9.12\wla-z80.exe -o $(PRJNAME).o $(PRJNAME).asm
	@echo [objects] > linkfile
	@echo $(PRJNAME).o >> linkfile
	@C:\Users\ANSJ\Documents\wla_dx_9.12\wlalink.exe -d -v -S linkfile $(OUTPUT)$(PRJNAME).sms
	@rm *.o linkfile

data/sprite_tiles.inc: data/img/sprites.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/sprites.png -noremovedupes -8x8 -palsms -fullpalette -savetiles data/sprite_tiles.inc -exit

data/village_tiles.inc: data/img/village.png
	@C:\Users\ANSJ\Documents\bmp2tile042\BMP2Tile.exe data/img/village.png -noremovedupes -8x8 -palsms -fullpalette -savetiles data/village_tiles.inc -exit

data/village_tilemap.bin: data/map/village.tmx
	node tools/convert_map.js data/map/village.tmx data/village_tilemap.bin

data/%.psg: data/sfx/%.vgm
	@C:\Users\ANSJ\Documents\PSGlib-nov15\tools\vgm2psg.exe $< $@
