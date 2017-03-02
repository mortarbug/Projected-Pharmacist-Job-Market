/*Last submitted: 3/2/2017
Program Name: Projections Central Job Projections
File Location: C:/Users/MBG/Documents/My Sas Files
Date Created: 2/20/2017
Author: Patrick Vo
Purpose: To estimate the size of the pharmacy graduate job market by state 
         and in general. */
         

/*Assumptions Made: All pharmacy schools will fill the same number of seats every 
      year. No new schools will open; no currently open schools will close.
      No new laws or other factors will drastically change the job market 
      projected by the Bureau of Labor Statistics.*/


/* Assign Fileref to output destination and open output destination*/
filename RPHout 'C:\Users\MBG\Documents\My SAS Files\Pharmacist Job Data\Projected Pharmacist Employment Report.pdf';
ods pdf file=RPHout style = journal;


/*----------------------------------------------------------------------------*/
/*1. Use proc import to load in the job outlook data                          */
/*----------------------------------------------------------------------------*/
PROC IMPORT OUT= WORK.Employmentdata 
            DATAFILE= "C:\Users\MBG\Documents\My SAS Files\Pharmacist Jo
b Data\Pharmacist Job Outlook.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 /*Change the number of rows that SAS looks at to decide variable length*/
	 /*This avoids truncation*/
	 guessingrows = 32767;

  /*Relabel columns for readability*/
  label PercentChange = '% Change', 
        AvgAnnualOpenings = 'Average Annual Openings';
RUN;

/*----------------------------------------------------------------------------*/
/* Use proc import to load in the total list of Pharmacy schools in the       */
/*     United States                                                          */
/*----------------------------------------------------------------------------*/
PROC IMPORT OUT= WORK.pharmSchoolData 
            DATAFILE= "C:\Users\MBG\Documents\My SAS Files\Pharmacist Jo
b Data\Pharmacy Schools By State.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	  /*Change the number of rows that SAS looks at to decide variable length*/
	 /*This avoids truncation*/
	 guessingrows = 32767;
RUN;

/*----------------------------------------------------------------------------*/
/* Use proc import to load the cleaned pharmacy school attendance data        */
/*----------------------------------------------------------------------------*/
PROC IMPORT OUT= WORK.AttendanceData 
            DATAFILE= "C:\Users\MBG\Documents\My SAS Files\Pharmacist Jo
b Data\Cleaned Pharmacy School Attendance Data.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	  /*Change the number of rows that SAS looks at to decide variable length*/
	 /*This avoids truncation*/
	 guessingrows = 32767;
RUN;


/*----------------------------------------------------------------------------*/
/*2. Prepare the PharmSchoolData and AttendanceData sets for merging          */
/*----------------------------------------------------------------------------*/


/*Sort the PharmSchoolData by University*/
proc sort data = work.PharmSchoolData;
  by University;
run;



/*There are nearly no identical rows between the 2 data sets. Create a third  */
/*   variable in both sets to make merging possible.                          */
data work.PharmSchoolData;
  set work.PharmSchoolData;
  mrgr = .;
run;

data work.AttendanceData;
  set work.AttendanceData;
  mrgr=.;
run;

/*----------------------------------------------------------------------------*/
/* 3. Create a new dataset of pharmacy schools and class size. Drop           */
/*        unnecessary variables.                                              */
/*----------------------------------------------------------------------------*/

data work.schoolByClassSize;
  /*Merge by the new variable*/
  merge work.pharmSchoolData(drop = city)
        work.AttendanceData(drop = University Number);
  by mrgr;
  drop mrgr;
  /*Enhance readability by changing labels*/
  label Est_='Established' Class_Size='Class Size';
run; 

/*Note: the merge step was chosen to avoid the Cartesian Product that would have
  resulted from proc sql. Also note that the cleaning of the attendance data involved 
  making it completely merge-compatible with the sorted PharmSchoolData dataset*/




/*----------------------------------------------------------------------------*/
/* 4. Print the overall projected employment data                             */   
/*----------------------------------------------------------------------------*/

/*Reformat to make the percent change dataset more readable*/
data work.EmploymentData;
  set work.EmploymentData;
  /*Create a new variable to take compare baseline change*/
  TotPercentChange = 0.07;
  PercentChange = PercentChange * 0.01;
  format PercentChange TotPercentChange PERCENT12.1;
  label PercentChange = 'Percent Change' Proj = 'Projected Total Jobs' 
      	Base = 'Current Total Jobs' AreaName = 'Area Name' 
        TotPercentChange = 'Average Percent Change for All Occupations';
