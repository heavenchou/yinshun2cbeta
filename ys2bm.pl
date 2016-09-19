###############################################
# 將印順法師全集的 xml 轉成 cbeta 格式的簡單標記版
#                             heaven 2016/09/02
###############################################

use utf8;
use strict;
use XML::DOM;

##########################
# 處理傳入參數, 要執行的冊數

my $volfrom = shift;
my $volto = shift;

if($volfrom eq "" and $volto eq "")
{
    # 沒有參數
    showhelp();
}
elsif($volfrom =~ /\D+/ or $volto =~ /\D+/)
{
    # 參數有錯, 呈現說明
    showhelp();
}
elsif($volfrom < 0 or $volfrom > 44 or $volto < 0 or $volto > 44)
{
    # 範圍不對
    showhelp();
}
else
{
    if($volto eq "")
    {
        # 如果只有一個參數, 就只執行該冊
        $volto = $volfrom;
    }
}

######################
# 變數
######################

my $parser = new XML::DOM::Parser;

my $errlog = "";    # 錯誤記錄
my $text = "";      # 內文
my $note_text = "";  # note 記錄
my @tags = ();      # 將 tag name 逐一推入堆疊中
my $div_level = 0;  # div 的層次, 第一層要轉成 <Q1> ,第二層 <Q2> 依此類推
my $list_level = 0;  # div 的層次, 第一層的 item 要轉成 <I1> ,第二層 <I2> 依此類推
my %no_use_tag = ();    # 記錄沒有處理的 tag
my $_linehead = "Y01n0001_p";   # 行首的基本資料

my $vol = "";    # y01 處理冊數

for(my $i = $volfrom; $i <= $volto; $i++)
{
    $vol = sprintf("y%02d", $i);
    run_file($vol);   
}

exit;

##################################
# 程式說明

sub showhelp
{
    print "
Yinshun to CBETA BM

ex:
    perl ys2bm.pl 0 44    => run vol 0 to vol 44
    perl ys2bm.pl 3       => run vol 3
    perl ys2bm.pl         => show this help
";
    exit;
}

##################################
# 變數初值化
sub initial
{
    my $vol = shift;
    my $sutra = substr($vol,1);
    
    $errlog = "";    # 錯誤記錄
    $text = "";      # 內文
    $note_text = "";  # note 記錄
    @tags = ();      # 將 tag name 逐一推入堆疊中
    $div_level = 0;  # div 的層次, 第一層要轉成 <Q1> ,第二層 <Q2> 依此類推
    $list_level = 0;  # div 的層次, 第一層的 item 要轉成 <I1> ,第二層 <I2> 依此類推
    %no_use_tag = ();    # 記錄沒有處理的 tag
    
    $_linehead = sprintf("Y%02dn%04d_p", $sutra, $sutra);   # Y01n0001_p 行首的基本資料 
}

################################################################
# 執行一個檔案
sub run_file
{
    my $vol = shift;
    
    initial($vol);  # 變數初值化
    
    ######################
    # 參數
    ######################

    my $infile = "Yinshun_XML-2016.08.12/${vol}.xml";

    my $outfile = "BM/${vol}.txt";
    my $logfile = "BM/${vol}_errlog.txt";
    my $notefile = "BM/${vol}_note.txt";
    
    if(not -d "BM")
    {
        mkdir("BM");
    }

    ######################
    # 主程式
    ######################

    # 開始分析 XML
    $text = ParserXML($infile);

    # 將結果輸出
    open OUT, ">:utf8", $outfile;
    $text =~ s/^\n*//;
    print OUT $text;
    close OUT;
    
    # 將錯誤報告輸出
    open OUT, ">:utf8", $logfile;
    print OUT $errlog;
    close OUT;

    # 將註解輸出
    open OUT, ">:utf8", $notefile;
    print OUT $note_text;
    close OUT;
    
    # 印出沒有處理到的標記
    print "vol = $vol\n"; 
    foreach my $key (keys(%no_use_tag))
    {
        print "<$key>" . "\n";
    }
}


##################################
# 記錄錯誤訊息
sub write_err
{
    my $msg = shift;
    my $txt = shift;
    $errlog .= $msg . " : " . $txt . "\n";
}

