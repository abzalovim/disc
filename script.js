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