run;

/*On the first page, write out the title and assumptions */
title 'Quick Projection of the Future Pharmacist Job Market';

/*Output relevant report data*/ 
ods escapechar = '^';
ods pdf text = '^{Newline 6}';
ods pdf text = '^S={Just = C}';
ods pdf text = 'Assumptions Made: All pharmacy schools will fill the same number of seats every year. 
No new schools will open; no currently open schools will close. 
No new laws or other factors will drastically change the job market 
 projected by the Bureau of Labor Statistics.';
ods pdf text = '^{Newline 6}';



/*Set a title and footnotes about where the data came from*/
title2 'National Pharmacist Employment, Projected to 2024';
footnote1 'Source of Data: ';
footnote2 'Bureau of Labor Statistics';

/*Use the proc print statement to print the first row of the EmploymentData 
     dataset*/
proc print data = work.EmploymentData(obs = 1) label noobs;
  var AreaName Base Proj PercentChange TotPercentChange;
run;


/*----------------------------------------------------------------------------*/
/* 5. Use proc sql to print out the state by state employment changes         */   
/*----------------------------------------------------------------------------*/
/* Set the title and footnotes*/
title2 'Comparison of Employment vs Graduating Pharmacists per Annum';
footnote2 'Employment Numbers from State Employment Security Agency via ProjectionsCentral.com';
footnote3 'Attendance numbers scraped from PHARMCAS website and pharmacy-schools.startclass.com';

/* Start the query*/
proc sql;
  /*Create a table, which will be used later*/
  Create table work.jobProjections as
  /*Select the desired columns, making sure there's only 1 row per state*/
  select distinct SCS.state,
		sum(SCS.class_size) as tot_grads label = 'Total Graduates',
    		class_size, 
			newJobs,
			SCS.Est_, 
			ED.newJobs - calculated tot_grads  as Difference label = 'Job Shortage'
  /*Inner join both datasets together by state. I wanted to practice inline views as well*/
  	from work.SchoolByClassSize as SCS inner join 
      (select avgAnnualOpenings as newJobs label = 'Job Openings',
								AreaName
								from work.EmploymentData
								group by AreaName) as ED
	on SCS.state = ED.AreaName
	group by state
	order by State	
  ;

  /*Print out the per annum job projections*/ 
select distinct state, tot_grads, newJobs, Difference
  from work.jobProjections
;

quit;


/*----------------------------------------------------------------------------*/
/* 6. Project national total job shortage to 2024                             */   
/*----------------------------------------------------------------------------*/
/*Set the title*/
title2 'Total Job Shortage by 2024';
footnote2 'Job Market as Predicted by the Bureau of Labor Statistics';
footnote3 'Attendance numbers scraped from PHARMCAS website and pharmacy-schools.startclass.com';

/*Create a new dataset to project the job data*/
data work.jobsIn2024;
  set work.jobProjections;
  /*Account for schools which will graduate their first class in 2017 or later*/
  if Est_ > 2013 then do;
     TotalGrads = (2024-(Est_ + 4)) * class_size;
	 end;
  /*If the schools are long established, then just multiply by years until 2024*/
  else do;
     TotalGrads = (2024-2017) * class_size;
	 end;
  totalJobs = (2024-2017) * newJobs;
run;

proc sql;
  /*Start the query. I decided to use the BLS national projection instead of my
       calculated total jobs*/
  select 'National Job Market', 7840*(2024-2017) as totjobs label = 'Total Jobs by 2024',
       J.sumgrads label = 'New Pharmacist Graduates by 2024',
       calculated totjobs - sumgrads as shortage label = 'Projected Job Shortage'
	from (select sum(totalGrads) as sumgrads from work.Jobsin2024) as J
  ;

  
  /* Set title and footnotes*/ 
  title2'State by State Job Shortage by 2024';
  footnote2 'Employment Data from State Employment Security Agency via ProjectionsCentral.com';
  footnote3 'Attendance Data Scraped from PHARMCAS website and pharmacy-schools.startclass.com';

  /*Query the jobsin2024 table for sums of grads and employment by state*/
proc sql;
  select distinct State, 
		 sum(totalGrads) as totGrads label = 'Total Graduates in State', 
         totalJobs label = 'Total Jobs in State', 
		 totalJobs - calculated totGrads label = 'Job Shortage in State'
    from work.Jobsin2024
    group by State
  ;
quit;

/*----------------------------------------------------------------------------*/
/* 7. Close the ODS device and titles/footnotes                               */   
/*----------------------------------------------------------------------------*/
ods pdf close;
title;
footnote;



