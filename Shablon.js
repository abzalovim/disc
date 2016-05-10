/**
 * Created by salimbek on 10.05.16.
 */
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
        PO.PrintCenterString("ÑÒÎÐÍÎ"," ");

    if (RO.Pos.Storno == 0)
    {


    }
}

function PrintFooter(PO, RO, CO)
{
    if(RO.ClientCard != "")
        PO.PrintStringWordWrap("Êàðòà: "+RO.ClientCard);

    PO.PrintStringWordWrap(" ");
    PO.PrintCenterString("Èíôîðìàöèÿ ïî áîíóñàì:"," ");

    for (RO.Disc.Index = 1;                                             //Ïåðåáèðàåì ñ÷åò÷èêè
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
    PO.PrintStringWordWrap("Ñïèñàíî:         "+UsedBonus.toString());
    PO.PrintStringWordWrap("Íà÷èñëåíî:       "+sNewBonus);
    PO.PrintStringWordWrap("Òåêóùèé îñòàòîê: "+(maxDisc-UsedBonus+NewBonus).toString());
}