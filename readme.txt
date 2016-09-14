印順導師 TEI XML 轉成 CBETA BM 

【程式位置】

https://github.com/heavenchou/yinshun2cbeta

【設置方法】

1. ys2bm.pl 放在一個空白目錄中 

(直接在 clone 的就是適合的情況, 但若您想要修改程式, 最好複製到另外的目錄再修改, 以免修改後無法順利拉取新版程式)

2. 建一子目錄 Yinshun_XML-2016.08.12 , 將 2016/08/16 版的印順導師全集 TEI XML 放在該目錄中. 沒有檔案者可以找 maha 拿.

【執行方法】

1. 完全不下參數, 可以看到說明檔 

命令 : perl ys2bm.pl

結果 :

Yinshun to CBETA BM

ex:
    perl ys2bm.pl 0 44    => run vol 0 to vol 44
    perl ys2bm.pl 3       => run vol 3
    perl ys2bm.pl         => show this help

2. 只執行一冊, 例如第 3 冊

命令 : perl ys2bm.pl 3

3. 執行指定範圍 , 例如 第 1 冊至第 5 冊

命令 : perl ys2bm.pl 1 5

4. 全部的範圍是 0 至 44 冊

命令 : perl ys2bm.pl 0 44

【結果檔】

會在程式目錄產生一個 BM 目錄，結果檔就在其中。


