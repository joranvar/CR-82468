CREATE TABLE dbo.Organisations
(
    OrganisationID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrganisationName nvarchar(180) NOT NULL
    /* More columns omitted for brevity */
);

INSERT INTO Organisations ([OrganisationName])
SELECT SUBSTRING(OrganisationName, 1, 180)
  FROM ( SELECT 'Microsoft Corporation'
         UNION ALL SELECT 'S&T System Integration & Technology Distribution Aktiengesellschaft'
         UNION ALL SELECT 'VeryLongOrganisationNameThatWillHaveToBeSplitWithoutASpace Because It Really Is A Long Name, But In The Second Column We Can Split It'
         UNION ALL SELECT 'Another VeryLongOrganisationNameThatWillHaveToBeSplitWithoutASpaceButOnlyInTheSecondColumn, Because It Really Is A Long Name'
         UNION ALL SELECT 'AnotherVeryLongOrganisationNameThatWillHaveToBeSplitWithoutASpaceBecauseItReallyIsALongNameButNowItEvenExceedsTheLimitOfAllThreeColumnsWithAMaximumLenghtOf50Characters(WhichIsACombinedTotalOf150Characters)AndNowWeDon''tHaveAnythingToPutInTheLastBox'
         UNION ALL SELECT 'OneWordOnly'
         UNION ALL SELECT 'A' -- Single letter edge case
         UNION ALL SELECT '' -- Empty string edge case
       ) Data(OrganisationName);

CREATE TABLE dbo.OrgStaging
(
    OrganisationID int NOT NULL,
    Name1 nvarchar(50) NOT NULL,
    Name2 nvarchar(50) NOT NULL,
    Name3 nvarchar(50) NOT NULL
    /* More columns omitted for brevity */
);
