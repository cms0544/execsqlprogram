if(exists(select 1 from sysobjects where id = object_id('V_ZH_Members')))
  begin
      drop view V_ZH_Members
  end

/****** Object:  View [dbo].[V_ZH_Members]    Script Date: 2021/7/26 12:06:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




create VIEW [dbo].[V_ZH_Members] 
AS

SELECT distinct zhm.[id]
      ,zhm.[ownerid]
      ,zhm.[name]
      ,zhm.[birdate]
      ,zhm.[sex]
      ,zhm.[ration]
      ,zhm.[zjlx]
      ,zhm.[zjhm]
      ,zhm.[xl]
      ,zhm.[memo]
      ,zhm.[gzdw]
      ,zhm.[lxdh] as [lxdh]
      ,zhm.[zpurl]
      ,zhm.[jtsf]
	  ,zhm.[alias]
      ,zhm.[usercardid]
      ,zhm.[app_bind_guid]
	  ,zhm.[deleted]
	  ,zhm.[CODE]
	  ,vcm.[col_OctopusNo]
	  ,zhm.[col_QrcodeNo]
	  ,isnull(zhm.[authorizer],'') as [authorizer]
	  ,isnull(zhm.[authorizedperson],'') as [authorizedperson]
	  ,zhm.[authorizedfrom] as [authorizedfrom]
	  ,zhm.[authorizedend] as [authorizedend]
	  ,vcm.col_cardNo              as card_ID
	  ,isnull(zhm.kmbm,'')         as card_kmbm
	  ,isnull(zhm.whatapps,'')	   whatapps
	  ,isnull(zhm.zjstatus,zmc.col_card_status)	   zjstatus
	  ,isnull(zhm.feestatus,0)	   feestatus
	  ,isnull(zhm.feevalue,zmc.col_card_fee)	   feevalue
	  ,isnull(zhm.jjlxr,'')              jjlxr
	  ,isnull(zhm.jjlxrmobile,'')        jjlxrmobile
	  ,isnull(zhm.enname,'')        enname
	  ,isnull(CM.col_Leave_Reason,zmc.col_leave_reason)	   col_Leave_Reason
	  ,isnull(ms.col_state,zmc.col_state)                as card_state
	  ,isnull(CM.Col_DateStart,zmc.col_datestart)            as card_DateStart
	  ,isnull(CM.Col_DateEnd,zmc.col_dateend)             as card_DateEnd
      --,BO.[zh_owner_id]
      ,BO.[bt_app_user_uid]
      ,BO.[bt_app_user_name]      
      ,zhm.[alias]                  as app_alias
      ,BO.[created_time]            as app_created_time
      ,BO.[updated_time]            as app_updated_time
      --,BO.[deleted]
      --,BO.[changedTS]
      ,BO.[is_master]               as app_is_maste
      ,BO.[bt_app_user_mobile]       
      ,BO.[app_permission_type]        
      ,BO.[bind_created_by_appuser] as app_bind_created_by_appuser
      ,BO.[remark]					as app_remark
      ,BO.[bind_created_by_qrcode]  as app_bind_created_by_qrcode
      ,BO.[disabled]				as app_disabled
	  ,sf.name as jtsfname
	  ,dbo.func_GetDistinct(fc.cellnames + ','+ vcm.cellnames,',') as cellnames




  FROM [dbo].[ZH_Members] zhm
  LEFT JOIN [dbo].[BT_APP_BindOwner] BO ON BO.[app_bind_guid]=zhm.[app_bind_guid] 
  LEFT JOIN (select row_number() over (partition by col_userid order by col_id desc) num,a.*  from [BT_col_CardManagement] as a) CM on CM.col_userid = zhm.id and CM.num = 1 
  left join (select max(col_state) col_state,col_userid from VI_CardManagement_Memeber group by col_userid) as ms on ms.col_userid = zhm.id
  left join VI_CardManagement_Memeber as vcm on vcm.col_userid = zhm.id and vcm.col_state = ms.col_state
  left join zh_member_carddefault as zmc on zmc.col_userid = zhm.id
  left join jtsf as sf on sf.id = zhm.jtsf
  left join ZH_Fc as f on f.OWNERID = zhm.ownerid
  left join (
     
		  select distinct stuff((select ','+fc_cell.name from ZH_Fc left join fc_cell on fc_cell.cellid = ZH_Fc.cellid where  ownerid = a.ownerid for xml path('')),1,1,'') as cellnames,ownerid
		  from ZH_Fc as a group by OWNERID

  ) as fc on fc.ownerid = zhm.ownerid
  --and (CM.col_State =1 )
  where isnull(zhm.deleted,0)= 0



GO


