drop table CustomerInformation
drop table CustomerAccountInformation
drop table BankCards
drop table CreditCards

create database BankDb
create table CustomerInformation
 (
 Id int IDENTITY (1,1) Primary Key Not null,
 Identification varchar(11) Not null,
 NameSurname varchar(100) Not null,
 PlaceOfBirth varchar(30) Not null,
 DateOfBirth date Not null,
 RiskLimit int Not null
 )
 create table CustomerAccountInformation
 (
 CustomerId int Foreign key references CustomerInformation(Id) Not null,
 AccountId int IDENTITY (9999,1)  Primary Key Not null,
 AccountName varchar(50) Not null,
 AccountCode varchar(34) Not null,
 OpeningDate date Not null,
 ClosingDate date
 )
 create table CreditCards
 (
 CustomerId  int Foreign key references CustomerInformation(Id) Not null,
 CCardId int IDENTITY (99999,1)  Primary Key Not null,
 CreditCard nvarchar(34),
 Limit money not null,
 CardStatus tinyint,
 TransferDate date,
 OpeningDate date Not null,
 ClosingDate date,
 Comment varchar (100)
 )
 create table BankCards
 (
 CustomerId  int Foreign key references CustomerInformation(Id) Not null,
 BCardId int IDENTITY (99999,1)  Primary Key Not null,
 BankCard nvarchar (34),
 Limit money not null,
 CardStatus tinyint,
 TransferDate date,
 OpeningDate date Not null,
 ClosingDate date,
 Comment varchar (100)
 )
/* create table CountTable
 (
 CustomerId  int Foreign key references CustomerInformation(Id) Not null,
 CountId int IDENTITY (999999,1)  Primary Key Not null,
 Create_at date,
 Delete_at date,
 UpdateCount tinyint,
 DeleteCount tinyint
 )*/

 alter table CustomerAccountInformation
 add Constraint DEF_CONSTRAINT_OPENINGDATE
 DEFAULT GETDATE () FOR OpeningDate;

 --Drop table Cards
-- Alter table CustomerInformation add comment varchar(100)
--Alter table Cards add Limit money not null
delete from CustomerInformation
delete from CustomerAccountInformation
delete from CreditCards
delete from CreditCards
delete from BankCards

/*create proc sp_UserSimulator
(

)*/
  --drop trigger RiskTrigger

--drop proc sp_MoneyTransfer

CREATE PROC sp_MoneyTransferCreditC (
    @Comment		varchar(100),
    @Purchaser      nvarchar(34),
    @Sender         nvarchar(34),
    @Amount         MONEY out,
    @retVal         INT OUT
)
AS
BEGIN
    DECLARE @inControl MONEY
    SELECT @inControl = Limit FROM CreditCards where @Sender = CreditCard
    IF @inControl >= @Amount
    BEGIN
        BEGIN TRANSACTION
			SELECT CustomerId, /*Count(TransferDate),*/ isNull (TransferDate, GETDATE()) from CreditCards /*group by CCardId*/ order by TransferDate DESC
                    UPDATE CreditCards SET Limit = Limit - @Amount WHERE CreditCard = @Sender
		IF @@ERROR <> 0
        --ROLLBACK
			SELECT CustomerId, isNull (TransferDate, GETDATE()) from CreditCards order by TransferDate DESC
                   UPDATE CreditCards SET Limit = Limit + @Amount WHERE CreditCard = @Purchaser
	   IF @@ERROR <> 0
			BEGIN
				ROLLBACK
			END
        COMMIT
		SET @retVal = 200;
		RETURN @retVal
    END
    ELSE
    BEGIN
        SET @retVal = -1;
        RETURN @retVal;
    END
END;

--exec sp_MoneyTransfer

