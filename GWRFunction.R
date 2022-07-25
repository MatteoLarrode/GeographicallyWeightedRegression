#Final Coursework Function
GWR.multicollin.diagno(Dub.voter,Dub.voter$GenEl2004, Dub.voter$Age18_24, Dub.voter$Unempl, Dub.voter$DiffAdd)

GWR.multicollin.diagno(Dub.voter,Dub.voter$GenEl2004, Dub.voter$SC1, Dub.voter$Unempl, Dub.voter$DiffAdd)


GWR.multicollin.diagno <- function (SpatialPolygonDF, Dependent, Predictor1, Predictor2,Predictor3, Kernel="gaussian", Bandwidth){
  
  #1)first overview (global linear regression analysis)
  global.reg <- lm(Dependent ~ Predictor1+Predictor2+Predictor3)
  
  coeff1 <- summary(global.reg)$coefficients[2, 1]
  coeff2 <- summary(global.reg)$coefficients[3, 1]
  coeff3 <- summary(global.reg)$coefficients[4, 1]
  pvalue1 <- summary (global.reg)$coefficients[2, 4]
  pvalue2 <- summary (global.reg)$coefficients[3, 4]
  pvalue3 <- summary (global.reg)$coefficients[4, 4]
  
  global.reg.df <- data.frame(
    Predictors = c("Predictor1", "Predictor2", "Predictor3"),
    Coefficients = c(coeff1, coeff2, coeff3),
    Pvalues = c(pvalue1, pvalue2, pvalue3))
  
  print(global.reg.df) 
  
  #2)Geographically Weighted Regression (custom kernel & bandwidth)
  if  (missing(Bandwidth)) { #run gwr model with bandwidth calculated by 'GWmodel'
    Bandwidth <- bw.gwr(Dependent ~ Predictor1+Predictor2+Predictor3, data=SpatialPolygonDF, kernel=Kernel, adaptive = TRUE) 
    print(paste0("Bandwidth: ",  Bandwidth)) #printing the calculated bandwidth makes choosing others easier for the user later on
    
    gwr.model <- gwr.basic(Dependent ~ Predictor1+Predictor2+Predictor3, data = SpatialPolygonDF, bw= Bandwidth, kernel = Kernel, adaptive=TRUE)
    GWR.df <<-as.data.frame(gwr.model$SDF) #data frame of results of GWR to global environment for easier access
  } 
  
  else{ #run gwr model with fixed bandwidth defined by the user 
    gwr.model <- gwr.basic(Dependent ~ Predictor1+Predictor2+Predictor3, data = SpatialPolygonDF,bw = Bandwidth, kernel = Kernel, adaptive = TRUE)
    GWR.df <<-as.data.frame(gwr.model$SDF)
  } 
  
  #3)GWR visualization: local regression coefficients & local R2
  gwr.map<- SpatialPolygonDF
  gwr.map@data <- cbind(SpatialPolygonDF@data, as.matrix(GWR.df))
  
  map.pred1 <- tm_shape(gwr.map) + 
    tm_fill("Predictor1", n = 5, style = "quantile", title = "Loc. Reg. Coeffs. (Pred.1)", palette = "RdYlBu", midpoint = 0) + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  map.pred2 <- tm_shape(gwr.map) +
    tm_fill("Predictor2", n = 5, style = "quantile", title = "Loc. Reg. Coeffs. (Pred.2)", palette = "RdYlBu", midpoint = 0) +
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  map.pred3 <- tm_shape(gwr.map) +
    tm_fill("Predictor3", n = 5, style = "quantile", title = "Loc. Reg. Coeffs. (Pred.3)", palette = "RdYlBu", midpoint = 0) +
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  map.R2 <- tm_shape(gwr.map) + 
    tm_fill("Local_R2", n = 5, style = "quantile", title = "Local R-squared", palette = "Greens", midpoint = NA) + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4, legend.outside = TRUE)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  grid.newpage()
  pushViewport(viewport(layout=grid.layout(1,3)))
  print(map.pred1, vp=viewport(layout.pos.col = 1, layout.pos.row =1))
  print(map.pred2, vp=viewport(layout.pos.col = 2, layout.pos.row =1))
  print(map.pred3, vp=viewport(layout.pos.col = 3, layout.pos.row =1))
  
  print(map.R2) #overall fit of the GWR model 
  
  #4)Diagnose global collinearity
  #Correlation between explanatory variables
  cor.coeff1 <- cor.test(Predictor1, Predictor2, method="pearson",use ="complete.obs")$estimate
  cor.coeff2 <- cor.test(Predictor1, Predictor3, method="pearson",use ="complete.obs")$estimate
  cor.coeff3 <- cor.test(Predictor2, Predictor3, method="pearson",use ="complete.obs")$estimate
  
  cor.pvalue1 <- cor.test(Predictor1, Predictor2, method="pearson",use ="complete.obs")$p.value
  cor.pvalue2 <- cor.test(Predictor1, Predictor3, method="pearson",use ="complete.obs")$p.value
  cor.pvalue3 <- cor.test(Predictor2, Predictor3, method="pearson",use ="complete.obs")$p.value
  
  print(paste0("Correlation coefficient between Pred.1 & Pred.2: ", cor.coeff1))
  print (paste0("P-value: ",cor.pvalue1))
  print(paste0("Correlation coefficient between Pred.1 & Pred.3: ", cor.coeff2))
  print (paste0("P-value: ",cor.pvalue2))
  print(paste0("Correlation coefficient between Pred.2 & Pred.3: ", cor.coeff3))
  print (paste0("P-value: ",cor.pvalue3))
  
  
  #Correlation between local regression coefficients
  cor.local.coeffs <- ggpairs(GWR.df,
                              columns= c("Predictor1","Predictor2", "Predictor3"), 
                              title="Correlation between local regression coefficients")
  print(cor.local.coeffs)
  
  
  #Variance Inflation Factor
  print(vif(global.reg))
  
  #5)Address local collinearity
  
  collin.diagno <- gwr.collin.diagno(Dependent ~ Predictor1+Predictor2+Predictor3, data = SpatialPolygonDF, bw = Bandwidth, kernel = Kernel, adaptive = TRUE) #provides  series of local collinearity diagnostics for the independent variables of a basic GWR model
  collin.diagno.df <<-as.data.frame(collin.diagno$SDF)
  
  collin.diagno.map<- SpatialPolygonDF
  collin.diagno.map@data <- cbind(SpatialPolygonDF@data, as.matrix(collin.diagno.df))
  
  #map local correlations
  corr.pred1.pred2 <- tm_shape(collin.diagno.map) + 
    tm_fill("Corr_Predictor1.Predictor2", n = 5, style = "quantile", title = "Local Correlation (Pred. 1 & 2)", palette = "RdBu", midpoint=0) + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  corr.pred1.pred3 <- tm_shape(collin.diagno.map) + 
    tm_fill("Corr_Predictor1.Predictor3", n = 5, style = "quantile", title = "Local Correlation (Pred. 1 & 3)", palette = "RdBu", midpoint=0) + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  corr.pred2.pred3 <- tm_shape(collin.diagno.map) + 
    tm_fill("Corr_Predictor2.Predictor3", n = 5, style = "quantile", title = "Local Correlation (Pred. 2 & 3)", palette = "RdBu", midpoint=0) + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  grid.newpage()
  pushViewport(viewport(layout=grid.layout(1,3)))
  print(corr.pred1.pred2, vp=viewport(layout.pos.col = 1, layout.pos.row =1))
  print(corr.pred1.pred3, vp=viewport(layout.pos.col = 2, layout.pos.row =1))
  print(corr.pred2.pred3, vp=viewport(layout.pos.col = 3, layout.pos.row =1))
  
  #map local variance inflation factors (VIFs) for each predictor
  vif.map.pred1 <- tm_shape(collin.diagno.map) + 
    tm_fill("Predictor1_VIF", n = 5, style = "quantile", title = "Local VIFs (Pred. 1)", palette = "YlOrRd") + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  vif.map.pred2 <- tm_shape(collin.diagno.map) + 
    tm_fill("Predictor2_VIF", n = 5, style = "quantile", title = "Local VIFs (Pred. 2)", palette = "YlOrRd") + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  vif.map.pred3 <- tm_shape(collin.diagno.map) + 
    tm_fill("Predictor3_VIF", n = 5, style = "quantile", title = "Local VIFs (Pred. 3)", palette = "YlOrRd") + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  grid.newpage()
  pushViewport(viewport(layout=grid.layout(1,3)))
  print(vif.map.pred1, vp=viewport(layout.pos.col = 1, layout.pos.row =1))
  print(vif.map.pred2, vp=viewport(layout.pos.col = 2, layout.pos.row =1))
  print(vif.map.pred3, vp=viewport(layout.pos.col = 3, layout.pos.row =1))
  
  #map local condition number
  local.CN <- tm_shape(collin.diagno.map) + 
    tm_fill("local_CN", n = 5, style = "quantile", title = "Local Condition Number", palette = "Purples") + 
    tm_layout(frame = FALSE, legend.text.size = 0.5, legend.title.size = 1.4)+
    tm_borders(col = "grey40", lwd = .5, lty = "solid", alpha = .4)
  
  print(local.CN)
}