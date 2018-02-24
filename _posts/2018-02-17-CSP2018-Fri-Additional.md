---
layout: post
title: ASA Conference on Statistical Practice 2018, Friday 6 of 6, Additional Sessions I Wish I'd Attended
category: [R, ASA, CSP2018]
tags: [R, ASA, CSP2018]
---

![lda topic 5](/images/ldatopic05.png "distribution of words in topic 5's vocabulary")

Highlights from [Conference on Statistical Practice](https://ww2.amstat.org/meetings/csp/2018/index.cfm). 

**Friday 2/16/2018**
* [8:00 AM Keynote Address & 9:15 AM Working with Messy Data](https://dgarmat.github.io/CSP2018-Fri-8am/)
* [11:00 AM Streamlining Your Work Using (Shiny) Apps](https://dgarmat.github.io/CSP2018-Fri-11am/)
* [2:00 PM Data Mining Algorithms / Presenting and Storytelling](https://dgarmat.github.io/CSP2018-Fri-2pm/)
* [3:45 PM Working with Health Care Data](https://dgarmat.github.io/CSP2018-Fri-345pm/)
* [Posters I Wish I'd Seen](https://dgarmat.github.io/CSP2018-Fri-Additional-Posters/)
* **Additional Sessions I Wish I'd Attended**

**Saturday 2/17/2018**
* [9:15 AM Poster Session 3 / Survival Analysis v. 'Survival' Analysis](https://dgarmat.github.io/CSP2018-Sat-915am/)
* [11:00 AM Causal Inference](https://dgarmat.github.io/CSP2018-Sat-11am/)
* [2:00 PM Deploying Quantitative Models as 'Visuals' in Popular Data Visualization Platforms](https://dgarmat.github.io/CSP2018-Sat-2pm/)
* [Additional Sessions I Wish I'd Attended](https://dgarmat.github.io/CSP2018-Sat-Additional/)


## Sessions I wish I'd Attended, Slides Reviewed in Retrospect

### What Does It Take for an Organization to Make Difficult Information-Based Decisions? Using the Oregon Department of Forestry’s RipStream Project as a Case Study *[Jeremy Groom](http://www.groomanalytics.com/who-we-are.html), Groom Analytics*

Problem: if data suggests a course of action vested interests don't want to take, how can it still be taken?

Heard this session was one of the most interactive of the conference. He discussed a case where data implied a hard decision needed to be made, with a lot of stakeholders on both sides. His process of handling these situations sounds nuanced and he shares a lot of lessons learned from this work. I especially like his advice for working with stakeholders: 
* Individuals matter
* Frequent communication + transparency + fairness = trust
* Getting feedback before analyses may increase buy-in
* Setting groundwork for next project

Some other useful reminders to me anyway:
* Small successes help with morale
* Shield tech staff from politics 
* Courage to have difficult conversations
* Provide room to fail, suspend disbelief
* Own the findings
* Retain dedicated staff
* Decision-makers want decision space (Bite-sized decisions)


I like this simple layout of costs and benefits of action and no action - takes some of the emotion out of it and lays all cards on the table.

![cost benefit](/images/decision01.png "making a tough decision based on data")

### 	Developing and Delegating: Two Key Strategies to Master as a Technical Leader *Diahanna L. Post, Nielsen, Columbia University*

Problem: leaders of technical teams have additional challenges to best use their technical talent and these skills don't happen automatically. Technical people who are new leaders of technical teams have a daunting set of soft skills needed to manage a team. Which ones could they focus on?

She recommends focusing on two skills: Developing your team and delegating work to your team. The slides are quite structured and probably worth rereading every few months as a leader of a technical team to take inventory how one is doing. This is not a mathematical talk, but a common sense talk that needs to be said anyway - one of those - refreshing and you know if you need it kind of talk. I also feel like these are management skills I can imagine [some](http://www.patricialampert.com/) [of](https://www.linkedin.com/in/heidi-mahoney-928a8293/) my better managers being a bit of a nerd about gaining, where I might have been a nerd about technical tools.

Under Developing Your Team, she splits this into Mindset and Skills. For mindset, her big distinction is between talent multipliers vs. talent diminishers. Talent multipliers bring out the intelligence in others by:
* attracting and optimizing talent
* requiring peoples' best thinking
* setting challenges
* debating decisions
* instilling accountability

Meanwhile diminishers are absorbed in their own intelligence, stifle others and deplete the collective intelligence of the organization. These are quite general, but anyone who's worked for a while knows this when they hear it. The attitudes are summed up as “They will never figure this out without me.” - Diminisher. “People are smart and will figure this out.” - Multiplier

For Skills under developing your team, she seems to consider this essentially Effective Coaching. This has three related categories of skills:
* Giving and receiving feedback, with a couple slides of detailed advice
* Skillful questioning, which involves skills for coaching individuals and skills for coaching the team
* Engaged listening, which could be summed up with a quote: “Listen with the intent to understand, not the intent to reply.” - Steven Covey

Her second key strategy is delegating work. Maybe necessary to say for technical people in leadership is to delegate to free up your time. "Do only what you can do." - Andy Stanley. Top points:
* consider the degree of initiative of your team members (from "Who's got the monkey?" book) 
* use a Leader-Leader model instead of a Leader-Follower model
* as something comes into your hands, ask if someone else can do it
* ask questions; don’t give answers
* give the team credit. Managers know all the work you have put in. You can tell your boss on the side but the team should get credit.
* don't give into thinking if your don't do it your team will lose motivation and you'll lose your technical edge



### 	Approachable, Interpretable Tools for Mining and Summarizing Large Text Corpora in R *Luke W. Miratrix, Harvard University*

Not yet posted online.

### Latent Dirichlet Allocation Topic Models Applied to the Center for Disease Control and Prevention’s Grant *Matthew Keith Eblen, Centers for Disease Control and Prevention*

Problem: from 2012 to 2016 the CDC adminstered $5 billion a year in grants. There were 800 funding opportunity announcements a year from 13 different centers. Is it possible to use titles and abstracts to classify grants from a public health perspective and get some view into what the CDC funded?

Unsupervised Topic Models methods aim to uncover textual themes running through a large collection of documents without prior annotation. Latent Dirichlet Allocation generative topic model specifically assumes a random distribution of words for a given topic's vocabulary. This gives an advantage of allowing a document to have multiple topics *and* words in multiple topic vocabularies. When topics are similar, such as with CDC grants, this can help capture for example that a document is about 50% cancer and 50% HIV, and that the word "prevention" may be in both topic vocabularies. Latent Dirichlet Allocation is abbreviated LDA, which I unfortunately kept confusing in this presentation with [Linear Discriminant Analysis](https://en.wikipedia.org/wiki/Linear_discriminant_analysis), a supervised classification method. 

Data preparation included collecting titles and abstratcs of funded grants that had abstracts, including locations and ubiquitous words like health in stop words then removing stop words, and removing sparse words showing up in less than 25 abstracts. This LDA requires prior choice of topic numbers (k essentially) so he chose 100 topics and ran LDA with [text2vec](http://text2vec.org/topic_modeling.html) R package. As output, each grant is clustered to some combination of topics adding up to 100%. Then for each grant, he kept only topics from the 100 with more than 20% to assign to the grant to remove long tail information not useful for his problem of interest.

Each of the 100 topics has a distribution of more and less common words in its vocabulary. In the above automatically detected topic, top words are highlighted in the word cloud. He pulls in metainformation on which of the 13 CDC centers funded these grants and is able to assign a meaningful title of Global HIV/AIDS to this cluster.

![lda topic 1](/images/ldatopic01.png "distribution of words in topic 1's vocabulary")

Ranking the topics by number of grants associated with it, number two he titled Immunization, which funding came from Center of Immunization and Respiratory Diseases.

![lda topic 2](/images/ldatopic02.png "distribution of words in topic 2's vocabulary")

Topic three, interestingly had to do with domestic HIV/AIDS. LDA does a good job here of handling that the token "HIV" can show up in two topics. Can see also no funding for this topic came from Center for Global Health.

![lda topic 3](/images/ldatopic03.png "distribution of words in topic 3's vocabulary")

Topic four had to do with sexual violence and funding was concentrated in National Center for Injury Prevention and Control
CIO. 

![lda topic 4](/images/ldatopic04.png "distribution of words in topic 4's vocabulary")

Most commonly funded topic 5, above at the top here, he labelled Adolescent Health.

As an example of less frequently funded topics, number 87 out of 100 doesn't have a clear vocabulary theme.

![lda topic 87](/images/ldatopic87.png "distribution of words in topic 87's vocabulary")

### 	Exploratory Data Structure Comparisons by Use of Principal Component Analysis *Anne Helby Petersen, Biostatistics, University of Copenhagen*

Couldn't get in the door for this one it was so packed!

### Tools for Exploratory Data Analysis *Wendy L. Martinez, U.S. Bureau of Labor Statistics*

Problem: what the heck is the structure of your data? Are there any especially useful tools to use to get a handle on the stories in some data?

For dimensionality reduction, everyone hears about Principle Complonents Analysis (PCA) a linear method. On a podcast someone once described PCA as one of a handful of top-useful algorithms in stats/ML/datascience. Multidimensional Scaling is a set of *nonlinear* dimensionality reduction techniques. There are two kinds of MDS: Metric, which uses a function of dissimilarities such as Euclidean distance for PCA, and Non-Metric, which instead uses rank-order. 

In this example they used MDS on some crab data, and colored according to gender. There does appear to be some clustering similar to these two genders.

![crab data](/images/crabs01.png "crab data through MDS")

She also highly reccomends the simple scatterplot with loess.

Another common exploratory data analysis method is clustering, such as the famous k-means. A silhouette plot helps show how well clusterings are in terms of internal validation anyway. In this example, there are no negative values which is good, and one cluster looks good but the other two are too close I think:

![silhouette plot](/images/silplot01.png "Sihouette plot of three clusters")

She reccomends animated "data tours" to see data along an additional dimension of time. These rotate scatterplots around different dimensions, and can give a quick sense of structure from several angles. For high dimensional data, since there are many ways to reduce dimensions, these animations can help get a sense of the different reasonable views of data sctructure. She used MATLAB and looks like there is an R package, [tourr](https://cran.r-project.org/package=tourr) to look into on this - may want to use [tourrGui](https://cran.r-project.org/package=tourrGui).

She's a fan of parallel coordinate plots for finding structure across many dimensions. I suppose it helps to have one categorical factor and the rest be numerical. Have seen these a few times recently, and maybe with alpha = 0.1 could handle larger data sets. These plots can be used in another method of interactive visualization called Brushing and Linking which could be useful for when there are several views or plots of data. For parallel coordinate plots she mentions reordering variables matters since adjacent variables are easier to see differences and color helps with categorical variables. Here a parallel plot handles 5 dimensions of data and shows obvious clustering:

![parallel coord plot](/images/parallelcoordplot01.png "Parallel Coordinate Plots")


### How to Give a Really Awful Presentation *Paul Teetor, William Blair & Co*

I arrived at the end of this session to attend the next one in the room, and the room was laughing and very engaged. 

### CANCELED: A Streamlined Process for Conducting a Propensity Score-Based Analysis *John A. Craycroft, University of Louisville*

Weather cancelled the presenter's flight. Wonder if this presentation is available. 

### 	The Life-Cycle of a Project: Visualizing Data from Start to Finish *View Presentation View Presentation Nola du Toit, NORC at the University of Chicago*





### 	Warranty/Performance Text Exploration for Modern Reliability *Scott Lee Wise, SAS Institute, Inc.*


### 	Developing a Comprehensive Personal Plan for Teleworking (Working Remotely) *Julia Lull, Janssen Research & Development, LLC*


### Combining Historical Data and Propensity Score Methods in Observational Studies to Improve Internal Validity *Miguel Marino, Oregon Health & Science University*

### 	Limitations of Propensity Score Methods: Demonstration Using a Real-World Example *Gregory B. Tallman, Oregon State University/Oregon Health & Science University*

### Appropriate Dimension Reduction for Sparse, High-Dimensional Data Using Intensity Plots and Other Visualizations *Eugenie Jackson, West Virginia University*

### 	Evaluating Model Fit for Predictive Validity *Katherine M. Wright, Northwestern University*










up next: [9:15 AM Poster Session 3 / Survival Analysis v. 'Survival' Analysis](https://dgarmat.github.io/CSP2018-Sat-915am/)

