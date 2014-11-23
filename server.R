library(shiny)
library(scatterplot3d)
library(data.table)
hoursYear <- 365 * 24
hoursMonth <- hoursYear / 12

# Disk prices -  per month

GCE_DISK_MONTH <- .04
GCE_SSD_MONTH <- .17
EBS_DISK_MONTH <- .05
EBS_SSD_MONTH <- .10
# Disk prices - per hour

GCE_DISK_HOUR <- GCE_DISK_MONTH / hoursMonth
GCE_SSD_HOUR <- GCE_SSD_MONTH / hoursMonth

EBS_DISK_HOUR <- EBS_DISK_MONTH / hoursMonth
EBS_SSD_HOUR <- EBS_SSD_MONTH / hoursMonth

DT <- fread("iaas-pricing.csv", sep=",", header=T)
DT$provider <- as.factor(DT$provider)
DT$type <- as.factor(DT$type)

DT$color[DT$provider == "Amazon"] <- "#feb24c"
DT$color[DT$provider == "Google"] <- "#de2d26"
DT$color[DT$provider == "Microsoft"] <- "#3182bd"

pred <- function(model) {
  function(c, r, d) {
    predict(model, data.frame(cores=c, ram=r, disk=d), interval="confidence")
  }
}

all.lm <- lm(data=DT, price ~ cores + ram + disk)
compOpt.lm <- lm(data=DT[type=="compOpt"], price ~ cores + ram + disk)
memOpt.lm <- lm(data=DT[type=="memOpt"], price ~ cores + ram + disk)
standard.lm <- lm(data=DT[type=="standard"], price ~ cores + ram + disk)

predAll <- pred(all.lm)
predComp <- pred(compOpt.lm)
predMem <- pred(memOpt.lm)
predStd <- pred(standard.lm)

predFun <- function(class, cores, memory, disk) {
  if (class == 1) { 
    result <- predStd(cores, memory, disk) 
  } else if (class == 2) {  
    result <- predComp(cores, memory, disk)
  } else if (class == 3) { 
    result <- predMem(cores, memory, disk) 
  }
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
  #TODO: If result is negative, warn user
  output$pred <-renderText({ paste0("$ ", round(predFun(input$serverOpt,
                                                        input$predCores, 
                                                        input$predMemory, 
                                                        input$predStorage)[1], 3)) })
  output$lwrConf <-renderText({ paste0("$ ", round(predFun(input$serverOpt,
                                                           input$predCores, 
                                                           input$predMemory, 
                                                           input$predStorage)[2], 3)) })
  output$uprConf <- renderText({ paste0("$ ", round(predFun(input$serverOpt,
                                                            input$predCores, 
                                                            input$predMemory, 
                                                            input$predStorage)[3],3)) })
})



