# Create SQL Server Virtual environment for High Availibilty and Disaster Recovery

Step 1: Install VMWare

Step 2: Create three Windows Servers
- Domain Conrroller
- SQL1 (Primary Node)
- SQL2 (Secondary Node)

Step 3: Enable Active Directory Windows Services on Domain Controller

Step 4: Add SQL1 and SQL2 in the domain

Step 5: Verify Connectivity

Step 6: Install SQL Server and Patches(If Required)

Step 7: Configure Disaster Recovery 
- Failover clustering
- Log shipping
- Replication

### Failover clustering

Database mirroring is a solution for increasing availability of a SQL Server database. It maintains two exact copies of a single database. These copies must be on different SQL Server instances. Two databases form a relationship known as a database mirroring session. One instance acts as the principal server, while the other is in the standby mode and acts as the mirror server. Two SQL Server instances that act in mirroring environment are known as partners, the principal server is sending the active portion of a transaction log to the mirror server where all transactions are redone.

There can be two types of mirror servers: hot and warm. A hot mirror server has synchronized sessions with quick failover time without data loss. A warm mirror server doesn’t have synchronized sessions and there is a possibility of data loss


### Replication

Replication can be used as a technology for coping and distributing data from one SQL Server database to another. Consistency is achieved by synchronizing. Replication of a SQL Server database can result in benefits like: load balancing, redundancy, and offline processing. Load balancing allows spreading data to a number of SQL Servers and distributing the query load among those SQL Servers. A replication consists of two components:

- **Publishers** – databases that provide data. Any replication may have one or more publishers
- **Subscribers** – databases that receive data from publishers via replication. Data in subscribers is updated whenever data the publisher is modified

**SQL Server supports three types of replication:**

- **Merge replication:** publisher and subscriber independently make changes to the SQL Server database. The merge agent monitors the changes on the publisher and subscriber, if needed it modifies the databases. In case of a conflict, predefined algorithm determinates the appropriate data
- **Snapshot replication:** the publisher makes a snapshot of the entire database and makes it available for all subscribers
- **Transactional replication:** uses replication agents which monitor changes on the publisher and transmit these changes to the subscribers

### Log shipping

Log shipping is based on automated sending of transaction log backups from a primary SQL Server instance to one or more secondary SQL Server instances. 
The primary SQL Server instance is a production server, while the secondary SQL Server instance is a warm standby copy. There can be a third SQL Server instance which acts as a monitoring server. 

The log shipping process consists of three main operations: creating a transaction log backup on the primary SQL Server, copying the transaction log backup to one or more secondary servers, and restoring the transaction log backup on the secondary server.

The **Backup and Restore** technique should be used as basic option for assurance. There are two major concepts involved: backing up SQL Server data and restoring SQL Server data. Backed up data is moved to a neutral off-site location and restore is tested to assure data integrity. There are different types of backups available in SQL Server: a full backup, differential backup, transaction log backup, and partial backup. The backup strategy defines the backup type and frequency, how backups will be tested, and where and how backup media will be stored. The restore strategy defines who is responsible for performing restores and how restores should be performed to meet availability and data loss goals.
