function getDiscount(AO, RO, POS, CO, UV)
{
    if (RO.Card.Count != 1)
        AO.Cancel();
    v1 = RO.SummForD*RO.UserValues.Get('ReturnValue')/100;
    //AO.ShowMessage(typeof(v1)+'-'+v1);
    v2 = parseInt(RO.UserValues.Get('DiscountValue'));
    //AO.ShowMessage(typeof(v2)+'-'+v2);
    ret = Math.min(v1,v2);
    //AO.ShowMessage('ret:'+ret);
    return Math.min(v1,v2);
}

function q(AO, RO, POS, CO, UV)
{
var xml = new ActiveXObject("Microsoft.XMLDOM");
xml.async = false;
r = xml.load("http://10.0.2.2:4567/cards/1/0130019979780/19/xml");
//AO.ShowMessage("Start");
if (r) {
x = xml.getElementsByTagName("keys")[0];
for (var i=0; i<x.childNodes.length; i++) {
    var child = x.childNodes[i];
    AO.ShowMessage(child.tagName+":"+child.text);
}

xml = false;
}
}
