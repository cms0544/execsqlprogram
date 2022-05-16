
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_DoorGroupSetting_Delete') and xtype='P')  DROP PROCEDURE [dbo].[SP_DoorGroupSetting_Delete]
GO



-- exec SP_DoorGroupSetting_Delete '15'

CREATE Proc [dbo].[SP_DoorGroupSetting_Delete]
(
	@DoorIDs		nvarchar(max)
)
as 
BEGIN TRY

			Declare @SQL nvarchar(max)

			--删除
			SET @SQL=' UPDATE [dbo].[tb_DoorGrup] SET [IsDelete]=1 WHERE [ID] in (' + @DoorIDs + ') '
			EXEC(@SQL)

			SET @SQL=' UPDATE  [dbo].[tb_DoorGroup_SettingUserID]  SET [IsDelete]=1 WHERE [DoorID] in (' + @DoorIDs + ') '
			EXEC(@SQL)


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
		
			--存在的都要删除

			SET @SQL=''
			SET @SQL +=' SELECT sys_MemberID,sys_ParentID,sys_ReaderID FROM tb_DoorGroup_UserReaderAccess_JTCY as A WHERE A.sys_ParentID in (' + @DoorIDs +  ') and isnull(sys_ReaderID,0)<>0 '
			INSERT INTO #TBDoorGroupDel EXEC(@SQL)

			SET @SQL=''
			SET @SQL +=' select sys_MemberID,sys_ParentID,sys_ReaderID  from ( '
			SET @SQL +=' select sys_MemberID,DoorID as sys_ParentID,AccessControlID as sys_ReaderID from tb_DoorGroup_SettingUserID as a '
			SET @SQL +=' left join tb_DoorGroup_UserReaderAccess_JTCY as b on b.sys_ParentID=a.DoorID ' 
			SET @SQL +=' where DoorID in (' + @DoorIDs +  ') and isnull(a.AccessControlID,0)<>0 and isnull(b.sys_ReaderID,0)=0 '
			SET @SQL +=' and isnull(b.sys_MemberID,0)<>0  '
			SET @SQL +=' ) as A where not exists (select 1 from #TBDoorGroupDel as B where B.sys_MemberID=A.sys_MemberID AND B.sys_ParentID=A.sys_ParentID AND B.sys_ReaderID=A.sys_ReaderID ) '
			INSERT INTO #TBDoorGroupDel EXEC(@SQL)

			--放在最前才对，之后删除
			DELETE A FROM tb_DoorGroup_UserReaderAccess_JTCY as A,#TBDoorGroupDel as B
			WHERE A.sys_memberid=B.sys_MemberID AND A.sys_ParentID=B.sys_ParentID 

			--select 'aaaaa', * from #TBDoorGroupDel
			--如果员工在其他门组也有这个门禁的话就不删除
			SET @SQL=''
			SET @SQL +=' DELETE A FROM #TBDoorGroupDel as A, '
			SET @SQL +=' ( '
			SET @SQL +=' 	SELECT sys_MemberID,sys_ParentID,sys_ReaderID FROM tb_DoorGroup_UserReaderAccess_JTCY as A WHERE A.sys_MemberID in ( SELECT sys_MemberID FROM #TBDoorGroupDel ) AND ISNULL(sys_ReaderID,0)<>0 AND A.sys_ParentID not in ( ' + @DoorIDs +  ' ) ' --表示员工在其他门组或门禁点也有这个门禁
			SET @SQL +=' ) as B '
			SET @SQL +=' WHERE A.sys_MemberID=B.sys_MemberID AND A.sys_ReaderID=B.sys_ReaderID '
			--删除
			EXEC(@SQL)

	

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
			--select * from BT_col_AutoDownloadUserForReader

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
		


	SELECT 1  

END TRY
BEGIN CATCH
	SELECT 0
END CATCH