if(not exists(select 1 from sysobjects where id = object_id('hk_Modu_yz')))
begin
   CREATE TABLE [dbo].[hk_Modu_yz](
	[modu_id] [bigint] NOT NULL primary key identity(1,1),
	[modu_mc] [nvarchar](50) NOT NULL,
	[modu_upid] [bigint] NOT NULL CONSTRAINT [DF_MODU_yz_modu_upid]  DEFAULT ((0)),
	[modu_zt] [varchar](4) NOT NULL CONSTRAINT [DF_MODU_yz_modu_zt]  DEFAULT ('啟用'),
	[modu_wjlj] [varchar](100) NOT NULL CONSTRAINT [DF_MODU_modu_yz_wjlj]  DEFAULT ('#'),
	[modu_ismanage] int not null ,   --0全部  1 業主(管理員)   2 家庭成員  
	[orderid] [numeric](12, 2) NULL,
)
end





if(not exists(select 1 from hk_modu_yz where modu_mc = '建議/反饋' ))
  begin
	insert into hk_modu_yz
	select '服務申請',0,'啟用','',0,1
 end


if(not exists(select 1 from hk_modu_yz where modu_mc = '建議/反饋' ))
  begin
    insert into hk_modu_yz
	select '建議/反饋',1,'啟用','/pms2/yzsq/yztsjy.aspx',0,1
  end


if(not exists(select 1 from hk_modu_yz where modu_mc = '租戶管理' and modu_upid = 0))
  begin
  	insert into hk_modu_yz
	select '租戶管理',0,'啟用','',0,1
 end

if(not exists(select 1 from hk_modu_yz where modu_mc = '租戶管理' and modu_upid != 0))
  begin
	insert into hk_modu_yz
	select '租戶管理',3,'啟用','/pms2/yzgl/Yzxx.aspx',0,1
 end


if(not exists(select 1 from hk_modu_yz where modu_mc = '來訪管理'))
  begin
	insert into hk_modu_yz
	select '來訪管理',3,'啟用','/pms2/bagl/lfgl.aspx',1,12
  end



if(not exists(select 1 from hk_modu_yz where modu_mc = '申請物業服務'))
  begin
	insert into hk_modu_yz
	select '申請物業服務',1,'禁用','/pms2/yzsq/sqwyfw.aspx',0,1
 end

if(not exists(select 1 from hk_modu_yz where modu_mc = '房屋裝修'))
  begin
		insert into hk_modu_yz
		select '房屋裝修',0,'禁用','',0,1
 end

 if(not exists(select 1 from hk_modu_yz where modu_mc = '房屋請修申請' and modu_upid != 0))
  begin
	insert into hk_modu_yz
	select '房屋請修申請',7,'禁用','/pms2/yzsq/fwqxsq.aspx',0,1
  end

   if(not exists(select 1 from hk_modu_yz where modu_mc = '房屋請修申請'  and modu_upid != 0))
  begin
		insert into hk_modu_yz
		select '房屋裝修申請',7,'禁用','/pms2/yzsq/fwzxsq.aspx',0,1
  end

 if(not exists(select 1 from hk_modu_yz where modu_mc = '業委會查詢'  ))
  begin
	insert into hk_modu_yz
	select '業委會查詢',0,'禁用','',0,1
 end
 if(not exists(select 1 from hk_modu_yz where modu_mc = '業委會成員'  ))
  begin
	insert into hk_modu_yz
	select '業委會成員',10,'禁用','/pms2/yzcx/Ywhcy.aspx',0,1
  end

   if(not exists(select 1 from hk_modu_yz where modu_mc = '費用查詢'  ))
  begin
		insert into hk_modu_yz
		select '費用查詢',0,'禁用','',0,1
  end

   if(not exists(select 1 from hk_modu_yz where modu_mc = '繳款單查詢'  ))
  begin
	insert into hk_modu_yz
	select '繳款單查詢',12,'禁用','/pms2/yzcx/jkdcx.aspx',0,1
 end

  if(not exists(select 1 from hk_modu_yz where modu_mc = '物業費查詢'  ))
  begin
		insert into hk_modu_yz
		select '物業費查詢',12,'禁用','/pms2/yzcx/wyfcx.aspx',0,1
  end