CREATE PROC sp_MoneyTransferBankC(
    @Comment		varchar(100),
    @Purchaser      nvarchar(34),
    @Sender         nvarchar(34),
    @Amount         MONEY out,
    @retVal         INT OUT
)
AS
BEGIN
    DECLARE @Control MONEY
    SELECT @Control = Limit FROM BankCards where @Sender = BankCard
    IF @Control >= @Amount
    BEGIN
        BEGIN TRANSACTION
            UPDATE BankCards SET Limit = Limit - @Amount WHERE BankCard = @Sender
			SELECT CustomerId, isNull (TransferDate, GETDATE()) from CreditCards order by TransferDate DESC
        IF @@ERROR <> 0
        --ROLLBACK
            UPDATE BankCards SET Limit = Limit - @Amount WHERE BankCard = @Sender
			SELECT CustomerId, isNull (TransferDate, GETDATE()) from CreditCards order by TransferDate DESC
        IF @@ERROR <> 0
			BEGIN
				ROLLBACK
			END
        COMMIT
		SET @retVal = 200;
		RETURN @retVal
    END
    ELSE
    BEGIN
        SET @retVal = -1;
        RETURN @retVal;
    END
END;

Create proc sp_Read
as
begin
select *from CustomerInformation
select *from CustomerAccountInformation
select *from BankCards
select *from CreditCards
end


Create proc sp_Create
as
begin
select Id, Count(Id), isNull (CreateDate, GETDATE()) from CustomerInformation group by Id order by Count(Id) DESC
select CustomerId, Count(CustomerId), isNull (OpeningDate, GETDATE()) from CustomerAccountInformation group by CustomerId order by Count(CustomerId) DESC
select CustomerId, Count(CustomerId), isNull (OpeningDate, GETDATE()) from BankCards group by CustomerId order by Count(CustomerId) DESC
select CustomerId, Count(CustomerId), isNull (OpeningDate, GETDATE()) from CreditCards group by CustomerId order by Count(CustomerId) DESC
end

Create proc sp_Delete
(
@DeleteId int
)
as
begin
SELECT CustomerId, Count(ClosingDate), isNull (ClosingDate, GETDATE()) from CustomerAccountInformation group by CustomerId order by count(ClosingDate) DESC
delete from CustomerAccountInformation where @DeleteId=AccountId
SELECT CustomerId, Count(ClosingDate), isNull (ClosingDate, GETDATE()) from CustomerAccountInformation group by CustomerId order by count(ClosingDate) DESC
delete from BankCards where @DeleteId=BCardId
SELECT CustomerId, Count(ClosingDate), isNull (ClosingDate, GETDATE()) from CustomerAccountInformation group by CustomerId order by count(ClosingDate) DESC
delete from CreditCards where @DeleteId=CCardId
end

Create proc sp_Update
(
@UpdateId			int,
@Limit				money,
@CardStatus			tinyint,
@TransferDate		date,
@Comment			nvarchar(100)
)
as
begin
select CustomerId, Count(CustomerId), isNull (OpeningDate, GETDATE()) from BankCards group by CustomerId order by Count(CustomerId) DESC
update BankCards set Limit=@Limit, CardStatus=@CardStatus, TransferDate=@TransferDate, Comment=@Comment where  BCardId=@UpdateId
select CustomerId, Count(CustomerId), isNull (OpeningDate, GETDATE()) from CreditCards group by CustomerId order by Count(CustomerId) DESC
update BankCards set Limit=@Limit, CardStatus=@CardStatus, TransferDate=@TransferDate, Comment=@Comment where  BCardId=@UpdateId
end
 

use BankDb
go
Create Trigger CreditCardsAdd on CreditCards
after insert
as
begin
declare @CreditCardCount int
--Select CreditCard from Cards Group by CreditCard Having Count(CreditCard)<2
--select * from Cards where DATALENGTH CreditCard and DATALENGTH BankCard
--select @CreditC = Count (CreditCard) from Cards
select @CreditCardCount = Count(CreditCard) from CreditCards
begin
if( @CreditCardCount <2)
begin
select 'kart oluþturuldu'
end
else
begin
--select * from Cards where DATALENGTH ( CreditCard ) >= 2 and DATALENGTH ( BankCard ) >=1
select 'maksimum oluþturulabilir kart sayýsý dolmuþtur'
end
end
end


