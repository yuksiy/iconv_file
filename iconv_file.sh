#!/bin/sh

# ==============================================================================
#   機能
#     ファイル単位に文字コード変換を実行する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2008-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_ROOT=`dirname $0`
SCRIPT_NAME=`basename $0`
PID=$$

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	:
}

POST_PROCESS() {
	:
}

# 変換対象ファイルの一覧表示
FILE_LIST() {
	for i in "$@" ; do
		# 変換元ファイルのチェック
		SRC_FILE_CHECK "${i}"
		# 変換元ファイルのチェックに成功した場合
		if [ $? -eq 0 ];then
			# ファイルの文字コード判別
			FROM_CODE="`ICONV_GUESS_FILE \"${i}\"`"
			# ファイルの文字コード判別が失敗した場合
			if [ "${FROM_CODE}" = "" ];then
				FROM_CODE="UNKNOWN"
			fi
			# 文字コード自動判別結果の表示
			printf "${FILE_LIST_PRINTF_FORMAT}" "${FROM_CODE}"
			# ファイル情報の表示
			ls ${FILE_LIST_LS_OPTIONS} "${i}"
			if [ $? -ne 0 ];then
				echo "-E Command has ended unsuccessfully." 1>&2
				POST_PROCESS;exit 1
			fi
		fi
	done
}

# ファイル単位に文字コード変換
#   (補足) nkfコマンドの--overwriteオプションとの相違点
#     ・変換元ファイルのパーミッションは保持するが、タイムスタンプは保持しない。
#     ・変換元ファイルを変換結果で上書きするが、
#       変換時に作成したバックアップファイルを削除せずに残す。
#       (オプション指定によって、バックアップファイルを削除して残さないことも可能。)
ICONV_FILE() {
	for i in "$@" ; do
		# 変換元ファイルのチェック
		SRC_FILE_CHECK "${i}"
		# 変換元ファイルのチェックに成功した場合
		if [ $? -eq 0 ];then
			# ファイルの文字コード判別
			FROM_CODE="`ICONV_GUESS_FILE \"${i}\"`"
			# ファイルの文字コード判別が失敗した場合
			if [ "${FROM_CODE}" = "" ];then
				echo "-W \"${i}\" cannot guess FROM_CODE, skipped" 1>&2
			# ファイルの文字コード判別が成功した場合
			else
				# バックアップファイルが既存の場合
				if [ -f "${i}${BACKUP_FILE_SUFFIX}" ];then
					echo "-W \"${i}${BACKUP_FILE_SUFFIX}\" file exist" 1>&2
					# YES オプションが指定されていない場合
					if [ "${FLAG_OPT_YES}" = "FALSE" ];then
						# 上書き確認
						echo "-Q Overwrite?" 1>&2
						YESNO
						# YES の場合
						if [ $? -eq 0 ];then
							echo "-W Overwriting..." 1>&2
						# NO の場合
						else
							echo "-W Skipping..." 1>&2
							continue
						fi
					# YES オプションが指定されている場合
					else
						echo "-W Overwriting..." 1>&2
					fi
				fi
				# 変換元ファイルのバックアップ
				CMD_V "cp -p \"${i}\" \"${i}${BACKUP_FILE_SUFFIX}\""
				if [ $? -ne 0 ];then
					echo "-E Command has ended unsuccessfully." 1>&2
					POST_PROCESS;exit 1
				fi
				# 変換元ファイルの文字コード変換
				CMD_V "${ICONV} ${ICONV_OPTIONS_INT:+${ICONV_OPTIONS_INT} }-f ${FROM_CODE} -t ${TO_CODE} \"${i}${BACKUP_FILE_SUFFIX}\" ${LINE_MODE_CONV:+| ${LINE_MODE_CONV} }> \"${i}\""
				if [ $? -ne 0 ];then
					echo "-E Command has ended unsuccessfully." 1>&2
					POST_PROCESS;exit 1
				fi
				# NO_BACKUP オプションが指定されている場合
				if [ "${FLAG_OPT_NO_BACKUP}" = "TRUE" ];then
					# バックアップファイルの削除
					CMD_V "rm \"${i}${BACKUP_FILE_SUFFIX}\""
					if [ $? -ne 0 ];then
						echo "-E Command has ended unsuccessfully." 1>&2
						POST_PROCESS;exit 1
					fi
				fi
			fi
		fi
	done
}

