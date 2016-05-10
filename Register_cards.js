function urlServ()
{
    return "http://192.168.0.8:4567"
}

function typeCard(barcode)
{
    flag = 0;
    prefix = barcode.substr(0,5);
    if ((prefix == '01300') || (prefix == '13001')) flag = 1;
    if ((prefix == '01500') || (prefix == '15001')) flag = 3;
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
        return new ActiveXObject("Microsoft.XMLDOM");;
    } catch (e) {
        return false
    }
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
        gUrl = url+'/cards/'+pos_id+'/'+cCard(barcode)+'/'+Math.random()+'/xml';
    }
    else if (tCard==3) {
        gUrl = url+'/cards/'+pos_id+'/'+cCard(barcode)+'/'+Math.random()+'/xml';
    }
    else
    {
        gUrl = url+'/clients/'+pos_id+'/'+barcode+'/'+Math.random()+'/xml';
    }
    xmlhttp.async = false;
    r = xmlhttp.load(gUrl);
    if (r) {
        sUsedBonus = xmlhttp.getElementsByTagName("bonuses")[0].text;
        cashe_p = xmlhttp.getElementsByTagName("cashe_percent")[0].text;
        card_p = xmlhttp.getElementsByTagName("card_percent")[0].text;
        if (tCard==1) {
            repl = xmlhttp.getElementsByTagName("replace")[0].text;
            if (repl == "3") {
                AO.ShowError("Данная карта была заменена!");
            }
            while (repl=="1") {
                n_card = AO.InputString("Введите НОВУЮ карту!","",13);
                if (n_card==null) {
                    repl="2";
                }
                else {
                    resp = AO.ShowMessage("Подтвердите новую карту:"+\n+n_card,Button.YesNoCancel);
                    if (resp==DialogResult.Yes) {
                        gUrl = url+'/replace/'+barcode+'/'+n_card;
                        xmlhttp.load(gUrl);
                        repl="2";
                        barcode = n_card;
                    }
                    else if (resp==DialogResult.Cancel) {
                        repl="2";
                    }
                }

            }
            //AO.ShowError('Нет связи с сервером!',Icon.Stop,5);
        }
        if ((tCard == 2) && (data['cashe_percent']<0))
            AO.ShowError ("Номер телефона не известен");
        UsedBonus = parseFloat(sUsedBonus);

        RO.UserValues.Set('DiscountValue',UsedBonus);
        RO.UserValues.Set('ReturnValue',Math.max(cashe_p,card_p));
        RO.UserValues.Set('Ready','2');
        AO.ShowMessage('На карте '+sUsedBonus+' рублей',Icon.Asterisk);
    }
    else
    {
        AO.ShowError('Нет связи с сервером!',Icon.Stop,5);
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