go
Create Trigger BankCardsAdd on BankCards
after insert
as
begin
declare @BankCardCount int
select @BankCardCount = Count(BankCard) from BankCards
begin
if( @BankCardCount <1)
begin
select 'kart oluþturuldu'
end
else begin
select 'mevcut kartýnýz bulunmakta'
end
end
end

go
Create Trigger AccountCardCheck on CustomerAccountInformation
after insert
as
begin
declare @Status tinyint
declare @AccountC int
select @AccountC = Count(AccountCode) from CustomerAccountInformation
begin
if( @AccountC <1)
begin
select 'hesap kartýnýz oluþturulmuþtur.'
end
else if( @AccountC =1)
begin
--insert into CustomerAccountInformation(CardStatus)
--values(0)
select * from CustomerAccountInformation where CardStatus = 1
update CustomerAccountInformation set CardStatus =0
select 'mevcut kartýnýz pasif hale gelip yeni kartýnýz oluþturulmuþtur.'
end
end
end



go
Create Trigger RiskTriggerAdd on CustomerInformation
after insert
as
begin 
select Identification from CustomerInformation where Identification = [Identification]
select 'Kullanýcý mevcut'
end
begin
select 'yeni kullanýcý eklendi.'
end

go
Create Trigger RiskTriggerDelete on CustomerInformation
after delete
as
begin
select 'kullanýcý silindi.'
end

go
Create Trigger RiskTriggerUpdate on CustomerInformation
after update
as
begin
select 'kullanýcý güncellendi.'
end

/*
go
Create Trigger UdCount on CustomerInformation --Update Ýþlemlerini tutma
after update
as
begin
update CountTable set UpdateCount=UpdateCount+1
end

go
Create Trigger DCount on CustomerInformation --Delete Ýþlemlerini tutma
after update
as
begin
update CountTable set DeleteCount=DeleteCount+1
end*/


--truncate table CustomerInformation

 insert into CustomerInformation (Identification, NameSurname, PlaceOfBirth, DateOfBirth, RiskLimit)
 values ('11111111111', 'Gün Gören', 'Eskiþehir', '01.02.1993','10000')

 select Id, isNull (RiskLimit, '10.000') from CustomerInformation
 select AccountId, isNull (OpeningDate, GETDATE()) from CustomerAccountInformation
 
 select* from CustomerAccountInformation
 insert into CustomerAccountInformation (CustomerId ,AccountName, AccountCode, CardStatus)
 values ('1','Vadesiz Anadolu', 'TR 01 1234 1546 4578 8999', 1)


 use BankDb
 go
 declare  @Id int, @NameS varchar(100), @SSN varchar (11), @PlaceB varchar(30), @DateB date, @RiskL money
 declare @AccountN varchar(50), @AccountC varchar (34), @OpeningD date, @AcountId int
 declare @CreditC nvarchar (34), @BankC nvarchar (34), @Limit money,  @Comment varchar, @CardId int, @Status tinyint
 select @SSN=Identification, @NameS=NameSurname, @PlaceB=PlaceOfBirth, @DateB=DateOfBirth, @RiskL=RiskLimit, @Id=Id from CustomerInformation
 select @AccountN=AccountName, @AccountC=AccountCode, @OpeningD=OpeningDate, @AcountId=AccountId, @Id=CustomerId , @Status=CardStatus from CustomerAccountInformation
 select @CreditC=CreditCard, @Limit=Limit, @Comment=Comment, @CardId=CCardId, @Id=CustomerId from CreditCards
 select @BankC=BankCard, @Limit=Limit, @Comment=Comment, @CardId=BCardId, @Id=CustomerId from BankCards
 --SQL'de Mükerrer Kayýt Engelleme
 Select NameSurname from CustomerInformation Group by NameSurname Having Count(NameSurname)=1
 begin
