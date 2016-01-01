DECLARE @MaxLen int = 50;     -- Maximum length of a target column

  WITH SpacePositions AS
     ( SELECT O.OrganisationID
            , CHARINDEX(' ', O.OrganisationName, 0) - 1 AS Position
         FROM dbo.Organisations O
        UNION ALL
       SELECT O.OrganisationID
            , CHARINDEX(' ', O.OrganisationName, S.Position + 2) - 1 AS Position
         FROM dbo.Organisations O
        INNER JOIN SpacePositions S
                ON CHARINDEX(' ', O.OrganisationName, S.Position + 2) - 1 > S.Position
               AND S.OrganisationID = O.OrganisationID
     )
     , FirstChunk AS
     ( SELECT O.OrganisationID
            , 1 AS ChunkStart
            , COALESCE(MAX(D.Position), @MaxLen) AS ChunkEnd
         FROM dbo.Organisations O
         LEFT JOIN ( SELECT S.OrganisationID
                          , S.Position + 1 AS Position
                       FROM SpacePositions S
                      WHERE Position BETWEEN 1 AND @MaxLen
                   ) D ON D.OrganisationID = O.OrganisationID
          GROUP BY O.OrganisationID
     )
     , SecondChunk AS
     ( SELECT C.OrganisationID
            , C.ChunkEnd + 1 AS ChunkStart
            , COALESCE(MAX(D.Position), C.ChunkEnd + @MaxLen) AS ChunkEnd
         FROM FirstChunk C
         LEFT JOIN ( SELECT S.OrganisationID
                          , S.Position + 1 AS Position
                       FROM SpacePositions S
                      INNER JOIN FirstChunk C ON C.OrganisationID = S.OrganisationID
                      WHERE S.Position BETWEEN C.ChunkEnd + 1 AND C.ChunkEnd + @MaxLen
                   ) D ON D.OrganisationID = C.OrganisationID
        GROUP BY C.OrganisationID, C.ChunkEnd
     )
     , ThirdChunk AS
     ( SELECT C.OrganisationID
            , C.ChunkEnd + 1 AS ChunkStart
            , COALESCE(MAX(D.Position), C.ChunkEnd + @MaxLen) AS ChunkEnd
         FROM SecondChunk C
         LEFT JOIN ( SELECT S.OrganisationID
                          , S.Position + 1 AS Position
                       FROM SpacePositions S
                      INNER JOIN SecondChunk C ON C.OrganisationID = S.OrganisationID
                      WHERE S.Position BETWEEN C.ChunkEnd + 1 AND C.ChunkEnd + @MaxLen
                   ) D ON D.OrganisationID = C.OrganisationID
        GROUP BY C.OrganisationID, C.ChunkEnd
     )
INSERT INTO dbo.OrgStaging
     ( OrganisationID
     , Name1
     , Name2
     , Name3 )
SELECT O.OrganisationID
     , LTRIM(RTRIM(SUBSTRING(O.OrganisationName, C1.ChunkStart, C1.ChunkEnd)))
     , LTRIM(RTRIM(SUBSTRING(O.OrganisationName, C2.ChunkStart, 1 + C2.ChunkEnd - C2.ChunkStart)))
     , LTRIM(RTRIM(SUBSTRING(O.OrganisationName, C3.ChunkStart, 1 + C3.ChunkEnd - C3.ChunkStart)))
  FROM dbo.Organisations O
 INNER JOIN FirstChunk C1 ON C1.OrganisationID = O.OrganisationID
 INNER JOIN SecondChunk C2 ON C2.OrganisationID = O.OrganisationID
 INNER JOIN ThirdChunk C3 ON C3.OrganisationID = O.OrganisationID
 ORDER BY O.OrganisationID;
