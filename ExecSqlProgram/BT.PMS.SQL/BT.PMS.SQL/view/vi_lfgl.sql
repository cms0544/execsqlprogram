/****** Object:  View [dbo].[vi_lfgl]    Script Date: 2021/4/8 11:16:29 ******/
IF exists(select table_name from information_schema.views where table_name ='vi_lfgl') DROP VIEW [dbo].[vi_lfgl];
GO
/****** Object:  View [dbo].[vi_lfgl]    Script Date: 2021/5/12 15:33:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
create view	[dbo].[vi_lfgl]	
as
(                                                                                                                                                                             
  select id, d.name as zzxq, c.name + '##' + b.name + '##' + e.name as dw, bfr, bfdh, reason, Convert(varchar(16),stime,120) as stime, lfr, lfdh, '' as picdataurl, null as sjdfsj, e.cellid, b.dyid, c.lgid, d.lpid,stime as begin_time,stime as end_time,opendoortime,-1 as sys_Valid ,null as opertor_id,null as [qrcode_id],null created_terminal,null as qrcode_status,null as inserttime,null as sb
    ,0 sys_usertemp,'' sys_isovertemp
	,'' as created_owner_id
  from WY_LFGL a                                                                                                                                                                   
  left join FC_CELL e on e.cellid = a.cellid                                                                                                                                       
  left join FC_Dy b on e.ssdyid = b.dyid                                                                                                                                           
  left join FC_Lg c on c.lgid = b.sslgid                                                                                                                                           
  left join FC_Lp d on d.lpid = c.sslpid                                                                                                                                   
  union all 

 SELECT distinct -2 as id
		,FC_Lp.[name] as xq_name--小區名稱
		,isnull(v2.simplecellname,FC_Lg.name + '##' + FC_Dy.name + '##' + FC_CELL.name) as room --被訪單元或APP申請者信息
		,CASE WHEN ISNULL(QRCode.created_terminal,1)=2 AND ISNULL(QRCode.created_owner_id,'')!='' THEN ZH_Owner.name
			  WHEN ISNULL(QRCode.created_terminal,1)=2 AND ISNULL(QRCode.opertor_id,'')!='' THEN YH.ui_desc
			  ELSE ZH_Owner.name
		END as applicant--主/申請人
		,CASE WHEN ISNULL(QRCode.created_terminal,1)=2 AND ISNULL(QRCode.created_owner_id,'')!='' THEN ZH_Owner.lxdh
			  WHEN ISNULL(QRCode.created_terminal,1)=2 AND ISNULL(QRCode.opertor_id,'')!='' THEN ''
			  ELSE ZH_Owner.lxdh
		END as interviewee--業主/申請人電話
		,ResonType.visiting_reason as 'reason' --來訪原因
		, convert(varchar(16),QRCode.begin_time,120)+'<br/>'+convert(varchar(16),QRCode.end_time,120) as lfsj --預約來訪時間範圍
        ,case when visitor='undefined' then '' else visitor end as visitor --來訪者
	    ,case when visitor_phone='undefined' then '' else visitor_phone end as visitor_phone --來訪者電話
	    , SUBSTRING(sys_PicDataUrl,charindex('/8001',sys_PicDataUrl),len(sys_PicDataUrl)) as picdataurl
	    ,convert(varchar(16),rdEvent.sys_EventTime,120) as sjdfsj --實際來訪時間
		,FC_Cell.cellid as cellid
		,FC_Dy.[dyid]   as dyid
		,FC_Lg.[lgid]   AS  ly_id
		,FC_Lp.[lpid]   AS  xq_id -- cellid	dyid	lgid	lpid
		,begin_time
		,end_time
		,QRCode.opendoortime--手動開門時間
		,sys_Valid 
	    ,QRCode.opertor_id
	    ,QRCode.[qrcode_id]
	    ,QRCode.created_terminal--創建終端（比如APP，還是WEB後臺
	    ,case when ISNULL([cancel],0)=1 then -1 --已取消
			when datediff(SECOND,[end_time],GETDATE())>0   then 0--已過期
			when datediff(SECOND,[begin_time],GETDATE())>0 then 1--已啟用
			else 2 --未生效 
		end as [qrcode_status],
		QRCode.createdTime as inserttime,
		isnull(v.xq_name+'#'+ v.ly_name+'#'+ v.HostName, rdEvent.sys_deviceName) as sb
			,sys_usertemp, case  when isnull(sys_isovertemp,0)=0 then  '正常'  else  '超溫' end   sys_isovertemp
		,QRCode.created_owner_id
     FROM[dbo].[BT_OpenDoor_QRCode] QRCode with(nolock) 
	 LEFT JOIN dbo.FC_Cell   with(nolock) ON QRCode.fc_cell_id=FC_Cell.cellid
	 LEFT join dbo.FC_Dy	 with(nolock) ON FC_Cell.ssdyid=FC_Dy.[dyid]
	 LEFT JOIN [dbo].[FC_Lg] with(nolock) ON FC_Dy.sslgid=FC_Lg.[lgid]
	 LEFT JOIN [dbo].[FC_Lp] with(nolock) ON FC_Lg.sslpid=FC_Lp.[lpid]
	 LEFT JOIN [dbo].[BT_OpenDoor_QRCode_Visiting_Reason_Type] ResonType with(nolock)  on ResonType.visiting_reason_typeid = QRCode.visiting_reason_typeid
     Left join [dbo].[YH] with(nolock) on YH.ui_id=QRCode.opertor_id

	 LEFT JOIN (
		 SELECT qrcode_id,zh_owner_id FROM (
			SELECT  ROW_NUMBER() OVER (partition BY qrcode_id order by zh_owner_id) as rn, qrcode_id,zh_owner_id FROM [dbo].[BT_OpenDoor_QRCode_OwnerRelation] WHERE zh_owner_id>0  
		 ) aa  where rn=1
	 ) OwnerRelation ON  QRCode.[qrcode_id]=OwnerRelation.[qrcode_id] --AND ISNULL(QRCode.opertor_id,'')!=''
	 LEFT JOIN [dbo].[ZH_Owner] WITH(NOLOCK) ON ZH_Owner.id=OwnerRelation.[zh_owner_id]
	 
	 --打卡信息
     left join BT_sys_RawDataLogForReader rdEvent with(nolock) on rdEvent.sys_CardNO = QRCode.cardid 
	   left join V_HostDevice as v on rdEvent.sys_ReaderID = v.HostDeviceID  
	   left join VI_col_CardManagement as v2 on  v2.col_ownerid =  ZH_Owner.id and v2.col_cardid = rdEvent.sys_CardNO
   
   union all
  select -1,v.lpname as buildname,isnull(v.simplecellname,'') as lyname,isnull(nullif(sys_username,''),e.name),isnull(nullif(e.lxdh,''),d.lxdh),'',null,a.sys_CardNO,isnull(nullif(e.lxdh,''),d.lxdh), SUBSTRING(sys_PicDataUrl,charindex('/8001',sys_PicDataUrl),len(sys_PicDataUrl)) as picdataurl,convert(varchar(16),sys_EventTime,120),0,0,vc.lpid,vc.lgid,null,null,null,sys_Valid ,null,null as [qrcode_id],null as created_terminal,null as qrcode_status,null as inserttime,isnull(  a.sys_deviceName,HD.HostName) as sb
     ,a.sys_usertemp,case  when isnull(a.sys_isovertemp,0)=0 then  '正常'  else  '超溫' end   sys_isovertemp
     ,d.id  as created_owner_id
	from BT_sys_RawDataLogForReader a 
	left join zh_members as e on e.id =  a.sys_userid
	left join ZH_Owner d on d.id = e.ownerid 
	 LEFT JOIN[dbo].[V_HostDevice] HD on a.sys_ReaderID = HD.[HostDeviceID] 
	   left join VI_col_CardManagement as v on  v.col_userid =  e.id and v.col_cardid = a.sys_CardNO
	  left join View_CellDetailInfo as vc on vc.cellid = v.col_FCCellID
    where sys_CardNo not in (select cardid from[BT_OpenDoor_QRCode]) 

   union all
   
		select 0
			,HD.[xq_name]      --小區名稱
			,APP_BindOwner.dw as lgcellname  --被訪單元或APP申請者信息
			,APP_BindOwner.app_alias as  applicant--申請人
			,APP_BindOwner.bt_app_user_mobile 
			,''
			,''
			,''
			,''
			,capture_img_url
			,case 
				when app_upload_delay = 1
					then app_open_time
				else open_time
				end
			,0
			,0
			,ly_id
			,xq_id
			,null
			,null
			,null
			,1
			,null as opertor_id
			,null as [qrcode_id]
			,null as created_terminal
			,null as qrcode_status
			,null as inserttime
			, isnull(HD.xq_name+'#'+ HD.ly_name+'#'+ HD.HostName, '') as sb
			,0 sys_usertemp,'' sys_isovertemp
			,zh_owner_id as created_owner_id
		from [BT_Door_OpenedRecord] as a
		LEFT JOIN [dbo].[V_HostDevice] HD with(nolock) on a.device_id = HD.[HostDeviceID]
		LEFT JOIN (
			 SELECT tmpAPP_BindOwner.[bt_app_user_uid],tmpAPP_BindOwner.app_alias,tmpAPP_BindOwner.bt_app_user_mobile,ZH_Fc.CELLID,FC_Dy.sslgid as lgid,
			 FC_LG.name + '##' + FC_Dy.name + '##' + FC_Cell.name as dw,zh_owner_id
			 FROM BT_APP_BindOwner tmpAPP_BindOwner with (nolock) 
			 INNER JOIN [dbo].[ZH_Fc] with (nolock)  ON tmpAPP_BindOwner.zh_owner_id=ZH_Fc.OWNERID
			 INNER JOIN FC_Cell with (nolock)  on ZH_Fc.CELLID=FC_Cell.cellid
			 INNER JOIN FC_Dy with (nolock)    on FC_Cell.ssdyid=FC_Dy.dyid
			 inner join FC_LG with (nolock) on FC_LG.lgid = FC_Dy.sslgid
			 WHERE ISNULL(tmpAPP_BindOwner.deleted,0)=0
		)  APP_BindOwner ON APP_BindOwner.[bt_app_user_uid] = a.[bt_app_user_uid] AND APP_BindOwner.lgid=HD.ly_id

		LEFT JOIN [dbo].[BT_APP_User] AppUser with (nolock) ON AppUser.[bt_app_user_uid] = a.[bt_app_user_uid]
		
			   		
)






GO


