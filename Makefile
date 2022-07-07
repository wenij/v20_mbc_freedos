# Makefile - GNU Makefile

# setting nasm path, you should install it first
NASM=c:\nasm
# setting watcomm c compiler path, you should install it first
WATCOMM=c:\watcomm\binnt;c:\watcomm\binw


export PATH:=$(NASM);$(WATCOMM);$(PATH)

all: bootdisk

bootdisk: freedos 
	if not exist "bootdisk" mkdir bootdisk
	

freedos:
	cd freedos\ke2043 && build.bat
	cd freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362 && build.bat
	copy freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362\command.com bootdisk\*
	copy freedos\ke2043\bin\* bootdisk\*
	
clean:
	cd freedos\ke2043 && clean.bat
	cd freedos\freecom-81535436f80343d7d111df381f2f9020bd1e3362 && clean.bat
	rd /s /q bootdisk

.PHONY: freedos bootdisk