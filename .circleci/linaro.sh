#!/usr/bin/env bash
 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

##----------------------------------------------------------##
# Device Name and Model
MODEL=Xiaomi
DEVICE=chime

# Kernel Defconfig
DEFCONFIG=${DEVICE}_defconfig

# Select LTO variant ( Full LTO by default )
DISABLE_LTO=0
THIN_LTO=0

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz
#DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
#DTB=$(pwd)/out/arch/arm64/boot/dts/mediatek

# Verbose Build
VERBOSE=0

# Date and Time
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME="SUPER.KERNEL-CHIME-(gcc-linaro)-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
FINAL_ZIP=${ZIPNAME}-${DEVICE}-${TANGGAL}.zip

##----------------------------------------------------------##
# Specify compiler.

COMPILER=linaro

##----------------------------------------------------------##
# Specify Linker
LINKER=ld.lld

##----------------------------------------------------------##

##----------------------------------------------------------##
# Clone ToolChain
function cloneTC() {
        
    if [ $COMPILER = "clang17-7" ];
	then
    wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r498229b.tar.gz && mkdir clang && tar -xzf clang-r498229b.tar.gz -C clang/
    export KERNEL_CLANG_PATH="${KERNEL_DIR}/clang"
    export KERNEL_CLANG="clang"
    export PATH="$KERNEL_CLANG_PATH/bin:$PATH"
    CLANG_VERSION=$(clang --version | grep version | sed "s|clang version ||")
	
    wget https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz && tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
    mv gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu gcc64
    export KERNEL_CCOMPILE64_PATH="${KERNEL_DIR}/gcc64"
    export KERNEL_CCOMPILE64="aarch64-linux-gnu-"
    export PATH="$KERNEL_CCOMPILE64_PATH/bin:$PATH"
    GCC_VERSION=$(aarch64-linux-gnu-gcc --version | grep "(GCC)" | sed 's|.*) ||')
   
    wget https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabi/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz && tar -xf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi.tar.xz
    mv gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabi gcc32
    export KERNEL_CCOMPILE32_PATH="${KERNEL_DIR}/gcc32"
    export KERNEL_CCOMPILE32="arm-linux-gnueabi-"
    export PATH="$KERNEL_CCOMPILE32_PATH/bin:$PATH"
      
    elif [ $COMPILER = "linaro" ];
	then    
    wget https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz && tar -xf gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
    mv gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu gcc64
    export KERNEL_CCOMPILE64_PATH="${KERNEL_DIR}/gcc64"
    export KERNEL_CCOMPILE64="aarch64-linux-gnu-"
    export PATH="$KERNEL_CCOMPILE64_PATH/bin:$PATH"
    GCC_VERSION=$(aarch64-linux-gnu-gcc --version | grep "(GCC)" | sed 's|.*) ||')
   
    wget https://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz && tar -xf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
    mv gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf gcc32
    export KERNEL_CCOMPILE32_PATH="${KERNEL_DIR}/gcc32"
    export KERNEL_CCOMPILE32="arm-linux-gnueabihf-"
    export PATH="$KERNEL_CCOMPILE32_PATH/bin:$PATH"   
   
   fi
	
}

##------------------------------------------------------##
# Export Variables
function exports() {

        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64
        
        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=Pancali
        export KBUILD_BUILD_USER="unknown"
        
	    export PROCS=$(nproc --all)
	    export DISTRO=$(source /etc/os-release && echo "${NAME}")
	    
	}
        
##----------------------------------------------------------------##

# Speed up build process
MAKE="./makeparallel"

##----------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
			       
	# Compile
	make O=out ARCH=arm64 ${DEFCONFIG}
	       
	if [ -d ${KERNEL_DIR}/gcc64 ];
	   then
	       make -j$(nproc --all) O=out \
	       ARCH=arm64 \
	       CROSS_COMPILE=$KERNEL_CCOMPILE64 \
	       CROSS_COMPILE_ARM32=$KERNEL_CCOMPILE32 \
           CROSS_COMPILE_COMPAT=$KERNEL_CCOMPILE32 \
	       V=$VERBOSE 2>&1 | tee error.log
	       
    fi
    	
}

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	# cp $DTBO AnyKernel3
	# find $DTB -name "*.dtb" -exec cat {} + > AnyKernel3/dtb
	# find $MODULE -name "*.ko" -exec cat {} + > AnyKernel3/wtc2.ko
	find . -name '*.ko' -exec cp '{}' AnyKernel3/modules/system/lib/modules \;
	
	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${ZIPNAME} *
        MD5CHECK=$(md5sum "$ZIPNAME" | cut -d' ' -f1)
        echo "Zip: $ZIPNAME"
        # curl -T $ZIPNAME temp.sh; echo
        # curl -T $ZIPNAME https://oshi.at; echo
        curl --upload-file $ZIPNAME https://free.keep.sh
    cd ..
    
}

    
##----------------------------------------------------------##

cloneTC
exports
compile
zipping

##----------------*****-----------------------------##