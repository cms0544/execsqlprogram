IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'sp_Del_Member') and xtype='P')  DROP PROCEDURE [dbo].[sp_Del_Member]
GO
/****** Object:  StoredProcedure [dbo].[sp_Del_Member]    Script Date: 2021/4/23 11:57:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-03-14,,>
-- Description:	<删除成員,,>
-- =============================================
create PROCEDURE [dbo].[sp_Del_Member]
	@id nvarchar(max)= '0' 
AS
BEGIN

   --   if(exists(select 1 from zh_members where nodeleted = 1 and id = @id))
	  --   begin
		 --        select '業主不能删除'
		 --end
   --   else
	  --   begin

	  select col as id into #ids from fn_split_ToTable(@id,',')
	    create table #temp
	  (
	      result int 
	  )

	  create table #BT_col_CardManagement
	    (
		   col_id int
		)
	  declare @userid int = 0;
	  while(exists(select 1 from #ids))
	     begin
	          
			    select top 1 @userid = id from #ids

				insert into #BT_col_CardManagement
		        select col_id  from BT_col_CardManagement where col_userid = @userid 
	
				declare @cardid int;
				while(exists(select 1 from #BT_col_CardManagement))
				   begin
					  select top 1 @cardid = col_id from #BT_col_CardManagement

					  insert into #temp
					  exec DeleteUserCard @cardid
			
					  delete from #BT_col_CardManagement where col_id = @cardid
			
				   end


				   update BT_APP_BindOwner set deleted = 1 where app_bind_guid in (select app_bind_guid from ZH_Members where id =  @userid)
				   update ZH_Members  set deleted = 1,usercardid = 0,app_bind_guid = CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER) where id = @userid
			
		    delete from #ids where id = @userid
		 end



	 
	    select '删除成功'
END
