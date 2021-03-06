
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_DoorGroupSetting') and xtype='P')  DROP PROCEDURE [dbo].[SP_DoorGroupSetting]
GO


/****** Object:  StoredProcedure [dbo].[SP_DoorGroupSetting]    Script Date: 18/5/2021 14:13:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- exec SP_DoorGroupSetting 25,'qqbbbbbb','2122','5,','admin',0

create Proc [dbo].[SP_DoorGroupSetting]
(
	@DoorID					int,
	@DoorName				nvarchar(max),
	@Remark					nvarchar(max),
	@AccessControlIDs		nvarchar(max),
	@UserID					nvarchar(max),
	@IsVisitor				int
)
as 
BEGIN TRY
	IF @DoorID<=0
		BEGIN
			Insert into tb_DoorGrup(DoorName,Remark,IsDelete,InUserID,InTime,UpUserID,Uptime,IsVisitor)
			Values(@DoorName,@Remark,0,@UserID,Getdate(),@UserID,getdate(),@IsVisitor)
			SET @DoorID =@@IDENTITY


		SELECT Row_number() over(order by AccessControlID asc) RID ,AccessControlID Into #TempData_AccessControlAdd FROM(
			SELECT Convert(int,COL) AccessControlID  from fn_split_ToTable(@AccessControlIDs,',')
		) as h

		--删除不需要的数据
		DELETE FROM tb_DoorGroup_SettingUserID where DoorID=@DoorID and AccessControlID not in(
			select isnull(AccessControlID,0) from #TempData_AccessControlAdd
		)

		--DECLARE @RIndex int=1
		--DECLARE @RCount int=(SELECT MAX(RID) FROM #TempData_AccessControl)
		--WHILE @RIndex<=@RCount
		--BEGIN
		--	DECLARE @AccessControlID int=0
		--	SELECT @AccessControlID=AccessControlID FROM #TempData_AccessControl where RID=@RIndex

		--	IF not exists(select 1 from tb_DoorGroup_SettingUserID where DoorID=@DoorID and AccessControlID=@AccessControlID)
		--	BEGIN  
		--		Insert into tb_DoorGroup_SettingUserID(DoorID,AccessControlID,IsDelete)
		--		Values(@DoorID,@AccessControlID,0)
		--	END
		--	set @RIndex=@RIndex+1
		--END

		--20210329 Jason 改成批量插入
		Insert into tb_DoorGroup_SettingUserID(DoorID,AccessControlID,IsDelete)
		SELECT @DoorID,A.AccessControlID,0 as IsDelete FROM #TempData_AccessControlAdd as A
		WHERE NOT EXISTS(SELECT 1 FROM tb_DoorGroup_SettingUserID as B WHERE B.DoorID=@DoorID AND B.AccessControlID=A.AccessControlID )



		END
	ELSE
		BEGIN
			Update tb_DoorGrup set DoorName=@DoorName,Remark=@Remark,UpUserID=@UserID,Uptime=getdate(),IsVisitor=@IsVisitor where ID=@DoorID


			SELECT Row_number() over(order by AccessControlID asc) RID ,AccessControlID Into #TempData_AccessControl FROM(
				SELECT Convert(int,COL) AccessControlID  from fn_split_ToTable(@AccessControlIDs,',')
			) as h



			------删除不需要的数据
			DELETE FROM tb_DoorGroup_SettingUserID where DoorID=@DoorID and AccessControlID not in(
				select isnull(AccessControlID,0) from #TempData_AccessControl
			)




			--20210329 Jason 改成批量插入
			Insert into tb_DoorGroup_SettingUserID(DoorID,AccessControlID,IsDelete)
			SELECT @DoorID,A.AccessControlID,0 as IsDelete FROM #TempData_AccessControl as A
			WHERE NOT EXISTS(SELECT 1 FROM tb_DoorGroup_SettingUserID as B WHERE B.DoorID=@DoorID AND B.AccessControlID=A.AccessControlID )

			--是否应用于此门组的所有业主

			--20210329 Jason 修改门组，新增卡机，询问是否将新卡机应用于此门组的所有业主。
			--20210329 Jason 修改门组，删除卡机，询问是否将删除所有业主在此卡机上的权限。
	
			--获取门组下的员工
			IF OBJECT_ID('tempdb.dbo.#TBMemberIDDoorGroup') IS NOT NULL DROP TABLE #TBMemberIDDoorGroup
			CREATE TABLE #TBMemberIDDoorGroup(
				number					[int] IDENTITY(1,1) NOT NULL,
				sys_MemberID			int,
				sys_ParentID			int,
				sys_ReaderID			int
			)

			declare @accnumber int,@AccessControlID int
			SET @accnumber=1		

			WHILE(EXISTS(SELECT 1 FROM #TempData_AccessControl WHERE RID=@accnumber))
				BEGIN
					SET @AccessControlID=0
					SELECT @AccessControlID=ISNULL(AccessControlID,0) FROM #TempData_AccessControl WHERE RID=@accnumber
					IF(ISNULL(@AccessControlID,0)<>0)
						BEGIN
							INSERT INTO #TBMemberIDDoorGroup 
							SELECT b.id as sys_MemberID,@DoorID as sys_ParentID,@AccessControlID as sys_ReaderID from tb_DoorGroup_UserReaderAccess_JTCY as a
							LEFT JOIN ZH_Members as b on b.id=a.sys_MemberID
							WHERE ISNULL(b.deleted,0)=0 AND ISNULL(b.id,0)>0 AND sys_ParentID=@DoorID GROUP BY b.id
						END

					SET @accnumber=@accnumber+1

				END

			--select '#TempData_AccessControl', * from #TempData_AccessControl


			--要删除的则删除
			--先获取门组存在，新表#TBMemberIDDoorGroup不存在的数据
			IF OBJECT_ID('tempdb.dbo.#TBDoorGroupDel') IS NOT NULL DROP TABLE #TBDoorGroupDel
			CREATE TABLE #TBDoorGroupDel(
				number					[int] IDENTITY(1,1) NOT NULL,
				sys_MemberID			int,
				sys_ParentID			int,
				sys_ReaderID			int
			)

			IF OBJECT_ID('tempdb.dbo.#TBDelUserCode') IS NOT NULL DROP TABLE #TBDelUserCode
			CREATE TABLE #TBDelUserCode(
				number					[int] IDENTITY(1,1) NOT NULL,
				col_UserCode			nvarchar(20) collate Chinese_PRC_CI_AS
			)
		
			INSERT INTO #TBDoorGroupDel 
			SELECT sys_MemberID,sys_ParentID,sys_ReaderID FROM tb_DoorGroup_UserReaderAccess_JTCY as A WHERE A.sys_ParentID=@DoorID
			AND NOT EXISTS (SELECT 1 FROM #TBMemberIDDoorGroup as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ParentID=A.sys_ParentID AND B.sys_ReaderID=A.sys_ReaderID )


			 --INSERT INTO #TBDoorGroupDel 
			 --select sys_MemberID,sys_ParentID,sys_ReaderID  from ( 
			 --select sys_MemberID,DoorID as sys_ParentID,AccessControlID as sys_ReaderID from tb_DoorGroup_SettingUserID as a 
			 --left join tb_DoorGroup_UserReaderAccess_JTCY as b on b.sys_ParentID=a.DoorID 
			 --where DoorID in ( @DoorID ) and isnull(a.AccessControlID,0)<>0 and isnull(b.sys_ReaderID,0)=0 
			 --and isnull(b.sys_MemberID,0)<>0  
			 --) as A where not exists (select 1 from #TBMemberIDDoorGroup as B where B.sys_MemberID=A.sys_MemberID AND B.sys_ParentID=A.sys_ParentID AND B.sys_ReaderID=A.sys_ReaderID ) 



			--select 'aaaa', * from #TBDoorGroupDel






			--放在最前才对，之后删除 20210412要不要都无所谓，现在表tb_DoorGroup_UserReaderAccess_JTCY的sys_ParentID或sys_ReaderID有一个是0的
			DELETE A FROM tb_DoorGroup_UserReaderAccess_JTCY as A,#TBDoorGroupDel as B
			WHERE A.sys_memberid=B.sys_MemberID AND A.sys_ReaderID=B.sys_ReaderID AND A.sys_ParentID=@DoorID AND A.sys_ReaderID<>0


			--如果员工在其他门组也有这个门禁的话就不删除
			DELETE A FROM #TBDoorGroupDel as A,
			(
				SELECT sys_MemberID,sys_ParentID,sys_ReaderID FROM tb_DoorGroup_UserReaderAccess_JTCY as A WHERE A.sys_MemberID in ( SELECT sys_MemberID FROM #TBDoorGroupDel ) AND ISNULL(sys_ReaderID,0)<>0 AND A.sys_ParentID<>@DoorID --表示员工在其他门组或门禁点也有这个门禁
			) as B 
			WHERE A.sys_MemberID=B.sys_MemberID AND A.sys_ReaderID=B.sys_ReaderID 


			--select * from #TBDoorGroupDel

			--select '#TBDoorGroupDel', * from #TBDoorGroupDel


			INSERT INTO #TBDelUserCode
			SELECT c.col_UserCode FROM #TBDoorGroupDel as a
			LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=a.sys_MemberID
			WHERE ISNULL(c.col_UserCode,'')<>'' GROUP BY c.col_UserCode

			--抄存储过程SaveUserReaderAccess
			--删除
			update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserCode in (
				SELECT col_UserCode FROM #TBDelUserCode
			)

			--Delete from BT_col_AutoDownloadUserForReader where col_UserCode in (
			--	SELECT col_UserCode FROM #TBDelUserCode
			--) -- and col_Status=1

			--Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserCode in (
			--	SELECT col_UserCode FROM #TBDelUserCode
			--) and col_UserAddress>0 and col_CardType>=12)
			--插入之前先删除之前插入的数据
			DELETE A FROM BT_col_AutoDownloadUserForReader as A,
			(
				SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBDoorGroupDel as d
				left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			) as B
			WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
			from #TBDoorGroupDel as d 
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
			from #TBDoorGroupDel as d 
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
			from #TBDoorGroupDel as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
			from #TBDoorGroupDel as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
			from #TBDoorGroupDel as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)

			--最后删除
			DELETE A FROM BT_sys_UserReaderAccess as A,
			( 
				SELECT c.col_UserCode,B.* FROM #TBDoorGroupDel as B
				LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=b.sys_MemberID
			) as B
			WHERE A.sys_UserCode=B.col_UserCode AND A.sys_ReaderID=B.sys_ReaderID

			DELETE A FROM BT_sys_UserReaderAccess_JTCY as A,#TBDoorGroupDel as B
			WHERE A.sys_memberid=B.sys_MemberID AND A.sys_ReaderID=B.sys_ReaderID
		

			--要插入的插入
			--先获取门组存在，新表#TBMemberIDDoorGroup存在而表tb_DoorGroup_UserReaderAccess_JTCY不存在的数据
			IF OBJECT_ID('tempdb.dbo.#TBDoorGroupInsert') IS NOT NULL DROP TABLE #TBDoorGroupInsert
			CREATE TABLE #TBDoorGroupInsert(
				number					[int] IDENTITY(1,1) NOT NULL,
				sys_MemberID			int,
				sys_ParentID			int,
				sys_ReaderID			int
			)

			IF OBJECT_ID('tempdb.dbo.#TBInsertUserCode') IS NOT NULL DROP TABLE #TBInsertUserCode
			CREATE TABLE #TBInsertUserCode(
				number					[int] IDENTITY(1,1) NOT NULL,
				col_UserCode			nvarchar(20) collate Chinese_PRC_CI_AS
			)
			INSERT INTO #TBDoorGroupInsert 
			SELECT sys_MemberID,sys_ParentID,sys_ReaderID FROM #TBMemberIDDoorGroup as A WHERE A.sys_ParentID=@DoorID
			--AND NOT EXISTS (SELECT 1 FROM tb_DoorGroup_UserReaderAccess_JTCY as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ParentID=A.sys_ParentID AND B.sys_ReaderID=A.sys_ReaderID )

		
			INSERT INTO #TBInsertUserCode
			SELECT c.col_UserCode FROM #TBDoorGroupInsert as a
			LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=a.sys_MemberID
			WHERE ISNULL(c.col_UserCode,'')<>'' GROUP BY c.col_UserCode


			--插入
			update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserCode in (
				SELECT col_UserCode FROM #TBInsertUserCode
			)

			--插入之前先删除之前插入的数据
			DELETE A FROM BT_col_AutoDownloadUserForReader as A,
			(
				SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBDoorGroupInsert as d
				left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			) as B
			WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
			from #TBDoorGroupInsert as d 
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
			from #TBDoorGroupInsert as d 
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
			from #TBDoorGroupInsert as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
			from #TBDoorGroupInsert as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
			ISNULL(col_Status,1) as col_Status ,sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
			from #TBDoorGroupInsert as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
			where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)


			--插入
			insert into tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
			SELECT sys_MemberID,sys_ParentID,sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBDoorGroupInsert as A
			WHERE NOT EXISTS(SELECT 1 FROM tb_DoorGroup_UserReaderAccess_JTCY as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ParentID=A.sys_ParentID AND B.sys_ReaderID=A.sys_ReaderID )

			insert into BT_sys_UserReaderAccess(sys_UserCode,sys_CardNo,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange)
			SELECT col_UserCode,col_CardID,A.sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBDoorGroupInsert as A
			LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=A.sys_MemberID
			WHERE ISNULL(c.col_UserCode,'')<>'' AND NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess as B WHERE B.sys_UserCode=c.col_UserCode AND B.sys_ReaderID=A.sys_ReaderID AND B.sys_CardNo=c.col_CardID )

			insert into BT_sys_UserReaderAccess_JTCY(sys_memberid,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange) 
			SELECT sys_MemberID,sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBDoorGroupInsert as A
			WHERE NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess_JTCY as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID )

		END


	SELECT 1  
END TRY
BEGIN CATCH
	SELECT 0
END CATCH