

#1 Query showing current positions and prices

select   
    t.symbolID,   
    sum(t.qty) "Current Quantity",   
    sum(t.qty*st.Multiplier*p.Price*fx.FxRate) "Current Market Value",  
    t.price "Most Recent Price",  
    p.PxAsOfDate "Pricing Date"  
from trades t  

inner join symbols s  
on s.SymbolID = t.symbolID  

inner join symboltypes st  
on st.SymbolType = s.symboltype  
  
left join pricinghistory p  
on p.SymbolID = t.symbolID  
#subquery to pull the most recent price for the symbol  
and p.Pxasofdate = (  
	select sub.Pxasofdate   
    from pricinghistory sub   
    where sub.symbolid = p.symbolid   
    order by sub.Pxasofdate desc limit 1)  
  
inner join fxhistory fx  
on fx.CurrencyCode = s.currencycode  
#subquery to pull the newest fx rate for the symbol  
and fx.Fxasofdate = (  
	select sub.Fxasofdate   
    from fxhistory sub   
    where sub.currencycode = fx.currencycode   
    order by sub.Fxasofdate desc limit 1)  
  
group by t.symbolID, p.price, p.pxasofdate  
having sum(t.qty <> 0)  
order by sum(t.qty*st.Multiplier*p.Price*fx.FxRate) desc; 
#2 Realized P&L for sold positions

Select 
	sells.symbolID, 
    sells.qty, 
    sells.price*sells.fxrate "SellPx USD", 
    buys.BuyPx,
    ((sells.Price*sells.fxrate) - (buys.BuyPx)) 
    *sells.qty*st.Multiplier "Realized P&L"
from trades sells

inner join (
	select SymbolID, avg(Price*FxRate) "BuyPx"
    from trades
    where TTypeCode = 'BUY'
    group by SymbolID
			) buys
on buys.symbolID = sells.symbolID

inner join symbols s
on sells.symbolid = s.symbolid

inner join symboltypes st
on st.SymbolType = s.SymbolType

where sells.ttypecode = 'SEL'; 

#3 Show the position that have a maturity date in this year 
SELECT s.SymbolID, s.SymbolType,s.SymbolName,
s.CurrencyCode,b.MaturityDate as BondMT, c.MaturityDate as CallMT
FROM symbols s
LEFT JOIN bonds b ON  s.SymbolID=b.SymbolID
LEFT JOIN calls c ON s.SymbolID=c.SymbolID
WHERE YEAR(b.MaturityDate)=2022 OR YEAR(c.MaturityDate)=2022;

#4 Average stock purchase price 
Select sum(trades.proceeds)/sum(trades.Qty) as Average_Stock_Purchase_Price 
from trades as Trades,Symbols as Symbols 
#inner join Symbols 
where Symbols.symbolID=Trades.symbolID 
and Trades.TTypeCode = "BUY" and Symbols.symboltype="STO";

#5 Select rows where company suffered a loss in the transaction buy
select  
	t.TradeID,t.SymbolID, t.TradeDate "Purchase Date",  
    t.qty "Qty",  t.price "Buy Px",  p.Price "Curr PX",  
    p.price - t.price "Decline in Px" 
from trades t 
  
inner join pricinghistory p 
on p.SymbolID = t.SymbolID 
and p.PXAsOfDate = (select sub.PXAsOfDate from pricinghistory sub 
where sub.SymbolID = p.symbolID 
order by sub.pxasofdate desc limit 1)

where t.TTypeCode = 'BUY' 
and t.price > p.price;
#6 Trade proceeds on different days, segregated based on Transaction type 
select   
	t.TradeDate, 
    t.TTypeCode, 
    sum((tt.ProceedsMultiplier*t.qty*t.price
    *st.Multiplier*t.FxRate) - t.Fees) "Proceeds"  
from trades t  
left join symbols s  on s.SymbolID = t.symbolID  
left join symboltypes st on st.SymbolType = s.symboltype  
left join transactiontypes tt on tt.TTypeCode = t.TTypeCode  
group by t.TradeDate, t.TTypeCode 
order by t.tradedate;

#7 Query showing Ttype’s avg price, max price and min price for each transaction type
SELECT TTypecode, SymbolID, avg(price),
max(price),min(price) FROM trades
GROUP BY Ttypecode, SymbolID
ORDER BY SymbolID, TTypeCode;

#8 Query for displaying fields which have stock sale price above average sale price 
Select s.SymbolName, T.Price
from Symbols S, trades t
where T.symbolID=S.SymbolID and S.symboltype="STO" and T.ttypecode = "Sel"
and t.price>(select avg(sub.price) from trades sub 
WHERE sub.symbolid=s.symbolid and sub.ttypecode = "Buy"); 

#9 Show highest three proceeds for each symbol by Ttype
SELECT
t.ttypecode,s.symbolname,
(tt.Proceedsmultiplier*t.qty*t.price*st.multiplier*t.fxrate)-t.fees AS Proceeds 
from transactiontypes tt
left join trades t on t.TTypeCode=tt.TTypeCode
Left join Symbols s ON t.SymbolID=s.SymbolID
left join Symboltypes st ON st.symboltype=s.symboltype
ORDER BY Proceeds DESC LIMIT 3;

#10 How many times have we traded with each counterparty? 
SELECT c.CounterpartyName,count(t.tradeID) AS 'No of transactions'
FROM trades t
INNER JOIN Counterparties c
ON c.Counterpartycode=t.Counterpartycode
GROUP BY c.Counterpartyname;

