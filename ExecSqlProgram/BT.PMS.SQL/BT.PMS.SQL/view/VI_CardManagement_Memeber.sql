IF exists(select table_name from information_schema.views where table_name ='VI_CardManagement_Memeber') DROP VIEW [dbo].[VI_CardManagement_Memeber];
GO
/****** Object:  View [dbo].[VI_CardManagement_Memeber]    Script Date: 2021/4/27 9:39:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create view  [dbo].[VI_CardManagement_Memeber]
as 

select  stuff( (select isnull( ','  +col_cardid,'') from [BT_col_CardManagement] as b where b.col_userid = a.col_userid and b.col_state = a.col_state and isnull(col_cardtype,0) = 0    for xml path('')),1,1,'') as col_cardNo,stuff( (select isnull( ','  +col_cardid,'') from [BT_col_CardManagement] as b where b.col_userid = a.col_userid and b.col_state = a.col_state  and isnull(col_cardtype,0) = 12    for xml path('')),1,1,'') as col_OctopusNo,col_userid,col_state as col_state,stuff(( select distinct ','+ convert(nvarchar(max),cc.name) from BT_col_CardManagement_FCCELL as aa left join BT_col_CardManagement as bb on aa.cardid = bb.col_ID left join fc_cell as cc on cc.cellid = aa.cellid where bb.col_UserID = a.col_userid  for xml path('')),1,1,'') as cellnames 
from [BT_col_CardManagement] as a
group by col_userid,col_state


GO
