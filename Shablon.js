/**
 * Created by salimbek on 10.05.16.
 */
    percent = RO.UserValues.Get('ReturnValue');
function PrintHeader(PO, RO, CO)
{
    if (RO.UserValues.Get('Ready')=='2') {
    }
    else
    {
        //PO.Cancel();
    }
}

function PrintPosition(PO, RO, CO)
{
    if (RO.Pos.Storno == 1)
        PO.PrintCenterString("СТОРНО"," ");

    if (RO.Pos.Storno == 0)
    {


    }
}

function PrintFooter(PO, RO, CO)
{
    if(RO.ClientCard != "")
        PO.PrintStringWordWrap("Карта: "+RO.ClientCard);

    PO.PrintStringWordWrap(" ");
    PO.PrintCenterString("Информация по бонусам:"," ");

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
    maxDisc = RO.UserValues.Get('DiscountValue');;
    percent = RO.UserValues.Get('ReturnValue');
    NewBonus = Math.ceil(RO.SummWD * percent / 100);
    sNewBonus = NewBonus.toString();
    PO.PrintStringWordWrap("Списано:         "+UsedBonus.toString());
    PO.PrintStringWordWrap("Начислено:       "+sNewBonus);
    PO.PrintStringWordWrap("Текущий остаток: "+(maxDisc-UsedBonus+NewBonus).toString());
}