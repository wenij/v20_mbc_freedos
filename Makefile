# Makefile - GNU Makefile
# your windows 7 need to install gnuwin32/make, and set your system PATH to it.

# setting nasm path, you should install it first
NASM=c:\nasm
# setting watcomm c compiler path, you should install it first
WATCOMM=c:\watcomm\binnt;c:\watcomm\binw


BFI=tools\bfi.exe
BOOTDISK_NAME=DS2N00.DSK
export PATH:=$(NASM);$(WATCOMM);$(PATH)

DISK_SET = bootdisk
DISK_SET += disk_b

all: $(DISK_SET)

disk_b:
	@if not exist "$@" mkdir $@

	copy /Y app\f83\* $@
	
	$(BFI) -f=DS2N01.DSK $@

ck_bootdisk: 
	if not exist "bootdisk" mkdir bootdisk

bootdisk:  freedos 
	@if not exist "$@" mkdir $@
	copy /Y freedos\ke2043\bin\*.sys bootdisk\ && copy /Y freedos\ke2043\bin\*.bat bootdisk\  \
	&& copy /Y freedos\ke2043\bin\*.com bootdisk\ && \
	copy /Y freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362\command.com bootdisk\ && \
	del bootdisk\KWC8616.sys

	copy /Y app\sys\* bootdisk\
	
	md bootdisk\f83

	copy /Y app\f83\* bootdisk\f83\ 

	$(BFI) -b=freedos\ke2043\boot\fat12com.bin -f=$(BOOTDISK_NAME) bootdisk
	

freedos:
	cd freedos\ke2043 && build.bat
	cd freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362 && build.bat
	
clean:
	cd freedos\ke2043 && clean.bat
	cd freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362 && clean.bat
	-rd /s /q bootdisk
	for %%x in ( $(DISK_SET) ) do if  exist "%%x" rd /s /q %%x

	-del *.ima DS2N00.DSK DS2N01.DSK

.PHONY: freedos $(DISK_SET)