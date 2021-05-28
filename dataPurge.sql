set nocount on
IF OBJECT_ID('tempdb.dbo.#fkeys') IS NOT NULL
begin
  drop table #fkeys
end
create table #fkeys (id int identity(1,1),
    childTableSchema sysname,
    childTable sysname,
    childKeyName sysname,
    childColumnName sysname,
    parentTableSchema sysname,
    parentTable sysname,
    parentColumnName sysname default NULL NULL,
  tLevel int default 0,
    done bit default 0)
declare @tableSchema sysname, @tableName sysname, @pTableSchema sysname, @pTableName sysname,
    @pTableColumnName sysname, @filter varchar(8000),
    @pTableKeyName sysname, @tLevel int = 0

set @TableSchema = 'Person' -- TABLE SCHEMANAME
set @TableName = 'Person' -- TABLE NAME
set @filter = 'BusinessEntityID between 20000 and 20777' -- Filter to be applied on table above.

set @pTableSchema = @tableSchema
set @pTableName = @tableName


insert into #fkeys(childTableSchema, childTable, childKeyName, childColumnName, parentTableSchema, parentTable)
select @pTableSchema, @pTableName, ind.name, cl.name, 0, 0 from sys.indexes ind join sys.index_columns icl on ind.object_id = icl.object_id
and ind.index_id = icl.index_id
join sys.columns cl on icl.column_id = cl.column_id and cl.object_id = icl.object_id
where is_primary_key = 1 and ind.object_id = object_id(@pTableSchema+'.'+@pTableName)

