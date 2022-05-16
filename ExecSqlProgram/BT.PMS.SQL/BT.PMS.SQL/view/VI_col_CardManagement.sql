--USE [BT_PMS]
--GO
if(exists(select 1 from sysobjects where id = object_id('VI_col_CardManagement')))
   begin
       drop view VI_col_CardManagement
   end
/****** Object:  View [dbo].[VI_col_CardManagement]    Script Date: 2021/7/16 12:00:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[VI_col_CardManagement] as (
select a.*,c.CODE as col_usercode,case when isnull(b.cellid,0) =0 then e.lpname else b.lpName end as lpname,fccell.cellname as dy,c.name as ownername,j.name as  jtsf,isnull(d.id,0) as memberid,d.code,simplecellname,fccell.cellid as morecellid,iif(isnull(f.sys_cardid,0)=0,0,1) as downloadstatus
from BT_col_CardManagement a
left join ZH_Members d on a.col_UserID = d.id
left join ZH_Owner as c on d.ownerid=c.ID
left join View_ZHFCLPInfo b on a.col_UserID =d.ownerid and isnull(a.col_FCCellID,0)=isnull(b.cellid,0)
left join (
   select stuff(
		  (
		   select ',' + convert(varchar(max),c.lgName+'#'+c.DyName+'#'+c.cellname)  from BT_col_CardManagement_FCCELL as b
		   left join View_CellDetailInfo as c on c.cellid = b.cellid
		   where cardid = A.cardid  for xml path('')
		   ),
		  1,
		  1,
		  '') as cellname,
		  stuff(
		  (
		   select ',' + c.name  from BT_col_CardManagement_FCCELL as b
		   left join FC_Cell as c on c.cellid = b.cellid
		   where cardid = A.cardid  for xml path('')
		   ),
		  1,
		  1,
		  '') as simplecellname,
		  stuff(
		  (
		   select ',' + convert(varchar(max),b.cellid)  from BT_col_CardManagement_FCCELL as b
		   where cardid = A.cardid  for xml path('')
		   ),
		  1,
		  1,
									'') as cellid,cardid
								from BT_col_CardManagement_FCCELL as a
								
								 group by cardid

) fccell on fccell.cardid = a.col_ID
left join jtsf j on j.id = d.jtsf
left join VI_zhfcowner e on e.id = c.id
left join (select top 1 sys_cardid from BT_sys_UserDownloadRecord where  sys_IsOK=1 and sys_status = 2 order by sys_CreateTime desc) as f on f.sys_cardid = a.col_cardid
where a.col_UserType=0
)

--初始化数据
--select jtsf.id,a.id as memeberid
--into #ZH_Members
--from  ZH_Members as a
--left join jtsf on jtsf.name = a.jtsf
--where isnull(jtsf.id,0)!=0



--update ZH_Members  set jtsf = #ZH_Members.id
--from #ZH_Members
--where #ZH_Members.memeberid = ZH_Members.id





GO


