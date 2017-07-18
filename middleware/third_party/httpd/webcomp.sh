# Copyright Statement:
#
# (C) 2005-2016 MediaTek Inc. All rights reserved.
#
# This software/firmware and related documentation ("MediaTek Software") are
# protected under relevant copyright laws. The information contained herein
# is confidential and proprietary to MediaTek Inc. ("MediaTek") and/or its licensors.
# Without the prior written permission of MediaTek and/or its licensors,
# any reproduction, modification, use or disclosure of MediaTek Software,
# and information contained herein, in whole or in part, shall be strictly prohibited.
# You may only use, reproduce, modify, or distribute (as applicable) MediaTek Software
# if you have agreed to and been bound by the applicable license agreement with
# MediaTek ("License Agreement") and been granted explicit permission to do so within
# the License Agreement ("Permitted User").  If you are not a Permitted User,
# please cease any access or use of MediaTek Software immediately.
# BY OPENING THIS FILE, RECEIVER HEREBY UNEQUIVOCALLY ACKNOWLEDGES AND AGREES
# THAT MEDIATEK SOFTWARE RECEIVED FROM MEDIATEK AND/OR ITS REPRESENTATIVES
# ARE PROVIDED TO RECEIVER ON AN "AS-IS" BASIS ONLY. MEDIATEK EXPRESSLY DISCLAIMS ANY AND ALL
# WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NONINFRINGEMENT.
# NEITHER DOES MEDIATEK PROVIDE ANY WARRANTY WHATSOEVER WITH RESPECT TO THE
# SOFTWARE OF ANY THIRD PARTY WHICH MAY BE USED BY, INCORPORATED IN, OR
# SUPPLIED WITH MEDIATEK SOFTWARE, AND RECEIVER AGREES TO LOOK ONLY TO SUCH
# THIRD PARTY FOR ANY WARRANTY CLAIM RELATING THERETO. RECEIVER EXPRESSLY ACKNOWLEDGES
# THAT IT IS RECEIVER'S SOLE RESPONSIBILITY TO OBTAIN FROM ANY THIRD PARTY ALL PROPER LICENSES
# CONTAINED IN MEDIATEK SOFTWARE. MEDIATEK SHALL ALSO NOT BE RESPONSIBLE FOR ANY MEDIATEK
# SOFTWARE RELEASES MADE TO RECEIVER'S SPECIFICATION OR TO CONFORM TO A PARTICULAR
# STANDARD OR OPEN FORUM. RECEIVER'S SOLE AND EXCLUSIVE REMEDY AND MEDIATEK'S ENTIRE AND
# CUMULATIVE LIABILITY WITH RESPECT TO MEDIATEK SOFTWARE RELEASED HEREUNDER WILL BE,
# AT MEDIATEK'S OPTION, TO REVISE OR REPLACE MEDIATEK SOFTWARE AT ISSUE,
# OR REFUND ANY SOFTWARE LICENSE FEES OR SERVICE CHARGE PAID BY RECEIVER TO
# MEDIATEK FOR SUCH MEDIATEK SOFTWARE AT ISSUE.
#

#!/bin/bash
#source ../.config

web_dir=$1
pageflag=
flag_type="NO_AUTH CACHE"

printhead()
{
	echo "/*" >> $filename
 	echo " * Generated by WEB converter:`date`" >> $filename
 	echo " * Do not edit" >> $filename
 	echo " */" >> $filename
}

getflag()
{
	var=$(echo "$1"|sed -e "s/.*\///g")
	var1=$(echo $var|sed -e "s/.*\.//g")
	for m in $flag_type ; do
		for j in `grep $m ./web.cfg | sed -e "s/$m=//"`; do
		if [ "$j" = "$var" ] || [ "$j" = "*.$var1" ] ; then
				pageflag=$pageflag"|"$m
		fi
		done
	done
	echo $pageflag
}

#generate webpage.c
filename=webpage.c

printhead

echo "#include \"web_proc.h\"" >> $filename
echo "#include \"webpage.h\"" >> $filename
echo "#include \"web_config.h\"" >> $filename
echo "#include \"webdata_bin.h\"" >> $filename
echo >> $filename

echo "const time_t time_pages_created =(`date +%s`+28800);"  >> $filename

#if	[ "$CONFIG_ZWEB" = "y" ] ; then
	#echo "const char* const zweb_location = NULL;" >> $filename
#else
	#echo "extern char _binary_webdata_bin_start[];" >> $filename
	#echo "const char* const zweb_location = &_binary_webdata_bin_start[0];" >> $filename
	#echo "extern char ___webdata_bin[];" >> $filename
	echo "const char* const zweb_location = (char *)(&webdata_bin[0]);" >> $filename
#fi

echo >> $filename

echo "webpage_entry webpage_table[]= {" >> $filename

rm -f webdata.bin

	if	[ "$CONFIG_ZWEB" = "y" ] ; then
		echo "WEBPAGES is compressed!"
	else
		echo "WEBPAGES without compression!"
	fi

for i in `cat web_list`; do
#	fn=`echo $i | sed -e "s/[\.\/]/_/g"`
	if	[ "$CONFIG_ZWEB" = "y" ] ; then
		pageflag="WEBP_COMPRESS"
	else
		pageflag="WEBP_NORMAL"
	fi
	getflag $i
	./webcomp_sin $i $web_dir ./web_c $filename $pageflag ../include/autoconf.h
	if [ $? -ne 0 ]; then
		exit -1
	fi
done

echo "{0 , NULL, 0, 0, 0, NULL, 0}," >> $filename
echo "};" >> $filename

#if	[ ! "$CONFIG_ZWEB" = "y" ] ; then
#	gzip webdata.bin ; mv webdata.bin.gz webdata.bin
#fi
dos2unix webdata.bin ;
sleep 2;
echo "#define WEBDATA_SZ `ls -l webdata.bin | cut -d ' ' -f 5`" >> webpage.h

#generate webpage.h
filename=webpage.h
printhead

echo "extern const time_t time_pages_created;" >> $filename
echo "extern webpage_entry webpage_table[];" >> $filename
echo "extern const unsigned char webdata_bin[];" >> $filename
echo "extern const char* const zweb_location;" >> $filename

find ./web_c -name "*.c" | sed -e 's/.\/web_c\/\(.*\).c/extern int \1(struct connstruct *req, char *datap);/' >> $filename

cat ./web_c/cgi_list >> $filename

# generate .objfiles
filename=./web_c/.objfiles
echo "WEB_OBJ = \\" >$filename
find ./web_c -name "*.c" | sed -e 's/.\/web_c\/\(.*\).c/.\/\1.o \\/' >> $filename

# generate webdata_bin.h
#echo -n "const " > webdata.h
#xxd -i webdata.bin >> webdata.h
cat webdata.bin | xxd -i > webdata.h