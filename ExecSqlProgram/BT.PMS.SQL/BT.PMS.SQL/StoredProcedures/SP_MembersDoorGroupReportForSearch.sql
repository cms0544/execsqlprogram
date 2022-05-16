IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_MembersDoorGroupReportForSearch') and xtype='P')  DROP PROCEDURE [dbo].[SP_MembersDoorGroupReportForSearch]
GO



-- exec SP_MembersDoorGroupReportForSearch 0,'',1,'','正式業主','', 1,10,'',0

CREATE PROCEDURE [dbo].[SP_MembersDoorGroupReportForSearch]
(
	@IsExport					int,							--0为预览，1为导出Excel，用DateSet
	@fjbm						nvarchar(max),					--房间编码
	@searchid					int,							--快速檢索ID，1为業主編碼，2为業主姓名，3为手機號碼	
	@searchtext					nvarchar(max),					--当前的页码 
	@yzlx						nvarchar(max),					--全部業主  正式業主  臨時業主
	@companyname				nvarchar(max),					--加个公司，模糊查找
	@pageNumber					int=1,	 
	@pageSize					int=100,						--每页显示的数据量  
	@sequenceField				nvarchar(100)='CODE asc ',		--排序字段  
	@DataCount					int out --总数据量  int out		--总数据量 
)
as 
BEGIN 

	begin try
		DECLARE @salessql nvarchar(max),@DGZiDuanSQL nvarchar(max), @DGZiDuan nvarchar(max),@DGNumber int,@DoorID int,@DoorName nvarchar(max)
		DECLARE @SQL nvarchar(max),@monthsql nvarchar(max)
		DECLARE @Sqlcount nvarchar(max)

		--门组名
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroup') IS NOT NULL DROP TABLE #TBDoorGroup
		CREATE TABLE #TBDoorGroup(
			number					[int] IDENTITY(1,1) NOT NULL,
			DoorID					int,
			DoorName				nvarchar(max) collate Chinese_PRC_CI_AS
		)

			
		IF OBJECT_ID('tempdb.dbo.#TBUserInfo') IS NOT NULL DROP TABLE #TBUserInfo
		CREATE TABLE #TBUserInfo(
			number					[int] IDENTITY(1,1) NOT NULL,
			memberid				int,
			ownerid					int,
			membername				nvarchar(50)  collate Chinese_PRC_CI_AS,
			cellname				nvarchar(50)  collate Chinese_PRC_CI_AS,
			cardids					nvarchar(max)  collate Chinese_PRC_CI_AS,
			lxdh					nvarchar(30)  collate Chinese_PRC_CI_AS,
			code					nvarchar(20)  collate Chinese_PRC_CI_AS,
			sumcount				int
		)

		IF OBJECT_ID('tempdb.dbo.#TBUserInfoExport') IS NOT NULL DROP TABLE #TBUserInfoExport
		CREATE TABLE #TBUserInfoExport(
			id						[int] IDENTITY(1,1) NOT NULL,
			number					int,
			memberid				int,
			ownerid					int,
			membername				nvarchar(50)  collate Chinese_PRC_CI_AS,
			cellname				nvarchar(50)  collate Chinese_PRC_CI_AS,
			cardids					nvarchar(max)  collate Chinese_PRC_CI_AS,
			lxdh					nvarchar(30)  collate Chinese_PRC_CI_AS,
			code					nvarchar(20)  collate Chinese_PRC_CI_AS,
			sumcount				int
		)


		INSERT INTO #TBDoorGroup(DoorID,DoorName)
		SELECT ID,DoorName from tb_DoorGrup as a where isnull(IsDelete,0)=0 order by DoorName asc

		SET @DGNumber=1
		SET @DGZiDuanSQL=''
		SET @salessql=''
		SET @monthsql=''
		WHILE(EXISTS( SELECT 1 FROM #TBDoorGroup WHERE number=@DGNumber))
			BEGIN
				
				SET @DoorID=0
				SET @DoorName=''
				SET @DGZiDuan=''
				SELECT TOP 1 @DoorID=ISNULL(DoorID,0),@DoorName=ISNULL(DoorName,'')  FROM #TBDoorGroup WHERE number=@DGNumber

				IF(ISNULL(@salessql,'') <>'')
					BEGIN
						SET @salessql +=',[' + Convert(nvarchar,@DoorID) + ']'
					END
				ELSE
					BEGIN
						SET @salessql +='[' + Convert(nvarchar,@DoorID) + ']'
					END


				SET @DGZiDuan='[ID' + Convert(nvarchar,@DoorID) + ']' --字段

				SET @monthsql += ',' + 'ISNULL(DailySales.[' + Convert(nvarchar,@DoorID) + '],0) AS ' + @DGZiDuan 

				SET @DGZiDuanSQL+=',' + @DGZiDuan

				EXEC ('alter table #TBUserInfo add ' + @DGZiDuan + ' nvarchar(10) ')

				EXEC ('alter table #TBUserInfoExport add ' + @DGZiDuan + ' nvarchar(10) ')

				SET @DGNumber=@DGNumber+1
			END

		--select @salessql,@DGZiDuanSQL

		--IF(ISNULL(@DGZiDuanSQL,'')<>'')
		--	BEGIN
		SET @SQL=''
		SET @SQL +=' INSERT INTO #TBUserInfo(memberid,ownerid,membername,lxdh,code' + @DGZiDuanSQL + ') SELECT a.id,a.ownerid,a.name,a.lxdh,a.CODE ' 
		SET @SQL +=  @monthsql 
		SET @SQL +=' from ZH_Members as a  '
		IF(ISNULL(@salessql,'')<>'')
			BEGIN
				SET @SQL +=' left join ( '
				SET @SQL +='  select sys_MemberID, ' + @salessql

				SET @SQL +='  from '
				SET @SQL +='  ( '
				SET @SQL +='  SELECT sys_MemberID,ISNULL(sys_ParentID,0) as DoorID from tb_DoorGroup_UserReaderAccess_JTCY as a '
				SET @SQL +='  LEFT JOIN ZH_Members as b on b.id=a.sys_MemberID '
				SET @SQL +='  WHERE ISNULL(b.deleted,0)=0 AND ISNULL(b.id,0)>0 AND ISNULL(a.sys_ParentID,0)<>0 AND isnull(a.sys_ReaderID,0)=0 GROUP BY sys_MemberID,sys_ParentID '
				SET @SQL +='  ) A '
				SET @SQL +='  pivot(MAX(DoorID) for DoorID in( ' + @salessql + ')'
				SET @SQL +=' ) pvt1 '
				SET @SQL +=' ) as DailySales on DailySales.sys_MemberID=a.id '
			END
		SET @SQL +=' WHERE ISNULL(a.deleted,0)=0  '
		IF(ISNULL(@fjbm,'')<>'')
			BEGIN
				SET @SQL +=' and a.ownerid in (  '
				SET @SQL +='	SELECT OWNERID from View_ZHFCLPInfo WHERE cellcode like ''%' + @fjbm  + '%''  '
				SET @SQL +=' )  '
			END

		IF(ISNULL(@searchtext,'')<>'')
			BEGIN
				--@searchid					int,							--快速檢索ID，1为業主編碼，2为業主姓名，3为手機號碼	
				IF(@searchid=1)
					BEGIN
						SET @SQL +=' and a.CODE like ''%' + @searchtext  + '%''  '
					END
				ELSE IF(@searchid=2)
					BEGIN
						SET @SQL +=' and a.name like ''%' + @searchtext  + '%''  '
					END
				ELSE IF(@searchid=3)
					BEGIN
						SET @SQL +=' and a.lxdh like ''%' + @searchtext  + '%''  '
					END
				
			END

		IF(ISNULL(@yzlx,'')<>'')
			BEGIN
				SET @SQL +=' and a.ownerid in (  '
				SET @SQL +='	SELECT ID from ZH_OWNER WHERE yzlx=''' + @yzlx  + '''  '
				SET @SQL +=' )  '
			END

		SET @SQL +=' order by a.CODE asc  '
		--select @SQL
		EXEC(@SQL)
		
		--	END
		--ELSE
		--	BEGIN
		--		INSERT INTO #TBUserInfo(memberid,ownerid,membername,lxdh,code) SELECT a.id,a.ownerid,a.name,a.lxdh,a.CODE from ZH_Members as a WHERE ISNULL(a.deleted,0)=0 order by a.CODE asc 
		--	END

		--select * from #TBUserInfo

		--分页
		SET @Sqlcount = N' select @countNum = count(1) from #TBUserInfo '
		EXEC sp_executesql @Sqlcount,N'@countNum int out',@DataCount out  


		UPDATE #TBUserInfo SET sumcount=@DataCount


		IF(@IsExport=0)
			BEGIN
				DECLARE @NewSQL nvarchar(max)
				DECLARE @BNum int  
				DECLARE @ENum int  
				SET @BNum = (@PageNumber-1)*@PageSize+1 
				SET @ENum = @PageNumber*@PageSize 						

				SET @NewSQL=' INSERT INTO #TBUserInfoExport SELECT top ' + convert(nvarchar(10),@pageSize) +' * FROM #TBUserInfo '

				SET @NewSQL+=' where number between '+  convert(nvarchar(10),@BNum) + ' and '+ convert(nvarchar(10),@ENum)
				EXEC(@NewSQL)				
			END
		ELSE
			BEGIN
				INSERT INTO #TBUserInfoExport SELECT * FROM #TBUserInfo order by number asc
			END

		--加上楼宇
		UPDATE A SET A.cellname=B.cellname FROM #TBUserInfoExport as A,
		(SELECT OWNERID,MIN(cellname) as cellname from View_ZHFCLPInfo GROUP BY OWNERID) as B
		WHERE A.ownerid=B.OWNERID


		SET @DGNumber=1
		WHILE(EXISTS( SELECT 1 FROM #TBDoorGroup WHERE number=@DGNumber))
			BEGIN				
				SET @DoorID=0
				SET @DoorName=''
				SET @DGZiDuan=''
				SELECT TOP 1 @DoorID=ISNULL(DoorID,0),@DoorName=ISNULL(DoorName,'')  FROM #TBDoorGroup WHERE number=@DGNumber

				SET @DGZiDuan='[ID' + Convert(nvarchar,@DoorID) + ']' --字段		

				EXEC (' UPDATE #TBUserInfoExport SET ' + @DGZiDuan + '=''√'' WHERE ' + @DGZiDuan +'<>''0'' '  )
				EXEC (' UPDATE #TBUserInfoExport SET ' + @DGZiDuan + '='''' WHERE ' + @DGZiDuan +'=''0'' '  )


				SET @DGNumber=@DGNumber+1
			END

		--SELECT * FROM #TBUserInfo

		--SELECT * from ZH_Members as a WHERE ISNULL(a.deleted,0)=0
		--加入卡号，拼接起来
		UPDATE A SET A.CardIDS=B.CardIDS FROM #TBUserInfoExport as A,
		(
		SELECT  col_UserID ,
        STUFF(( SELECT  ',' + BT_col_CardManagement.col_CardID
                FROM    BT_col_CardManagement
                WHERE   col_UserID = a.col_UserID
              FOR
                XML PATH('')
              ), 1, 1, '') AS CardIDS
		FROM    BT_col_CardManagement a WHERE ISNULL(a.col_UserID,0)>0
		GROUP BY a.col_UserID 
		) as B
		WHERE A.MemberID=B.col_UserID 



		SELECT *  FROM #TBUserInfoExport Order By ID asc

		

	end try
	begin catch
		--if(@@TRANCOUNT >0)    
		--rollback transaction
		select ERROR_MESSAGE()
		SELECT '查询失败'     
	end catch
END 