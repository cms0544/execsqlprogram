
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_Octopus_UpdateTrasferCard4Soyal') and xtype='P')  DROP PROCEDURE [dbo].[SP_Octopus_UpdateTrasferCard4Soyal]

GO
/****** Object:  StoredProcedure [dbo].[SP_Octopus_UpdateTrasferCard4Soyal]    Script Date: 28/4/2021 14:33:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
 
CREATE PROCEDURE [dbo].[SP_Octopus_UpdateTrasferCard4Soyal]--[dbo].[SP_Octopus_UpdateTrasferCard4Soyal] 4,'0038353483','0024005225','2021-01-07 18:44:00'
@UserAddress int,--用戶的卡機位置,
@OldCardNO nvarchar(32),
@NewCardNO nvarchar(32),
@EventTime datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Declare @UserID int,@UserCode nvarchar(max),@DateStart datetime,@DateEnd datetime,@ID int,@count int
	set @UserID=0
	set @UserCode=''
	set @DateStart=convert(nvarchar(10),getdate(),120)
	Set @DateEnd=DATEADD(day,-1,@DateStart)
	set @ID=0
	set @count=0

	select @UserID=col_UserID,@UserCode=col_UserCode from BT_col_UserInfoForReader where col_CardID=@OldCardNO and col_UserAddress=@UserAddress AND col_Status=1 AND (@EventTime between col_DateStart and col_DateEnd)
	if @UserID=0
		begin
			select @count=count(1) from BT_col_UserInfoForReader where col_CardID=@OldCardNO and col_UserAddress=@UserAddress AND col_Status=1
			if @count=1
				begin
					select @UserID=col_UserID,@UserCode=col_UserCode from BT_col_UserInfoForReader where col_CardID=@OldCardNO and col_UserAddress=@UserAddress AND col_Status=1
				end
			else
				begin
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode from BT_col_UserInfoForReader where col_CardID=@OldCardNO and col_UserAddress=@UserAddress AND col_Status=1 AND col_DateStart<@EventTime order by col_DateEnd desc
				end
		end

	if @UserID=0
		begin
			return
		end

	update BT_col_CardManagement set col_DateEnd=@DateEnd,col_State=0 where col_CardID=@OldCardNO and col_UserID=@UserID
	update BT_col_UserInfoForReader set col_DateEnd=@DateEnd,col_PlanTemplateID=2,col_Status=0,col_IsUploadToReader=99,col_UpdateTime=GetDate() where col_UserCode=@UserCode and col_CardID=@OldCardNO
	Exec DeleteUserReaderAccessByCardNo @UserCode,@OldCardNO

	Set @DateEnd=DATEADD(year,10,@DateStart)
	insert into BT_col_CardManagement(col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_State,col_UserID,col_FCCellID,col_CardName,col_Remark,col_CreateTime,col_UserType,col_OwnerID,kmbm,col_Leave_Reason,col_card_status,col_card_fee)
	select @NewCardNO,col_CardType,col_MaxSwipeTime,@DateStart,@DateEnd,1,col_UserID,col_FCCellID,col_CardName,col_Remark,GetDate(),col_UserType,col_OwnerID,kmbm,col_Leave_Reason,col_card_status,col_card_fee from BT_col_CardManagement where col_CardID=@OldCardNO and col_UserID=@UserID 
	select @ID=col_ID from BT_col_CardManagement where col_CardID=@NewCardNO and col_UserID=@UserID

	INSERT BT_col_UserInfoForReader(col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime)
	select col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,@NewCardNO,col_CardType,col_MaxSwipeTime,@DateStart,@DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,1,col_SwipeTime,col_IfHadFace,NULL,col_LastInOutTime,col_LastReaderID,col_InOutType,GetDate(),GetDate() from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@OldCardNO

	insert into BT_sys_UserReaderAccess(sys_UserCode,sys_CardNo,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange) select sys_UserCode,@NewCardNO,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange from BT_sys_UserReaderAccess where sys_UserCode=@UserCode and sys_CardNo=@OldCardNO
	Exec SaveUserCardReadeAccessStatus @ID,1
	return


	--Declare @MembersID int,@card_DateStart datetime,@card_DateEnd datetime,@CardManagement_AID bigint
	--SET @MembersID=-1;
	--SET @CardManagement_AID=-1;
	----select top 1  @EmpID=sys_EmployeeID from t_sys_AddressAndEmployeeID where sys_UserAddress=@UserAddress

	--select  @MembersID=ZH_Members.id
	--	   ,@card_DateStart=BT_col_CardManagement.col_DateStart
	--	   ,@card_DateEnd=BT_col_CardManagement.col_DateEnd 
	--	   ,@CardManagement_AID=BT_col_CardManagement.[col_ID]
	--from BT_col_CardManagement  
	--inner join BT_col_UserInfoForReader on BT_col_CardManagement.col_CardID=BT_col_UserInfoForReader.col_CardID 
	--inner join ZH_Members on BT_col_CardManagement.col_UserID = ZH_Members.id
	--where   BT_col_CardManagement.col_CardID=@OldCardNO
	--	AND BT_col_UserInfoForReader.col_UserAddress=@UserAddress 
	--	AND (@EventTime between BT_col_CardManagement.col_DateStart and BT_col_CardManagement.col_DateEnd)


	--IF  @CardManagement_AID>0 AND @MembersID>0
	--	BEGIN
	--	 --   SELECT TOP 1 @card_DateStart=hr_DateStart,@card_DateEnd=hr_DateEnd FROM t_hr_UserCardHistory with(nolock) 
	--		--WHERE [hr_EmployeeID]=@EmpID and hr_CardID=@OldCardNO and (@EventTime between hr_DateStart and hr_DateEnd)

	--		IF @card_DateStart is not null
	--			begin
	--					DECLARE @HasUPDATECount int

	--					UPDATE BT_col_CardManagement    SET col_CardID=@NewCardNO WHERE [col_ID]=@CardManagement_AID and [col_CardID]=@OldCardNO and (@EventTime between col_DateStart and col_DateEnd)
	--					SET @HasUPDATECount=@@ROWCOUNT;
	--					UPDATE BT_col_UserInfoForReader SET col_CardID=@NewCardNO where col_UserID=@MembersID        and [col_CardID]=@OldCardNO and (@EventTime between col_DateStart and col_DateEnd)
	--					IF @HasUPDATECount>0
	--						BEGIN
	--							INSERT INTO [dbo].[t_Octopus_CardTransfer]([NewCardNO],[OldCardNO],[EmployeeID],[CreatedTime]) VALUES(@NewCardNO,@OldCardNO,cast(@MembersID as  varchar),GETDATE());
	--							INSERT INTO [dbo].[BT_col_AutoDownloadUserForReader]
	--									   ([col_UserAddress]
	--									   ,[col_EmployeeNo]
	--									   ,[col_EmployeeID]
	--									   ,[col_EmployeeName]
	--									   ,[col_CardID]
	--									   ,[col_CardType]
	--									   ,[col_MaxSwipeTime]
	--									   ,[col_ReaderDoorID]
	--									   ,[col_ReaderID]
	--									   ,[col_ReaderLOGO]
	--									   ,[col_Status]
	--									   ,[col_DateStart]
	--									   ,[col_DateEnd]
	--									   ,[col_IsQRCodeCard]
	--									   ,[col_DownloadLevel]
	--									   ,[col_CreateTime]
	--									   ,[col_DownloadTime])
	--							SELECT       @UserAddress as col_UserAddress
	--									   ,[hr_EmployeeNo] as col_EmployeeNo
	--									   ,[hr_EmployeeID] as col_EmployeeID
	--									   ,[hr_EngName] as col_EmployeeName
	--									   ,@NewCardNO as col_CardID
	--									   ,1 as col_CardType
	--									   ,0 as col_MaxSwipeTime
	--									   ,0-t_sys_ReaderMachine.id as col_ReaderDoorID
	--									   ,t_sys_ReaderMachine.id as col_ReaderID
	--									   ,t_sys_ReaderMachine.ReaderLOGO as col_ReaderLOGO
	--									   ,1 as col_Status
	--									   ,@card_DateStart as col_DateStart
	--									   ,@card_DateEnd   as col_DateEnd
	--									   ,0 as col_IsQRCodeCard
	--									   ,1 as col_DownloadLevel
	--									   ,getdate() as col_CreateTime
	--									   ,0 as col_DownloadTime
	--							  FROM [dbo].[t_hr_Employee] with(nolock) ,t_sys_ReaderMachine with(nolock) 
	--							  WHERE t_hr_Employee.[hr_EmployeeID]=@EmpID
	--							  AND  t_sys_ReaderMachine.BrandType=2 and t_sys_ReaderMachine.IsCardRegReader=0 AND t_sys_ReaderMachine.MainReaderID=0			 
	--						END
	--			END
	--	END



END

 