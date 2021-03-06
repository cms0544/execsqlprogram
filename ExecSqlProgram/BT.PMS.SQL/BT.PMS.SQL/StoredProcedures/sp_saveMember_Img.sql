IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'sp_saveMember_Img') and xtype='P')  DROP PROCEDURE [dbo].[sp_saveMember_Img]
GO
/****** Object:  StoredProcedure [dbo].[sp_saveMember_Img]    Script Date: 2021/4/20 15:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-03-28,,>
-- Description:	<上传图片保存路径,,sp_saveMember_Img 'test15',''>
-- =============================================
create PROCEDURE [dbo].[sp_saveMember_Img]
	@code varchar(max),
	@zpurl varchar(max),
	@yzid int =0,
	@selecttype varchar(max)=''
AS
BEGIN

   declare @id int = 0;


   if(@selecttype = 'code')
      begin
	   if(@yzid =0)
		 begin
			 select @id = id from zh_members where code = @code 
		 end
		else
		 begin
			select @id = id from zh_members where code = @code and ownerid =@yzid
		 end
	  end
	else if(@selecttype = 'cardno')
	  begin
	       if(@yzid =0)
			 begin
				 select @id = col_userid from BT_col_CardManagement where col_cardid = @code 
			 end
			else
			 begin
				 select @id = col_userid from BT_col_CardManagement where col_cardid = @code and col_ownerid =@yzid
			 end
	      
	  end

	update zh_members set zpurl = @zpurl where id = @id; 
	declare @tempcardid varchar(max) = '';
	create table #tempid (
	   id int
	)

	select  col_cardid into #bt_col_cardmanagement from bt_col_cardmanagement where col_userid  = @id
	 while(exists(select 1 from #bt_col_cardmanagement))
	   begin
	         select top 1 @tempcardid = convert(varchar(max),col_Cardid )  from #bt_col_cardmanagement

			    
				   insert into #tempid
					exec SaveUserCardInfoForReader @id,@tempcardid,0,1
				--select @tempcardid

			 insert into #tempid
			 exec SaveUserFacePath @code,@tempcardid,@zpurl



			 delete from #bt_col_cardmanagement where col_cardid = @tempcardid 

	   end

	   if(@id = 0)
	     begin
		    select 0 
		 end
		else
		 begin
			select 1
		end
END

