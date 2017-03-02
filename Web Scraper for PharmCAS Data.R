#Created By Patrick Vo
#Date created: 2/22/2017
#Last submitted: 2/22/2017
#Purpose: I could not find a table of school by class size, so I wrote a script
#         to scrape the PHARMCAS website for data about pharmacy school class 
#         sizes
#Additional note: Used in conjunction with Selector Gadget (finds CSS)


#Description: The Pharmacy School Centralized Application Service general page
#         uses web formats that I could not scrape using my standard techniques
#         in Rvest. However, I realized that the links to each individual school
#         were numbered (such as http://schoolpages.pharmcas.org/publishedsurvey/2203)
#         If a typed URL contains a number that does not link to the profile of an
#         actual school, then user is redirected to an error page
#         I wrote a script that would concatenate the possible range of numbers
#         to the general pharmcas.org link
#         The script then checks to see if it landed on an error page. If it doesn't,
#         then the script writes down the school name and class size.

testObject<-''

#Load the rvest and xml2 libraries
library(rvest)
library(xml2)

#Initialize the following variables:
  #Possible numbers for each school page
  possibleSchools <-(400:2500) 
  
  #A null list that has the length of possibleSchools
  possibleWebsites <- rep('', length(possibleSchools))
  
  #A null variable which will later test for an error page
  errorMessage <- ''
  
  #A null vector to hold the class sizes
  classSize<-rep(0,length(possibleWebsites))
  
  #A null list to hold the school names
  schoolName<- rep('a', length(possibleWebsites))

for (i in 1:(2500-400)){
possibleWebsites[i]<-paste('http://schoolpages.pharmcas.org/publishedsurvey/',
                           possibleSchools[i],sep='')
}

for (i in 1:length(possibleWebsites)){
   #Download and parse the the possible website. 
  PharmCAS<- read_html(possibleWebsites[i])
    
   #Looks for a message in the css = 'h3 span' node of the website and loads it 
   #    into the variable errorMessage
   #    If the script has loaded a page that doesn't correspond to a school, the
   #    then the errorMessage will read 'Error'
   PharmCAS%>%
   html_nodes('h3 span') %>% 
   html_text() -> errorMessage
   
   #If it doesn't read Error
   if (errorMessage !="Error"){
     #Read in the school name. Note the CSS styling is still present
     PharmCAS%>%
       html_nodes('h1') %>% 
       html_text() -> schoolName[i]
     
     
     if(length(PharmCAS%>%
       html_nodes('#statistics-criteria li:nth-child(3) span') %>% 
       html_text()) != 0){
       PharmCAS%>%
            html_nodes('#statistics-criteria li:nth-child(3) span') %>% 
            html_text() -> classSize[i]
       testObject <- 'This is not length 0'
     } else if(length(PharmCAS%>%
                      html_nodes('statistics-criteria li:nth-child(3) span') %>% 
                      html_text()) != 0){
         PharmCAS%>%
                html_nodes('statistics-criteria li:nth-child(3) span') %>% 
                html_text()-> classSize[i] 
     }
     print(classSize[i])
     print(schoolName[i])
   } 
   print(errorMessage)
   errorMessage <- NULL
   #I like to have a visual cue as to where my program is
   print(i + 400)
}

#Turn the scraped data into a  dataframe
schoolNameAndClassSize<-cbind(schoolName, classSize)
schoolNameAndClassSizeFrame <-data.frame(schoolNameAndClassSize)

#Rename the columns of the dataframe
colnames(schoolNameAndClassSizeFrame)<-c('Name', 'classSize')

#Select from the data only columns where the word 'pharmacy' appears in the title
#Note that there are some exceptions, such as Larkin Health Sciences. 
schoolNameAndClassSizeFrame<-schoolNameAndClassSizeFrame[grepl('pharmacy',schoolNameAndClassSizeFrame$Name, ignore.case = TRUE)
                                                         |grepl('larkin',schoolNameAndClassSizeFrame$Name, ignore.case = TRUE),]


# At this point, there were ~20 data points which were missing, extra, or otherwise poorly formatted. 
# The data was viewed (via RStudio), sorted, then copied+pasted into a spreadsheet program for 
# manual cleaning. 
View(schoolNameAndClassSizeFrame)


