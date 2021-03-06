if(exists (select 1 from sysobjects where id = object_id('sp_exists_CardMember')))
  begin
      drop PROCEDURE sp_exists_CardMember
  end
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--select *from BT_col_CardManagement where col_CardID = '72341357260475150'
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,sp_exists_CardMember '971@@72344574207419158@@@@0@@1@@@@10/05/2021@@10/05/2121@@1@@0@@2045,2082@@10/05/2021',2500 >
-- =============================================
CREATE PROCEDURE sp_exists_CardMember
	-- Add the parameters for the stored procedure here
	@cardstr varchar(max) = '',
	@userid int = 0
AS
BEGIN
	 
	
		select 
		ROW_NUMBER() over (order by(select 1)) as rowindex,
		dbo.[GetSplitOfIndex](col,'@@',5) as col_state,
		dbo.[GetSplitOfIndex](col,'@@',1) as col_id,
		dbo.[GetSplitOfIndex](col,'@@',11) as col_fccellid,
		convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',12), 103),120) as col_createtime
		into #tempcard
		from dbo.fn_split(@cardstr,'##')

		declare @col_cardid int ,@col_fccellid nvarchar(max),@rowindex int,@col_state int =0; 

		create table #BT_col_CardManagement_FCCELL
		(
		    cardid int,
			cellid int
		)
      while(exists(select 1 from #tempcard))
	   begin
	   select top 1  @rowindex = rowindex,@col_cardid = col_id,@col_fccellid = col_fccellid,@col_state = col_state from #tempcard
	   if(@col_state = 1)
	     begin
			delete from #BT_col_CardManagement_FCCELL where cardid = @col_cardid
			/*卡所屬住戶,給限制卡號數量和報表標記用*/
			insert into #BT_col_CardManagement_FCCELL(cardid,cellid)
			select @col_cardid,col
			from dbo.fn_split_ToTable(@col_fccellid,',')
		 end
		delete from #tempcard where rowindex = @rowindex
	 end
													 /**/
--select *from BT_col_CardManagement_FCCELL where cellid = 2082

	 insert into #BT_col_CardManagement_FCCELL 
	 select cardid,cellid from BT_col_CardManagement_FCCELL 
	 where not exists (select 1 from #BT_col_CardManagement_FCCELL where #BT_col_CardManagement_FCCELL.cardid = BT_col_CardManagement_FCCELL.cardid and #BT_col_CardManagement_FCCELL.cellid = BT_col_CardManagement_FCCELL.cellid) 
	  and ( BT_col_CardManagement_FCCELL.cardid in (select col_id from BT_col_CardManagement where col_UserID = @userid and  col_State = 1 ) or cellid in (select cellid from #BT_col_CardManagement_FCCELL))



	 select count(1) as fkcounts,cellid into #maxfk from #BT_col_CardManagement_FCCELL group by cellid


	 select b.name as cellname
	 into #maxcellname
	 from #maxfk as a 
	 left join FC_Cell as b on a.cellid = b.cellid
	 where b.maxfk< a.fkcounts and isnull(b.maxfk,0) !=0

	 declare @cellname nvarchar(max)= '';

	 if(exists( select 1 from #maxcellname ))
	   begin
	           select @cellname = (   select  STUFF((SELECT ','+cellname  FROM #maxcellname with(nolock) where  1=1 for xml path('')),1,1,'') )

	   end

	   select @cellname;
END
GO