#######################################################################
# 處理 XML
sub ParserXML
{
    my $file = shift;
	my $doc = $parser->parsefile($file);
	#my $root = $doc->getDocumentElement();
    my @body = $doc->getElementsByTagName("body");
	my $text = parseNode($body[0]);	# 進行分析
	$doc->dispose;
    return $text;
}

sub parseNode
{
    my $node = shift;
    my $text = "";
    my $nodeTypeName = $node->getNodeTypeName;
	if ($nodeTypeName eq "ELEMENT_NODE") 
    {
        # 處理標記
        my $tag_name = $node->getNodeName();	# 取得標記名稱     
        push(@tags, $tag_name);                 # 將 tag name 推入堆疊
        
        
        if   ($tag_name eq "author")  { $text = skip_tag($node); }
        elsif($tag_name eq "bibl")  { $text = skip_tag($node); }
        elsif($tag_name eq "biblScope")  { $text = skip_tag($node); }
        elsif($tag_name eq "byline")  { $text = tag_byline($node); }     
        elsif($tag_name eq "cb")  { $text = skip_tag($node); }   
        elsif($tag_name eq "cell")  { $text = tag_cell($node); }   
        elsif($tag_name eq "choice")  { $text = tag_choice($node); }
        elsif($tag_name eq "cit")  { $text = skip_tag($node); }
        elsif($tag_name eq "corr")  { $text = tag_corr($node); }
        elsif($tag_name eq "div")  { $text = tag_div($node); }
        elsif($tag_name eq "editor")  { $text = skip_tag($node); }
        elsif($tag_name eq "figure")  { $text = tag_figure($node); }
        elsif($tag_name eq "figDesc")  { $text = ""; }
        elsif($tag_name eq "foreign")  { $text = skip_tag($node); }
        elsif($tag_name eq "g")  { $text = tag_g($node); }
        elsif($tag_name eq "graphic")  { $text = skip_tag($node); }
        elsif($tag_name eq "head")  { $text = skip_tag($node); }
        elsif($tag_name eq "item")  { $text = tag_item($node); }  
        elsif($tag_name eq "l")  { $text = skip_tag($node); }
        elsif($tag_name eq "label")  { $text = skip_tag($node); }
        elsif($tag_name eq "lb") { $text = tag_lb($node); }
        elsif($tag_name eq "lg")  { $text = tag_lg($node); }
        elsif($tag_name eq "list")  { $text = tag_list($node); }
        elsif($tag_name eq "listBibl")  { $text = skip_tag($node); }
        elsif($tag_name eq "note")  { $text = tag_note($node); }
        elsif($tag_name eq "num")  { $text = skip_tag($node); }
        elsif($tag_name eq "opener")  { $text = tag_opener($node); }
        elsif($tag_name eq "orig")  { $text = skip_tag($node); }
        elsif($tag_name eq "p")  { $text = tag_p($node); }
        elsif($tag_name eq "pb")  { $text = skip_tag($node); }
        elsif($tag_name eq "persName")  { $text = skip_tag($node); }
        elsif($tag_name eq "ptr")  { $text = tag_ptr($node); }
        elsif($tag_name eq "q")  { $text = skip_tag($node); }
        elsif($tag_name eq "ref")  { $text = tag_ref($node); }
        elsif($tag_name eq "reg")  { $text = tag_reg($node); }
        elsif($tag_name eq "row")  { $text = tag_row($node); }
        elsif($tag_name eq "seg")  { $text = skip_tag($node); }
        elsif($tag_name eq "sic")  { $text = skip_tag($node); }
        elsif($tag_name eq "table")  { $text = tag_table($node); }
        elsif($tag_name eq "title")  { $text = skip_tag($node); }
        else { $text = tag_default($node); }
        
        pop(@tags);
    }
	elsif ($nodeTypeName eq "TEXT_NODE") 
    {
        # 處理文字
        $text = text_handler($node);
    }   
    return $text; 
}


# 處理子程序
sub parseChild
{
    my $node = shift;
    my $text = "";
    
    for my $kid ($node->getChildNodes) 
    {
        $text .= parseNode($kid);
    }
    
    return $text;    
}

