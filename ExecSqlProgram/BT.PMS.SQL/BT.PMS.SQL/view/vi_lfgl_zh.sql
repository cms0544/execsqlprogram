if(exists(select 1 from sysobjects where id = object_id('vi_lfgl_zh')))
   begin
      drop view vi_lfgl_zh
   end
/****** Object:  View [dbo].[vi_lfgl_zh]    Script Date: 2021/6/1 10:08:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

  create view [dbo].[vi_lfgl_zh]
  as 
		SELECT distinct  QRCode.[qrcode_id],id as ownerid,isnull(FC_Cell.name,'') as cellname --被訪單元或APP申請者信息
		
		,ResonType.visiting_reason as 'reason' --來訪原因
		, convert(varchar(16),QRCode.begin_time,120)+'<br/>'+convert(varchar(16),QRCode.end_time,120) as lfsj --預約來訪時間範圍
        ,case when visitor='undefined' then '' else visitor end as visitor --來訪者
	    ,case when visitor_phone='undefined' then '' else visitor_phone end as visitor_phone --來訪者電話
		,QRCode.id_card
		,QRCode.remark
		,QRCode.created_terminal--創建終端（比如APP，還是WEB後臺
		,begin_time
		,end_time
	    ,QRCode.opertor_id
	   
	    ,case when ISNULL([cancel],0)=1 then -1 --已取消
			when datediff(SECOND,[end_time],GETDATE())>0   then 0--已過期
			when datediff(SECOND,[begin_time],GETDATE())>0 then 1--已啟用
			else 2 --未生效 
		end as [qrcode_status],
		QRCode.createdTime as inserttime,
		QRCode.created_owner_id,
		OwnerRelation.[zh_owner_id],
		[ZH_Owner].alias as owneralias,
		[ZH_Owner].name as ownername,
		[ZH_Owner].LXDH as ownerlxdh,
		isnull(QRCode.floor_unitvisited,isnull(FC_Cell.name,'')) as floor_unitvisited,
		convert(varchar(16),rdEvent.sys_EventTime,120) as sjdfsj --實際來訪時間


     FROM[dbo].[BT_OpenDoor_QRCode] QRCode with(nolock) 
	 LEFT JOIN dbo.FC_Cell   with(nolock) ON QRCode.fc_cell_id=FC_Cell.cellid
	 LEFT JOIN [dbo].[BT_OpenDoor_QRCode_Visiting_Reason_Type] ResonType with(nolock)  on ResonType.visiting_reason_typeid = QRCode.visiting_reason_typeid
     Left join [dbo].[YH] with(nolock) on YH.ui_id=QRCode.opertor_id

	 LEFT JOIN (
		 SELECT qrcode_id,zh_owner_id FROM (
			SELECT  ROW_NUMBER() OVER (partition BY qrcode_id order by zh_owner_id) as rn, qrcode_id,zh_owner_id FROM [dbo].[BT_OpenDoor_QRCode_OwnerRelation] WHERE zh_owner_id>0  
		 ) aa  where rn=1
	 ) OwnerRelation ON  QRCode.[qrcode_id]=OwnerRelation.[qrcode_id] --AND ISNULL(QRCode.opertor_id,'')!=''
	 left join (select min(sys_EventTime) as sys_EventTime,sys_CardNO from BT_sys_RawDataLogForReader group by sys_CardNO) as rdEvent on rdEvent.sys_CardNO = QRCode.cardid 
	 LEFT JOIN [dbo].[ZH_Owner] WITH(NOLOCK) ON ZH_Owner.id=OwnerRelation.[zh_owner_id]


GO
