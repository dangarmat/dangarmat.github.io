---
layout: post
title: ASA Conference on Statistical Practice 2018, Friday 5 of 5, Posters and Additional Sessions I Wish I'd Attended
category: [R, ASA, CSP2018]
tags: [R, ASA, CSP2018]
---

![CSP Conf Logo](/images/csp2018.png "Conference Logo")

Highlights from [Conference on Statistical Practice](https://ww2.amstat.org/meetings/csp/2018/index.cfm). 

**Friday 2/16/2018**
* [8:00 AM Keynote Address & 9:15 AM Working with Messy Data](https://dgarmat.github.io/CSP2018-Fri-8am/)
* [11:00 AM Streamlining Your Work Using (Shiny) Apps](https://dgarmat.github.io/CSP2018-Fri-11am/)
* [2:00 PM Data Mining Algorithms / Presenting and Storytelling](https://dgarmat.github.io/CSP2018-Fri-2pm/)
* [3:45 PM Working with Health Care Data](https://dgarmat.github.io/CSP2018-Fri-345pm/)
* **Posters and Additional Sessions I Wish I'd Attended**

**Saturday 2/17/2018**
* [9:15 AM Poster Session 3 / Survival Analysis v. 'Survival' Analysis](https://dgarmat.github.io/CSP2018-Sat-915am/)
* [11:00 AM Causal Inference](https://dgarmat.github.io/CSP2018-Sat-11am/)
* [2:00 PM Deploying Quantitative Models as 'Visuals' in Popular Data Visualization Platforms](https://dgarmat.github.io/CSP2018-Sat-2pm/)
* [Additional Sessions I Wish I'd Attended](https://dgarmat.github.io/CSP2018-Sat-Additional/)

## 5:00 PM Poster Sessions

### 	2 Curating and Visualizing Big Data from Wearable Activity Trackers *Meike Niederhausen, OHSU-PSU School of Public Health*

Problem: data from a wrist health device tracker study involving 500 people is messy. How can visualization help separate useful data  from not useful data?

They had to throw out the first week ([Hawthorne Effect](https://en.wikipedia.org/wiki/Hawthorne_effect)) and implausible values such as 5000 steps in one minute. They also had to limit to people who had enough activity and didn't just take the watch off for days and days.

I liked these plots showing the correlation of different activity levels with health outcomes. Maybe useful for exercise motivation? Not sure exactly who the study can be inferred to, especially after the data cleaning, but suggestive of reasonable hypotheses. I'm not sure about the multiple hypothesis testing if they did any correction, and if the p-values could be taken on face value given the data cleaning choices, but it offers an awesome glimpse into this, [as I've seen first hand, difficult, highly personal data](https://dgarmat.github.io/Calories-vs-Sleep/). One thing I notice is in each column the slope has the same sign - this makes sense as for each variable on the y-axis, lower is associated with better health outcomes. 

![corrplots01](/images/corrplots01.png "can see the red low p-value ones")

It's interesting to see, on the other hand, how little linear correlation there was with clinical values like blood pressure. I'm surprised to see Diastolic blood pressure goes up with age of these participants, but not Systolic blood pressure. There's really nothing much going on besides age here. One wouldn't expect numbers like HbA1c, a long-term measure of diabetes, to be affected much by this study over a few weeks, so would expect correlations to have more to do with pre-existing habits, and so it's surprising there isn't more going on in this population. Wonder if this sample does represent typical adults. It's weird too because one would expect the numbers in the other charts like BMI to correlate with HbA1c, but I think this implies in these data, it doesn't. Shows just how challenging research with health tracker data can be.

![corrplots02.png](/images/corrplots02.png "again, fewer low p-value ones")

### 	5 The Boeing Applied Statistics ToolKit: Best Practices and Tools for Collaboration and Reproducibility in High-Throughput Consulting *Robert Michael Lawton, Boeing Research & Technology*

### 	9 Estimating the Relative Excess Risk Due to Interaction in Clustered Data Settings *Katharine Fischer Berry Correia, Harvard T.H. Chan School of Public Health*

### 16 Exploratory Analyses from Different Forms of Interactive Visualizations *Lata Kodali, Virginia Tech*

### 17 Using SAS Programming to Create Complex Paneled Graphs from Electronic Health Records *Carrie Tillotson, OCHIN, Inc.*

Problem: a new electronic tool is being implemented - can the changes in key variables before and after be measured and displayed in a visually meaningful way?

They implemented an insurance tool in their electronic health records and tracked changes in an important response over time (maybe count of Medicare billings?) at different facilities. They were able to show these plots to staff at the facilities to give insight how practices had or had not changed since tool implementation.

![SAS plot 01](/images/sas01.png "SAS Plot 01")

### 18 An Algorithm to Identify Family Linkages Using Electronic Health Record Data *Megan Hoopes, OCHIN, Inc.*

Problem: Health factors highly correlate among family members but explicit family links are often missing from medical records. Is there a reproducible way to impute links between family members in EHRs?

Their strategy to find family links included identifying key fields such as address, home phone, insurance carrier, and fuzzy matching on mother emergency contact phone number, and cases to exclude such as when it looks like there are two adult females in the household so the biological mother is less clear. and then compare this to a "gold standard" data set. In the end, in a pediatric dataset they linked 382,000 mother-child relationships, of which only 44% were explicitly stated in the EHR.

Some caveats: has high precision but low sensitivity - that is the matches it makes tend to be true, but the number of matches caught is low. Also, this method really is limited to household units not genetic relationships.

This plot shows accuracy of linkage is higher with younger children, and children who go to the doctor more often (younger children go to the doctor more so same or different people?)

![household linkages](/images/householdlink01.png "accuracy of linkages")

## Sessions and Posters I wish I'd Attended


### 	Developing a Comprehensive Personal Plan for Teleworking (Working Remotely) *Julia Lull, Janssen Research & Development, LLC*


### Combining Historical Data and Propensity Score Methods in Observational Studies to Improve Internal Validity *Miguel Marino, Oregon Health & Science University*

### 	Limitations of Propensity Score Methods: Demonstration Using a Real-World Example *Gregory B. Tallman, Oregon State University/Oregon Health & Science University*

### Appropriate Dimension Reduction for Sparse, High-Dimensional Data Using Intensity Plots and Other Visualizations *Eugenie Jackson, West Virginia University*

### 	Evaluating Model Fit for Predictive Validity *Katherine M. Wright, Northwestern University*

### 	Developing and Delegating: Two Key Strategies to Master as a Technical Leader *Diahanna L. Post, Nielsen, Columbia University*

### 	Approachable, Interpretable Tools for Mining and Summarizing Large Text Corpora in R *Luke W. Miratrix, Harvard University*

### Latent Dirichlet Allocation Topic Models Applied to the Center for Disease Control and Prevention’s Grant *Matthew Keith Eblen, Centers for Disease Control and Prevention*

### 	Exploratory Data Structure Comparisons by Use of Principal Component Analysis *Anne Helby Petersen, Biostatistics, University of Copenhagen*

Couldn't get in the door for this one it was so packed!

### Tools for Exploratory Data Analysis *Wendy L. Martinez, U.S. Bureau of Labor Statistics*

### How to Give a Really Awful Presentation *Paul Teetor, William Blair & Co*

I arrived at the end of this session to attend the next one in the room, and the room was laughing and very engaged. 

### CANCELED: A Streamlined Process for Conducting a Propensity Score-Based Analysis *John A. Craycroft, University of Louisville*

Weather cancelled the presenter's flight. Wonder if this presentation is available. 

### 	The Life-Cycle of a Project: Visualizing Data from Start to Finish *View Presentation View Presentation Nola du Toit, NORC at the University of Chicago*

### What Does It Take for an Organization to Make Difficult Information-Based Decisions? Using the Oregon Department of Forestry’s RipStream Project as a Case Study *[Jeremy Groom](http://www.groomanalytics.com/who-we-are.html), Groom Analytics*

Problem: if data suggests a course of action vested interests don't want to take, how can it still be taken?

Heard this session was one of the most interactive of the conference. He discussed a case where data implied a hard decision needed to be made, with a lot of stakeholders on both sides. His process of handling the situations sounds nuanced and he shares a lot of lessons learned. I like this simple layout of costs and benefits of action and no action - takes some of the emotion out of it and lays all cards on the table.

![cost benefit](/images/decision01.png "making a tough decision based on data")



### 	Warranty/Performance Text Exploration for Modern Reliability *Scott Lee Wise, SAS Institute, Inc.*



up next: [9:15 AM Poster Session 3 / Survival Analysis v. 'Survival' Analysis](https://dgarmat.github.io/CSP2018-Sat-915am/)

