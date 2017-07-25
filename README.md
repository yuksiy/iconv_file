# iconv_file

## 概要

ファイル単位に文字コード変換

## 使用方法

### iconv_file.sh

ファイル単位に文字コード変換を実行します。

手順例:

下記の例では、カレントディレクトリ直下にある「*.txt」というファイル名の
テキストファイルの文字コードを一括変換します。  
その際、変換元ファイルの文字コードを
「ASCII,CP932,UTF-8,UTF-16LE」の中から自動判別し、
自動判別に成功したファイル全てを「UTF-8」に変換します。  
自動判別できなかったファイルはスキップされます。

    $ iconv_file.sh -f ASCII,CP932,UTF-8,UTF-16LE -t UTF-8 *.txt

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux (Debian)
* Cygwin

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* iconv
* dos2unix (Cygwin の場合)
* tofrodos (Debian の場合)
* [common_sh](https://github.com/yuksiy/common_sh)

## インストール

ソースからインストールする場合:

    (Debian, Cygwin の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/iconv_file>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/iconv_file/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2008-2017 Yukio Shiiya
