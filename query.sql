DECLARE
   @MaxLen int = 50;     // Maximum length of a target column

WITH
   SpacePositions AS
      (
         SELECT
               O.OrganisationID,
               CHARINDEX(' ', O.OrganisationName, 0) AS Position
            FROM
               SourceDB.dbo.Organisations O
         UNION ALL SELECT
               O.OrganisationID,
               CHARINDEX(' ', O.OrganisationName, S.Position + 1) AS Position
            FROM
               SourceDB.dbo.Organisations O
               INNER JOIN SpacePositions S
                  ON CHARINDEX(' ', O.OrganisationName, S.Position + 1) > S.Position
                     AND S.OrganisationID = O.OrganisationID
      ),
   SplitPositions AS      
      (
         SELECT
               S.OrganisationID,
               S.Position - 1 AS Position
            FROM
               SpacePositions S
            WHERE
               S.Position != 0
            UNION SELECT
               O.OrganisationID,
               LEN(O.OrganisationName) AS Position
            FROM
               SourceDB.dbo.Organisations O
      ),
   FirstChunk AS
      (
         SELECT
               D.OrganisationID,
               1 AS ChunkStart,
               MAX(D.Position) AS ChunkEnd
            FROM
               (
                  SELECT
                        S.OrganisationID,
                        S.Position + 1 AS Position
                     FROM
                        SplitPositions S
                     WHERE
                        Position BETWEEN 1 AND @MaxLen
                  UNION SELECT
                        S.OrganisationID,
                        @MaxLen
                     FROM
                        SplitPositions S
                     WHERE
                        NOT EXISTS
                           (
                              SELECT
                                    *
                                 FROM
                                    SplitPositions SI
                                 WHERE
                                    SI.Position BETWEEN 1 AND @MaxLen
                                    AND SI.OrganisationID = S.OrganisationID
                           )
               ) D
            GROUP BY
               D.OrganisationID
      ),
   SecondChunk AS
      (
         SELECT
               C.OrganisationID,
               C.ChunkEnd + 1 AS ChunkStart,
               MAX(D.Position) AS ChunkEnd
            FROM
               FirstChunk C
               INNER JOIN
                  (
                     SELECT
                           S.OrganisationID,
                           S.Position + 1 AS Position
                        FROM
                           SplitPositions S
                           INNER JOIN FirstChunk C
                              ON C.OrganisationID = S.OrganisationID
                        WHERE
                           S.Position BETWEEN C.ChunkEnd + 1 AND C.ChunkEnd + @MaxLen
                     UNION SELECT
                           S.OrganisationID,
                           C.ChunkEnd + @MaxLen AS Position
                           FROM
                              SplitPositions S
                              INNER JOIN FirstChunk C
                                 ON C.OrganisationID = S.OrganisationID
                           WHERE
                              NOT EXISTS
                                 (
                                    SELECT
                                          *
                                       FROM
                                          SplitPositions SI
                                       WHERE
                                          SI.Position BETWEEN C.ChunkEnd + 1 AND C.ChunkEnd + @MaxLen
                                          AND OrganisationID = C.OrganisationID
                                 )
                  ) D
                  ON D.OrganisationID = C.OrganisationID
            GROUP BY
               C.OrganisationID,
               C.ChunkEnd
      ),
   ThirdChunk AS
      (
         SELECT
               C.OrganisationID,
               C.ChunkEnd + 1 AS ChunkStart,
               MAX(D.Position) AS ChunkEnd
            FROM
               SecondChunk C
               INNER JOIN
                  (
                     SELECT
                           S.OrganisationID,
                           S.Position + 1 AS Position
                        FROM
                           SplitPositions S
                           INNER JOIN SecondChunk C
                              ON C.OrganisationID = S.OrganisationID
                        WHERE
                           S.Position BETWEEN C.ChunkEnd + 1 AND C.ChunkEnd + @MaxLen
                     UNION SELECT
                           S.OrganisationID,
                           C.ChunkEnd + @MaxLen AS Position
                           FROM
                              SplitPositions S
                              INNER JOIN SecondChunk C
                                 ON C.OrganisationID = S.OrganisationID
                           WHERE
                              NOT EXISTS
                                 (
                                    SELECT
                                          *
                                       FROM
                                          SplitPositions SI
                                       WHERE
                                          SI.Position BETWEEN C.ChunkEnd + 1 AND C.ChunkEnd + @MaxLen
                                          AND OrganisationID = C.OrganisationID
                                 )
                  ) D
                  ON D.OrganisationID = C.OrganisationID
            GROUP BY
               C.OrganisationID,
               C.ChunkEnd
      )
INSERT INTO dbo.OrgStaging
   (
      OrganisationID,
      Name1,
      Name2,
      Name3
   )
SELECT
      O.OrganisationID,
      LTRIM(RTRIM(SUBSTRING(O.OrganisationName, C1.ChunkStart, C1.ChunkEnd))),
      LTRIM(RTRIM(SUBSTRING(O.OrganisationName, C2.ChunkStart, 1 + C2.ChunkEnd - C2.ChunkStart))),
      LTRIM(RTRIM(SUBSTRING(O.OrganisationName, C3.ChunkStart, 1 + C3.ChunkEnd - C3.ChunkStart)))
   FROM
      SourceDB.dbo.Organisations O
      INNER JOIN FirstChunk C1
         ON C1.OrganisationID = O.OrganisationID
      INNER JOIN SecondChunk C2
         ON C2.OrganisationID = O.OrganisationID
      INNER JOIN ThirdChunk C3
         ON C3.OrganisationID = O.OrganisationID
   ORDER BY
      O.OrganisationID;