# 處理文字
sub text_handler
{
    my $node = shift;
    my $text = $node->getNodeValue();   # 取得文字
    $text =~ s/\n//g;   # 移除換行
    return $text;     
}

#######################################################################
# 處理各種標記
#######################################################################

# <byline>
sub tag_byline
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "<B>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束    
    return $text;
}

# <cell>
sub tag_cell
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    # <cell> => <c>
    # <cell cols="3"> => <c3>
    # <cell rows="3"> => <c r3>
    # <cell cols="3" rows="3"> => <c3 r3>

    my $att_cols = $node->getAttributeNode("cols");	# 取得屬性
    my $att_cols_v = "";
    if($att_cols)
    {
        $att_cols_v = $att_cols->getValue();	# 取得屬性內容
    }
    
    my $att_rows = $node->getAttributeNode("rows");	# 取得屬性
    my $att_rows_v = "";
    if($att_rows)
    {
        $att_rows_v = $att_rows->getValue();	# 取得屬性內容
    }
    
    $text = "<c";
    if($att_cols_v) { $text .= $att_cols_v; }
    if($att_rows_v) { $text .= " r" . $att_rows_v; }
    $text .= ">";

    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <choice>
sub tag_choice
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    # <choice><orig>裏</orig><reg>裡</reg></choice>
    # 改成
    # [裏;裡]
    
    $text = "[";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    $text .= "]";
    
    return $text;
}

# <corr>
# <choice><sic>？</sic><corr resp="厚觀法師 周怡曄">！</corr></choice>
# 改成
# [？>！]

sub tag_corr
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = ">";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <div>
sub tag_div
{
    my $node = shift;
    my $text = "";
    
    $div_level++;
    
    # 處理標記
    $text = "<Q${div_level}>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    
    $div_level--;
    
    return $text;
}

# <figure>
sub tag_figure
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "【圖】";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <g ref="#Z1295"/>
sub tag_g
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    my $att_ref = $node->getAttributeNode("ref");	# 取得屬性
    if($att_ref)
    {
        my $ref = $att_ref->getValue();	# 取得屬性內容
        $text = "[" . $ref . "]";
    }
    else
    {
        write_err("<g> 標記沒有 ref 屬性", $node->toString());
        $text = "[？]";
    }
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束    
    return $text;
}

# <item>
sub tag_item
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "<I${list_level}>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <lb>
sub tag_lb
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    my $att_n = $node->getAttributeNode("n");	# 取得屬性
    if($att_n)
    {
        # <lb n="1.01"/>
        my $n = $att_n->getValue();	# 取得屬性內容
        
        if($n =~ /^(.*?)\.(.*)$/)
        {
            my $page = $1;
            my $line = $2;
            
            $text = sprintf("\n%s%04sa%02d_##", $_linehead , $page , $line);
        }
        else
        {
            # <lb> 之中的 n 屬性不是 xx.xx 格式
            write_err("lb 的 n 屬性不是 xx.xx 格式", $node->toString());
        }
        
    }
    else
    {
        # <lb> 沒有 n 屬性, 怪怪的吧
        # 果然有, 雙行小註切行的內容, BM 不管它 
        # <note place="inline2" rend="font-size:medium;color:black">研究<lb/>攝論</note>
    }
    
    # 處理內容
    # 處理標記結束
    return $text;
}


# <lg>
sub tag_lg
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "<T>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    $text .= "</T>";
    
    return $text;
}

# <list>
sub tag_list
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $list_level++;
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    $list_level--;
    
    if($list_level == 0)
    {
        $text .= "</L>";
    }
    return $text;
}

