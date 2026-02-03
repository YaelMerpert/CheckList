
--==========================================
--- all AWS connections
--==========================================
select distinct c.client_net_address
   , s.host_name
 from sys.dm_exec_connections as c
 join sys.dm_exec_sessions as s on c.session_id = s.session_id
 where c.client_net_address like '100%'
 group by c.client_net_address
   , s.host_name
   , s.program_name
   , s.login_name;


--==========================================
---K8S  modules deployed already
--==========================================

select distinct x.k8s_module, count(x.k8s_module)
 from sys.dm_exec_connections c
 join sys.dm_exec_sessions s on c.session_id = s.session_id
 cross apply (select left(s.host_name, charindex('-', s.host_name + '-') - 1)) as x(k8s_module)
 where c.client_net_address like '100.92%'
       and parsename(c.client_net_address, 2) not in ('12', '11', '5', '6', '156')
group by x.k8s_module
order by  2 desc;


--==========================================
---connected K8S  modules only
--==========================================
select *
 from dbo.dt_Configuration as dc
 where dc.Qc like '%prod-ngcs-apps.eks-edc-application.edc.ngcs.net%';
--and dc.ConfigurationKey like '%NGCSWebApi%'



--==========================================
--What is running right now
--==========================================
select  x.k8s_module
   , t.text as sql_handle
   ,qp.query_plan as EP
 from sys.dm_exec_requests r
 join sys.dm_exec_sessions s on r.session_id = s.session_id
 join sys.dm_exec_connections c on r.session_id = c.session_id
 cross apply (select left(s.host_name, charindex('-', s.host_name + '-') - 1)) x(k8s_module)
 cross apply sys.dm_exec_sql_text(r.sql_handle) t
 CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) qp
 where r.status in ('running', 'suspended')
       and c.client_net_address like '100.92%'
       and parsename(c.client_net_address, 2) not in ('12', '11', '5', '6', '156')
       and s.is_user_process = 1;


