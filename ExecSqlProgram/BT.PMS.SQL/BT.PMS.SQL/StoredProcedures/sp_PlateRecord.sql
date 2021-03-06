if(exists(select 1 from sysobjects where id = object_id('sp_PlateRecord')))
   begin
      drop PROCEDURE [dbo].[sp_PlateRecord]
   end
/****** Object:  StoredProcedure [dbo].[sp_PlateRecord]    Script Date: 7/8/2021 9:48:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-02-20,,>
-- Description:	<出入记录,, sp_PlateRecord '2021-03-22 11:40','2021-03-22 11:45','','','','','0','',0,50>
-- =============================================
create PROCEDURE [dbo].[sp_PlateRecord]
	-- Add the parameters for the stored procedure here
	@start varchar(max)='2021-02-19',
	@end varchar(max) = '2021-02-20',
	@platenumber varchar(max) = '',
	@username varchar(max) = '',
	@code varchar(max) ='',
	@deviceid varchar(max)='',
	@car_Parking_type varchar(max) = '',
	@cartype varchar(max) ='',
	@pageindex int =1,
	@pagesize int =20


AS
BEGIN
	declare @sql varchar(max) = '';


	set @sql = @sql + ' select DeviceName as ''車道 Lane'', dbo.dateformatter(Time,''dd-MM-yyyy HH:mm:ss'') as ''時間 Time'',PlateNumber as ''車牌號 Plates'',case when id>0 then IIF(car_Parking_type=2,''員工 Employee'',''會員 Member'') else ''訪客 Guest'' end  as ''車主類型 ID Type'', code as ''編號 ID #'',[dbo].[fn_GetCarType](isnull(type,''0'')) as ''車輛類型 Type'',UserCollectName as ''收費類型 Payment'',OpenDoor as ''開閘狀態 Barrier'','+char(13);
	set @sql = @sql + ' ''\''+AttachImageUrl as ''圖片 Capture'',''\''+ PicImageUrl as ''详细圖片 Capture'' '+char(13);
	set @sql = @sql + ' from  '+char(13);
	set @sql = @sql + ' (  '+char(13);
	set @sql = @sql + ' SELECT d.DeviceName, CONVERT(varchar(100), i.Time, 120) ''Time'', case i.OpenDoor when 1 then ''已開閘 Open'' else ''未開閘 Close'' end ''OpenDoor'', c.id,i.AttachImageUrl,i.PicImageUrl '+char(13);
	set @sql = @sql + '  ,i.enter,i.EventInfoID,i.Guid,n.IP,n.Port,n.UserName,n.PassWord,n.DeviceType,d.Channel,l.ParentID,lp.PassType,i.PlateNumber,r.cellid,fc.UserCollectName,car_Parking_type,type,bco.code,d.DeviceID '+char(13);
	set @sql = @sql + ' FROM '+char(13);
	--if(datediff(DAY,@start,getdate())>90)
	--   begin
	--       set @sql = @sql + '(select PlateNumber,DeviceID,Time,OpenDoor,AttachImageUrl,PicImageUrl,enter,EventInfoID,Guid,type from [tb_DeviceUserEventInfo_top] with(nolock) where [Time]<='+@end+ ' and [Time]>= ' +@start +char(13);
 --          set @sql = @sql + ' union all ';
 --          set @sql = @sql + 'select PlateNumber,DeviceID,Time,OpenDoor,AttachImageUrl,PicImageUrl,enter,EventInfoID,Guid,type from [tb_DeviceUserEventInfo_old] with(nolock) where  [Time]<='+@end + ' and [Time]>='+ @start+ ' ) i  '+char(13);

	--   end
	--else 
	--   begin

	      set @sql = @sql + '(select PlateNumber,DeviceID,Time,OpenDoor,AttachImageUrl,PicImageUrl,enter,EventInfoID,Guid,iif(ISNUMERIC(type) = 1,type,0) as type,autoadd,isMain from [tb_DeviceUserEventInfo_top] with(nolock) where  [Time]<= '''+@end+ ''' and [Time]>='''+@start+''' ) i '+char(13);
	   --end


	    set @sql = @sql + ' left join tb_DeviceUser d  with(nolock) on i.DeviceID=d.DeviceID '+char(13);
        set @sql = @sql + ' left join BT_Car c with(nolock) on c.car_code=i.PlateNumber and card_starttime<= getdate() and card_endtime>= getdate() and isnull(card_status,0) = 0  ' +char(13);
        set @sql = @sql + ' left join bt_car_other as bco on isnull(bco.carid,0) = isnull(c.id,0) ' +char(13);
        set @sql = @sql + ' left join tb_DeviceNvr n on n.DeviceID=d.NvrID' +char(13);
        set @sql = @sql + ' left join tb_LotPass lp on lp.ID=d.LotID' +char(13);
        set @sql = @sql + ' left join tb_lot l  on l.LotID=lp.LotID' +char(13);;
        set @sql = @sql + ' left join (select [Guid],OldPlate,ROW_NUMBER() over(partition by [Guid] order by LastAmendTime) num from tb_UpdatePlateNotes  with(nolock)) up on up.Guid=i.Guid and  num=1 ' +char(13);
        set @sql = @sql + ' left join tb_FeeUserCollectRelate r on r.guid=i.Guid' +char(13);               
        set @sql = @sql + ' left join tb_FeeUserCollect fc on fc.id=r.FeeUserCollectid' +char(13);
        set @sql = @sql + ' where 1=1  and autoadd !=2  ' +char(13);

		
		if(@platenumber!='')
		   begin
		        set @sql = @sql + ' and platenumber like ''%'+@platenumber+'%''' +char(13);
		   end

		if(@username!='')
		   begin
		        set @sql = @sql + ' and username like ''%'+@username+'%''' +char(13);
		   end
 
       if(@code!='')
		   begin
		        set @sql = @sql + ' and code like ''%'+@code+'%''' +char(13);
		   end

        if(@deviceid!='' and @deviceid !='0')
		   begin
		        set @sql = @sql + ' and d.deviceid in ('+@deviceid +')'+char(13);
		   end

        if(@car_Parking_type != '-1')
		   begin
		        set @sql = @sql + ' and isnull(c.car_Parking_type,0) = '+@car_Parking_type +char(13);
				if(@car_Parking_type = '0')
				   begin
				      set @sql = @sql + ' and (isnull(i.ismain,0) = 1 or not exists (   select 1 from tb_DeviceUserEventInfo_top as temp with(nolock) where abs(DATEDIFF(ss,i.time,temp.time))<2 and isnull(temp.isMain,0) = 1 and temp.PlateNumber in (select car_code from BT_Car where card_starttime<= getdate() and card_endtime>= getdate() and isnull(card_status,0) = 0 ) ) )';
				   end
		   end



		if(@cartype != '-1')
		   begin
		      if (@cartype = '2')
                    begin
                       set @sql = @sql + ' and isnull([type],0) in (1,10) '+char(13);
                   end
              if (@cartype = '3')
                    begin
                        set @sql = @sql + ' and isnull([type],0) in (2,5,7,8,15,16,17,19,20,21,22) '+char(13);
                   end

              if (@cartype = '1')
                begin
                  set @sql = @sql + ' and isnull([type],0) not in (1,10,2,5,7,8,15,16,17,19,20,21,22 ) '+char(13);
              end

		   end


		     set @sql = @sql + 'order by Time desc '+char(13);
             set @sql = @sql + 'offset ' + convert(varchar(max),((@pageindex) * @pagesize)) + ' row fetch next ' + convert(varchar(max), @pagesize) + ' rows only '+char(13);
             set @sql = @sql + ') a '+char(13);;
             set @sql = @sql + 'order by Time desc '+char(13);


		exec(@sql);

END

