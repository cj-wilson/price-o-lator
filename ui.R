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
             helpText("Use the widgets below to estimate your costs."),
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
      column(9,div(style = "height:50px;background-color: white;padding-top:30px;",
                   em(style="padding-left:25px", "Source: Amazon, Google, Microsoft public pricing. Updated: May, 2015")),
             div(style="padding-left:25px", 
                 wellPanel(
                   helpText("The predicted hourly cost is below.  We have included lower and upper ranges for the mean costs",
                            "for a Virtual Machine given your parameters.  There is also an estimated cost breakdown for vCPU",
                            "Memory, and Instance Based Storage."),
                   tableOutput("result"),
                   br(),
                   span("Note: If your predicted cost is negative try increasing Memory size", style = "color:blue")
                 ))
      )
    )
  )
)