# <note>
# <note resp="周怡曄">《妙法蓮華經》卷1〈2 方便品〉(CBETA, T09, no. 262, p. 5, c10-13)</note>
sub tag_note
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    
    # note 有很多種
    # 1. 只有在 <q> 引文標記中的 note 才是註解, 且要有 resp 屬性才算 (嚴格檢查)
    # 2. place="inline2" 是雙行小註 <note place="inline2"....> 
    #    也有 place="inline", Y10 : <note place="inline"><title level="a">（業品）</title></note>
    # 3. 忽略這些
    #    Y13 有這種的 <note type="authorial">（西田幾多郎）</note>
    #    Y14 有這種的 <note type="editorial">民國三〇年撰</note>
    # 4. Y25 發現真正的註解
    #    <ptr type="note" target="#note1.001"/>能大師於韶州大梵寺施法壇經一卷</p><lb
    #    <div type="note"><p><note xml:id="note1.001">慧，「原本」作惠，唐人通寫，今一律改正為慧。</note>
    #    所以 <ptr> 依然呈現註解方式 [＊]
    #    <note xml:id="note1.001"> 在內文留著, 註解區也留著一份
   
    # 1.

    my $att_resp = $node->getAttributeNode("resp");	# 取得屬性
    if($att_resp)
    {
        $text = "[＊]";
        
        # 處理內容
        my $txt = parseChild($node);
        $note_text .= "$txt\n";         # 存入註解檔 
        
        return $text;
    }
    
    # 2.
    
    my $att_place = $node->getAttributeNode("place");	# 取得屬性
    if($att_place)
    {
        my $n = $att_place->getValue();	    # 取得屬性內容
        if($n eq "inline" or $n eq "inline2" )
        {
            $text = "(";
            
            # 處理內容
            $text .= parseChild($node);
            
            $text .= ")";
            return $text;   
        }
    }

    # 3.
    
    my $att_type = $node->getAttributeNode("type");	# 取得屬性
    if($att_type)
    {
        my $n = $att_type->getValue();	    # 取得屬性內容
        if($n eq "authorial" or $n eq "editorial")
        {
            # 處理內容
            $text .= parseChild($node);
            return $text;   
        }
    }
    
    # 4.<note xml:id="note1.001">慧，「原本」作惠，唐人通寫，今一律改正為慧。</note>
    
    my $att_id = $node->getAttributeNode("xml:id");	# 取得屬性
    if($att_id)
    {
        my $id = $att_id->getValue();	    # 取得屬性內容
        if($id =~ /note.*/)
        {
            # 處理內容
            my $txt = parseChild($node);
            $text .= $txt;
            $note_text .= "$txt\n";
            return $text;   
        }
    }    
    
    # 其他不明 note
    
    $text = tag_default($node);
    
    # 處理標記結束
    return $text;
}

# <opener>
sub tag_opener
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "<J>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <p>
sub tag_p
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "<p>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <ptr>
sub tag_ptr
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "[＊]";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <ref>
# <ref type="taixu" target="vol:29;page:p188"/>
# 轉成 [＊]
# 並將 taixu::vol:29;page:p188 放在註解檔
sub tag_ref
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    my $att_type = $node->getAttributeNode("type");	# 取得屬性
    my $att_type_n = "";
    if($att_type)
    {
        $att_type_n = $att_type->getValue();	# 取得屬性內容
    }
    
    my $att_target = $node->getAttributeNode("target");	# 取得屬性
    my $att_target_n = "";
    if($att_target)
    {
        $att_target_n = $att_target->getValue();	# 取得屬性內容
    }
    
    if($att_target_n or $att_type_n)
    {
        $note_text .= $att_type_n . "::" . $att_target_n . "\n";
    }
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    $text .= "[＊]";
    
    return $text;
}

# <reg>
# <choice><orig>裏</orig><reg>裡</reg></choice>
# 改成
# [裏;裡]

sub tag_reg
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = ";";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <row>
sub tag_row
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "<r>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    return $text;
}

# <table>
sub tag_table
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    $text = "<F>";
    
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束
    $text .= "</F>";
    return $text;
}

# 忽略標記, 只取內容
sub skip_tag
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
   
    # 處理內容
    $text .= parseChild($node);
    
    # 處理標記結束 </xxx>
    
    return $text;
}

# 處理預設標記
# <xxx>abc</xxx>
sub tag_default
{
    my $node = shift;
    my $text = "";
    
    # 處理標記 <xxx>
    if($node->getNodeName ne "body")
    {
        $no_use_tag{$node->getNodeName} = 1;    # 記錄沒用過的 tag
        $text = "<<" . $node->getNodeName . ">>";
    }
    
    # 處理內容 abc
    $text .= parseChild($node);
    
    # 處理標記結束 </xxx>
    
    return $text;
}
