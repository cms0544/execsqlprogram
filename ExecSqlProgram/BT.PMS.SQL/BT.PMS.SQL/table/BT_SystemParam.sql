IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_SystemParam') AND NAME='ParamGroup')   alter table BT_SystemParam add ParamGroup varchar(20);
GO

IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_SystemParam') AND NAME='ParamValueUseHTML')   alter table BT_SystemParam add ParamValueUseHTML bit;
GO

if not exists(select 1 from BT_SystemParam where ParamName='PMS_ISCompany')--光大要求，法律規定不能保存超過多少天的記錄，自動刪除歷史數據
	begin
		insert into BT_SystemParam(ParamName,ParamValue,ParamDesc,ParamLongDesc,Seq)
		select 'PMS_ISCompany',1,'是否是公司','1：表示是公司 0：表示普通的物業系統',null
	end

if not exists(select 1 from BT_SystemParam where ParamName='PMS_AutoDelRawDataLogBeforeDays')--光大要求，法律規定不能保存超過多少天的記錄，自動刪除歷史數據
	begin
		 insert into BT_SystemParam([ParamName],[ParamValue],[ParamDesc],[ParamLongDesc],[Seq],[ParamGroup]) select 'PMS_AutoDelRawDataLogBeforeDays',31,'是否自動刪除多少天前的打卡記錄（法律問題）','是否自動刪除多少天前的打卡記錄（法律問題）',null,null
	end


if not exists(select 1 from BT_SystemParam where ParamName='PMS_isHideyztsjy')--是否暂时隐藏投诉建议
begin
	 insert into BT_SystemParam([ParamName],[ParamValue],[ParamDesc],[ParamLongDesc],[Seq],[ParamGroup]) select 'PMS_isHideyztsjy',1,'是否暂时隐藏投诉建议','是否暂时隐藏投诉建议',null,null
end

--if not exists(select 1 from BT_SystemParam where ParamName='PMS_isHideyztsjy')--是否暂时隐藏投诉建议
--begin
--	 insert into BT_SystemParam select 'PMS_isHideyztsjy',1,'是否暂时隐藏投诉建议','是否暂时隐藏投诉建议',null
--end

--if not exists(select 1 from BT_SystemParam where ParamName='PMS_isHideyztsjy')--是否暂时隐藏投诉建议
--begin
--	 insert into BT_SystemParam([ParamName],[ParamValue],[ParamDesc],[ParamLongDesc],[Seq],[ParamGroup]) select 'PMS_isHideyztsjy',1,'是否暂时隐藏投诉建议','是否暂时隐藏投诉建议',null,null
--end


---****************begin OpenDoorQRCode組

UPDATE [dbo].[BT_SystemParam] SET ParamGroup='OpenDoorQRCode',[Seq]=99,[ParamDesc]=N'開門QRCode-大華解密密鈅'   WHERE [ParamName]='PMS_Open_Door_QRCode_KEY'
UPDATE [dbo].[BT_SystemParam] SET ParamGroup='OpenDoorQRCode',[Seq]=0 ,[ParamDesc]=N'開門QRCode-是否禁用'       WHERE [ParamName]='PMS_Community_DisableOpenDoorQRCode'
UPDATE [dbo].[BT_SystemParam] SET ParamGroup='OpenDoorQRCode',[Seq]=1 ,[ParamDesc]=N'開門QRCode-最大有效小時數' WHERE [ParamName]='PMS_Open_Door_QRCode_Max_Valid_Hour'

