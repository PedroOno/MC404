# ----------------------------------------
# Disciplina: MC404 - 1o semestre de 2015
# Professor: Edson Borin
#
# Descrição: Makefile para o segundo trabalho
# ----------------------------------------

# ----------------------------------
# SOUL object files -- Add your SOUL object files here
SOUL_OBJS=SOUL.o

# ----------------------------------
# Compiling/Assembling/Linking Tools and flags
AS=arm-eabi-as
AS_FLAGS=-g

CC=arm-eabi-gcc
CC_FLAGS=-g

LD=arm-eabi-ld
LD_FLAGS=-g

# ----------------------------------
# Default rule
all: disk.img

# ----------------------------------
# Generic Rules
%.o: %.s
	$(AS) $(AS_FLAGS) $< -o $@

%.o: %.c
	$(CC) $(CC_FLAGS) -c $< -o $@

# ----------------------------------
# Specific Rules
SOUL.x: $(SOUL_OBJS)
	$(LD) $^ -o $@ $(LD_FLAGS) --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0

LOCO.x: loco.o bico.o
	$(LD) $^ -o $@ $(LD_FLAGS) -Ttext=0x77802000

disk.img: SOUL.x LOCO.x
	mksd.sh --so SOUL.x --user LOCO.x

clean:
	rm -f SOUL.x LOCO.x disk.img *.o


##################################################################################
USER = user_code
SYSTEM = SOUL

# IC Computer
 DUMBOOT = /home/specg12-1/mc404/simulador/simulador_player/bin/dumboot.bin
 ARMSIM = armsim_player
 GDB = arm-eabi-gdb
# source :  source /home/specg12-1/mc404/simulador/set_path_player.sh

# ARM Simulator
#GDB = /home/mc404/simuladorfromspecg/simulador/bin/arm-eabi-gdb

# target remote localhost:5000

simulation:
	$(ARMSIM) --rom=$(DUMBOOT) --sd=disk.img $(LD_FLAGS)

gdb_tui:
	arm-eabi-gdbtui $(SYSTEM).x -ex 'target remote localhost:5000'

gdb:
	$(GDB) $(SYSTEM).x -ex 'target remote localhost:5000'

player:
	 player /home/specg12-1/mc404/simulador/simulador_player/worlds_mc404/simple.cfg