# ファイルの文字コード判別
ICONV_GUESS_FILE() {
	# 文字コード(code)のループ
	for code in ${FROM_CODES} ; do
		${ICONV} -f ${code} -t ${code} "$1" > /dev/null 2>&1
		if [ $? -eq 0 ];then
			echo "${code}"
			break
		fi
	done
}

# 変換元ファイルのチェック
SRC_FILE_CHECK() {
	# 変換元ファイルが既存の場合
	if [ -f "$1" ];then
		# 変換元ファイルが読み取り可能の場合
		if [ -r "$1" ];then
			return 0
		# 変換元ファイルが読み取り可能でない場合
		else
			echo "-W \"$1\" file not readable, skipped" 1>&2
			return 1
		fi
	# 変換元ファイルが既存でない場合
	else
		echo "-W \"$1\" file not exist, or not a file, skipped" 1>&2
		return 1
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    iconv_file.sh -f FROM_CODES[,...] -t TO_CODE [-L LINE_MODE]
		      [-B] [-N] [-Y] SRC_FILES ...
		    iconv_file.sh -l
		    iconv_file.sh --help
		
		    -f FROM_CODES[,...]
		       Convert characters from FROM_CODE.
		       If multiple FROM_CODE are specified, FROM_CODE are tried one by one.
		    -t TO_CODE
		       Convert characters to TO_CODE.
		    -L LINE_MODE
		       Convert line mode to LINE_MODE.
		         LINE_MODE are:
		           u = unix (LF)
		           w = windows (CRLF)
		           n = No conversion
		       When this option is not specified, "n" is assumed.
		    -B (batch-mode)
		       If this option is specified, following interactive processes are skipped:
		         * Guessing and listing source files.
		         * Prompting message before converting source files.
		    -N (no-backup)
		       Don't keep backed-up "X${BACKUP_FILE_SUFFIX}" file created when file X is converted.
		    -Y (yes)
		       Suppresses prompting to confirm you want to overwrite an existing
		       backed-up "X${BACKUP_FILE_SUFFIX}" file.
		    -l (list)
		       List known character codesets and exit.
		    --help
		       Display this help and exit.
	EOF
}

. cmd_v_function.sh
. yesno_function.sh

# 処理継続確認
CALL_YESNO() {
	echo "-Q Continue?"
	#echo "-Q 続行しますか？"
	YESNO
	if [ $? -ne 0 ];then
		# 作業終了後処理
		echo "-I Interrupted."
		#echo "-I 中断します"
		POST_PROCESS;exit 0
	fi
}

######################################################################
# 変数定義
######################################################################
# ユーザ変数
BACKUP_FILE_SUFFIX=".iconv.bak"

FILE_LIST_LS_OPTIONS="-al --full-time --show-control-chars"

#FILE_LIST_PRINTF_FORMAT="%-12s"
FILE_LIST_PRINTF_FORMAT="%s\t"

# システム環境 依存定義
ICONV="iconv"
ICONV_OPTIONS_INT=""
DOS2UNIX="dos2unix"
UNIX2DOS="unix2dos"
case `uname -s` in
Linux)
	output_check_linux="$(. /etc/os-release && echo "${ID}")"
	case "${output_check_linux}" in
	debian)
		DOS2UNIX="fromdos"
		UNIX2DOS="todos"
		;;
	esac
	;;
esac

# プログラム内部変数
FROM_CODES=""
TO_CODE=""
LINE_MODE_CONV=""

FLAG_OPT_BATCH_MODE=FALSE
FLAG_OPT_NO_BACKUP=FALSE
FLAG_OPT_YES=FALSE