-- "TR 01 1234 1546 4578 8999" "Vadesiz Anadolu" hesabý için 1234 9876 5464 5489 numaralý hesap kartýný oluþturunuz.
  if @AccountC = 'TR 01 1234 1546 4578 8999' and @AccountN = 'Vadesiz Anadolu'
  begin
  --if @BankC is not null
  --begin
  insert into BankCards (CustomerId,BankCard,Limit, Comment,OpeningDate)
  values ('1','1234 9876 5464 5489','10000','"Vadesiz Anadolu" hesabý için 1234 9876 5464 5489 numaralý hesap kartýnýz oluþturulmuþtur.', GETDATE())
   SELECT CustomerId, isNull (OpeningDate, GETDATE()) from CreditCards
  end
  end
		--"Gün Gören" müþterisi için 1234 8796 5464 5488 beþ bin TL ve 1234 8796 5464 5487 üç bin limitli kredi kartlarýný tanýmlayanýz.
  if @NameS = 'Gün Gören'
  begin
  insert into CreditCards (CustomerId,CreditCard,Limit,OpeningDate)
  values ('1','1234 9876 5464 5488','5000',GETDATE())
  SELECT CustomerId, isNull (OpeningDate, GETDATE()) from CreditCards

  insert into CreditCards (CustomerId,CreditCard,Limit, OpeningDate)
  values ('1','1234 9876 5464 5487','3000',GETDATE())
  SELECT CustomerId, isNull (OpeningDate, GETDATE()) from CreditCards
  end
 end
  

declare @rVal int;
EXEC sp_MoneyTransferCreditC 'Yaz Tatili','Null', '1234 9876 5464 5488','700.25', @rVal out;
select @rVal; --88 ile biten kredi kartýndan "Yaz Tatili" açýklamalý 750.25 TL lik harcama yapýnýz.

EXEC sp_MoneyTransferCreditC 'Pandemi','Null','1234 9876 5464 5487', '15.50', @rVal out;
select @rVal --87 ile biten kredi kartýndan "Pandemi" açýklamalý 15.50 TL lik harcama yapýnýz.

EXEC sp_MoneyTransferBankC 'Para Yatýrýldý','1234 9876 5464 5489', '1234 9876 5464 5489','1500', @rVal out;
select @rVal --89 ile biten hesap kartý ile 1500 TL lik para yapýnýz.

EXEC sp_MoneyTransferBankC 'Para Çekildi','Null','1234 9876 5464 5489', '350', @rVal out;
select @rVal --89 ile biten hesap kartý ile  350 TL lik para çekiniz.

EXEC sp_MoneyTransferBankC 'Para Çekildi', 'Null','1234 9876 5464 5490', '125', @rVal out;
select @rVal --90 ile biten hesap kartý ile 125 TL para çekiniz.

 --"TR 01 1234 1546 4578 8999" "Vadesiz Anadolu" hesabý için 1234 9876 5464 5490 numaralý hesap kartýný oluþturunuz.
Select NameSurname from CustomerInformation Group by NameSurname Having Count(NameSurname)=1
begin
 if @AccountC = 'TR 01 1234 1546 4578 8999' and @AccountN = 'Vadesiz Anadolu'
  begin
  insert into BankCards(CustomerId,BankCard, Limit, Comment)
  values('1','1234 9876 5464 5490', '10000','"Vadesiz Anadolu" hesabý için 1234 9876 5464 5490 numaralý hesap kartýnýz oluþturulmuþtur.')
 end
end

 use BankDb
 go
 select * from CustomerInformation
 select * from CustomerAccountInformation
 select * from CreditCards
 select * from BankCards
 select*from CustomerInformation Ci inner join CustomerAccountInformation Cai on Ci.Id = Cai.CustomerId
 select*from CustomerInformation Ci inner join CreditCards Cc on Ci.Id = Cc.CustomerId
 select*from CustomerInformation Ci inner join BankCards Bc on Ci.Id = Bc.CustomerId

--datetime CreatAt (get,set) = datetime.now

