IF NOT EXISTS (select name from syscolumns where id=object_id(N'hk_modu') AND NAME='o_sp') 
alter table hk_modu add o_sp varchar(20)

UPDATE [dbo].[hk_Modu] SET [modu_mc]=N'業主建議/反饋' WHERE [modu_id]=22303;
if(not exists(select 1 from  hk_modu where modu_mc = '警告管理'  ))
   begin
	insert into hk_modu
	select 20000,'警告管理','F',904,'啓用','portal/events/EventSettings.aspx',null,null,null,'標准模塊','','否',0,0,0,0,0,0,0,0,0,0,0,905,'admin',null,'警告管理','',0,0
  end

  if(not exists(select 1 from  hk_modu where modu_mc = '成員信息'  ))
   begin
	insert into hk_modu
	select 9030508,'成員信息','F',223,'啓用','pms2/yzgl/Memeber.aspx',null,null,null,'標准模塊','','否',0,0,'9030508m','9030508d',0,0,0,0,0,0,0,9030508,'admin',null,'成員信息','',0,0
  end
