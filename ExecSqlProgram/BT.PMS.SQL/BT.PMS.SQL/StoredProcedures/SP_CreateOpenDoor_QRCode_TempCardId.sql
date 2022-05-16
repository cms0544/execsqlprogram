IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_CreateOpenDoor_QRCode_TempCardId') and xtype='P')  DROP PROCEDURE [dbo].[SP_CreateOpenDoor_QRCode_TempCardId]
GO

CREATE PROCEDURE [dbo].[SP_CreateOpenDoor_QRCode_TempCardId]--SP_CreateOpenDoor_QRCode_TempCardId '900'
@preFixNum varchar(20)='300'
AS
BEGIN

SET NOCOUNT ON;


	DECLARE @TransactionDateIndex int;
	declare @RestLen int,@new_cardid varchar(20)
	if(Isnumeric(@preFixNum)=1) 
		begin
			SET @preFixNum= cast(@preFixNum as decimal(18,0));
		end
	else
		begin
			SET @preFixNum='300';
		end	
	SET @RestLen=10-len(@preFixNum)
SET XACT_ABORT ON;

begin TRANSACTION

	SELECT @TransactionDateIndex=ISNULL(max([TempIndex]),0)+1 FROM [dbo].[BT_OpenDoor_QRCode_TempCardId] with(TABLOCKX) 

	INSERT INTO [dbo].[BT_OpenDoor_QRCode_TempCardId]
			   ([TempIndex],[CreatedTime])
		 VALUES
			   (@TransactionDateIndex,GETDATE())

	SET @new_cardid=cast(@preFixNum+RIGHT('0000000000'+CAST(@TransactionDateIndex as varchar),@RestLen) as bigint)   
	print '1='+@new_cardid
	IF(exists(select * from BT_col_CardManagement WHERE col_CardID=@new_cardid))--已經存在相同再生成一次
		begin
				SELECT @TransactionDateIndex+=1;
				INSERT INTO [dbo].[BT_OpenDoor_QRCode_TempCardId]
						   ([TempIndex],[CreatedTime])
					 VALUES
						   (@TransactionDateIndex,GETDATE())
				SET @new_cardid=cast(@preFixNum+RIGHT('0000000000'+CAST(@TransactionDateIndex as varchar),@RestLen) as bigint) 
				print '2='+@new_cardid
		end

	SELECT @new_cardid as TempIndex
commit TRANSACTION

END

 