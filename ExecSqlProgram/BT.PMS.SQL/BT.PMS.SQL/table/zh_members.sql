IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_members') AND NAME='pwd')
alter table zh_members add pwd varchar(max)



IF NOT EXISTS (select name from syscolumns where id=object_id(N'ZH_Members') AND NAME='nodeleted')
alter table ZH_Members add nodeleted int

--update ZH_Members set nodeleted = 1 where id in ( select id from #ZH_Members where num = 1)



IF NOT EXISTS (select name from syscolumns where id=object_id(N'ZH_Members') AND NAME='authorizer')
alter table ZH_Members add authorizer varchar(max)


IF NOT EXISTS (select name from syscolumns where id=object_id(N'ZH_Members') AND NAME='authorizedperson')
alter table ZH_Members add authorizedperson varchar(max)

IF NOT EXISTS (select name from syscolumns where id=object_id(N'ZH_Members') AND NAME='authorizedfrom')
alter table ZH_Members add authorizedfrom datetime


IF NOT EXISTS (select name from syscolumns where id=object_id(N'ZH_Members') AND NAME='authorizedend')
alter table ZH_Members add authorizedend datetime