if not exists(select * from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_10Length')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup])
				 VALUES
					   ('PMS_Open_Door_QRCode_10Length'
					   ,N'0'
					   ,N'開門QRCode-生成10位長度的臨時卡號'
					   ,N'格式“是否啟用|卡號前綴”，比如“1|33”表示啟用，卡號前綴為33，后面八位為自增數字'
					   ,1
					   ,'OpenDoorQRCode')
	end
else
	begin
	       UPDATE BT_SystemParam SET [ParamLongDesc]=N'格式“是否啟用(0或者1)|卡號前綴”，比如“1|39”表示啟用，卡號前綴為39，后面八位為自增數字'  where ParamName='PMS_Open_Door_QRCode_10Length'
	end

if not exists(select 1 from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_HideExpired')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup])
				 VALUES
					   ('PMS_Open_Door_QRCode_HideExpired'
					   ,N''
					   ,N'開門QRCode-列表是否隱藏失效的QRCode'
					   ,N'開門QRCode，列表不顯示已經失效的QRCode，0-表示顯示，1-表示不顯示'
					   ,2
					   ,'OpenDoorQRCode')
	end

if not exists(select 1 from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_Title')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup])
				 VALUES
					   ('PMS_Open_Door_QRCode_Title'
					   ,N''
					   ,N'開門QRCode-標題'
					   ,N'開門QRCode第一行顯示文字，比如位置或大廈名稱'
					   ,3
					   ,'OpenDoorQRCode')
	end


	update BT_SystemParam set ParamValueUseHTML = 1 where ParamName = 'PMS_Open_Door_QRCode_Title'

if not exists(select 1 from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_Title_Logo')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup])
				 VALUES
					   ('PMS_Open_Door_QRCode_Title_Logo'
					   ,N''
					   ,N'開門QRCode-標題LOGO路徑'
					   ,N'開門QRCode標題下的文字LOGO，圖片放到網站下，比如：~/images/qrcode/qrcode_title.png （注：如果沒有設置就不顯示'
					   ,4
					   ,'OpenDoorQRCode')
	end

if not exists(select 1 from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_Logo')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup])
				 VALUES
					   ('PMS_Open_Door_QRCode_Logo'
					   ,N''
					   ,N'開門QRCode-LOGO路徑'
					   ,N'開門QRCode中間個性LOGO，圖片放到網站下，比如：~/images/qrcode/qrcode_code.png（注：如果沒有設置就不顯示'
					   ,5
					   ,'OpenDoorQRCode')
	end
	 
if not exists(select 1 from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_DoorList_Hidden')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup])
				 VALUES
					   ('PMS_Open_Door_QRCode_DoorList_Hidden'
					   ,N'0'
					   ,N'開門QRCode-不顯示可開啟門明細'
					   ,N'開門QRCode,不顯示可開啟門明細，0-表示顯示，1-表示不顯示'
					   ,6
					   ,'OpenDoorQRCode')
	end
	
if not exists(select 1 from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_EmailSubject')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup]
					   ,ParamValueUseHTML)
				 VALUES
					   ('PMS_Open_Door_QRCode_EmailSubject'
					   ,N''
					   ,N'開門QRCode-發郵件標題'
					   ,N'開門QRCode,發郵件標題'
					   ,7
					   ,'OpenDoorQRCode'
					   ,0)
	end
 
if not exists(select 1 from BT_SystemParam where ParamName='PMS_Open_Door_QRCode_EmailBody')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup]
					   ,ParamValueUseHTML)
				 VALUES
					   ('PMS_Open_Door_QRCode_EmailBody'
					   ,N''
					   ,N'開門QRCode-發郵件模板'
					   ,N'開門QRCode,發郵件模板,其中{{TAG:QRCODE}}替換圖片的位置'
					   ,8
					   ,'OpenDoorQRCode'
					   ,1)
	end

---****************begin OpenDoorQRCode組

if not exists(select 1 from BT_SystemParam where ParamName='PMS_Feedback_ShowStaticHtml')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup]
					   ,ParamValueUseHTML)
				 VALUES
					   ('PMS_Feedback_ShowStaticHtml'
					   ,N''
					   ,N'投訴建議-使用靜態HTML'
					   ,N'注：非空內容表示啟用'
					   ,1
					   ,'PMS_Feedback'
					   ,1)
	end


---****************PMS_Feedback_ShowStaticHtml_Web  web建议反馈
	
if not exists(select 1 from BT_SystemParam where ParamName='PMS_Feedback_ShowStaticHtml_Web')
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup]
					   ,ParamValueUseHTML)
				 VALUES
					   ('PMS_Feedback_ShowStaticHtml_Web'
					   ,N''
					   ,N'投訴建議-使用靜態HTML-Web'
					   ,N'注：非空內容表示啟用'
					   ,1
					   ,'PMS_Feedback'
					   ,1)
	end




---*******************

---****************begin '業主 家庭成員組

if not exists(select 1 from BT_SystemParam where ParamName='ZH_OWNER_Member_Code_Need_HandInput')--家庭成員編號是否要手動輸入
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup]
					   ,ParamValueUseHTML)
				 VALUES
					   ('ZH_OWNER_Member_Code_Need_HandInput'
					   ,N'0'
					   ,N'業主-家庭成員編號是否手動必填'
					   ,N'家庭成員編號是否要手動輸入，1-表示要手動輸入，其它值為否。（注：不必手動填，那麼會動態生成。且手機APP創建不顯示成員編號輸入'
					   ,1
					   ,'ZH_OWNER'
					   ,0)
	end


if not exists(select 1 from BT_SystemParam where ParamName='ZH_OWNER_Member_Code_Prefix')--家庭成員編號自動生成的時候的前綴
	begin
			INSERT INTO [dbo].[BT_SystemParam]
					   ([ParamName]
					   ,[ParamValue]
					   ,[ParamDesc]
					   ,[ParamLongDesc]
					   ,[Seq]
					   ,[ParamGroup]
					   ,ParamValueUseHTML)
				 VALUES
					   ('ZH_OWNER_Member_Code_Prefix'
					   ,N'ID'
					   ,N'業主-家庭成員編號前綴'
					   ,N'家庭成員編號前綴'
					   ,1
					   ,'ZH_OWNER'
					   ,0)
	end

---****************begin 家庭成員組



if not exists(select 1 from BT_SystemParam where ParamName='PMS_limitMaxFK')--是否限制最大发卡数量   1 直接限制  0 只是提示
begin
	 insert into BT_SystemParam([ParamName],[ParamValue],[ParamDesc],[ParamLongDesc],[Seq],[ParamGroup]) select 'PMS_limitMaxFK',1,'是否限制最大发卡数量','是否限制最大发卡数量',null,null
end


if not exists(select 1 from BT_SystemParam where ParamName='PMS_IsDeleteCodeCanUse')--是刪除的成員編號是否可以複用
begin
	 insert into BT_SystemParam([ParamName],[ParamValue],[ParamDesc],[ParamLongDesc],[Seq],[ParamGroup]) select 'PMS_IsDeleteCodeCanUse',0,'是否刪除的成員編號可以複用','是否刪除的成員編號可以複用',null,null
end


