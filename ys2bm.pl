##################################################
# 將印順法師全集的 xml 轉成 cbeta 格式的簡單標記版
# by heaven 2016/09/02
##################################################
#use 5.010;
use utf8;
use strict;

use XML::DOM;
my $parser = new XML::DOM::Parser;

######################
# 參數
######################

my $infile = "Yinshun_XML-2016.08.12/y01.xml";

my $outfile = "BM/y01.txt";
my $logfile = "errlog.txt";
my $notefile = "BM/y01note.txt";

######################
# 變數
######################

my $errlog = "";    # 錯誤記錄
my $text = "";      # 內文
my $note_text = "";  # note 記錄
my @tags = ();      # 將 tag name 逐一推入堆疊中

my $_linehead = "Y01n0001_p";   # 行首的基本資料

# 開始分析 XML
$text = ParserXML($infile);

# 將結果輸出
open OUT, ">:utf8", $outfile;
print OUT $text;
close OUT;

open OUT, ">:utf8", $logfile;
print OUT $errlog;
close OUT;

open OUT, ">:utf8", $notefile;
print OUT $note_text;
close OUT;

exit;

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
	my $root = $doc->getDocumentElement();
	my $text = parseNode($root);	# 進行分析
	$root->dispose;
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
        
        if($tag_name eq "lb") { $text = tag_lb($node); }
        elsif($tag_name eq "p")  { $text = tag_p($node); }
        elsif($tag_name eq "note")  { $text = tag_note($node); }
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

# <note>
# <note resp="周怡曄">《妙法蓮華經》卷1〈2 方便品〉(CBETA, T09, no. 262, p. 5, c10-13)</note>
sub tag_note
{
    my $node = shift;
    my $text = "";
    
    # 處理標記
    
    # note 有很多種
    # 1.只有在 <q> 引文標記中的 note 才是註解, 且要有 resp 屬性才算 (嚴格檢查)
    # 2. place="inline2" 是雙行小註 <note place="inline2"....> 
   
    # 1.
    if("q" ~~ @tags)
    {
        my $att_resp = $node->getAttributeNode("resp");	# 取得屬性
        if($att_resp)
        {
            $text = "[＊]";
            
            # 處理內容
            my $txt = parseChild($node);
            $note_text .= "$txt\n"; 
            
            return $text;
        }
    }
    
    # 2.
    
    my $att_place = $node->getAttributeNode("place");	# 取得屬性
    if($att_place)
    {
        my $n = $att_place->getValue();	    # 取得屬性內容
        if($n eq "inline2")
        {
            $text = "(";
            
            # 處理內容
            $text .= parseChild($node);
            
            $text .= ")";
            return $text;   
        }
    }
    
    # 3 . 其他不明 note
    
    $text = tag_default($node);
    
    # 處理標記結束
    return $text;
}

# 處理預設標記
# <xxx>abc</xxx>
sub tag_default
{
    my $node = shift;
    my $text = "";
    
    # 處理標記 <xxx>
    $text = "<<" . $node->getNodeName . ">>";
    
    # 處理內容 abc
    $text .= parseChild($node);
    
    # 處理標記結束 </xxx>
    
    return $text;
}

