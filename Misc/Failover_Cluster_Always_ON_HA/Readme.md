# Steps to create a Failover Cluster with Always ON High Availability.

1. Install VMWare ✅
2. Download SQL Sever and Cumulative Package ✅
3. Download Windows OS Images ✅


 ``If above mentioned steps are complete, start by creating:`` 

4. Add a VM host that would be the Domain Controller (DC) ✅
5. One Primary Server and Required Number of Replicas ✅
    * Memory 2 Gigs and Storage 60 gigs for DC ✅
    * Memory 4 Gigs and Storage 100 gigs for ✅
  
``OR``

6. Create Primary Server and Install SQL Server
7. Clone Primary to make number of desired replicas. 

``Once VMWare and OS are installed``

8. Install VMWare tools ✅
9. Update VMWare Network Adapter to Bridge if it’s not. Usually its on NAT. ✅
10. Update Windows Network Adapter and change it to Static from DHCP ✅
    * ``Set IPv4 address: for example: 192.168.1.50 given default gateway starts with 192.168.1.*``✅
        * Keep adding 1 in each server and point the default DNS to DC. For example: 
            * ``IPv4 address: 192.168.1.51``
            * ``IPv4 DNS Server: 192.168.1.50``
    * ``Set IPv4 Subnet Mask: 255.255.255.0``
    * ``Set IPv4 Default gateway: 192.168.1.1 (from your ISP)``
    * ``Set IPv4 DNS Server: 192.168.1.1 (from your ISP)``
    * ``Set secondary IPv4 DNS Server: 192.168.1.1 (from your ISP - Optional)``
11. Change Computer Name ✅
12. Share Network Drive ✅
13. Install Domain Controller Service on DC ✅
14. Repeat Step 8 - 12 on all servers. ✅
15. Split partition into 3 drives: ✅
    - SQL DATA 40 Gigs (D)
        - ``If letter D is already used by Shared Drive or DVD ROM, change the assigned letter first. Go to cmd:``
              
           ```
           > DiskPart
           > List Volume
           > SELECT VOLUME <ASSIGNED NUMBER to D>
           > assign letter=D
           ```
           
    - TempDB 10 Gigs (T)
    - Log 10 Gigs (L)
16. Create SQLAdmin, SSIS, SSRS users in AZ directory ✅


``Install SQL Server(s):``

17. Launch downloader and SELECT a NEW Instance install ✅
18. Make sure to point DATA, LOG and TEMPDB to their respective drive ✅
19. Make sure to add users we created in Active Directory for SQL ✅

``After SQL Server Install Complete:``

20. Add Firewall rules to allow 1433 for TCP and 1434 for UDP on each server ✅
21. Add Firewall rules to allow 5022 for TCP on each server ✅
22. Enable TCP/IP from SQL Server Configure Manager ✅
23. Install Failover Cluster feature on each server ✅
24. Enable Always On Availability Group from SQL Server Configuration Manager ✅

25. Restore Database(s) and Set RECOVERY to FULL ✅
26. Take a Full backup on a shared location ✅
27. A SQL Login should have sysadmin access and should be an administrators ✅

``Failover Test``

28. Test failing a server and see if t responds in an expected manner ✅
29. Primary replica if not configured as “Readable”, on Failover  when it becomes a secondary, it won’t be readable ✅

``Setting up Maintenance Plan``

30. Setup a maint task
    * Typical maintenance tasks
        * ``Check Database integrity``
            * [DBCC CHECKDB](https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-checkdb-transact-sql?view=sql-server-ver16)
            * [How to Automate the SQL Server DBCC CheckDB](https://www.sqlshack.com/automate-the-sql-server-dbcc-checkdb-command-using-maintenance-plans/)
        * ``Reorganize Indexes``
        * ``Rebuild Indexes``
        * ``Update Statistics ( cannot be done on read only replica)``
        * ``Backup Database (Full/Log)  (Differential backup cannot be performed on the read-only database)``
        * ``Cleanup History from msdb if needed``
        * ``Shrink Database (It is recommended that you never execute this action as part of any regular maintenance as it leads to severe index fragmentation which can harm database performance.)``

