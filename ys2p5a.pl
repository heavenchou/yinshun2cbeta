################################################
# 將印順法師全集的 xml 轉成 cbeta 格式的 P5a XML
################################################

use utf8;

use XML::DOM;
my $parser = new XML::DOM::Parser;

my $infile = "Yinshun_XML-2016.08.12/y01.xml";
my $outfile = "P5a/y01.xml";

# 開始分析 XML
my $text = ParserXML($infile);

# 將結果輸出
open OUT, ">:utf8", $outfile;
print OUT $text;
close OUT;
exit;

########################################################
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

# 處理節點
sub parseNode
{
	my $node = shift;
	my $nodeTypeName = $node->getNodeTypeName;
	if ($nodeTypeName eq "ELEMENT_NODE") 
    {
        # 處理起始標記
		my $head = start_handler($node);
        my $mid = "";
        
        # 處理子項目
		for my $kid ($node->getChildNodes) 
        {
			$mid .= parseNode($kid);
		}
        
        # 處理結束標記
        my $tail = end_handler($node);
        
        return $head . $mid . $tail;
	}
	elsif ($nodeTypeName eq "TEXT_NODE") 
    {
        # 處理文字
        my $text = text_handler($node);
        return $text;
    }
}

# 處理起始標記
sub start_handler
{
    my $node = shift;
    my $tag_name = $node->getNodeName();	# 取得標記名稱
    
    my $att_n = $node->getAttributeNode("n");	# 取得屬性
    my $att_n_v = "";
    if($att_n)
    {
        $att_n_v = $att_n->getValue();	# 取得屬性內容
    }
    return "";    
}

# 處理結束標記
sub end_handler
{
    my $node = shift;
    return "";
}

# 處理文字
sub text_handler
{
    my $node = shift;
    my $text = $node->getNodeValue();   # 取得文字
    return $text;     
}
