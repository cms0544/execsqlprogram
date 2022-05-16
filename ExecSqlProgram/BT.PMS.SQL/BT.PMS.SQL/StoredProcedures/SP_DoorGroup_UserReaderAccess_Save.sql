

IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_DoorGroup_UserReaderAccess_Save') and xtype='P')  DROP PROCEDURE [dbo].[SP_DoorGroup_UserReaderAccess_Save]
GO



-- exec SP_DoorGroup_UserReaderAccess_Save 1499,''

-- Author:		<Jason>
-- Create date: <2021-04-09>
-- Description:	<修改卡号门禁组权限> 

CREATE Proc [dbo].[SP_DoorGroup_UserReaderAccess_Save]
(
	@memberid				int,
	@doorids				nvarchar(max)
)
as 
BEGIN TRY


		--获取员工保存之前的门组
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupOld') IS NOT NULL DROP TABLE #TBDoorGroupOld
		CREATE TABLE #TBDoorGroupOld(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int
		)

		INSERT INTO #TBDoorGroupOld(sys_ParentID) SELECT ISNULL(sys_ParentID,0) FROM tb_DoorGroup_UserReaderAccess_JTCY where sys_MemberID=@memberid and isnull(sys_ReaderID,0)=0

		DELETE FROM tb_DoorGroup_UserReaderAccess_JTCY where sys_MemberID=@memberid and isnull(sys_ParentID,0)<>0


		SELECT Row_number() over(order by ParentID asc) RID ,ParentID Into #TempData_AccessControlAdd FROM(
			SELECT Convert(int,COL) ParentID  from fn_split_ToTable(@doorids,',')
		) as h

		DELETE FROM #TempData_AccessControlAdd WHERE ISNULL(ParentID,0)=0

		INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
		SELECT @memberid as sys_MemberID,ParentID,0 as sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TempData_AccessControlAdd

		--加这个是为了防止先在【卡号信息】加了门组，之后在【门组管理】去掉某个门禁点，要删除而删除不了
		INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
		SELECT  @memberid as sys_MemberID,DoorID as sys_ParentID,AccessControlID as sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange 
		FROM tb_DoorGroup_SettingUserID as a WHERE ISNULL(a.IsDelete,0)=0 AND isnull(a.AccessControlID,0)<>0 AND a.DoorID in (SELECT ParentID FROM #TempData_AccessControlAdd)
		AND not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=@memberid AND B.sys_ParentID=A.DoorID AND B.sys_ReaderID=A.AccessControlID ) 



		--获取员工保存之后的门组
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupNew') IS NOT NULL DROP TABLE #TBDoorGroupNew
		CREATE TABLE #TBDoorGroupNew(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int
		)

		INSERT INTO #TBDoorGroupNew(sys_ParentID) SELECT ParentID FROM #TempData_AccessControlAdd


		--获取已删除的门组
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupDel') IS NOT NULL DROP TABLE #TBDoorGroupDel
		CREATE TABLE #TBDoorGroupDel(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int,			
			sys_ReaderID			int
		)
		--select * from #TBDoorGroupOld
		INSERT INTO #TBDoorGroupDel(sys_ParentID,sys_ReaderID) SELECT DoorID,AccessControlID FROM tb_DoorGroup_SettingUserID as a WHERE ISNULL(IsDelete,0)=0 AND ISNULL(AccessControlID,0)<>0		
		and a.DoorID in ( 
		SELECT sys_ParentID FROM #TBDoorGroupOld WHERE sys_ParentID not in (SELECT sys_ParentID FROM #TBDoorGroupNew )
		)
		
		--select 'abcdddd', * from #TBDoorGroupDel

		--如果员工在其他门组或门禁点也有这个门禁的话就不删除
		DELETE A FROM #TBDoorGroupDel as A,
		(
			SELECT sys_MemberID,sys_ParentID,sys_ReaderID FROM tb_DoorGroup_UserReaderAccess_JTCY as A WHERE A.sys_MemberID=@memberid AND ISNULL(sys_ReaderID,0)<>0 AND A.sys_ParentID not in (SELECT sys_ParentID FROM #TBDoorGroupDel  ) --表示员工在其他门组或门禁点也有这个门禁
		) as B 
		WHERE A.sys_ReaderID=B.sys_ReaderID 

		--select 'aaaa', * from #TBDoorGroupDel

		--放在最前才对，之后删除
		DELETE A FROM tb_DoorGroup_UserReaderAccess_JTCY as A,#TBDoorGroupDel as B
		WHERE A.sys_memberid=@memberid AND A.sys_ReaderID=B.sys_ReaderID AND A.sys_ParentID=B.sys_ParentID AND ISNULL(A.sys_ReaderID,0)=0

		--抄存储过程SaveUserReaderAccess
		--删除
		update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserID=@memberid



		--插入之前先删除之前插入的数据
		DELETE A FROM BT_col_AutoDownloadUserForReader as A,
		(
			SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBDoorGroupDel as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		) as B
		WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
		from #TBDoorGroupDel as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid 
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupDel as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupDel as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupDel as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
		from #TBDoorGroupDel as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)

		--最后删除
		DELETE A FROM BT_sys_UserReaderAccess as A,
		( 
			SELECT c.col_UserCode,B.* FROM #TBDoorGroupDel as B
			LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=@memberid
		) as B
		WHERE A.sys_UserCode=B.col_UserCode AND A.sys_ReaderID=B.sys_ReaderID

		DELETE A FROM BT_sys_UserReaderAccess_JTCY as A,#TBDoorGroupDel as B
		WHERE A.sys_memberid=@memberid AND A.sys_ReaderID=B.sys_ReaderID
		




		--要插入的插入
		--先获取门组存在，新表#TBMemberIDDoorGroup存在而表tb_DoorGroup_UserReaderAccess_JTCY不存在的数据
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupInsert') IS NOT NULL DROP TABLE #TBDoorGroupInsert
		CREATE TABLE #TBDoorGroupInsert(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int,
			sys_ReaderID			int
		)

		IF OBJECT_ID('tempdb.dbo.#TBInsertUserCode') IS NOT NULL DROP TABLE #TBInsertUserCode
		CREATE TABLE #TBInsertUserCode(
			number					[int] IDENTITY(1,1) NOT NULL,
			col_UserCode			nvarchar(20) collate Chinese_PRC_CI_AS
		)

		INSERT INTO #TBDoorGroupInsert(sys_ParentID,sys_ReaderID) SELECT DoorID,AccessControlID FROM tb_DoorGroup_SettingUserID as a WHERE ISNULL(IsDelete,0)=0 AND ISNULL(AccessControlID,0)<>0		
		and a.DoorID in ( 
			SELECT sys_ParentID FROM #TBDoorGroupNew WHERE sys_ParentID not in (SELECT sys_ParentID FROM #TBDoorGroupOld )
		)

		--插入
		update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserID=@memberid


		--插入之前先删除之前插入的数据
		DELETE A FROM BT_col_AutoDownloadUserForReader as A,
		(
			SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBDoorGroupInsert as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		) as B
		WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
		from #TBDoorGroupInsert as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupInsert as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid 
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupInsert as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupInsert as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid 
		left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
		from #TBDoorGroupInsert as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)
		

		insert into BT_sys_UserReaderAccess(sys_UserCode,sys_CardNo,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange)
		SELECT col_UserCode,col_CardID,A.sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBDoorGroupInsert as A
		LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=@memberid
		WHERE ISNULL(c.col_UserCode,'')<>'' AND NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess as B WHERE B.sys_UserCode=c.col_UserCode AND B.sys_ReaderID=A.sys_ReaderID AND B.sys_CardNo=c.col_CardID )

		insert into BT_sys_UserReaderAccess_JTCY(sys_memberid,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange) 
		SELECT @memberid as sys_MemberID,sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBDoorGroupInsert as A
		WHERE NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess_JTCY as B WHERE B.sys_MemberID=@memberid AND B.sys_ReaderID=A.sys_ReaderID )

		
		--有操作过，加权限
		IF(NOT EXISTS(SELECT 1 FROM BT_IsExistsUserReaderAccess WHERE sys_MemberID=@memberid))
			BEGIN
				INSERT INTO BT_IsExistsUserReaderAccess(sys_MemberID) VALUES(@memberid)
			END



	SELECT 1  
END TRY
BEGIN CATCH
	SELECT 0
END CATCH