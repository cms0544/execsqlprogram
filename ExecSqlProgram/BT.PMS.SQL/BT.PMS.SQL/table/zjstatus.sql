update zjstatus set name = '補領(遺失)' where id = 3
if(not exists(select 1 from zjstatus where name = '補領(懷卡)'))
  begin
insert into zjstatus
select '補領(懷卡)'
end