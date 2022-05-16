--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SaveUserInfoForReader') and xtype='P')  DROP PROCEDURE [dbo].[SaveUserInfoForReader]
GO
/****** Object:  StoredProcedure [dbo].[SaveUserInfoForReader]    Script Date: 10/12/2018 18:23:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2019-03-14>
-- Description:	<保存业主信息时调用,只有一个卡号的情况下才调用此存储过程> 
--Exec SaveUserInfoForReader 1,'4276095628'
-- =============================================
CREATE PROCEDURE [dbo].[SaveUserInfoForReader] 
(
	@UserCode nvarchar(20),
	@CardID nvarchar(125),
	@UserType int=0,--0：業主；1：訪客
	@UserCodeType int=-1-- -1;0: UserCode是業主編碼；1：UserCode是成員編碼
)
AS
BEGIN
	SET NOCOUNT ON; 
--BEGIN TRANSACTION
	 
	Declare @Count int,@UserID int,@OwnerID int,@UserAddress int,@DateStart datetime,@DateEnd datetime,@UserName nvarchar(400),@yzzt nvarchar(20),@OldCardNo nvarchar(125),@UserEnabled int,@Enabled int,@FCCellID int,@FCCellCode nvarchar(20),@IfHadFace int
	set @Count=0 
	set @UserID=0 
	set @OwnerID=0 
	set @UserAddress=0
	set @Enabled=0
	set @UserName=''
	set @yzzt=''

	if REPLACE(@UserCode,'0','')<>''
		begin
			if @UserCodeType<1
				begin
					Select @Count=1,@UserID=ID,@OwnerID=ID,@UserName=name,@yzzt=yzzt from ZH_Owner where Code=@UserCode
				end
			else
				begin
					Select @Count=1,@UserCode=a.Code,@OwnerID=a.OwnerID,@UserName=isnull(a.alias,a.name),@UserEnabled=(case when a.deleted=0 then 1 else 0 end),@yzzt=b.yzzt from ZH_Members a left join ZH_Owner b on a.OwnerID=b.ID where a.Code=@UserCode
				end
				
			if @Count=0
				begin
					if @UserCodeType<1--主要是兼容舊的，新的不可能出現這種情況了
						begin
							if @UserID=0
								begin
									Select @UserID=col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode
								end

							Exec DeleteUserInfoForReaderByOwnerID @UserID
							goto TheEnd
						end

					Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode
					Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_UserAddress>0 and col_CardType>=12)
					--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime) select col_UserCode,col_CardID,sys_ReaderID,99,col_DateStart,col_DateEnd,0,GetDate() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_IsUploadToReader<>99
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and ISNULL(a.col_CardID,'0')<>'0' and a.col_CardType<11 and a.col_IsUploadToReader<>99

					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and ISNULL(a.col_CardID,'0')<>'0' and col_UserAddress>0 and a.col_CardType>12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15)

					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and ISNULL(a.col_CardID,'0')<>'0' and col_UserAddress>0 and a.col_CardType=12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true')

					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and ISNULL(a.col_CardID,'0')<>'0' and a.col_CardType=11 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')

					--insert into BT_sys_FreeCard (sys_CardNO,sys_EventTime,sys_DeviceID,sys_CreateTime) select col_CardID,GetDate(),0,GetDate() from BT_col_UserInfoForReader where col_UserCode=@UserCode
			
					Delete From BT_col_TempUserFace where col_UserCode=@UserCode 
					Delete From BT_col_UserFaceData where col_UserCode=@UserCode 
					Delete from BT_sys_UserReaderAccess where sys_UserCode=@UserCode
					Delete from BT_sys_UserReaderAccessOld where sys_UserCode=@UserCode
					Delete from BT_sys_UserReaderAccess_JTCY where sys_memberid in (select col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode)
					Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_memberid in (select col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode)
					Delete from BT_col_UserOldCard where col_UserCode=@UserCode
					Delete from BT_col_UserCardRecord where col_UserCode=@UserCode
					Delete from BT_col_CardManagement where col_UserID in (select col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode)
					--update BT_col_CardManagement set col_UserID=0,col_FCCellID=0,col_OwnerID=0 where col_UserID in (select col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode)
					update BT_col_UserIDAndAddress set col_IsDel=1 where col_UserID in (select col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode)
					--update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_UserID in (select col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode)
					--update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserCode=@UserCode) and col_UserAddress not in (select col_UserAddress from BT_col_UserInfoForReader where col_UserCode<>@UserCode)
					Delete from BT_col_UserInfoForReader where col_UserCode=@UserCode
					goto TheEnd
				end
		 
		end

	if @CardID<>'' and @CardID<>''
		begin
			select @Count=1,@UserID=col_UserID,@UserName=col_CardName,@UserEnabled=col_State from BT_col_CardManagement where col_CardID=@CardID
			if @Count=1
				begin
					SET @Count=0
					Select @Count=1,@UserCode=a.Code,@UserEnabled=(case when a.deleted=0 then 1 else 0 end),@yzzt=b.yzzt from ZH_Members a left join ZH_Owner b on a.OwnerID=b.ID where a.ID=@UserID--,@UserName=isnull(a.alias,a.name)
				end
			else
				begin
					Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_CardNo=@CardID
					Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID and col_UserAddress>0 and col_CardType>=12)
					--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime) select col_UserCode,col_CardID,sys_ReaderID,99,col_DateStart,col_DateEnd,0,GetDate() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_IsUploadToReader<>99
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_CardType<11 and a.col_IsUploadToReader<>99
			
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and col_UserAddress>0 and a.col_CardType>12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15)
			
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and col_UserAddress>0 and a.col_CardType=12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true')

					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_CardType=11 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')

					--insert into BT_sys_FreeCard (sys_CardNO,sys_EventTime,sys_DeviceID,sys_CreateTime) select col_CardID,GetDate(),0,GetDate() from BT_col_UserInfoForReader where col_UserCode=@UserCode
					select @UserID=col_UserID from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID
					Delete From BT_col_TempUserFace where col_UserCode=@UserCode and col_CardID=@CardID 
					Delete From BT_col_UserFaceData where col_UserCode=@UserCode and col_CardID=@CardID  
					Delete from BT_sys_UserReaderAccess where sys_UserCode=@UserCode and sys_CardNo=@CardID 
					Delete from BT_sys_UserReaderAccessOld where sys_UserCode=@UserCode and sys_CardNo=@CardID 
					if not exists(select * from BT_col_CardManagement where col_UserID=@UserID and col_CardID<>@CardID)
						begin
							Delete from BT_sys_UserReaderAccess_JTCY where sys_memberid=@UserID
							Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_memberid=@UserID
						end
					Delete from BT_col_UserOldCard where col_UserCode=@UserCode and col_CardNo=@CardID 
					Delete from BT_col_UserCardRecord where col_UserCode=@UserCode and col_CardNo=@CardID 
					--Delete from BT_col_CardManagement where col_UserID=@UserID and col_CardID=@CardID 
					update BT_col_UserIDAndAddress set col_IsDel=1 where col_UserID=@UserID and col_CardID=@CardID 
					--update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_UserID=@UserID and col_CardID=@CardID 
					--update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_UserAddress=(select col_UserAddress from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID) and col_UserAddress not in (select col_UserAddress from BT_col_UserInfoForReader where col_UserCode<>@UserCode and col_CardID<>@CardID)
					Delete from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID
					goto TheEnd
				end
		end


	if @yzzt='正常'-- or @yzzt='1'
		begin
			set @Enabled=1
		end
	else
		begin
			set @Enabled=0
		end
		
	if @CardID=''
		set @CardID='0'

	set @FCCellID=0
	set @FCCellCode='0'
	--select top 1 @FCCellID=cellid,@FCCellCode=cellcode from View_ZHFCLPInfo where OwnerCode=@UserCode order by cellid--cast(cellid as nvarchar(16))
	--select top 1 @FCCellID=cellid,@FCCellCode=cellcode from View_ZHFCLPInfo where OwnerCode=@UserCode and cellid not in (select col_FccellID from BT_col_CardManagement where col_UserID=@UserID) order by cellid

	set @DateStart=Convert(nvarchar(10),Getdate(),120)
	set @DateEnd=dateadd(year,10,@DateStart)
	Declare @Status int,@PlanTemplateID int,@SetorClear int,@ifNeedInsert int,@CardType int,@MaxSwipeTime int 
	set @CardType=0--0:普通卡；11:臨時卡(QRCODE)；12:八達通
	set @MaxSwipeTime=0
	set @ifNeedInsert=0	
	set @Status=0
	set @SetorClear=1
	set @PlanTemplateID=255
	select @CardType=col_CardType,@MaxSwipeTime=col_MaxSwipeTime,@DateStart=col_DateStart,@DateEnd=col_DateEnd,@Enabled=col_State,@UserName=col_CardName,@FCCellID=col_FCCellID from BT_col_CardManagement where col_UserID=@UserID AND col_CardID=@CardID
	select @FCCellCode=code from FC_Cell where cellid=@FCCellID
	if @UserEnabled=0
		begin
			set @Enabled=0
		end
	
	if @Enabled=0
		begin
			set @Status=98
			set @SetorClear=99
			set @PlanTemplateID=2
			set @DateEnd=dateadd(day,-1,@DateStart)
			set @DateStart=@DateEnd
		end
		
	set @IfHadFace=0
	select @IfHadFace=1 from ZH_Members where id=@UserID and REPLACE(ISNULL(zpurl,'no.gif'),'no.gif','')<>'' 
	
	Declare @OldUserAddress as int
	set @OldUserAddress=0
	set @Count=0 	
	if @CardID='0'
		begin
			select @Count=count(1) from BT_col_UserInfoForReader where col_UserCode=@UserCode 
		end
	else
		begin
			select @Count=1,@OldUserAddress=col_UserAddress from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID	  
		end

	if @Count>=1--samlau 20160415
		begin 
			--set @OldCardNo=@CardID
			--set @Count=0
			--select @Count=count(1) from BT_col_UserInfoForReader where col_UserCode=@UserCode
			--if @Count=1
			--	begin
			--		select @OldCardNo=col_CardID from BT_col_UserInfoForReader where col_UserCode=@UserCode  
			--	end

			Declare @IfNotChange as int,@IfPhotoNotChange as int
			set @IfNotChange=0 
			set @IfPhotoNotChange=0 
			if @CardID<>'0'
				begin
					select @IfNotChange=1 from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_UserType=@UserType and col_CardID=@CardID and col_UserName=@UserName and col_PlanTemplateID=@PlanTemplateID and col_CardType=@CardType and col_MaxSwipeTime=@MaxSwipeTime and col_FCCellID=@FCCellCode and col_Status=@Enabled and col_DateStart=@DateStart and col_DateEnd=@DateEnd and col_IfHadFace=@IfHadFace
					select @IfPhotoNotChange=1 from zh_Members where id=@UserID and zpurl=(select col_FaceURL from BT_col_UserFaceData where col_UserCode=@UserCode and col_CardID=@CardID)
					if @Enabled=1 and @IfPhotoNotChange=0 --图片变了
						begin
							if @IfNotChange=1
								begin
									set @SetorClear=4
									set @ifNeedInsert=1
								end
						end

					if @OldUserAddress=0
						begin
							select top 1 @UserAddress=col_UserAddress from BT_col_UserIDAndAddress WITH(nolock) where col_UserID=@UserID and col_CardID=@CardID and col_UserAddress not in (select col_UserAddress from BT_col_UserInfoForReader WITH(nolock))
							if @UserAddress=0
								begin
									select top 1 @UserAddress=col_UserAddress from BT_col_UserIDAndAddress WITH(nolock) where col_UserID=@UserID and col_CardID=@CardID and col_UserAddress not in (select col_UserAddress from BT_col_UserInfoForReader WITH(nolock) where col_IsUploadToReader<99)
								end
							if @UserAddress=0
								begin
									select @UserAddress=min(col_UserAddress) from BT_col_UserIDAndAddress where col_UserID=0 and col_CardID='' 
			 					end
							if @UserAddress=0
								begin
									select top 1 @UserAddress=a.col_UserAddress from BT_col_UserIDAndAddress a left join BT_col_UserInfoForReader b on a.col_CardID=b.col_CardID where a.col_IsDel=1 and b.col_IsUploadToReader=99 order by b.col_DateEnd
								end
							
							if @CardType<>11 and @IfNotChange=1--@CardType>=12 and	
								begin
									set @IfNotChange=0
								end
						end
					else
						begin
							set @UserAddress=@OldUserAddress
						end
				end
			else
				begin
					select @IfNotChange=1 from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_UserType=@UserType and col_UserName=@UserName and col_Status=@Enabled and col_IfHadFace=@IfHadFace
					select @IfPhotoNotChange=1 from zh_Members where id=@UserID and zpurl=(select col_FaceURL from BT_col_UserFaceData where col_UserCode=@UserCode)
					if @Enabled=1 and @IfPhotoNotChange=0 --图片变了
						begin
							if @IfNotChange=1
								begin
									set @SetorClear=4
									set @ifNeedInsert=1
								end
						end
				end

			if @IfNotChange=0 --or @IfPhotoNotChange=0
				begin
					if @CardID<>'0'
						begin
							INSERT BT_col_UserInfoForReaderBackup(col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime,col_BackupTime)
							select col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime,GetDate() from BT_col_UserInfoForReader where col_UserCode=@UserCode and col_CardID=@CardID
							update BT_col_UserInfoForReader set col_UserID=@UserID,col_UserCode=@UserCode,col_UserType=@UserType,col_UserAddress=@UserAddress,col_UserName=@UserName,col_FCCellID=@FCCellCode,col_CardID=@CardID,col_CardType=@CardType,col_MaxSwipeTime=@MaxSwipeTime,col_DateStart=@DateStart,col_DateEnd=@DateEnd,col_PlanTemplateID=@PlanTemplateID,col_Status=@Enabled,col_IsUploadToReader=@Status,col_IfHadFace=@IfHadFace,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserCode=@UserCode and col_CardID=@CardID-- from BT_col_UserInfoForReader,ZH_Owner where BT_col_UserInfoForReader.col_UserCode=ZH_Owner.code and ZH_Owner.code=@UserCode
						
							if @OldUserAddress=0 and @UserAddress>0
								begin
									update BT_col_UserIDAndAddress set col_IsDel=1 where col_UserID=@UserID and col_CardID=@CardID and col_UserAddress<>@UserAddress
									update BT_col_UserIDAndAddress set col_UserID=@UserID,col_CardID=@CardID,col_IsDel=0 where col_UserAddress=@UserAddress
			 					end
						end
					else
						begin
							INSERT BT_col_UserInfoForReaderBackup(col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime,col_BackupTime)
							select col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime,GetDate() from BT_col_UserInfoForReader where col_UserCode=@UserCode 
							update BT_col_UserInfoForReader set col_UserID=@UserID,col_UserCode=@UserCode,col_UserType=@UserType,col_UserName=@UserName,col_Status=@Enabled,col_IsUploadToReader=@Status,col_IfHadFace=@IfHadFace,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserCode=@UserCode-- from BT_col_UserInfoForReader,ZH_Owner where BT_col_UserInfoForReader.col_UserCode=ZH_Owner.code and ZH_Owner.code=@UserCode
						end

					set @ifNeedInsert=1

				end
		end
	ELSE if @CardID<>'0'
		begin
			 select top 1 @UserAddress=col_UserAddress from BT_col_UserIDAndAddress WITH(nolock) where col_UserID=@UserID and col_CardID=@CardID and col_UserAddress not in (select col_UserAddress from BT_col_UserInfoForReader WITH(nolock))
			if @UserAddress=0
				begin
					select top 1 @UserAddress=col_UserAddress from BT_col_UserIDAndAddress WITH(nolock) where col_UserID=@UserID and col_CardID=@CardID and col_UserAddress not in (select col_UserAddress from BT_col_UserInfoForReader WITH(nolock) where col_IsUploadToReader<99)
				end
			if @UserAddress=0
				begin
					select @UserAddress=min(col_UserAddress) from BT_col_UserIDAndAddress where col_UserID=0 and col_CardID='' 
			 	end
			if @UserAddress=0
				begin
					select top 1 @UserAddress=a.col_UserAddress from BT_col_UserIDAndAddress a left join BT_col_UserInfoForReader b on a.col_CardID=b.col_CardID where a.col_IsDel=1 and b.col_IsUploadToReader=99 order by b.col_DateEnd
				end

			 INSERT BT_col_UserInfoForReader(col_UserID,col_UserCode,col_UserType,col_UserAddress,col_UserName,col_OwnerID,col_FCCellID,col_CardID,col_CardType,col_MaxSwipeTime,col_DateStart,col_DateEnd,col_PlanTemplateID,col_ReaderAccess,col_Status,col_IsUploadToReader,col_SwipeTime,col_IfHadFace,col_UploadTime,col_LastInOutTime,col_LastReaderID,col_InOutType,col_UpdateTime,col_CreateTime)
			 Select @UserID,@UserCode,@UserType,@UserAddress,@UserName,@OwnerID,@FCCellCode,@CardID,@CardType,@MaxSwipeTime,@DateStart,@DateEnd,@PlanTemplateID,'-1',@Enabled,@Status,0,@IfHadFace,NULL,NULL,0,-1,GetDate(),GetDate() --from ZH_Owner where code=@UserCode--sync_created_time,Convert(nvarchar(10),dateadd(year,20,sync_created_time),120)
			 update BT_col_UserIDAndAddress set col_IsDel=1 where col_UserID=@UserID and col_CardID=@CardID and col_UserAddress<>@UserAddress
			 update BT_col_UserIDAndAddress set col_UserID=@UserID,col_CardID=@CardID,col_IsDel=0 where col_UserAddress=@UserAddress
			 set @ifNeedInsert=1
		end
	else 
		begin
			 set @ifNeedInsert=1
		end

	if @CardID<>'0'
		begin
			Delete From BT_col_UserCardRecord where col_UserCode=@UserCode and col_CardNo=@CardID
			insert into BT_col_UserCardRecord select @UserCode,@CardID,@CardType,@MaxSwipeTime,@DateStart,@DateEnd,GetDate() 

			Delete From BT_sys_FreeCard where sys_CardNO=@CardID
	
			--Delete From BT_col_CardManagement where col_CardID=@CardID
			--Declare @State as int
			--set @State=0	 
			--set @Count=0
			--select @Count=1,@State=col_State from BT_col_CardManagement where col_CardID=@CardID	  
			--if @Count=0
			--	begin
			--		insert into BT_col_CardManagement
			--		select @CardID,@CardType,@MaxSwipeTime,@DateStart,@DateEnd,@Enabled,@UserID,@FCCellID,@UserName,'',GetDate(),''
			--	end
			--else
			--	begin
			--		update BT_col_CardManagement set col_UserID=@UserID,col_FCCellID=@FCCellID,col_CardName=@UserName where col_CardID=@CardID	
			--		if @Enabled<>@State
			--			begin
			--				update BT_col_CardManagement set col_DateStart=@DateStart,col_DateEnd=@DateEnd,col_State=@Enabled where col_CardID=@CardID	
			--			end
					
			--	end
		end

	if @Enabled=1
		begin
			Exec SaveUserReaderAccess @UserID,@CardID,@UserCodeType
		end
	else if @UserEnabled=0
		begin
			Exec DeleteUserReaderAccess @UserID,@UserCodeType
		end
	else
		begin
			Exec DeleteUserReaderAccess @UserID,@UserCodeType
		end

	--if @CardID<>'0'
	--	begin
	--		if @OldCardNo<>'' and @OldCardNo<>@CardID
	--			begin
	--				Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_CardNo=@OldCardNo
	--				--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime) select @UserCode,@OldCardNo,sys_ReaderID,99,col_DateStart,col_DateEnd,0,dateadd(MINUTE,-1,GetDate()) from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@OldCardNo
	--				INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
	--				SELECT top 1 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(MINUTE,-1,GetDate()),dateadd(MINUTE,-1,GetDate()) from BT_col_UserInfoForReaderBackup as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@OldCardNo and a.col_CardType<11 and a.col_IsUploadToReader<>99 order by col_BackupTime

	--				INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
	--				SELECT top 1 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(MINUTE,-1,GetDate()),dateadd(MINUTE,-1,GetDate()) from BT_col_UserInfoForReaderBackup as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@OldCardNo and a.col_CardType>12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15) order by col_BackupTime

	--				INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
	--				SELECT top 1 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(MINUTE,-1,GetDate()),dateadd(MINUTE,-1,GetDate()) from BT_col_UserInfoForReaderBackup as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@OldCardNo and a.col_CardType=12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15 and IsOctDevice='true') order by col_BackupTime

	--				INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
	--				SELECT top 1 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(MINUTE,-1,GetDate()),dateadd(MINUTE,-1,GetDate()) from BT_col_UserInfoForReaderBackup as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@OldCardNo and a.col_CardType=11 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true') order by col_BackupTime

	--			end

	--	end

	if @ifNeedInsert=1 and @Enabled=1
		begin		
			if @CardID<>'0'
				begin
					--Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_CardNo=@CardID
					--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime) select col_UserCode,col_CardID,sys_ReaderID,@SetorClear,col_DateStart,col_DateEnd,0,GetDate() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and col_CardID=@CardID			
					if @SetorClear=4
						begin
							Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_Status=@SetorClear and col_Status>1

							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)
						end
					else
						begin
							Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_CardNo=@CardID

							if @CardType<11
								begin
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_CardType<11
								end
							else if @CardType>12 and @UserAddress>0
								begin
									Delete from BT_col_AutoDownloadUserForReader where col_UserAddress=@UserAddress
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when @SetorClear=99 then GETDATE() when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_CardType>12 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15)
								end
							else if @CardType=12 and @UserAddress>0
								begin
									Delete from BT_col_AutoDownloadUserForReader where col_UserAddress=@UserAddress
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when @SetorClear=99 then GETDATE() when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_CardType=12 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15 and IsOctDevice='true')
								end
							else if @CardType=11
								begin
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when @SetorClear=99 then GETDATE() when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo left join V_HostDeviceForSam c on b.sys_ReaderID=c.HostDeviceID where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true'
		 						end
						end

					if @SetorClear<>99 AND @CardType<12 and @IfHadFace=1
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,GETDATE()),dateadd(second,1,GETDATE()) from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardID=@CardID and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)
						end
				end
			else
				begin
					--Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_Status=@SetorClear
					--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime) select col_UserCode,col_CardID,sys_ReaderID,@SetorClear,col_DateStart,col_DateEnd,0,GetDate() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode --and col_CardID=@CardID
					if @SetorClear=4
						begin
							Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_Status=@SetorClear and col_Status>1

							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)
						end
					else
						begin
							Delete from BT_col_AutoDownloadUserForReader where col_UserCode=@UserCode and col_Status=@SetorClear

							if @CardType<11
								begin
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardType<11-- and a.col_CardID=@CardID
								end	
							else if @CardType>12
								begin
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when @SetorClear=99 then GETDATE() when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardType>12 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15)-- and a.col_CardID=@CardID
								end	
							else if @CardType=12
								begin
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when @SetorClear=99 then GETDATE() when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_CardType=12 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15 and IsOctDevice='true')-- and a.col_CardID=@CardID
								end	
							else if @CardType=11
								begin
									INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
									SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,@SetorClear,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when @SetorClear=99 then GETDATE() when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo left join V_HostDeviceForSam c on b.sys_ReaderID=c.HostDeviceID where a.col_UserCode=@UserCode and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true'-- and a.col_CardID=@CardID
		 						end
						end

					if @SetorClear<>99 AND @CardType<12 and @IfHadFace=1
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,GETDATE()),dateadd(second,1,GETDATE()) from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)-- and a.col_CardID=@CardID
						end
				end

		end	 


--commit Transaction
Select 1
return 0


TheEnd:	
--commit Transaction
Select 0
return 0

PROBLEM:
--rollback Transaction
Select 0
return 1

END
