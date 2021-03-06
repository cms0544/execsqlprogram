if(exists(select 1 from sysobjects where id = object_id('sp_SaveCouponWhitelist')))
   begin
        drop PROCEDURE [dbo].[sp_SaveCouponWhitelist]
   end
/****** Object:  StoredProcedure [dbo].[sp_SaveCouponWhitelist]    Script Date: 2021/6/16 17:40:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Mason>
-- Create date: <2021-01-08,,>
-- Description:	<新增或者修改臨時白名單,,>
-- =============================================
create PROCEDURE [dbo].[sp_SaveCouponWhitelist]
	-- Add the parameters for the stored procedure here
	@id int,
	@name varchar(max)='',
	@type int = 1,
	@param  varchar(20)= '0',
	@enable int = 0,
	@startdate varchar(max) ='',
	@expiredate varchar(max) = '',
	@defaultID int = 0,
	@plateNumber varchar(max),
	@degree int = 1
AS
BEGIN


	if(isnull(@startdate,'')='' )
	   begin
	       set @startdate = convert(varchar(19),getdate(),120);
	   end

	if(isnull(@expiredate,'')='')
	  begin
	      set @expiredate = convert(varchar(10),getdate(),120);
	  end 

	  if(@name = '' )
	     begin

		   set @name = '臨時優惠券';
		 end

	  set @plateNumber = Upper(replace(replace(replace(REPLACE(@plateNumber,'O','0'),'I','1'),'Q','0'),' ',''))

	if(exists(select 1 from tb_CouponWhitelist where plateNumber = @plateNumber and isnull(isdelete,0) = 0 and [expiredate] >getdate() and isnull(id,0)! =@id))
	  begin
			select '車牌已重複,請重新再入'
			return;
	  end

	if(@id = 0)
	   begin
	   
	       insert into tb_CouponWhitelist([Name] ,[Type],[Param] ,[Enable],[Startdate],[Expiredate],[DefaultID],[PlateNumber],[degree],[LastAmendUser],[LastAmendTime])
	      select @name,@type,@param,@enable,@startdate,@expiredate,0,@platenumber,@degree,null,getdate()

	   end
	 else
	   begin
	      update tb_CouponWhitelist set name=@name,[type]= @type,[param]=@param,[Enable]=@enable,Startdate=@startdate,Expiredate=@expiredate,DefaultID=@defaultID,PlateNumber=@plateNumber,degree=@degree,LastAmendTime= getdate()  where id = @id;
	   end


	   select 1

END

