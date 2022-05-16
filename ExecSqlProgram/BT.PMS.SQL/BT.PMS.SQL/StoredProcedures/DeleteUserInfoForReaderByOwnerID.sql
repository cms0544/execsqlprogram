--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'DeleteUserInfoForReaderByOwnerID') and xtype='P')  DROP PROCEDURE [dbo].[DeleteUserInfoForReaderByOwnerID]
GO
/****** Object:  StoredProcedure [dbo].[DeleteUserInfoForReaderByOwnerID]    Script Date: 04/22/2021 18:23:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2019-03-14>
-- Description:	<刪除业主及業主下所有成員的卡片> 
--Exec DeleteUserInfoForReaderByOwnerID 1
-- =============================================
CREATE PROCEDURE [dbo].[DeleteUserInfoForReaderByOwnerID] 
(
	@OwnerID int
)
AS
BEGIN
	SET NOCOUNT ON; 
--BEGIN TRANSACTION
	 
	Declare @Count int
	set @Count=0
	select top 1 @Count=1 from V_HostDeviceForSam
	if @Count=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
			Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID) and col_UserAddress>0 and col_CardType>=12)
			--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime) select col_UserCode,col_CardID,sys_ReaderID,99,col_DateStart,col_DateEnd,0,GetDate() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode and a.col_IsUploadToReader<>99
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID) and a.col_CardType<11 and a.col_IsUploadToReader<>99

			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID) and col_UserAddress>0 and a.col_CardType>12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15)

			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID) and col_UserAddress>0 and a.col_CardType=12 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true')

			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID) and a.col_CardType=11 and a.col_IsUploadToReader<>99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')
		end

	Delete From BT_col_TempUserFace where col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete From BT_col_UserFaceData where col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from BT_sys_UserReaderAccess where sys_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from BT_sys_UserReaderAccessOld where sys_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from BT_sys_UserReaderAccess_JTCY where sys_memberid in (select col_UserID from BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_memberid in (select col_UserID from BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from BT_col_UserOldCard where col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from BT_col_UserCardRecord where col_UserCode in (select col_UserCode From BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from BT_col_CardManagement where col_UserID in (select col_UserID from BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
	Delete from BT_col_CardManagement where col_OwnerID=@OwnerID
	if @Count=1
		begin
			update BT_col_UserIDAndAddress set col_IsDel=1 where col_UserID in (select col_UserID from BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
		end
	else
		begin
			update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_UserID in (select col_UserID from BT_col_UserInfoForReader where col_OwnerID=@OwnerID)
			--update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_OwnerID=@OwnerID) and col_UserAddress not in (select col_UserAddress from BT_col_UserInfoForReader where col_OwnerID<>@OwnerID)
		end
	Delete from BT_col_UserInfoForReader where col_OwnerID=@OwnerID
	Delete from BT_col_UserInfoForReaderBackup where col_OwnerID=@OwnerID
	if @Count=0
		begin
			select top 1 @Count=1 from ZH_Owner
			if @Count=0--初始化系統
				begin
					truncate table ZH_Owner 
					truncate table ZH_Members   
					truncate table BT_sys_UserReaderAccess
					truncate table BT_sys_UserReaderAccessOld 
					truncate table BT_sys_UserReaderAccess_JTCY  
					truncate table tb_DoorGroup_UserReaderAccess_JTCY  
					truncate table BT_col_CardManagement
					update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 
					truncate table BT_col_UserInfoForReader  
					truncate table BT_col_UserInfoForReaderBackup
					truncate table BT_col_UserFaceDownloadError  
					truncate table BT_col_UserCardRecord  
					truncate table BT_col_UserOldCard  
					truncate table BT_sys_FreeCard
					truncate table BT_sys_UserDownloadRecord 
					truncate table BT_sys_UserDownloadRecordBackup 
					truncate table BT_col_AutoDownloadUserForReader
					truncate table BT_col_UserFaceData  
					truncate table BT_col_TempUserFace  
					truncate table BT_sys_RawDataLogForReader 
					truncate table BT_sys_InitReaderData 
					truncate table BT_sys_ReaderAccessForLP 
					truncate table BT_sys_ReaderAccessForLPOld 
					truncate table BT_sys_ReaderOnlineStatus 
					truncate table BT_sys_ReaderOnlineLog 
					truncate table BT_sys_IfNeedReStartServer 
					truncate table BT_sys_ReaderProcessID 
					truncate table t_Soyal_Area 
					truncate table t_Soyal_ConnPort 
					truncate table t_sys_ReaderMachine 
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
