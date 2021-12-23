# Teensyduino Core Library
# http://www.pjrc.com/teensy/
# Copyright (c) 2019 PJRC.COM, LLC.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# 1. The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# 2. If the Software is incorporated into a build system that allows
# selection among a list of target devices, then similar target
# devices manufactured by PJRC.COM must be included in the list of
# target devices and selectable in the same manner.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# set your MCU type here, or make command line `make MCU=IMXRT1062`
MCU=IMXRT1062

# The name of your project (used to name the compiled .hex file)
TARGET = WSPRTx

# configurable options
# USING_MAKEFILE is not set as we wish for the main.cpp in the teensy toolchain
# to call our setup() and loop() functions, instead of overwriting it
OPTIONS = -DF_CPU=600000000 -DUSB_SERIAL -DLAYOUT_US_ENGLISH #-DUSING_MAKEFILE

# options needed by many Arduino libraries to configure for Teensy 4.0
OPTIONS += -D__$(MCU)__ -DARDUINO=10810 -DTEENSYDUINO=149 -DARDUINO_TEENSY40

# for Cortex M7 with single & double precision FPU
CPUOPTIONS = -mcpu=cortex-m7 -mfloat-abi=hard -mfpu=fpv5-d16 -mthumb

# use this for a smaller, no-float printf
#SPECS = --specs=nano.specs

# Other Makefiles and project templates for Teensy
#
# https://forum.pjrc.com/threads/57251?p=213332&viewfull=1#post213332
# https://github.com/apmorton/teensy-template
# https://github.com/xxxajk/Arduino_Makefile_master
# https://github.com/JonHylands/uCee


#************************************************************************
# Location of Teensyduino utilities, Toolchain, and Arduino Libraries.
# To use this makefile without Arduino, copy the resources from these
# locations and edit the pathnames.  The rest of Arduino is not needed.
#************************************************************************

# Those that specify a NO_ARDUINO environment variable will
# be able to use this Makefile with no Arduino dependency.
# Please note that if ARDUINOPATH was set, it will override
# the NO_ARDUINO behaviour.
ifndef NO_ARDUINO
# Path to your arduino installation
ARDUINOPATH ?= ../../../../..
endif

ifdef ARDUINOPATH

# path location for Teensy Loader, teensy_post_compile and teensy_reboot (on Linux)
TOOLSPATH = $(abspath $(ARDUINOPATH)/hardware/tools)
LIBRARYPATH = $(abspath $(ARDUINOPATH)/hardware/teensy/avr/libraries)

# path location for the arm-none-eabi compiler
COMPILERPATH = $(abspath $(ARDUINOPATH)/hardware/tools/arm/bin)

else
# Default to the normal GNU/Linux compiler path if NO_ARDUINO
# and ARDUINOPATH was not set.
COMPILERPATH ?= /usr/bin

endif

# Libraries that we use outside of the main Arduino one
SPI_INCLUDE_DIR = ./submodules/SPI
WSPRLITE_INCLUDE_DIR = ./submodules/WSPRLite/include
AD9834_SRC_DIR = ./submodules/AD9834/src
AD9834_INCLUDE_DIR = $(AD9834_SRC_DIR)

ADAFRUIT_SSD1306_INCLUDE_DIR = ./submodules/Adafruit_SSD1306
ADAFRUIT_GFX_INCLUDE_DIR = ./submodules/Adafruit-GFX-Library
ADAFRUIT_BUS_INCLUDE_DIR = ./submodules/Adafruit-BusIO

WIRE_INCLUDE_DIR = $(LIBRARYPATH)/Wire
WIRE_SRC_DIR = $(WIRE_INCLUDE_DIR)

TIMELIB_INCLUDE_DIR = $(LIBRARYPATH)/Time
TIMELIB_SRC_DIR = $(TIMELIB_INCLUDE_DIR)

NEOGPS_INCLUDE_DIR = ./submodules/NeoGPS/src
NEOGPS_SRC_DIR = $(NEOGPS_INCLUDE_DIR)

#************************************************************************
# Settings below this point usually do not need to be edited
#************************************************************************