--select * from #fkeys
declare @pTableId int
while ((select count(1) from #fkeys where done = 0)>0)
begin
  select top 1 @pTableId = id, @pTableSchema= childTableSchema, @pTableName = childTable, @pTableKeyName = childKeyName
  , @pTableColumnName = childColumnName, @tLevel = tLevel
  from #fkeys where done = 0

  insert into #fkeys (childTableSchema, childTable, childKeyName, childColumnName, parentTableSchema, parentTable, parentColumnName, tLevel)
  -- childTableSchema, childTable, childKeyName, childColumnName, parentTable
  SELECT
    schema_name(fk.schema_id) childTableSchema,
    object_name(fk.parent_object_id) childTable,
    fk.name childKeyName,
    cl.name childColumnName,
    @pTableSchema parentTableSchema,
    @pTableName parentTable,
    (select name from sys.columns where column_id = fkc.constraint_column_id and object_id = fkc.referenced_object_id) as parentColumnName,
  (@tLevel+1) currentLevel
  FROM
    sys.tables parent
    join
    sys.foreign_keys fk
    on fk.referenced_object_id = parent.object_id
    join sys.foreign_key_columns fkc
    on fkc.parent_object_id = fk.parent_object_id
    and fk.object_id = fkc.constraint_object_id
    join sys.columns cl
    on cl.object_id = fk.parent_object_id
    and cl.column_id = fkc.parent_column_id
    and fkc.referenced_object_id = parent.object_id
    where parent.name = @pTableName
  
  update #fkeys set done = 1 where childTableSchema = @pTableSchema and childTable = @pTableName
end

--select * from #fkeys

/*
select * from Person.Address where AddressID between 29859 and 32521

select * from
Sales.SalesOrderDetail SalesOrderDetail_2 join Sales.SalesOrderHeader SalesOrderHeader_1
    on SalesOrderDetail_2.SalesOrderID = SalesOrderHeader_1.SalesOrderID
  join Person.Address Address_0
    on SalesOrderHeader_1.BillToAddressID = Address_0.AddressID and SalesOrderHeader_1.ShipToAddressID = Address_0.AddressID
  where Address_0.AddressID between 29859 and 32521

select * from
Sales.SalesOrderHeaderSalesReason SalesOrderHeaderSalesReason_2 join Sales.SalesOrderHeader SalesOrderHeader_1
    on SalesOrderHeaderSalesReason_2.SalesOrderID = SalesOrderHeader_1.SalesOrderID
  join Person.Address Address_0
    on SalesOrderHeader_1.BillToAddressID = Address_0.AddressID and SalesOrderHeader_1.ShipToAddressID = Address_0.AddressID
  where Address_0.AddressID between 29859 and 32521
*/

--select * from #fkeys
--
-- GENERATOR START
--

/*
select * from #fkeys
select 'select * from '+fk.childTableSchema+'.'+fk.childTable+' as '+fk.childTable+'_'+convert(varchar,fk.tLevel)+'_'+convert(varchar,fk.id)
,' join '+fk.parentTableSchema+'.'+fk.parentTable+' as '+fk.parentTable+'_'+convert(varchar,pfk.tLevel)+'_'+convert(varchar,fk.id)
+' on '+fk.childTable+'_'+convert(varchar,fk.tLevel)+'_'+convert(varchar,fk.id)+'.'+fk.childColumnName+'='+fk.parentTable+'_'+convert(varchar,pfk.tLevel)+'_'+convert(varchar,fk.id)+'.'+fk.parentColumnName
,* from #fkeys fk
join #fkeys pfk on fk.parentTable = pfk.childTable
and pfk.tLevel < fk.tLevel
order by fk.id desc, fk.tLevel desc, pfk.id desc, pfk.tLevel desc
*/

IF OBJECT_ID('tempdb.dbo.#qTable') IS NOT NULL
begin
  drop table #qTable
end

create table #qTable
(
  qid int identity (1,1),
  headQ varchar(max),
  joinQ varchar(max),
  fkid int,
  childSchema sysname,childTable sysname,childColumn sysname,childLevel int,
  parentSchema sysname,parentTable sysname,parentColumn sysname,parentLevel int,
  hDone int default 0, jDone int default 0 
)

insert into #qTable (headQ, joinQ, fkid, childSchema, childTable, childColumn, childLevel,
  parentSchema, parentTable, parentColumn, parentLevel)
select 'delete '+fk.childTable+'_'+convert(varchar,fk.tLevel)+'_'+convert(varchar,fk.id)+' from '+fk.childTableSchema+'.'+fk.childTable+' as '+fk.childTable+'_'+convert(varchar,fk.tLevel)+'_'+convert(varchar,fk.id)
,' join '+fk.parentTableSchema+'.'+fk.parentTable+' as '+fk.parentTable+'_'+convert(varchar,pfk.tLevel)+'_'+convert(varchar,fk.id)
+' on '+fk.childTable+'_'+convert(varchar,fk.tLevel)+'_'+convert(varchar,fk.id)+'.'+fk.childColumnName+'='+fk.parentTable+'_'+convert(varchar,pfk.tLevel)+'_'+convert(varchar,fk.id)+'.'+fk.parentColumnName
,fk.id,fk.childTableSchema,fk.childTable, fk.childColumnName,fk.tLevel, fk.parentTableSchema, fk.parentTable, fk.parentColumnName,
pfk.tLevel
from #fkeys fk
join #fkeys pfk on fk.parentTable = pfk.childTable
and pfk.tLevel < fk.tLevel
order by fk.id desc, fk.tLevel desc, pfk.id desc, pfk.tLevel desc

select * from #qTable

declare @childSchema sysname, @childTable sysname, @childLevel sysname,
@childColumn sysname, @parentColumn sysname,
@parentSchema sysname, @parentTable sysname, @parentLevel sysname, @cmdText varchar(8000), @fkid int, @jid int,
@headQ varchar(8000), @joinQ varchar(8000), @alias1 int, @alias2 int

update #qTable set hDone = 0
WHILE((select count(1) from #qTable where hDone = 0)>0)
BEGIN
  select top 1 @headQ=headQ, @joinQ = joinQ, @parentSchema = parentSchema, @parentTable=parentTable, @parentLevel=parentLevel,
  @fkid = fkid, @jid = fkid from #qTable where hDone = 0
  print @headQ + @joinQ
  update #qTable set hDone = 1 where headQ = @headQ
  update #qTable set jDone=0

  IF OBJECT_ID('tempdb.dbo.#jParentQueue') IS NOT NULL
  begin
    drop table #jParentQueue
  end
  create table #jParentQueue (id int identity(1,1), parentSchema sysname, parentTable sysname, parentLevel int, fkid int, done int)
  WHILE(
    (select count(1) from #qTable where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel)>0
    or
    (select count(1) from #jParentQueue where done = 0) > 0
  )
  BEGIN
    if((select count(1) from #qTable where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel)>0)
    begin
      select top 1 @joinQ=replace(joinQ,childTable+'_'+convert(varchar,childLevel)+'_'+convert(varchar,fkid),childTable+'_'+convert(varchar,childLevel)+'_'+convert(varchar,@fkid))
        ,@jid = fkid
        from #qTable where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel
      print @joinQ
      insert into #jParentQueue(parentSchema,parentTable,parentLevel,fkid,done) select parentSchema, parentTable, parentLevel, fkid, 0 from #qTable
        where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel
        order by parentLevel desc
      update #jParentQueue set done = 1 where parentLevel = 0
      update #qTable set jDone = 1 where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel
    end
    else
    begin
      select top 1 @parentSchema = parentSchema, @parentTable = parentTable, @parentLevel = parentLevel from #jParentQueue where done = 0
        order by parentLevel desc
      select top 1 @alias1 = parentLevel, @alias2 = fkid from #jParentQueue where parentSchema =  @parentSchema and parentTable = @parentTable
      select top 1 @joinQ=replace(joinQ,childTable+'_'+convert(varchar,childLevel)+'_'+convert(varchar,fkid),childTable+'_'+convert(varchar,@alias1)+'_'+convert(varchar,@alias2))
        ,@jid = fkid
        from #qTable where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel
      print @joinQ+'--FromQueue'
      --select distinct parentSchema, parentTable, parentLevel, fkid, 0 from #qTable
      --  where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel
      insert into #jParentQueue(parentSchema,parentTable,parentLevel,fkid,done) select parentSchema, parentTable, parentLevel, fkid, 0 from #qTable
        where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel
        order by parentLevel desc
      update #jParentQueue set done = 1 where parentLevel = 0
      update #qTable set jDone = 1 where jDone = 0 and childSchema=@parentSchema and childTable=@parentTable and childLevel = @parentLevel
      update #jParentQueue set done = 1 where parentSchema = @parentSchema and parentTable = @parentTable and parentLevel = @parentLevel
    end
    --select * from #jParentQueue
  END
  print 'where '+@TableName+'_0_'+convert(varchar,@jid)+'.'+@filter
END



--
-- GENERATOR END
--

set nocount off
