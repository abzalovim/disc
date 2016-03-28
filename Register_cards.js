function urlServ()
{
    return "http://192.168.0.8:4567"
}

function typeCard(barcode)
{
    flag = 0;
    prefix = barcode.substr(0,5);
    if ((prefix == '01300') || (prefix == '13001')) flag = 1;
    prefix = barcode.substr(0,2);
    if (prefix == '79') flag = 2;
    return flag;
}

function cCard(barcode)
{
    prefix = barcode.substr(0,5);
    if (prefix == '13001') barcode='0'+barcode;
    return barcode;
}

function getXmlHttp()
{
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
    if (RO.ReceiptTypeCode != 1) //Только документ продажи
        return;

    if (RO.Card.Count != 0)
        AO.ShowError ("Карта уже введена");

    barcode = O.Value;
    tCard = typeCard(barcode);
    if (tCard==0)
        AO.ShowError ("Данная карта не обслуживается");

    var xmlhttp = getXmlHttp();
    url=urlServ();

    pos_id = RO.NShop.toString();
    doc_no = RO.ReceiptNo.toString();

    RO.UserValues.Set('Ready','');
    if (tCard==1) {
        gUrl = url+'/cards/'+pos_id+'/'+cCard(barcode)+'/'+Math.random();
    }
    else
    {
        gUrl = url+'/clients/'+pos_id+'/'+barcode+'/'+Math.random();
    }
    xmlhttp.open("GET", gUrl);
    xmlhttp.send(null);
    xmlhttp.onreadystatechange = function() {
        if ((xmlhttp.readyState == 4) && (xmlhttp.status == 200)) {
            RO.UserValues.Set('Ready','1');
        }
    };

    counter=0;
    AO.ShowMessage('Проверяем баланс карты',Icon.Exclamation,2);
    if (xmlhttp.status == 200) {
        var data = eval('('+xmlhttp.responseText+')');
        if ((tCard == 2) && (data['cashe_percent']<0))
            AO.ShowError ("Номер телефона не известен");
        sUsedBonus = data['bonuses'].toString();

        RO.UserValues.Set('DiscountValue',data['bonuses']);
        RO.UserValues.Set('ReturnValue',Math.max(data['cashe_percent'],data['card_percent']));
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