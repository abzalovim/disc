function urlServ()
{
    return "http://192.168.0.8:4567"
}

function typeCard(barcode)
{
    flag = 0;
    prefix = barcode.substr(0,4);
    if ((prefix == '0130') || (prefix == '1300')) flag = 1;
    if ((prefix == '0150') || (prefix == '1500')) flag = 1;
    prefix = barcode.substr(0,2);
    if (prefix == '79') flag = 2;
    return flag;
}

function getXmlHttp(){
    try {
        return new ActiveXObject("Microsoft.XMLDOM");;
    } catch (e) {
        return false
    }
}

function BeforeAct(AO, RO, E, O, CO)
{
}

function AfterAct(AO, RO, E, O, CO)
{
    if (RO.ReceiptTypeCode != 1) //Только документ продажи
        return;
    if (RO.UserValues.Get('Ready') != '2') //Только обработанный дисконт
        return;
    if ((RO.Card.Count != 0) && (RO.Disc.Count != 0))                       //Если количество введенных карт не = 0
    {
        RO.Card.Index = 1;
        barcode = RO.Card.Value;
        pos_id = RO.NShop.toString();
        doc_no = RO.ReceiptNo.toString();
        payment= RO.SummWD;

        var xmlhttp = getXmlHttp();
        url=urlServ();
        if (xmlhttp) {
            maxDisc = RO.UserValues.Get('DiscountValue');
            percent = RO.UserValues.Get('ReturnValue');

            for (RO.Disc.Index = 1;                                             //Перебираем счетчики
                 RO.Disc.Index <=
                 RO.Disc.Count;
                 RO.Disc.Index++) {
                UsedBonus = 0;
                if ((RO.Disc.KindD == 2) && (RO.Disc.TypeD == 1))
                {
                    UsedBonus = RO.Disc.Value;
                    //payment=payment+UsedBonus;
                }
            }

            sUsedBonus = UsedBonus.toString();

            payment = payment.toString();

            NewBonus = Math.ceil(RO.SummWD * percent / 100);
            sNewBonus = NewBonus.toString();
            prms = pos_id + "/" + doc_no + "/" + barcode + '/' + payment + '/' + sUsedBonus + '/' + sNewBonus;
            if (typeCard(barcode) == 1)
                prms = "/cards/" + prms;
            else
                prms = "/clients/" + prms;
            xmlhttp.load(url + prms);
            if (NewBonus != 0)
                AO.ShowMessage('На карту начислено ' + sNewBonus + ' рублей', Icon.Exclamation, 5);
        }
    }
}

function FuncAct(AO, RO, CO)
{
}
