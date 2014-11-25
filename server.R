library(shiny)
library(scatterplot3d)
library(data.table)

# Constants for hours per year - 730 hours per month
hoursYear <- 365 * 24
hoursMonth <- hoursYear / 12

# Setup Disk prices for Google/EBS -  per month

GCE_DISK_MONTH <- .04
GCE_SSD_MONTH <- .17
EBS_DISK_MONTH <- .05
EBS_SSD_MONTH <- .10

# Disk prices - per hour

GCE_DISK_HOUR <- GCE_DISK_MONTH / hoursMonth
GCE_SSD_HOUR <- GCE_SSD_MONTH / hoursMonth

EBS_DISK_HOUR <- EBS_DISK_MONTH / hoursMonth
EBS_SSD_HOUR <- EBS_SSD_MONTH / hoursMonth

# Read data table

DT <- fread("iaas-pricing.csv", sep=",", header=T)

# Correct types

DT$provider <- as.factor(DT$provider)
DT$type <- as.factor(DT$type)

# Add color column - makes scatterplot3d easier to work with

DT$color[DT$provider == "Amazon"] <- "#feb24c"
DT$color[DT$provider == "Google"] <- "#de2d26"
DT$color[DT$provider == "Microsoft"] <- "#3182bd"

# Create a function factory for prediction

pred <- function(model) {
  function(c, r, d) {
    predict(model, data.frame(cores=c, ram=r, disk=d), interval="confidence")
  }
}

getWeights <- function(model, c, r, d) {
  result <- c(c, r, d) * model$coefficients[2:4]
  result
}

# Create linear models 
# Called once at load time

all.lm <- lm(data=DT, price ~ cores + ram + disk)
compOpt.lm <- lm(data=DT[type=="compOpt"], price ~ cores + ram + disk)
memOpt.lm <- lm(data=DT[type=="memOpt"], price ~ cores + ram + disk)
standard.lm <- lm(data=DT[type=="standard"], price ~ cores + ram + disk)

# store linear models in specified prediction function
# called for each user and action, models already created at
# load time

predAll <- pred(all.lm)
predComp <- pred(compOpt.lm)
predMem <- pred(memOpt.lm)
predStd <- pred(standard.lm)

predFun <- function(class, cores, memory, disk) {
  if (class == 1) { 
    result <- c(as.vector(unlist(predStd(cores, memory, disk))), 
                as.vector(unlist(getWeights(standard.lm, cores, memory, disk))))
  } else if (class == 2) {  
    result <- c(as.vector(unlist(predComp(cores, memory, disk))), 
                as.vector(unlist(getWeights(compOpt.lm, cores, memory, disk))))
  } else if (class == 3) { 
    result <- c(as.vector(unlist(predMem(cores, memory, disk))),
                as.vector(unlist(getWeights(memOpt.lm, cores, memory, disk))))
  }
  round(result, 3)
}

# TODO: Add feature to true up model for instances with no storage

# trueUp <- function(dt) {
#   dt[provider=="Amazon" & name=="t2.micro"]$disk <- as.integer(round(dt[cores==1 & disk > 0 , {mean(disk)}], 0))
#   dt[provider=="Amazon" & name=="t2.small"]$disk <- as.integer(round(dt[cores==1 & disk > 0, {mean(disk)}], 0))
#   dt[provider=="Amazon" & name=="t2.medium"]$disk <- as.integer(round(dt[cores==2 & disk > 0, {mean(disk)}], 0))
#   dt[provider=="Google" & cores==1]$disk <- as.integer(round(dt[cores==1 & disk > 0, {mean(disk)}], 0))
#   dt[provider=="Google" & cores==2]$disk <- as.integer(round(dt[cores==2 & disk > 0, {mean(disk)}], 0))
#   dt[provider=="Google" & cores==4]$disk <- as.integer(round(dt[cores==4 & disk > 0, {mean(disk)}], 0))
#   dt[provider=="Google" & cores==8]$disk <- as.integer(round(dt[cores==8 & disk > 0, {mean(disk)}], 0))
#   dt[provider=="Google" & cores==16]$disk <- as.integer(round(dt[cores==16 & disk > 0, {mean(disk)}], 0))
#   dt
# }
# 
# DT.trueup <- trueUp(DT)

shinyServer(function(input, output, session) {
  # Create and render 3D plot
  output$plot <- renderPlot({    
    with(DT[type==input$type & cores >= input$coresSlider[[1]] & 
      cores <= input$coresSlider[[2]]], {
      s3d <- scatterplot3d( cores, price, ram,
                            color=color, pch=15,
                            type="h", lty.hplot = 2,
                            main="",
                            xlab="Virtual Cores",
                            ylab="Price",
                            zlab="Memory",
                            scale.y=.75
                            
      )
      std.lm <- lm(data=DT[type==input$type], ram ~ cores + price)
      s3d$plane3d(std.lm)
      }
    )
  }, height= 400, width=600)
  
  # output data table if user wants to view raw data
  output$dt <- renderDataTable(DT[,1:(ncol(DT)-2), with=F],
                               options = list(lengthMenu = c(10, 25, 50), pageLength = 10))
  
  # TODO: If result is negative, warn user
  # TODO: currently handled in UI as message text
  
  # Data table in renderTable is called with user
  # options for server optimization, cores, memory, etc.
  # The data table is transposed into a single row and
  # column names and a row name for USD($) is added.
  
  output$result <- renderTable({
    dt <- as.data.frame(t(predFun(input$serverOpt,
                                  input$predCores, 
                                  input$predMemory, 
                                  input$predStorage)))
    setnames(dt, c("Predicted Cost", "Lower Range", "Upper Range", 
                   "vCPU Cost", "Memory Cost", "Storage Cost"))
    rownames(dt) <- c("USD ($)")
    return(dt)
    }, digits=3)
  
})



