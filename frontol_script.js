function urlServ()
{
    return "192.168.0.18:4567"
}

function isNotOurCard(barcode)
{
    flag = true;
    prefix = barcode.substr(0,5);
    if (prefix == '01300') flag = false;
    prefix = barcode.substr(0,2);
    if (prefix == '79') flag = false;
    return flag;
}

function getXmlHttp(){
    try {
        return new ActiveXObject("Msxml2.XMLHTTP");
    } catch (e) {
        try {
            return new ActiveXObject("Microsoft.XMLHTTP");
        } catch (ee) {
        }
    }
    if (typeof XMLHttpRequest!='undefined') {
        return new XMLHttpRequest();
    }
    else {return false}
}

function BeforeAct(AO, RO, E, O, CO)
{
    if (RO.ReceiptTypeCode != 0)
        return;

    if (RO.Card.Count != 0)
        AO.ShowError ("Карта уже введена");

    barcode= O.Value;
    if (isNotOurCard(barcode))
        AO.ShowError ("Данная карта не обслуживается");

    var xmlhttp = getXmlHttp();
    url=urlServ();

    RO.UserValues.Set('DiscountValue',0);
    pos_id = RO.NShop.toString();
    doc_no = RO.ReceiptNo.toString();
    payment= RO.SummWD.toString();

    RO.UserValues.Set('Ready','');
    xmlhttp.open("GET", url+'/cards/'+pos_id+'/'+barcode+'/'+Math.random());
    xmlhttp.send(null);
    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            RO.UserValues.Set('Ready','1');
        }
    }

    counter=0;
    AO.ShowMessage('Проверяем баланс карты',Icon.Exclamation,2);
    if (xmlhttp.readyState == 4) {
        var data = eval('('+xmlhttp.responseText+')');
        sUsedBonus = data['bonuses'].toString();
        RO.UserValues.Set('DiscountValue',data['bonuses']);
        RO.UserValues.Set('Ready','2');
        AO.ShowMessage('На карте '+sUsedBonus+' рублей',Icon.Asterisk);
    }
    else
    {
        AO.ShowMessage('Нет связи с сервером!',Icon.Stop,5);
    }
}

function AfterAct(AO, RO, E, O, CO)
{
}

function FuncAct(AO, RO, CO)
{
}

function NoAction(AO, RO, POS, CO, UserParam)
{
}

function getUrl(AO, RO, POS, CO, UP) {
    var xmlhttp = getXmlHttp();
    url=urlServ();

    RO.UserValues.Set('DiscountValue',0);
    pos_id = RO.NShop.toString();
    doc_no = RO.ReceiptNo.toString();
    barcode= '0130019979780';
    payment= RO.SummWD.toString();
    //sNewBonus = '70';

    RO.UserValues.Set('Ready',0);
    xmlhttp.open("GET", url+'/cards/'+pos_id+'/'+barcode+'/'+Math.random());
    xmlhttp.send(null);
    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            RO.UserValues.Set('Ready',1);
        }
    }

    counter=0;
    AO.ShowMessage('Проверяем баланс карты',Icon.Exclamation,2);
    if (xmlhttp.readyState == 4) {
        var data = eval('('+xmlhttp.responseText+')');
        sUsedBonus = data['bonuses'].toString();
        RO.UserValues.Set('DiscountValue',data['bonuses']);
        AO.ShowMessage('Bonuses: '+sUsedBonus);
        percent = data['cashe_percent'];
        NewBonus = RO.SummWD*percent/100;
        sNewBonus = NewBonus.toString();
        params = "/cards/"+pos_id+"/"+doc_no+"/"+barcode+'/'+payment+'/'+sUsedBonus+'/'+sNewBonus;
        xmlhttp.open("GET", url+params);
        xmlhttp.send(null);
    }
    else
    {
        AO.ShowMessage('Нет связи с сервером!',Icon.Stop,5);
    }
}

function getUrl(AO, RO, POS, CO, UP) {
    var xmlhttp = getXmlHttp();
    url="http://10.0.2.2:4567";
    //url="http://192.168.0.8:4567";
    // IE кэширует XMLHttpRequest запросы, так что добавляем случайный параметр к URL
    // (хотя можно обойтись правильными заголовками на сервере)

    RO.UserValues.Set('DiscountValue',0);
    pos_id = RO.NShop.toString();
    doc_no = RO.ReceiptNo.toString();
    barcode= '0130019979780';
    payment= RO.SummWD.toString();
    //sNewBonus = '70';


    RO.UserValues.Set('Ready',0);
    xmlhttp.open("GET", url+'/cards/'+pos_id+'/'+barcode+'/'+Math.random());
    xmlhttp.send(null);
    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            RO.UserValues.Set('Ready',1);
        }
    }

    counter=0;
    AO.ShowMessage('Проверяем баланс карты',Icon.Exclamation,2);
    if (xmlhttp.readyState == 4) {
        var data = eval('('+xmlhttp.responseText+')');
        sUsedBonus = data['bonuses'].toString();
        RO.UserValues.Set('DiscountValue',data['bonuses']);
        AO.ShowMessage('Bonuses: '+sUsedBonus);
        percent = data['cashe_percent'];
        NewBonus = RO.SummWD*percent/100;
        sNewBonus = NewBonus.toString();
        params = "/cards/"+pos_id+"/"+doc_no+"/"+barcode+'/'+payment+'/'+sUsedBonus+'/'+sNewBonus;
        xmlhttp.open("GET", url+params);
        xmlhttp.send(null);
    }
    else
    {
        AO.ShowMessage('Нет связи с сервером!');
    }
}


function BeforeAct(AO, RO, E, O, CO)
{
}

function AfterAct(AO, RO, E, O, CO)
{

}

function FuncAct(AO, RO, CO)
{
}

function q(AO, RO, POS, CO)
{
    card_number = RO.UserValues.Get("card_number");
    summ = parseInt(card_number);
    result = summ;
    return result
}