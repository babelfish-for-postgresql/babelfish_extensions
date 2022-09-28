USE master;
GO

-- the problem is not reproducible with simple query
-- because it depends PG optimizer's decision.
-- use the almost same query with customer system.

CREATE TABLE babel_2089_Rpd(
	RpdId int NOT NULL,
	Title nvarchar(max) NOT NULL,
	Severity nvarchar(max) NOT NULL,
	Type nvarchar(max) NOT NULL,
	Priority nvarchar(max) NOT NULL,
	Status nvarchar(max) NULL,
	AuthorId varchar(50) NOT NULL,
	AuthorType varchar(14) NOT NULL,
	AuthorName nvarchar(128) NULL,
	EntityType nvarchar(max) NULL,
	Entity nvarchar(max) NULL,
	CreatedDate datetime NOT NULL,
	LastCommentDate datetime NULL,
	ResolvedDate datetime NULL,
	SBUpdateDate datetime NULL,
	createdAt datetime2(7) NULL,
	updatedAt datetime2(7) NULL,
	Difficulty nvarchar(max) NULL,
	LocationId int NULL,
	ResolutionCode nvarchar(50) NULL,
	Supplier varchar(255) NULL,
	IsPaidImplementation bit NULL,
PRIMARY KEY CLUSTERED 
(
	RpdId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE babel_2089_RpdToOpsDbInstance(
	RpdId int NOT NULL,
	OpsDbInstanceId int NOT NULL,
PRIMARY KEY CLUSTERED 
(
	RpdId ASC,
	OpsDbInstanceId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
go

CREATE TABLE babel_2089_RpdMetaDataItem(
	RpdId int NOT NULL,
	Item varchar(50) NOT NULL,
	Value nvarchar(300) NULL,
	createdAt datetime2(7) NULL,
	updatedAt datetime2(7) NULL
) ON [PRIMARY]
GO
CREATE TABLE babel_2089_RpdNextSopStep(
	rpdid int NOT NULL,
	TeamId int NOT NULL,
	TeamName nvarchar(30) NOT NULL,
	SopId int NOT NULL,
	StepId int NOT NULL,
	StepSequence int NOT NULL,
	TaskId int NOT NULL,
	StepName varchar(100) NULL,
	CompletedDate datetime2(7) NULL,
	totalSops int NULL,
	completedSops int NULL,
	done int NOT NULL,
	Ready int NOT NULL,
	lastStepCompletedDate datetime2(7) NULL,
	TimelinessTarget int NULL,
PRIMARY KEY CLUSTERED 
(
	rpdid ASC,
	StepId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE babel_2089_RpdAssignee(
	RpdId int NOT NULL,
	EmployeeId int NOT NULL,
	EmployeeName nvarchar(250) NOT NULL,
	IsPrimary bit NULL,
	createdAt datetime2(7) NULL,
	updatedAt datetime2(7) NULL,
PRIMARY KEY CLUSTERED 
(
	RpdId ASC,
	EmployeeId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE babel_2089_CompanyLocation(
	LocationId int NOT NULL,
	LocationName nvarchar(255) NULL,
	LocationDesc nvarchar(2000) NULL,
	MainLocation bit NOT NULL,
	PrimaryContactId int NULL,
	CompanyId int NULL,
	AddressId int NULL,
	Address1 nvarchar(255) NULL,
	Address2 nvarchar(255) NULL,
	Address3 nvarchar(255) NULL,
	City nvarchar(255) NULL,
	RegionCode nvarchar(50) NULL,
	Country nvarchar(5) NULL,
	PostCode nvarchar(40) NULL,
	RegionName varchar(100) NULL,
	CountryCodeDesc varchar(100) NULL,
	MainPhone varchar(50) NULL,
	Formatted_MainPhone varchar(50) NULL,
	StatusId int NULL,
	StatusTypeDesc varchar(50) NULL,
	SubStatusId int NULL,
	StatusSubTypeDesc varchar(50) NULL,
	NumberRequiredVisits int NULL,
	ProspectRating tinyint NULL,
	CompanySizeId int NULL,
	CompanySize varchar(50) NULL,
	BusinessTypeId int NULL,
	BusinessTypeDesc varchar(100) NULL,
	BusinessDescId int NULL,
	BusinessDescription varchar(100) NULL,
	LocalSalesRep int NULL,
	LocalConsultant int NULL,
	InsertBy smallint NULL,
	InsertDate datetime NULL,
	UpdateBy smallint NULL,
	UpdateDate datetime NULL,
	Active int NULL,
	SBUpdateDate datetime NULL,
	UltimateParentName nvarchar(255) NULL,
	ProspectRank int NULL,
	CompanyName nvarchar(255) NULL,
	UltimateParentId int NULL,
	SecondaryConsultant int NULL,
	KeyAccountConsultant int NULL,
	KACSecondary int NULL,
	CompanyClassificationId int NULL,
	CompanyClassificationDesc varchar(100) NULL,
	FirmTypeId int NULL,
	FirmTypeName varchar(50) NULL,
	FirmDescriptionId int NULL,
	FirmDescriptionName varchar(50) NULL,
	EnterpriseId int NULL,
	EnterpriseName nvarchar(255) NULL,
	SalesforceAccountName nvarchar(255) NULL,
	SalesTeamDepartmentId int NULL,
	ConsultingTeamDepartmentId int NULL,
	SalesTeamDepartmentName nvarchar(75) NULL,
	ConsultingTeamDepartmentName nvarchar(75) NULL,
	MainLocationId int NULL,
	Reseller bit NULL,
	FactSetEMSBasketServer varchar(255) NULL,
 CONSTRAINT PK_CompanyLocation PRIMARY KEY CLUSTERED 
(
	LocationId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE babel_2089_Individual(
	IndividualId int NOT NULL,
	LocationId int NULL,
	Salutation nvarchar(50) NULL,
	FirstName nvarchar(255) NULL,
	MiddleName nvarchar(255) NULL,
	LastName nvarchar(255) NULL,
	Nickname nvarchar(255) NULL,
	Suffix nvarchar(50) NULL,
	EmailAddress varchar(255) NULL,
	SecondaryEmailAddress varchar(255) NULL,
	JobTitleId int NULL,
	JobTitleDesc varchar(100) NULL,
	BusinessCardTitle nvarchar(255) NULL,
	DepartmentId int NULL,
	DepartmentDesc varchar(100) NULL,
	Division nvarchar(255) NULL,
	MethodologyId int NULL,
	MethodologyDesc varchar(100) NULL,
	AssetTypeId int NULL,
	AssetTypeDesc varchar(100) NULL,
	StyleRegionId int NULL,
	StyleRegionDesc varchar(100) NULL,
	StyleSizeId int NULL,
	StyleSizeDesc varchar(100) NULL,
	BlockMarketingMail bit NULL,
	BlockMarketingEmail bit NULL,
	SpeaksEnglish bit NULL,
	PrefferedLanguageId int NULL,
	LanguageDesc varchar(100) NULL,
	MainPhoneNumber varchar(50) NULL,
	DirectPhoneNumber varchar(50) NULL,
	MobilePhoneNumber varchar(50) NULL,
	HomePhoneNumber varchar(50) NULL,
	FaxNumber varchar(50) NULL,
	Formatted_MainPhone varchar(50) NULL,
	Formatted_DirectPhone varchar(50) NULL,
	Formatted_MobilePhone varchar(50) NULL,
	Formatted_HomePhone varchar(50) NULL,
	Formatted_Fax varchar(50) NULL,
	upgradePolicy bit NULL,
	InsertBy int NULL,
	InsertDate datetime NULL,
	UpdateBy int NULL,
	UpdateDate datetime NULL,
	Active int NULL,
	SBUpdateDate datetime NULL,
	FactSetEntityId varchar(255) NULL,
	factset_id nvarchar(255) NULL,
	UserClassId int NULL,
	UserClassName varchar(50) NULL,
	PositionId int NULL,
	PositionName varchar(50) NULL,
 CONSTRAINT [PK_babel_2089_Individual] PRIMARY KEY CLUSTERED 
(
	IndividualId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE babel_2089_RpdClientsAffected(
	RpdId int NOT NULL,
	EntityId int NOT NULL,
	EntityType nvarchar(250) NOT NULL,
	ClientId int NULL,
	ClientName nvarchar(250) NULL,
	createdAt datetime2(7) NULL,
	updatedAt datetime2(7) NULL
) ON [PRIMARY]
GO
CREATE TABLE babel_2089_Employee(
	EmployeeId int NOT NULL,
	FirstName nvarchar(75) NULL,
	ShortFirstName nvarchar(75) NULL,
	LastName nvarchar(75) NULL,
	FullName_LNF nvarchar(128) NULL,
	FullName_FNF nvarchar(128) NULL,
	EmailAddress varchar(50) NULL,
	WindowsUsername varchar(25) NULL,
	Active bit NULL,
	DepartmentID int NULL,
	EmploymentType nvarchar(25) NULL,
	JobTitleID int NULL,
	ManagerId int NULL,
	OfficeId int NULL,
	SubsidiaryId int NULL,
	OfficePhone varchar(50) NULL,
	FDSCellPhone varchar(50) NULL,
	updatedate datetime NULL,
	MiddleName nvarchar(75) NULL,
	UnixAccount nvarchar(75) NULL,
	VMSAccount nvarchar(75) NULL,
	JobTitle nvarchar(175) NULL,
	HireDate date NULL,
	OfficeExtension varchar(50) NULL,
	FirstName_NDC nvarchar(150) NULL,
	MiddleName_NDC nvarchar(100) NULL,
	LastName_NDC nvarchar(150) NULL,
	PreferredLastName nvarchar(75) NULL,
 CONSTRAINT PK__Employee__7AD04F11125EB334 PRIMARY KEY CLUSTERED 
(
	EmployeeId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE babel_2089_Department(
	DepartmentId int NOT NULL,
	DepartmentName nvarchar(75) NOT NULL,
	ParentDepartment int NULL,
	UltimateParent int NOT NULL,
	SalesGroupId int NULL,
	SalesGroupName nvarchar(100) NULL,
	Active bit NOT NULL,
	ModifiedDate datetime NOT NULL,
	DepartmentManager int NULL,
	DepartmentMailGroup varchar(100) NULL,
	DepartmentType tinyint NULL,
	DepartmentTypeName varchar(100) NULL,
	ObjectSid char(84) NULL,
	VerticalId int NULL,
	VerticalName nvarchar(75) NULL,
	SalesRegionId int NULL,
	SalesRegionName nvarchar(75) NULL,
	BusinessTypeId int NULL,
	BusinessTypeName nvarchar(75) NULL,
	updatedate datetime NULL,
 CONSTRAINT PK__Department__5C37ACAD PRIMARY KEY CLUSTERED 
(
	DepartmentId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


CREATE view babel_2089_TeamMember as
with config as (
	select 2 as teamId, 17896 as managerId_hierarchy, cast(null as int) as departmentId       -- JPOLO and indirect reports - BDI Content
	union select 2 as teamId, 2670 as managerId_hierarchy, cast(null as int) as departmentId  -- DBeilin and indirect reports - BDI Content 
	union select 2 as teamId, 18519 as managerId_hierarchy, cast(null as int) as departmentId  -- LPapa and indirect reports - BDI Content 
	union select 1 as teamId, 363, cast(null as int) -- MSasser and indirects - BDI Licensing
	union select 5 as teamId, 363, cast(null as int) -- MSasser and indirects - BDI Entitlements
	union select 3 as teamId, 2165, cast(null as int) -- APetre and indirects - BDI Engineering
), mgmt as (
	--	Content Dev
	select c.teamId, employeeId, managerId from babel_2089_Employee e
	inner join config c on c.managerId_hierarchy = e.employeeID 
	union all 
	select m.teamId, e.employeeId, e.managerId
	from mgmt m
	inner join babel_2089_Employee e on e.managerId = m.employeeId
	where e.active = 1
), allUsers as (
	select teamId, employeeId from mgmt
	union
	select 8, employeeId
	from babel_2089_Employee  e
	inner join babel_2089_Department d on d.DepartmentId = e.departmentId
	where (e.departmentId = 1019 and e.active = 1) or employeeId = 12002
)
select m.teamId, m.employeeId
from allUsers m
GO


CREATE view babel_2089_OpsDbView as
	select distinct r.RpdId, r.Title, r.Severity, r.Priority, r.Status, r.CreatedDate, r.LastCommentDate
	, r.AuthorName, r.EntityType, r.Entity, coalesce(cl.locationId, cl_i.locationId) as ClientLocationId, ca.ClientsAffected
	, m_vendor.Value as Vendor -- case when len(meta.Vendor) > 50 then left(meta.Vendor, 30)+'...' else meta.Vendor end as Vendor
	, opsDb.OpsDbInstanceId, sop.TeamId, sop.TeamName, sop.SopId, sop.StepId, sop.StepSequence, sop.TaskId, sop.StepName, sop.CompletedDate
	, sop.totalSops, sop.completedSops, sop.done
	, sop.Ready
	, sop.timelinessTarget, sop.lastStepCompletedDate
	--, m.TimelinessTarget - DATEDIFF(minute, ready.lastStepCompletedDate, GETUTCDATE()) as TatOverUnderMinutes
	--, dateadd(minute, m.TimelinessTarget - DATEDIFF(minute, ready.lastStepCompletedDate, GETUTCDATE()), getutcdate()) as DueDate
	
	, datediff(minute, getdate(), try_parse(m_estComplDate.Value as date)) as TatOverUnderMinutes	
	, convert(varchar, try_parse(m_estComplDate.Value as date)) as DueDate
	, convert(varchar, try_parse(m_wkstnECD.Value as date)) as WorkstationECD
	, tm.AssigneeId, isnull(tm.Assignee, 'Unassigned') as Assignee
	, coalesce(pa.EmployeeId, tm.AssigneeId) as PrimaryAssigneeId, coalesce(pa.EmployeeName, tm.Assignee, 'Unassigned') as PrimaryAssignee
	from babel_2089_Rpd r
	inner join babel_2089_RpdToOpsDbInstance opsDb on opsDb.RpdId = r.RpdId
	left  join babel_2089_RpdMetaDataItem m_vendor on m_vendor.RpdId = r.RpdId and m_vendor.Item = 'Vendor'
	left join babel_2089_RpdMetaDataItem m_estComplDate on m_estComplDate.RpdId = r.RpdId and m_estComplDate.Item = 'EstCompletionDate'
	left join babel_2089_RpdMetaDataItem m_wkstnECD on m_wkstnECD.RpdId = r.RpdId and m_wkstnECD.Item = 'WorkstationECD'
	inner join babel_2089_RpdNextSopStep sop on sop.rpdId = r.RpdId
	left join (
		select a.RpdId, tm.TeamId, a.EmployeeId as AssigneeId, a.EmployeeName as Assignee
		from babel_2089_TeamMember tm 
		inner join babel_2089_RpdAssignee a on tm.EmployeeId = a.employeeID
	) tm on tm.teamId = sop.TeamId and tm.RpdId = r.RpdId
	left join babel_2089_RpdAssignee pa on pa.RpdId = r.RpdId and pa.IsPrimary = 1
	left join babel_2089_CompanyLocation cl on r.EntityType = 'Location' and isnumeric(r.entity) = 1 and cl.LocationId = r.Entity
	left join babel_2089_Individual i on r.EntityType = 'Individual' and isnumeric(r.entity) = 1 and i.IndividualId = r.Entity
	left join babel_2089_CompanyLocation cl_i on cl_i.LocationId = i.LocationId
	left join (
		select rpdId, count(distinct clientId) as ClientsAffected
		from babel_2089_RpdClientsAffected
		group by RpdID
		having count(distinct clientId) > 0
	) ca on ca.RpdId = r.RpdId
	where r.Status <> 'Resolved'
	and isnumeric(r.entity) = 1

go

-- should not throw an error
select * from babel_2089_OpsDbView
go

drop view babel_2089_opsdbview
drop view babel_2089_teammember
drop table babel_2089_rpd
drop table babel_2089_rpdtoopsdbinstance
drop table babel_2089_rpdmetadataitem
drop table babel_2089_rpdnextsopstep
drop table babel_2089_rpdassignee
drop table babel_2089_companylocation
drop table babel_2089_individual
drop table babel_2089_rpdclientsaffected
drop table babel_2089_employee
drop table babel_2089_department
go
