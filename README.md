# Summary

## Cloud Computing Price Estimator

This Shiny application provies a simple to use visualization of pricing for 3 major Cloud Computing providers.  Included in this release is costs for Microsoft Azure, Google Compute Engine, and Amazon Web Services.  The data was collected on November 15, 2014 and focuses solely on basic pricing without enhancements for commitments or spot pricing markets.  I have found visualizing, and estimating, Infrastructure as a Service pricing to be a "black art" and the Coursera Data Products course gave me the motivation to make an attempt and solving this puzzle.

As Infrastructure as a Service pricing is multivariate, depending on number of Virtual CPUs, Memory, and in most cases instance based storage, I chose to visualize the data in 3 dimensions.  I used the scatterplot3d package from Uwe Ligges and Martin Machler with some excellent help from the Statmethods blog (http://statmethods.wordpress.com/2012/01/30/getting-fancy-with-3-d-scatterplots/).

The pricing applet uses a linear model of price, conditioned by Virtual CPUs, Memory, and Disk.  Using the predict function in the user can choose a class of server optimization and use the sliders to select a number of Virtual CPUs, Memory, and Disk.  The result provides a relatively accurate estimate given the users parameters.  I found the model, with all available server configurations provided an model with an R-squared at the .8 level.  Filtering by class of server optimizatio (Standard, Memory, or Compute) raised the R-squared to the .9 level and tests against known pricing were accurate to within $.01 or $.02.

One assumption with the model was that instance based storage was unaltered.  All instances from Google Compute Engine, and some small ones from Amazon, do not use local instance based storage.  Though Memory, rather than disk storage, is the greatest factor to the model I plan follow on work to refine the applet to align the instance based storage skew in the data.

### Files 

Below is a list of files contained in this release

1. ui.R 
2. server.R
3. iaas-pricing.csv
4. cloud_pricing - Slidify Presentation