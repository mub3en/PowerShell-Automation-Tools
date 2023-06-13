/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [DepartmentCode]
      ,[CourseNumber]
      ,[CourseTitle]
      ,[CourseDescription]
      ,[Credits]
      ,[MaximumSectionSize]
  FROM [Students].[dbo].[Courses]