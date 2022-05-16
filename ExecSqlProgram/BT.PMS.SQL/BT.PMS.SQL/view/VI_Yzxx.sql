if(exists (select 1 from sysobjects where id = object_id('VI_Yzxx')))
   begin
      drop view [dbo].[VI_Yzxx]
   end
go
/****** Object:  View [dbo].[VI_Yzxx]    Script Date: 2021/6/4 20:13:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create view [dbo].[VI_Yzxx]
as
	 select distinct   isnull(d.nodeleted,0) as nodeleted,isnull(vc.cellname,fce.name)  as [單位],bc.col_cardid as 卡號,d.enname as 英文姓名,d.name as 中文姓名,d.sex as 性別,d.code as 編號,c.name as [身份],d.authorizer as [授權人(業主)],d.authorizedperson as [獲授權人],case when d.authorizedfrom is null then null else convert(varchar(10),d.authorizedfrom,120) end [授權期(起)],case when d.authorizedend is null then null else convert(varchar(10),d.authorizedend,120) end  as [授權期(終)],zj.name as [新證 / 轉名 / 補領 (遺失/ 壞卡)],convert(varchar(10),isnull(bc.col_CreateTime,zmc.col_CreateTime),120) as '申請日期',case when isnull(bc.col_card_fee,isnull(zmc.col_card_fee,0)) = 0 then '免費' else convert(varchar(max),isnull(bc.col_card_fee,isnull(zmc.col_card_fee,0))) end  as '費用',convert(varchar(10),isnull(bc.col_DateStart,zmc.col_DateStart),120) as '取卡日期',convert(varchar(10),isnull(bc.col_DateEnd,zmc.col_DateEnd),120) as '停用日期',isnull(bc.col_Leave_Reason,zmc.col_Leave_Reason) as '停用原因',replace(d.lxdh,'+852','') as '電話',d.whatapps as 'whatsapp',iif(d.nodeleted=1, yzdzdw,'') as '業主地址(單位/樓層/座數)',iif(d.nodeleted=1,yzdzds,'')  as '業主地址(大廈/屋苑)',iif(d.nodeleted=1,yzdzjd,'') as '業主地址(街道)',iif(d.nodeleted=1,yzdzdq,'') as '業主地址(地區)',isnull(iif(d.nodeleted=1,a.jjlxrxm,d.jjlxr),'') as '(業主)緊急聯繫人',replace(iif(d.nodeleted=1,a.JJLXRDH,d.jjlxrmobile),'+852','') as '緊急聯絡人電話' ,case when isnull(bc.col_cardtype,0) = 0 then '普通卡'when isnull(bc.col_cardtype,0) = 12 then '八達通' end as '卡類型(普通卡/八達通)',d.memo as '備註',iif(d.nodeleted=1,fce.maxfk,null)  as '最大發卡數量',iif(d.nodeleted=1,a.email,'') as email,d.ownerid,vc.lgid,vc.lpid,vc.dyid,vc.cellid,c.id as jtsfid,col_UserAddress as '用户位置',isnull(nullif(nullif(d.zpurl,'no'),'no.gif'),'')  as '圖片'
	 from ZH_members as d 
	 left join ZH_Owner as a on a.ID = d.ownerid 
	 left join jtsf as c on convert(varchar(max),c.id) = convert(varchar(max), d.jtsf) 
	 left join BT_col_CardManagement as bc on bc.col_userid = d.id   
	 left join BT_col_CardManagement_FCCELL as cf on cf.cardid = bc.col_id 
	 left join zh_fc as  fc  on fc.OWNERID = a.ID 
	 left join View_CellDetailInfo as vc on vc.cellid = isnull(cf.cellid,fc.cellid)
	 left join fc_cell fce on fce.cellid =  isnull(cf.cellid,fc.cellid)
	 left join zjstatus as zj on zj.id = bc.col_card_status 
	 left join zh_member_carddefault as zmc on zmc.col_userid = d.id
	 left join BT_col_UserInfoForReader as bcu on bcu.col_UserID = d.id and bcu.col_CardID = bc.col_CardID and bcu.col_Status = bc.col_State and bcu.col_Status = 1 
	  where  d.deleted = 0   and isnull(d.CODE,'') != ''






GO


