if(exists(select 1 from sysobjects where id = object_id('sp_ExceptionReport')))
   begin
      drop PROCEDURE [dbo].[sp_ExceptionReport]
   end
/****** Object:  StoredProcedure [dbo].[sp_ExceptionReport]    Script Date: 2021/6/7 19:45:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <異常報表,,>
-- Description:	<Description,,sp_ExceptionReport '','2021-02-06','2021-02-10',1,100,3>
-- =============================================
create PROCEDURE [dbo].[sp_ExceptionReport]
	-- Add the parameters for the stored procedure here
	@platenumber varchar(max) = '',
	@startdate datetime,
	@enddate datetime,
	@page int=1,
	@row int = 100,
	@exceptiontype  int = 0

AS
BEGIN
     declare @sql varchar(max) = '';

	if(@enddate = null )
	  begin

	    set @enddate = dateadd(day,1, getdate())
	  end
	
	
	set @sql =        ' select 設備 as  ''設備 Device'',車牌號 as  ''車牌號 Plates'',Time as ''時間 Time'',case when id>0 then IIF(car_Parking_type=2,''員工 Employee'',''會員 Member'') else ''訪客 Guest'' end  ''車主類型 Owner Type''' 
	set @sql = @sql + ',[dbo].[fn_GetCarType](isnull(type,''0'')) ''車輛類型 Type'', case when ExceptionType=1 then ''無車牌 Unidentifiable'' when ExceptionType=3 then ''逆行 Violation''  else ''無入場記錄 No Entry Record'' end ''異常類型 Anomaly'',AttachImageUrl as ''圖片 Capture'',PicImageUrl as ''详细圖片 Capture'''
	set @sql = @sql + '   into #temp';
	set @sql = @sql + '  from';
	set @sql = @sql + ' (';
	set @sql = @sql + '  SELECT d.DeviceName ''設備'', i.PlateNumber ''車牌號'', dbo.dateformatter(i.Time,''dd-MM-yyyy HH:mm:ss'') Time, case i.OpenDoor when 1 then ''已開閘'' else ''未開閘'' end ''開閘狀態'', c.id';
	set @sql = @sql + '  ,i.enter,i.EventInfoID,i.Guid,lp.PassType,i.PlateNumber,ExceptionType,car_Parking_type,type,''\''+AttachImageUrl as AttachImageUrl,''\''+PicImageUrl as PicImageUrl ';
	set @sql = @sql + ' FROM';
	--if(datediff(DAY,@startdate,getdate())>90)
	--   begin
	--       set @sql = @sql + ' (select PlateNumber,DeviceID,Time,OpenDoor,AttachImageUrl,PicImageUrl,enter,EventInfoID,Guid,ExceptionType,type,CreateDate from [tb_DeviceUserEventInfo] with(nolock) where PlateNumber like ''%'+@platenumber+'%'' and [Time]>='''+convert(varchar(max),@startdate,120)+''' and  [Time]<='''+convert(varchar(max),@enddate,120)+''' and  (ExceptionType>0 or lotid = 3)';
	--	   set @sql = @sql + ' union all';
	--	   set @sql = @sql + ' select PlateNumber,DeviceID,Time,OpenDoor,AttachImageUrl,PicImageUrl,enter,EventInfoID,Guid,ExceptionType,type,CreateDate from [tb_DeviceUserEventInfo_old] with(nolock) where PlateNumber like ''%'+@platenumber+'%'' and [Time]>='''++convert(varchar(max),@startdate,120)+''' and  [Time]<='''+convert(varchar(max),@enddate,120)+ ''' and  (ExceptionType>0 or lotid = 3)) i';
	--   end
	--else
	--   begin
		set @sql = @sql + '  (select PlateNumber,DeviceID,Time,OpenDoor,AttachImageUrl,PicImageUrl,enter,EventInfoID,Guid,ExceptionType,type,CreateDate from [tb_DeviceUserEventInfo_top] with(nolock)  where PlateNumber like ''%'+@platenumber+'%'' and [Time]>='''++convert(varchar(max),@startdate,120)+''' and  [Time]<='''+convert(varchar(max),@enddate,120)+ ''' and  ExceptionType>0 ) i';
	  --end
	
	set @sql = @sql + '  left join tb_DeviceUser d  with(nolock) on i.DeviceID=d.DeviceID '
	set @sql = @sql + '  left join BT_Car c with(nolock) on c.car_code=i.PlateNumber and card_starttime<= getdate() and card_endtime>= getdate() and isnull(card_status,0) = 0 '
	set @sql = @sql + '  left join tb_LotPass lp on lp.ID=d.LotID'
	set @sql = @sql + '  ';
	if(@exceptiontype = 0 )
	   begin
			set @sql = @sql + ' where ExceptionType=1 or  ExceptionType=2 or ( ExceptionType=3 and not exists( select 1 from tb_DeviceUserEventInfo  with(nolock) where ExceptionType=0  and  DATEDIFF(SS,CreateDate,i.CreateDate)<=3 and  DATEDIFF(SS,CreateDate,i.CreateDate)>=0 )) ';
	   end
	else if(@exceptiontype = 1)
	  begin
	     set @sql = @sql + ' where ExceptionType=1 or  ExceptionType=2  ';
	  end
	else if(@exceptiontype = 3)
	  begin
	       set @sql = @sql+ ' where  ExceptionType=3 and not exists( select 1 from tb_DeviceUserEventInfo  with(nolock) where ExceptionType=0  and  DATEDIFF(SS,CreateDate,i.CreateDate)<=3 and  DATEDIFF(SS,CreateDate,i.CreateDate)>=0 ) ';
	  end
	set @sql = @sql + '  ) A';
	set @sql = @sql + ' select * from #temp ';	
	set @sql = @sql + ' order by [時間 Time] desc  offset '+convert(varchar(max),(@page-1)*@row)+'  row fetch next '+convert(varchar(max),@row)+' rows only '
	set @sql = @sql + ' select count(1) from #temp';



  exec(@sql);
		 
		  

END


