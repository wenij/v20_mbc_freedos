# Makefile - GNU Makefile

# setting nasm path, you should install it first
NASM=c:\nasm
# setting watcomm c compiler path, you should install it first
WATCOMM=c:\watcomm\binnt;c:\watcomm\binw
BFI=tools\bfi.exe
BOOTDISK_NAME=DS2N00.DSK
export PATH:=$(NASM);$(WATCOMM);$(PATH)

all: bootdisk

ck_bootdisk: 
	if not exist "bootdisk" mkdir bootdisk

bootdisk: ck_bootdisk freedos 
	copy /Y freedos\ke2043\bin\*.sys bootdisk\ && copy /Y freedos\ke2043\bin\*.bat bootdisk\  \
	&& copy /Y freedos\ke2043\bin\*.com bootdisk\ && \
	copy /Y freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362\command.com bootdisk\ && \
	del bootdisk\KWC8616.sys

	copy /Y app\* bootdisk\
	
	$(BFI) -b=freedos\ke2043\boot\fat12com.bin -f=$(BOOTDISK_NAME) bootdisk
	

freedos:
	cd freedos\ke2043 && build.bat
	cd freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362 && build.bat
	
clean:
	cd freedos\ke2043 && clean.bat
	cd freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362 && clean.bat
	-rd /s /q bootdisk
	-del *.ima *.dsk

.PHONY: freedos bootdisk