# CPPFLAGS = compiler options for C and C++
CPPFLAGS = -Wall -g -O2 $(CPUOPTIONS) -MMD $(OPTIONS) -I$(SPI_INCLUDE_DIR) -I$(WSPRLITE_INCLUDE_DIR) -I$(AD9834_INCLUDE_DIR) -I$(ADAFRUIT_BUS_INCLUDE_DIR) -I$(ADAFRUIT_GFX_INCLUDE_DIR) -I$(ADAFRUIT_SSD1306_INCLUDE_DIR) -I$(WIRE_INCLUDE_DIR) -I$(TIMELIB_INCLUDE_DIR) -I$(NEOGPS_INCLUDE_DIR) -I$(ARDUINOPATH)/hardware/teensy/avr/cores/teensy4 -Isrc -ffunction-sections -fdata-sections

# compiler options for C++ only
CXXFLAGS = -std=gnu++0x -felide-constructors -fno-exceptions -fpermissive -fno-rtti -Wno-error=narrowing

# compiler options for C only
CFLAGS =

# linker options
LDFLAGS = -Os -Wl,--gc-sections,--relax $(SPECS) $(CPUOPTIONS) -T$(MCU_LD)

# additional libraries to link
LIBS = -larm_cortexM7lfsp_math -lm -lstdc++


# names for the compiler programs
CC = $(COMPILERPATH)/arm-none-eabi-gcc
CXX = $(COMPILERPATH)/arm-none-eabi-g++
OBJCOPY = $(COMPILERPATH)/arm-none-eabi-objcopy
SIZE = $(COMPILERPATH)/arm-none-eabi-size

CPP_FILES := $(wildcard $(ARDUINOPATH)/hardware/teensy/avr/cores/teensy4/*.cpp)
CPP_FILES += $(wildcard $(ARDUINOPATH)/hardware/teensy/avr/cores/teensy4/*.c)

# Add our libraries
CPP_FILES += $(AD9834_INCLUDE_DIR)/AD9834.cpp $(SPI_INCLUDE_DIR)/SPI.cpp

CPP_FILES += $(wildcard $(ADAFRUIT_SSD1306_INCLUDE_DIR)/*.cpp)
CPP_FILES += $(wildcard $(ADAFRUIT_GFX_INCLUDE_DIR)/*.cpp)
CPP_FILES += $(wildcard $(ADAFRUIT_BUS_INCLUDE_DIR)/*.cpp)

CPP_FILES += $(wildcard $(WIRE_SRC_DIR)/*.cpp)

CPP_FILES += $(wildcard $(TIMELIB_SRC_DIR)/*.cpp)

CPP_FILES += $(wildcard $(WIRE_SRC_DIR)/utility/*.c)

CPP_FILES += $(wildcard $(NEOGPS_SRC_DIR)/*.cpp)


CPP_FILES += src/WSPRTx.cpp

CPP_OBJS = $(CPP_FILES:.cpp=.o)
OBJS = $(CPP_OBJS:.c=.o)

# the actual makefile rules (all .o files built by GNU make's default implicit rules)

all: $(TARGET).hex

$(TARGET).elf: $(OBJS) $(MCU_LD)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

%.hex: %.elf
	$(SIZE) $<
	$(OBJCOPY) -O ihex -R .eeprom $< $@
ifneq (,$(wildcard $(TOOLSPATH)))
	$(TOOLSPATH)/teensy_post_compile -file=$(basename $@) -path=$(shell pwd) -tools=$(TOOLSPATH)
	-$(TOOLSPATH)/teensy_reboot
endif

# compiler generated dependency info
-include $(OBJS:.o=.d)

# # make "MCU" lower case
LOWER_MCU := $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$(MCU)))))))))))))))))))))))))))
MCU_LD = $(abspath $(ARDUINOPATH)/hardware/teensy/avr/cores/teensy4/$(LOWER_MCU).ld)

clean:
	rm -f *.o *.d $(TARGET).elf $(TARGET).hex
	rm $(OBJS)
	rm $(OBJS:.o=.d)
.PHONY: echo
echo:
	echo $(OBJS)