#DEBUG=TRUE

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o f:t:L:BNYl -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-f)
		# 指定された文字コードがiconvでサポートされているか否かのチェック
		for code in `echo "$2" | sed -e 's/,/ /g'` ; do
			${ICONV} -l | grep -q -w -e "${code}"
			if [ $? -ne 0 ];then
				echo "-E argument to \"-${opt}\" includes unknown character codeset -- \"${code}\"" 1>&2
				USAGE;exit 1
			fi
		done
		FROM_CODES="`echo \"$2\" | sed -e 's/,/ /g'`"
		shift 2
		;;
	-t)
		# 指定された文字コードがiconvでサポートされているか否かのチェック
		${ICONV} -l | grep -q -w -e "$2"
		if [ $? -ne 0 ];then
			echo "-E argument to \"-${opt}\" includes unknown character codeset -- \"$2\"" 1>&2
			USAGE;exit 1
		fi
		TO_CODE="$2"
		shift 2
		;;
	-L)
		# 指定された改行方式のチェック
		case "$2" in
		u)	LINE_MODE_CONV="${DOS2UNIX}";;
		w)	LINE_MODE_CONV="${UNIX2DOS}";;
		n)	LINE_MODE_CONV="";;
		*)
			echo "-E argument to \"-${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE;exit 1
			;;
		esac
		shift 2
		;;
	-B)	FLAG_OPT_BATCH_MODE=TRUE ; shift 1;;
	-N)	FLAG_OPT_NO_BACKUP=TRUE ; shift 1;;
	-Y)	FLAG_OPT_YES=TRUE ; shift 1;;
	-l)
		CMD_V "${ICONV} -l"
		exit 0
		;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# オプションの整合性チェック
# -f と-t の両方が指定されなかった場合
if [ \( "${FROM_CODES}" = "" \) -o \( "${TO_CODE}" = "" \) ];then
	echo "-E Both \"-f\" and \"-t\" options are not specified" 1>&2
	USAGE;exit 1
fi

# 引数のチェック
if [ "$*" = "" ];then
	echo "-E Missing SRC_FILES argument" 1>&2
	USAGE;exit 1
fi

# 作業開始前処理
PRE_PROCESS

# 文字コード変換前ファイルの一覧表示
if [ "${FLAG_OPT_BATCH_MODE}" = "FALSE" ];then
	echo
	FILE_LIST "$@"
	echo
	echo "-I Files listed above are converted."
	#echo "-I 上記のファイルが変換されます"
	# 処理継続確認
	CALL_YESNO
fi

# 処理開始メッセージの表示
echo
echo "-I File convert has started."

# ファイル単位に文字コード変換
ICONV_FILE "$@"

# 文字コード変換後ファイルの一覧表示
if [ "${FLAG_OPT_BATCH_MODE}" = "FALSE" ];then
	# ・FROM_CODES オプション引数にTO_CODE オプション引数の値が含まれないケース
	#   では、「文字コード変換後ファイルの一覧表示」の際の文字コード判別結果が
	#   「UNKNOWN」になってしまう。
	#   そこで、「文字コード変換後ファイルの一覧表示」の際には、FILE_LIST 関数の
	#   呼び出し前にFROM_CODES 変数にTO_CODE 変数の値を付加してからFILE_LIST 関
	#   数を呼び出す。
	#   そして、FILE_LIST 関数の呼び出し後にFROM_CODES 変数の値を元に戻す。
	#   (現状では、以降の処理でFROM_CODES 変数の値が参照されることがないため元に
	#    戻す必要はないのだが、処理速度がそれほど増えるわけでもないので念のため。)
	echo
	FROM_CODES_SAVE="${FROM_CODES}"
	FROM_CODES="${FROM_CODES} ${TO_CODE}"
	FILE_LIST "$@"
	FROM_CODES="${FROM_CODES_SAVE}"
	echo
	echo "-I Files listed above have been converted."
	#echo "-I 上記のファイルが変換されました"
fi

# 処理終了メッセージの表示
echo
echo "-I File convert has ended successfully."

# 作業終了後処理
POST_PROCESS;exit 0

