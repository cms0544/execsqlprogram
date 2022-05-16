/****** Object:  StoredProcedure [dbo].[SP_SaveOpenDoor_QRCodeByAdmin]    Script Date: 2021/4/8 11:05:34 ******/
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_SaveOpenDoor_QRCodeByAdmin') and xtype='P')  DROP PROCEDURE [dbo].[SP_SaveOpenDoor_QRCodeByAdmin]
GO

/****** Object:  StoredProcedure [dbo].[SP_SaveOpenDoor_QRCodeByAdmin]    Script Date: 2021/4/8 11:05:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_SaveOpenDoor_QRCodeByAdmin]  --[dbo].[SP_SaveOpenDoor_QRCode]'7CA9BD80-116E-4C2F-8449-C24D3ACFD4EA',N'7CA9BD80-116E-4C2F-8449-C24D3ACFD4EA',12345683,N'fFFFFFFFFF',N'2019-01-01',N'2019-01-01',0,1,'123','456'
@DoorGroupIDs varchar(max),
@qrcode_str varchar(Max),
@cardid bigint,
@cardid_x varchar(200),
@begin_time datetime,
@end_time datetime,
@cancel bit,
@created_terminal tinyint,
@remark nvarchar(50),
@visitor nvarchar(50)='',
@visitor_phone nvarchar(50)='',
@visiting_reason_typeid [tinyint]=0,
@zh_owner_id int=-1,
@opertor_id varchar(50)='',--系統管理員ID
@fc_cell_id int=-1,
@created_owner_id varchar(20)='',
@id_card varchar(20)='',
@floor_unitvisited nvarchar(max) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @bt_app_user_uid uniqueidentifier='00000000-0000-0000-0000-000000000000'

	SELECT 
		hd.HostDeviceID,
		hd.[HostName],
		hd.[ly_name],
		BrandID
	INTO #DoorInfo
	from [dbo].[V_HostDevice] hd WITH(nolock)
	WHERE IsCardMachine=0 and isnull(hd.[HasQRCode],0)=1
		AND exists(
			select * from tb_DoorGroup_SettingUserID DG_Settings with(nolock) 
			WHERE isnull(IsDelete,0)=0 AND [DoorID] IN(select id FROM [dbo].[SplitByComma_IntResult](@DoorGroupIDs))
			AND hd.HostDeviceID=DG_Settings.AccessControlID
		)

	if not exists(select * from #DoorInfo)
		begin
				select HostDeviceID as door_id,[HostName] as door_name,[ly_name] from #DoorInfo
				return -1
		end

	DECLARE @qrcode_id bigint

    INSERT INTO [dbo].[BT_OPENDOOR_QRCODE]
    (
	  bt_app_user_uid,qrcode_str,cardid,cardid_x,begin_time,end_time,cancel,created_terminal,remark,visitor,[visitor_phone],[visiting_reason_typeid],opertor_id,DoorGroupIDs,fc_cell_id,created_owner_id,id_card,floor_unitvisited
    )
      VALUES
    (
	  @bt_app_user_uid,@qrcode_str,@cardid,@cardid_x,@begin_time,@end_time,@cancel,@created_terminal,@remark,@visitor,@visitor_phone,@visiting_reason_typeid,@opertor_id,@DoorGroupIDs,@fc_cell_id,@created_owner_id,@id_card,@floor_unitvisited
    )

    SELECT @qrcode_id=SCOPE_IDENTITY()


	INSERT INTO [dbo].[BT_OpenDoor_QRCode_OwnerRelation]
           ([qrcode_id]
           ,[zh_owner_id])
		values(@qrcode_id,@zh_owner_id)

	INSERT INTO [dbo].[BT_OpenDoor_QRCode_Door]
			   ([qrcode_id]
			   ,[HostDeviceID])
		select   @qrcode_id as qrcode_id
				,HD.HostDeviceID FROM #DoorInfo HD

    declare @col_UserCode nvarchar(20)
	if(ISNULL(@visitor,'')='')
		begin
			set @col_UserCode='QRCode Visitor'
		end
	else
		begin
			set @col_UserCode=@visitor
		end
	
	Declare @Enabled as int,@PlanTemplateID int,@Status int--samlau 20210308
	set @Enabled=1--samlau 20210308
	set @Status=1--samlau 20210308
	set @PlanTemplateID=255
	if @cancel='true'--samlau 20210308
		begin
			set @Enabled=0
			set @Status=99
			set @PlanTemplateID=2
		end
	else if @end_time<GETDATE()
		begin
			set @Enabled=0
			set @Status=99
			set @PlanTemplateID=2
		end

	Declare @count int,@CardType as int,@MaxSwipeTime int--samlau 20210310
	set @count=0
	set @CardType=11--QRCODE
	set @MaxSwipeTime=0
	Delete From BT_col_UserCardRecord where col_UserCode=@col_UserCode and col_CardNo=@CardID 
	insert into BT_col_UserCardRecord select @col_UserCode,@CardID,@CardType,@MaxSwipeTime,@begin_time,@end_time,GetDate() 

	select @count=1 from BT_col_CardManagement where col_CardID=@CardID
	if @count=0
		begin
			insert into BT_col_CardManagement(col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_State,col_UserID,col_FCCellID,col_CardName,col_Remark,col_CreateTime,col_UserType,col_OwnerID,col_Leave_Reason)
			select @CardID,@CardType,@MaxSwipeTime,@begin_time,@end_time,@Enabled,@qrcode_id,'0',@col_UserCode,'',GetDate(),1,@zh_owner_id,''
		end
	else
		begin
			update BT_col_CardManagement set col_CardType=@CardType,col_DateStart=@begin_time,col_DateEnd=@end_time,col_State=@Enabled,col_UserID=@qrcode_id,col_CardName=@col_UserCode where col_CardID=@CardID
		end

	set @count=0
	select @count=1 from BT_col_UserInfoForReader where col_CardID=@CardID
	if @count=1
		begin
			Insert into BT_col_UserInfoForReaderBackup(col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime,col_BackupTime)
			select col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime,GetDate() from BT_col_UserInfoForReader where col_CardID=@CardID 
			Delete from BT_col_UserInfoForReader where col_CardID=@CardID
		end

	INSERT BT_col_UserInfoForReader(col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime)
	Select @qrcode_id,@col_UserCode,1,0,@col_UserCode,@zh_owner_id,'0',@CardID,@CardType,@MaxSwipeTime,@begin_time,@end_time,@PlanTemplateID,'-1',@Enabled,@Status,0,0,NULL,NULL,0,-1,GetDate(),GetDate() --from ZH_Owner where id=@UserID--sync_created_time,Convert(nvarchar(10),dateadd(year,20,sync_created_time),120)
	
	set @count=0
	select @count=1 from BT_sys_UserReaderAccess where sys_CardNo=@CardID
	if @count=1
		begin
			Delete from BT_sys_UserReaderAccess where sys_CardNo=@CardID
		end
	insert into BT_sys_UserReaderAccess select @col_UserCode,@CardID,HostDeviceID,@PlanTemplateID,0,0 from #DoorInfo

	INSERT INTO [dbo].[BT_col_AutoDownloadUserForReader]
			   (col_UserID
			   ,[col_UserCode]
			   ,[col_UserName]
			   ,col_UserType
			   ,col_UserAddress
			   ,col_FCCellID
			   ,[col_CardNo]
			   ,col_CardType
			   ,[col_DateStart]
			   ,[col_DateEnd]
			   ,col_MaxSwipeTime
			   ,col_PlanTemplateID
			   ,col_Enabled
			   ,[col_DeviceID]
			   ,[col_Status]
			   ,[col_IsQRCodeCard]
			   ,col_DownloadLevel
			   ,col_RunCount
			   ,col_UpdateTime
			   ,[col_CreateTime])

	   SELECT  @qrcode_id
			   ,@col_UserCode as col_UserCode
			   ,@col_UserCode as col_UserName
			   ,1
			   ,0
			   ,'QRCODE'
			   ,cast(@cardid as varchar) as [col_CardNo]
			   ,@CardType
			   ,@begin_time as [col_DateStart]
			   ,@end_time as [col_DateEnd]
			   ,0
			   ,@PlanTemplateID
			   ,@Enabled
			   ,HD.HostDeviceID as [col_DeviceID]
			   ,@Status as [col_Status]
			   ,1 as [col_IsQRCodeCard]
			   ,1
			   ,0
			   ,case when @begin_time>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,@begin_time)>0 AND datepart(MINUTE,@begin_time)>0 then @begin_time else '2008-01-01' end
			   ,getdate() as [col_CreateTime]
	   FROM #DoorInfo HD--samlau 20210308

	select HostDeviceID as door_id,[HostName] as door_name,[ly_name] from #DoorInfo

	select @qrcode_id as qrcode_id;

	return 1
END



GO


