CREATE TABLE dbo.Organisations
(
    OrganisationID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrganisationName nvarchar(180) NOT NULL
    /* More columns omitted for brevity */
);

CREATE TABLE dbo.OrgStaging
(
    OrganisationID int NOT NULL,
    Name1 nvarchar(50) NOT NULL,
    Name2 nvarchar(50) NOT NULL,
    Name3 nvarchar(50) NOT NULL
    /* More columns omitted for brevity */
);
