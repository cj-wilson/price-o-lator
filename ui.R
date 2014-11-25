library(shiny)

shinyUI(
  fluidPage(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "app.css")
    ),
    titlePanel("Cloud Computing Price Analyzer", windowTitle="Price Analyzer"),
    column(3,
           # Panel for inspecting market pricing
           wellPanel(
             h4("Marketplace Inspector"),
             radioButtons("type", h5("Type:"),
                          choices = list("Standard" = "standard",
                                         "Compute Optimized" = "compOpt",
                                         "Memory Optimized" = "memOpt")
             ),
             sliderInput("coresSlider", label = h6("Virtual Cores"), min=1, 
                         max=32, value = c(1, 32)),
             br()
             # TODO: Add feature to true up models for local instance storage
             # span("Some Instance Types do not contain Local Storage.  Check the box below to normalize storage capacity.", style = "color:blue"),
             # br(),
             # checkboxInput("trueUpModel", label = "Align Storage", value = FALSE)
           ),
           # setup panel for pricing applet
           wellPanel(
             h4("Price-o-Lator"),
             hr(),
             selectInput("serverOpt", label = h5("Server Optimization"), 
                         choices = list("Standard" = 1, "Compute" = 2, "Memory" = 3), 
                         selected = 1),
             hr(),
             sliderInput("predCores", label = h5("Virtual Cores"), min = 1, 
                         max = 32, value = 1),
             sliderInput("predMemory", label = h5("Memory"), min = 1, 
                         max = 512, value = 8),
             sliderInput("predStorage", label = h5("Storage"), min = 1, 
                         max = 1000, value = 50)
           )
    ),
    column(9,
           mainPanel(
             # Create a tabset for 3D plot and for inspecting data
             tabsetPanel(
               tabPanel("Plot", plotOutput("plot", width="100%"),
                        # Create a legend which is not attached to the plot
                        # scatterplot3d legends would not align
                        tags$div(class='my-legend', 
                                 tags$div(class="legend-title", "Provider",
                                          tags$div(class="legend-scale",
                                                   tags$ul(class="legend-labels",
                                                           list(
                                                             tags$li(tags$span(style="background:#feb24c;"), "Amazon"),
                                                             tags$li(tags$span(style="background:#de2d26;"), "Google"),
                                                             tags$li(tags$span(style="background:#3182bd;"), "Microsoft")
                                                           )
                                                   )
                                          )
                                 )
                        )
               ),
               # show the raw data to the user
               tabPanel("Data", dataTableOutput("dt"))
             )
           )
    ),
    # setup a fluid row to separate the plot from the pricing prediction output
    fluidRow(
      # TODO: Add Mean Price, Memory and CPU to this frame
      column(9,div(style = "height: 100px;background-color: white;padding-top:40px;",
                   em(style="padding-left:25px", "Data updated: November, 15, 2014")),
             div(style="padding-left:25px", 
                 helpText("Use the widgets in the left panel and view your pricing information below"))
      )),
    # show the prediction and confidence interval
    fluidRow(
      column(9, offset=1,
             wellPanel(
               span("Predicted Hourly Cost: ", textOutput("pred"),
                    "Confidence Interval: ", br(),
                    "On average, predicted cost be between: ", textOutput("lwrConf"), "and",  textOutput("uprConf"),
                    "95% of the time.",br(),
                    span("Warning: If your predicted cost is negative try increasing Memory size", style = "color:blue"))
               
             )
      )
    )
  )
)


