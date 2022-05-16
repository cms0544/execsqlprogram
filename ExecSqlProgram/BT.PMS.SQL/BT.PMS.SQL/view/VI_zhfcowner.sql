if(exists( select 1 from sysobjects where  id=object_id(N'VI_zhfcowner') )) drop  view [dbo].[VI_zhfcowner]
GO

/****** Object:  View [dbo].[VI_zhfcowner]    Script Date: 2021/4/28 15:22:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[VI_zhfcowner]
as 
(
select STUFF((select ',' + lgname+'#'+dyname+'#'+cellname from (
 select lgname,dyname,cellname,id from ZH_Owner a 
 left join View_ZHFCLPInfo b on a.ID = b.ownerid
) as aa where  aa.id =owners.id for xml path('')),1,1,'') as cellname,
STUFF((select ',' + cellname from (
 select lgname,dyname,cellname,id from ZH_Owner a 
 left join View_ZHFCLPInfo b on a.ID = b.ownerid
) as bb where  bb.id =owners.id for xml path('')),1,1,'') as cellname2,
STUFF((select ',' + lpname from (
 select lpname,id from ZH_Owner a 
 left join View_ZHFCLPInfo b on a.ID = b.ownerid
) as aa where  aa.id =owners.id for xml path('')),1,1,'') lpname,id
from
(
select id from ZH_Owner a 
group by a.id
) as owners
group by id
)


GO

